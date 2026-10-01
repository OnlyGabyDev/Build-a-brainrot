--[[
	FactoryBuilder
	Builds each plot's factory building around its lines (GDD §10): a toy-house tower
	that grows a storey at a time. Each storey holds two zones' rooms (front and back).
	The ground floor is colored brick with chunky dark trims and flower boxes, the 2nd
	floor wood siding with shutters, under two crossed gabled roofs (a clock in the
	front gable). Bolted on: outside stairs up to the 2nd floor, a turret, a crooked
	chimney and pipes. The entrance faces the hub under the owner's sign; a doorway
	leads into each other room, closed by a shutter until its zone unlocks.
	TycoonManager furnishes the rooms.

	Plot space: origin on the ground at the plot's center, -Z (front) faces the hub.

	Cutaway: whatever sits above the ground floor's ceiling lives in Models tagged
	"Cutaway" with a Level (2: from the ground floor's ceiling up, the 2nd floor; 3:
	from the 2nd floor's ceiling up, the roofs). They're pivoted at the ground floor's
	center, on its floor, with Area (the building's footprint), StoreyHeight and
	CeilingHeight attributes: TycoonFX fades those above your storey while you're
	inside and the camera is up above your ceiling.
]]

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Zones = require(ReplicatedStorage.Shared.Config.Zones)

local FactoryBuilder = {}

FactoryBuilder.RoomSize = Vector3.new(140, 1, 120) -- one zone's floor
FactoryBuilder.FloorTop = 1 -- the ground floor's
FactoryBuilder.CeilingHeight = 28 -- above each floor (the Toy Workshop's chutes hang from it)
FactoryBuilder.StoreyHeight = 30 -- floor to floor: the room, then the slab above it

-- Where each zone's room sits, by zone index: its storey, and its center along Z.
FactoryBuilder.Layout = {
	{ Storey = 1, Z = 0 }, -- Toy Workshop, at the plot's center
	{ Storey = 1, Z = 120 }, -- Plushie Sewing Room, behind it
	{ Storey = 2, Z = 0 }, -- Clay Studio, upstairs
	{ Storey = 2, Z = 120 }, -- Vinyl Collectibles
}

-- The building with its stairs and overhangs, in plot space ("in the plot").
FactoryBuilder.Lot = { HalfWidth = 84, Front = -68, Back = 186 }

local ROOM_SIZE = FactoryBuilder.RoomSize
local FLOOR_TOP = FactoryBuilder.FloorTop
local CEILING = FactoryBuilder.CeilingHeight
local STOREY = FactoryBuilder.StoreyHeight
local STOREYS = 2
local HALF_X = ROOM_SIZE.X / 2
local FRONT_Z = -ROOM_SIZE.Z / 2 -- the building's front face
local BACK_Z = FRONT_Z + ROOM_SIZE.Z * 2 -- and its back face
local WALL = 2 -- thickness
local CEILING_THICKNESS = 0.4
local BAND_TOP = 8 -- the wainscot inside, up to the window sills
local WINDOW = Vector2.new(14, 13) -- its bottom sits on the band
local SIDE_WINDOWS = { -36, 0, 36 } -- along a room's side walls, from its center
local ENTRANCE = Vector2.new(26, 18)
local DOORWAY = Vector2.new(24, 18) -- into a back room
local SIDE_DOOR = Vector2.new(10, 14) -- upstairs, off the outside stairs
local SIDE_DOOR_Z = 31 -- along the front room
local ROOF_BASE = FLOOR_TOP + STOREYS * STOREY + 0.5 -- where the roofs meet the walls
local FRONT_RISE, BACK_RISE = 26, 22
local OVERHANG = 5
local ROOF_THICKNESS = 1.2

-- Creator Store textures (each decal's image id), white so they take a tint.
local BRICK_TEXTURE = "rbxassetid://74130396057975" -- decal 92246549548513
local SIDING_TEXTURE = "rbxassetid://2448219595" -- decal 2448219602
local SHINGLE_TEXTURE = "rbxassetid://9583141656" -- decal 9583141664

local WHITE = Color3.new(1, 1, 1)
local GLASS_COLOR = Color3.fromRGB(150, 220, 255)
local CHIMNEY_COLOR = Color3.fromRGB(225, 120, 95)
local CAP_COLOR = Color3.fromRGB(70, 60, 80)
local WOOD_COLOR = Color3.fromRGB(215, 160, 105)
local WOOD_DARK = Color3.fromRGB(150, 100, 65)
local LEAF_COLOR = Color3.fromRGB(90, 200, 80)
local LAMP_COLOR = Color3.fromRGB(255, 230, 150)
local GOLD_COLOR = Color3.fromRGB(255, 205, 60)
local SIGN_TEXT_COLOR = Color3.fromRGB(120, 70, 200)
local FLOWER_COLORS = {
	Color3.fromRGB(255, 100, 165),
	Color3.fromRGB(255, 215, 60),
	Color3.fromRGB(255, 255, 255),
	Color3.fromRGB(170, 120, 255),
}

-- A plot's colors, from its own pastel: Pastel, Vivid, Dark (trims), Brick, Siding
-- (a pastel of the opposite hue), Stone (the plinth), Roof, BackRoof (the opposite
-- hue again) and White.
type Palette = { [string]: Color3 }

-- Each room's inside.
type RoomStyle = {
	Title: string, -- the sign over its doorway
	SignColor: Color3,
	Floor: Color3,
	FloorMaterial: Enum.Material,
	Wall: Color3?, -- nil: the plot's pastel
	Band: Color3,
	BandMaterial: Enum.Material,
	Trim: Color3, -- door and window frames
	Ceiling: Color3,
}

local ROOM_STYLES: { [string]: RoomStyle } = {
	ToyWorkshop = {
		Title = "🪀 TOY WORKSHOP",
		SignColor = SIGN_TEXT_COLOR,
		Floor = Color3.fromRGB(236, 200, 150),
		FloorMaterial = Enum.Material.WoodPlanks,
		Band = Color3.fromRGB(205, 150, 95),
		BandMaterial = Enum.Material.Wood,
		Trim = WHITE,
		Ceiling = Color3.fromRGB(255, 248, 235),
	},
	PlushieRoom = {
		Title = "🧸 PLUSHIE SEWING ROOM",
		SignColor = Color3.fromRGB(255, 110, 180),
		Floor = Color3.fromRGB(255, 205, 228),
		FloorMaterial = Enum.Material.Fabric,
		Wall = Color3.fromRGB(255, 228, 242),
		Band = Color3.fromRGB(255, 170, 205),
		BandMaterial = Enum.Material.Fabric,
		Trim = Color3.fromRGB(255, 120, 190),
		Ceiling = Color3.fromRGB(255, 236, 246),
	},
	ClayStudio = {
		Title = "🎨 CLAY STUDIO",
		SignColor = Color3.fromRGB(225, 110, 60),
		Floor = Color3.fromRGB(230, 175, 135),
		FloorMaterial = Enum.Material.Sand,
		Wall = Color3.fromRGB(255, 230, 205),
		Band = Color3.fromRGB(215, 125, 85),
		BandMaterial = Enum.Material.SmoothPlastic,
		Trim = Color3.fromRGB(185, 95, 60),
		Ceiling = Color3.fromRGB(255, 242, 228),
	},
	VinylCollectibles = {
		Title = "✨ VINYL COLLECTIBLES",
		SignColor = Color3.fromRGB(90, 120, 255),
		Floor = Color3.fromRGB(120, 140, 230),
		FloorMaterial = Enum.Material.SmoothPlastic,
		Wall = Color3.fromRGB(228, 238, 255),
		Band = Color3.fromRGB(130, 175, 255),
		BandMaterial = Enum.Material.SmoothPlastic,
		Trim = Color3.fromRGB(90, 135, 255),
		Ceiling = Color3.fromRGB(242, 247, 255),
	},
}

-- Each storey's outside (palette keys for the colors).
type Facade = {
	Texture: string,
	Tile: number, -- studs per texture tile
	Wall: string,
	Frame: string, -- window frames
	Pillar: string, -- the round corner pillars
	PillarSize: number,
	Windows: { number }, -- along the front and back walls, from the middle
	Shutters: boolean,
	FlowerBoxes: boolean, -- under the front windows
}

local FACADES: { Facade } = {
	{
		Texture = BRICK_TEXTURE,
		Tile = 12,
		Wall = "Brick",
		Frame = "Dark",
		Pillar = "Dark",
		PillarSize = 5,
		Windows = { -56, -34, 34, 56 },
		Shutters = false,
		FlowerBoxes = true,
	},
	{
		Texture = SIDING_TEXTURE,
		Tile = 10,
		Wall = "Siding",
		Frame = "White",
		Pillar = "Vivid",
		PillarSize = 4.4,
		Windows = { -52, -26, 26, 52 },
		Shutters = true,
		FlowerBoxes = false,
	},
}

local function vivid(color: Color3): Color3
	local hue, saturation, value = color:ToHSV()
	return Color3.fromHSV(hue, math.max(saturation, 0.6), math.max(value, 0.95))
end
FactoryBuilder.Vivid = vivid

local function paletteOf(color: Color3): Palette
	local hue = color:ToHSV()
	local opposite = (hue + 0.45) % 1
	-- Dark yellow turns olive: the yellow plot's trims go brown instead.
	local darkHue = if hue > 0.1 and hue < 0.2 then 0.07 else hue
	local dark = Color3.fromHSV(darkHue, 0.6, 0.4)
	return {
		Pastel = color,
		Vivid = vivid(color),
		Dark = dark,
		Brick = Color3.fromHSV(hue, 0.5, 1),
		Siding = Color3.fromHSV(opposite, 0.22, 1),
		Stone = dark:Lerp(WHITE, 0.3),
		Roof = Color3.fromHSV(hue, 0.75, 0.95),
		BackRoof = Color3.fromHSV(opposite, 0.6, 0.9),
		White = WHITE,
	}
end

local function floorY(storey: number): number
	return FLOOR_TOP + (storey - 1) * STOREY
end
FactoryBuilder.FloorY = floorY

-- A zone's room, by zone index: the center of its floor, in plot space.
function FactoryBuilder.RoomCFrame(zoneIndex: number): CFrame
	local spot = FactoryBuilder.Layout[zoneIndex]
	return CFrame.new(0, floorY(spot.Storey), spot.Z)
end

export type Doorway = {
	Label: TextLabel, -- the sign over it
	Title: string,
	Shutter: BasePart,
}

export type Factory = {
	SignLabel: TextLabel, -- the owner's sign over the entrance
	Doorways: { [string]: Doorway }, -- by zone id, for every room but the first
}

type Opening = {
	X: number, -- center along the wall
	Width: number,
	Height: number, -- from the floor
}

type Room = {
	ZoneId: string,
	Z: number,
	Style: RoomStyle,
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

-- Just for looks: no collisions (so it doesn't push the camera around either).
local function makeDecor(parent: Instance, name: string, size: Vector3, cframe: CFrame, color: Color3, material: Enum.Material?): Part
	local part = makePart(parent, name, size, cframe, color, material)
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	return part
end

local function makeBall(parent: Instance, name: string, diameter: number, cframe: CFrame, color: Color3): Part
	local part = makeDecor(parent, name, Vector3.new(diameter, diameter, diameter), cframe, color)
	part.Shape = Enum.PartType.Ball
	return part
end

-- An upright cylinder standing on `base` (its bottom center).
local function makeCylinder(parent: Instance, name: string, diameter: number, height: number, base: CFrame, color: Color3): Part
	local part = makeDecor(parent, name, Vector3.new(height, diameter, diameter), base * CFrame.new(0, height / 2, 0) * CFrame.Angles(0, 0, math.pi / 2), color)
	part.Shape = Enum.PartType.Cylinder
	return part
end

local function makeWedge(parent: Instance, name: string, size: Vector3, cframe: CFrame, color: Color3): WedgePart
	local wedge = Instance.new("WedgePart")
	wedge.Name = name
	wedge.Anchored = true
	wedge.CanCollide = false
	wedge.CanTouch = false
	wedge.CanQuery = false
	wedge.Size = size
	wedge.CFrame = cframe
	wedge.Color = color
	wedge.Material = Enum.Material.SmoothPlastic
	wedge.Parent = parent
	return wedge
end

local function addTexture(part: BasePart, face: Enum.NormalId, image: string, tile: number, color: Color3, offsetU: number?, offsetV: number?)
	local texture = Instance.new("Texture")
	texture.Texture = image
	texture.Face = face
	texture.StudsPerTileU = tile
	texture.StudsPerTileV = tile
	texture.OffsetStudsU = offsetU or 0
	texture.OffsetStudsV = offsetV or 0
	texture.Color3 = color
	texture.Parent = part
end

-- A sign with text on its front face (-Z of `cframe`), in a colored border with a
-- dark outline.
local function makeSign(parent: Instance, name: string, size: Vector3, cframe: CFrame, color: Color3, border: Color3, outline: Color3, text: string): TextLabel
	makeDecor(parent, name .. "Outline", size + Vector3.new(2.8, 2.8, -0.6), cframe * CFrame.new(0, 0, 0.3), outline)
	makeDecor(parent, name .. "Border", size + Vector3.new(2, 2, -0.4), cframe * CFrame.new(0, 0, 0.2), border)
	local sign = makePart(parent, name, size, cframe, WHITE)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.LightInfluence = 0
	gui.PixelsPerStud = 14 -- scaled text tops out at 100 px: this lets it fill the sign
	gui.Parent = sign
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = color
	label.Text = text
	label.Parent = gui
	return label
end

-- A shutter closing a doorway (on `base`: the floor at the doorway's middle, -Z
-- toward the side people come from), with a big lock on its front.
local function makeShutter(parent: Instance, name: string, size: Vector2, base: CFrame, color: Color3): Part
	local shutter = makePart(parent, name, Vector3.new(size.X, size.Y, 0.8), base * CFrame.new(0, size.Y / 2, 0), color, Enum.Material.DiamondPlate)
	local gui = Instance.new("SurfaceGui")
	gui.Name = "Lock"
	gui.Face = Enum.NormalId.Front
	gui.LightInfluence = 0
	gui.PixelsPerStud = 10
	gui.Parent = shutter
	local lock = Instance.new("TextLabel")
	lock.Size = UDim2.fromScale(1, 0.5)
	lock.Position = UDim2.fromScale(0, 0.25)
	lock.BackgroundTransparency = 1
	lock.TextScaled = true
	lock.Font = Enum.Font.FredokaOne
	lock.Text = "🔒"
	lock.Parent = gui
	return shutter
end

-- A Model for the cutaway (see the header), parented to the plot's model.
local function makeCutaway(model: Model, name: string, level: number, cframe: CFrame): Model
	local cutaway = Instance.new("Model")
	cutaway.Name = name
	cutaway.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	cutaway.WorldPivot = cframe * CFrame.new(0, FLOOR_TOP, (FRONT_Z + BACK_Z) / 2)
	cutaway:SetAttribute("Level", level)
	cutaway:SetAttribute("Area", Vector3.new(ROOM_SIZE.X, STOREYS * STOREY, BACK_Z - FRONT_Z))
	cutaway:SetAttribute("StoreyHeight", STOREY)
	cutaway:SetAttribute("CeilingHeight", CEILING)
	CollectionService:AddTag(cutaway, "Cutaway")
	cutaway.Parent = model
	return cutaway
end

-- Walls ----------------------------------------------------------------------------

-- The stretches of a wall `length` long between its door `openings` (sorted by X).
local function solidSpans(length: number, openings: { Opening }): { { number } }
	local spans = {}
	local x = -length / 2
	for _, opening in openings do
		table.insert(spans, { x, opening.X - opening.Width / 2 })
		x = opening.X + opening.Width / 2
	end
	table.insert(spans, { x, length / 2 })
	return spans
end

-- A wall along the X axis of `base` (on the floor at the wall's middle; -Z is the
-- outside), `length` long and a storey tall, with door `openings` (sorted by X) cut
-- into it. Its color is the room's inside; `skin` textures its outer face, lined up
-- across the slabs so the pattern runs on. A `thickness` builds half of a two-faced
-- wall.
local function buildWall(parent: Instance, base: CFrame, length: number, openings: { Opening }, color: Color3, skin: Facade?, skinColor: Color3?, thickness: number?)
	local depth = thickness or WALL
	local function slab(x0: number, x1: number, y0: number, y1: number)
		if x1 - x0 < 0.01 or y1 - y0 < 0.01 then
			return
		end
		local part = makePart(parent, "Wall", Vector3.new(x1 - x0, y1 - y0, depth), base * CFrame.new((x0 + x1) / 2, (y0 + y1) / 2, 0), color)
		if skin and skinColor then
			-- Seen from outside, U runs toward the base's -X and V down from the top.
			addTexture(part, Enum.NormalId.Front, skin.Texture, skin.Tile, skinColor, x1 % skin.Tile, y1 % skin.Tile)
		end
	end
	for index, span in solidSpans(length, openings) do
		slab(span[1], span[2], 0, STOREY)
		local opening = openings[index]
		if opening then
			local left, right = opening.X - opening.Width / 2, opening.X + opening.Width / 2
			slab(left, right, opening.Height, STOREY)
		end
	end
end

-- The wainscot: a band along the wall's inner face (base's +Z side, `offset` from the
-- base), broken by its doors.
local function buildBand(parent: Instance, base: CFrame, length: number, openings: { Opening }, offset: number, style: RoomStyle)
	for _, span in solidSpans(length, openings) do
		if span[2] - span[1] > 0.01 then
			makeDecor(parent, "Band", Vector3.new(span[2] - span[1], BAND_TOP, 0.3), base * CFrame.new((span[1] + span[2]) / 2, BAND_TOP / 2, offset + 0.15), style.Band, style.BandMaterial)
		end
	end
end

-- A chunky door frame around an opening that starts at the floor.
local function buildDoorFrame(parent: Instance, base: CFrame, size: Vector2, trim: Color3)
	local depth = WALL + 0.8
	local offset = 0.4 -- a 1.4-stud frame reaches 0.3 into the opening, over the cut edges
	for _, side in { -1, 1 } do
		makeDecor(parent, "DoorFrame", Vector3.new(1.4, size.Y, depth), base * CFrame.new(side * (size.X / 2 + offset), size.Y / 2, 0), trim)
	end
	makeDecor(parent, "DoorFrame", Vector3.new(size.X + 2.2, 1.4, depth), base * CFrame.new(0, size.Y + offset, 0), trim)
end

-- A window on a wall's face (`face`: on the face at the window's center, -Z out):
-- light-blue glass in a chunky frame with a cross of bars, a glint, and a sill, a
-- flower box or shutters.
local function buildWindow(parent: Instance, face: CFrame, size: Vector2, frame: Color3, shutters: Color3?, flowerBox: boolean)
	local border, depth = 1.2, 1
	local glass = makeDecor(parent, "Window", Vector3.new(size.X, size.Y, 0.3), face * CFrame.new(0, 0, -0.2), GLASS_COLOR)
	glass.Reflectance = 0.15
	for _, side in { -1, 1 } do
		makeDecor(parent, "WindowFrame", Vector3.new(size.X + border * 2, border, depth), face * CFrame.new(0, side * (size.Y + border) / 2, -depth / 2), frame)
		makeDecor(parent, "WindowFrame", Vector3.new(border, size.Y, depth), face * CFrame.new(side * (size.X + border) / 2, 0, -depth / 2), frame)
	end
	makeDecor(parent, "WindowBar", Vector3.new(0.5, size.Y, 0.6), face * CFrame.new(0, 0, -0.5), frame)
	makeDecor(parent, "WindowBar", Vector3.new(size.X, 0.5, 0.6), face * CFrame.new(0, 0, -0.5), frame)
	local glint = makeDecor(parent, "Glint", Vector3.new(0.5, 3.4, 0.1), face * CFrame.new(-size.X / 4, size.Y / 4, -0.4) * CFrame.Angles(0, 0, math.rad(-45)), WHITE)
	glint.Transparency = 0.2

	local bottom = -size.Y / 2 - border
	if flowerBox then
		local y = bottom - 1.2
		makeDecor(parent, "FlowerBox", Vector3.new(size.X + 2, 2.4, 2.4), face * CFrame.new(0, y, -1.2), WOOD_DARK, Enum.Material.Wood)
		makeDecor(parent, "FlowerLeaves", Vector3.new(size.X + 1, 0.8, 1.8), face * CFrame.new(0, y + 1.5, -1.2), LEAF_COLOR)
		for index, color in FLOWER_COLORS do
			makeBall(parent, "Flower", 1.8, face * CFrame.new(-size.X / 2 + (index - 0.5) * size.X / #FLOWER_COLORS, y + 2.1, -1.2), color)
		end
	else
		makeDecor(parent, "WindowSill", Vector3.new(size.X + 4, 0.8, 1.8), face * CFrame.new(0, bottom - 0.4, -0.9), frame)
	end
	if shutters then
		local width = 4
		for _, side in { -1, 1 } do
			local x = side * (size.X / 2 + border + width / 2 + 0.2)
			makeDecor(parent, "Shutter", Vector3.new(width, size.Y + border * 2, 0.5), face * CFrame.new(x, 0, -0.25), shutters)
			-- slats
			for row = -1, 1 do
				makeDecor(parent, "ShutterSlat", Vector3.new(width - 1, 0.5, 0.3), face * CFrame.new(x, row * size.Y / 3.2, -0.6), shutters:Lerp(Color3.new(0, 0, 0), 0.15))
			end
		end
	end
end

-- The same window seen from inside: a framed light-blue pane (standing proud of the
-- band, so they don't flicker where they meet).
local function buildInnerWindow(parent: Instance, face: CFrame, size: Vector2, frame: Color3)
	makeDecor(parent, "WindowFrame", Vector3.new(size.X + 2.4, size.Y + 2.4, 0.4), face * CFrame.new(0, 0, -0.2), frame)
	makeDecor(parent, "Window", Vector3.new(size.X, size.Y, 0.3), face * CFrame.new(0, 0, -0.35), GLASS_COLOR)
end

-- A wall of the building's outside, with its windows on both faces (and the band
-- inside). `spots` are the windows along the wall; the facade's flower boxes go on
-- the front only.
local function buildOuterWall(layer: Instance, base: CFrame, length: number, openings: { Opening }, spots: { number }, room: Room, storey: number, palette: Palette, isFront: boolean)
	local facade = FACADES[storey]
	local inside = room.Style.Wall or palette.Pastel
	buildWall(layer, base, length, openings, inside, facade, palette[facade.Wall])
	buildBand(layer, base, length, openings, WALL / 2, room.Style)
	local y = BAND_TOP + WINDOW.Y / 2
	for _, x in spots do
		local outer = base * CFrame.new(x, y, -WALL / 2)
		buildWindow(layer, outer, WINDOW, palette[facade.Frame], if facade.Shutters then palette.Vivid else nil, facade.FlowerBoxes and isFront)
		buildInnerWindow(layer, base * CFrame.new(x, y, WALL / 2) * CFrame.Angles(0, math.pi, 0), WINDOW, room.Style.Trim)
	end
end

-- Outside ----------------------------------------------------------------------------

-- A candy-striped awning over the entrance. `hinge` sits on the wall's outer face at
-- the awning's top edge.
local function buildAwning(parent: Instance, hinge: CFrame, width: number, color: Color3)
	local stripes, depth = 7, 7
	local tilted = hinge * CFrame.Angles(math.rad(-22), 0, 0)
	for index = 1, stripes do
		local x = -width / 2 + (index - 0.5) * width / stripes
		local stripe = if index % 2 == 1 then color else WHITE
		makeDecor(parent, "Awning", Vector3.new(width / stripes, 0.4, depth), tilted * CFrame.new(x, 0, -depth / 2), stripe)
		-- a little scallop hanging off the front edge
		makeDecor(parent, "AwningEdge", Vector3.new(width / stripes, 1.2, 0.4), tilted * CFrame.new(x, -0.6, -depth), stripe)
	end
end

-- A wall lamp beside the entrance (`face`: on the wall's outer face, -Z out).
local function buildLamp(parent: Instance, face: CFrame, color: Color3)
	makeDecor(parent, "LampBracket", Vector3.new(0.6, 0.6, 1.6), face * CFrame.new(0, 0, -0.8), color)
	local lamp = makeDecor(parent, "Lamp", Vector3.new(1.6, 2.2, 1.6), face * CFrame.new(0, -0.6, -1.9), LAMP_COLOR, Enum.Material.Neon)
	lamp.CastShadow = false
	makeDecor(parent, "LampCap", Vector3.new(2.2, 0.6, 2.2), face * CFrame.new(0, 0.75, -1.9), color)
end

-- Pastel smoke puffing out of `parent`'s top.
local function addSmoke(parent: BasePart, height: number)
	local attachment = Instance.new("Attachment")
	attachment.Position = Vector3.new(0, height, 0)
	attachment.Parent = parent
	local smoke = Instance.new("ParticleEmitter")
	smoke.Texture = "rbxasset://textures/particles/smoke_main.dds"
	smoke.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 190, 230)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(200, 220, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 245, 200)),
	})
	smoke.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 3), NumberSequenceKeypoint.new(1, 9) })
	smoke.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1) })
	smoke.Lifetime = NumberRange.new(4, 6)
	smoke.Rate = 2.5
	smoke.Speed = NumberRange.new(4, 6)
	smoke.SpreadAngle = Vector2.new(12, 12)
	smoke.RotSpeed = NumberRange.new(-20, 20)
	smoke.Acceleration = Vector3.new(1.5, 0.5, 0)
	smoke.LightEmission = 0.15
	smoke.EmissionDirection = Enum.NormalId.Top
	smoke.Parent = attachment
