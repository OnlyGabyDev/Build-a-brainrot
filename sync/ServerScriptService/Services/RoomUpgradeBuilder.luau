--[[
	RoomUpgradeBuilder
	Builds the room upgrades (Config/RoomUpgrades, GDD §6), one level at a time, each in
	its own spot of its room, and says where its button goes. Every level is the whole
	thing at that level (bigger, shinier, busier than the one before): TycoonManager
	clears the old level and builds the new one into the upgrade's Model.

	Motion: RoomFX (client) plays the upgrades tagged BubbleWrap, JackInTheBox,
	BoxConveyor and ToyTrain from their parts and attributes; the rest turn, bob or
	chase lights with Atmosphere's Spinner, Bobbing and Marquee tags, or sparkle with
	ParticleEmitters.

	Room space, as in RoomDecor: `floor` is the room's floor center, -Z toward the
	building's front; the lines run along Z at X = -42, 0, 42 with their buttons on
	their +X side. Spots: the front corners, the left wall, the back-left corner, and
	the ceiling all round (the conveyor).
]]

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BrainrotModels = require(ReplicatedStorage.Shared.BrainrotModels)
local Brainrots = require(ReplicatedStorage.Shared.Config.Brainrots)
local ConveyorPath = require(ReplicatedStorage.Shared.ConveyorPath)

local RoomUpgradeBuilder = {}

local WHITE = Color3.new(1, 1, 1)
local INK = Color3.fromRGB(45, 30, 60)
local GOLD = Color3.fromRGB(255, 200, 60)
local WOOD = Color3.fromRGB(225, 175, 120)
local TOY_COLORS = {
	Color3.fromRGB(255, 80, 100), -- red
	Color3.fromRGB(255, 200, 40), -- yellow
	Color3.fromRGB(50, 150, 255), -- blue
	Color3.fromRGB(80, 205, 90), -- green
	Color3.fromRGB(160, 95, 255), -- purple
	Color3.fromRGB(255, 140, 40), -- orange
}
local PLUSH_COLORS = {
	Color3.fromRGB(255, 110, 180), -- pink
	Color3.fromRGB(160, 120, 255), -- lavender
	Color3.fromRGB(100, 195, 255), -- blue
	Color3.fromRGB(255, 200, 90), -- butter
	Color3.fromRGB(110, 215, 160), -- mint
}
local SPARKLE_TEXTURE = "rbxasset://textures/particles/sparkles_main.dds"

-- Helpers --------------------------------------------------------------------------

local function makeDecor(parent: Instance, name: string, size: Vector3, cframe: CFrame, color: Color3, material: Enum.Material?): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

local function ball(parent: Instance, name: string, diameter: number, cframe: CFrame, color: Color3, material: Enum.Material?): Part
	local part = makeDecor(parent, name, Vector3.one * diameter, cframe, color, material)
	part.Shape = Enum.PartType.Ball
	return part
end

-- An upright cylinder standing on `base` (its bottom center).
local function cylinder(parent: Instance, name: string, diameter: number, height: number, base: CFrame, color: Color3, material: Enum.Material?): Part
	local part = makeDecor(parent, name, Vector3.new(height, diameter, diameter), base * CFrame.new(0, height / 2, 0) * CFrame.Angles(0, 0, math.pi / 2), color, material)
	part.Shape = Enum.PartType.Cylinder
	return part
end

-- A cylinder lying along `at`'s X axis, centered on it.
local function roller(parent: Instance, name: string, diameter: number, length: number, at: CFrame, color: Color3, material: Enum.Material?): Part
	local part = makeDecor(parent, name, Vector3.new(length, diameter, diameter), at, color, material)
	part.Shape = Enum.PartType.Cylinder
	return part
end

-- A rod (its length along Z) from `from` to `to`, world positions.
local function rod(parent: Instance, name: string, thickness: number, from: Vector3, to: Vector3, color: Color3, material: Enum.Material?): Part
	return makeDecor(parent, name, Vector3.new(thickness, thickness, (to - from).Magnitude), CFrame.lookAt((from + to) / 2, to), color, material)
end

local function tagged(model: Model, tag: string, parent: Instance): Model
	CollectionService:AddTag(model, tag)
	model.Parent = parent
	return model
end

-- Turns about its pivot's Z (Atmosphere), at `speed` radians per second.
local function spinner(model: Model, parent: Instance, pivot: CFrame, speed: number)
	model.WorldPivot = pivot
	model:SetAttribute("Speed", speed)
	tagged(model, "Spinner", parent)
end

-- Sparkles drifting off `part`.
local function sparkles(part: BasePart, color: Color3, rate: number, size: number?)
	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture = SPARKLE_TEXTURE
	emitter.Color = ColorSequence.new(color)
	emitter.LightEmission = 1
	emitter.Rate = rate
	emitter.Lifetime = NumberRange.new(0.8, 1.6)
	emitter.Speed = NumberRange.new(1, 3)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, size or 0.7), NumberSequenceKeypoint.new(1, 0) })
	emitter.Parent = part
end

local function glow(part: BasePart, color: Color3, range: number)
	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = range
	light.Brightness = 1.5
	light.Shadows = false
	light.Parent = part
end

local function bulb(parent: Instance, at: CFrame, index: number): Part
	local part = ball(parent, "Bulb", 0.9, at, Color3.fromRGB(255, 215, 130), Enum.Material.Neon)
	part.CastShadow = false
	part:SetAttribute("Index", index)
	CollectionService:AddTag(part, "Marquee")
	return part
end

