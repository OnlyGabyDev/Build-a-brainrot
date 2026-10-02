--[[
	TurntableBuilder
	Builds what's special about the Clay Studio's line (LineLayouts "Turntable", GDD §6):
	no belt; a clay pad inside the open capsule where the brainrot is modeled; round it a
	big table whose top turns in stop-motion clicks (the Turntable Model, turned by
	ProductionVisuals on every client by the same clock), its edge printed like a film
	strip; the kiln's step, where the brainrot hops off the table; the Stop-Motion Camera
	(the special) on its tripod out front, aimed at the step; the turbo rings round the
	table (Speed); and the Belt Boost track's look (studio lights round the table, a
	golden clapperboard). The presses, the capsule, the gloves, the stations and the kiln
	are TycoonManager's and StationBuilder's.

	ProductionVisuals finds by name: Turntable (the turning top, tagged Turntable, pivoted
	on the pad at the table's height), KilnStep (its top is where the brainrot lands),
	Station3 (the camera's body), Station3Lens and Station3Flash. The Belt Boost track
	recolors the TableGlow strips.

	Line space, as in TycoonManager: `origin` on the floor at the pad, -Z toward the
	room's front; angles round the table as in LineLayouts (from -Z toward -X).
]]

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LineLayouts = require(ReplicatedStorage.Shared.LineLayouts)
local TycoonItems = require(ReplicatedStorage.Shared.Config.TycoonItems)

local TurntableBuilder = {}

local DECK = LineLayouts.Deck
local TABLE = LineLayouts.TableSettings
local SEGMENTS = 24 -- the table is built in this many pieces round
local TOP = 0.7 -- the turning top's thickness
local PAD_RADIUS = 9.3 -- inside the capsule's glass (10)

local WHITE = Color3.new(1, 1, 1)
local CHROME_COLOR = Color3.fromRGB(215, 220, 235)
local SIGN_BACK = Color3.fromRGB(40, 28, 60)
-- the Clay Studio's machines (as in TycoonManager): terracotta and cream, teal neon
local CLAY_COLOR = Color3.fromRGB(225, 120, 75)
local CLAY_LIGHT_COLOR = Color3.fromRGB(245, 180, 125)
local CLAY_DARK_COLOR = Color3.fromRGB(150, 75, 50)
local CLAY_TEAL = Color3.fromRGB(60, 205, 195)
local CAMERA_BLACK = Color3.fromRGB(45, 40, 55)
local CLAY_GOLD = Color3.fromRGB(255, 190, 40) -- solid gold: Metal, no reflectance
local TURBO_COLOR = Color3.fromRGB(255, 230, 60) -- the Speed upgrades' glow, as on a belt
local SPLAT_COLORS = {
	Color3.fromRGB(255, 100, 120),
	Color3.fromRGB(255, 200, 60),
	Color3.fromRGB(90, 190, 255),
	Color3.fromRGB(130, 220, 110),
	Color3.fromRGB(190, 130, 255),
}

-- Helpers --------------------------------------------------------------------------

local function makePart(parent: Instance, name: string, size: Vector3, cframe: CFrame, color: Color3, material: Enum.Material?): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

-- Just for looks: no collisions, no touches.
local function makeDecor(parent: Instance, name: string, size: Vector3, cframe: CFrame, color: Color3, material: Enum.Material?): Part
	local part = makePart(parent, name, size, cframe, color, material)
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	return part
end

-- An upright cylinder from `bottom` to `top` over `base`.
local function makeColumn(parent: Instance, name: string, diameter: number, bottom: number, top: number, base: CFrame, color: Color3, material: Enum.Material?): Part
	local part = makeDecor(parent, name, Vector3.new(top - bottom, diameter, diameter), base * CFrame.new(0, (bottom + top) / 2, 0) * CFrame.Angles(0, 0, math.pi / 2), color, material)
	part.Shape = Enum.PartType.Cylinder
	return part
end

local function makeBall(parent: Instance, name: string, diameter: number, cframe: CFrame, color: Color3, material: Enum.Material?): Part
	local part = makeDecor(parent, name, Vector3.one * diameter, cframe, color, material)
	part.Shape = Enum.PartType.Ball
	return part
end

local function makeRod(parent: Instance, name: string, from: Vector3, to: Vector3, thickness: number, color: Color3, material: Enum.Material?): Part
	return makeDecor(parent, name, Vector3.new(thickness, thickness, (to - from).Magnitude), CFrame.lookAt((from + to) / 2, to), color, material)
end

-- A cylinder lying along `at`'s Z.
local function makeBarrel(parent: Instance, name: string, length: number, diameter: number, at: CFrame, color: Color3, material: Enum.Material?): Part
	local part = makeDecor(parent, name, Vector3.new(length, diameter, diameter), at * CFrame.Angles(0, math.pi / 2, 0), color, material)
	part.Shape = Enum.PartType.Cylinder
	return part
end

-- `text` in glowing neon letters on `panel`'s front face.
local function neonLabel(panel: BasePart, text: string, color: Color3, face: Enum.NormalId?)
	local gui = Instance.new("SurfaceGui")
	gui.Face = face or Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 30
	gui.LightInfluence = 0
	gui.Brightness = 2.5 -- past 1, so it blooms like neon
	gui.Parent = panel
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(0.9, 0.78)
	label.Position = UDim2.fromScale(0.05, 0.11)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = color:Lerp(WHITE, 0.7)
	label.Text = text
	label.Parent = gui
	local glow = Instance.new("UIStroke")
	glow.Thickness = 3
	glow.Color = color
	glow.Parent = label
end

-- An empty Model turning about `pivot`'s Z (Atmosphere's Spinners), for parts to go in.
local function makeSpinner(model: Model, name: string, pivot: CFrame, speed: number): Model
	local spinner = Instance.new("Model")
	spinner.Name = name
	spinner.WorldPivot = pivot
	spinner:SetAttribute("Speed", speed)
	CollectionService:AddTag(spinner, "Spinner")
	spinner.Parent = model
	return spinner