end

-- A crooked brick chimney (`base`: where it starts, inside the roof), puffing smoke.
local function buildChimney(parent: Instance, base: CFrame, height: number)
	local chimney = makeDecor(parent, "Chimney", Vector3.new(7, height, 7), base * CFrame.new(0, height / 2, 0), CHIMNEY_COLOR, Enum.Material.Brick)
	chimney.CastShadow = false
	makeDecor(parent, "ChimneyBand", Vector3.new(7.8, 1.2, 7.8), base * CFrame.new(0, height - 4, 0), CAP_COLOR)
	local cap = makeDecor(parent, "ChimneyCap", Vector3.new(8.6, 1.4, 8.6), base * CFrame.new(0, height + 0.7, 0), CAP_COLOR)
	addSmoke(cap, 1)
end

-- Outside stairs up the +X wall to a landing at the 2nd floor's side door, under a
-- crooked little porch roof (in `upper`: it goes with the 2nd floor in the cutaway).
-- Plot space.
local function buildStairs(parent: Instance, upper: Instance, cframe: CFrame, palette: Palette)
	local x0 = HALF_X + 1.6 -- clear of the plinth and the trim band
	local width = 8
	local x = x0 + width / 2
	local top = floorY(2)
	local landingFrom, landingTo = SIDE_DOOR_Z - 9, SIDE_DOOR_Z + 9
	local steps = math.floor(top) - 1 -- 1-stud risers, the landing being the last
	local run = 2
	local z0 = landingFrom - steps * run
	for index = 1, steps do
		makePart(parent, "Step", Vector3.new(width, 1, run), cframe * CFrame.new(x, index - 0.5, z0 + (index - 0.5) * run), WOOD_COLOR, Enum.Material.WoodPlanks)
	end
	local length = math.sqrt((steps * run) ^ 2 + top ^ 2)
	local angle = math.atan2(top, steps * run)
	local middle = cframe * CFrame.new(0, top / 2 - 1, (z0 + landingFrom) / 2)
	for _, sx in { x0 + 0.4, x0 + width - 0.4 } do
		makeDecor(parent, "Stringer", Vector3.new(0.8, 2.4, length), middle * CFrame.new(sx, 0, 0) * CFrame.Angles(-angle, 0, 0), WOOD_DARK)
	end
	-- the railing, on the outer side
	local railX = x0 + width - 0.4
	for index = 1, steps, 5 do
		makeDecor(parent, "RailPost", Vector3.new(0.6, 3.6, 0.6), cframe * CFrame.new(railX, index + 1.8, z0 + (index - 0.5) * run), WHITE)
	end
	makeDecor(parent, "Rail", Vector3.new(0.7, 0.5, length), middle * CFrame.new(railX, 4.6, 0) * CFrame.Angles(-angle, 0, 0), WHITE)

	-- the landing, flush with the 2nd floor (and the trim band under the door)
	local landingX0 = HALF_X + 1.4
	local landingWidth = x0 + width - landingX0 + 0.4
	local landingX = landingX0 + landingWidth / 2
	local landingZ = (landingFrom + landingTo) / 2
	makePart(parent, "Landing", Vector3.new(landingWidth, 1.2, landingTo - landingFrom), cframe * CFrame.new(landingX, top - 0.6, landingZ), WOOD_COLOR, Enum.Material.WoodPlanks)
	local outer = landingX0 + landingWidth - 0.6
	for _, z in { landingFrom + 0.6, landingTo - 0.6 } do
		makePart(parent, "LandingPost", Vector3.new(1.2, top - 1.2, 1.2), cframe * CFrame.new(outer, (top - 1.2) / 2, z), WOOD_DARK, Enum.Material.Wood)
		makeDecor(parent, "RailPost", Vector3.new(0.6, 3.6, 0.6), cframe * CFrame.new(outer, top + 1.8, z), WHITE)
	end
	makeDecor(parent, "Rail", Vector3.new(0.7, 0.5, landingTo - landingFrom), cframe * CFrame.new(outer, top + 3.6, landingZ), WHITE)
	makeDecor(parent, "Rail", Vector3.new(landingWidth, 0.5, 0.7), cframe * CFrame.new(landingX, top + 3.6, landingTo - 0.6), WHITE)
	-- invisible walls keep people on the landing and the stairs
	local guard = makePart(parent, "Guard", Vector3.new(0.4, 6, landingTo - landingFrom), cframe * CFrame.new(outer + 0.5, top + 3, landingZ), WHITE)
	guard.Transparency = 1
	local back = makePart(parent, "Guard", Vector3.new(landingWidth, 6, 0.4), cframe * CFrame.new(landingX, top + 3, landingTo), WHITE)
	back.Transparency = 1

	-- the crooked porch roof, on two posts
	local roofLow, roofHigh = top + 21, top + 23.5
	for _, z in { landingFrom + 0.8, landingTo - 0.8 } do
		makeDecor(upper, "PorchPost", Vector3.new(0.8, roofLow - top, 0.8), cframe * CFrame.new(outer - 0.2, top + (roofLow - top) / 2, z), WHITE)
	end
	local roofWidth = outer + 2 - HALF_X
	local tilt = math.atan2(roofHigh - roofLow, roofWidth)
	local porch = cframe * CFrame.new(HALF_X + roofWidth / 2, (roofLow + roofHigh) / 2 + 0.4, landingZ) * CFrame.Angles(math.rad(3), 0, -tilt)
	local slab = makeDecor(upper, "PorchRoof", Vector3.new(roofWidth + 1, 0.8, landingTo - landingFrom + 5), porch, palette.Roof)
	addTexture(slab, Enum.NormalId.Top, SHINGLE_TEXTURE, 8, palette.Roof)
	makeDecor(upper, "PorchFascia", Vector3.new(1, 1.4, landingTo - landingFrom + 5.4), porch * CFrame.new(roofWidth / 2 + 0.5, -0.2, 0), palette.Dark)