-- Text on `part`'s `face`. `glowing`: neon-bright.
local function printOn(part: BasePart, face: Enum.NormalId, text: string, color: Color3, outline: Color3, glowing: boolean?)
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 20
	gui.LightInfluence = 0
	if glowing then
		gui.Brightness = 2.5
	end
	gui.Parent = part
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(0.9, 0.8)
	label.Position = UDim2.fromScale(0.05, 0.1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = color
	label.Text = text
	label.Parent = gui
	local stroke = Instance.new("UIStroke")
	stroke.Color = outline
	stroke.Thickness = if glowing then 4 else 2
	stroke.Parent = label
end

-- A wrapped present standing on `at` (its bottom center): ribbons both ways and a bow.
local function present(parent: Instance, at: CFrame, size: Vector3, color: Color3, ribbon: Color3, material: Enum.Material?): Part
	local box = makeDecor(parent, "Present", size, at * CFrame.new(0, size.Y / 2, 0), color, material)
	makeDecor(parent, "PresentRibbon", Vector3.new(size.X + 0.12, size.Y + 0.12, size.Z * 0.18), box.CFrame, ribbon)
	makeDecor(parent, "PresentRibbon", Vector3.new(size.X * 0.18, size.Y + 0.12, size.Z + 0.12), box.CFrame, ribbon)
	local top = at * CFrame.new(0, size.Y, 0)
	local s = math.min(size.X, size.Z) * 0.34
	ball(parent, "PresentKnot", s * 0.55, top * CFrame.new(0, s * 0.18, 0), ribbon)
	for _, side in { -1, 1 } do
		roller(parent, "PresentBow", s, s * 0.3, top * CFrame.new(side * s * 0.48, s * 0.38, 0) * CFrame.Angles(0, 0, side * math.rad(35)), ribbon)
	end
	return box
end

-- Gift Tower (Toy Workshop, the front-left corner) ------------------------------------
-- A pile of wrapped presents that grows a layer each level, sparkling at level 3, and
-- crowned by a floating golden present at level 4.

type Gift = { Level: number, At: Vector3, Size: Vector3, Turn: number, Color: number, Ribbon: number }
local GIFT_BOXES: { Gift } = { -- Ribbon 0: white
	{ Level = 1, At = Vector3.new(-60, 0, -52), Size = Vector3.new(6, 5, 6), Turn = 0.1, Color = 1, Ribbon = 2 },
	{ Level = 1, At = Vector3.new(-53.5, 0, -54), Size = Vector3.new(4.6, 4, 4.6), Turn = -0.2, Color = 3, Ribbon = 0 },
	{ Level = 1, At = Vector3.new(-60, 5, -52), Size = Vector3.new(4.2, 3.6, 4.2), Turn = 0.35, Color = 4, Ribbon = 1 },
	{ Level = 2, At = Vector3.new(-61.5, 0, -45), Size = Vector3.new(5, 4.4, 5), Turn = -0.15, Color = 5, Ribbon = 2 },
	{ Level = 2, At = Vector3.new(-53.5, 4, -54), Size = Vector3.new(3.4, 3, 3.4), Turn = 0.3, Color = 2, Ribbon = 1 },
	{ Level = 2, At = Vector3.new(-60, 8.6, -52), Size = Vector3.new(3.4, 3, 3.4), Turn = -0.2, Color = 6, Ribbon = 3 },
	{ Level = 3, At = Vector3.new(-61.5, 4.4, -45), Size = Vector3.new(3.8, 3.4, 3.8), Turn = 0.25, Color = 1, Ribbon = 0 },
	{ Level = 3, At = Vector3.new(-60, 11.6, -52), Size = Vector3.new(2.6, 2.4, 2.6), Turn = 0.4, Color = 3, Ribbon = 2 },
}

local function buildGiftTower(model: Model, floor: CFrame, level: number)
	local top: Part? = nil
	for _, gift in GIFT_BOXES do
		if gift.Level <= level then
			local ribbon = if gift.Ribbon == 0 then WHITE else TOY_COLORS[gift.Ribbon]
			top = present(model, floor * CFrame.new(gift.At) * CFrame.Angles(0, gift.Turn, 0), gift.Size, TOY_COLORS[gift.Color], ribbon)
		end
	end
	if level >= 3 and top then
		sparkles(top, Color3.fromRGB(255, 240, 160), 4)
	end
	if level >= 4 then
		-- a golden present floating over the pile
		local crown = Instance.new("Model")
		crown.Name = "GoldenGift"
		local at = floor * CFrame.new(-60, 17, -52) * CFrame.Angles(0, 0.6, 0)
		local gold = present(crown, at, Vector3.new(3.4, 3, 3.4), GOLD, WHITE, Enum.Material.SmoothPlastic)
		gold.Reflectance = 0.25
		sparkles(gold, GOLD, 8, 1)
		glow(gold, GOLD, 16)
		crown.WorldPivot = at
		tagged(crown, "Bobbing", model)
	end
end

-- Bubble Wrap Popper (Toy Workshop, on the left wall) ----------------------------------
-- A workbench against the wall with a roll of bubble wrap and a sheet of it across the
-- table; RoomFX pops the bubbles (Bubble parts) one by one, each regrowing a moment
-- later. Level 2 adds a stamping press (Stamper) that thumps the sheet as they pop;
-- level 3 makes the bubbles rainbow and the table glow.

local function buildBubbleWrap(model: Model, floor: CFrame, level: number)
	local base = floor * CFrame.new(-63.5, 0, -18) -- the table's middle, on the floor; +X into the room
	local top = 4.2
	local table_ = TOY_COLORS[3]
	makeDecor(model, "WrapTable", Vector3.new(7, 0.6, 16), base * CFrame.new(0, top - 0.3, 0), table_)
	makeDecor(model, "WrapTableTrim", Vector3.new(0.3, 0.7, 16.2), base * CFrame.new(3.6, top - 0.3, 0), if level >= 3 then TOY_COLORS[2] else WHITE, if level >= 3 then Enum.Material.Neon else nil)
	for _, x in { -3, 3 } do
		for _, z in { -7.4, 7.4 } do
			makeDecor(model, "WrapTableLeg", Vector3.new(0.8, top - 0.6, 0.8), base * CFrame.new(x, (top - 0.6) / 2, z), table_:Lerp(Color3.new(0, 0, 0), 0.25))
		end
	end
	-- the roll, lying across the table at its far end
	local rollSize = if level >= 2 then 4.4 else 3.6
	local plastic = Color3.fromRGB(195, 230, 255)
	local roll = roller(model, "WrapRoll", rollSize, 6, base * CFrame.new(0, top + rollSize / 2, -5.4), plastic)
	roll.Transparency = 0.25
	roll.Reflectance = 0.1
	roller(model, "WrapCore", rollSize * 0.35, 6.3, roll.CFrame, Color3.fromRGB(200, 150, 100))
	-- the sheet, bubbles in rows
	makeDecor(model, "WrapSheet", Vector3.new(6, 0.1, 11), base * CFrame.new(0, top + 0.05, 2), plastic).Transparency = 0.3
	local rows = if level >= 2 then 8 else 6
	for row = 1, rows do
		for column = 1, 4 do
			local color = if level >= 3 then TOY_COLORS[(row + column) % #TOY_COLORS + 1]:Lerp(WHITE, 0.3) else Color3.fromRGB(215, 240, 255)
			local bubble = ball(model, "Bubble", 1, base * CFrame.new(-2.25 + (column - 1) * 1.5, top + 0.15, -3 + row * 1.3), color)
			bubble.Transparency = 0.2
			bubble.Reflectance = 0.15
		end
	end
	if level >= 2 then
		-- the stamping press over the middle of the sheet
		local pressZ = 2.8
		for _, x in { -3.2, 3.2 } do
			makeDecor(model, "PressPost", Vector3.new(0.7, 7, 0.7), base * CFrame.new(x, top + 3.5, pressZ), TOY_COLORS[1])
		end
		makeDecor(model, "PressBeam", Vector3.new(7.2, 1, 1.4), base * CFrame.new(0, top + 7, pressZ), TOY_COLORS[1])
		makeDecor(model, "StamperRod", Vector3.new(0.5, 3, 0.5), base * CFrame.new(0, top + 5, pressZ), Color3.fromRGB(205, 210, 225), Enum.Material.Metal)
		makeDecor(model, "Stamper", Vector3.new(5.4, 1, 2.6), base * CFrame.new(0, top + 3.2, pressZ), TOY_COLORS[2])
	end
	model:SetAttribute("Level", level)
	tagged(model, "BubbleWrap", model.Parent :: Instance)
end

-- Box Conveyor (Toy Workshop, overhead all round the room) ------------------------------
-- A rail hung from the ceiling in a loop (a rectangle with rounded corners) with
-- wrapped boxes hanging off it on hooks; RoomFX moves them round. Level 2: more boxes,
-- bows, faster. Level 3 (rebirth): a glowing rail and golden boxes.

local CONVEYOR_BOXES = { 8, 14, 18 }
local CONVEYOR_SPEEDS = { 5, 7, 9 }

local function buildBoxConveyor(model: Model, floor: CFrame, level: number)
	local perimeter = ConveyorPath.Perimeter
	local railColor = TOY_COLORS[5]
	-- the rail, in short straight pieces round the loop, with hangers up to the ceiling
	local pieces = 64
	for index = 0, pieces - 1 do
		local from = ConveyorPath.Point(index / pieces * perimeter)
		local to = ConveyorPath.Point((index + 1) / pieces * perimeter)
		local a, b = (floor * CFrame.new(from)).Position, (floor * CFrame.new(to)).Position
		rod(model, "ConveyorRail", 0.8, a, b + (b - a).Unit * 0.4, railColor)
		if level >= 3 then
			rod(model, "ConveyorGlow", 0.35, a - Vector3.new(0, 0.5, 0), b - Vector3.new(0, 0.5, 0), TOY_COLORS[2], Enum.Material.Neon).CastShadow = false
		end
		if index % 8 == 0 then
			local hanger = (floor * CFrame.new(from + Vector3.new(0, 1.6, 0))).Position
			makeDecor(model, "ConveyorHanger", Vector3.new(0.4, 3.2, 0.4), CFrame.new(hanger) * floor.Rotation, Color3.fromRGB(90, 80, 110))
		end
	end
	-- the boxes, spread evenly round the loop; each one's pivot is its hook on the rail
	local count = CONVEYOR_BOXES[level]
	for index = 1, count do
		local phase = (index - 1) / count
		local point, heading = ConveyorPath.Point(phase * perimeter)
		local hook = floor * CFrame.lookAt(point, point + heading)
		local box = Instance.new("Model")
		box.Name = "ConveyorBox"
		makeDecor(box, "Trolley", Vector3.new(1.2, 0.5, 1.4), hook * CFrame.new(0, 0.6, 0), Color3.fromRGB(90, 80, 110))
		makeDecor(box, "Hook", Vector3.new(0.25, 1.6, 0.25), hook * CFrame.new(0, -0.8, 0), Color3.fromRGB(205, 210, 225), Enum.Material.Metal)
		local golden = level >= 3 and index % 3 == 0
		local color = if golden then GOLD else TOY_COLORS[index % #TOY_COLORS + 1]
		local gift = present(box, hook * CFrame.new(0, -4.2, 0), Vector3.new(2.6, 2.6, 2.6), color, if golden then WHITE else TOY_COLORS[(index + 2) % #TOY_COLORS + 1])
		if golden then
			gift.Reflectance = 0.25
			sparkles(gift, GOLD, 3)
		end
		box:SetAttribute("Phase", phase)
		box.WorldPivot = hook
		box.Parent = model
	end
	model:SetAttribute("Origin", floor)
	model:SetAttribute("Speed", CONVEYOR_SPEEDS[level])
	tagged(model, "BoxConveyor", model.Parent :: Instance)
end

-- Jack-in-the-Box (Toy Workshop, the front-right corner) -------------------------------
-- A giant toy box with a crank. Every few seconds (RoomFX) the crank whirs, the lid
-- flips open and a brainrot head springs out on a coil with confetti. Level 2: bigger,
-- chasing lights round the top, two heads.

local function buildJackBox(model: Model, floor: CFrame, level: number)
	local s = if level >= 2 then 1.25 else 1
	local size = 8 * s
	local center = floor * CFrame.new(59, 0, -50)
	local body = TOY_COLORS[1]
	local trim = TOY_COLORS[2]
	local box = makeDecor(model, "JackBody", Vector3.one * size, center * CFrame.new(0, size / 2, 0), body)
	box.CanCollide = true
	for _, corner in { Vector2.new(-1, -1), Vector2.new(-1, 1), Vector2.new(1, -1), Vector2.new(1, 1) } do
		makeDecor(model, "JackTrim", Vector3.new(0.9 * s, size + 0.2, 0.9 * s), center * CFrame.new(corner.X * size / 2, size / 2, corner.Y * size / 2), trim)
	end
	makeDecor(model, "JackBand", Vector3.new(size + 0.3, 0.8 * s, size + 0.3), center * CFrame.new(0, 0.4 * s, 0), trim)
	for _, face in { Enum.NormalId.Front, Enum.NormalId.Back, Enum.NormalId.Left, Enum.NormalId.Right } do
		printOn(box, face, "?", WHITE, INK)
	end
	-- the lid, hinged along its top edge on the wall side (+X); RoomFX turns it about
	-- its pivot's X by OpenAngle to open it
	local hinge = center * CFrame.fromMatrix(Vector3.new(size / 2, size, 0), Vector3.zAxis, Vector3.yAxis)
	local lid = Instance.new("Model")
	lid.Name = "JackLid"
	makeDecor(lid, "Lid", Vector3.new(size + 0.6, 0.8 * s, size + 0.6), hinge * CFrame.new(0, 0.4 * s, size / 2), trim)
	makeDecor(lid, "LidTop", Vector3.new(size - 1.4, 0.4 * s, size - 1.4), hinge * CFrame.new(0, 0.9 * s, size / 2), body)
	ball(lid, "LidKnob", 1.2 * s, hinge * CFrame.new(0, 0.5 * s, size + 0.4), WHITE)
	lid.WorldPivot = hinge
	lid:SetAttribute("OpenAngle", -math.rad(115))
	lid.Parent = model
	-- the crank on the side facing into the room (+Z)
	local hub = center * CFrame.new(0, size * 0.5, size / 2 + 0.3)
	local crank = Instance.new("Model")
	crank.Name = "JackCrank"
	roller(crank, "CrankWheel", 3.2 * s, 0.5, hub * CFrame.Angles(0, math.pi / 2, 0), trim)
	makeDecor(crank, "CrankArm", Vector3.new(0.5, 1.8 * s, 0.4), hub * CFrame.new(0, 0.9 * s, 0.5), WHITE)
	ball(crank, "CrankKnob", 1 * s, hub * CFrame.new(0, 1.8 * s, 1), TOY_COLORS[3])
	crank.WorldPivot = hub
	crank.Parent = model
	if level >= 2 then
		local count = 0
		for side = 0, 3 do
			local edge = center * CFrame.Angles(0, side * math.pi / 2, 0)
			for k = 0, 4 do
				count += 1
				bulb(model, edge * CFrame.new(-size / 2 + (k + 0.5) * size / 5, size - 0.6 * s, -size / 2 - 0.3), count)
			end
		end
	end
	-- where the jack springs from (inside, on the bottom), and how big it is
	model:SetAttribute("JackBase", center * CFrame.new(0, 0.8 * s, 0))
	model:SetAttribute("JackDepth", size - 1)
	model:SetAttribute("Level", level)
	tagged(model, "JackInTheBox", model.Parent :: Instance)
end

-- Toy Train (Toy Workshop, the back-left corner) --------------------------------------
-- A round table with a track and a little train pulling wagons of presents round and
-- round (RoomFX: TrainCar models, each with its Offset in radians behind the engine).
-- Level 2: a golden engine, more wagons and a tunnel mountain in the middle.

local TRAIN_RADIUS = 5.2

local function buildEngine(car: Model, at: CFrame, golden: boolean)
	local dark = Color3.fromRGB(60, 50, 70)
	local boiler = if golden then GOLD else TOY_COLORS[1]
	makeDecor(car, "Chassis", Vector3.new(1.4, 0.5, 2.8), at * CFrame.new(0, 0.6, 0), dark)
	local tube = roller(car, "Boiler", 1.3, 1.7, at * CFrame.new(0, 1.45, -0.45) * CFrame.Angles(0, math.pi / 2, 0), boiler)
	tube.Reflectance = if golden then 0.25 else 0
	roller(car, "Smokebox", 1.35, 0.3, at * CFrame.new(0, 1.45, -1.35) * CFrame.Angles(0, math.pi / 2, 0), dark)
	cylinder(car, "Chimney", 0.55, 0.9, at * CFrame.new(0, 2.05, -0.9), dark)
	makeDecor(car, "Cab", Vector3.new(1.4, 1.5, 1.1), at * CFrame.new(0, 1.6, 0.8), TOY_COLORS[3])
	makeDecor(car, "CabRoof", Vector3.new(1.7, 0.25, 1.4), at * CFrame.new(0, 2.45, 0.8), boiler)
	ball(car, "Lamp", 0.4, at * CFrame.new(0, 1.5, -1.55), Color3.fromRGB(255, 240, 160), Enum.Material.Neon)
	for _, x in { -0.75, 0.75 } do
		for _, z in { -0.9, 0.9 } do
			roller(car, "Wheel", 0.8, 0.25, at * CFrame.new(x, 0.4, z), TOY_COLORS[2])
		end
	end
end

local function buildWagon(car: Model, at: CFrame, index: number)
	makeDecor(car, "Chassis", Vector3.new(1.3, 0.45, 2.2), at * CFrame.new(0, 0.6, 0), TOY_COLORS[(index + 3) % #TOY_COLORS + 1])
	present(car, at * CFrame.new(0, 0.82, 0) * CFrame.Angles(0, index, 0), Vector3.new(1.1, 1, 1.1), TOY_COLORS[(index + 1) % #TOY_COLORS + 1], WHITE)
	for _, x in { -0.7, 0.7 } do
		for _, z in { -0.7, 0.7 } do
			roller(car, "Wheel", 0.7, 0.25, at * CFrame.new(x, 0.35, z), Color3.fromRGB(60, 50, 70))
		end
	end
end

local function buildToyTrain(model: Model, floor: CFrame, level: number)
	local center = floor * CFrame.new(-60, 0, 36)
	local tableTop = 3.7
	-- the table: a round top with a green felt, a colored skirt, four legs
	cylinder(model, "TrainTableSkirt", 14.4, 0.7, center * CFrame.new(0, tableTop - 1.2, 0), TOY_COLORS[5])
	cylinder(model, "TrainTable", 14, 0.6, center * CFrame.new(0, tableTop - 0.6, 0), WOOD, Enum.Material.Wood)
	cylinder(model, "TrainFelt", 13.2, 0.08, center * CFrame.new(0, tableTop, 0), Color3.fromRGB(90, 190, 90), Enum.Material.Fabric)
	for index = 0, 3 do
		local angle = index * math.pi / 2 + math.pi / 4
		makeDecor(model, "TrainTableLeg", Vector3.new(0.9, tableTop - 1.2, 0.9), center * CFrame.new(math.cos(angle) * 5, (tableTop - 1.2) / 2, math.sin(angle) * 5), TOY_COLORS[5]:Lerp(Color3.new(0, 0, 0), 0.25))
	end
	-- the track: two rails round a ring of sleepers
	local track = center * CFrame.new(0, tableTop + 0.08, 0)
	local segments = 16
	for index = 0, segments - 1 do
		local angle = (index + 0.5) / segments * math.pi * 2
		local spoke = track * CFrame.Angles(0, -angle, 0)
		makeDecor(model, "Sleeper", Vector3.new(1.8, 0.15, 0.45), spoke * CFrame.new(TRAIN_RADIUS, 0.075, 0), Color3.fromRGB(150, 100, 70))
		local length = 2 * math.pi * TRAIN_RADIUS / segments
		for _, offset in { -0.5, 0.5 } do
			local radius = TRAIN_RADIUS + offset
			makeDecor(model, "Rail", Vector3.new(0.22, 0.22, length * radius / TRAIN_RADIUS + 0.1), spoke * CFrame.new(radius, 0.26, 0), Color3.fromRGB(200, 205, 220), Enum.Material.Metal)
		end
	end
	if level >= 2 then
		-- a mountain with a snowy top in the middle
		for index, tier in { { 5, 1.6 }, { 3.8, 1.5 }, { 2.6, 1.3 } } do
			cylinder(model, "Mountain", tier[1], tier[2], track * CFrame.new(0, (index - 1) * 1.4, 0), Color3.fromRGB(70, 170, 90):Lerp(WHITE, (index - 1) * 0.05))
		end
		ball(model, "MountainSnow", 2.2, track * CFrame.new(0, 4.4, 0), WHITE)
	end
	-- the train, each car standing on the track facing the way it goes
	local wagons = if level >= 2 then 4 else 2
	for index = 0, wagons do
		local offset = index * 0.5
		local car = Instance.new("Model")
		car.Name = "TrainCar"
		local at = track * CFrame.Angles(0, -offset, 0) * CFrame.new(TRAIN_RADIUS, 0.4, 0) -- -Z: the way round
		if index == 0 then
			buildEngine(car, at, level >= 2)
		else
			buildWagon(car, at, index)
		end
		car:SetAttribute("Offset", offset)
		car.WorldPivot = at
		car.Parent = model
	end
	model:SetAttribute("Center", track * CFrame.new(0, 0.4, 0))
	model:SetAttribute("Radius", TRAIN_RADIUS)
	model:SetAttribute("Speed", if level >= 2 then 0.8 else 0.55)
	tagged(model, "ToyTrain", model.Parent :: Instance)
end

-- Yarn Spinner (Plushie room, on the left wall) ---------------------------------------
-- A spinning wheel: its big wheel turns on two uprights over a bench and a band drives
-- the bobbin, which winds yarn. Each level is bigger with better yarn: cream wool, then
-- pink with a basket of yarn, then rainbow and sparkling, then (rebirth) golden thread
-- on a golden wheel, glowing.

local YARN_SCALES = { 1, 1.15, 1.25, 1.45 }

local function buildYarnSpinner(model: Model, floor: CFrame, level: number)
	local s = YARN_SCALES[level]
	local base = floor * CFrame.new(-62, 0, -18) -- +X into the room, Z along the wall
	local function at(x: number, y: number, z: number): CFrame
		return base * CFrame.new(x * s, y * s, z * s)
	end
	local golden = level >= 4
	local wood = if golden then Color3.fromRGB(240, 200, 120) else WOOD
	-- the bench on its legs
	makeDecor(model, "SpinnerBench", Vector3.new(2.4, 0.8, 12) * s, at(0, 3.2, 0), wood, Enum.Material.Wood)
	for _, z in { -5, 5 } do
		for _, x in { -0.8, 0.8 } do
			makeDecor(model, "SpinnerLeg", Vector3.new(0.6, 2.9, 0.6) * s, at(x, 1.4, z), wood:Lerp(Color3.new(0, 0, 0), 0.15), Enum.Material.Wood)
		end
	end
	-- the wheel's uprights, and the wheel
	local radius = 4
	local hubY, hubZ = 9.6, -2.5
	for _, x in { -0.9, 0.9 } do
		makeDecor(model, "SpinnerUpright", Vector3.new(0.5, 6.5, 0.6) * s, at(x, 6.8, hubZ), wood, Enum.Material.Wood)
	end
	local wheel = Instance.new("Model")
	wheel.Name = "SpinnerWheel"
	local hub = at(0, hubY, hubZ)
	local rim = if golden then GOLD else Color3.fromRGB(205, 150, 95)
	local rimMaterial = if golden then Enum.Material.Neon else Enum.Material.Wood
	local segments = 16
	for index = 0, segments - 1 do
		local angle = (index + 0.5) / segments * math.pi * 2
		local radial = Vector3.new(0, math.sin(angle), math.cos(angle))
		local length = 2 * math.pi * radius / segments + 0.1
		makeDecor(wheel, "WheelRim", Vector3.new(0.45, 0.6, length) * s, hub * CFrame.fromMatrix(radial * radius * s, Vector3.xAxis, radial), rim, rimMaterial)
	end
	for index = 0, 7 do
		local angle = index / 8 * math.pi * 2
		local radial = Vector3.new(0, math.sin(angle), math.cos(angle))
		local color = if level >= 3 then PLUSH_COLORS[index % #PLUSH_COLORS + 1] else rim
		makeDecor(wheel, "WheelSpoke", Vector3.new(0.25, radius, 0.25) * s, hub * CFrame.fromMatrix(radial * radius * s / 2, Vector3.xAxis, radial), color, if level >= 3 then nil else Enum.Material.Wood)
	end
	roller(wheel, "WheelHub", 1 * s, 1.2 * s, hub, if golden then GOLD else PLUSH_COLORS[1])
	spinner(wheel, model, hub * CFrame.Angles(0, math.pi / 2, 0), 1.6)
	-- the bobbin at the other end, winding yarn (it spins fast), on two little posts
	local bobbinY, bobbinZ = 7.6, 4.2
	for _, x in { -0.9, 0.9 } do
		makeDecor(model, "BobbinPost", Vector3.new(0.4, 4.2, 0.4) * s, at(x, 5.6, bobbinZ), wood, Enum.Material.Wood)
	end
	local yarnColors = if golden
		then { GOLD }
		elseif level >= 3 then PLUSH_COLORS
		elseif level >= 2 then { PLUSH_COLORS[1] }
		else { Color3.fromRGB(250, 245, 235) }
	local bobbin = Instance.new("Model")
	bobbin.Name = "SpinnerBobbin"
	local spool = at(0, bobbinY, bobbinZ)
	roller(bobbin, "BobbinCore", 0.4 * s, 2 * s, spool, wood)
	for index, color in yarnColors do
		local width = 1.4 / #yarnColors
		roller(bobbin, "BobbinYarn", 1.5 * s, width * s, spool * CFrame.new((-0.7 + (index - 0.5) * width) * s, 0, 0), color, if golden then Enum.Material.Neon else Enum.Material.Fabric)
	end
	roller(bobbin, "BobbinPulley", 1.2 * s, 0.3 * s, spool * CFrame.new(-0.95 * s, 0, 0), PLUSH_COLORS[2])
	spinner(bobbin, model, spool * CFrame.Angles(0, math.pi / 2, 0), 7)
	-- the drive band from the wheel's rim to the pulley
	for _, sign in { 1, -1 } do
		rod(model, "DriveBand", 0.1, at(-0.95, hubY + sign * radius, hubZ).Position, at(-0.95, bobbinY + sign * 0.6, bobbinZ).Position, Color3.fromRGB(240, 235, 225))
	end
	-- the fleece it spins from, and (level 2+) a basket of finished yarn
	local fleece = at(1.6, 0, 6.5)
	for _, puff in { { 0, 1.3, 0, 2.6 }, { 1.2, 1, 0.8, 2 }, { -0.6, 1.1, 1.2, 2.2 } } do
		ball(model, "Fleece", puff[4] * s, fleece * CFrame.new(puff[1] * s, puff[2] * s, puff[3] * s), Color3.fromRGB(250, 245, 235), Enum.Material.Fabric)
	end
	if level >= 2 then
		local basket = at(2.4, 0, -8)
		cylinder(model, "YarnBasket", 4.4 * s, 2.2 * s, basket, wood, Enum.Material.Wood)
		for index, spot in { Vector3.new(-0.8, 2.3, 0.3), Vector3.new(0.8, 2.4, -0.4), Vector3.new(0, 2.9, 0.8) } do
			ball(model, "BasketYarn", 2 * s, basket * CFrame.new(spot * s), if golden then GOLD else PLUSH_COLORS[index], Enum.Material.Fabric)
		end
	end
	if level >= 3 then
		local sparkler = makeDecor(model, "SpinnerSparkle", Vector3.one, spool, WHITE)
		sparkler.Transparency = 1
		sparkles(sparkler, if golden then GOLD else Color3.fromRGB(255, 200, 240), if golden then 10 else 5, if golden then 1 else 0.7)
	end
	if golden then
		local light = makeDecor(model, "SpinnerLight", Vector3.one, hub, WHITE)
		light.Transparency = 1
		glow(light, GOLD, 20)
	end
end

-- Pillow Pile (Plushie room, the front-left corner) ------------------------------------
-- Stacks of plump tufted poufs, growing each level, a golden one on top at level 3.

local function pouf(parent: Instance, at: CFrame, diameter: number, height: number, color: Color3, material: Enum.Material?)
	cylinder(parent, "Pouf", diameter, height, at, color, material or Enum.Material.Fabric)
	cylinder(parent, "PoufPiping", diameter + 0.3, 0.35, at * CFrame.new(0, height - 0.25, 0), WHITE, Enum.Material.Fabric)
	cylinder(parent, "PoufPiping", diameter + 0.3, 0.35, at * CFrame.new(0, 0.1, 0), WHITE, Enum.Material.Fabric)
	ball(parent, "PoufTuft", diameter * 0.16, at * CFrame.new(0, height, 0), color:Lerp(WHITE, 0.4), Enum.Material.Fabric)
end

local POUFS = { -- { level, x, y, z, diameter, height, color }
	{ 1, -60, 0, -52, 8, 2.6, 1 },
	{ 1, -60, 2.6, -52, 6.6, 2.4, 2 },
	{ 1, -53, 0, -55, 5.4, 2.2, 5 },
	{ 2, -60, 5, -52, 5.4, 2.2, 3 },
	{ 2, -62, 0, -44, 6.4, 2.4, 4 },
	{ 2, -62, 2.4, -44, 5, 2.2, 1 },
	{ 3, -60, 7.2, -52, 4.4, 2, 0 }, -- golden
	{ 3, -53, 2.2, -55, 4.2, 2, 2 },
}

local function buildPillowPile(model: Model, floor: CFrame, level: number)
	for _, stack in POUFS do
		if stack[1] <= level then
			local golden = stack[7] == 0
			pouf(model, floor * CFrame.new(stack[2], stack[3], stack[4]), stack[5], stack[6], if golden then GOLD else PLUSH_COLORS[stack[7]], if golden then Enum.Material.SmoothPlastic else nil)
			if golden then
				local top = makeDecor(model, "PoufSparkle", Vector3.one, floor * CFrame.new(stack[2], stack[3] + stack[6] + 0.5, stack[4]), WHITE)
				top.Transparency = 1
				sparkles(top, GOLD, 6)
			end
		end
	end
end

-- Button Jar (Plushie room, the back-left corner) --------------------------------------
-- A giant glass jar of sewing buttons that fills up each level; at level 3 (rebirth) it
-- brims over with glowing golden buttons.

local function buildButtonJar(model: Model, floor: CFrame, level: number)
	local base = floor * CFrame.new(-61, 0, 50)
	local height, diameter = 9, 6.6
	cylinder(model, "JarBase", diameter + 0.4, 0.6, base, Color3.fromRGB(200, 225, 240))
	local glass = cylinder(model, "Jar", diameter, height, base * CFrame.new(0, 0.6, 0), Color3.fromRGB(210, 235, 255), Enum.Material.Glass)
	glass.Transparency = 0.6
	cylinder(model, "JarNeck", diameter - 0.8, 0.8, base * CFrame.new(0, height + 0.6, 0), Color3.fromRGB(210, 235, 255), Enum.Material.Glass).Transparency = 0.5
	cylinder(model, "JarLid", diameter + 0.2, 1, base * CFrame.new(0, height + 1.2, 0), PLUSH_COLORS[1])
	makeDecor(model, "JarCloth", Vector3.new(diameter + 1, 0.15, diameter + 1), base * CFrame.new(0, height + 2.25, 0) * CFrame.Angles(0, math.rad(45), 0), PLUSH_COLORS[2], Enum.Material.Fabric)
	cylinder(model, "JarRibbon", diameter + 0.5, 0.5, base * CFrame.new(0, height + 1.4, 0), WHITE, Enum.Material.Fabric)
	-- the buttons inside, up to the fill line
	local fill = ({ 3, 5.8, 8.6 })[level]
	local random = Random.new(7)
	local count = math.floor(fill * 5)
	for index = 1, count do
		local y = 0.9 + (index - 0.5) / count * (fill - 0.4)
		local angle = random:NextNumber(0, math.pi * 2)
		local r = random:NextNumber(0, diameter / 2 - 1.1)
		local golden = level >= 3 and index % 3 == 0
		local color = if golden then GOLD else PLUSH_COLORS[index % #PLUSH_COLORS + 1]
		local at = base * CFrame.new(math.cos(angle) * r, y, math.sin(angle) * r) * CFrame.Angles(random:NextNumber(-1, 1), random:NextNumber(0, 6), random:NextNumber(-1, 1))
		local button = roller(model, "SewingButton", 1.5, 0.35, at, color, if golden then Enum.Material.Neon else nil)
		button.CastShadow = false
	end
	if level >= 3 then
		local light = makeDecor(model, "JarLight", Vector3.one, base * CFrame.new(0, 5, 0), WHITE)
		light.Transparency = 1
		glow(light, GOLD, 18)
		sparkles(light, GOLD, 6, 1)
	end
end

-- Giant Plushie (Plushie room, the front-right corner) ---------------------------------
-- A giant plush brainrot (Tung Tung Tung Sahur, in the room's fabric) sitting on a
-- big round cushion and looking into the room; level 2 is bigger, crowned in gold and
-- sparkling.

local PLUSHIE_ID = "TungTungTungSahur"

local function buildGiantPlushie(model: Model, floor: CFrame, level: number)
	local spot = floor * CFrame.new(58, 0, -50)
	local cushion = if level >= 2 then 15 else 13
	cylinder(model, "PlushieCushion", cushion, 1.8, spot, PLUSH_COLORS[1], Enum.Material.Fabric)
	cylinder(model, "PlushieCushionPiping", cushion + 0.4, 0.4, spot * CFrame.new(0, 1.5, 0), WHITE, Enum.Material.Fabric)
	-- facing into the room (toward its middle and the front)
	local roomward = (floor * CFrame.new(20, 0, -20)).Position
	local root = CFrame.lookAt((spot * CFrame.new(0, 1.8, 0)).Position, Vector3.new(roomward.X, spot.Y + 1.8, roomward.Z))
	local brainrot = Instance.new("Model")
	brainrot.Name = "Plushie"
	if Brainrots.ById[PLUSHIE_ID] then
		for _, partType in Brainrots.PartTypes do
			local part = BrainrotModels.CreatePart(PLUSHIE_ID, partType, "PlushieRoom")
			for _, child in part:GetChildren() do
				child.Parent = brainrot
			end
			part:Destroy()
		end
	end
	brainrot.WorldPivot = CFrame.identity
	brainrot:ScaleTo(if level >= 2 then 4 else 3.3)
	brainrot:PivotTo(root)
	brainrot.Parent = model
	if level >= 2 then
		-- a golden crown on its head, and sparkles all round
		local box, size = brainrot:GetBoundingBox()
		local crown = CFrame.new(box.X, box.Y + size.Y / 2 - 0.4, box.Z) * root.Rotation
		local across = math.min(size.X, size.Z) * 0.6
		cylinder(model, "Crown", across, 1.8, crown, GOLD).Reflectance = 0.3
		for index = 0, 5 do
			local angle = index / 6 * math.pi * 2
			local point = crown * CFrame.new(math.cos(angle) * across * 0.42, 1.8, math.sin(angle) * across * 0.42)
			makeDecor(model, "CrownPoint", Vector3.new(0.7, 1.6, 0.7), point * CFrame.new(0, 0.6, 0), GOLD).Reflectance = 0.3
			ball(model, "CrownGem", 0.8, point * CFrame.new(0, 1.5, 0), PLUSH_COLORS[index % #PLUSH_COLORS + 1], Enum.Material.Neon)
		end
		local sparkler = makeDecor(model, "PlushieSparkle", Vector3.new(size.X, 1, size.Z), CFrame.new(box.Position), WHITE)
		sparkler.Transparency = 1
		sparkles(sparkler, Color3.fromRGB(255, 220, 140), 8, 1)
	end
end

-- Deliveries -----------------------------------------------------------------------
-- Why a room upgrade makes money, shown: every few seconds it sends what it makes over
-- to a line's machine (RoomFX flies it there): presents and boxes into the toy boxes,
-- bubble wrap to the Toy Packer, yarn to the knitting machines, fluff to the fluff
-- machine, buttons to the sewing machine, hearts all round. Each lands with its bonus.
-- The Jack-in-the-Box instead spills coins to the Cash Pad each time it pops (RoomFX).

type Delivery = {
	Kind: string, -- what flies: Gift, Wrap, Box, Yarn, Fluff, Button, Heart
	Target: string, -- the line part it lands on (Dropper parts' names end with it for Yarn)
	Every: number, -- seconds, roughly
	Source: Vector3?, -- room space; or
	FromChild: string?, -- from one of its children with this name (a conveyor box, the train)
}

local DELIVERIES: { [string]: Delivery } = {
	GiftTower = { Kind = "Gift", Target = "Ship", Every = 5, Source = Vector3.new(-60, 14, -52) },
	BubbleWrap = { Kind = "Wrap", Target = "Station3", Every = 4, Source = Vector3.new(-63.5, 6, -14) },
	BoxConveyor = { Kind = "Box", Target = "Ship", Every = 3, FromChild = "ConveyorBox" },
	ToyTrain = { Kind = "Gift", Target = "Assembler", Every = 6, FromChild = "TrainCar" },
	YarnSpinner = { Kind = "Yarn", Target = "KnitYarnBall", Every = 3, Source = Vector3.new(-62, 10, -13) },
	PillowPile = { Kind = "Fluff", Target = "Ship", Every = 4, Source = Vector3.new(-60, 10, -52) },
	ButtonJar = { Kind = "Button", Target = "NeedleHead", Every = 4, Source = Vector3.new(-61, 12, 50) },
	GiantPlushie = { Kind = "Heart", Target = "Ship", Every = 5, Source = Vector3.new(58, 16, -50) },
}

-- API --------------------------------------------------------------------------------

type Spot = {
	Button: Vector3, -- room space, on the floor
	Tag: Vector3, -- room space: where its floating name and bonus show
	Build: (model: Model, floor: CFrame, level: number) -> (),
}

local SPOTS: { [string]: Spot } = {
	GiftTower = { Button = Vector3.new(-52, 0, -42), Tag = Vector3.new(-58, 21, -50), Build = buildGiftTower },
	BubbleWrap = { Button = Vector3.new(-52.5, 0, -10), Tag = Vector3.new(-63, 14, -18), Build = buildBubbleWrap },
	BoxConveyor = { Button = Vector3.new(30, 0, -52), Tag = Vector3.new(30, 19, -50), Build = buildBoxConveyor },
	JackBox = { Button = Vector3.new(50, 0, -48), Tag = Vector3.new(59, 17, -50), Build = buildJackBox },
	ToyTrain = { Button = Vector3.new(-60, 0, 48), Tag = Vector3.new(-60, 12, 36), Build = buildToyTrain },
	YarnSpinner = { Button = Vector3.new(-52.5, 0, -10), Tag = Vector3.new(-62, 20, -18), Build = buildYarnSpinner },
	PillowPile = { Button = Vector3.new(-52, 0, -42), Tag = Vector3.new(-58, 14, -50), Build = buildPillowPile },
	ButtonJar = { Button = Vector3.new(-61, 0, 41), Tag = Vector3.new(-61, 17, 50), Build = buildButtonJar },
	GiantPlushie = { Button = Vector3.new(48, 0, -46), Tag = Vector3.new(58, 25, -50), Build = buildGiantPlushie },
}

-- Where a room upgrade's button goes, room space.
function RoomUpgradeBuilder.ButtonSpot(key: string): Vector3
	return SPOTS[key].Button
end

-- Where its floating name and bonus go, room space.
function RoomUpgradeBuilder.TagSpot(key: string): Vector3
	return SPOTS[key].Tag
end

-- Builds a room upgrade at `level` into `model` (already in its room's Lines folder),
-- tagged RoomUpgrade with its delivery for RoomFX.
function RoomUpgradeBuilder.Build(model: Model, floor: CFrame, key: string, level: number)
	SPOTS[key].Build(model, floor, level)
	local delivery = DELIVERIES[key]
	if delivery then
		model:SetAttribute("Delivery", delivery.Kind)
		model:SetAttribute("Target", delivery.Target)
		model:SetAttribute("Every", delivery.Every)
		if delivery.Source then
			model:SetAttribute("Source", (floor * CFrame.new(delivery.Source)).Position)
		end
		model:SetAttribute("FromChild", delivery.FromChild)
	end
	CollectionService:AddTag(model, "RoomUpgrade")
end

return RoomUpgradeBuilder
