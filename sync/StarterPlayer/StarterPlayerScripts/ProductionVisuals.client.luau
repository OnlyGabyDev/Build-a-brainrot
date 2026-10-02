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
	    two punch presses BONK the arms into place with boxing gloves, and the claw
	    ratchets the head on. Pop!
	  * Plushie Sewing Room: the legs plop onto a cushion, the needle stitches the body
	    on, thread spools reel the arms in, and the needle pumps the head full of
	    stuffing. Pop!
	  * Clay Studio (stop-motion): the legs plop down, a big white glove presses the
	    body on, both gloves squish the arms in, and the head jumps into place frame by
	    frame between them, the camera flashing at every step. Pop!
	Then the finished brainrot shows itself off (ta-da: a spin under a spotlight, its
	name tag pops up) before it rides on: it's the star of the line, so it's big, gets
	an outline on your own lines, and keeps its name tag until it's packed off.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local BrainrotModels = require(Shared:WaitForChild("BrainrotModels"))
local Brainrots = require(Config:WaitForChild("Brainrots"))
local Format = require(Shared:WaitForChild("Format"))
local Production = require(Config:WaitForChild("Production"))
local Rarities = require(Config:WaitForChild("Rarities"))
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

local INTAKE_GAP = 5.5 -- studs before the pad where parts wait to be picked up
local HOP_HEIGHT = 2.5
local SQUISH = 0.85 -- scale at the bottom of a squash
local LOOSE = 1.25 -- the arms arrive this much too big, until they're pushed/reeled in
local GRIP_DEPTH = 0.3 -- how far the claw's grip sinks into the top of a part
local CLAW_CLEARANCE = 0.6 -- studs between a carried part and what it passes over
local FINGERS_CLOSED = 0.65 -- finger spread when gripping, as a share of open
local STITCHES = 6 -- needle stitches while sewing the body on
local STITCH_HOVER = 1.5 -- studs the body starts above its place
local DEFLATED = 0.35 -- the plushie head's starting scale, before it's stuffed
local CHUTE_DROP = 3 -- studs the brainrot sinks into the chute as it ships
local BELT_END_GAP = 2 -- studs from the end of the belt where the brainrot stops
local FALL_TIME = 0.5 -- a part's bounce from its dropper's mouth onto the belt
local SHOW_GAP = 5.5 -- studs down the belt from the pad where the brainrot shows itself off
local SHOW_HEIGHT = 3 -- how high it springs up as it spins
local SPOTLIGHT_COLOR = Color3.fromRGB(255, 245, 205)
local OUTLINE_COLOR = Color3.fromRGB(40, 25, 70) -- a cartoon ink line round your own brainrots
local TAG_STROKE = Color3.fromRGB(30, 25, 45)

type Piece = {
	Model: Model,
	Center: Vector3, -- the part's center relative to its pivot
	Size: Vector3,
	PartType: string,
	Scale: number, -- its full size (a knitted part starts tiny)
	Dropper: BasePart,
	ChuteTop: BasePart?, -- a ceiling chute's collar, where the part starts its slide
	Hanger: BasePart?, -- what a hanging dropper (chute, pillow) hangs from: it squashes
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
	Parts: { [string]: string }, -- [partType] = brainrotId
	Near: boolean, -- close enough to the camera for particles
	Zone: string,
	Name: string, -- what it's called (a mash-up for mixed builds)
	Rarity: string, -- its rarest part's tier
	Own: boolean, -- on the local player's plot
}

type StepAnimation = (build: Build, piece: Piece, duration: number) -> ()
-- Packs the finished brainrot up at the Ship spot and sends it off, in `duration`
-- seconds. Returns where the coins burst out.
type FinishAnimation = (build: Build, brainrot: Model, ship: BasePart, duration: number) -> Vector3
-- The zone's special upgrade (its Station3 `machine`) works on the brainrot at the end
-- of the belt, in `duration` seconds.
type SpecialAnimation = (build: Build, brainrot: Model, machine: BasePart, duration: number) -> ()