end

-- A pipe running up a wall (`base`: on the ground, -X toward the wall), a storey per
-- segment, each segment in that storey's layer; it bends into the wall at the top.
local function buildPipe(layers: { Instance }, base: CFrame, top: number, color: Color3, bracket: Color3)
	local gap = 3 -- from the pipe's center to the wall
	for storey = 1, STOREYS do
		local layer = layers[storey]
		local y0 = if storey == 1 then 0 else floorY(storey) - 1
		local y1 = math.min(floorY(storey + 1) - 1, top)
		makeCylinder(layer, "Pipe", 2.4, y1 - y0, base * CFrame.new(0, y0, 0), color)
		for _, y in { y0 + (y1 - y0) * 0.3, y0 + (y1 - y0) * 0.75 } do
			makeCylinder(layer, "PipeBracket", 3, 0.7, base * CFrame.new(0, y, 0), bracket)
			makeDecor(layer, "PipeBracket", Vector3.new(gap, 0.6, 0.6), base * CFrame.new(-gap / 2, y + 0.35, 0), bracket)
		end
		if storey == 1 then
			makeCylinder(layer, "PipeFoot", 3.2, 1, base, bracket)
		end
	end
	local layer = layers[STOREYS]
	makeBall(layer, "PipeElbow", 2.4, base * CFrame.new(0, top, 0), color)
	local arm = makeDecor(layer, "Pipe", Vector3.new(gap, 2.4, 2.4), base * CFrame.new(-gap / 2, top, 0), color)
	arm.Shape = Enum.PartType.Cylinder
