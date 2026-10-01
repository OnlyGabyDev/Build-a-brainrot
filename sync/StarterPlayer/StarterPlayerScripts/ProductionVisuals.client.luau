--[[
	ProductionVisuals
	Animates the assembly lines near the camera (GDD §6): droppers spit out their parts,
	the parts ride the belt to the Assembler, and the zone's machines put the brainrot
	together one part at a time, each part with its own animation and sounds. The
	finished brainrot rides through the upgrade stations (paint, glitter) to the
	shipping chute, and its coins fly over to the Cash Pad. Purely cosmetic: the server
	decides what ships and pays out on the same schedule (Production.Schedule).

	Every zone has its own style in ASSEMBLY_STYLES (GDD §10): machines found on the
	line (built by TycoonManager) plus one animation per part type.
	  * Toy Workshop: the legs boing onto the pad, the claw whirs the body onto them,
	    two wooden robots BONK the arms into place, and the claw ratchets the head on.
	    Pop!
	  * Plushie Sewing Room: the legs plop onto a cushion, the needle stitches the body
	    on, thread spools reel the arms in, and the needle pumps the head full of
	    stuffing. Pop!
]]

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
local TycoonItems = require(Config:WaitForChild("TycoonItems"))
local Effects = require(ReplicatedStorage:WaitForChild("Client"):WaitForChild("Effects"))

local RENDER_DISTANCE = 250
local FX_RANGE = 140 -- particles and flying coins only for lines this close to the camera
local COIN_COLOR = Color3.fromRGB(255, 215, 60)
local MATCH_COLOR = Color3.fromRGB(120, 255, 140)
local SPARKLE_COLOR = Color3.fromRGB(255, 255, 255)
local POP_COLOR = Color3.fromRGB(255, 200, 60)
local STUFFING_COLOR = Color3.fromRGB(255, 250, 245)
local DUST_COLOR = Color3.fromRGB(235, 220, 200)
local BONK_COLOR = Color3.fromRGB(255, 110, 90)
local PAINT_COLORS = {
	Color3.fromRGB(255, 90, 170),
	Color3.fromRGB(90, 210, 255),
	Color3.fromRGB(255, 220, 60),
	Color3.fromRGB(140, 240, 100),
	Color3.fromRGB(190, 120, 255),
}
local GLITTER_COLOR = Color3.fromRGB(255, 230, 120)

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
local CHUTE_DROP = 3 -- studs the brainrot sinks into the chute as it ships
local FALL_TIME = 0.5 -- a part's bounce from its dropper's mouth onto the belt

type Piece = {
	Model: Model,
	Center: Vector3, -- the part's center relative to its pivot
	Size: Vector3,
	Dropper: BasePart,
	ChuteTop: BasePart?, -- a ceiling chute's collar, where the part starts its slide
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
	Near: boolean, -- close enough to the camera for particles
}

type StepAnimation = (build: Build, piece: Piece, duration: number) -> ()

type Style = {
	-- Finds the zone's machines on a line and reads their resting poses. Nil if
	-- they're missing, and then every part just hops into place.
	Setup: (line: Model) -> any?,
	Steps: { [string]: StepAnimation },
}

local effects = Effects.Folder

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

-- Whether TycoonFX is still popping a line's parts into place (just bought).
local function isBuilding(line: Instance): boolean
	local deadline = line:GetAttribute("BuildingUntil")
	return typeof(deadline) == "number" and deadline > os.clock()
end

-- Particles are skipped on lines far from the camera; sounds cull themselves.
local function sparkle(build: Build, position: Vector3, color: Color3, count: number)
	if build.Near then
		Effects.sparkle(position, color, count)
	end
end

local function puff(build: Build, position: Vector3, color: Color3, count: number, size: number?)
	if build.Near then
		Effects.puff(position, color, count, size)
	end
end

local function ring(build: Build, color: Color3, radius: number)
	if build.Near then
		Effects.ring(build.Root.Position + Vector3.new(0, 0.1, 0), color, radius)
	end
end

