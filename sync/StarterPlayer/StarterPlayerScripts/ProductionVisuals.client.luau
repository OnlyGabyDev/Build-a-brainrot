--[[
	ProductionVisuals
	Animates the assembly lines near the camera (GDD §6): droppers release their parts,
	the parts ride the belt to the Assembler, and the zone's machines put the brainrot
	together one part at a time, each part with its own animation. The finished
	brainrot then rides to the shipping chute with a coin popup. Purely cosmetic: the
	server decides what ships and pays out on the same schedule (Production.Schedule).

	Every zone has its own style in ASSEMBLY_STYLES (GDD §10): machines found on the
	line (built by TycoonManager) plus one animation per part type.
	  * Toy Workshop: the legs hop onto the pad, the claw lifts the body onto them, two
	    wooden robots punch the arms into place, and the claw screws the head on. Pop!
	  * Plushie Sewing Room: the legs plop onto a cushion, the needle stitches the body
	    on, thread spools reel the arms in, and the needle pumps the head full of
	    stuffing. Pop!
]]

local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local BrainrotModels = require(Shared:WaitForChild("BrainrotModels"))
local Format = require(Shared:WaitForChild("Format"))
local Production = require(Config:WaitForChild("Production"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Sounds = require(Config:WaitForChild("Sounds"))

local RENDER_DISTANCE = 250
local COIN_COLOR = Color3.fromRGB(255, 215, 60)
local MATCH_COLOR = Color3.fromRGB(120, 255, 140)
local SPARKLE_COLOR = Color3.fromRGB(255, 255, 255)
local POP_COLOR = Color3.fromRGB(255, 200, 60)
local STUFFING_COLOR = Color3.fromRGB(255, 250, 245)
local SPARKLE_TEXTURE = "rbxasset://textures/particles/sparkles_main.dds"
local PUFF_TEXTURE = "rbxasset://textures/particles/smoke_main.dds"

local INTAKE_GAP = 4 -- studs before the pad where parts wait to be picked up
local HOP_HEIGHT = 2.5
local SQUISH = 0.85 -- scale at the bottom of a squash
local LOOSE = 1.25 -- the arms arrive this much too big, until they're pushed/reeled in
local GRIP_DEPTH = 0.3 -- how far the claw's grip sinks into the top of a part
local CLAW_CLEARANCE = 0.6 -- studs between a carried part and what it passes over
local FINGERS_CLOSED = 0.65 -- finger spread when gripping, as a share of open
local FIST_HALF = 0.4
local STITCHES = 6 -- needle stitches while sewing the body on
local STITCH_HOVER = 1.5 -- studs the body starts above its place
local DEFLATED = 0.35 -- the plushie head's starting scale, before it's stuffed

type Piece = {
	Model: Model,
	Center: Vector3, -- the part's center relative to its pivot
	Size: Vector3,
	Dropper: BasePart,
	Waiting: CFrame, -- pivot while it waits at the intake
	Home: CFrame, -- pivot in the assembled brainrot
	Travel: number, -- belt distance, dropper to intake
}

type Build = {
	Line: Model,
	Root: CFrame, -- the assembly pad: the brainrot's root once assembled
	Machines: any, -- whatever the zone style's Setup returned
	Built: { Piece }, -- parts in place so far
	FullMatch: boolean,
}

type StepAnimation = (build: Build, piece: Piece, duration: number) -> ()

type Style = {
	-- Finds the zone's machines on a line and reads their resting poses. Nil if
	-- they're missing, and then every part just hops into place.
	Setup: (line: Model) -> any?,
	Steps: { [string]: StepAnimation },
}

local effects = Instance.new("Folder")
effects.Name = "ProductionEffects"
effects.Parent = workspace

-- Helpers --------------------------------------------------------------------

local function ease(alpha: number, style: Enum.EasingStyle?, direction: Enum.EasingDirection?): number
	return TweenService:GetValue(alpha, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.InOut)
end

-- Calls `update(alpha)` every frame for `duration` seconds (alpha 0 → 1) and yields
-- until it's done. Choreography with several moving objects is simpler this way
-- than juggling tweens.
local function run(duration: number, update: (alpha: number) -> ())
	local start = os.clock()
	while true do
		local alpha = if duration > 0 then math.min((os.clock() - start) / duration, 1) else 1
		update(alpha)
		if alpha >= 1 then
			return
		end
		RunService.Heartbeat:Wait()
	end
end

local function glide(model: Model, target: CFrame, duration: number, style: Enum.EasingStyle, direction: Enum.EasingDirection)
	local start = model:GetPivot()
	run(duration, function(alpha)
		model:PivotTo(start:Lerp(target, ease(alpha, style, direction)))
	end)
end

local function hop(model: Model, target: CFrame, duration: number, height: number)
	local start = model:GetPivot()
	run(duration, function(alpha)
		model:PivotTo(start:Lerp(target, alpha) + Vector3.new(0, height * 4 * alpha * (1 - alpha), 0))
	end)
end

local function tweenScale(model: Model, target: number, info: TweenInfo)
	local value = Instance.new("NumberValue")
	value.Value = model:GetScale()
	value.Changed:Connect(function(scale)
		if model.Parent then
			model:ScaleTo(scale)
		end
	end)
	local tween = TweenService:Create(value, info, { Value = target })
	tween.Completed:Once(function()
		value:Destroy()
	end)
	tween:Play()
end

-- A quick squash and spring back around the model's pivot.
local function squish(model: Model)
	local info = TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, true)
	tweenScale(model, model:GetScale() * SQUISH, info)
end

-- An invisible part for effects to hang off. It cleans itself up after `lifetime`.
local function makeAnchor(position: Vector3, lifetime: number): Part
	local anchor = Instance.new("Part")
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.Transparency = 1
	anchor.Size = Vector3.new(0.2, 0.2, 0.2)
	anchor.Position = position
	anchor.Parent = effects
	Debris:AddItem(anchor, lifetime)
	return anchor
end

local function playSound(position: Vector3, soundId: string, volume: number, speed: number?)
	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Volume = volume
	sound.PlaybackSpeed = speed or 1
	sound.RollOffMaxDistance = 120
	sound.Parent = makeAnchor(position, 3)
	sound:Play()
end

local function sparkle(position: Vector3, color: Color3, count: number)
	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture = SPARKLE_TEXTURE
	emitter.Color = ColorSequence.new(color)
	emitter.LightEmission = 0.7
	emitter.Size = NumberSequence.new(0.9, 0)
	emitter.Lifetime = NumberRange.new(0.4, 0.8)
	emitter.Speed = NumberRange.new(10, 18)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Acceleration = Vector3.new(0, -35, 0)
	emitter.Rotation = NumberRange.new(0, 360)
	emitter.Enabled = false
	emitter.Parent = makeAnchor(position, 1.5)
	emitter:Emit(count)
end

-- Soft white clouds, like stuffing bursting out.
local function puff(position: Vector3, count: number)
	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture = PUFF_TEXTURE
	emitter.Color = ColorSequence.new(STUFFING_COLOR)
	emitter.Size = NumberSequence.new(1.2, 2.8)
	emitter.Transparency = NumberSequence.new(0.1, 1)
	emitter.Lifetime = NumberRange.new(0.5, 0.8)
	emitter.Speed = NumberRange.new(4, 8)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Drag = 4
	emitter.Rotation = NumberRange.new(0, 360)
	emitter.Enabled = false
	emitter.Parent = makeAnchor(position, 1.5)
	emitter:Emit(count)
end

-- Floating text that rises and fades. `height` is in studs.
local function popup(position: Vector3, text: string, color: Color3, height: number, duration: number?)
	local lifetime = duration or 1.2
	local anchor = makeAnchor(position, lifetime + 0.1)

	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromScale(height * 5, height)
	gui.AlwaysOnTop = true
	gui.LightInfluence = 0
	gui.Parent = anchor

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = color
	label.Text = text
	label.Parent = gui

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 3
	stroke.Parent = label

	local rise = TweenInfo.new(lifetime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local fade = TweenInfo.new(lifetime * 0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, lifetime * 0.6)
	TweenService:Create(anchor, rise, { Position = position + Vector3.new(0, 6, 0) }):Play()
	TweenService:Create(label, fade, { TextTransparency = 1 }):Play()
	TweenService:Create(stroke, fade, { Transparency = 1 }):Play()
end

local function findPart(parent: Instance?, name: string): BasePart?
	local part = parent and parent:FindFirstChild(name)
	return if part and part:IsA("BasePart") then part else nil
end

-- Stretches a rod (length along its Z axis) between two points.
local function placeRod(rod: BasePart, from: Vector3, to: Vector3)
	local length = (to - from).Magnitude
	if length < 0.01 then
		return
	end
	rod.Size = Vector3.new(rod.Size.X, rod.Size.Y, length)
	rod.CFrame = CFrame.lookAt((from + to) / 2, to)
end

-- Build helpers --------------------------------------------------------------

-- Puts a piece in its place and makes everything built so far squish, with sparkles
-- and a sound.
local function place(build: Build, piece: Piece, color: Color3, sparkles: number, soundId: string, volume: number)
	piece.Model:PivotTo(piece.Home)
	table.insert(build.Built, piece)
	for _, built in build.Built do
		squish(built.Model)
	end
	local center = build.Root.Position + Vector3.new(0, 2, 0)
	sparkle(center, color, sparkles)
	playSound(center, soundId, volume)
end

-- The finishing touch on the last part: a big pop.
local function pop(build: Build)
	local color = if build.FullMatch then MATCH_COLOR else POP_COLOR
	local center = build.Root.Position + Vector3.new(0, 2, 0)
	sparkle(center, color, 30)
	playSound(center, Sounds.Pop, 0.6)
	popup(build.Root.Position + Vector3.new(0, 5, 0), "POP!", color, 1.5, 0.6)
end

local function builtTop(build: Build): number
	local top = build.Root.Position.Y
	for _, piece in build.Built do
		local box, size = piece.Model:GetBoundingBox()
		top = math.max(top, box.Position.Y + size.Y / 2)
	end
	return top
end

-- The world position of a piece's center once it's in place.
local function homeCenter(piece: Piece): Vector3
	return (piece.Home * CFrame.new(piece.Center)).Position
end

-- Pieces scale around their pivot (the brainrot's feet). This keeps the piece's own
-- center where it is instead: its pivot for a given `factor` of its base scale, when
-- its pivot would otherwise be at `pivot`.
local function centeredPivot(piece: Piece, pivot: CFrame, factor: number): CFrame
	local offset = homeCenter(piece) - piece.Home.Position
	return pivot + offset * (1 - factor)
end

-- The arms arrive too wide: hop to their place while growing to LOOSE size.
local function hopInLoose(piece: Piece, duration: number)
	local model = piece.Model
	local base = model:GetScale()
	local start = model:GetPivot()
	run(duration, function(a)
		model:PivotTo(start:Lerp(piece.Home, a) + Vector3.new(0, HOP_HEIGHT * 4 * a * (1 - a), 0))
		model:ScaleTo(base * (1 + (LOOSE - 1) * a))
	end)
end

-- Toy Workshop machines ------------------------------------------------------

type Claw = {
	Hand: BasePart,
	Rod: BasePart,
	Fingers: { { Part: BasePart, Offset: CFrame } }, -- offsets from the grip point, open
	Rest: CFrame, -- grip point at rest
	RodTop: number, -- world Y where the rod meets the gantry
	Owner: {}?, -- the animation currently driving it
}

type Pusher = {
	Fist: BasePart,
	Rod: BasePart,
	Shoulder: Vector3,
	Rest: CFrame,
}

type ToyMachines = { Claw: Claw, PusherLeft: Pusher, PusherRight: Pusher }

local function readPusher(model: Instance?): Pusher?
	local fist, rod = findPart(model, "Fist"), findPart(model, "Rod")
	if not (fist and rod) then
		return nil
	end
	return {
		Fist = fist,
		Rod = rod,
		Shoulder = rod.CFrame * Vector3.new(0, 0, rod.Size.Z / 2), -- the fist is at the -Z end
		Rest = fist.CFrame,
	}
end

local function setupToy(line: Model): ToyMachines?
	local claw = line:FindFirstChild("Claw")
	local assembler = findPart(line, "Assembler")
	local hand, rod = findPart(claw, "Hand"), findPart(claw, "Rod")
	local left, right = readPusher(line:FindFirstChild("PusherLeft")), readPusher(line:FindFirstChild("PusherRight"))
	if not (assembler and hand and rod and left and right) then
		return nil
	end

	local grip = hand.CFrame * CFrame.new(0, -hand.Size.Y / 2, 0)
	local fingers = {}
	for _, name in { "FingerLeft", "FingerRight" } do
		local finger = findPart(claw, name)
		if finger then
			table.insert(fingers, { Part = finger, Offset = grip:ToObjectSpace(finger.CFrame) })
		end
	end
	return {
		Claw = {
			Hand = hand,
			Rod = rod,
			Fingers = fingers,
			Rest = grip,
			RodTop = assembler.Position.Y - assembler.Size.Y / 2,
			Owner = nil,
		},
		PusherLeft = left,
		PusherRight = right,
	}
end

-- Poses the claw with its grip point at `grip`. `open` goes from 0 (gripping) to 1.
local function setClaw(claw: Claw, grip: CFrame, open: number)
	claw.Hand.CFrame = grip * CFrame.new(0, claw.Hand.Size.Y / 2, 0)
	local spread = FINGERS_CLOSED + (1 - FINGERS_CLOSED) * open
	for _, finger in claw.Fingers do
		local offset = finger.Offset
		finger.Part.CFrame = grip * CFrame.new(offset.X * spread, offset.Y, offset.Z) * offset.Rotation
	end
	local bottom = (grip * CFrame.new(0, claw.Hand.Size.Y, 0)).Position
	local length = math.max(claw.RodTop - bottom.Y, 0.05)
	claw.Rod.Size = Vector3.new(claw.Rod.Size.X, length, claw.Rod.Size.Z)
	claw.Rod.CFrame = grip.Rotation + Vector3.new(bottom.X, bottom.Y + length / 2, bottom.Z)
end

local function setFist(pusher: Pusher, cframe: CFrame)
	pusher.Fist.CFrame = cframe
	placeRod(pusher.Rod, pusher.Shoulder, cframe.Position)
end

-- The claw picks `piece` up from the intake, carries it over the build and lowers it
-- into place, spinning it `turns` times on the way down. Calls `onPlaced` the moment
-- it lands, then heads home.
local function clawCarry(build: Build, piece: Piece, duration: number, turns: number, onPlaced: () -> ())
	local claw = (build.Machines :: ToyMachines).Claw
	local token = {}
	claw.Owner = token
	local function setGrip(grip: CFrame, open: number)
		if claw.Owner == token then
			setClaw(claw, grip, open)
		end
	end

	-- Grip points sit on top of the part: where it waits, and where it belongs.
	local top = CFrame.new(piece.Center + Vector3.new(0, piece.Size.Y / 2 - GRIP_DEPTH, 0))
	local held = top:Inverse() -- from the grip point to the part's pivot
	local pickup = piece.Waiting * top
	local drop = piece.Home * top
	local carryY = math.max(claw.Rest.Y, builtTop(build) + CLAW_CLEARANCE + piece.Size.Y - GRIP_DEPTH)
	carryY = math.min(carryY, claw.RodTop - 1.5)
	local function above(grip: CFrame): CFrame
		return grip.Rotation + Vector3.new(grip.X, carryY, grip.Z)
	end
	local function carry(grip: CFrame)
		setGrip(grip, 0)
		piece.Model:PivotTo(grip * held)
	end

	local d = duration
	run(d * 0.18, function(a)
		setGrip(claw.Rest:Lerp(above(pickup), ease(a)), 1)
	end)
	run(d * 0.12, function(a)
		setGrip(above(pickup):Lerp(pickup, ease(a)), 1)
	end)
	run(d * 0.06, function(a)
		setGrip(pickup, 1 - a)
	end)
	run(d * 0.14, function(a)
		carry(pickup:Lerp(above(pickup), ease(a)))
	end)
	run(d * 0.14, function(a)
		carry(above(pickup):Lerp(above(drop), ease(a)))
	end)
	run(d * 0.22, function(a)
		local e = ease(a, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		carry(above(drop):Lerp(drop, e) * CFrame.Angles(0, turns * 2 * math.pi * (1 - e), 0))
	end)
	onPlaced()
	run(d * 0.04, function(a)
		setGrip(drop, a)
	end)
	run(d * 0.1, function(a)
		setGrip(drop:Lerp(claw.Rest, ease(a)), 1)
	end)
end

-- Plushie Sewing Room machines -----------------------------------------------

type Spool = {
	Spool: BasePart,
	Thread: BasePart,
	SpoolRest: CFrame,
	ThreadRest: CFrame,
	ThreadSize: Vector3,
}

type SewingMachines = {
	Needle: BasePart,
	NeedleRest: CFrame,
	TipRestY: number, -- world Y of the needle's tip at rest
	Spools: { Spool }, -- left, right
}

local function setupSewing(line: Model): SewingMachines?
	local needle = findPart(line, "Needle")
	if not needle then
		return nil
	end
	local spools = {}
	for _, side in { "Left", "Right" } do
		local spool, thread = findPart(line, `Spool{side}`), findPart(line, `Thread{side}`)
		if not (spool and thread) then
			return nil
		end
		table.insert(spools, {
			Spool = spool,
			Thread = thread,
			SpoolRest = spool.CFrame,
			ThreadRest = thread.CFrame,
			ThreadSize = thread.Size,
		})
	end
	return {
		Needle = needle,
		NeedleRest = needle.CFrame,
		TipRestY = needle.Position.Y - needle.Size.Y / 2,
		Spools = spools,
	}
end

-- One stitch: the needle dips to `tipY` (world) and back up.
local function stitch(machines: SewingMachines, x: number, z: number, tipY: number, duration: number)
	local rest = machines.NeedleRest
	local offset = Vector3.new(x - rest.X, 0, z - rest.Z)
	run(duration, function(a)
		local down = math.sin(a * math.pi)
		machines.Needle.CFrame = rest + offset + Vector3.new(0, (tipY - machines.TipRestY) * down, 0)
	end)
	machines.Needle.CFrame = rest
end

local function resetSpools(machines: SewingMachines)
	for _, spool in machines.Spools do
		spool.Spool.CFrame = spool.SpoolRest
		spool.Thread.CFrame = spool.ThreadRest
		spool.Thread.Size = spool.ThreadSize
	end
end

-- Assembly styles ------------------------------------------------------------
-- One animation per part type, per zone. Each runs for its step's duration, starting
-- as the part reaches the intake. The rarer the zone, the crazier it should be.

-- Used when a zone has no animation for a part (or its machines are missing).
local function simpleStep(build: Build, piece: Piece, duration: number)
	hop(piece.Model, piece.Home, duration * 0.6, HOP_HEIGHT)
	place(build, piece, SPARKLE_COLOR, 8, Sounds.Stamp, 0.25)
end

local ASSEMBLY_STYLES: { [string]: Style } = {
	ToyWorkshop = {
		Setup = setupToy,
		Steps = {
			-- The legs hop off the belt and land on the pad.
			Legs = function(build, piece, duration)
				hop(piece.Model, piece.Home, duration * 0.7, 3)
				place(build, piece, SPARKLE_COLOR, 6, Sounds.Pop, 0.3)
			end,

			-- The claw lifts the body off the belt and sets it down on the legs.
			Body = function(build, piece, duration)
				clawCarry(build, piece, duration, 0, function()
					place(build, piece, SPARKLE_COLOR, 10, Sounds.Stamp, 0.25)
				end)
			end,

			-- The arms hop in loose until the two robots punch them into place.
			Arms = function(build, piece, duration)
				local machines = build.Machines :: ToyMachines
				local model = piece.Model
				local base = model:GetScale()
				hopInLoose(piece, duration * 0.35)

				local center = build.Root:PointToObjectSpace(homeCenter(piece))
				local reach = piece.Size.X / 2 + FIST_HALF
				local punches = {
					[machines.PusherLeft] = build.Root * CFrame.new(center.X - reach, center.Y, center.Z),
					[machines.PusherRight] = build.Root * CFrame.new(center.X + reach, center.Y, center.Z),
				}
				task.wait(duration * 0.1)
				run(duration * 0.15, function(a)
					local e = ease(a, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
					for pusher, target in punches do
						setFist(pusher, pusher.Rest:Lerp(target, e))
					end
					model:ScaleTo(base * (LOOSE - (LOOSE - 1) * e))
				end)
				model:ScaleTo(base)
				place(build, piece, SPARKLE_COLOR, 12, Sounds.Stamp, 0.3)

				run(duration * 0.3, function(a)
					local e = ease(a, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
					for pusher, target in punches do
						setFist(pusher, target:Lerp(pusher.Rest, e))
					end
				end)
			end,

			-- The claw screws the head on. Pop!
			Head = function(build, piece, duration)
				clawCarry(build, piece, duration, 2, function()
					place(build, piece, POP_COLOR, 12, Sounds.Stamp, 0.2)
					pop(build)
				end)
			end,
		},
	},

	PlushieRoom = {
		Setup = setupSewing,
		Steps = {
			-- The legs plop down from up high onto a soft cushion. Floof.
			Legs = function(build, piece, duration)
				hop(piece.Model, piece.Home, duration * 0.7, 5)
				place(build, piece, STUFFING_COLOR, 6, Sounds.Pop, 0.3)
				puff(build.Root.Position + Vector3.new(0, 0.5, 0), 8)
			end,

			-- The body hovers over the legs and the needle stitches it down, one quick
			-- stitch at a time.
			Body = function(build, piece, duration)
				local machines = build.Machines :: SewingMachines
				local hover = piece.Home + Vector3.new(0, STITCH_HOVER, 0)
				hop(piece.Model, hover, duration * 0.3, HOP_HEIGHT)
				local center = homeCenter(piece)
				local stitchTime = duration * 0.6 / STITCHES
				for index = 1, STITCHES do
					local height = STITCH_HOVER * (1 - index / STITCHES)
					piece.Model:PivotTo(piece.Home + Vector3.new(0, height, 0))
					local topY = center.Y + piece.Size.Y / 2 + height
					playSound(center, Sounds.Stamp, 0.12, 2.2)
					stitch(machines, center.X, center.Z, topY - 0.4, stitchTime)
				end
				place(build, piece, Color3.fromRGB(255, 170, 205), 10, Sounds.Pop, 0.25)
			end,

			-- The arms land too wide, and the thread spools reel them in snug.
			Arms = function(build, piece, duration)
				local machines = build.Machines :: SewingMachines
				local model = piece.Model
				local base = model:GetScale()
				hopInLoose(piece, duration * 0.35)

				local center = build.Root:PointToObjectSpace(homeCenter(piece))
				local half = piece.Size.X / 2
				run(duration * 0.45, function(a)
					local e = ease(a, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
					local scale = LOOSE - (LOOSE - 1) * e
					model:ScaleTo(base * scale)
					for index, spool in machines.Spools do
						local side = if index == 1 then -1 else 1
						local target = (build.Root * CFrame.new(center.X + side * half * scale, center.Y * scale, center.Z)).Position
						placeRod(spool.Thread, spool.SpoolRest.Position, target)
						spool.Spool.CFrame = spool.SpoolRest * CFrame.Angles(e * math.pi * 6 * side, 0, 0)
					end
				end)
				model:ScaleTo(base)
				resetSpools(machines)
				place(build, piece, Color3.fromRGB(120, 200, 255), 12, Sounds.Pop, 0.3)
			end,

			-- The head arrives deflated, and the needle pumps it full of stuffing. Pop!
			Head = function(build, piece, duration)
				local machines = build.Machines :: SewingMachines
				local model = piece.Model
				local base = model:GetScale()
				local start = model:GetPivot()
				run(duration * 0.3, function(a)
					local factor = 1 - (1 - DEFLATED) * a
					local pivot = start:Lerp(piece.Home, a) + Vector3.new(0, HOP_HEIGHT * 4 * a * (1 - a), 0)
					model:ScaleTo(base * factor)
					model:PivotTo(centeredPivot(piece, pivot, factor))
				end)

				local center = homeCenter(piece)
				for pump = 1, 3 do
					local factor = DEFLATED + (1.15 - DEFLATED) * pump / 3 -- overshoots a little
					local topY = center.Y + piece.Size.Y * factor / 2
					stitch(machines, center.X, center.Z, topY, duration * 0.15)
					model:ScaleTo(base * factor)
					model:PivotTo(centeredPivot(piece, piece.Home, factor))
					puff(center, 3)
					playSound(center, Sounds.Pop, 0.2, 0.8 + pump * 0.2)
				end
				model:ScaleTo(base)
				place(build, piece, STUFFING_COLOR, 12, Sounds.Pop, 0.2)
				puff(center, 14)
				pop(build)
			end,
		},
	},
}
local DEFAULT_STYLE = ASSEMBLY_STYLES.ToyWorkshop

-- Machines are read once per line, while they're at rest.
local machinesByLine: { [Model]: any } = setmetatable({}, { __mode = "k" }) :: any

local function getMachines(line: Model, style: Style): any?
	local machines = machinesByLine[line]
	if not machines then
		machines = style.Setup(line)
		machinesByLine[line] = machines
	end
	return machines
end

-- One production cycle -------------------------------------------------------

local function animateCycle(
	line: Model,
	parts: { [string]: string },
	zoneId: string,
	value: number,
	fullMatch: boolean,
	cycleTime: number
)
	local belt = findPart(line, "Belt")
	local assembler = findPart(line, "Assembler")
	local ship = findPart(line, "Ship")
	if not (belt and assembler and ship) then
		return
	end

	local rotation = belt.CFrame.Rotation
	local beltTop = belt.Position.Y + belt.Size.Y / 2
	local root = rotation + Vector3.new(assembler.Position.X, beltTop, assembler.Position.Z)
	local shipRoot = rotation + Vector3.new(ship.Position.X, beltTop, ship.Position.Z)
	local style = ASSEMBLY_STYLES[zoneId] or DEFAULT_STYLE
	local build: Build = { Line = line, Root = root, Machines = getMachines(line, style), Built = {}, FullMatch = fullMatch }

	-- Everything is scheduled against one clock, so the parts and machines stay in sync.
	local start = os.clock()
	local function waitUntil(t: number)
		local remaining = start + t - os.clock()
		if remaining > 0 then
			task.wait(remaining)
		end
	end

	-- The pivot that puts a piece's center at `position`.
	local function centeredAt(center: Vector3, position: Vector3): CFrame
		return (rotation + position) * CFrame.new(-center)
	end

	local steps = Production.Schedule(parts, cycleTime)
	local layout = BrainrotModels.Layout(parts, zoneId)
	local pieces: { [string]: Piece } = {}
	local maxTravel = 0
	for _, step in steps do
		local partType = step.PartType
		local dropper = findPart(line, partType .. "Dropper")
		if not dropper then
			continue
		end
		local model, center, size = BrainrotModels.CreatePart(parts[partType], partType, zoneId)
		local flat = Vector3.new(dropper.Position.X - root.X, 0, dropper.Position.Z - root.Z)
		local direction = if flat.Magnitude > 0 then flat.Unit else Vector3.zero
		local intake = root.Position + direction * INTAKE_GAP + Vector3.new(0, size.Y / 2, 0)
		local piece: Piece = {
			Model = model,
			Center = center,
			Size = size,
			Dropper = dropper,
			Waiting = centeredAt(center, intake),
			Home = root * CFrame.new(layout[partType]),
			Travel = math.max(flat.Magnitude - INTAKE_GAP, 0),
		}
		model:PivotTo(centeredAt(center, dropper.Position)) -- starts hidden inside the dropper
		model.Parent = effects
		maxTravel = math.max(maxTravel, piece.Travel)
		pieces[partType] = piece
	end
	if not next(pieces) then
		return
	end

	-- 1-2) Each part drops onto the belt and rides it at one constant speed, timed to
	-- reach the intake just as its assembly step starts.
	local speed = math.max(maxTravel, 1) / Production.SlideTime
	for _, step in steps do
		local piece = pieces[step.PartType]
		if not piece then
			continue
		end
		local ride = piece.Travel / speed
		task.spawn(function()
			waitUntil(step.Start - ride - Production.DropTime)
			local below = piece.Dropper.Position
			local landing = centeredAt(piece.Center, Vector3.new(below.X, beltTop + piece.Size.Y / 2, below.Z))
			glide(piece.Model, landing, Production.DropTime, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out)
			waitUntil(step.Start - ride)
			glide(piece.Model, piece.Waiting, ride, Enum.EasingStyle.Linear, Enum.EasingDirection.In)
		end)
	end

	-- 3) The zone's machines assemble it, one part at a time.
	for _, step in steps do
		local piece = pieces[step.PartType]
		if not piece then
			continue
		end
		waitUntil(step.Start)
		local animate = if build.Machines then style.Steps[step.PartType] else nil
		local ok, err = pcall(animate or simpleStep, build, piece, step.Duration)
		if not ok then
			warn(`[ProductionVisuals] {zoneId} {step.PartType} step failed: {err}`)
			piece.Model:PivotTo(piece.Home)
		end
	end
	local _, finished = Production.Schedule(parts, cycleTime)
	waitUntil(finished)

	-- 4) Ride to the chute as one brainrot, then drop in.
	local brainrot = Instance.new("Model")
	brainrot.Name = "Brainrot"
	for _, piece in pieces do
		piece.Model:PivotTo(piece.Home)
		piece.Model.Parent = brainrot
	end
	brainrot.WorldPivot = root
	brainrot.Parent = effects

	glide(brainrot, shipRoot, Production.ShipTime, Enum.EasingStyle.Linear, Enum.EasingDirection.In)

	local text = `+{Format.Number(value)} 💰` .. (if fullMatch then " x2!" else "")
	local top = ship.Position + Vector3.new(0, ship.Size.Y / 2 + 2, 0)
	popup(top, text, if fullMatch then MATCH_COLOR else COIN_COLOR, 2)
	playSound(top, Sounds.Cash, 0.35)
	tweenScale(brainrot, 0.05, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.In))
	Debris:AddItem(brainrot, 0.3)
end

local function findLine(plot: Instance?, lineId: string): Model?
	local lines = plot and plot:FindFirstChild("Lines")
	local line = lines and lines:FindFirstChild(lineId)
	return if line and line:IsA("Model") then line else nil
end

Remotes.Event("Production").OnClientEvent:Connect(function(plot, lineId, parts, zoneId, value, fullMatch, cycleTime)
	local line = findLine(plot, lineId)
	local camera = workspace.CurrentCamera
	if not (line and camera) or (camera.CFrame.Position - line:GetPivot().Position).Magnitude > RENDER_DISTANCE then
		return
	end
	task.spawn(animateCycle, line, parts, zoneId, value, fullMatch, cycleTime or Production.BaseCycleTime)
end)