end

-- Calls `build(frame, width)` for each of the table's pieces round a ring `radius` out:
-- `frame` is the piece's middle on the ring at height `y`, its -Z facing out; `width`
-- is the piece's length round the ring.
local function round(origin: CFrame, radius: number, y: number, count: number, build: (frame: CFrame, width: number) -> ())
	local width = 2 * radius * math.tan(math.pi / count) + 0.06
	for index = 0, count - 1 do
		local angle = (index + 0.5) / count * math.pi * 2
		build(origin * LineLayouts.TableSpot(angle, radius) * CFrame.new(0, y, 0), width)
	end
end

-- The line ----------------------------------------------------------------------

-- The pad inside the capsule the brainrot is modeled on: terracotta with cream and
-- teal bands, a cream top ringed with clay dabs.
local function buildPad(model: Model, origin: CFrame)
	local pad = makeColumn(model, "Pad", PAD_RADIUS * 2, 0, DECK - 0.3, origin, CLAY_COLOR)
	pad.CanCollide = true
	pad.CanQuery = true
	makeColumn(model, "PadStripe", PAD_RADIUS * 2 + 0.1, 1, 1.4, origin, CLAY_LIGHT_COLOR)
	makeColumn(model, "PadGlow", PAD_RADIUS * 2 + 0.12, 2.1, 2.3, origin, CLAY_TEAL, Enum.Material.Neon).CastShadow = false
	makeColumn(model, "PadTop", PAD_RADIUS * 2 - 0.3, DECK - 0.3, DECK, origin, CLAY_LIGHT_COLOR)
	for index = 0, 11 do
		local angle = index / 12 * math.pi * 2
		local dab = origin * LineLayouts.TableSpot(angle, PAD_RADIUS - 1.3)
		makeColumn(model, "PadDab", 0.9 + (index % 3) * 0.25, DECK, DECK + 0.08, dab, SPLAT_COLORS[index % #SPLAT_COLORS + 1])
	end
end

-- The table's base, standing still: a dark terracotta ring with a cream stripe and a
-- glowing teal band round its outside (TableGlow), a gold rim and a teal line on top.
local function buildBase(model: Model, origin: CFrame)
	local depth = TABLE.Outer - TABLE.Inner
	local middle = (TABLE.Inner + TABLE.Outer) / 2
	local height = DECK - TOP
	round(origin, middle, height / 2, SEGMENTS, function(frame, _)
		local width = 2 * TABLE.Outer * math.tan(math.pi / SEGMENTS) + 0.06
		local skirt = makePart(model, "TableBase", Vector3.new(width, height, depth), frame, CLAY_DARK_COLOR)
		skirt.CanCollide = true
	end)
	round(origin, TABLE.Outer + 0.05, 1.3, SEGMENTS, function(frame, width)
		makeDecor(model, "TableStripe", Vector3.new(width, 0.5, 0.2), frame, CLAY_LIGHT_COLOR)
	end)
	round(origin, TABLE.Outer + 0.08, 2.45, SEGMENTS, function(frame, width)
		makeDecor(model, "TableGlow", Vector3.new(width, 0.3, 0.2), frame, CLAY_TEAL, Enum.Material.Neon).CastShadow = false
	end)
	-- the rim round the turning top, and a teal line along its inside edge (rings look
	-- the same turned, so they needn't turn)
	round(origin, TABLE.Outer + 0.15, DECK - 0.25, SEGMENTS, function(frame, width)
		makeDecor(model, "TableRim", Vector3.new(width, 0.6, 0.35), frame, CLAY_GOLD, Enum.Material.Metal)
	end)
	round(origin, TABLE.Inner + 0.45, DECK + 0.02, SEGMENTS, function(frame, width)
		makeDecor(model, "TableLine", Vector3.new(width, 0.05, 0.3), frame, CLAY_TEAL)
	end)
end

-- The top that turns: cream, its outer edge printed with dark sprocket holes like a
-- strip of film, a few splats of clay here and there, so you see it click round.
local function buildTop(model: Model, origin: CFrame)
	local top = Instance.new("Model")
	top.Name = "Turntable"
	local depth = TABLE.Outer - TABLE.Inner
	round(origin, (TABLE.Inner + TABLE.Outer) / 2, DECK - TOP / 2, SEGMENTS, function(frame, _)
		local width = 2 * TABLE.Outer * math.tan(math.pi / SEGMENTS) + 0.06
		makeDecor(top, "TableTop", Vector3.new(width, TOP, depth), frame, CLAY_LIGHT_COLOR)
	end)
	round(origin, TABLE.Outer - 0.75, DECK + 0.02, SEGMENTS * 2, function(frame, _)
		makeDecor(top, "TableSprocket", Vector3.new(0.75, 0.05, 0.6), frame, CAMERA_BLACK)
	end)
	local random = Random.new(5)
	for index = 1, 8 do
		local angle = (index - 1) / 8 * math.pi * 2 + random:NextNumber(-0.2, 0.2)
		local spot = origin * LineLayouts.TableSpot(angle, TABLE.Ride + random:NextNumber(-1, 1))
		makeColumn(top, "TableSplat", random:NextNumber(1.1, 1.9), DECK, DECK + 0.06, spot, SPLAT_COLORS[index % #SPLAT_COLORS + 1])
	end
	top.WorldPivot = origin * CFrame.new(0, DECK, 0)
	CollectionService:AddTag(top, "Turntable")
	top.Parent = model
end

-- The kiln's step: a round landing in front of its door, where the brainrot hops off
-- the table (and poses for the camera).
local function buildStep(model: Model, origin: CFrame)
	local spot = origin * CFrame.new(TABLE.Landing)
	makeColumn(model, "KilnStepFoot", 6.4, 0, 0.5, spot, CLAY_DARK_COLOR)
	local step = makeColumn(model, "KilnStep", 5.6, 0.5, DECK, spot, CLAY_COLOR)
	step.CanCollide = true
	makeColumn(model, "KilnStepStripe", 5.7, 1.6, 2, spot, CLAY_LIGHT_COLOR)
	makeColumn(model, "KilnStepRim", 5.9, DECK - 0.35, DECK + 0.05, spot, CLAY_TEAL, Enum.Material.Neon).CastShadow = false
	makeColumn(model, "KilnStepTop", 5.2, DECK + 0.05, DECK + 0.1, spot, CLAY_LIGHT_COLOR)
end

-- The pad, the table (its base and its turning top) and the kiln's step.
function TurntableBuilder.BuildLine(model: Model, origin: CFrame)
	buildPad(model, origin)
	buildBase(model, origin)
	buildTop(model, origin)
	buildStep(model, origin)
end

-- Speed upgrades: a glowing turbo ring round the table's base, one each.
function TurntableBuilder.BuildSpeed(model: Model, origin: CFrame, item: TycoonItems.Item)
	local y = if item.Key == "Speed1" then 3.1 else 0.55
	round(origin, TABLE.Outer + 0.12, y, SEGMENTS, function(frame, width)
		makeDecor(model, item.Key, Vector3.new(width, 0.4, 0.25), frame, TURBO_COLOR, Enum.Material.Neon).CastShadow = false
	end)
end

-- Station3, the Stop-Motion Camera (the special): a big film camera on a tripod out
-- front (`spot`: on the floor under it, its -Z toward the kiln's step), its lens on the
-- step, reels turning on top, a flash umbrella, and a neon sign on its back.
function TurntableBuilder.BuildCamera(model: Model, spot: CFrame, item: TycoonItems.Item)
	local key = item.Key
	local headY = 9.5
	local head = spot * CFrame.new(0, headY, 0)
	for index = 0, 2 do
		local angle = (index + 0.5) / 3 * math.pi * 2
		local toe = (spot * CFrame.new(math.cos(angle) * 2.6, 0, math.sin(angle) * 2.6)).Position
		makeRod(model, key .. "TripodLeg", toe, head.Position, 0.45, CLAY_DARK_COLOR)
		makeBall(model, key .. "TripodFoot", 0.8, CFrame.new(toe), CLAY_TEAL)
	end
	makeColumn(model, key .. "TripodHead", 1.6, headY - 0.6, headY + 0.4, spot, CHROME_COLOR, Enum.Material.Metal)
	-- the camera, tipped down a little toward the step's brainrot
	local body = head * CFrame.new(0, 2.2, 0) * CFrame.Angles(math.rad(-12), 0, 0)
	makePart(model, key, Vector3.new(3.6, 3.2, 4.8), body, CAMERA_BLACK)
	makeDecor(model, key .. "Stripe", Vector3.new(3.7, 0.5, 4.9), body * CFrame.new(0, -0.6, 0), CLAY_TEAL)
	makeBarrel(model, key .. "LensHood", 1.4, 2.8, body * CFrame.new(0, 0, -3), CHROME_COLOR, Enum.Material.Metal)
	makeBarrel(model, key .. "Lens", 0.8, 2.2, body * CFrame.new(0, 0, -3.8), Color3.fromRGB(90, 85, 100))
	makeBarrel(model, key .. "LensGlass", 0.12, 1.8, body * CFrame.new(0, 0, -4.2), Color3.fromRGB(120, 200, 255), Enum.Material.Glass)
	-- two film reels on top, turning
	for _, z in { -1.2, 1.4 } do
		local center = body * CFrame.new(0, 3.2, z)
		local reel = makeSpinner(model, key .. "Reel", center * CFrame.Angles(0, math.pi / 2, 0), if z < 0 then 2 else -2)
		local disc = makeDecor(reel, key .. "ReelDisc", Vector3.new(0.45, 3.4, 3.4), center, CAMERA_BLACK)
		disc.Shape = Enum.PartType.Cylinder
		for spoke = 0, 2 do
			makeDecor(reel, key .. "ReelHole", Vector3.new(0.5, 0.8, 0.8), center * CFrame.Angles(spoke * math.pi * 2 / 3, 0, 0) * CFrame.new(0, 0.9, 0), CLAY_TEAL).Shape = Enum.PartType.Cylinder
		end
	end
	-- the flash: a white reflector on a pole behind it and to one side, facing the step,
	-- the bulb in front of it
	local pole = spot * CFrame.new(-3, 0, 2.2)
	makeColumn(model, key .. "UmbrellaPole", 0.3, 0, headY + 4, pole, CHROME_COLOR, Enum.Material.Metal)
	local mouth = (pole * CFrame.new(0, headY + 4.4, 0)).Position
	local aim = CFrame.lookAt(mouth, (spot * CFrame.new(0, DECK + 3, -12)).Position) * CFrame.Angles(0, math.pi / 2, 0) -- (a cylinder's axis is its X)
	local reflector = makeDecor(model, key .. "Umbrella", Vector3.new(0.2, 3.2, 3.2), aim, WHITE)
	reflector.Shape = Enum.PartType.Cylinder
	local back = makeDecor(model, key .. "UmbrellaBack", Vector3.new(0.15, 3.5, 3.5), aim * CFrame.new(0.15, 0, 0), CAMERA_BLACK)
	back.Shape = Enum.PartType.Cylinder
	makeBall(model, key .. "Flash", 0.9, aim * CFrame.new(-0.7, 0, 0), Color3.fromRGB(255, 245, 210), Enum.Material.Neon)
	-- its name in neon on its back, toward the room's front
	local sign = makeDecor(model, key .. "Sign", Vector3.new(4.6, 1.4, 0.3), body * CFrame.new(0, 0.5, 2.55) * CFrame.Angles(0, math.pi, 0), SIGN_BACK)
	neonLabel(sign, "📸 " .. string.upper(item.Name), CLAY_TEAL)
	for _, y in { -0.8, 0.8 } do
		makeDecor(model, key .. "SignTube", Vector3.new(4.9, 0.2, 0.35), sign.CFrame * CFrame.new(0, y, 0), CLAY_TEAL:Lerp(WHITE, 0.3), Enum.Material.Neon).CastShadow = false
	end
end

-- The Belt Boost track's look on a turntable: the table's glowing band takes the tier's
-- color, studio lights on stands gather round the table (more each level), a golden
-- clapperboard stands by the kiln from tier 2, sparkles over the table from tier 3, and
-- at the top tier chasing lights run round its base.
export type TrackLook = {
	Tier: number,
	Color: Color3,
	Gold: Color3,
	Bulb: (parent: Instance, at: CFrame, size: number, tier: number, index: number) -> Part,
	Sparkles: (parent: Instance, at: CFrame, size: Vector3, rate: number) -> (),
}

-- where round the table the studio lights stand, in the order they come (degrees: clear
-- of the presses, the stations, the way out of the capsule and the step)
local LIGHT_ANGLES = { 95, 285, 122, 300, 70, 108 }
local LIGHT_RADIUS = 17.4

-- A studio light: a softbox on a stand, aimed at the table's middle.
local function studioLight(model: Model, origin: CFrame, angle: number, tier: number, color: Color3, gold: Color3)
	local foot = origin * LineLayouts.TableSpot(angle, LIGHT_RADIUS)
	local height = 12.5
	for index = 0, 2 do
		local spread = (index + 0.5) / 3 * math.pi * 2
		local toe = (foot * CFrame.new(math.cos(spread) * 1.4, 0, math.sin(spread) * 1.4)).Position
		makeRod(model, "LightLeg", toe, (foot * CFrame.new(0, 3, 0)).Position, 0.25, CAMERA_BLACK)
	end
	makeColumn(model, "LightPole", 0.35, 3, height, foot, CHROME_COLOR, Enum.Material.Metal)
	local box = CFrame.lookAt((foot * CFrame.new(0, height + 1, 0)).Position, (origin * CFrame.new(0, DECK + 3, 0)).Position)
	makeDecor(model, "Softbox", Vector3.new(3.4, 2.6, 1.6), box, if tier >= 2 then gold else CAMERA_BLACK, if tier >= 2 then Enum.Material.Metal else nil)
	local face = makeDecor(model, "SoftboxGlow", Vector3.new(3, 2.2, 0.1), box * CFrame.new(0, 0, -0.82), color:Lerp(WHITE, 0.55), Enum.Material.Neon)
	face.CastShadow = false
	local light = Instance.new("SpotLight")
	light.Face = Enum.NormalId.Front
	light.Angle = 60
	light.Range = 18
	light.Brightness = 0.8
	light.Color = color:Lerp(WHITE, 0.6)
	light.Shadows = false
	light.Parent = face
end

-- A golden clapperboard standing on the floor (`at`: under its middle, -Z its face).
local function clapperboard(model: Model, at: CFrame, gold: Color3)
	local board = at * CFrame.new(0, 3.4, 0) * CFrame.Angles(math.rad(-8), 0, 0)
	makeDecor(model, "ClapBoard", Vector3.new(5.6, 4.2, 0.4), board, gold, Enum.Material.Metal)
	makeDecor(model, "ClapSlate", Vector3.new(5, 2.8, 0.1), board * CFrame.new(0, -0.3, -0.22), CAMERA_BLACK)
	for index = 0, 4 do
		makeDecor(model, "ClapStripe", Vector3.new(0.7, 0.9, 0.42), board * CFrame.new(-2.2 + index * 1.1, 2.6, 0) * CFrame.Angles(0, 0, math.rad(-20)), if index % 2 == 0 then gold else WHITE)
	end
	makeDecor(model, "ClapArm", Vector3.new(5.6, 0.9, 0.4), board * CFrame.new(0, 3.3, 0) * CFrame.Angles(0, 0, math.rad(14)), gold, Enum.Material.Metal)
	local slate = makeDecor(model, "ClapText", Vector3.new(4.6, 2, 0.05), board * CFrame.new(0, -0.3, -0.29), CAMERA_BLACK)
	neonLabel(slate, "TAKE 1 ✦", gold)
	makeDecor(model, "ClapFoot", Vector3.new(4, 0.5, 2.4), at * CFrame.new(0, 0.25, 0.4), CAMERA_BLACK)
end

function TurntableBuilder.BuildTrackLook(model: Model, line: Model, origin: CFrame, level: number, look: TrackLook)
	for _, child in line:GetChildren() do
		if child.Name == "TableGlow" and child:IsA("BasePart") then
			child.Color = look.Color
		end
	end
	local lights = math.min(1 + math.ceil(level * 0.5), #LIGHT_ANGLES)
	for index = 1, lights do
		studioLight(model, origin, math.rad(LIGHT_ANGLES[index]), look.Tier, look.Color, look.Gold)
	end
	if look.Tier >= 2 then
		clapperboard(model, origin * CFrame.new(-13, 0, -20) * CFrame.Angles(0, math.rad(25), 0), look.Gold)
	end
	if look.Tier >= 3 then
		for k = 0, 3 do
			local spot = origin * LineLayouts.TableSpot(k / 4 * math.pi * 2 + 0.4, TABLE.Ride) * CFrame.new(0, DECK + 6, 0)
			look.Sparkles(model, spot, Vector3.new(6, 1, 6), 4 + look.Tier * 2)
		end
	end
	if look.Tier >= 4 then
		local index = 0
		round(origin, TABLE.Outer + 0.3, 1.9, SEGMENTS * 2, function(frame, _)
			index += 1
			look.Bulb(model, frame, 0.5, look.Tier, index)
		end)
	end
end

return TurntableBuilder