-- A random pitch around `speed`, so repeated sounds don't grate.
local function vary(speed: number?): number
	return (speed or 1) * (0.92 + math.random() * 0.16)
end

-- Droppers and the beacon ----------------------------------------------------

-- Ceiling chutes (the Toy Workshop's droppers, TycoonManager.buildChute) are rubbery:
-- their bands bulge as a part slides down past them, and the whole chute squashes and
-- stretches as it spits the part out, hanging from its collar in the ceiling.
type ChutePiece = {
	Part: BasePart,
	Rest: CFrame,
	Size: Vector3,
	Axis: number, -- which of its Size's components runs up and down (1 = X, 2 = Y, 3 = Z)
}
type Chute = {
	Anchor: Vector3, -- where it hangs from: the bottom of its collar
	Pieces: { ChutePiece }, -- everything that stretches: tube, bands, neck, nozzle
	Bands: { ChutePiece },
	Owner: {}?, -- the squash currently driving it
}

-- { seconds, height scale, width scale }: it gathers itself short and fat as it spits,
-- stretches down after the part, and wobbles back.
local CHUTE_SQUASH = {
	{ 0, 1, 1 },
	{ 0.07, 0.84, 1.16 },
	{ 0.17, 1.12, 0.9 },
	{ 0.27, 0.95, 1.06 },
	{ 0.37, 1.02, 0.98 },
	{ 0.46, 1, 1 },
}
local CHUTE_BULGE = 0.4 -- how much wider a band swells as a part passes
local CHUTE_BULGE_REACH = 3.5 -- studs from the part where a band starts to swell

local chutes: { [BasePart]: Chute } = setmetatable({}, { __mode = "k" }) :: any

local function startsWith(name: string, prefix: string): boolean
	return string.sub(name, 1, #prefix) == prefix
end

-- The chute whose collar is `top`, read once while it's at rest.
local function readChute(line: Model, top: BasePart): Chute
	local cached = chutes[top]
	if cached then
		return cached
	end
	local prefix = string.sub(top.Name, 1, #top.Name - #"ChuteTop") -- "Head", "Body", ...
	local chute: Chute = {
		Anchor = top.Position - Vector3.new(0, top.Size.X / 2, 0), -- the collar stands on its side: X is its height
		Pieces = {},
		Bands = {},
		Owner = nil,
	}
	for _, child in line:GetChildren() do
		local name = child.Name
		local stretches = startsWith(name, prefix .. "Dropper") or name == prefix .. "ChuteTube" or name == prefix .. "ChuteBand" or name == prefix .. "ChuteNeck"
		if stretches and child:IsA("BasePart") then
			local frame = child.CFrame
			local axis = if math.abs(frame.RightVector.Y) > 0.9 then 1 elseif math.abs(frame.LookVector.Y) > 0.9 then 3 else 2
			local piece = { Part = child, Rest = frame, Size = child.Size, Axis = axis }
			table.insert(chute.Pieces, piece)
			if name == prefix .. "ChuteBand" then
				table.insert(chute.Bands, piece)
			end
		end
	end
	chutes[top] = chute
	return chute
end

-- Scales a piece's size: `along` up and down, `across` the other two ways.
local function scaledSize(piece: ChutePiece, along: number, across: number): Vector3
	local size = piece.Size
	return Vector3.new(
		size.X * (if piece.Axis == 1 then along else across),
		size.Y * (if piece.Axis == 2 then along else across),
		size.Z * (if piece.Axis == 3 then along else across)
	)
end

-- Poses the whole chute stretched `along` its height and `across` its width, still
-- hanging from its collar.
local function poseChute(chute: Chute, along: number, across: number)
	for _, piece in chute.Pieces do
		local offset = piece.Rest.Position - chute.Anchor
		piece.Part.CFrame = piece.Rest.Rotation + chute.Anchor + Vector3.new(offset.X * across, offset.Y * along, offset.Z * across)
		piece.Part.Size = scaledSize(piece, along, across)
	end
end

-- The bands near world height `y` swell, as if the tube were gulping a part down.
local function bulgeChute(chute: Chute, y: number)
	for _, band in chute.Bands do
		local near = math.max(0, 1 - math.abs(band.Rest.Position.Y - y) / CHUTE_BULGE_REACH)
		band.Part.Size = scaledSize(band, 1, 1 + CHUTE_BULGE * near)
	end
end

local function squashChute(chute: Chute)
	local token = {}
	chute.Owner = token
	local total = CHUTE_SQUASH[#CHUTE_SQUASH][1]
	run(total, function(alpha)
		if chute.Owner ~= token then
			return
		end
		local t = alpha * total
		for index = 2, #CHUTE_SQUASH do
			local from, to = CHUTE_SQUASH[index - 1], CHUTE_SQUASH[index]
			if t <= to[1] or index == #CHUTE_SQUASH then
				local e = ease(math.clamp((t - from[1]) / (to[1] - from[1]), 0, 1), Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
				poseChute(chute, from[2] + (to[2] - from[2]) * e, from[3] + (to[3] - from[3]) * e)
				break
			end
		end
	end)
	if chute.Owner == token then
		poseChute(chute, 1, 1)
		chute.Owner = nil
	end
end

-- The dropper squashes and spits its part out with a plop and a puff. A ceiling chute
-- does its rubbery squash instead, with a bigger splash.
local function spit(line: Model, dropper: BasePart, near: boolean, chute: Chute?)
	local mouth = dropper.Position - Vector3.new(0, dropper.Size.Y / 2 + 0.3, 0)
	Effects.sound(mouth, Sounds.Plop, 0.35, vary(1))
	if chute then
		Effects.sound(mouth, Sounds.Squeak, 0.3, vary(1.35))
		Effects.sound(mouth, Sounds.Boing, 0.15, vary(1.7))
		if near then
			Effects.puff(mouth, dropper.Color:Lerp(Color3.new(1, 1, 1), 0.4), 10, 0.8)
			Effects.sparkle(mouth, Color3.new(1, 1, 1), 8)
			Effects.ring(mouth, dropper.Color:Lerp(Color3.new(1, 1, 1), 0.3), 4, 0.35)
		end
		task.spawn(squashChute, chute)
		return
	end
	if near then
		Effects.puff(mouth, dropper.Color:Lerp(Color3.new(1, 1, 1), 0.5), 5, 0.6)
	end
	if isBuilding(line) then
		return -- it's still popping in; don't fight over its size
	end
	local rest = dropper:GetAttribute("RestSize")
	if typeof(rest) ~= "Vector3" then
		rest = dropper.Size
		dropper:SetAttribute("RestSize", rest)
	end
	local restSize = rest :: Vector3
	dropper.Size = restSize
	local squashed = Vector3.new(restSize.X * 1.12, restSize.Y * 0.8, restSize.Z * 1.12)
	local info = TweenInfo.new(0.09, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, true)
	TweenService:Create(dropper, info, { Size = squashed }):Play()
end

local beaconTweens: { [BasePart]: Tween } = {}

-- The gantry's beacon glows and pulses while the Assembler works.
local function setBeacon(line: Model, on: boolean)
	local beacon = findPart(line, "Beacon")
	local light = beacon and beacon:FindFirstChildOfClass("PointLight")
	if not (beacon and light) then
		return
	end
	local running = beaconTweens[beacon]
	if running then
		running:Cancel()
		beaconTweens[beacon] = nil
	end
	local glow = beacon:GetAttribute("GlowColor")
	if on then
		beacon.Material = Enum.Material.Neon
		beacon.Color = if typeof(glow) == "Color3" then glow else POP_COLOR
		light.Brightness = 0.5
		local tween = TweenService:Create(light, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Brightness = 4 })
		beaconTweens[beacon] = tween
		tween:Play()
	else
		beacon.Material = Enum.Material.SmoothPlastic
		beacon.Color = Color3.fromRGB(120, 110, 130)
		light.Brightness = 0
	end
end

-- Build helpers --------------------------------------------------------------

-- Puts a piece in its place and makes everything built so far squish, with sparkles,
-- a ring on the pad and a sound.
local function place(build: Build, piece: Piece, color: Color3, sparkles: number, soundId: string, volume: number)
	piece.Model:PivotTo(piece.Home)
	table.insert(build.Built, piece)
	for _, built in build.Built do
		squish(built.Model)
	end
	local center = build.Root.Position + Vector3.new(0, 2, 0)
	sparkle(build, center, color, sparkles)
	ring(build, color, 3.5)
	Effects.sound(center, soundId, volume, vary(1))
end

-- The finishing touch on the last part: a big pop. A full match gets confetti too.
local function pop(build: Build)
	local color = if build.FullMatch then MATCH_COLOR else POP_COLOR
	local center = build.Root.Position + Vector3.new(0, 2, 0)
	sparkle(build, center, color, 30)
	ring(build, color, 6)
	if build.Near then
		Effects.flash(center + Vector3.new(0, 2, 0), color, 3, 18)
	end
	Effects.sound(center, Sounds.Pop, 0.6, vary(1))
	if build.FullMatch then
		if build.Near then
			Effects.confetti(center + Vector3.new(0, 2, 0), 25)
		end
		Effects.popup(build.Root.Position + Vector3.new(0, 5.5, 0), "PERFECT!", color, 1.5, 0.8)
	else
		Effects.popup(build.Root.Position + Vector3.new(0, 5, 0), "POP!", color, 1.5, 0.6)
	end
	setBeacon(build.Line, false)
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
-- into place, spinning it `turns` times on the way down. Calls `onLower` as it starts
-- down and `onPlaced` the moment it lands, then heads home. Whirs as it goes.
local function clawCarry(build: Build, piece: Piece, duration: number, turns: number, onPlaced: () -> (), onLower: (() -> ())?)
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
	local speed = math.clamp(1.2 / d, 1, 2) -- faster lines whir higher
	Effects.sound(claw.Rest.Position, Sounds.Servo, 0.25, vary(speed))
	run(d * 0.18, function(a)
		setGrip(claw.Rest:Lerp(above(pickup), ease(a)), 1)
	end)
	run(d * 0.12, function(a)
		setGrip(above(pickup):Lerp(pickup, ease(a)), 1)
	end)
	run(d * 0.06, function(a)
		setGrip(pickup, 1 - a)
	end)
	Effects.sound(pickup.Position, Sounds.Servo, 0.2, vary(speed * 1.2))
	run(d * 0.14, function(a)
		carry(pickup:Lerp(above(pickup), ease(a)))
	end)
	run(d * 0.14, function(a)
		carry(above(pickup):Lerp(above(drop), ease(a)))
	end)
	if onLower then
		onLower()
	end
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

local function stopSound(sound: Sound?)
	if sound then
		sound:Stop()
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
			-- The legs boing off the belt and land on the pad.
			Legs = function(build, piece, duration)
				Effects.sound(homeCenter(piece), Sounds.Boing, 0.3, vary(1.15))
				hop(piece.Model, piece.Home, duration * 0.7, 3)
				place(build, piece, SPARKLE_COLOR, 6, Sounds.Pop, 0.3)
				puff(build, build.Root.Position + Vector3.new(0, 0.4, 0), DUST_COLOR, 6, 0.6)
			end,

			-- The claw lifts the body off the belt and sets it down on the legs.
			Body = function(build, piece, duration)
				clawCarry(build, piece, duration, 0, function()
					place(build, piece, SPARKLE_COLOR, 10, Sounds.Stamp, 0.25)
				end)
			end,

			-- The arms hop in loose until the two robots BONK them into place.
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
				place(build, piece, SPARKLE_COLOR, 12, Sounds.Clunk, 0.35)
				for _, target in punches do
					sparkle(build, target.Position, BONK_COLOR, 6)
				end
				Effects.popup(homeCenter(piece) + Vector3.new(0, 1.5, 0), "BONK!", BONK_COLOR, 1, 0.5)

				run(duration * 0.3, function(a)
					local e = ease(a, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
					for pusher, target in punches do
						setFist(pusher, target:Lerp(pusher.Rest, e))
					end
				end)
			end,

			-- The claw ratchets the head on. Pop!
			Head = function(build, piece, duration)
				local ratchet: Sound? = nil
				clawCarry(build, piece, duration, 2, function()
					stopSound(ratchet)
					place(build, piece, POP_COLOR, 12, Sounds.Stamp, 0.2)
					pop(build)
				end, function()
					ratchet = Effects.sound(homeCenter(piece), Sounds.Ratchet, 0.3, vary(math.clamp(1.2 / duration, 1, 1.8)))
				end)
			end,
		},
	},

	PlushieRoom = {
		Setup = setupSewing,
		Steps = {
			-- The legs plop down from up high onto a soft cushion. Floof.
			Legs = function(build, piece, duration)
				Effects.sound(homeCenter(piece), Sounds.Boing, 0.25, vary(0.8))
				hop(piece.Model, piece.Home, duration * 0.7, 5)
				place(build, piece, STUFFING_COLOR, 6, Sounds.Squeak, 0.3)
				puff(build, build.Root.Position + Vector3.new(0, 0.5, 0), STUFFING_COLOR, 8)
			end,

			-- The body hovers over the legs and the needle stitches it down, one quick
			-- stitch at a time.
			Body = function(build, piece, duration)
				local machines = build.Machines :: SewingMachines
				local hover = piece.Home + Vector3.new(0, STITCH_HOVER, 0)
				hop(piece.Model, hover, duration * 0.3, HOP_HEIGHT)
				local center = homeCenter(piece)
				local stitchTime = duration * 0.6 / STITCHES
				local sewing = Effects.sound(center, Sounds.Sewing, 0.3, math.clamp(1.2 / duration, 1, 1.6))
				for index = 1, STITCHES do
					local height = STITCH_HOVER * (1 - index / STITCHES)
					piece.Model:PivotTo(piece.Home + Vector3.new(0, height, 0))
					local topY = center.Y + piece.Size.Y / 2 + height
					stitch(machines, center.X, center.Z, topY - 0.4, stitchTime)
				end
				stopSound(sewing)
				place(build, piece, Color3.fromRGB(255, 170, 205), 10, Sounds.Squeak, 0.25)
			end,

			-- The arms land too wide, and the thread spools reel them in snug.
			Arms = function(build, piece, duration)
				local machines = build.Machines :: SewingMachines
				local model = piece.Model
				local base = model:GetScale()
				hopInLoose(piece, duration * 0.35)

				local center = build.Root:PointToObjectSpace(homeCenter(piece))
				local half = piece.Size.X / 2
				local reel = Effects.sound(homeCenter(piece), Sounds.Ratchet, 0.2, 1.6)
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
				stopSound(reel)
				model:ScaleTo(base)
				resetSpools(machines)
				place(build, piece, Color3.fromRGB(120, 200, 255), 12, Sounds.Squeak, 0.3)
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
					puff(build, center, STUFFING_COLOR, 3)
					Effects.sound(center, Sounds.Pop, 0.25, 0.8 + pump * 0.2)
				end
				model:ScaleTo(base)
				place(build, piece, STUFFING_COLOR, 12, Sounds.Squeak, 0.3)
				puff(build, center, STUFFING_COLOR, 14)
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
		-- A line that was just bought is still popping in; read it once it settles.
		while isBuilding(line) do
			task.wait(0.1)
		end
		machines = style.Setup(line)
		machinesByLine[line] = machines
	end
	return machines
end

-- Upgrade stations -----------------------------------------------------------
-- The brainrot rides under each station's arch on its way to the chute, and the
-- station does its thing: the Paint Booth splashes it with paint, the Glitter
-- Blaster showers it in glitter. Each shows its value multiplier.

type StationPass = { Alpha: number, Key: string, Arch: BasePart }

local STATION_FX: { [string]: (build: Build, arch: BasePart, brainrot: Model, center: Vector3) -> () } = {
	Station1 = function(build, _arch, brainrot, center)
		local color = PAINT_COLORS[math.random(1, #PAINT_COLORS)]
		Effects.tint(brainrot, color, 0.7)
		puff(build, center, color, 8, 0.7)
		sparkle(build, center, PAINT_COLORS[math.random(1, #PAINT_COLORS)], 10)
		Effects.sound(center, Sounds.Whoosh, 0.2, vary(1.8))
	end,
	Station2 = function(build, arch, brainrot, center)
		Effects.tint(brainrot, GLITTER_COLOR, 0.7)
		sparkle(build, arch.Position - Vector3.new(0, arch.Size.Y / 2, 0), GLITTER_COLOR, 24)
		sparkle(build, center, SPARKLE_COLOR, 12)
		Effects.sound(center, Sounds.Coin, 0.35, vary(1.7))
	end,
}

-- The stations on a line, as the share of the ride where the brainrot passes under.
local function stationPasses(line: Model, from: Vector3, to: Vector3): { StationPass }
	local passes = {}
	local path = to - from
	local length = path.Magnitude
	if length < 0.01 then
		return passes
	end
	for key in STATION_FX do
		local arch = findPart(line, key)
		if arch then
			local alpha = (arch.Position - from):Dot(path.Unit) / length
			table.insert(passes, { Alpha = math.clamp(alpha, 0, 1), Key = key, Arch = arch })
		end
	end
	table.sort(passes, function(a, b)
		return a.Alpha < b.Alpha
	end)
	return passes
end

local function stationPass(build: Build, pass: StationPass, brainrot: Model)
	local box = brainrot:GetBoundingBox()
	local center = box.Position
	STATION_FX[pass.Key](build, pass.Arch, brainrot, center)

	local glow = findPart(build.Line, pass.Key .. "Glow")
	if glow then
		local info = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, true)
		TweenService:Create(glow, info, { Color = POP_COLOR }):Play()
	end
	local item = TycoonItems.ById[`{build.Line.Name}_{pass.Key}`]
	if item and item.Multiplier then
		Effects.popup(center + Vector3.new(0, 3, 0), `x{item.Multiplier}`, glow and glow.Color or POP_COLOR, 1, 0.6)
	end
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
	local build: Build = {
		Line = line,
		Root = root,
		Machines = getMachines(line, style),
		Built = {},
		FullMatch = fullMatch,
		Near = Effects.near(root.Position, FX_RANGE),
	}

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
			ChuteTop = findPart(line, partType .. "ChuteTop"),
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

	-- A plot reset (rebirth) clears the line mid-cycle: the brainrot goes with it (the
	-- server voids its payout too).
	local function cancelled(): boolean
		if line.Parent then
			return false
		end
		for _, piece in pieces do
			piece.Model:Destroy()
		end
		return true
	end

	-- 1-2) Each part drops onto the belt (a ceiling chute's slides down its glass tube
	-- into the nozzle first) and rides it at one constant speed, timed to reach the
	-- intake just as its assembly step starts.
	local speed = math.max(maxTravel, 1) / Production.SlideTime
	for _, step in steps do
		local piece = pieces[step.PartType]
		if not piece then
			continue
		end
		local ride = piece.Travel / speed
		task.spawn(function()
			waitUntil(step.Start - ride - Production.DropTime)
			if cancelled() then
				return
			end
			local top = piece.ChuteTop
			local chute: Chute? = nil
			if top then
				-- down the glass tube from the ceiling, the bands gulping as it passes
				-- (a chute that's still popping in just lets it slide)
				chute = if isBuilding(line) then nil else readChute(line, top)
				local from = centeredAt(piece.Center, top.Position)
				local to = centeredAt(piece.Center, piece.Dropper.Position)
				piece.Model:PivotTo(from)
				Effects.sound(top.Position, Sounds.Whoosh, 0.18, vary(1.5))
				run(Production.DropTime - FALL_TIME, function(alpha)
					local pivot = from:Lerp(to, ease(alpha, Enum.EasingStyle.Quad, Enum.EasingDirection.In))
					piece.Model:PivotTo(pivot)
					if chute then
						bulgeChute(chute, (pivot * CFrame.new(piece.Center)).Y)
					end
				end)
				if chute then
					bulgeChute(chute, -math.huge)
				end
			else
				waitUntil(step.Start - ride - FALL_TIME)
			end
			if cancelled() then
				return
			end
			spit(line, piece.Dropper, build.Near, chute)
			local below = piece.Dropper.Position
			local landing = centeredAt(piece.Center, Vector3.new(below.X, beltTop + piece.Size.Y / 2, below.Z))
			glide(piece.Model, landing, FALL_TIME, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out)
			waitUntil(step.Start - ride)
			if cancelled() then
				return
			end
			glide(piece.Model, piece.Waiting, ride, Enum.EasingStyle.Linear, Enum.EasingDirection.In)
		end)
	end

	-- 3) The zone's machines assemble it, one part at a time, with the beacon flashing.
	for index, step in steps do
		local piece = pieces[step.PartType]
		if not piece then
			continue
		end
		waitUntil(step.Start)
		if cancelled() then
			return
		end
		if index == 1 then
			setBeacon(line, true)
		end
		local animate = if build.Machines then style.Steps[step.PartType] else nil
		local ok, err = pcall(animate or simpleStep, build, piece, step.Duration)
		if not ok then
			if cancelled() then
				return -- its machines vanished mid-step
			end
			warn(`[ProductionVisuals] {zoneId} {step.PartType} step failed: {err}`)
			piece.Model:PivotTo(piece.Home)
		end
	end
	local _, finished = Production.Schedule(parts, cycleTime)
	waitUntil(finished)
	if cancelled() then
		return
	end
	setBeacon(line, false) -- in case the last step wasn't a head (no pop)

	-- 4) Ride through the stations to the chute as one brainrot, then drop in.
	local brainrot = Instance.new("Model")
	brainrot.Name = "Brainrot"
	for _, piece in pieces do
		piece.Model:PivotTo(piece.Home)
		piece.Model.Parent = brainrot
	end
	brainrot.WorldPivot = root
	brainrot.Parent = effects

	local passes = stationPasses(line, root.Position, shipRoot.Position)
	local nextPass = 1
	run(Production.ShipTime, function(alpha)
		brainrot:PivotTo(root:Lerp(shipRoot, alpha))
		local pass = passes[nextPass]
		if pass and alpha >= pass.Alpha and line.Parent then
			nextPass += 1
			stationPass(build, pass, brainrot)
		end
	end)
	if cancelled() then
		brainrot:Destroy()
		return
	end

	local top = ship.Position + Vector3.new(0, ship.Size.Y / 2 + 2, 0)
	local text = `+{Format.Number(value)} 💰` .. (if fullMatch then " x2!" else "")
	Effects.popup(top + Vector3.new(0, 1, 0), text, if fullMatch then MATCH_COLOR else COIN_COLOR, 2.2, 1.4)
	Effects.sound(top, Sounds.Whoosh, 0.2, vary(1.2))
	Effects.sound(top, Sounds.Cash, 0.3, vary(1))

	-- The coins spill out of the chute and hop over to the Cash Pad.
	local plot = line.Parent and line.Parent.Parent
	local pad = findPart(plot, "CashPad")
	if pad and build.Near then
		local count = math.clamp(2 + math.floor(math.log10(math.max(value, 1))), 3, 8)
		Effects.sound(top, Sounds.Coins, 0.25, vary(1))
		Effects.coins(top, pad.Position + Vector3.new(0, pad.Size.Y / 2 + 0.3, 0), count)
		sparkle(build, top, COIN_COLOR, 10)
	end

	-- Sink into the chute, shrinking away.
	local base = brainrot:GetScale()
	run(0.25, function(alpha)
		local e = ease(alpha, Enum.EasingStyle.Back, Enum.EasingDirection.In)
		brainrot:ScaleTo(base * math.max(1 - 0.9 * e, 0.05))
		brainrot:PivotTo(shipRoot - Vector3.new(0, CHUTE_DROP * e, 0))
	end)
	brainrot:Destroy()
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
