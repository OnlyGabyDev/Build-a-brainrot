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

	A bought level drops in (Client/DropIn) in the order it was built here: each direct
	child Model of the upgrade falls as one piece (a present, a cushion, a jar's
	buttons, a train car), every loose part on its own (a track goes down segment by
	segment). So build bottom to top, and group what should land whole.

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
local LoopPath = require(ReplicatedStorage.Shared.LoopPath)
local RibbonBow = require(ReplicatedStorage.Shared.RibbonBow)

local FactoryBuilder = require(script.Parent.FactoryBuilder)

local RoomUpgradeBuilder = {}

local WHITE = Color3.new(1, 1, 1)
local INK = Color3.fromRGB(45, 30, 60)
-- Solid gold is Metal with no Reflectance: reflectance mixes in the pale sky and turns
-- gold to cream.
local GOLD = Color3.fromRGB(255, 190, 40)
local WOOD = Color3.fromRGB(225, 175, 120)
local TOY_COLORS = {
	Color3.fromRGB(255, 80, 100), -- red
	Color3.fromRGB(255, 200, 40), -- yellow
	Color3.fromRGB(50, 150, 255), -- blue
	Color3.fromRGB(80, 205, 90), -- green
	Color3.fromRGB(160, 95, 255), -- purple
	Color3.fromRGB(255, 140, 40), -- orange
}
-- The Plushie room is a plush factory (RoomDecor), not a nursery: glossy magenta and
-- violet with gold and chrome, neon accents.
local PLUSH_COLORS = {
	Color3.fromRGB(255, 70, 160), -- magenta
	Color3.fromRGB(140, 90, 255), -- violet
	Color3.fromRGB(40, 200, 255), -- cyan
	Color3.fromRGB(255, 200, 50), -- yellow
	Color3.fromRGB(60, 220, 140), -- green
	Color3.fromRGB(255, 120, 60), -- orange
}
local CHROME = Color3.fromRGB(215, 220, 235)
local PLUM = Color3.fromRGB(70, 35, 105)
local CARDBOARD = Color3.fromRGB(210, 160, 105)
local KNIT = "PlushKnit" -- the Plushie room's MaterialVariant (tools/SetupMaterials)
local SIGN_BACK = Color3.fromRGB(40, 28, 60)
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

-- A neon sign (`at`: its middle, -Z its front): glowing letters on a dark panel, framed
-- in neon tubes. `twoSided`: lettered on the back too.
local function neonSign(parent: Instance, at: CFrame, size: Vector2, text: string, color: Color3, twoSided: boolean?): Part
	local panel = makeDecor(parent, "NeonSign", Vector3.new(size.X, size.Y, 0.3), at, SIGN_BACK)
	printOn(panel, Enum.NormalId.Front, text, color:Lerp(WHITE, 0.65), color, true)
	if twoSided then
		printOn(panel, Enum.NormalId.Back, text, color:Lerp(WHITE, 0.65), color, true)
	end
	local tube = color:Lerp(WHITE, 0.3)
	for _, y in { -1, 1 } do
		makeDecor(parent, "NeonTube", Vector3.new(size.X + 0.6, 0.3, 0.4), at * CFrame.new(0, y * (size.Y / 2 + 0.15), 0), tube, Enum.Material.Neon).CastShadow = false
	end
	for _, x in { -1, 1 } do
		makeDecor(parent, "NeonTube", Vector3.new(0.3, size.Y + 0.6, 0.4), at * CFrame.new(x * (size.X / 2 + 0.15), 0, 0), tube, Enum.Material.Neon).CastShadow = false
	end
	return panel
end

-- A bunch of balloons on strings tied at `at`, bobbing (Atmosphere), `rise` studs up.
local function balloons(parent: Instance, at: CFrame, count: number, seed: number, rise: number)
	local bunch = Instance.new("Model")
	bunch.Name = "Balloons"
	for index = 1, count do
		local angle = index * 2.4 + seed
		local top = at * CFrame.new(math.cos(angle) * 1.6, rise + (index % 3) * 1.1, math.sin(angle) * 1.6)
		local color = TOY_COLORS[(index + seed) % #TOY_COLORS + 1]
		local balloon = ball(bunch, "Balloon", 2.8, top, color)
		balloon.Reflectance = 0.1
		ball(bunch, "BalloonKnot", 0.5, top * CFrame.new(0, -1.5, 0), color)
		rod(bunch, "BalloonString", 0.08, at.Position, (top * CFrame.new(0, -1.6, 0)).Position, WHITE).CastShadow = false
	end
	bunch.WorldPivot = at
	tagged(bunch, "Bobbing", parent)
end

-- Chasing bulbs round a circle `y` over the floor (`center`: its middle, room space),
-- `radius` out, about every `gap` studs; none where the circle runs into the walls.
local function bulbRing(parent: Instance, floor: CFrame, center: Vector3, radius: number, gap: number, y: number)
	local count = math.floor(math.pi * 2 * radius / gap)
	local index = 0
	for k = 1, count do
		local angle = k / count * math.pi * 2
		local spot = center + Vector3.new(math.cos(angle) * radius, y, math.sin(angle) * radius)
		if math.abs(spot.X) < 67.3 and math.abs(spot.Z) < 57.3 then
			index += 1
			bulb(parent, floor * CFrame.new(spot), index)
		end
	end
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

-- A brainrot in the Plushie room's fabric (knitted), `scale` times its size, standing on `root`.
local function plushie(id: string, scale: number, root: CFrame): Model
	local brainrot = Instance.new("Model")
	if Brainrots.ById[id] then
		for _, partType in Brainrots.PartTypes do
			local part = BrainrotModels.CreatePart(id, partType, "PlushieRoom")
			for _, child in part:GetChildren() do
				child.Parent = brainrot
			end
			part:Destroy()
		end
	end
	brainrot.WorldPivot = CFrame.identity
	brainrot:ScaleTo(scale)
	brainrot:PivotTo(root)
	return brainrot
end

-- Gift Tower (Toy Workshop, the front-left corner) ------------------------------------
-- A tower of wrapped presents that gains a tier every level, each tier a ring of
-- presents on the one below: a little pile (1); taller, with balloons tied to its foot
-- (2); a third tier on a round stage ringed with chasing lights, a giant bow on top and
-- sparkles (3); then (R2) a wider fourth tier, gold ribbons, and a golden present
-- floating and spinning over the top in a halo of lights, glowing. Each present is a
-- Model, so it drops in whole. It stays under the Box Conveyor's boxes (their bottoms
-- ~20 over the floor).

type GiftTier = { Count: number, Radius: number, Height: number, Size: number }
local GIFT_LEVELS: { { GiftTier } } = {
	{
		{ Count = 3, Radius = 2.6, Height = 4.2, Size = 4.2 },
		{ Count = 1, Radius = 0, Height = 3.2, Size = 3.6 },
	},
	{
		{ Count = 4, Radius = 3.4, Height = 4.6, Size = 4.8 },
		{ Count = 3, Radius = 2.1, Height = 3.8, Size = 3.8 },
		{ Count = 1, Radius = 0, Height = 3, Size = 3.2 },
	},
	{
		{ Count = 5, Radius = 4.2, Height = 4.6, Size = 5.2 },
		{ Count = 4, Radius = 2.9, Height = 4, Size = 4.4 },
		{ Count = 3, Radius = 1.8, Height = 3.4, Size = 3.6 },
		{ Count = 1, Radius = 0, Height = 2.8, Size = 3 },
	},
	{
		{ Count = 6, Radius = 4.8, Height = 4.2, Size = 5.4 },
		{ Count = 5, Radius = 3.6, Height = 3.6, Size = 4.6 },
		{ Count = 4, Radius = 2.5, Height = 3, Size = 3.8 },
		{ Count = 3, Radius = 1.5, Height = 2.6, Size = 3.2 },
	},
}
local GIFT_CENTER = Vector3.new(-60, 0, -51)
local ROOMWARD = Vector3.new(1, 0, 1).Unit -- from the front-left corner toward the room
local GIFT_STAGE = 0.7 -- the stage's top (3+), over the floor