end

-- A round turret on a corner (`base`: on the ground at its center), on a corbel,
-- with a crooked stepped cone roof and a flag.
local function buildTurret(parent: Instance, base: CFrame, outward: Vector3, palette: Palette)
	local bottom, top = floorY(2) - 2.5, ROOF_BASE + 14
	makeCylinder(parent, "Corbel", 6, 2, base * CFrame.new(0, bottom - 6.5, 0), palette.Dark)
	makeCylinder(parent, "Corbel", 10, 2, base * CFrame.new(0, bottom - 4.5, 0), palette.Dark)
	makeCylinder(parent, "Corbel", 14, 2.5, base * CFrame.new(0, bottom - 2.5, 0), palette.Dark)
	makeCylinder(parent, "Turret", 16, top - bottom, base * CFrame.new(0, bottom, 0), palette.Vivid)
	for _, y in { floorY(2) + 12, ROOF_BASE - 2 } do
		makeCylinder(parent, "TurretBand", 16.8, 1.2, base * CFrame.new(0, y, 0), palette.Dark)
	end
	for _, y in { floorY(2) + 20, ROOF_BASE + 6 } do
		local position = (base * CFrame.new(0, y, 0)).Position + outward * 8
		local face = CFrame.lookAt(position, position + outward)
		makeDecor(parent, "WindowFrame", Vector3.new(5.6, 7.6, 0.6), face, palette.Dark)
		local glass = makeDecor(parent, "Window", Vector3.new(4, 6, 0.6), face * CFrame.new(0, 0, -0.2), GLASS_COLOR)
		glass.Reflectance = 0.15
	end
	makeCylinder(parent, "TurretEave", 19.5, 1.4, base * CFrame.new(0, top, 0), palette.Dark)
	-- the cone, tilted a little for that ramshackle look
	local cone = base * CFrame.new(0, top + 1.4, 0) * CFrame.Angles(math.rad(4), 0, math.rad(-5))
	local tiers = { 17, 13, 9, 5 }
	for index, diameter in tiers do
		local color = if index % 2 == 1 then palette.Roof else palette.Roof:Lerp(WHITE, 0.25)
		makeCylinder(parent, "TurretRoof", diameter, 4, cone * CFrame.new(0, (index - 1) * 4, 0), color)
	end
	local tip = cone * CFrame.new(0, #tiers * 4, 0)
	makeBall(parent, "TurretTip", 2.6, tip * CFrame.new(0, 1, 0), GOLD_COLOR)
	makeDecor(parent, "FlagPole", Vector3.new(0.3, 6, 0.3), tip * CFrame.new(0, 4, 0), WHITE)
	makeDecor(parent, "Flag", Vector3.new(0.2, 2.4, 4), tip * CFrame.new(0, 5.6, 2), palette.Vivid)
end

-- A big clock face (`face`: its center, -Z out), showing ten past ten.
local function buildClock(parent: Instance, face: CFrame, palette: Palette)
	local axis = CFrame.Angles(0, math.pi / 2, 0) -- a cylinder's axis along the face's Z
	local ring = makeDecor(parent, "ClockRing", Vector3.new(1.2, 17, 17), face * CFrame.new(0, 0, -0.6) * axis, palette.Dark)
	ring.Shape = Enum.PartType.Cylinder
	local dial = makeDecor(parent, "Clock", Vector3.new(1.4, 15, 15), face * CFrame.new(0, 0, -0.7) * axis, WHITE)
	dial.Shape = Enum.PartType.Cylinder
	local front = face * CFrame.new(0, 0, -1.45)
	for hour = 0, 3 do
		local angle = hour * math.pi / 2
		makeDecor(parent, "ClockTick", Vector3.new(0.8, 2, 0.3), front * CFrame.Angles(0, 0, angle) * CFrame.new(0, 5.6, 0), palette.Dark)
	end
	-- Seen from the front, a hand `angle` clockwise from 12 turns the part's +Y that way.
	for _, hand in { { math.rad(300), 4.5, 0.9 }, { math.rad(60), 6.2, 0.6 } } do
		makeDecor(parent, "ClockHand", Vector3.new(hand[3], hand[2], 0.3), front * CFrame.Angles(0, 0, hand[1]) * CFrame.new(0, hand[2] / 2, -0.1), palette.Dark)
	end
	makeBall(parent, "ClockPin", 1.6, front, palette.Vivid)
end

-- Roofs -----------------------------------------------------------------------------

-- One slope of a gabled roof, from its ridge (`top`: on the roof's surface, at the
-- middle of the ridge) down to its eave (`bottom`), `length` long along the ridge
-- (`along`). Shingle rows run along the ridge. Returns the surface's CFrame (X along
-- the ridge, Y out of the roof, Z down the slope).
local function buildSlope(parent: Instance, top: Vector3, bottom: Vector3, along: Vector3, length: number, texture: string, tint: Color3, color: Color3, palette: Palette): CFrame
	local down = (bottom - top).Unit
	local normal = down:Cross(along)
	if normal.Y < 0 then
		along, normal = -along, -normal
	end
	local width = (bottom - top).Magnitude
	local surface = CFrame.fromMatrix((top + bottom) / 2, along, normal, down)
	local slab = makeDecor(parent, "Roof", Vector3.new(length, ROOF_THICKNESS, width), surface * CFrame.new(0, -ROOF_THICKNESS / 2, 0), color)
	addTexture(slab, Enum.NormalId.Top, texture, 9, tint)
	-- chunky trims: bargeboards up both ends and a fascia along the eave
	for _, side in { -1, 1 } do
		makeDecor(parent, "Bargeboard", Vector3.new(1.4, 2.6, width + 0.6), surface * CFrame.new(side * (length / 2 + 0.2), 0.1, 0), palette.Dark)
	end
	makeDecor(parent, "Fascia", Vector3.new(length + 2.2, 2, 1.4), surface * CFrame.new(0, -0.3, width / 2 + 0.2), palette.Dark)
	return surface