type Style = {
	-- Finds the zone's machines on a line and reads their resting poses. Nil if
	-- they're missing, and then every part just hops into place.
	Setup: (line: Model) -> any?,
	Steps: { [string]: StepAnimation },
	Finish: FinishAnimation?,
	Special: SpecialAnimation?,
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

-- Half the world height of `part`, however it's turned.
local function halfHeight(part: BasePart): number
	local frame, size = part.CFrame, part.Size
	return (math.abs(frame.RightVector.Y) * size.X + math.abs(frame.UpVector.Y) * size.Y + math.abs(frame.LookVector.Y) * size.Z) / 2
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

-- The Toy Workshop's ceiling chutes (TycoonManager.buildChute) are rubbery: their bands
-- bulge and light up as a part slides down past them, and the whole chute squashes and
-- stretches as it spits the part out, hanging from its collar in the ceiling.
type ChutePiece = {
	Part: BasePart,
	Rest: CFrame,
	Size: Vector3,
	Color: Color3,
	Material: Enum.Material,
	Axis: number, -- which of its Size's components runs up and down (1 = X, 2 = Y, 3 = Z)
}
type Chute = {
	Anchor: Vector3, -- where it hangs from: the bottom of its collar
	Pieces: { ChutePiece }, -- everything that stretches: tube, bands, badge, neck, nozzle
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

-- The `prefix` ("Head", "Body", ...) dropper hanging from `top`, read once while it's at
-- rest.
local function readChute(line: Model, top: BasePart, prefix: string): Chute
	local cached = chutes[top]
	if cached then
		return cached
	end
	local chute: Chute = {
		Anchor = top.Position - Vector3.new(0, top.Size.X / 2, 0), -- the collar stands on its side: X is its height
		Pieces = {},
		Bands = {},
		Owner = nil,
	}
	for _, child in line:GetChildren() do
		local name = child.Name
		local stretches = startsWith(name, prefix .. "Dropper")
			or startsWith(name, prefix .. "ChuteBadge")
			or name == prefix .. "ChuteTube"
			or name == prefix .. "ChuteBand"
			or name == prefix .. "ChuteNeck"
		if stretches and child:IsA("BasePart") then
			local frame = child.CFrame
			local axis = if math.abs(frame.RightVector.Y) > 0.9 then 1 elseif math.abs(frame.LookVector.Y) > 0.9 then 3 else 2
			local piece = { Part = child, Rest = frame, Size = child.Size, Color = child.Color, Material = child.Material, Axis = axis }
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

-- The bands near world height `y` swell and glow, as if the tube were gulping a part
-- down.
local function bulgeChute(chute: Chute, y: number)
	for _, band in chute.Bands do
		local near = math.max(0, 1 - math.abs(band.Rest.Position.Y - y) / CHUTE_BULGE_REACH)
		band.Part.Size = scaledSize(band, 1, 1 + CHUTE_BULGE * near)
		local lit = near > 0.15
		band.Part.Material = if lit then Enum.Material.Neon else band.Material
		band.Part.Color = if lit then band.Color:Lerp(Color3.new(1, 1, 1), 0.25 * near) else band.Color
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

-- The Plushie room's sock-knitting machines (TycoonManager.buildKnittingMachine):
-- while one knits a part, its needle ring whirls round the head, the yarn ball on top
-- rolls as it feeds the head, and the crank on the column turns.
type KnitSpinner = { Model: Model, Rest: CFrame, Axis: Vector3, Speed: number }
-- (the Clay Studio's play-dough presses work the same way, plus a plunger that pushes down)
type Plunger = { Model: Model, Rest: CFrame, Travel: number }
type Knitting = { Spinners: { KnitSpinner }, Plunger: Plunger? }

local KNIT_SPINS = { -- each moving bit: the axis it turns about (its own), radians per second
	KnitRing = { Vector3.yAxis, 24 },
	KnitYarn = { Vector3.xAxis, -12 },
	KnitCrank = { Vector3.xAxis, 14 },
}

local knittings: { [BasePart]: Knitting } = setmetatable({}, { __mode = "k" }) :: any

-- The `partType` machine knitting through `head`, read once while it's at rest.
local function readKnitting(line: Model, partType: string, head: BasePart): Knitting
	local cached = knittings[head]
	if cached then
		return cached
	end
	local knitting: Knitting = { Spinners = {} }
	for suffix, spin in KNIT_SPINS do
		local model = line:FindFirstChild(partType .. suffix)
		if model and model:IsA("Model") then
			table.insert(knitting.Spinners, { Model = model, Rest = model:GetPivot(), Axis = spin[1], Speed = spin[2] })
		end
	end
	local plunger = line:FindFirstChild(partType .. "PressPlunger")
	if plunger and plunger:IsA("Model") then
		local travel = plunger:GetAttribute("Travel")
		knitting.Plunger = { Model = plunger, Rest = plunger:GetPivot(), Travel = if typeof(travel) == "number" then travel else 2 }
	end
	knittings[head] = knitting
	return knitting
end

-- Poses the machine `t` seconds into its knitting, or at rest (nil). A press's plunger
-- pushes all the way down over the knitting time.
local function poseKnitting(knitting: Knitting, t: number?)
	for _, spinner in knitting.Spinners do
		spinner.Model:PivotTo(if t then spinner.Rest * CFrame.fromAxisAngle(spinner.Axis, t * spinner.Speed) else spinner.Rest)
	end
	local plunger = knitting.Plunger
	if plunger then
		local push = if t then math.clamp(t / (Production.DropTime - FALL_TIME), 0, 1) else 0
		plunger.Model:PivotTo(plunger.Rest - Vector3.new(0, plunger.Travel * ease(push, Enum.EasingStyle.Quad, Enum.EasingDirection.In), 0))
	end
end

-- The dropper squashes and spits its part out with a plop and a puff. A ceiling chute
-- does its rubbery squash instead, with a bigger splash; a knitting machine's head
-- squishes as it lets the part go in a puff of fluff.
local function spit(line: Model, dropper: BasePart, near: boolean, chute: Chute?)
	local mouth = dropper.Position - Vector3.new(0, halfHeight(dropper) + 0.3, 0)
	if dropper:GetAttribute("Knitting") then
		Effects.sound(mouth, Sounds.Plop, 0.3, vary(1.1))
		Effects.sound(mouth, Sounds.Squeak, 0.2, vary(1.4))
		local partColor = dropper:GetAttribute("PartColor")
		if near and dropper:GetAttribute("Press") and typeof(partColor) == "Color3" then
			-- a squelch of clay
			Effects.puff(mouth, partColor, 8, 0.7)
			Effects.puff(mouth, Color3.fromRGB(245, 200, 160), 5, 0.6)
			Effects.sparkle(mouth, partColor:Lerp(Color3.new(1, 1, 1), 0.5), 6)
		elseif near then
			Effects.puff(mouth, Color3.new(1, 1, 1), 10, 0.6)
			Effects.puff(mouth, dropper.Color:Lerp(Color3.new(1, 1, 1), 0.4), 6, 0.7)
			Effects.sparkle(mouth, Color3.fromRGB(255, 190, 230), 8)
		end
		if not isBuilding(line) then
			-- the head is a cylinder on its side: its X runs up and down
			local rest = dropper:GetAttribute("RestSize")
			if typeof(rest) ~= "Vector3" then
				rest = dropper.Size
				dropper:SetAttribute("RestSize", rest)
			end
			local restSize = rest :: Vector3
			dropper.Size = restSize
			local info = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, true)
			TweenService:Create(dropper, info, { Size = Vector3.new(restSize.X * 0.85, restSize.Y * 1.12, restSize.Z * 1.12) }):Play()
		end
		return
	end
	Effects.sound(mouth, Sounds.Plop, 0.35, vary(1))
	if chute then
		Effects.sound(mouth, Sounds.Squeak, 0.3, vary(1.35))
		Effects.sound(mouth, Sounds.Boing, 0.15, vary(1.7))
		if near then
			if dropper:GetAttribute("Feathers") then
				Effects.puff(mouth, Color3.new(1, 1, 1), 14, 0.5) -- a pillow: feathers everywhere
			end
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
	Riders: { { Part: BasePart, Offset: CFrame } }, -- the glove's cuff and thumb, from the fist
	Lamp: BasePart?,
}

type ToyMachines = { Claw: Claw, PusherLeft: Pusher, PusherRight: Pusher }

local function readPusher(model: Instance?): Pusher?
	local fist, rod = findPart(model, "Fist"), findPart(model, "Rod")
	if not (fist and rod) then
		return nil
	end
	local riders = {}
	for _, child in (model :: Instance):GetChildren() do
		if child:IsA("BasePart") and child ~= fist and startsWith(child.Name, "Fist") then
			table.insert(riders, { Part = child, Offset = fist.CFrame:ToObjectSpace(child.CFrame) })
		end
	end
	return {
		Fist = fist,
		Rod = rod,
		Shoulder = rod.CFrame * Vector3.new(0, 0, rod.Size.Z / 2), -- the fist is at the -Z end
		Rest = fist.CFrame,
		Riders = riders,
		Lamp = findPart(model, "PusherLamp"),
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
	for _, rider in pusher.Riders do
		rider.Part.CFrame = cframe * rider.Offset
	end
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

-- Clay Studio machines ---------------------------------------------------------------

type Glove = {
	Model: Model,
	Rod: BasePart,
	Rest: CFrame, -- the palm's middle at rest, -Z toward the pad
	RodTop: number, -- world Y where its rod meets the gantry
}

type ClayMachines = { Left: Glove, Right: Glove, Flash: BasePart? }

local CLAY_FLASH = Color3.fromRGB(255, 250, 235)
local CLAY_SPARK = Color3.fromRGB(255, 200, 150)
local GLOVE_WRIST = 2.5 -- from the palm's middle up to where its rod holds it
local PALM_HALF = 0.65 -- half the palm's thickness
local STOP_MOTION_FRAMES = 6

local function readGlove(line: Model, name: string, rodTop: number): Glove?
	local model = line:FindFirstChild(name)
	local rod = findPart(line, name .. "Rod")
	if not (model and model:IsA("Model") and rod) then
		return nil
	end
	return { Model = model, Rod = rod, Rest = model:GetPivot(), RodTop = rodTop }
end

local function setupClay(line: Model): ClayMachines?
	local assembler = findPart(line, "Assembler")
	if not assembler then
		return nil
	end
	local rodTop = assembler.Position.Y - assembler.Size.Y / 2
	local left, right = readGlove(line, "HandLeft", rodTop), readGlove(line, "HandRight", rodTop)
	if not (left and right) then
		return nil
	end
	return { Left = left, Right = right, Flash = findPart(line, "ClayFlash") }
end

-- Puts a glove's palm at `cframe`; its rod hangs straight down from the gantry to it.
local function setGlove(glove: Glove, cframe: CFrame)
	glove.Model:PivotTo(cframe)
	local wrist = (cframe * CFrame.new(0, GLOVE_WRIST, 0)).Position
	local length = math.max(glove.RodTop - wrist.Y, 0.05)
	glove.Rod.Size = Vector3.new(glove.Rod.Size.X, length, glove.Rod.Size.Z)
	glove.Rod.CFrame = glove.Rest.Rotation + Vector3.new(wrist.X, wrist.Y + length / 2, wrist.Z)
end

-- The glove's palm against the side of a piece of `width` at `center` (world), from its
-- own side: where it would rest, moved in.
local function gloveAgainst(glove: Glove, build: Build, center: Vector3, width: number): CFrame
	local local_ = build.Root:PointToObjectSpace(center)
	local side = if build.Root:PointToObjectSpace(glove.Rest.Position).X < 0 then -1 else 1
	local at = build.Root * Vector3.new(local_.X + side * (width / 2 + PALM_HALF), local_.Y, local_.Z)
	return glove.Rest.Rotation + at
end

-- Click! The stop-motion camera's bulb flashes.
local function snap(build: Build, loud: boolean?)
	local machines = build.Machines :: ClayMachines?
	local bulb = machines and machines.Flash
	local at = if bulb then bulb.Position else build.Root.Position + Vector3.new(0, 6, 0)
	Effects.sound(at, Sounds.Click, if loud then 0.4 else 0.25, vary(if loud then 1 else 1.3))
	if build.Near then
		Effects.flash(at, CLAY_FLASH, if loud then 4 else 2.5, if loud then 22 else 14, 0.2)
	end
	if bulb then
		bulb.Color = Color3.new(1, 1, 1)
		TweenService:Create(bulb, TweenInfo.new(0.25), { Color = Color3.fromRGB(255, 245, 210) }):Play()
	end
end

-- Finishing stages -----------------------------------------------------------
-- Past the end of the belt, each zone packs the brainrot up its own way (GDD §6),
-- and the payout lands as it's sent off.

local function newPart(parent: Instance, name: string, size: Vector3, cframe: CFrame, color: Color3, shape: Enum.PartType?): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Shape = shape or Enum.PartType.Block
	part.Parent = parent
	return part
end

-- The world height of the top of `part`, however it's turned.
local function topOf(part: BasePart): number
	return part.Position.Y + halfHeight(part)
end

-- The brainrot hops from where it stands to `target`, shrinking to `factor` of its
-- size on the way.
local function hopShrinking(brainrot: Model, target: CFrame, duration: number, height: number, factor: number)
	local start = brainrot:GetPivot()
	local base = brainrot:GetScale()
	run(duration, function(a)
		brainrot:ScaleTo(base * (1 - (1 - factor) * a))
		brainrot:PivotTo(start:Lerp(target, a) + Vector3.new(0, height * 4 * a * (1 - a), 0))
	end)
end

-- Toy Workshop: a toy box pops up out of the trapdoor, flips its lid open, the toy
-- jumps in, the lid slams, the box wiggles (the toy's excited) and drops back down.
local TOY_BOX = Vector3.new(7, 5, 7)
local TOY_BOX_COLORS = {
	{ Color3.fromRGB(255, 90, 110), Color3.fromRGB(255, 215, 70) },
	{ Color3.fromRGB(70, 165, 255), Color3.fromRGB(255, 255, 255) },
	{ Color3.fromRGB(110, 210, 90), Color3.fromRGB(255, 215, 70) },
	{ Color3.fromRGB(175, 115, 255), Color3.fromRGB(120, 230, 255) },
}
local LID_OPEN = math.rad(115)

type ToyBox = {
	Model: Model,
	Lid: { { Part: BasePart, Offset: CFrame } }, -- from the hinge, shut
	Hinge: CFrame, -- from the box's base: the lid's far edge
}

-- A toy box standing on `base` (-Z the way the belt runs: its lid hinges on that edge).
local function makeToyBox(base: CFrame): ToyBox
	local colors = TOY_BOX_COLORS[math.random(1, #TOY_BOX_COLORS)]
	local model = Instance.new("Model")
	model.Name = "ToyBox"
	local height = TOY_BOX.Y
	local body = newPart(model, "Body", TOY_BOX, base * CFrame.new(0, height / 2, 0), colors[1])
	newPart(model, "Band", Vector3.new(TOY_BOX.X + 0.3, 0.7, TOY_BOX.Z + 0.3), base * CFrame.new(0, 0.35, 0), colors[2])
	newPart(model, "Band", Vector3.new(TOY_BOX.X + 0.3, 0.5, TOY_BOX.Z + 0.3), base * CFrame.new(0, height - 0.25, 0), colors[2])
	newPart(model, "Inside", Vector3.new(TOY_BOX.X - 1, 0.06, TOY_BOX.Z - 1), base * CFrame.new(0, height + 0.03, 0), Color3.fromRGB(70, 40, 80))
	for _, face in { Enum.NormalId.Front, Enum.NormalId.Back, Enum.NormalId.Left, Enum.NormalId.Right } do
		local gui = Instance.new("SurfaceGui")
		gui.Face = face
		gui.LightInfluence = 0
		gui.PixelsPerStud = 20
		gui.Parent = body
		local star = Instance.new("TextLabel")
		star.Size = UDim2.fromScale(0.6, 0.6)
		star.Position = UDim2.fromScale(0.2, 0.22)
		star.BackgroundTransparency = 1
		star.TextScaled = true
		star.Text = "⭐"
		star.Parent = gui
	end

	local hinge = CFrame.new(0, height, -TOY_BOX.Z / 2)
	local lid = {}
	local function lidPart(name: string, size: Vector3, offset: CFrame, color: Color3)
		local part = newPart(model, name, size, base * hinge * offset, color)
		table.insert(lid, { Part = part, Offset = offset })
	end
	lidPart("Lid", Vector3.new(TOY_BOX.X + 0.4, 0.8, TOY_BOX.Z + 0.4), CFrame.new(0, 0.4, TOY_BOX.Z / 2), colors[2])
	lidPart("LidTop", Vector3.new(TOY_BOX.X - 1.6, 0.5, TOY_BOX.Z - 1.6), CFrame.new(0, 1, TOY_BOX.Z / 2), colors[1])
	lidPart("Latch", Vector3.new(1.4, 0.9, 0.4), CFrame.new(0, 0.1, TOY_BOX.Z + 0.35), COIN_COLOR)
	model.WorldPivot = base
	model.Parent = effects
	return { Model = model, Lid = lid, Hinge = hinge }
end

-- Swings the lid `angle` radians open (0 = shut).
local function setLid(box: ToyBox, angle: number)
	local hinge = box.Model:GetPivot() * box.Hinge * CFrame.Angles(-angle, 0, 0)
	for _, piece in box.Lid do
		piece.Part.CFrame = hinge * piece.Offset
	end
end

local function toyBoxFinish(build: Build, brainrot: Model, ship: BasePart, duration: number): Vector3
	local d = duration
	local rotation = brainrot:GetPivot().Rotation
	local base = rotation + Vector3.new(ship.Position.X, topOf(ship), ship.Position.Z)
	local center = base.Position + Vector3.new(0, TOY_BOX.Y / 2, 0)
	local box = makeToyBox(base)
	local model = box.Model

	-- up it pops, out of the trapdoor
	model:ScaleTo(0.05)
	Effects.sound(center, Sounds.Boing, 0.35, vary(1.25))
	puff(build, base.Position + Vector3.new(0, 0.5, 0), DUST_COLOR, 8, 0.8)
	run(d * 0.14, function(a)
		model:ScaleTo(math.max(ease(a, Enum.EasingStyle.Back, Enum.EasingDirection.Out), 0.05))
	end)
	model:ScaleTo(1)

	-- the lid flips open, and the toy jumps in, shrinking to fit
	Effects.sound(center, Sounds.Squeak, 0.2, vary(0.7))
	task.spawn(run, d * 0.12, function(a)
		if model.Parent then
			setLid(box, LID_OPEN * ease(a, Enum.EasingStyle.Back, Enum.EasingDirection.Out))
		end
	end)
	task.wait(d * 0.06)
	Effects.sound(brainrot:GetPivot().Position, Sounds.Boing, 0.3, vary(1.05))
	hopShrinking(brainrot, base * CFrame.new(0, 0.6, 0), d * 0.3, 6, 0.5)
	brainrot:Destroy()
	sparkle(build, center + Vector3.new(0, TOY_BOX.Y / 2, 0), SPARKLE_COLOR, 8)

	-- slam!
	run(d * 0.07, function(a)
		setLid(box, LID_OPEN * (1 - ease(a, Enum.EasingStyle.Quad, Enum.EasingDirection.In)))
	end)
	setLid(box, 0)
	Effects.sound(center, Sounds.Clunk, 0.35, vary(1.1))
	squish(model)
	puff(build, center + Vector3.new(0, TOY_BOX.Y / 2, 0), Color3.new(1, 1, 1), 6, 0.6)

	-- it wiggles: the toy inside is excited
	task.wait(d * 0.05)
	model:ScaleTo(1)
	Effects.sound(center, Sounds.Squeak, 0.25, vary(1.3))
	run(d * 0.18, function(a)
		local wobble = math.sin(a * math.pi * 6) * 0.14 * (1 - a)
		model:PivotTo(base * CFrame.Angles(wobble * 0.5, 0, wobble))
	end)
	model:PivotTo(base)

	-- and down the trapdoor it goes
	Effects.sound(center, Sounds.Whoosh, 0.25, vary(1.1))
	run(d * 0.14, function(a)
		local e = ease(a, Enum.EasingStyle.Back, Enum.EasingDirection.In)
		model:ScaleTo(math.max(1 - 0.4 * e, 0.05))
		model:PivotTo(base - Vector3.new(0, (TOY_BOX.Y + 1) * e, 0))
	end)
	model:Destroy()
	puff(build, base.Position + Vector3.new(0, 0.5, 0), DUST_COLOR, 8, 0.8)
	return base.Position + Vector3.new(0, 3, 0)
end

-- Plushie Sewing Room: the brainrot hops into the fluff machine's glass dome, fluff
-- swirls round and round it until it's puffed up, and it sinks into the cushy base.
local FLUFF_COLORS = { Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 225, 240), Color3.fromRGB(235, 240, 255) }
local HEART_COLOR = Color3.fromRGB(255, 120, 190)
local FLUFF_BALLS = 14

local function fluffFinish(build: Build, brainrot: Model, ship: BasePart, duration: number): Vector3
	local d = duration
	local rotation = brainrot:GetPivot().Rotation
	local base = rotation + Vector3.new(ship.Position.X, topOf(ship), ship.Position.Z)
	local center = base.Position + Vector3.new(0, 2, 0)

	-- in it hops, shrinking to fit under the dome
	Effects.sound(brainrot:GetPivot().Position, Sounds.Boing, 0.3, vary(0.85))
	hopShrinking(brainrot, base, d * 0.22, 6, 0.5)
	local size = brainrot:GetScale()
	puff(build, center, STUFFING_COLOR, 6)

	-- fluff swirls around it, more and more, and it puffs up
	local balls: { BasePart } = {}
	for index = 1, FLUFF_BALLS do
		local ball = newPart(effects, "Fluff", Vector3.one * (1.1 + (index % 3) * 0.35), CFrame.new(center), FLUFF_COLORS[index % #FLUFF_COLORS + 1], Enum.PartType.Ball)
		ball.Material = Enum.Material.Fabric
		ball.Transparency = 1
		balls[index] = ball
	end
	local beats = 0
	run(d * 0.48, function(a)
		for index, ball in balls do
			ball.Transparency = if a > (index - 1) / FLUFF_BALLS * 0.6 then 0 else 1
			local angle = index * 2.4 + a * 14 * (if index % 2 == 0 then 1 else -1)
			local radius = 3.2 + math.sin(a * 9 + index) * 0.6
			local height = 0.8 + (index % 4) * 1 + math.sin(a * 12 + index * 1.7) * 0.5
			ball.CFrame = CFrame.new(base.Position + Vector3.new(math.cos(angle) * radius, height, math.sin(angle) * radius))
		end
		brainrot:ScaleTo(size * (1 + 0.2 * ease(a) + 0.05 * math.sin(a * math.pi * 8)))
		local beat = math.floor(a * 4)
		if beat > beats then
			beats = beat
			Effects.sound(center, Sounds.Squeak, 0.22, 0.9 + beat * 0.15)
			puff(build, center, STUFFING_COLOR, 3)
		end
	end)

	-- all fluffed up!
	sparkle(build, center + Vector3.new(0, 1, 0), HEART_COLOR, 14)
	Effects.sound(center, Sounds.Pop, 0.35, vary(1.2))
	Effects.popup(center + Vector3.new(0, 6, 0), "FLUFFY!", HEART_COLOR, 1.2, 0.6)
	task.wait(d * 0.08)

	-- down into the base, fluff and all
	Effects.sound(center, Sounds.Whoosh, 0.22, vary(1.1))
	local grown = brainrot:GetScale()
	local start = brainrot:GetPivot()
	local sink = CFrame.new(base.Position - Vector3.new(0, 1, 0))
	run(d * 0.16, function(a)
		local e = ease(a, Enum.EasingStyle.Back, Enum.EasingDirection.In)
		brainrot:ScaleTo(math.max(grown * (1 - 0.95 * e), 0.02))
		brainrot:PivotTo(start - Vector3.new(0, 2 * e, 0))
		for _, ball in balls do
			ball.CFrame = ball.CFrame:Lerp(sink, e)
		end
	end)
	brainrot:Destroy()
	for _, ball in balls do
		ball:Destroy()
	end
	puff(build, center, STUFFING_COLOR, 10)
	return center + Vector3.new(0, 4, 0)
end

-- Clay Studio: the brainrot hops into the kiln through its glowing door; the kiln roars
-- (the door blazes, smoke pours out of the chimney) and it comes out baked.
local KILN_HOT = Color3.fromRGB(255, 230, 150)

local function kilnFinish(build: Build, brainrot: Model, ship: BasePart, duration: number): Vector3
	local d = duration
	local rotation = brainrot:GetPivot().Rotation
	local base = rotation + Vector3.new(ship.Position.X, topOf(ship), ship.Position.Z)
	local center = base.Position + Vector3.new(0, 3, 0)
	Effects.sound(brainrot:GetPivot().Position, Sounds.Boing, 0.3, vary(0.9))
	hopShrinking(brainrot, base * CFrame.new(0, 0.5, 0), d * 0.3, 4, 0.6)
	brainrot:Destroy()
	-- the door blazes, and smoke pours out
	local glow = findPart(build.Line, "KilnGlow")
	if glow then
		local cool = glow.Color
		glow.Color = KILN_HOT
		TweenService:Create(glow, TweenInfo.new(d * 0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Color = cool }):Play()
	end
	if build.Near then
		Effects.flash(center, Color3.fromRGB(255, 150, 60), 5, 22, d * 0.5)
	end
	Effects.sound(center, Sounds.Whoosh, 0.3, vary(0.7))
	local chimney = findPart(build.Line, "KilnChimneyCap")
	puff(build, if chimney then chimney.Position + Vector3.new(0, 1, 0) else center + Vector3.new(0, 7, 0), Color3.fromRGB(230, 225, 235), 12, 1.2)
	task.wait(d * 0.35)
	Effects.popup(center + Vector3.new(0, 6, 0), "BAKED!", Color3.fromRGB(255, 150, 60), 1.2, 0.6)
	Effects.sound(center, Sounds.Pop, 0.35, vary(0.9))
	sparkle(build, center + Vector3.new(0, 4, 0), Color3.fromRGB(255, 170, 80), 14)
	task.wait(d * 0.15)
	return center + Vector3.new(0, 4, 0)
end

-- Zones without a finish of their own: the brainrot hops onto the Ship spot and
-- sinks away.
local function simpleFinish(_build: Build, brainrot: Model, ship: BasePart, duration: number): Vector3
	local rotation = brainrot:GetPivot().Rotation
	local base = rotation + Vector3.new(ship.Position.X, topOf(ship), ship.Position.Z)
	hopShrinking(brainrot, base, duration * 0.4, 3, 0.9)
	local size = brainrot:GetScale()
	run(duration * 0.3, function(a)
		local e = ease(a, Enum.EasingStyle.Back, Enum.EasingDirection.In)
		brainrot:ScaleTo(math.max(size * (1 - 0.9 * e), 0.05))
		brainrot:PivotTo(base - Vector3.new(0, CHUTE_DROP * e, 0))
	end)
	brainrot:Destroy()
	return base.Position + Vector3.new(0, 3, 0)
end

-- Special upgrades -----------------------------------------------------------
-- Each zone's own last upgrade (Station3) stands over the end of the belt: as the
-- brainrot arrives, it does its thing before the finishing stage, with its multiplier.

-- The special machine's top gives a quick stamp, and its glow flashes.
local function stampMachine(build: Build, machine: BasePart)
	local glow = findPart(build.Line, "Station3Glow")
	if glow then
		local info = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, true)
		TweenService:Create(glow, info, { Color = POP_COLOR }):Play()
	end
	if isBuilding(build.Line) then
		return
	end
	local rest = machine:GetAttribute("RestSize")
	if typeof(rest) ~= "Vector3" then
		rest = machine.Size
		machine:SetAttribute("RestSize", rest)
	end
	local restSize = rest :: Vector3
	machine.Size = restSize
	local info = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, true)
	TweenService:Create(machine, info, { Size = Vector3.new(restSize.X * 1.05, restSize.Y * 0.8, restSize.Z * 1.05) }):Play()
end

local function specialPopup(build: Build, position: Vector3, color: Color3)
	local item = TycoonItems.ById[`{build.Line.Name}_Station3`]
	if item and item.Multiplier then
		Effects.popup(position, `x{item.Multiplier}`, color, 1, 0.6)
	end
end

-- Toy Workshop: the Toy Packer boxes the brainrot up in store packaging, like a toy
-- on a shop shelf: a card back printed with a sunburst, a header with the BRAINROT
-- TOYS logo, a hanging hole and a NEW! sticker, a name plate, and clear plastic over
-- the front and sides with white glints across it. Each piece drops down out of the
-- machine and slots into place, then a shine sweeps across the plastic.
local PACKAGE_COLORS = {
	Color3.fromRGB(255, 95, 125),
	Color3.fromRGB(70, 165, 255),
	Color3.fromRGB(255, 170, 40),
	Color3.fromRGB(150, 110, 255),
	Color3.fromRGB(60, 200, 140),
}
local PLASTIC_COLOR = Color3.fromRGB(225, 242, 255)
local LOGO_INK = Color3.fromRGB(45, 30, 70)

local function canvas(part: BasePart, face: Enum.NormalId, pixels: number): SurfaceGui
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = pixels
	gui.LightInfluence = 0
	gui.Parent = part
	return gui
end

local function frame(parent: Instance, size: UDim2, position: UDim2, color: Color3, transparency: number?): Frame
	local box = Instance.new("Frame")
	box.AnchorPoint = Vector2.new(0.5, 0.5)
	box.Size = size
	box.Position = position
	box.BackgroundColor3 = color
	box.BackgroundTransparency = transparency or 0
	box.BorderSizePixel = 0
	box.Parent = parent
	return box
end

local function words(parent: Instance, text: string, size: UDim2, position: UDim2, color: Color3, stroke: Color3?, thickness: number?): TextLabel
	local label = Instance.new("TextLabel")
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.Size = size
	label.Position = position
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = color
	label.Text = text
	label.Parent = parent
	if stroke then
		local outline = Instance.new("UIStroke")
		outline.Color = stroke
		outline.Thickness = thickness or 2
		outline.Parent = label
	end
	return label
end

-- The card back's print: a sunburst over a soft gradient, sparkles in the corners.
-- (Turned frames aren't cut off at a SurfaceGui's edges, so each ray is just long
-- enough to reach the card's edges.)
local CARD_PIXELS = 24
local function printCard(part: BasePart, color: Color3)
	local gui = canvas(part, Enum.NormalId.Front, CARD_PIXELS)
	local back = frame(gui, UDim2.fromScale(1, 1), UDim2.fromScale(0.5, 0.5), Color3.new(1, 1, 1))
	local shade = Instance.new("UIGradient")
	shade.Rotation = 90
	shade.Color = ColorSequence.new(color:Lerp(Color3.new(1, 1, 1), 0.45), color)
	shade.Parent = back
	local half = Vector2.new(part.Size.X, part.Size.Y) * CARD_PIXELS / 2
	local thickness = half.X * 0.3
	for index = 0, 5 do
		local turn = math.rad(index * 30)
		-- the ray runs along its own Y: how far it can go from the middle in that direction
		local along = math.min(half.X / math.max(math.abs(math.sin(turn)), 1e-3), half.Y / math.max(math.abs(math.cos(turn)), 1e-3))
		local ray = frame(back, UDim2.fromOffset(thickness, along * 2 - thickness * 0.6), UDim2.fromScale(0.5, 0.5), Color3.new(1, 1, 1), 0.72)
		ray.Rotation = index * 30
	end
	for _, spot in { Vector2.new(0.14, 0.12), Vector2.new(0.86, 0.2), Vector2.new(0.12, 0.8), Vector2.new(0.88, 0.85) } do
		words(back, "✦", UDim2.fromScale(0.16, 0.12), UDim2.fromScale(spot.X, spot.Y), Color3.fromRGB(255, 240, 150))
	end
end

-- The header: the hanging hole, the logo, and a NEW! sticker.
local function printHeader(part: BasePart, color: Color3)
	local gui = canvas(part, Enum.NormalId.Front, 30)
	local back = frame(gui, UDim2.fromScale(1, 1), UDim2.fromScale(0.5, 0.5), color)
	local hole = frame(back, UDim2.fromScale(0.2, 0.16), UDim2.fromScale(0.5, 0.15), LOGO_INK)
	local round = Instance.new("UICorner")
	round.CornerRadius = UDim.new(1, 0)
	round.Parent = hole
	words(back, "BRAINROT", UDim2.fromScale(0.66, 0.4), UDim2.fromScale(0.42, 0.5), Color3.new(1, 1, 1), LOGO_INK, 3)
	words(back, "★ TOYS ★", UDim2.fromScale(0.42, 0.24), UDim2.fromScale(0.42, 0.82), Color3.fromRGB(255, 225, 90), LOGO_INK, 2)
	local sticker = frame(back, UDim2.fromScale(0.2, 0.5), UDim2.fromScale(0.88, 0.36), Color3.fromRGB(255, 220, 60))
	sticker.Rotation = 14
	local stickerRound = Instance.new("UICorner")
	stickerRound.CornerRadius = UDim.new(1, 0)
	stickerRound.Parent = sticker
	words(sticker, "NEW!", UDim2.fromScale(0.86, 0.6), UDim2.fromScale(0.5, 0.5), Color3.fromRGB(255, 70, 110), Color3.new(1, 1, 1), 2)
end

-- Clear plastic's look: white glints slanting across it, a faint haze in one corner
-- and a bright rim. Returns the glints' gradient (its Offset sweeps them across).
local function glints(part: BasePart, face: Enum.NormalId): UIGradient
	local gui = canvas(part, face, 24)
	local sheen = frame(gui, UDim2.fromScale(1, 1), UDim2.fromScale(0.5, 0.5), Color3.new(1, 1, 1))
	local gradient = Instance.new("UIGradient")
	gradient.Rotation = -50
	gradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.55),
		NumberSequenceKeypoint.new(0.16, 1),
		NumberSequenceKeypoint.new(0.34, 1),
		NumberSequenceKeypoint.new(0.35, 0.15),
		NumberSequenceKeypoint.new(0.43, 0.15),
		NumberSequenceKeypoint.new(0.44, 1),
		NumberSequenceKeypoint.new(0.5, 1),
		NumberSequenceKeypoint.new(0.51, 0.45),
		NumberSequenceKeypoint.new(0.54, 0.45),
		NumberSequenceKeypoint.new(0.55, 1),
		NumberSequenceKeypoint.new(1, 1),
	})
	gradient.Parent = sheen
	local rim = Instance.new("UIStroke")
	rim.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	rim.Color = Color3.new(1, 1, 1)
	rim.Transparency = 0.25
	rim.Thickness = 4
	rim.Parent = sheen
	return gradient
end

local function packerSpecial(build: Build, brainrot: Model, machine: BasePart, duration: number)
	local box, size = brainrot:GetBoundingBox()
	local pivot = brainrot:GetPivot()
	local base = pivot.Rotation + Vector3.new(box.X, pivot.Y, box.Z) -- the package's floor, under the brainrot
	local width, height, depth = size.X + 1.6, size.Y + 1.6, math.max(size.Z + 1.2, 3)
	local color = PACKAGE_COLORS[math.random(1, #PACKAGE_COLORS)]
	local deep = color:Lerp(Color3.new(0, 0, 0), 0.18)
	local plate = 1.3 -- the name plate under the window

	-- { part, where it ends up (from `base`), when it starts dropping (share of the packing) }
	local pieces: { { Part: BasePart, Home: CFrame, Start: number } } = {}
	local function piece(name: string, partSize: Vector3, home: CFrame, partColor: Color3, start: number): Part
		local part = newPart(brainrot, name, partSize, base * home + Vector3.new(0, 8, 0), partColor)
		part.Transparency = 1
		table.insert(pieces, { Part = part, Home = home, Start = start })
		return part
	end
	local function plastic(name: string, partSize: Vector3, home: CFrame, face: Enum.NormalId): UIGradient
		local part = piece(name, partSize, home, PLASTIC_COLOR, 0.46)
		part.Reflectance = 0.15
		part:SetAttribute("Clear", true)
		return glints(part, face)
	end

	piece("PackageTray", Vector3.new(width, 0.5, depth), CFrame.new(0, 0.25, 0), deep, 0)
	local back = piece("PackageBack", Vector3.new(width, height, 0.3), CFrame.new(0, height / 2, depth / 2), color, 0.1)
	printCard(back, color)
	local header = piece("PackageHeader", Vector3.new(width, 2.8, 0.3), CFrame.new(0, height + 1.4, depth / 2), deep, 0.1)
	printHeader(header, deep)
	piece("PackageLid", Vector3.new(width, 0.4, depth), CFrame.new(0, height - 0.2, 0), deep, 0.22)
	-- the front frame: posts either side, a strip across the top, the name plate below
	for _, side in { -1, 1 } do
		piece("PackagePost", Vector3.new(0.5, height - 0.4, 0.4), CFrame.new(side * (width / 2 - 0.25), height / 2, -depth / 2), color, 0.3)
	end
	piece("PackageTop", Vector3.new(width, 0.5, 0.4), CFrame.new(0, height - 0.65, -depth / 2), color, 0.3)
	local nameplate = piece("PackagePlate", Vector3.new(width, plate, 0.4), CFrame.new(0, 0.5 + plate / 2, -depth / 2), color, 0.3)
	local gui = canvas(nameplate, Enum.NormalId.Front, 30)
	local stripe = frame(gui, UDim2.fromScale(1, 1), UDim2.fromScale(0.5, 0.5), color)
	local name = string.upper(build.Name)
	words(stripe, name, UDim2.fromScale(0.94, 0.8), UDim2.fromScale(0.5, 0.5), Color3.new(1, 1, 1), LOGO_INK, 2)
	-- the clear plastic: a front window and both sides
	local inner = height - plate - 1.4
	local sweep = plastic("PackageWindow", Vector3.new(width - 1, inner, 0.12), CFrame.new(0, 0.5 + plate + inner / 2, -depth / 2 - 0.05), Enum.NormalId.Front)
	for _, side in { -1, 1 } do
		plastic("PackageSideWindow", Vector3.new(0.12, height - 1.1, depth - 0.7), CFrame.new(side * (width / 2 - 0.05), height / 2, 0), if side < 0 then Enum.NormalId.Left else Enum.NormalId.Right)
	end

	stampMachine(build, machine)
	Effects.sound(base.Position, Sounds.Servo, 0.25, vary(1.3))
	local drop, landed = 0.2, {} -- each piece drops for this share of the packing
	run(duration * 0.7, function(a)
		for index, entry in pieces do
			local fall = math.clamp((a - entry.Start) / drop, 0, 1)
			if fall > 0 then
				entry.Part.Transparency = if entry.Part:GetAttribute("Clear") then 0.72 else 0
				local e = ease(fall, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
				entry.Part.CFrame = base * entry.Home + Vector3.new(0, 8 * (1 - e), 0)
				if fall >= 1 and not landed[index] then
					landed[index] = true
					if index == 1 or index == 4 or index == #pieces then
						Effects.sound(entry.Part.Position, Sounds.Stamp, 0.25, vary(1.2 + index * 0.05))
					end
				end
			end
		end
	end)
	for _, entry in pieces do
		entry.Part.CFrame = base * entry.Home
	end
	squish(brainrot)
	-- a shine sweeps across the plastic
	sweep.Offset = Vector2.new(-0.9, 0)
	TweenService:Create(sweep, TweenInfo.new(duration * 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Offset = Vector2.zero }):Play()
	local top = base.Position + Vector3.new(0, height + 3, 0)
	sparkle(build, top, SPARKLE_COLOR, 12)
	sparkle(build, base.Position + Vector3.new(0, height / 2, 0), Color3.new(1, 1, 1), 8)
	Effects.sound(top, Sounds.Pop, 0.3, vary(1.3))
	Effects.popup(top + Vector3.new(0, 1.5, 0), "PACKED!", color, 1.2, 0.6)
	specialPopup(build, top, color)
	task.wait(duration * 0.3)
end

-- Plushie Sewing Room: the Bow Tier drops a big ribbon bow onto the brainrot's head.
local BOW_COLOR = Color3.fromRGB(255, 110, 180)

local function bowSpecial(build: Build, brainrot: Model, machine: BasePart, duration: number)
	local frame, size = brainrot:GetBoundingBox()
	local rotation = brainrot:GetPivot().Rotation
	local head = rotation + (frame.Position + Vector3.new(0, size.Y / 2 + 0.5, 0))
	local bow = Instance.new("Model")
	bow.Name = "Bow"
	local knot = newPart(bow, "BowKnot", Vector3.one * 1.1, head, BOW_COLOR, Enum.PartType.Ball)
	knot.Material = Enum.Material.Fabric
	for _, side in { -1, 1 } do
		-- a loop each side: a flat disc tipped up and out
		local loop = newPart(bow, "BowLoop", Vector3.new(0.5, 2.4, 2.4), head * CFrame.new(side * 1.25, 0.25, 0) * CFrame.Angles(0, math.pi / 2, side * math.rad(-20)), BOW_COLOR, Enum.PartType.Cylinder)
		loop.Material = Enum.Material.Fabric
		local tail = newPart(bow, "BowTail", Vector3.new(0.5, 1.6, 0.2), head * CFrame.new(side * 0.6, -0.8, -0.2) * CFrame.Angles(0, 0, side * math.rad(25)), BOW_COLOR:Lerp(Color3.new(1, 1, 1), 0.2))
		tail.Material = Enum.Material.Fabric
	end
	bow.WorldPivot = head
	bow.Parent = brainrot

	stampMachine(build, machine)
	Effects.sound(head.Position, Sounds.Sewing, 0.2, vary(1.5))
	local from = head + Vector3.new(0, 7, 0)
	bow:PivotTo(from)
	run(duration * 0.45, function(a)
		bow:PivotTo(from:Lerp(head, ease(a, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out)) * CFrame.Angles(0, (1 - a) * math.pi * 2, 0))
	end)
	bow:PivotTo(head)
	squish(brainrot)
	sparkle(build, head.Position, Color3.fromRGB(255, 150, 210), 14)
	Effects.sound(head.Position, Sounds.Squeak, 0.3, vary(1.2))
	Effects.sound(head.Position, Sounds.Pop, 0.25, vary(1.4))
	Effects.popup(head.Position + Vector3.new(0, 2.5, 0), "CUTE!", BOW_COLOR, 1.2, 0.6)
	specialPopup(build, head.Position + Vector3.new(0, 1, 0), BOW_COLOR)
	task.wait(duration * 0.4)
end

-- Clay Studio: the Stop-Motion Camera shoots the brainrot in three quick poses (a flash
-- each), and the photo slides out and flutters away.
local SNAP_POSES = { { -0.45, 0.8 }, { 0.45, 1.2 }, { 0, 0 } } -- { turn, lift }

local function cameraSpecial(build: Build, brainrot: Model, machine: BasePart, duration: number)
	local pivot = brainrot:GetPivot()
	local box = brainrot:GetBoundingBox()
	local lens = machine.Position - Vector3.new(0, machine.Size.Y / 2 + 1.5, 0)
	local flash = findPart(build.Line, "Station3Flash")
	stampMachine(build, machine)
	for _, pose in SNAP_POSES do
		local from = brainrot:GetPivot()
		local to = pivot * CFrame.Angles(0, pose[1], 0) + Vector3.new(0, pose[2], 0)
		run(duration * 0.12, function(a)
			brainrot:PivotTo(from:Lerp(to, ease(a, Enum.EasingStyle.Back, Enum.EasingDirection.Out)))
		end)
		Effects.sound(lens, Sounds.Click, 0.4, vary(1.1))
		if build.Near then
			Effects.flash(if flash then flash.Position else lens, Color3.new(1, 1, 1), 5, 24, 0.25)
		end
		sparkle(build, box.Position, Color3.new(1, 1, 1), 6)
		task.wait(duration * 0.1)
	end
	brainrot:PivotTo(pivot)
	-- the photo: a white card with the brainrot's name, sliding out and fluttering off
	local photo = newPart(effects, "Photo", Vector3.new(3, 3.6, 0.15), CFrame.new(lens) * pivot.Rotation, Color3.new(1, 1, 1))
	local gui = canvas(photo, Enum.NormalId.Front, 40)
	frame(gui, UDim2.fromScale(0.86, 0.66), UDim2.fromScale(0.5, 0.4), Color3.fromRGB(150, 210, 255))
	words(gui, "📸", UDim2.fromScale(0.5, 0.4), UDim2.fromScale(0.5, 0.4), Color3.new(1, 1, 1))
	words(gui, string.upper(build.Name), UDim2.fromScale(0.9, 0.18), UDim2.fromScale(0.5, 0.86), Color3.fromRGB(60, 50, 70))
	local start = photo.CFrame
	task.spawn(function()
		run(1.1, function(a)
			if photo.Parent then
				photo.CFrame = start * CFrame.new(math.sin(a * 6) * 1.2, 3 * a, -2 * a) * CFrame.Angles(0, a * 3, math.sin(a * 8) * 0.4)
				photo.Transparency = math.max(a - 0.6, 0) / 0.4
			end
		end)
		photo:Destroy()
	end)
	Effects.popup(lens + Vector3.new(0, 2, 0), "SNAP!", Color3.fromRGB(60, 205, 195), 1.2, 0.6)
	specialPopup(build, lens, Color3.fromRGB(60, 205, 195))
	task.wait(duration * 0.24)
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
		Special = packerSpecial,
		Finish = toyBoxFinish,
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
				local reach = piece.Size.X / 2 + machines.PusherLeft.Fist.Size.X / 2
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
				for pusher, target in punches do
					sparkle(build, target.Position, BONK_COLOR, 6)
					if pusher.Lamp and build.Near then
						Effects.flash(pusher.Lamp.Position, Color3.fromRGB(255, 170, 40), 3, 8, 0.3)
					end
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
		Special = bowSpecial,
		Finish = fluffFinish,
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
	ClayStudio = {
		Setup = setupClay,
		Special = cameraSpecial,
		Finish = kilnFinish,
		Steps = {
			-- The legs plop down onto the pad with a squish. Click!
			Legs = function(build, piece, duration)
				Effects.sound(homeCenter(piece), Sounds.Boing, 0.25, vary(0.9))
				hop(piece.Model, piece.Home, duration * 0.7, 3)
				place(build, piece, CLAY_SPARK, 6, Sounds.Squeak, 0.3)
				puff(build, build.Root.Position + Vector3.new(0, 0.4, 0), CLAY_SPARK, 6, 0.6)
				snap(build)
			end,

			-- The body hovers over the legs, and a glove comes over, palm down, and
			-- presses it on. Squish! Click!
			Body = function(build, piece, duration)
				local machines = build.Machines :: ClayMachines
				local glove = machines.Right
				local lift = 2
				hop(piece.Model, piece.Home + Vector3.new(0, lift, 0), duration * 0.25, HOP_HEIGHT)
				local center = homeCenter(piece)
				local palmDown = glove.Rest.Rotation * CFrame.Angles(math.rad(-90), 0, 0)
				local function over(height: number): CFrame
					return palmDown + Vector3.new(center.X, center.Y + piece.Size.Y / 2 + PALM_HALF + height, center.Z)
				end
				local above = over(lift + 2)
				run(duration * 0.25, function(a)
					setGlove(glove, glove.Rest:Lerp(above, ease(a)))
				end)
				run(duration * 0.2, function(a)
					local e = ease(a, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
					setGlove(glove, above:Lerp(over(0), e))
					piece.Model:PivotTo(piece.Home + Vector3.new(0, lift * (1 - e), 0))
				end)
				place(build, piece, CLAY_SPARK, 10, Sounds.Squeak, 0.3)
				snap(build)
				run(duration * 0.25, function(a)
					setGlove(glove, over(0):Lerp(glove.Rest, ease(a)))
				end)
				setGlove(glove, glove.Rest)
			end,

			-- The arms land too wide, and both gloves squish them in. Click!
			Arms = function(build, piece, duration)
				local machines = build.Machines :: ClayMachines
				local model = piece.Model
				local base = model:GetScale()
				hopInLoose(piece, duration * 0.35)
				local center = homeCenter(piece)
				local targets = {
					[machines.Left] = gloveAgainst(machines.Left, build, center, piece.Size.X),
					[machines.Right] = gloveAgainst(machines.Right, build, center, piece.Size.X),
				}
				run(duration * 0.3, function(a)
					local e = ease(a, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
					for glove, target in targets do
						setGlove(glove, glove.Rest:Lerp(target, e))
					end
					model:ScaleTo(base * (LOOSE - (LOOSE - 1) * e))
				end)
				model:ScaleTo(base)
				place(build, piece, CLAY_SPARK, 12, Sounds.Squeak, 0.35)
				Effects.popup(center + Vector3.new(0, 1.5, 0), "SQUISH!", Color3.fromRGB(255, 150, 90), 1, 0.5)
				snap(build)
				run(duration * 0.25, function(a)
					local e = ease(a, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
					for glove, target in targets do
						setGlove(glove, target:Lerp(glove.Rest, e))
					end
				end)
			end,

			-- Stop-motion: the head jumps into place a frame at a time between the gloves,
			-- the camera clicking each frame. Pop!
			Head = function(build, piece, duration)
				local machines = build.Machines :: ClayMachines
				local start = piece.Model:GetPivot()
				local frameTime = duration * 0.75 / STOP_MOTION_FRAMES
				for frameIndex = 1, STOP_MOTION_FRAMES do
					local a = frameIndex / STOP_MOTION_FRAMES
					local wiggle = if frameIndex < STOP_MOTION_FRAMES then (if frameIndex % 2 == 0 then 0.25 else -0.25) else 0
					local pivot = start:Lerp(piece.Home, a) * CFrame.Angles(0, wiggle, 0) + Vector3.new(0, 2 * math.sin(a * math.pi), 0)
					piece.Model:PivotTo(pivot)
					local center = (pivot * CFrame.new(piece.Center)).Position
					setGlove(machines.Left, gloveAgainst(machines.Left, build, center, piece.Size.X))
					setGlove(machines.Right, gloveAgainst(machines.Right, build, center, piece.Size.X))
					snap(build, frameIndex == STOP_MOTION_FRAMES)
					task.wait(frameTime)
				end
				piece.Model:PivotTo(piece.Home)
				place(build, piece, POP_COLOR, 12, Sounds.Stamp, 0.2)
				pop(build)
				local holding = { machines.Left.Model:GetPivot(), machines.Right.Model:GetPivot() }
				run(duration * 0.2, function(a)
					setGlove(machines.Left, holding[1]:Lerp(machines.Left.Rest, ease(a)))
					setGlove(machines.Right, holding[2]:Lerp(machines.Right.Rest, ease(a)))
				end)
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

-- Zones can give the stations their own effects (and TycoonManager their own arches).
local DYE_COLORS = {
	Color3.fromRGB(255, 120, 190),
	Color3.fromRGB(150, 110, 255),
	Color3.fromRGB(90, 200, 255),
	Color3.fromRGB(255, 200, 80),
}
local CLAY_PAINTS = {
	Color3.fromRGB(255, 100, 120),
	Color3.fromRGB(255, 200, 60),
	Color3.fromRGB(90, 190, 255),
	Color3.fromRGB(130, 220, 110),
	Color3.fromRGB(190, 130, 255),
}
local ZONE_STATION_FX: { [string]: { [string]: (build: Build, arch: BasePart, brainrot: Model, center: Vector3) -> () } } = {
	ClayStudio = {
		-- the Color Squish presses a blob of colored clay onto it
		Station1 = function(build, arch, brainrot, center)
			local color = CLAY_PAINTS[math.random(1, #CLAY_PAINTS)]
			Effects.tint(brainrot, color, 0.8)
			squish(brainrot)
			puff(build, center, color, 10, 0.7)
			puff(build, arch.Position - Vector3.new(0, arch.Size.Y / 2, 0), color, 5, 0.5)
			Effects.sound(center, Sounds.Squeak, 0.25, vary(0.9))
		end,
		-- the Sparkle Glaze drips a glossy coat over it
		Station2 = function(build, arch, brainrot, center)
			Effects.tint(brainrot, Color3.fromRGB(255, 250, 235), 0.7)
			sparkle(build, arch.Position - Vector3.new(0, arch.Size.Y / 2, 0), Color3.fromRGB(240, 250, 255), 16)
			sparkle(build, center, Color3.new(1, 1, 1), 12)
			Effects.sound(center, Sounds.Coin, 0.35, vary(1.6))
		end,
	},
	PlushieRoom = {
		-- the Dye Bath dips it in fabric dye: a splash of color and bubbles
		Station1 = function(build, arch, brainrot, center)
			local color = DYE_COLORS[math.random(1, #DYE_COLORS)]
			Effects.tint(brainrot, color, 0.8)
			puff(build, center, color, 12, 0.6)
			puff(build, arch.Position + Vector3.new(0, 2, 0), color, 6, 0.5)
			Effects.sound(center, Sounds.Squeak, 0.25, vary(0.8))
			Effects.sound(center, Sounds.Whoosh, 0.15, vary(1.4))
		end,
		-- the Sequin Shower rains sequins from its disco ball
		Station2 = function(build, arch, brainrot, center)
			Effects.tint(brainrot, Color3.fromRGB(255, 190, 235), 0.7)
			sparkle(build, arch.Position + Vector3.new(0, 2.4, 0), Color3.fromRGB(255, 170, 230), 18)
			sparkle(build, center, Color3.fromRGB(220, 230, 255), 14)
			Effects.sound(center, Sounds.Coin, 0.35, vary(1.9))
		end,
	},
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
	local zoneFx = ZONE_STATION_FX[build.Zone]
	local fx = (if zoneFx then zoneFx[pass.Key] else nil) or STATION_FX[pass.Key]
	fx(build, pass.Arch, brainrot, center)

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

-- The show ------------------------------------------------------------------
-- The finished brainrot is the star of the line: it shows itself off under a
-- spotlight, a name tag (its name, its rarest tier) rides over it until it's packed
-- off, and on your own lines it gets a cartoon outline so it stands out from the busy,
-- colorful machines.

type Star = { Tag: BillboardGui?, Outline: Highlight?, Light: PointLight? }

local localPlayer = Players.LocalPlayer

local function isOwnLine(line: Model): boolean
	local plot = line.Parent and line.Parent.Parent
	return plot ~= nil and plot.Name == `Plot{localPlayer:GetAttribute("PlotIndex")}`
end

-- The name tag over the brainrot: its name, and its rarest tier in that tier's color
-- (Godly in a rainbow). It pops in with a bounce.
local function makeTag(build: Build, brainrot: Model): BillboardGui
	local anchor = newPart(brainrot, "TagAnchor", Vector3.one * 0.2, brainrot:GetPivot(), Color3.new(1, 1, 1))
	anchor.Transparency = 1
	local _, size = brainrot:GetBoundingBox()
	local gui = Instance.new("BillboardGui")
	gui.Name = "NameTag"
	gui.Size = UDim2.fromScale(9, 2.6)
	gui.StudsOffset = Vector3.new(0, size.Y + 2.2, 0)
	gui.AlwaysOnTop = true
	gui.LightInfluence = 0
	gui.MaxDistance = 110
	gui.Adornee = anchor
	gui.Parent = anchor

	local scale = Instance.new("UIScale")
	scale.Scale = 0.2
	scale.Parent = gui
	local name = Instance.new("TextLabel")
	name.Size = UDim2.fromScale(1, 0.62)
	name.BackgroundTransparency = 1
	name.Font = Enum.Font.FredokaOne
	name.TextScaled = true
	name.TextColor3 = Color3.new(1, 1, 1)
	name.Text = build.Name
	name.Parent = gui
	local nameStroke = Instance.new("UIStroke")
	nameStroke.Thickness = 3
	nameStroke.Color = TAG_STROKE
	nameStroke.Parent = name

	local rarity = Rarities.ById[build.Rarity]
	local tier = Instance.new("TextLabel")
	tier.Size = UDim2.fromScale(1, 0.38)
	tier.Position = UDim2.fromScale(0, 0.62)
	tier.BackgroundTransparency = 1
	tier.Font = Enum.Font.FredokaOne
	tier.TextScaled = true
	tier.TextColor3 = if rarity then rarity.Color else Color3.new(1, 1, 1)
	tier.Text = if build.FullMatch then `⭐ {string.upper(build.Rarity)} ⭐` else string.upper(build.Rarity)
	tier.Parent = gui
	local tierStroke = Instance.new("UIStroke")
	tierStroke.Thickness = 2.5
	tierStroke.Color = TAG_STROKE
	tierStroke.Parent = tier
	if build.Rarity == "Godly" then
		local rainbow = Instance.new("UIGradient")
		rainbow.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 90, 90)),
			ColorSequenceKeypoint.new(0.25, Color3.fromRGB(255, 220, 60)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(90, 230, 120)),
			ColorSequenceKeypoint.new(0.75, Color3.fromRGB(80, 170, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(220, 110, 255)),
		})
		rainbow.Parent = tier
	end
	TweenService:Create(scale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	return gui
end

-- Makes the finished brainrot the star: a name tag on lines near the camera, and on
-- your own lines an outline and a soft glow of its own.
local function crown(build: Build, brainrot: Model): Star
	local star: Star = {}
	if not build.Near then
		return star
	end
	star.Tag = makeTag(build, brainrot)
	if build.Own then
		local outline = Instance.new("Highlight")
		outline.FillTransparency = 1
		outline.OutlineColor = OUTLINE_COLOR
		outline.OutlineTransparency = 0
		outline.DepthMode = Enum.HighlightDepthMode.Occluded
		outline.Parent = brainrot
		star.Outline = outline
		local light = Instance.new("PointLight")
		light.Color = SPOTLIGHT_COLOR
		light.Brightness = 0.8
		light.Range = 9
		light.Shadows = false
		light.Parent = (star.Tag :: BillboardGui).Parent
		star.Light = light
	end
	return star
end

-- Its moment is over (it's being packed off): the tag shrinks away, the outline goes.
local function uncrown(star: Star)
	if star.Outline then
		star.Outline:Destroy()
	end
	if star.Light then
		star.Light:Destroy()
	end
	local tag = star.Tag
	if tag and tag.Parent then
		local scale = tag:FindFirstChildOfClass("UIScale")
		if scale then
			TweenService:Create(scale, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In), { Scale = 0 }):Play()
		end
		Debris:AddItem(tag, 0.25)
	end
end

-- Ta-da! The brainrot steps off the pad to `spot`, springs up spinning under a beam of
-- light (sparkles, a ring, a chime), and lands with a squash, in `duration` seconds.
local function showOff(build: Build, brainrot: Model, from: CFrame, spot: CFrame, duration: number)
	local d = duration
	run(d * 0.2, function(a)
		brainrot:PivotTo(from:Lerp(spot, ease(a, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)))
	end)

	local beam: BasePart? = nil
	local glow: BasePart? = nil
	if build.Near then
		local height = 16
		beam = newPart(effects, "Spotlight", Vector3.new(height, 7, 7), spot * CFrame.new(0, height / 2, 0) * CFrame.Angles(0, 0, math.pi / 2), SPOTLIGHT_COLOR, Enum.PartType.Cylinder)
		glow = newPart(effects, "SpotlightPool", Vector3.new(0.1, 8, 8), spot * CFrame.new(0, 0.06, 0) * CFrame.Angles(0, 0, math.pi / 2), SPOTLIGHT_COLOR, Enum.PartType.Cylinder)
		for _, part in { beam :: BasePart, glow :: BasePart } do
			part.Material = Enum.Material.Neon
			part.Transparency = 1
			TweenService:Create(part, TweenInfo.new(d * 0.15), { Transparency = if part == beam then 0.86 else 0.55 }):Play()
		end
		Effects.flash(spot.Position + Vector3.new(0, 4, 0), SPOTLIGHT_COLOR, 2.5, 16, d * 0.8)
		sparkle(build, spot.Position + Vector3.new(0, 3, 0), POP_COLOR, 16)
		Effects.ring(spot.Position + Vector3.new(0, 0.1, 0), POP_COLOR, 5)
	end
	Effects.sound(spot.Position, Sounds.Coin, 0.3, vary(1.5))
	Effects.sound(spot.Position, Sounds.Boing, 0.25, vary(1.3))

	local base = brainrot:GetScale()
	run(d * 0.55, function(a)
		local e = ease(a, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
		local lift = SHOW_HEIGHT * math.sin(a * math.pi)
		brainrot:ScaleTo(base * (1 + 0.12 * math.sin(a * math.pi)))
		brainrot:PivotTo(spot * CFrame.new(0, lift, 0) * CFrame.Angles(0, e * math.pi * 2, 0))
	end)
	brainrot:ScaleTo(base)
	brainrot:PivotTo(spot)
	squish(brainrot)
	puff(build, spot.Position + Vector3.new(0, 0.4, 0), DUST_COLOR, 6, 0.6)
	Effects.sound(spot.Position, Sounds.Stamp, 0.2, vary(1.2))

	for _, part in { beam, glow } do
		if part then
			TweenService:Create(part, TweenInfo.new(d * 0.2), { Transparency = 1 }):Play()
			Debris:AddItem(part, d * 0.25)
		end
	end
	task.wait(d * 0.25)
end

-- One production cycle -------------------------------------------------------

local function animateCycle(
	line: Model,
	parts: { [string]: string },
	zoneId: string,
	value: number,
	fullMatch: boolean,
	cycleTime: number,
	special: boolean
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
	-- the far end of the belt, where it runs out (its -Z end)
	local beltEnd = rotation + belt.CFrame * Vector3.new(0, belt.Size.Y / 2, -belt.Size.Z / 2 + BELT_END_GAP)
	local style = ASSEMBLY_STYLES[zoneId] or DEFAULT_STYLE
	local build: Build = {
		Line = line,
		Root = root,
		Machines = getMachines(line, style),
		Built = {},
		FullMatch = fullMatch,
		Parts = parts,
		Near = Effects.near(root.Position, FX_RANGE),
		Zone = zoneId,
		Name = Brainrots.NameOf(parts),
		Rarity = Brainrots.TopRarity(parts),
		Own = isOwnLine(line),
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

	-- The middle of the belt's top, level with `at` along the belt (where a part dropped
	-- or tossed from there lands).
	local function beltPoint(at: Vector3): Vector3
		local along = belt.CFrame:PointToObjectSpace(at).Z
		return belt.CFrame:PointToWorldSpace(Vector3.new(0, belt.Size.Y / 2, along))
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
		local landing = beltPoint(dropper.Position)
		local flat = Vector3.new(landing.X - root.X, 0, landing.Z - root.Z)
		local direction = if flat.Magnitude > 0 then flat.Unit else Vector3.zero
		local intake = root.Position + direction * INTAKE_GAP + Vector3.new(0, size.Y / 2, 0)
		local piece: Piece = {
			Model = model,
			Center = center,
			Size = size,
			PartType = partType,
			Scale = model:GetScale(),
			Dropper = dropper,
			ChuteTop = findPart(line, partType .. "ChuteTop"),
			Hanger = findPart(line, partType .. "ChuteTop") or findPart(line, partType .. "Hanger"),
			Waiting = centeredAt(center, intake),
			Home = root * CFrame.new(layout[partType]),
			Travel = math.max(flat.Magnitude - INTAKE_GAP, 0),
		}
		if dropper:GetAttribute("Knitting") then
			model:ScaleTo(piece.Scale * 0.05) -- a speck in the knitting head, until it's knitted
			model:PivotTo(centeredAt(center * 0.05, dropper.Position))
		else
			model:PivotTo(centeredAt(center, dropper.Position)) -- starts hidden inside the dropper
		end
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
			-- (a dropper that's still popping in doesn't squash)
			local hanger = piece.Hanger
			local chute = if hanger and not isBuilding(line) then readChute(line, hanger, piece.PartType) else nil
			local top = piece.ChuteTop
			if top then
				-- down the glass tube from the ceiling, the bands gulping as it passes
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
			elseif piece.Dropper:GetAttribute("Knitting") then
				-- the machine knits it: it grows down out of the head's mouth, its top
				-- tucked in the mouth, while the needles whirl and the yarn feeds in
				local head = piece.Dropper
				local knitting = if isBuilding(line) then nil else readKnitting(line, piece.PartType, head)
				local mouth = head.Position - Vector3.new(0, halfHeight(head), 0)
				local sewing = Effects.sound(mouth, Sounds.Sewing, 0.25, vary(1.6))
				local began = os.clock()
				local function hang(factor: number)
					piece.Model:ScaleTo(piece.Scale * factor)
					piece.Model:PivotTo(centeredAt(piece.Center * factor, mouth - Vector3.new(0, piece.Size.Y * factor / 2, 0)))
				end
				run(Production.DropTime - FALL_TIME, function(alpha)
					hang(math.max(ease(alpha, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), 0.05))
					if knitting then
						poseKnitting(knitting, os.clock() - began)
					end
					if build.Near and math.random() < 0.15 then
						Effects.sparkle(mouth, head.Color:Lerp(Color3.new(1, 1, 1), 0.5), 1)
					end
				end)
				hang(1)
				if knitting then
					poseKnitting(knitting, nil)
				end
				stopSound(sewing)
			else
				waitUntil(step.Start - ride - FALL_TIME)
			end
			if cancelled() then
				return
			end
			spit(line, piece.Dropper, build.Near, chute)
			local landing = centeredAt(piece.Center, beltPoint(piece.Dropper.Position) + Vector3.new(0, piece.Size.Y / 2, 0))
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

	-- 4) Ta-da: as one brainrot, it steps off the pad and shows itself off.
	local brainrot = Instance.new("Model")
	brainrot.Name = "Brainrot"
	for _, piece in pieces do
		piece.Model:PivotTo(piece.Home)
		piece.Model.Parent = brainrot
	end
	brainrot.WorldPivot = root
	brainrot.Parent = effects

	local path = beltEnd.Position - root.Position
	local showSpot = root + path.Unit * math.min(SHOW_GAP, path.Magnitude / 3)
	local star = crown(build, brainrot)
	showOff(build, brainrot, root, showSpot, Production.ShowDuration(cycleTime))
	if cancelled() then
		brainrot:Destroy()
		return
	end

	-- 5) It rides through the stations to the end of the belt.
	local passes = stationPasses(line, showSpot.Position, beltEnd.Position)
	local nextPass = 1
	run(Production.ShipTime, function(alpha)
		brainrot:PivotTo(showSpot:Lerp(beltEnd, alpha))
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

	-- 6) The zone's special upgrade, if the line has it, works on it at the belt's end.
	uncrown(star)
	if special then
		local machine = findPart(line, "Station3")
		local specialTime = Production.SpecialDuration(cycleTime)
		if machine and style.Special then
			local ok, err = pcall(style.Special, build, brainrot, machine, specialTime)
			if not ok then
				warn(`[ProductionVisuals] {zoneId} special failed: {err}`)
			end
		else
			task.wait(specialTime) -- keep in step with the payout anyway
		end
		if cancelled() then
			brainrot:Destroy()
			return
		end
	end

	-- 7) The zone's finishing stage packs it up and sends it off: that's the payout.
	local ok, result = pcall(style.Finish or simpleFinish, build, brainrot, ship, Production.FinishDuration(cycleTime))
	brainrot:Destroy()
	if not line.Parent then
		return
	end
	if not ok then
		warn(`[ProductionVisuals] {zoneId} finish failed: {result}`)
	end
	local top = if ok then result :: Vector3 else ship.Position + Vector3.new(0, 3, 0)
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

end

local function findLine(plot: Instance?, lineId: string): Model?
	local lines = plot and plot:FindFirstChild("Lines")
	local line = lines and lines:FindFirstChild(lineId)
	return if line and line:IsA("Model") then line else nil
end

Remotes.Event("Production").OnClientEvent:Connect(function(plot, lineId, parts, zoneId, value, fullMatch, cycleTime, special)
	local line = findLine(plot, lineId)
	local camera = workspace.CurrentCamera
	if not (line and camera) or (camera.CFrame.Position - line:GetPivot().Position).Magnitude > RENDER_DISTANCE then
		return
	end
	task.spawn(animateCycle, line, parts, zoneId, value, fullMatch, cycleTime or Production.BaseCycleTime, special == true)
end)