local function buildGiftTower(model: Model, floor: CFrame, level: number)
	local tiers = GIFT_LEVELS[level]
	local golden = level >= 4
	local random = Random.new(11)
	local y = 0
	if level >= 3 then
		-- a round red stage on a gold lip, chasing lights round its edge
		local reach = tiers[1].Radius + tiers[1].Size / 2 + 1.2
		local stage = floor * CFrame.new(GIFT_CENTER)
		cylinder(model, "GiftStageLip", reach * 2 + 0.8, 0.3, stage, GOLD, Enum.Material.Metal)
		cylinder(model, "GiftStage", reach * 2, GIFT_STAGE - 0.3, stage * CFrame.new(0, 0.3, 0), TOY_COLORS[1])
		bulbRing(model, floor, GIFT_CENTER, reach - 0.5, 2.2, GIFT_STAGE + 0.15)
		y = GIFT_STAGE
	end
	local count = 0
	local top: Part? = nil
	for tierIndex, tier in tiers do
		for k = 1, tier.Count do
			count += 1
			-- round from the room's side: the bottom tier straddles it (clear of the
			-- button), the others put a present toward it
			local angle = math.rad(45) + (k - (if tierIndex == 1 then 0.5 else 1)) / tier.Count * math.pi * 2
			local spot = GIFT_CENTER + Vector3.new(math.cos(angle) * tier.Radius, y, math.sin(angle) * tier.Radius)
			local across = tier.Size * random:NextNumber(0.9, 1.05)
			-- neighbours in a tier overlap a little: a hair's difference in height keeps
			-- their tops from sharing a plane (they'd flicker)
			local tall = tier.Height * (1 - (k % 3) * 0.008)
			local color = TOY_COLORS[(tierIndex * 2 + k) % #TOY_COLORS + 1]
			local ribbon = if golden then (if count % 2 == 0 then WHITE else GOLD) elseif count % 3 == 0 then WHITE else TOY_COLORS[(tierIndex * 2 + k + 3) % #TOY_COLORS + 1]
			local gift = Instance.new("Model")
			gift.Name = "Gift"
			top = present(gift, floor * CFrame.new(spot) * CFrame.Angles(0, -angle + random:NextNumber(-0.25, 0.25), 0), Vector3.new(across, tall, across), color, ribbon)
			gift.Parent = model
		end
		y += tier.Height
	end
	if level >= 2 then
		-- balloons tied to the first tier's top, on the room side
		local tie = GIFT_CENTER + ROOMWARD * (tiers[1].Radius + 1) + Vector3.new(0, (if level >= 3 then GIFT_STAGE else 0) + tiers[1].Height, 0)
		balloons(model, floor * CFrame.new(tie), 2 + level, level, 6.5)
	end
	if level == 3 and top then
		-- a giant red bow on the top present, facing the room
		local knot = CFrame.lookAt((floor * CFrame.new(GIFT_CENTER + Vector3.new(0, y + 0.5, 0))).Position, (floor * CFrame.new(GIFT_CENTER + ROOMWARD * 10 + Vector3.new(0, y + 0.5, 0))).Position)
		local bow = RibbonBow.Build(model, knot, 4.2, TOY_COLORS[1])
		bow.Name = "GiftBow"
		sparkles(top, Color3.fromRGB(255, 240, 160), 5)
	end
	if golden then
		-- a golden present floating over the top in a halo of lights, spinning, glowing
		local crown = Instance.new("Model")
		crown.Name = "GoldenGift"
		local at = floor * CFrame.new(GIFT_CENTER + Vector3.new(0, y + 1.6, 0))
		local gold = present(crown, at, Vector3.new(3.4, 3, 3.4), GOLD, WHITE, Enum.Material.Metal)
		for index = 1, 10 do
			local angle = index / 10 * math.pi * 2
			ball(crown, "Halo", 0.5, at * CFrame.new(math.cos(angle) * 2.9, -0.7, math.sin(angle) * 2.9), Color3.fromRGB(255, 235, 140), Enum.Material.Neon).CastShadow = false
		end
		sparkles(gold, GOLD, 10, 1)
		glow(gold, GOLD, 18)
		spinner(crown, model, at * CFrame.new(0, 1.5, 0) * CFrame.Angles(math.pi / 2, 0, 0), 0.9)
	end
end

-- Bubble Wrap Popper (Toy Workshop, on the left wall) ----------------------------------
-- A packing bench against the wall: a roll of bubble wrap at its front end, a sheet of
-- it across the table (RoomFX pops the Bubble parts one by one, each plumping back up a
-- moment later), and boxes wrapped in it stacked at the back end. Every level the bench
-- is longer, with more bubbles and boxes: a little bench (1); a stamping press (a
-- Stamper: RoomFX thumps it on each pop) and spare rolls on a wall shelf (2); a long
-- bench with two presses, rainbow bubbles, a glowing trim and a POP! POP! neon sign (3).

type WrapLevel = { Length: number, Width: number, Rows: number, Columns: number, Roll: number, Presses: number, Boxes: number, Spares: number }
local WRAP_LEVELS: { WrapLevel } = {
	{ Length = 13, Width = 6.6, Rows = 4, Columns = 4, Roll = 3.4, Presses = 0, Boxes = 1, Spares = 0 },
	{ Length = 17, Width = 7, Rows = 7, Columns = 4, Roll = 4.4, Presses = 1, Boxes = 2, Spares = 2 },
	{ Length = 21, Width = 8, Rows = 9, Columns = 5, Roll = 5.2, Presses = 2, Boxes = 3, Spares = 3 },
}
local WRAP_PLASTIC = Color3.fromRGB(195, 230, 255)
local TAPE = Color3.fromRGB(240, 205, 130)

local function buildBubbleWrap(model: Model, floor: CFrame, level: number)
	local spec = WRAP_LEVELS[level]
	local length, width = spec.Length, spec.Width
	local glowing = level >= 3
	local base = floor * CFrame.new(-67.6 + width / 2, 0, -18) -- the table's middle on the floor; +X into the room, -Z toward the front
	local top = 4.2
	local tableColor = TOY_COLORS[3]
	makeDecor(model, "WrapTable", Vector3.new(width, 0.6, length), base * CFrame.new(0, top - 0.3, 0), tableColor)
	makeDecor(model, "WrapTableTrim", Vector3.new(0.3, 0.7, length + 0.2), base * CFrame.new(width / 2 + 0.1, top - 0.3, 0), if glowing then TOY_COLORS[2] else WHITE, if glowing then Enum.Material.Neon else nil)
	local legZ = length / 2 - 0.6
	local legs: { number } = if length > 15 then { -legZ, 0, legZ } else { -legZ, legZ }
	for _, x in { -1, 1 } do
		for _, z in legs do
			makeDecor(model, "WrapTableLeg", Vector3.new(0.8, top - 0.6, 0.8), base * CFrame.new(x * (width / 2 - 0.6), (top - 0.6) / 2, z), tableColor:Lerp(Color3.new(0, 0, 0), 0.25))
		end
	end
	-- the roll, lying across the table at its front end
	local rollZ = -length / 2 + spec.Roll / 2 + 0.3
	local roll = roller(model, "WrapRoll", spec.Roll, width - 0.8, base * CFrame.new(0, top + spec.Roll / 2, rollZ), WRAP_PLASTIC)
	roll.Transparency = 0.25
	roll.Reflectance = 0.1
	roller(model, "WrapCore", spec.Roll * 0.35, width - 0.5, roll.CFrame, CARDBOARD)
	-- the sheet off the roll, bubbles in rows, up to the boxes
	local boxZone = 4.4
	local sheetFrom, sheetTo = rollZ + spec.Roll / 2, length / 2 - boxZone
	local sheetLength = sheetTo - sheetFrom
	makeDecor(model, "WrapSheet", Vector3.new(width - 1, 0.1, sheetLength), base * CFrame.new(0, top + 0.05, (sheetFrom + sheetTo) / 2), WRAP_PLASTIC).Transparency = 0.3
	local across = width - 1.6
	for row = 1, spec.Rows do
		for column = 1, spec.Columns do
			local color = if glowing then TOY_COLORS[(row + column) % #TOY_COLORS + 1]:Lerp(WHITE, 0.3) else Color3.fromRGB(215, 240, 255)
			local spot = base * CFrame.new(-across / 2 + (column - 0.5) * across / spec.Columns, top + 0.15, sheetFrom + (row - 0.5) * sheetLength / spec.Rows)
			local bubble = ball(model, "Bubble", 1, spot, color)
			bubble.Transparency = 0.2
			bubble.Reflectance = 0.15
		end
	end
	-- the stamping presses over the sheet
	local presses = if spec.Presses == 2 then { sheetFrom + sheetLength * 0.27, sheetFrom + sheetLength * 0.73 } elseif spec.Presses == 1 then { (sheetFrom + sheetTo) / 2 } else {}
	for index, z in presses do
		local frame = TOY_COLORS[if index == 1 then 1 else 5]
		for _, x in { -1, 1 } do
			makeDecor(model, "PressPost", Vector3.new(0.7, 7, 0.7), base * CFrame.new(x * (width / 2 - 0.3), top + 3.5, z), frame)
		end
		makeDecor(model, "PressBeam", Vector3.new(width + 0.4, 1, 1.4), base * CFrame.new(0, top + 7, z), frame)
		makeDecor(model, "StamperRod", Vector3.new(0.5, 3, 0.5), base * CFrame.new(0, top + 5, z), Color3.fromRGB(205, 210, 225), Enum.Material.Metal)
		makeDecor(model, "Stamper", Vector3.new(across, 1, 2.4), base * CFrame.new(0, top + 3.2, z), TOY_COLORS[2])
		if glowing then
			ball(model, "PressLamp", 0.9, base * CFrame.new(width / 2 + 0.3, top + 7, z), Color3.fromRGB(255, 240, 160), Enum.Material.Neon).CastShadow = false
		end
	end
	-- boxes wrapped in it, stacked at the back end, each a Model (it drops in whole)
	local y = top
	for index = 1, spec.Boxes do
		local size = 3.6 - (index - 1) * 0.5
		local box = Instance.new("Model")
		box.Name = "WrappedBox"
		local at = base * CFrame.new(0, y + size / 2, length / 2 - boxZone / 2) * CFrame.Angles(0, (index % 2 - 0.5) * 0.35, 0)
		makeDecor(box, "Box", Vector3.one * size, at, CARDBOARD)
		makeDecor(box, "BoxTape", Vector3.new(size + 0.06, size + 0.06, size * 0.26), at, TAPE)
		local wrap = makeDecor(box, "BoxWrap", Vector3.one * (size + 0.35), at, WRAP_PLASTIC)
		wrap.Transparency = 0.72
		wrap.Reflectance = 0.1
		box.Parent = model
		y += size
	end
	-- spare rolls on a shelf on the wall
	if spec.Spares > 0 then
		local shelf = base * CFrame.new(-width / 2 + 1.1, top + 8.4, 0)
		local span = spec.Spares * 3.2
		makeDecor(model, "WrapShelf", Vector3.new(2.2, 0.4, span + 1), shelf, WHITE)
		for _, z in { -span / 2, span / 2 } do
			makeDecor(model, "WrapShelfBracket", Vector3.new(0.5, 1.6, 0.4), shelf * CFrame.new(-0.7, -1, z), tableColor)
		end
		for k = 1, spec.Spares do
			-- lying with its cardboard core toward the room
			local at = shelf * CFrame.new(0, 1.45, -span / 2 + (k - 0.5) * 3.2)
			local spare = roller(model, "SpareRoll", 2.5, 2.2, at, WRAP_PLASTIC)
			spare.Transparency = 0.25
			spare.Reflectance = 0.1
			roller(model, "SpareCore", 0.9, 2.3, at, CARDBOARD)
		end
	end
	if glowing then
		neonSign(model, base * CFrame.new(-width / 2 + 0.3, top + 14.6, 0) * CFrame.Angles(0, -math.pi / 2, 0), Vector2.new(9, 2.6), "💥 POP! POP! 💥", TOY_COLORS[1])
	end
	model:SetAttribute("Level", level)
	tagged(model, "BubbleWrap", model.Parent :: Instance)
end

-- Box Conveyor (Toy Workshop, overhead all round the room) ------------------------------
-- A rail hung from the ceiling in a loop (a rectangle with rounded corners) with
-- packages hanging off it on hooks; RoomFX moves them round, swaying. Every level the
-- rail is chunkier, with more and bigger packages, faster: a few small presents (1);
-- twice as many, starred cardboard crates among them, a white stripe on the rail (2); then
-- (R1) a golden rail glowing underneath, golden presents, the most and the biggest (3).

type ConveyorLevel = { Boxes: number, Speed: number, Size: number, Rail: number }
local CONVEYOR_LEVELS: { ConveyorLevel } = {
	{ Boxes = 6, Speed = 5, Size = 2.2, Rail = 0.6 },
	{ Boxes = 12, Speed = 7, Size = 2.8, Rail = 0.9 },
	{ Boxes = 18, Speed = 9, Size = 3.2, Rail = 1.1 },
}
local CONVEYOR_DARK = Color3.fromRGB(90, 80, 110)
local HOOK_DROP = 1.6 -- from the rail down to a package's top

local function buildBoxConveyor(model: Model, floor: CFrame, level: number)
	local spec = CONVEYOR_LEVELS[level]
	local perimeter = ConveyorPath.Perimeter
	local golden = level >= 3
	local railColor = if golden then GOLD else TOY_COLORS[5]
	-- the rail, in short straight pieces round the loop, with hangers up to the ceiling
	local pieces = 64
	for index = 0, pieces - 1 do
		local from = ConveyorPath.Point(index / pieces * perimeter)
		local to = ConveyorPath.Point((index + 1) / pieces * perimeter)
		local a, b = (floor * CFrame.new(from)).Position, (floor * CFrame.new(to)).Position
		local along = (b - a).Unit * 0.4
		rod(model, "ConveyorRail", spec.Rail, a, b + along, railColor, if golden then Enum.Material.Metal else nil)
		if level >= 2 then
			local up = Vector3.new(0, spec.Rail * 0.45, 0)
			rod(model, "ConveyorStripe", spec.Rail * 0.4, a + up, b + up + along, WHITE)
		end
		if golden then
			local down = Vector3.new(0, spec.Rail / 2 + 0.1, 0)
			rod(model, "ConveyorGlow", 0.35, a - down, b - down + along, TOY_COLORS[2], Enum.Material.Neon).CastShadow = false
		end
		if index % 8 == 0 then
			local hanger = (floor * CFrame.new(from + Vector3.new(0, 1.6, 0))).Position
			makeDecor(model, "ConveyorHanger", Vector3.new(0.3, 3.2, 0.3) * (1 + level * 0.2), CFrame.new(hanger) * floor.Rotation, CONVEYOR_DARK)
		end
	end
	-- the packages, spread evenly round the loop; each one's pivot is its hook on the rail
	local size = spec.Size
	local grow = size / 2.6
	for index = 1, spec.Boxes do
		local phase = (index - 1) / spec.Boxes
		local point, heading = ConveyorPath.Point(phase * perimeter)
		local hook = floor * CFrame.lookAt(point, point + heading)
		local box = Instance.new("Model")
		box.Name = "ConveyorBox"
		makeDecor(box, "Trolley", Vector3.new(1.2, 0.5, 1.4) * grow, hook * CFrame.new(0, spec.Rail / 2 + 0.25 * grow, 0), CONVEYOR_DARK)
		makeDecor(box, "Hook", Vector3.new(0.25, HOOK_DROP, 0.25) * Vector3.new(grow, 1, grow), hook * CFrame.new(0, -HOOK_DROP / 2, 0), Color3.fromRGB(205, 210, 225), Enum.Material.Metal)
		local bottom = hook * CFrame.new(0, -HOOK_DROP - size, 0)
		local goldBox = golden and index % 3 == 0
		if level >= 2 and not goldBox and index % 2 == 0 then
			-- a cardboard crate, taped up
			local center = bottom * CFrame.new(0, size / 2, 0)
			local crate = makeDecor(box, "Crate", Vector3.one * size, center, CARDBOARD)
			makeDecor(box, "CrateTape", Vector3.new(size + 0.06, size + 0.06, size * 0.26), center, TAPE)
			-- a star stamped on the faces the tape doesn't cross
			printOn(crate, Enum.NormalId.Front, "★", Color3.fromRGB(255, 90, 110), WHITE)
			printOn(crate, Enum.NormalId.Back, "★", Color3.fromRGB(255, 90, 110), WHITE)
		else
			local color = if goldBox then GOLD else TOY_COLORS[index % #TOY_COLORS + 1]
			local gift = present(box, bottom, Vector3.one * size, color, if goldBox then WHITE else TOY_COLORS[(index + 2) % #TOY_COLORS + 1], if goldBox then Enum.Material.Metal else nil)
			if goldBox then
				sparkles(gift, GOLD, 3)
			end
		end
		box:SetAttribute("Phase", phase)
		box.WorldPivot = hook
		box.Parent = model
	end
	model:SetAttribute("Origin", floor)
	model:SetAttribute("Speed", spec.Speed)
	tagged(model, "BoxConveyor", model.Parent :: Instance)
end

-- Jack-in-the-Box (Toy Workshop, the front-right corner) -------------------------------
-- A giant toy box with a crank. Every few seconds (RoomFX) the crank whirs, the lid
-- flips open and a brainrot head springs out on a coil with confetti, spilling coins
-- onto the Cash Pad. Level 2 (R3): a bigger box on a gold-rimmed stage, glowing
-- question marks, chasing lights round its top, and heaps of gold coins round its foot.

local function coinStack(parent: Instance, at: CFrame, count: number, seed: number)
	local stack = Instance.new("Model")
	stack.Name = "CoinStack"
	local random = Random.new(seed)
	for k = 1, count do
		local spot = at * CFrame.new(random:NextNumber(-0.15, 0.15), 0.17 + (k - 1) * 0.32, random:NextNumber(-0.15, 0.15))
		roller(stack, "Coin", 1.8, 0.32, spot * CFrame.Angles(0, random:NextNumber(0, 6), math.pi / 2), GOLD, Enum.Material.Metal)
	end
	stack.Parent = parent
end

local function buildJackBox(model: Model, floor: CFrame, level: number)
	local big = level >= 2
	local s = if big then 1.25 else 1
	local size = 8 * s
	local stage = if big then 0.8 else 0
	local spot = floor * CFrame.new(59.5, 0, -50.5)
	local center = spot * CFrame.new(0, stage, 0)
	local body = TOY_COLORS[1]
	local trim = TOY_COLORS[2]
	if big then
		-- the stage: a gold-rimmed purple slab, heaps of coins round it
		makeDecor(model, "JackStage", Vector3.new(size + 3, stage, size + 3), spot * CFrame.new(0, stage / 2, 0), TOY_COLORS[5])
		makeDecor(model, "JackStageRim", Vector3.new(size + 3.4, 0.3, size + 3.4), spot * CFrame.new(0, stage - 0.1, 0), GOLD, Enum.Material.Metal)
		for index, heap in { { -5.6, 7.8, 7 }, { -2.2, 8.5, 5 }, { -8.2, -4.6, 4 } } do
			coinStack(model, spot * CFrame.new(heap[1], 0, heap[2]), heap[3], index)
		end
	end
	local box = makeDecor(model, "JackBody", Vector3.one * size, center * CFrame.new(0, size / 2, 0), body)
	box.CanCollide = true
	for _, corner in { Vector2.new(-1, -1), Vector2.new(-1, 1), Vector2.new(1, -1), Vector2.new(1, 1) } do
		makeDecor(model, "JackTrim", Vector3.new(0.9 * s, size + 0.2, 0.9 * s), center * CFrame.new(corner.X * size / 2, size / 2, corner.Y * size / 2), trim)
	end
	makeDecor(model, "JackBand", Vector3.new(size + 0.3, 0.8 * s, size + 0.3), center * CFrame.new(0, 0.4 * s, 0), trim)
	for _, face in { Enum.NormalId.Front, Enum.NormalId.Back, Enum.NormalId.Left, Enum.NormalId.Right } do
		printOn(box, face, "?", if big then Color3.fromRGB(255, 245, 190) else WHITE, if big then trim else INK, big)
	end
	-- the lid, hinged along its top edge on the wall side (+X); RoomFX turns it about
	-- its pivot's X by OpenAngle to open it
	local hinge = center * CFrame.fromMatrix(Vector3.new(size / 2, size, 0), Vector3.zAxis, Vector3.yAxis)
	local lid = Instance.new("Model")
	lid.Name = "JackLid"
	makeDecor(lid, "Lid", Vector3.new(size + 0.6, 0.8 * s, size + 0.6), hinge * CFrame.new(0, 0.4 * s, size / 2), trim)
	makeDecor(lid, "LidTop", Vector3.new(size - 1.4, 0.4 * s, size - 1.4), hinge * CFrame.new(0, 0.9 * s, size / 2), body)
	ball(lid, "LidKnob", 1.2 * s, hinge * CFrame.new(0, 0.5 * s, size + 0.4), if big then GOLD else WHITE, if big then Enum.Material.Metal else nil)
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
	if big then
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

-- Toy Train (Toy Workshop, along the left wall at the back) ----------------------------
-- A table with a toy train running round an oval track (RoomFX moves its TrainCar
-- models along the LoopPath in its attributes; each car's Offset is how many studs it
-- runs behind the engine). Every level the table, the train and the track grow and
-- more wagons join; one wagon carries the loot: a heap of gold coins (level 2), then
-- diamonds (3), then both (4). Pine trees on the table, then a snowy mountain and a
-- neon station sign (3), then a golden engine, a glowing track and chasing lights (4).

type TrainLevel = {
	Scale: number, -- the train and the track
	Width: number, -- the table's half width (its round ends' radius)
	Straight: number, -- half the length of the table's straight sides
	Speed: number, -- studs per second
	Wagons: { string }, -- behind the engine: Gift, Coins, Diamonds, Both
}
local TRAIN_LEVELS: { TrainLevel } = {
	{ Scale = 1, Width = 7, Straight = 0, Speed = 3, Wagons = { "Gift", "Gift" } },
	{ Scale = 1.15, Width = 7.6, Straight = 5, Speed = 3.6, Wagons = { "Coins", "Gift", "Gift" } },
	{ Scale = 1.3, Width = 8.3, Straight = 9, Speed = 4.2, Wagons = { "Diamonds", "Gift", "Coins", "Gift" } },
	{ Scale = 1.45, Width = 9, Straight = 11, Speed = 5, Wagons = { "Both", "Gift", "Diamonds", "Coins", "Gift" } },
}
local TRAIN_TABLE_TOP = 3.7
local GEM_COLORS = { Color3.fromRGB(90, 230, 255), Color3.fromRGB(255, 110, 220), Color3.fromRGB(170, 120, 255) }

-- An oval slab (`at`: its bottom middle): a box between two round ends, its long way
-- along Z.
local function stadium(parent: Instance, name: string, halfWidth: number, straight: number, height: number, at: CFrame, color: Color3, material: Enum.Material?)
	if straight > 0 then
		makeDecor(parent, name, Vector3.new(halfWidth * 2, height, straight * 2), at * CFrame.new(0, height / 2, 0), color, material)
	end
	local ends = if straight > 0 then { -straight, straight } else { 0 }
	for _, z in ends do
		cylinder(parent, name, halfWidth * 2, height, at * CFrame.new(0, 0, z), color, material)
	end
end

local function pineTree(parent: Instance, at: CFrame, height: number)
	cylinder(parent, "PineTrunk", height * 0.16, height * 0.3, at, Color3.fromRGB(140, 90, 60), Enum.Material.Wood)
	for tier = 0, 2 do
		local width = height * (0.62 - tier * 0.17)
		cylinder(parent, "PineTier", width, height * 0.26, at * CFrame.new(0, height * (0.24 + tier * 0.22), 0), Color3.fromRGB(40, 150, 80):Lerp(Color3.fromRGB(90, 200, 110), tier * 0.3))
	end
	ball(parent, "PineSnow", height * 0.16, at * CFrame.new(0, height * 0.95, 0), WHITE)
end

-- `at`: the car's base on the rails, -Z the way it goes; `s`: its scale.
local function buildEngine(car: Model, at: CFrame, golden: boolean, s: number)
	local function p(x: number, y: number, z: number): CFrame
		return at * CFrame.new(x * s, y * s, z * s)
	end
	local dark = Color3.fromRGB(60, 50, 70)
	local boiler = if golden then GOLD else TOY_COLORS[1]
	local shiny = if golden then Enum.Material.Metal else nil
	makeDecor(car, "Chassis", Vector3.new(1.4, 0.5, 2.8) * s, p(0, 0.6, 0), dark)
	roller(car, "Boiler", 1.3 * s, 1.7 * s, p(0, 1.45, -0.45) * CFrame.Angles(0, math.pi / 2, 0), boiler, shiny)
	roller(car, "BoilerBand", 1.38 * s, 0.18 * s, p(0, 1.45, -0.2) * CFrame.Angles(0, math.pi / 2, 0), if golden then WHITE else GOLD, Enum.Material.Metal)
	roller(car, "Smokebox", 1.35 * s, 0.3 * s, p(0, 1.45, -1.35) * CFrame.Angles(0, math.pi / 2, 0), dark)
	cylinder(car, "Chimney", 0.55 * s, 0.9 * s, p(0, 2.05, -0.9), dark)
	makeDecor(car, "Cab", Vector3.new(1.4, 1.5, 1.1) * s, p(0, 1.6, 0.8), if golden then TOY_COLORS[5] else TOY_COLORS[3])
	makeDecor(car, "CabRoof", Vector3.new(1.7, 0.25, 1.4) * s, p(0, 2.45, 0.8), boiler, shiny)
	ball(car, "Lamp", 0.4 * s, p(0, 1.5, -1.55), Color3.fromRGB(255, 240, 160), Enum.Material.Neon)
	makeDecor(car, "Cowcatcher", Vector3.new(1.3, 0.4, 0.35) * s, p(0, 0.45, -1.5), TOY_COLORS[2])
	for _, x in { -0.75, 0.75 } do
		for _, z in { -0.9, 0.9 } do
			roller(car, "Wheel", 0.8 * s, 0.25 * s, p(x, 0.4, z), TOY_COLORS[2])
		end
	end
end

-- A wagon: a present, or an open hopper heaped with loot (Coins, Diamonds or Both).
local function buildWagon(car: Model, at: CFrame, index: number, cargo: string, s: number)
	local function p(x: number, y: number, z: number): CFrame
		return at * CFrame.new(x * s, y * s, z * s)
	end
	local color = TOY_COLORS[(index + 3) % #TOY_COLORS + 1]
	makeDecor(car, "Chassis", Vector3.new(1.3, 0.45, 2.2) * s, p(0, 0.6, 0), color)
	for _, x in { -0.7, 0.7 } do
		for _, z in { -0.7, 0.7 } do
			roller(car, "Wheel", 0.7 * s, 0.25 * s, p(x, 0.35, z), Color3.fromRGB(60, 50, 70))
		end
	end
	if cargo == "Gift" then
		present(car, p(0, 0.82, 0) * CFrame.Angles(0, index, 0), Vector3.new(1.1, 1, 1.1) * s, TOY_COLORS[(index + 1) % #TOY_COLORS + 1], WHITE)
		return
	end
	-- the hopper: an open tub with a gold rim
	makeDecor(car, "HopperFloor", Vector3.new(1.3, 0.15, 2) * s, p(0, 0.9, 0), color)
	for _, side in { -1, 1 } do
		makeDecor(car, "HopperSide", Vector3.new(0.15, 0.8, 2) * s, p(side * 0.6, 1.3, 0), color)
		makeDecor(car, "HopperEnd", Vector3.new(1.3, 0.8, 0.15) * s, p(0, 1.3, side * 0.95), color)
		makeDecor(car, "HopperRim", Vector3.new(0.22, 0.15, 2.1) * s, p(side * 0.6, 1.75, 0), GOLD, Enum.Material.Metal)
	end
	local random = Random.new(index * 7 + #cargo)
	if cargo == "Coins" or cargo == "Both" then
		local count = if cargo == "Both" then 8 else 11
		for k = 1, count do
			local spot = p(random:NextNumber(-0.4, 0.4), 1.25 + (k / count) * 0.75, random:NextNumber(-0.7, 0.7))
			roller(car, "CargoCoin", 0.62 * s, 0.14 * s, spot * CFrame.Angles(random:NextNumber(-0.5, 0.5), random:NextNumber(0, 6), math.pi / 2 + random:NextNumber(-0.5, 0.5)), GOLD, Enum.Material.Metal)
		end
	end
	if cargo == "Diamonds" or cargo == "Both" then
		local count = if cargo == "Both" then 4 else 6
		for k = 1, count do
			local spot = p(random:NextNumber(-0.35, 0.35), 1.45 + (k / count) * 0.7, random:NextNumber(-0.6, 0.6))
			local gem = makeDecor(car, "CargoGem", Vector3.one * 0.5 * s, spot * CFrame.Angles(math.rad(45), random:NextNumber(0, 6), math.rad(35)), GEM_COLORS[k % #GEM_COLORS + 1], Enum.Material.Neon)
			gem.CastShadow = false
		end
	end
	if cargo == "Both" then
		local sparkler = makeDecor(car, "CargoSparkle", Vector3.one * 0.2, p(0, 2, 0), WHITE)
		sparkler.Transparency = 1
		sparkles(sparkler, GOLD, 6, 0.6)
	end
end

local function buildToyTrain(model: Model, floor: CFrame, level: number)
	local spec = TRAIN_LEVELS[level]
	local s, width, straight = spec.Scale, spec.Width, spec.Straight
	local center = floor * CFrame.new(-58, 0, 34)
	local top = TRAIN_TABLE_TOP
	-- the table: legs, a colored skirt, the wooden top, green felt (level 4: a gold rim)
	local legs = if straight > 6 then { -straight, 0, straight } elseif straight > 0 then { -straight, straight } else { 0 }
	for _, z in legs do
		for _, x in { -1, 1 } do
			local spot = center * CFrame.new(x * (width - 2.2), (top - 1.2) / 2, z + (if straight == 0 then x * 2.5 else 0))
			makeDecor(model, "TrainTableLeg", Vector3.new(0.9, top - 1.2, 0.9), spot, TOY_COLORS[5]:Lerp(Color3.new(0, 0, 0), 0.25))
		end
	end
	stadium(model, "TrainTableSkirt", width + 0.2, straight, 0.7, center * CFrame.new(0, top - 1.2, 0), TOY_COLORS[5])
	stadium(model, "TrainTable", width, straight, 0.6, center * CFrame.new(0, top - 0.6, 0), WOOD, Enum.Material.Wood)
	stadium(model, "TrainFelt", width - 0.4, straight, 0.08, center * CFrame.new(0, top, 0), Color3.fromRGB(90, 190, 90), Enum.Material.Fabric)
	if level >= 4 then
		stadium(model, "TrainTableRim", width + 0.35, straight, 0.3, center * CFrame.new(0, top - 0.85, 0), GOLD, Enum.Material.Metal)
	end

	-- the track: sleepers and two rails round the loop, laid segment by segment (so it
	-- drops in that way)
	local radius = width - 1.8 * s
	local path = LoopPath.new(radius, radius + straight, radius)
	local track = center * CFrame.new(0, top + 0.08, 0)
	local gauge = 0.5 * s
	local segments = math.max(16, math.floor(path.Perimeter / (1.5 * s)))
	local step = path.Perimeter / segments
	for index = 0, segments - 1 do
		local a, headingA = path:Point(index * step)
		local b, headingB = path:Point((index + 1) * step)
		local middle, heading = path:Point((index + 0.5) * step)
		makeDecor(model, "Sleeper", Vector3.new(1.8, 0.15, 0.45) * s, track * CFrame.lookAt(middle, middle + heading) * CFrame.new(0, 0.075 * s, 0), Color3.fromRGB(150, 100, 70))
		for _, side in { -1, 1 } do
			local outA = Vector3.new(-headingA.Z, 0, headingA.X) * side * gauge
			local outB = Vector3.new(-headingB.Z, 0, headingB.X) * side * gauge
			local from = (track * CFrame.new(a + outA + Vector3.new(0, 0.26 * s, 0))).Position
			local to = (track * CFrame.new(b + outB + Vector3.new(0, 0.26 * s, 0))).Position
			rod(model, "Rail", 0.22 * s, from, to + (to - from).Unit * 0.05, if level >= 4 then GOLD else Color3.fromRGB(200, 205, 220), Enum.Material.Metal)
		end
		if level >= 4 then
			local from = (track * CFrame.new(a + Vector3.new(0, 0.17 * s, 0))).Position
			local to = (track * CFrame.new(b + Vector3.new(0, 0.17 * s, 0))).Position
			rod(model, "TrackGlow", 0.2 * s, from, to, TOY_COLORS[2], Enum.Material.Neon).CastShadow = false
		end
	end

	-- inside the loop: pine trees (a hill at level 2), then a snowy mountain
	local inner = radius - gauge - 1
	if level >= 3 then
		for _, z in { -1, 1 } do
			pineTree(model, center * CFrame.new(0, top, z * (straight + inner * 0.45)), 2.4 * s)
		end
		for index, tier in { { 5, 1.6 }, { 3.8, 1.5 }, { 2.6, 1.3 } } do
			cylinder(model, "Mountain", tier[1] * s, tier[2] * s, center * CFrame.new(0, top + (index - 1) * 1.4 * s, 0), Color3.fromRGB(70, 170, 90):Lerp(WHITE, (index - 1) * 0.05))
		end
		ball(model, "MountainSnow", 2.2 * s, center * CFrame.new(0, top + 4.4 * s, 0), WHITE)
	else
		for k, x in { -0.45, 0.45 } do
			pineTree(model, center * CFrame.new(x * inner, top, (k * 2 - 3) * straight * 0.5), 2.4 * s)
		end
		if level >= 2 then
			cylinder(model, "Hill", inner * 1.1, 0.9, center * CFrame.new(0, top, 0), Color3.fromRGB(110, 200, 110))
			ball(model, "HillTop", inner * 0.8, center * CFrame.new(0, top + 0.6, 0), Color3.fromRGB(110, 200, 110))
		end
	end
	if level >= 3 then
		-- the station sign on the table's room side (+X), facing into the room
		local sign = center * CFrame.new(width - 0.9, top, 0) * CFrame.Angles(0, -math.pi / 2, 0)
		for _, x in { -2.6, 2.6 } do
			makeDecor(model, "SignPost", Vector3.new(0.3, 3.4, 0.3), sign * CFrame.new(x, 1.7, 0), Color3.fromRGB(70, 60, 90))
		end
		local panel = makeDecor(model, "StationSign", Vector3.new(6, 1.4, 0.3), sign * CFrame.new(0, 3.4, 0), Color3.fromRGB(40, 28, 60))
		printOn(panel, Enum.NormalId.Front, "🚂 BRAINROT EXPRESS", Color3.fromRGB(255, 240, 180), TOY_COLORS[6], true)
		printOn(panel, Enum.NormalId.Back, "🚂 BRAINROT EXPRESS", Color3.fromRGB(255, 240, 180), TOY_COLORS[6], true)
		for _, y in { -0.82, 0.82 } do
			makeDecor(model, "SignTube", Vector3.new(6.3, 0.18, 0.4), sign * CFrame.new(0, 3.4 + y, 0), TOY_COLORS[6]:Lerp(WHITE, 0.3), Enum.Material.Neon).CastShadow = false
		end
	end
	if level >= 4 then
		-- chasing lights round the rim
		local rim = LoopPath.new(width + 0.3, width + 0.3 + straight, width + 0.3)
		local count = math.floor(rim.Perimeter / 2.2)
		for index = 1, count do
			local at = rim:Point(index / count * rim.Perimeter)
			bulb(model, center * CFrame.new(at + Vector3.new(0, top - 0.55, 0)), index)
		end
	end

	-- the train, engine first, each car standing on the track facing the way it goes
	local spacing = 3.1 * s
	local cars = { "Engine" }
	for _, cargo in spec.Wagons do
		table.insert(cars, cargo)
	end
	local lift = 0.4 * s
	for index, kind in cars do
		local offset = (index - 1) * spacing
		local point, heading = path:Point(-offset)
		local at = track * CFrame.lookAt(point, point + heading) * CFrame.new(0, lift, 0)
		local car = Instance.new("Model")
		car.Name = "TrainCar"
		if kind == "Engine" then
			buildEngine(car, at, level >= 4, s)
		else
			buildWagon(car, at, index, kind, s)
		end
		car:SetAttribute("Offset", offset)
		car.WorldPivot = at
		car.Parent = model
	end
	model:SetAttribute("Center", track * CFrame.new(0, lift, 0))
	model:SetAttribute("HalfX", radius)
	model:SetAttribute("HalfZ", radius + straight)
	model:SetAttribute("Corner", radius)
	model:SetAttribute("Speed", spec.Speed)
	tagged(model, "ToyTrain", model.Parent :: Instance)
end

-- Yarn Spinner (Plushie room, on the left wall) ---------------------------------------
-- A giant spinning wheel in the plush factory's colors: its magenta wheel turns on two
-- plum uprights over a bench and a band drives the bobbin, which winds yarn from a heap
-- of fleece. Every level it's bigger with more going on: cream yarn (1); magenta yarn
-- and a chrome stand of finished yarn cones (2); rainbow yarn, chasing lights round the
-- wheel, more cones, sparkles and a neon sign (3); then (R3) a golden wheel winding
-- golden thread, glowing, and the stand full of golden cones.

local YARN_SCALES = { 1, 1.15, 1.3, 1.45 }
local CREAM = Color3.fromRGB(250, 245, 235)

-- An industrial thread cone standing on `at`, `s` times its size.
local function yarnCone(parent: Instance, at: CFrame, s: number, color: Color3, material: Enum.Material?)
	cylinder(parent, "ConeFoot", 1.7 * s, 0.3 * s, at, WHITE)
	cylinder(parent, "Cone", 1.9 * s, 1.3 * s, at * CFrame.new(0, 0.3 * s, 0), color, material or Enum.Material.Fabric)
	cylinder(parent, "Cone", 1.4 * s, 1.3 * s, at * CFrame.new(0, 1.6 * s, 0), color:Lerp(WHITE, 0.15), material or Enum.Material.Fabric)
	cylinder(parent, "ConeTip", 0.7 * s, 0.6 * s, at * CFrame.new(0, 2.9 * s, 0), WHITE)
end

local function buildYarnSpinner(model: Model, floor: CFrame, level: number)
	local s = YARN_SCALES[level]
	local base = floor * CFrame.new(-62, 0, -18) -- +X into the room, Z along the wall
	local function at(x: number, y: number, z: number): CFrame
		return base * CFrame.new(x * s, y * s, z * s)
	end
	local golden = level >= 4
	-- the bench on chrome legs, a gold edge
	makeDecor(model, "SpinnerBench", Vector3.new(2.4, 0.8, 12) * s, at(0, 3.2, 0), PLUM)
	makeDecor(model, "SpinnerBenchEdge", Vector3.new(2.6, 0.25, 12.2) * s, at(0, 3.65, 0), GOLD)
	for _, z in { -5, 5 } do
		for _, x in { -0.8, 0.8 } do
			makeDecor(model, "SpinnerLeg", Vector3.new(0.5, 2.9, 0.5) * s, at(x, 1.4, z), CHROME, Enum.Material.Metal)
		end
	end
	-- the wheel's uprights, and the wheel
	local radius = 4
	local hubY, hubZ = 9.6, -2.5
	for _, x in { -0.9, 0.9 } do
		makeDecor(model, "SpinnerUpright", Vector3.new(0.5, 6.5, 0.6) * s, at(x, 6.8, hubZ), PLUM)
	end
	local wheel = Instance.new("Model")
	wheel.Name = "SpinnerWheel"
	local hub = at(0, hubY, hubZ)
	local rim = if golden then GOLD else PLUSH_COLORS[1]
	local segments = 16
	for index = 0, segments - 1 do
		local angle = (index + 0.5) / segments * math.pi * 2
		local radial = Vector3.new(0, math.sin(angle), math.cos(angle))
		local length = 2 * math.pi * radius / segments + 0.1
		makeDecor(wheel, "WheelRim", Vector3.new(0.45, 0.6, length) * s, hub * CFrame.fromMatrix(radial * radius * s, Vector3.xAxis, radial), rim, if golden then Enum.Material.Neon else nil)
		if not golden then
			-- a gold band round its outside
			makeDecor(wheel, "WheelBand", Vector3.new(0.5, 0.15, length) * s, hub * CFrame.fromMatrix(radial * (radius + 0.35) * s, Vector3.xAxis, radial), GOLD)
		end
	end
	for index = 0, 7 do
		local angle = index / 8 * math.pi * 2
		local radial = Vector3.new(0, math.sin(angle), math.cos(angle))
		makeDecor(wheel, "WheelSpoke", Vector3.new(0.25, radius, 0.25) * s, hub * CFrame.fromMatrix(radial * radius * s / 2, Vector3.xAxis, radial), if golden then GOLD else CHROME, Enum.Material.Metal)
	end
	roller(wheel, "WheelHub", 1 * s, 1.2 * s, hub, GOLD)
	if level >= 3 then
		-- chasing lights round the rim, turning with it
		for index = 1, 12 do
			local angle = index / 12 * math.pi * 2
			bulb(wheel, hub * CFrame.new(0.45 * s, math.sin(angle) * (radius + 0.75) * s, math.cos(angle) * (radius + 0.75) * s), index)
		end
	end
	spinner(wheel, model, hub * CFrame.Angles(0, math.pi / 2, 0), 1.6)
	-- the bobbin at the other end, winding yarn (it spins fast), on two little posts
	local bobbinY, bobbinZ = 7.6, 4.2
	for _, x in { -0.9, 0.9 } do
		makeDecor(model, "BobbinPost", Vector3.new(0.4, 4.2, 0.4) * s, at(x, 5.6, bobbinZ), CHROME, Enum.Material.Metal)
	end
	local yarnColors = if golden then { GOLD } elseif level >= 3 then { PLUSH_COLORS[1], PLUSH_COLORS[2], PLUSH_COLORS[3], PLUSH_COLORS[4] } elseif level >= 2 then { PLUSH_COLORS[1] } else { CREAM }
	local bobbin = Instance.new("Model")
	bobbin.Name = "SpinnerBobbin"
	local spool = at(0, bobbinY, bobbinZ)
	roller(bobbin, "BobbinCore", 0.4 * s, 2 * s, spool, CHROME)
	for index, color in yarnColors do
		local width = 1.4 / #yarnColors
		roller(bobbin, "BobbinYarn", 1.5 * s, width * s, spool * CFrame.new((-0.7 + (index - 0.5) * width) * s, 0, 0), color, if golden then Enum.Material.Neon else Enum.Material.Fabric)
	end
	roller(bobbin, "BobbinPulley", 1.2 * s, 0.3 * s, spool * CFrame.new(-0.95 * s, 0, 0), GOLD)
	spinner(bobbin, model, spool * CFrame.Angles(0, math.pi / 2, 0), 7)
	-- the drive band from the wheel's rim to the pulley
	for _, sign in { 1, -1 } do
		rod(model, "DriveBand", 0.1, at(-0.95, hubY + sign * radius, hubZ).Position, at(-0.95, bobbinY + sign * 0.6, bobbinZ).Position, WHITE)
	end
	-- the fleece it spins from
	local fleece = at(0.2, 0, 8.2) -- past the bench's end, clear of the line's paint bucket
	for index, puff in { { 0, 1.3, 0, 2.6 }, { 1.2, 1, 0.8, 2 }, { -0.6, 1.1, 1.2, 2.2 } } do
		local color = if level >= 3 and index == 2 then Color3.fromRGB(255, 205, 230) else CREAM
		ball(model, "Fleece", puff[4] * s, fleece * CFrame.new(puff[1] * s, puff[2] * s, puff[3] * s), color, Enum.Material.Fabric)
	end
	-- the stand of finished cones (2+): a ring on its foot, another on a shelf (3+)
	if level >= 2 then
		local stand = Instance.new("Model")
		stand.Name = "ConeStand"
		local foot = at(2.6, 0, -8.6)
		cylinder(stand, "StandFoot", 4.6 * s, 0.4 * s, foot, CHROME, Enum.Material.Metal)
		cylinder(stand, "StandRim", 4.8 * s, 0.15 * s, foot * CFrame.new(0, 0.4 * s, 0), GOLD)
		cylinder(stand, "StandPole", 0.4 * s, 7.4 * s, foot, CHROME, Enum.Material.Metal)
		local rings = if level >= 3 then { 0.4, 3.9 } else { 0.4 }
		for ringIndex, y in rings do
			if y > 1 then
				cylinder(stand, "StandShelf", 4.2 * s, 0.3 * s, foot * CFrame.new(0, y * s - 0.3 * s, 0), CHROME, Enum.Material.Metal)
			end
			local count = if ringIndex == 1 then 4 else 3
			for k = 1, count do
				local angle = k / count * math.pi * 2 + ringIndex
				local color = if golden then GOLD else PLUSH_COLORS[(k + ringIndex) % #PLUSH_COLORS + 1]
				yarnCone(stand, foot * CFrame.new(math.cos(angle) * 1.4 * s, y * s, math.sin(angle) * 1.4 * s), 0.75 * s, color, if golden then Enum.Material.SmoothPlastic else nil)
			end
		end
		yarnCone(stand, foot * CFrame.new(0, 7.4 * s, 0), 0.8 * s, if golden then GOLD else PLUSH_COLORS[3], if golden then Enum.Material.SmoothPlastic else nil)
		stand.Parent = model
	end
	if level >= 3 then
		local sparkler = makeDecor(model, "SpinnerSparkle", Vector3.one, spool, WHITE)
		sparkler.Transparency = 1
		sparkles(sparkler, if golden then GOLD else Color3.fromRGB(255, 200, 240), if golden then 10 else 5, if golden then 1 else 0.7)
		neonSign(model, base * CFrame.new(-5.75, 22.6, 0) * CFrame.Angles(0, -math.pi / 2, 0), Vector2.new(10, 2.6), "🧶 YARN SPINNER 🧶", if golden then GOLD else PLUSH_COLORS[1])
	end
	if golden then
		local light = makeDecor(model, "SpinnerLight", Vector3.one, hub, WHITE)
		light.Transparency = 1
		glow(light, GOLD, 22)
	end
end

-- Pillow Pile (Plushie room, the front-left corner) ------------------------------------
-- The plush factory's cushion showroom: plump satin cushions with gold tassels, stacked
-- every which way. A stack of three (1); a round velvet display stand under two taller
-- stacks, and a heap on the floor (2); taller still, chasing lights round the stand, and
-- a golden cushion on top with a knitted Tralalero sitting on it, sparkling (3). Each
-- cushion is a Model, so it drops in whole.

local PILE_CENTER = Vector3.new(-59, 0, -50)
local STAND_RADIUS = 6.6
local STAND_HEIGHT = 1.2

-- A plump square cushion standing on `at`: an ellipsoid puffed round a flat core (whose
-- corners poke out, pointy), gold tassels on the corners, a tufted button on top.
local function cushion(parent: Instance, at: CFrame, size: Vector3, color: Color3, golden: boolean?): Model
	local model = Instance.new("Model")
	model.Name = "Cushion"
	local middle = at * CFrame.new(0, size.Y / 2, 0)
	local core = makeDecor(model, "CushionCore", Vector3.new(size.X * 0.88, size.Y * 0.5, size.Z * 0.88), middle, color)
	local puff = makeDecor(model, "CushionPuff", size, middle, color)
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = puff
	if not golden then
		core.Reflectance = 0.06 -- satin
		puff.Reflectance = 0.06
	end
	for _, corner in { Vector2.new(-1, -1), Vector2.new(-1, 1), Vector2.new(1, -1), Vector2.new(1, 1) } do
		local tip = middle * CFrame.new(corner.X * size.X * 0.46, 0, corner.Y * size.Z * 0.46)
		ball(model, "Tassel", 0.55, tip, GOLD)
		local fringe = math.clamp(size.Y / 2 - 0.3, 0.25, 0.9) -- clear of the floor
		makeDecor(model, "TasselFringe", Vector3.new(0.35, fringe, 0.35), tip * CFrame.new(0, -0.25 - fringe / 2, 0), GOLD)
	end
	ball(model, "CushionTuft", 0.6, at * CFrame.new(0, size.Y * 0.97, 0), if golden then WHITE else GOLD)
	model.Parent = parent
	return model
end

-- A stack of cushions on `at`, `widths` from the bottom up, each turned a bit more;
-- returns the height of its top.
local function cushionStack(parent: Instance, at: CFrame, widths: { number }, seed: number): number
	local y = 0
	for k, width in widths do
		local height = width * 0.34
		cushion(parent, at * CFrame.new(0, y, 0) * CFrame.Angles(0, (k + seed) * 0.45, 0), Vector3.new(width, height, width), PLUSH_COLORS[(k + seed) % 3 + 1])
		y += height * 0.82 -- they sink into each other a little
	end
	return y
end

local PILE_LEVELS = {
	{ A = { 7, 6.2, 5.4 } },
	{ A = { 6.4, 5.8, 5.2, 4.6 }, B = { 4.8, 4.2, 3.6 } },
	{ A = { 6.6, 6, 5.4, 4.8, 4.2 }, B = { 4.8, 4.2, 3.6, 3 } },
}

local function buildPillowPile(model: Model, floor: CFrame, level: number)
	local spec = PILE_LEVELS[level]
	local center = floor * CFrame.new(PILE_CENTER)
	if not spec.B then
		cushionStack(model, center, spec.A, 0)
		return
	end
	-- the display stand: chrome, violet velvet, a gold rim
	cylinder(model, "DisplayStand", STAND_RADIUS * 2, 0.5, center, CHROME, Enum.Material.Metal)
	cylinder(model, "DisplayRim", STAND_RADIUS * 2 + 0.3, 0.3, center * CFrame.new(0, 0.45, 0), GOLD)
	cylinder(model, "DisplayVelvet", STAND_RADIUS * 2 - 0.4, STAND_HEIGHT - 0.6, center * CFrame.new(0, 0.6, 0), PLUSH_COLORS[2], Enum.Material.Fabric).MaterialVariant = KNIT
	local stackA = center * CFrame.new(-1.6, STAND_HEIGHT, -1.4)
	local topA = cushionStack(model, stackA, spec.A, 0)
	cushionStack(model, center * CFrame.new(2.4, STAND_HEIGHT, 2.2), spec.B :: { number }, 1)
	-- a heap on the floor beside the stand, along the front wall
	local heap = floor * CFrame.new(PILE_CENTER + Vector3.new(9.6, 0, -4.4))
	cushion(model, heap * CFrame.Angles(0, 0.3, 0), Vector3.new(4.6, 1.6, 4.6), PLUSH_COLORS[3])
	cushion(model, heap * CFrame.new(0.4, 1.2, -0.3) * CFrame.Angles(math.rad(14), 1.1, 0), Vector3.new(3.8, 1.3, 3.8), PLUSH_COLORS[1])
	if level >= 3 then
		cushion(model, heap * CFrame.new(2.6, 0, 1.4) * CFrame.Angles(0, -0.5, math.rad(18)), Vector3.new(3.4, 1.2, 3.4), PLUSH_COLORS[2])
		bulbRing(model, floor, PILE_CENTER, STAND_RADIUS + 0.35, 2, 0.9)
		-- the golden cushion on top, and the plushie sitting on it, facing the room
		local goldAt = stackA * CFrame.new(0, topA, 0)
		local gold = cushion(model, goldAt, Vector3.new(4.6, 1.6, 4.6), GOLD, true)
		local sparkler = makeDecor(gold, "CushionSparkle", Vector3.new(4, 1, 4), goldAt * CFrame.new(0, 1.6, 0), WHITE)
		sparkler.Transparency = 1
		sparkles(sparkler, GOLD, 8, 0.9)
		local seat = goldAt * CFrame.new(0, 1.3, 0)
		local roomward = (floor * CFrame.new(0, 0, 0)).Position
		local plush = plushie("TralaleroTralala", 0.7, CFrame.lookAt(seat.Position, Vector3.new(roomward.X, seat.Y, roomward.Z)))
		plush.Name = "Plushie"
		plush.Parent = model
	end
end

-- Button Jar (Plushie room, the back-left corner) --------------------------------------
-- Giant jars of sewing buttons in the factory's colors, with chrome lids and gold rims.
-- Every level the jar is bigger and fuller and more jars join it: a third full (1);
-- bigger, two-thirds full, a little full jar beside it (2); then (R4) a huge jar
-- brimming over with its lid off, golden buttons glowing among the rest, buttons
-- spilled round its foot, two little jars and a neon sign (3). Each jar's buttons are a
-- Model, so they pour in whole as it drops in.

local JAR_CENTER = Vector3.new(-61, 0, 50)
local JAR_CLEAR = Color3.fromRGB(220, 240, 255)
type JarLevel = { Diameter: number, Height: number, Fill: number, Small: { Vector3 } }
local JAR_LEVELS: { JarLevel } = {
	{ Diameter = 6.6, Height = 9, Fill = 0.35, Small = {} },
	{ Diameter = 7.6, Height = 11, Fill = 0.7, Small = { Vector3.new(-54.4, 0, 53.6) } },
	{ Diameter = 8.6, Height = 13, Fill = 1.12, Small = { Vector3.new(-54, 0, 54), Vector3.new(-55.2, 0, 44.6) } },
}

-- A sewing button lying at `at`, tipped by `tilt`.
local function sewingButton(parent: Instance, at: CFrame, color: Color3, glowing: boolean)
	local button = roller(parent, "SewingButton", 1.5, 0.35, at, color, if glowing then Enum.Material.Neon else nil)
	button.CastShadow = false
end

-- A jar on the floor at `at`: clear plastic (Glass would wash the buttons out), a chrome
-- foot and neck, and (unless `open`) a chrome lid with a gold rim and a magenta knob. Its
-- buttons fill it up to `fill` of its height (over 1: heaped up out of its mouth).
local function buttonJar(parent: Instance, at: CFrame, diameter: number, height: number, fill: number, seed: number, golden: boolean, open: boolean)
	cylinder(parent, "JarFoot", diameter + 0.4, 0.6, at, CHROME, Enum.Material.Metal)
	local jar = cylinder(parent, "Jar", diameter, height, at * CFrame.new(0, 0.6, 0), JAR_CLEAR)
	jar.Transparency = 0.8
	jar.Reflectance = 0.08
	cylinder(parent, "JarNeck", diameter - 0.6, 0.6, at * CFrame.new(0, height + 0.6, 0), CHROME, Enum.Material.Metal)
	if not open then
		cylinder(parent, "JarLid", diameter + 0.2, 0.9, at * CFrame.new(0, height + 1.2, 0), CHROME, Enum.Material.Metal)
		cylinder(parent, "JarLidRim", diameter + 0.4, 0.3, at * CFrame.new(0, height + 1.5, 0), GOLD)
		ball(parent, "JarKnob", math.min(1.6, diameter * 0.25), at * CFrame.new(0, height + 2.2, 0), PLUSH_COLORS[1])
	end
	-- the buttons, layer by layer up to the fill line (and heaped over the mouth)
	local fill_ = Instance.new("Model")
	fill_.Name = "ButtonFill"
	local random = Random.new(seed)
	local inside = diameter / 2 - 0.95
	local fillTo = height * math.min(fill, 1)
	local heap = math.max(fill - 1, 0) * height * 2.2
	local count = math.floor((fillTo + heap * 0.5) * diameter * 1.05)
	for index = 1, count do
		local y = 0.9 + (index - 0.5) / count * (fillTo + heap - 0.4)
		local reach = inside
		if y > height + 0.6 then
			local over = (y - height - 0.6) / heap
			reach = inside * math.sqrt(math.max(1 - over * over, 0.05))
		end
		local angle = random:NextNumber(0, math.pi * 2)
		local r = math.sqrt(random:NextNumber(0, 1)) * reach
		local color = if golden and index % 3 == 0 then GOLD else PLUSH_COLORS[index % #PLUSH_COLORS + 1]
		sewingButton(fill_, at * CFrame.new(math.cos(angle) * r, y, math.sin(angle) * r) * CFrame.Angles(random:NextNumber(-1, 1), random:NextNumber(0, 6), math.pi / 2 + random:NextNumber(-0.6, 0.6)), color, golden and index % 6 == 0)
	end
	fill_.Parent = parent
end

local function buildButtonJar(model: Model, floor: CFrame, level: number)
	local spec = JAR_LEVELS[level]
	local golden = level >= 3
	local base = floor * CFrame.new(JAR_CENTER)
	buttonJar(model, base, spec.Diameter, spec.Height, spec.Fill, 7, golden, golden)
	for index, spot in spec.Small do
		buttonJar(model, floor * CFrame.new(spot), 4, 5.4, 0.92, 20 + index, false, false)
	end
	if golden then
		-- a spill of buttons round its foot (on the back and the sides: its button's in
		-- front)
		local spill = Instance.new("Model")
		spill.Name = "ButtonSpill"
		local random = Random.new(3)
		for index = 1, 16 do
			local angle = random:NextNumber(math.rad(-20), math.rad(200))
			local r = spec.Diameter / 2 + random:NextNumber(0.8, 3.6)
			local spot = base * CFrame.new(math.cos(angle) * r, 0.18, math.sin(angle) * r)
			if math.abs((floor:Inverse() * spot).X) < 67 and math.abs((floor:Inverse() * spot).Z) < 57 then
				sewingButton(spill, spot * CFrame.Angles(0, random:NextNumber(0, 6), math.pi / 2), if index % 4 == 0 then GOLD else PLUSH_COLORS[index % #PLUSH_COLORS + 1], index % 8 == 0)
			end
		end
		spill.Parent = model
		local light = makeDecor(model, "JarLight", Vector3.one, base * CFrame.new(0, spec.Height + 2, 0), WHITE)
		light.Transparency = 1
		glow(light, GOLD, 12)
		sparkles(light, GOLD, 7, 1)
		-- a neon sign hung from the ceiling over it (the wall behind has a window)
		local sign = floor * CFrame.new(JAR_CENTER.X + 0.5, 22.4, JAR_CENTER.Z)
		neonSign(model, sign, Vector2.new(9, 2.6), "✨ BUTTON JAR ✨", PLUSH_COLORS[3], true)
		for _, x in { -3.6, 3.6 } do
			rod(model, "SignCord", 0.15, (sign * CFrame.new(x, 1.75, 0)).Position, (sign * CFrame.new(x, 28 - 22.4, 0)).Position, CHROME, Enum.Material.Metal)
		end
	end
end

-- Giant Plushie (Plushie room, the front-right corner) ---------------------------------
-- A giant plush brainrot (Tung Tung Tung Sahur, knitted) on a big round magenta
-- cushion with gold piping, looking into the room. Every level it grows and more little
-- plushies (other brainrots) gather round its feet on the cushion; level 3 rings the
-- cushion with chasing lights, level 4 crowns it in gold, sparkling.

-- Scale is the giant's size at each level, but never more than fits under the ceiling
-- with its crown on: its height is measured from the art (brainrot art changes size:
-- the v2 Tung made a fixed 2.8 poke its crown through the ceiling).
type PlushieLevel = { Scale: number, Cushion: number, Minis: number }
local PLUSHIE_LEVELS: { PlushieLevel } = {
	{ Scale = 1.7, Cushion = 11, Minis = 0 },
	{ Scale = 2.1, Cushion = 13, Minis = 2 },
	{ Scale = 2.45, Cushion = 15, Minis = 4 },
	{ Scale = 2.8, Cushion = 17, Minis = 6 },
}
local PLUSHIE_ID = "TungTungTungSahur"
local MINI_SCALE = 0.8
local PLUSHIE_CUSHION_HEIGHT = 1.8
local CROWN_RISE = 3.3 -- the crown's gems top out this far over the giant's head
local HEADROOM = 0.6 -- kept free under the ceiling
-- the little ones in the order they join, and where round the big one's feet (degrees
-- from the way it faces)
local MINI_PLUSHIES = {
	{ Id = "TralaleroTralala", Angle = -55 },
	{ Id = "BallerinaCappuccina", Angle = 55 },
	{ Id = "ChimpanziniBananini", Angle = -100 },
	{ Id = "LiriliLarila", Angle = 100 },
	{ Id = "BrrBrrPatapim", Angle = -18 },
	{ Id = "TrippiTroppi", Angle = 18 },
}

local function buildGiantPlushie(model: Model, floor: CFrame, level: number)
	local spec = PLUSHIE_LEVELS[level]
	local spot = floor * CFrame.new(58.5, 0, -49)
	local cushion = spec.Cushion
	cylinder(model, "PlushieCushion", cushion, PLUSHIE_CUSHION_HEIGHT, spot, PLUSH_COLORS[1], Enum.Material.Fabric).MaterialVariant = KNIT
	for _, y in { 0.15, 1.2 } do -- piping bands round its side (the top stays magenta)
		cylinder(model, "PlushieCushionPiping", cushion + 0.4, 0.35, spot * CFrame.new(0, y, 0), GOLD, if level >= 4 then Enum.Material.Metal else nil)
	end
	if level >= 3 then
		-- chasing lights round the cushion's edge
		local count = math.floor(cushion * math.pi / 2)
		for index = 1, count do
			local angle = index / count * math.pi * 2
			bulb(model, spot * CFrame.new(math.cos(angle) * (cushion / 2 + 0.25), 0.9, math.sin(angle) * (cushion / 2 + 0.25)), index)
		end
	end
	-- facing into the room (toward its middle and the front)
	local roomward = (floor * CFrame.new(20, 0, -20)).Position
	local top = spot * CFrame.new(0, PLUSHIE_CUSHION_HEIGHT, 0)
	local root = CFrame.lookAt(top.Position, Vector3.new(roomward.X, top.Y, roomward.Z))
	-- built at scale 1 to measure it (its pivot is its feet, on the cushion), then grown
	local brainrot = plushie(PLUSHIE_ID, 1, root)
	local measured, extent = brainrot:GetBoundingBox()
	local height = measured.Y + extent.Y / 2 - root.Y
	local room = FactoryBuilder.CeilingHeight - HEADROOM - PLUSHIE_CUSHION_HEIGHT - (if level >= 4 then CROWN_RISE else 0)
	brainrot:ScaleTo(math.min(spec.Scale, room / math.max(height, 0.1)))
	brainrot.Name = "Plushie"
	brainrot.Parent = model
	-- the little ones round its feet, each looking into the room too
	for index = 1, spec.Minis do
		local mini = MINI_PLUSHIES[index]
		local at = root * CFrame.Angles(0, math.rad(mini.Angle), 0) * CFrame.new(0, 0, -(cushion / 2 - 1.6))
		local little = plushie(mini.Id, MINI_SCALE, CFrame.new(at.Position) * root.Rotation)
		little.Name = "MiniPlushie"
		little.Parent = model
	end
	if level >= 4 then
		-- a golden crown on its head, and sparkles all round
		local box, size = brainrot:GetBoundingBox()
		local crown = CFrame.new(box.X, box.Y + size.Y / 2 - 0.4, box.Z) * root.Rotation
		local across = math.min(size.X, size.Z) * 0.6
		cylinder(model, "Crown", across, 1.8, crown, GOLD, Enum.Material.Metal)
		for index = 0, 5 do
			local angle = index / 6 * math.pi * 2
			local point = crown * CFrame.new(math.cos(angle) * across * 0.42, 1.8, math.sin(angle) * across * 0.42)
			makeDecor(model, "CrownPoint", Vector3.new(0.7, 1.6, 0.7), point * CFrame.new(0, 0.6, 0), GOLD, Enum.Material.Metal)
			ball(model, "CrownGem", 0.8, point * CFrame.new(0, 1.5, 0), PLUSH_COLORS[index % #PLUSH_COLORS + 1], Enum.Material.Neon)
		end
		local sparkler = makeDecor(model, "PlushieSparkle", Vector3.new(size.X, 1, size.Z), CFrame.new(box.Position), WHITE)
		sparkler.Transparency = 1
		sparkles(sparkler, Color3.fromRGB(255, 220, 140), 8, 1)
	end
end

-- API --------------------------------------------------------------------------------

type Spot = {
	Button: Vector3, -- room space, on the floor
	Tag: Vector3, -- room space: where its floating name and bonus show
	Build: (model: Model, floor: CFrame, level: number) -> (),
}

local SPOTS: { [string]: Spot } = {
	GiftTower = { Button = Vector3.new(-52, 0, -42), Tag = Vector3.new(-50, 18, -42), Build = buildGiftTower },
	BubbleWrap = { Button = Vector3.new(-52.5, 0, -10), Tag = Vector3.new(-58.5, 12.5, -18), Build = buildBubbleWrap },
	BoxConveyor = { Button = Vector3.new(30, 0, -52), Tag = Vector3.new(30, 19, -50), Build = buildBoxConveyor },
	JackBox = { Button = Vector3.new(50, 0, -48), Tag = Vector3.new(51, 15, -55), Build = buildJackBox },
	ToyTrain = { Button = Vector3.new(-56, 0, 8), Tag = Vector3.new(-58, 15, 34), Build = buildToyTrain },
	YarnSpinner = { Button = Vector3.new(-52.5, 0, -10), Tag = Vector3.new(-56, 15, -27), Build = buildYarnSpinner },
	PillowPile = { Button = Vector3.new(-52, 0, -42), Tag = Vector3.new(-50, 13, -50), Build = buildPillowPile },
	ButtonJar = { Button = Vector3.new(-61, 0, 41), Tag = Vector3.new(-55, 15, 44), Build = buildButtonJar },
	GiantPlushie = { Button = Vector3.new(46.5, 0, -54), Tag = Vector3.new(45, 20, -46), Build = buildGiantPlushie },
}

-- Where a room upgrade's button goes, room space.
function RoomUpgradeBuilder.ButtonSpot(key: string): Vector3
	return SPOTS[key].Button
end

-- Where its floating name and bonus go, room space.
function RoomUpgradeBuilder.TagSpot(key: string): Vector3
	return SPOTS[key].Tag
end

-- Builds a room upgrade at `level` into `model` (already in its room's Lines folder).
function RoomUpgradeBuilder.Build(model: Model, floor: CFrame, key: string, level: number)
	SPOTS[key].Build(model, floor, level)
end

return RoomUpgradeBuilder