end

-- A triangular gable wall (`base`: its bottom middle, -Z out), `width` across.
local function buildGable(parent: Instance, base: CFrame, width: number, height: number, palette: Palette)
	for _, side in { -1, 1 } do
		-- A wedge is tallest at its +Z: turn each half so that end meets in the middle.
		local wedge = makeWedge(parent, "Gable", Vector3.new(WALL, height, width / 2), base * CFrame.new(side * width / 4, height / 2, 0) * CFrame.Angles(0, -side * math.pi / 2, 0), palette.Siding)
		for _, face in { Enum.NormalId.Left, Enum.NormalId.Right } do
			addTexture(wedge, face, SIDING_TEXTURE, FACADES[2].Tile, palette.Siding)
		end
	end
end

local function ridgeCap(parent: Instance, top: Vector3, along: Vector3, length: number, color: Color3)
	local cap = makeDecor(parent, "RidgeCap", Vector3.new(length + 1.6, 2.6, 2.6), CFrame.fromMatrix(top + Vector3.new(0, 0.3, 0), along, Vector3.yAxis), color)
	cap.Shape = Enum.PartType.Cylinder
end

-- The front room's roof faces the hub with a gable (the clock in it); the back room's
-- runs across it. Plot space.
local function buildRoofs(layer: Instance, cframe: CFrame, palette: Palette)
	local splitZ = FRONT_Z + ROOM_SIZE.Z -- between the front and back rooms
	local wallTop = floorY(STOREYS + 1)
	-- front: the ridge runs front to back
	local frontFrom, frontTo = FRONT_Z - 4, splitZ + 1
	local frontMid = (frontFrom + frontTo) / 2
	local ridge = Vector3.new(0, ROOF_BASE + FRONT_RISE, frontMid)
	local drop = OVERHANG * FRONT_RISE / HALF_X
	for _, side in { -1, 1 } do
		local eave = Vector3.new(side * (HALF_X + OVERHANG), ROOF_BASE - drop, frontMid)
		buildSlope(layer, (cframe * CFrame.new(ridge)).Position, (cframe * CFrame.new(eave)).Position, cframe.ZVector, frontTo - frontFrom, SHINGLE_TEXTURE, palette.Roof, palette.Roof, palette)
	end
	ridgeCap(layer, (cframe * CFrame.new(ridge)).Position, cframe.ZVector, frontTo - frontFrom, palette.Dark)
	buildGable(layer, cframe * CFrame.new(0, wallTop, FRONT_Z + WALL / 2), ROOM_SIZE.X, ROOF_BASE + FRONT_RISE - wallTop, palette)
	buildGable(layer, cframe * CFrame.new(0, wallTop, splitZ) * CFrame.Angles(0, math.pi, 0), ROOM_SIZE.X, ROOF_BASE + FRONT_RISE - wallTop, palette)
	buildClock(layer, cframe * CFrame.new(0, wallTop + 10, FRONT_Z), palette)

	-- back: the ridge runs across, the gables face the sides
	local backRidgeZ = splitZ + ROOM_SIZE.Z / 2
	local backRidge = Vector3.new(0, ROOF_BASE + BACK_RISE, backRidgeZ)
	local backLength = ROOM_SIZE.X + OVERHANG * 2
	local backDrop = (OVERHANG - 1) * BACK_RISE / (ROOM_SIZE.Z / 2)
	local ridgeWorld = (cframe * CFrame.new(backRidge)).Position
	buildSlope(layer, ridgeWorld, (cframe * CFrame.new(0, ROOF_BASE, splitZ)).Position, cframe.XVector, backLength, SHINGLE_TEXTURE, palette.BackRoof, palette.BackRoof, palette)
	buildSlope(layer, ridgeWorld, (cframe * CFrame.new(0, ROOF_BASE - backDrop, BACK_Z + OVERHANG - 1)).Position, cframe.XVector, backLength, SHINGLE_TEXTURE, palette.BackRoof, palette.BackRoof, palette)
	ridgeCap(layer, ridgeWorld, cframe.XVector, backLength, palette.Dark)
	for _, side in { -1, 1 } do
		local gable = cframe * CFrame.new(side * (HALF_X - WALL / 2), wallTop, backRidgeZ) * CFrame.Angles(0, -side * math.pi / 2, 0)
		buildGable(layer, gable, ROOM_SIZE.Z, ROOF_BASE + BACK_RISE - wallTop, palette)
	end

	-- the crooked chimney on the back roof
	buildChimney(layer, cframe * CFrame.new(-38, ROOF_BASE + 4, BACK_Z - 30) * CFrame.Angles(0, 0, math.rad(5)), 36)
end

-- Storeys ---------------------------------------------------------------------------

-- A storey's rooms (front first), its walls in `layers[storey]` and its ceiling in the
-- layer above. Plot space.
local function buildStorey(layers: { Instance }, cframe: CFrame, storey: number, rooms: { Room }, palette: Palette, factory: Factory)
	local layer = layers[storey]
	local above = layers[storey + 1]
	local facade = FACADES[storey]
	local inner = ROOM_SIZE.X - WALL * 2 -- the end walls fit between the side walls
	local base = floorY(storey)

	for index, room in rooms do
		local style = room.Style
		local isFirst, isLast = index == 1, index == #rooms
		local center = cframe * CFrame.new(0, base, room.Z) -- on the floor
		local halfZ = ROOM_SIZE.Z / 2
		local innerFrom = if isFirst then -halfZ + WALL else -halfZ
		local innerTo = if isLast then halfZ - WALL else halfZ
		local innerZ = (innerFrom + innerTo) / 2

		-- the floor, and the ceiling above (it never casts shadows: the rooms stay sunny)
		if storey == 1 then
			makePart(layer, `{room.ZoneId}Floor`, ROOM_SIZE, center * CFrame.new(0, -ROOM_SIZE.Y / 2, 0), style.Floor, style.FloorMaterial)
		else
			local thickness = STOREY - CEILING - CEILING_THICKNESS
			local floor = makePart(layer, `{room.ZoneId}Floor`, Vector3.new(inner, thickness, innerTo - innerFrom), center * CFrame.new(0, -thickness / 2, innerZ), style.Floor, style.FloorMaterial)
			floor.CastShadow = false
		end
		local ceiling = makeDecor(above, `{room.ZoneId}Ceiling`, Vector3.new(inner, CEILING_THICKNESS, innerTo - innerFrom), center * CFrame.new(0, CEILING + CEILING_THICKNESS / 2, innerZ), style.Ceiling)
		ceiling.CastShadow = false

		-- side walls
		for _, side in { -1, 1 } do
			local wallBase = center * CFrame.new(side * (HALF_X - WALL / 2), 0, 0) * CFrame.Angles(0, -side * math.pi / 2, 0)
			local openings, spots = {}, SIDE_WINDOWS
			if storey == 2 and isFirst and side == 1 then
				-- the side door off the outside stairs (this wall's X runs along +Z)
				openings = { { X = SIDE_DOOR_Z, Width = SIDE_DOOR.X, Height = SIDE_DOOR.Y } }
				spots = { -36, 0 }
			end
			buildOuterWall(layer, wallBase, ROOM_SIZE.Z, openings, spots, room, storey, palette, false)
			if #openings > 0 then
				buildDoorFrame(layer, wallBase * CFrame.new(SIDE_DOOR_Z, 0, 0), SIDE_DOOR, palette.Dark)
				local shutter = makeShutter(layer, `{room.ZoneId}Shutter`, SIDE_DOOR, wallBase * CFrame.new(SIDE_DOOR_Z, 0, 0), style.Band)
				local sign = makeSign(layer, `{room.ZoneId}Sign`, Vector3.new(17, 4.6, 1), wallBase * CFrame.new(SIDE_DOOR_Z, SIDE_DOOR.Y + 5, -WALL / 2 - 0.55), style.SignColor, palette.Vivid, palette.Dark, style.Title)
				factory.Doorways[room.ZoneId] = { Label = sign, Title = style.Title, Shutter = shutter }
			end
		end

		if isFirst then
			-- the front wall, facing the hub
			local front = center * CFrame.new(0, 0, -halfZ + WALL / 2)
			local openings = if storey == 1 then { { X = 0, Width = ENTRANCE.X, Height = ENTRANCE.Y } } else {}
			buildOuterWall(layer, front, inner, openings, facade.Windows, room, storey, palette, true)
			local face = front * CFrame.new(0, 0, -WALL / 2)
			if storey == 1 then
				-- the entrance, under an awning and the owner's sign, between two lamps
				buildDoorFrame(layer, front, ENTRANCE, palette.Dark)
				buildAwning(layer, face * CFrame.new(0, ENTRANCE.Y + 1, 0), ENTRANCE.X + 4, palette.Vivid)
				factory.SignLabel = makeSign(layer, "Sign", Vector3.new(40, 6.5, 1), face * CFrame.new(0, CEILING - 3.5, -2.2), SIGN_TEXT_COLOR, palette.Vivid, palette.Dark, "Empty Plot")
				for _, side in { -1, 1 } do
					buildLamp(layer, face * CFrame.new(side * (ENTRANCE.X / 2 + 4), ENTRANCE.Y - 3, 0), palette.Dark)
				end
			else
				-- a round window over the entrance
				local axis = CFrame.Angles(0, math.pi / 2, 0)
				local window = face * CFrame.new(0, BAND_TOP + WINDOW.Y / 2, 0)
				local ring = makeDecor(layer, "WindowFrame", Vector3.new(1, 15, 15), window * CFrame.new(0, 0, -0.5) * axis, palette[facade.Frame])
				ring.Shape = Enum.PartType.Cylinder
				local glass = makeDecor(layer, "Window", Vector3.new(1.2, 12.4, 12.4), window * CFrame.new(0, 0, -0.5) * axis, GLASS_COLOR)
				glass.Shape = Enum.PartType.Cylinder
				glass.Reflectance = 0.15
				makeDecor(layer, "WindowBar", Vector3.new(0.5, 12.4, 0.6), window * CFrame.new(0, 0, -1.2), palette[facade.Frame])
				makeDecor(layer, "WindowBar", Vector3.new(12.4, 0.5, 0.6), window * CFrame.new(0, 0, -1.2), palette[facade.Frame])
			end
		else
			-- The doorway from the room in front, with the room's sign over it and a
			-- shutter that stays down until the zone unlocks. Each half of the wall wears
			-- its own room's color.
			local divider = center * CFrame.new(0, 0, -halfZ)
			local half = WALL / 2
			local previous = rooms[index - 1]
			local openings = { { X = 0, Width = DOORWAY.X, Height = DOORWAY.Y } }
			buildWall(layer, divider * CFrame.new(0, 0, -half / 2), inner, openings, previous.Style.Wall or palette.Pastel, nil, nil, half)
			buildWall(layer, divider * CFrame.new(0, 0, half / 2), inner, openings, style.Wall or palette.Pastel, nil, nil, half)
			buildBand(layer, divider * CFrame.Angles(0, math.pi, 0), inner, openings, half, previous.Style)
			buildBand(layer, divider, inner, openings, half, style)
			buildDoorFrame(layer, divider, DOORWAY, previous.Style.Trim)
			local face = divider * CFrame.new(0, 0, -half)
			local sign = makeSign(layer, `{room.ZoneId}Sign`, Vector3.new(34, 6.5, 1), face * CFrame.new(0, CEILING - 4.5, -0.55), style.SignColor, palette.Vivid, palette.Dark, style.Title)
			local shutter = makeShutter(layer, `{room.ZoneId}Shutter`, DOORWAY, divider, style.Band)
			factory.Doorways[room.ZoneId] = { Label = sign, Title = style.Title, Shutter = shutter }
		end

		if isLast then
			local back = center * CFrame.new(0, 0, halfZ - WALL / 2) * CFrame.Angles(0, math.pi, 0)
			buildOuterWall(layer, back, inner, {}, facade.Windows, room, storey, palette, false)
		end
	end

	-- The trims: a stone plinth (ground floor), round corner pillars, pilasters where
	-- the rooms meet, and a chunky band along the top (the next floor's ledge, or the
	-- cornice under the roofs).
	local depth = BACK_Z - FRONT_Z
	local middleZ = (FRONT_Z + BACK_Z) / 2
	local isTop = storey == STOREYS
	local bandHeight, bandOut = if isTop then 2.5 else 3, if isTop then 2 else 1.4
	local bandTop = if isTop then STOREY - 0.5 else STOREY
	local function ring(name: string, height: number, out: number, y: number, color: Color3, skipEntrance: boolean)
		local at = cframe * CFrame.new(0, base + y, middleZ)
		for _, side in { -1, 1 } do
			makeDecor(layer, name, Vector3.new(out, height, depth + out * 2), at * CFrame.new(side * (HALF_X + out / 2), 0, 0), color)
		end
		makeDecor(layer, name, Vector3.new(ROOM_SIZE.X, height, out), at * CFrame.new(0, 0, depth / 2 + out / 2), color)
		local frontZ = -depth / 2 - out / 2
		if skipEntrance then
			local width = HALF_X - ENTRANCE.X / 2 - 1.4
			for _, side in { -1, 1 } do
				makeDecor(layer, name, Vector3.new(width, height, out), at * CFrame.new(side * (HALF_X - width / 2), 0, frontZ), color)
			end
		else
			makeDecor(layer, name, Vector3.new(ROOM_SIZE.X, height, out), at * CFrame.new(0, 0, frontZ), color)
		end
	end
	ring("TrimBand", bandHeight, bandOut, bandTop - bandHeight / 2, palette.Dark, false)
	ring("TrimStrip", 0.8, bandOut - 0.6, bandTop - bandHeight - 0.4, if isTop then WHITE else palette.Vivid, false)
	if storey == 1 then
		ring("Plinth", 3, 0.8, 1.5 - FLOOR_TOP, palette.Stone, true) -- from the ground up
	end

	local pillarFrom = if storey == 1 then -FLOOR_TOP else 0
	local pillarTo = bandTop - bandHeight
	for _, corner in { { -1, FRONT_Z }, { 1, FRONT_Z }, { -1, BACK_Z }, { 1, BACK_Z } } do
		local turretCorner = storey == 2 and corner[1] == -1 and corner[2] == FRONT_Z
		if not turretCorner then
			local foot = cframe * CFrame.new(corner[1] * HALF_X, base + pillarFrom, corner[2])
			local pillar = makeCylinder(layer, "Pillar", facade.PillarSize, pillarTo - pillarFrom, foot, palette[facade.Pillar])
			pillar.CanCollide = true
			pillar.CanQuery = true
			makeCylinder(layer, "PillarFoot", facade.PillarSize + 1.4, 2, foot, palette.Dark)
		end
	end
	for _, side in { -1, 1 } do
		local pilaster = cframe * CFrame.new(side * (HALF_X + 0.35), base + (pillarFrom + pillarTo) / 2, FRONT_Z + ROOM_SIZE.Z)
		makeDecor(layer, "Pilaster", Vector3.new(0.7, pillarTo - pillarFrom, 3), pilaster, palette[facade.Pillar])
	end
end

-- API ------------------------------------------------------------------------------

-- Builds the factory for a plot at `cframe`: a room for each zone in the layout,
-- open or not. `color` is the plot's own pastel color, which tints the whole outside.
function FactoryBuilder.Build(model: Model, cframe: CFrame, color: Color3): Factory
	local factory: Factory = { SignLabel = (nil :: any) :: TextLabel, Doorways = {} }
	local palette = paletteOf(color)
	local layers: { Instance } = {
		model,
		makeCutaway(model, "UpperFloor", 2, cframe),
		makeCutaway(model, "Roof", 3, cframe),
	}

	local storeys: { { Room } } = {}
	for index, spot in FactoryBuilder.Layout do
		local zoneId = Zones.List[index].Id
		storeys[spot.Storey] = storeys[spot.Storey] or {}
		table.insert(storeys[spot.Storey], { ZoneId = zoneId, Z = spot.Z, Style = ROOM_STYLES[zoneId] or ROOM_STYLES.ToyWorkshop })
	end
	for storey, rooms in storeys do
		table.sort(rooms, function(a, b)
			return a.Z < b.Z
		end)
		buildStorey(layers, cframe, storey, rooms, palette, factory)
	end

	buildRoofs(layers[3], cframe, palette)
	buildTurret(layers[3], cframe * CFrame.new(-HALF_X - 2, 0, FRONT_Z - 2), (cframe:VectorToWorldSpace(Vector3.new(-1, 0, -1))).Unit, palette)
	buildStairs(model, layers[2], cframe, palette)
	for index, z in { FRONT_Z + ROOM_SIZE.Z + 10, BACK_Z - 10 } do
		local pipeColor = if index == 1 then palette.Vivid else Color3.fromRGB(200, 215, 235)
		buildPipe(layers, cframe * CFrame.new(-HALF_X - 3, 0, z) * CFrame.Angles(0, math.pi, 0), floorY(STOREYS + 1) - 4, pipeColor, palette.Dark)
	end

	-- Nothing upstairs casts shadows: the rooms below stay sunny.
	for level = 2, #layers do
		for _, part in layers[level]:GetDescendants() do
			if part:IsA("BasePart") then
				part.CastShadow = false
			end
		end
	end
	return factory
end

-- Shows a room's sign with `lock` under it and closes its shutter, or opens the
-- doorway when `lock` is nil.
function FactoryBuilder.SetLocked(doorway: Doorway, lock: string?)
	doorway.Label.Text = if lock then `{doorway.Title}\n{lock}` else doorway.Title
	local shutter = doorway.Shutter
	shutter.Transparency = if lock then 0 else 1
	shutter.CanCollide = lock ~= nil
	shutter.CanQuery = lock ~= nil
	local gui = shutter:FindFirstChild("Lock")
	if gui and gui:IsA("SurfaceGui") then
		gui.Enabled = lock ~= nil
	end
end

return FactoryBuilder
