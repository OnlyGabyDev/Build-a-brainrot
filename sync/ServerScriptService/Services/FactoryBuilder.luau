--[[
	FactoryBuilder
	Builds each plot's factory building around its lines (GDD §10): a toy-house tower
	that grows a storey at a time (it starts with 2; more are bought, and each new one
	drops in: PrepareDropIn), all in the plot's own color at a different strength per
	storey. The ground floor (Toy Workshop front, Plushie room back) is brick with
	chunky trims and flower boxes; the 2nd floor (Clay Studio, Vinyl Collectibles)
	lighter wood siding with bold shutters, flower boxes and a little balcony; the 3rd
	floor (Candy Factory, over the front half only) a candy shop: white stripes, a
	frosting band with rainbow sprinkles and drips, round windows, candy-cane pillars
	and a giant spinning donut in a ring of chasing marquee bulbs, under a gable with a
	clock and a pinwheel. The back half's roof is a terrace. Bolted on: outside stairs
	up to the 2nd floor and on to the terrace, a turret, a crooked chimney, a water
	tower, pipes and bobbing balloons. The entrance faces the hub under the owner's
	sign; a glass door leads into each other room, locked until its zone unlocks, so
	you can peek at its theme (patterned floors and wallpaper here, RoomDecor's props).
	TycoonManager furnishes the lines. Atmosphere plays the motion.

	Plot space: origin on the ground at the plot's center, -Z (front) faces the hub.

	Cutaway: whatever sits above the ground floor's ceiling lives in Models tagged
	"Cutaway" with a Level: everything from storey N-1's ceiling up to storey N's is
	Level N (the terrace goes with the 3rd floor), and the roof is the level above the
	top storey. They're pivoted at the ground floor's center, on its floor, with Area
	(the building's box), StoreyHeight and CeilingHeight attributes: TycoonFX fades
	those above your storey while you're inside and the camera is up above your
	ceiling.
]]

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Zones = require(ReplicatedStorage.Shared.Config.Zones)

local RoomDecor = require(script.Parent.RoomDecor)

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
	{ Storey = 3, Z = 0 }, -- Candy Factory, on top of the front half
}

-- The building with its stairs and overhangs, in plot space ("in the plot").
FactoryBuilder.Lot = { HalfWidth = 84, Front = -68, Back = 186 }

local ROOM_SIZE = FactoryBuilder.RoomSize
local FLOOR_TOP = FactoryBuilder.FloorTop
local CEILING = FactoryBuilder.CeilingHeight
local STOREY = FactoryBuilder.StoreyHeight
local HALF_X = ROOM_SIZE.X / 2
local FRONT_Z = -ROOM_SIZE.Z / 2 -- the building's front face
local BACK_Z = FRONT_Z + ROOM_SIZE.Z * 2 -- and its back face (the lower storeys')
local WALL = 2 -- thickness
local CEILING_THICKNESS = 0.4
local BAND_TOP = 8 -- the wainscot inside, up to the window sills
local WINDOW = Vector2.new(14, 13) -- its bottom sits on the band
local ROUND_WINDOW = 12 -- the candy floor's, across
local DONUT_SIZE, DONUT_Y = 16, 13.5 -- the candy floor's emblem: across, and its center's height
local SIDE_WINDOWS = { -36, 0, 36 } -- along a room's side walls, from its center
local ENTRANCE = Vector2.new(26, 18)
local DOORWAY = Vector2.new(24, 18) -- into a back room
local SIDE_DOOR = Vector2.new(10, 14) -- upstairs, off the outside stairs
local SIDE_DOOR_Z = 31 -- along the front room
local TERRACE_DOOR = Vector2.new(14, 16) -- from the terrace into the top storey
local LOCKED_GLASS = 0.55 -- a locked door's transparency
local OVERHANG = 5
local FRONT_RISE = 26
local ROOF_THICKNESS = 1.2

local function floorY(storey: number): number
	return FLOOR_TOP + (storey - 1) * STOREY
end
FactoryBuilder.FloorY = floorY

local STOREYS = 0
for _, spot in FactoryBuilder.Layout do
	STOREYS = math.max(STOREYS, spot.Storey)
end
-- The factory starts with BaseStoreys and grows a storey at a time as floors are bought
-- (TycoonManager); Build puts the roof on whichever storey is its top. These two follow
-- the building being built.
FactoryBuilder.BaseStoreys = 2
FactoryBuilder.MaxStoreys = STOREYS
local topStorey = STOREYS
local roofBase = floorY(topStorey + 1) + 0.5 -- where the roof meets the walls
local terraceBehindTop = true -- the top storey's back opens onto a terrace (over a room below it)

-- Creator Store textures (each decal's image id), white so they take a tint.
local BRICK_TEXTURE = "rbxassetid://74130396057975" -- decal 92246549548513
local SIDING_TEXTURE = "rbxassetid://2448219595" -- decal 2448219602
local SHINGLE_TEXTURE = "rbxassetid://9583141656" -- decal 9583141664

local WHITE = Color3.new(1, 1, 1)
local GLASS_COLOR = Color3.fromRGB(165, 225, 255)
local CHIMNEY_COLOR = Color3.fromRGB(235, 150, 125)
local CAP_COLOR = Color3.fromRGB(110, 95, 120)
local WOOD_COLOR = Color3.fromRGB(225, 180, 130)
local WOOD_DARK = Color3.fromRGB(165, 120, 85)
local DECK_COLOR = Color3.fromRGB(240, 215, 180)
local POT_COLOR = Color3.fromRGB(230, 150, 115)
local LEAF_COLORS = { Color3.fromRGB(110, 210, 95), Color3.fromRGB(150, 230, 120), Color3.fromRGB(80, 185, 90) }
local LAMP_COLOR = Color3.fromRGB(255, 230, 150)
local GOLD_COLOR = Color3.fromRGB(255, 210, 90)
local SIGN_TEXT_COLOR = Color3.fromRGB(130, 85, 200)
local FLOWER_COLORS = {
	Color3.fromRGB(255, 130, 185),
	Color3.fromRGB(255, 220, 90),
	Color3.fromRGB(255, 255, 255),
	Color3.fromRGB(185, 145, 255),
}
-- Candy colors, the same on every plot, for the little things: sprinkles, balloons,
-- the pinwheel and the donut, so the building sparkles whatever its own color.
local RAINBOW = {
	Color3.fromRGB(255, 85, 150), -- strawberry
	Color3.fromRGB(255, 205, 45), -- lemon
	Color3.fromRGB(70, 220, 135), -- mint
	Color3.fromRGB(65, 170, 255), -- blueberry
	Color3.fromRGB(170, 105, 255), -- grape
	Color3.fromRGB(255, 135, 55), -- orange
}
local DOUGH_COLOR = Color3.fromRGB(235, 170, 95)

-- A plot's colors, all of its own hue so the building hangs together (the user
-- found mixed hues ugly), each storey a different strength of it so the floors still
-- read apart: Brick and Accent (the ground floor), Siding and Shutter (the 2nd floor,
-- lighter), Candy and CandyDeep (the candy floor, the boldest, under white stripes).
-- Plus Pastel (the plot's own), Dark (trims), Stone (the plinth), Roof and White. The
-- candy colors (RAINBOW) only go on small things.
type Palette = { [string]: Color3 }

-- Each room's inside.
type RoomStyle = {
	Title: string, -- the sign over its door
	SignColor: Color3,
	Floor: Color3,
	FloorMaterial: Enum.Material,
	Wall: Color3?, -- nil: the plot's pastel
	Band: Color3,
	BandMaterial: Enum.Material,
	Trim: Color3, -- door and window frames
	Ceiling: Color3,
	Wallpaper: Color3?, -- stripes down the walls above the band
	Checker: Color3?, -- big floor tiles, every other one this color
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
		Title = "🧵 PLUSHIE SEWING ROOM",
		SignColor = Color3.fromRGB(255, 70, 160),
		-- a plush factory: a glossy plum checker floor (the brainrots pop on it),
		-- hot-pink striped walls over a deep violet band, gold trims
		Floor = Color3.fromRGB(105, 55, 140),
		FloorMaterial = Enum.Material.SmoothPlastic,
		Wall = Color3.fromRGB(240, 95, 170),
		Band = Color3.fromRGB(80, 45, 140),
		BandMaterial = Enum.Material.SmoothPlastic,
		Trim = Color3.fromRGB(255, 195, 60),
		Ceiling = Color3.fromRGB(255, 225, 245),
		Wallpaper = Color3.fromRGB(250, 120, 185),
		Checker = Color3.fromRGB(125, 70, 165),
	},
	ClayStudio = {
		Title = "🎨 CLAY STUDIO",
		SignColor = Color3.fromRGB(225, 110, 60),
		-- a stop-motion film studio: a glossy deep terracotta checker floor (the cream
		-- turntables and the clay brainrots pop on it), warm orange striped walls over a
		-- dark band, teal trims
		Floor = Color3.fromRGB(118, 56, 40),
		FloorMaterial = Enum.Material.SmoothPlastic,
		Wall = Color3.fromRGB(245, 140, 80),
		Band = Color3.fromRGB(92, 44, 34),
		BandMaterial = Enum.Material.SmoothPlastic,
		Trim = Color3.fromRGB(60, 205, 195),
		Ceiling = Color3.fromRGB(255, 222, 192),
		Wallpaper = Color3.fromRGB(252, 168, 108),
		Checker = Color3.fromRGB(142, 70, 48),
	},
	VinylCollectibles = {
		Title = "✨ VINYL COLLECTIBLES",
		SignColor = Color3.fromRGB(90, 120, 255),
		Floor = Color3.fromRGB(85, 95, 215),
		FloorMaterial = Enum.Material.SmoothPlastic,
		Wall = Color3.fromRGB(175, 180, 255),
		Band = Color3.fromRGB(95, 110, 240),
		BandMaterial = Enum.Material.SmoothPlastic,
		Trim = Color3.fromRGB(255, 200, 55),
		Ceiling = Color3.fromRGB(150, 160, 250),
		Wallpaper = Color3.fromRGB(200, 205, 255),
		Checker = Color3.fromRGB(120, 135, 245),
	},
	CandyFactory = {
		Title = "🍭 CANDY FACTORY",
		SignColor = Color3.fromRGB(255, 90, 160),
		Floor = Color3.fromRGB(255, 245, 250),
		FloorMaterial = Enum.Material.SmoothPlastic,
		Wall = Color3.fromRGB(255, 150, 200),
		Band = Color3.fromRGB(95, 220, 185),
		BandMaterial = Enum.Material.SmoothPlastic,
		Trim = Color3.fromRGB(255, 70, 150),
		Ceiling = Color3.fromRGB(255, 225, 240),
		Wallpaper = WHITE,
		Checker = Color3.fromRGB(255, 160, 205),
	},
}

-- Each storey's outside (palette keys for the colors).
type Facade = {
	Texture: string?, -- tinted onto the walls' outer faces (nil: a plain skin)
	Tile: number, -- studs per texture tile
	Wall: string,
	Pop: string, -- the storey's bright accent: shutters, the trim strip, its sign borders
	Frame: string, -- window frames
	Pillar: string, -- the corner pillars
	PillarSize: number,
	CandyPillars: boolean, -- striped like candy canes
	Windows: { number }, -- along the front and back walls, from the middle
	RoundWindows: boolean,
	Shutters: boolean,
	FlowerBoxes: boolean, -- under the front windows
	Stripes: boolean, -- white candy stripes down the walls
	Icing: boolean, -- frosting with sprinkles and drips under the cornice
}

local FACADES: { Facade } = {
	{
		Texture = BRICK_TEXTURE,
		Tile = 12,
		Wall = "Brick",
		Pop = "Accent",
		Frame = "Dark",
		Pillar = "Dark",
		PillarSize = 5,
		CandyPillars = false,
		Windows = { -56, -34, 34, 56 },
		RoundWindows = false,
		Shutters = false,
		FlowerBoxes = true,
		Stripes = false,
		Icing = false,
	},
	{
		Texture = SIDING_TEXTURE,
		Tile = 10,
		Wall = "Siding",
		Pop = "Shutter",
		Frame = "White",
		Pillar = "Shutter",
		PillarSize = 4.4,
		CandyPillars = false,
		Windows = { -52, -26, 26, 52 },
		RoundWindows = false,
		Shutters = true,
		FlowerBoxes = true,
		Stripes = false,
		Icing = false,
	},
	{
		Texture = nil,
		Tile = 10,
		Wall = "Candy",
		Pop = "CandyDeep",
		Frame = "White",
		Pillar = "CandyDeep",
		PillarSize = 4.4,
		CandyPillars = true,
		Windows = { -52, -26, 26, 52 },
		RoundWindows = true,
		Shutters = false,
		FlowerBoxes = false,
		Stripes = true,
		Icing = true,
	},
}

local function vivid(color: Color3): Color3
	local hue, saturation, value = color:ToHSV()
	return Color3.fromHSV(hue, math.max(saturation, 0.6), math.max(value, 0.95))
end
FactoryBuilder.Vivid = vivid

local function paletteOf(color: Color3): Palette
	local hue = color:ToHSV()
	-- Dark yellow turns olive: the yellow plot's trims go a warm brown instead.
	local darkHue = if hue > 0.1 and hue < 0.2 then 0.07 else hue
	local dark = Color3.fromHSV(darkHue, 0.45, 0.52)
	return {
		Pastel = color,
		Brick = Color3.fromHSV(hue, 0.4, 1),
		Accent = Color3.fromHSV(hue, 0.62, 1),
		Siding = Color3.fromHSV(hue, 0.2, 1),
		Shutter = Color3.fromHSV(hue, 0.6, 0.97),
		Candy = Color3.fromHSV(hue, 0.5, 1),
		CandyDeep = Color3.fromHSV(hue, 0.75, 1),
		Dark = dark,
		Stone = dark:Lerp(WHITE, 0.45),
		Roof = Color3.fromHSV(hue, 0.66, 0.93),
		White = WHITE,
	}
end

-- A zone's room, by zone index: the center of its floor, in plot space.
function FactoryBuilder.RoomCFrame(zoneIndex: number): CFrame
	local spot = FactoryBuilder.Layout[zoneIndex]
	return CFrame.new(0, floorY(spot.Storey), spot.Z)
end

export type Doorway = {
	Label: TextLabel, -- the sign over it
	Title: string,
	Shutter: BasePart, -- the locked glass door
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

-- A disc on a wall (`face`: its center on the face, -Z out), `depth` thick, standing
-- out from the face.
local function makeDisc(parent: Instance, name: string, diameter: number, depth: number, face: CFrame, color: Color3): Part
	local part = makeDecor(parent, name, Vector3.new(depth, diameter, diameter), face * CFrame.new(0, 0, -depth / 2) * CFrame.Angles(0, math.pi / 2, 0), color)
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

-- A tinted glass door closing a doorway while its zone is locked (on `base`: the
-- floor at the doorway's middle, -Z toward the side people come from), with a big
-- lock on it. You can see the room through it.
local function makeGlassDoor(parent: Instance, name: string, size: Vector2, base: CFrame, color: Color3): Part
	local door = makePart(parent, name, Vector3.new(size.X, size.Y, 0.6), base * CFrame.new(0, size.Y / 2, 0), color:Lerp(WHITE, 0.35), Enum.Material.Glass)
	door.Transparency = LOCKED_GLASS
	local gui = Instance.new("SurfaceGui")
	gui.Name = "Lock"
	gui.Face = Enum.NormalId.Front
	gui.LightInfluence = 0
	gui.PixelsPerStud = 10
	gui.Parent = door
	-- two glints across the glass, so it reads as glass (they go with the lock)
	for index, glint in { { 0.3, 0.25, 0.09 }, { 0.42, 0.33, 0.04 } } do
		local frame = Instance.new("Frame")
		frame.Name = `Glint{index}`
		frame.AnchorPoint = Vector2.new(0.5, 0.5)
		frame.Position = UDim2.fromScale(glint[1], glint[2])
		frame.Size = UDim2.fromScale(glint[3], 0.5)
		frame.Rotation = 35
		frame.BackgroundColor3 = WHITE
		frame.BackgroundTransparency = 0.45
		frame.BorderSizePixel = 0
		frame.Parent = gui
	end
	local lock = Instance.new("TextLabel")
	lock.Size = UDim2.fromScale(1, 0.28)
	lock.Position = UDim2.fromScale(0, 0.62) -- low, out of the way of the view inside
	lock.BackgroundTransparency = 1
	lock.TextScaled = true
	lock.Font = Enum.Font.FredokaOne
	lock.Text = "🔒"
	lock.Parent = gui
	return door
end

-- Motion, played on the client (Atmosphere): a Model tagged "Spinner" turns about its
-- pivot's Z axis at its Speed (radians per second), one tagged "Bobbing" bobs up and
-- down, and Neon bulbs tagged "Marquee" chase colored light along their Index.

-- Makes `model` (its parts already in) a spinner about `pivot`, into `parent`.
local function spin(model: Model, parent: Instance, pivot: CFrame, speed: number)
	model.WorldPivot = pivot
	model:SetAttribute("Speed", speed)
	CollectionService:AddTag(model, "Spinner")
	model.Parent = parent
end

local function makeBulb(parent: Instance, at: CFrame, index: number): Part
	local bulb = makeBall(parent, "Bulb", 1.8, at, LAMP_COLOR)
	bulb.Material = Enum.Material.Neon
	bulb.CastShadow = false
	bulb:SetAttribute("Index", index)
	CollectionService:AddTag(bulb, "Marquee")
	return bulb
end

-- A bunch of balloons on strings, tied at `at`, bobbing. `seed` picks their colors.
local function buildBalloons(parent: Instance, at: CFrame, count: number, seed: number)
	local bunch = Instance.new("Model")
	bunch.Name = "Balloons"
	for index = 1, count do
		local angle = index * 2.4 + seed
		local top = at * CFrame.new(math.cos(angle) * 2.4, 9 + (index % 3) * 1.6, math.sin(angle) * 2.4)
		local color = RAINBOW[(index + seed) % #RAINBOW + 1]
		local balloon = makeBall(bunch, "Balloon", 3.8, top, color)
		balloon.Reflectance = 0.1
		makeBall(bunch, "BalloonKnot", 0.7, top * CFrame.new(0, -2, 0), color)
		local from, to = at.Position, (top * CFrame.new(0, -2.2, 0)).Position
		makeDecor(bunch, "BalloonString", Vector3.new(0.12, 0.12, (to - from).Magnitude), CFrame.lookAt((from + to) / 2, to), WHITE)
	end
	bunch.WorldPivot = at
	CollectionService:AddTag(bunch, "Bobbing")
	bunch.Parent = parent
end

-- A Model for the cutaway (see the header), parented to the plot's model.
local function makeCutaway(model: Model, name: string, level: number, cframe: CFrame): Model
	local cutaway = Instance.new("Model")
	cutaway.Name = name
	cutaway.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	cutaway.WorldPivot = cframe * CFrame.new(0, FLOOR_TOP, (FRONT_Z + BACK_Z) / 2)
	cutaway:SetAttribute("Level", level)
	cutaway:SetAttribute("Area", Vector3.new(ROOM_SIZE.X, topStorey * STOREY, BACK_Z - FRONT_Z))
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

type Skin = { Texture: string?, Tile: number, Color: Color3 }

-- A wall along the X axis of `base` (on the floor at the wall's middle; -Z is the
-- outside), `length` long and a storey tall, with door `openings` (sorted by X) cut
-- into it. Its color is the room's inside; `skin` covers its outer face: a texture
-- lined up across the slabs so the pattern runs on, or a thin colored skin. A
-- `thickness` builds half of a two-faced wall.
local function buildWall(parent: Instance, base: CFrame, length: number, openings: { Opening }, color: Color3, skin: Skin?, thickness: number?)
	local depth = thickness or WALL
	local function slab(x0: number, x1: number, y0: number, y1: number)
		if x1 - x0 < 0.01 or y1 - y0 < 0.01 then
			return
		end
		local center = base * CFrame.new((x0 + x1) / 2, (y0 + y1) / 2, 0)
		local part = makePart(parent, "Wall", Vector3.new(x1 - x0, y1 - y0, depth), center, color)
		if skin and skin.Texture then
			-- Seen from outside, U runs toward the base's -X and V down from the top.
			addTexture(part, Enum.NormalId.Front, skin.Texture, skin.Tile, skin.Color, x1 % skin.Tile, y1 % skin.Tile)
		elseif skin then
			makeDecor(parent, "WallSkin", Vector3.new(x1 - x0, y1 - y0, 0.2), center * CFrame.new(0, 0, -depth / 2 - 0.1), skin.Color)
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

-- Wallpaper stripes down a wall's inner face, from the band up to the ceiling (same
-- frame as buildBand), around its doors.
local function buildWallpaper(parent: Instance, base: CFrame, length: number, openings: { Opening }, offset: number, color: Color3)
	local width, period = 3, 8
	local height = CEILING - BAND_TOP
	local x = -length / 2 + period / 2
	while x + width / 2 <= length / 2 - 0.5 do
		local blocked = false
		for _, opening in openings do
			if math.abs(x - opening.X) < opening.Width / 2 + width / 2 + 1.5 then
				blocked = true
			end
		end
		if not blocked then
			makeDecor(parent, "Wallpaper", Vector3.new(width, height, 0.1), base * CFrame.new(x, BAND_TOP + height / 2, offset + 0.05), color)
		end
		x += period
	end
end

-- Big floor tiles over a room's floor (`center`: on the floor), every other one.
local function buildChecker(parent: Instance, center: CFrame, color: Color3, material: Enum.Material)
	local tile = 20
	for column = 0, ROOM_SIZE.X / tile - 1 do
		for row = 0, ROOM_SIZE.Z / tile - 1 do
			if (column + row) % 2 == 0 then
				local x = -ROOM_SIZE.X / 2 + (column + 0.5) * tile
				local z = -ROOM_SIZE.Z / 2 + (row + 0.5) * tile
				makeDecor(parent, "FloorTile", Vector3.new(tile, 0.05, tile), center * CFrame.new(x, 0.025, z), color, material)
			end
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
		makeDecor(parent, "FlowerLeaves", Vector3.new(size.X + 1, 0.8, 1.8), face * CFrame.new(0, y + 1.5, -1.2), LEAF_COLORS[1])
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
			for row = -1, 1 do
				makeDecor(parent, "ShutterSlat", Vector3.new(width - 1, 0.5, 0.3), face * CFrame.new(x, row * size.Y / 3.2, -0.6), shutters:Lerp(Color3.new(0, 0, 0), 0.12))
			end
		end
	end
end

-- A round candy window (`face`: its center on the face, -Z out): glass in a white
-- ring in a colored ring, like a candy button.
local function buildRoundWindow(parent: Instance, face: CFrame, diameter: number, ring: Color3)
	makeDisc(parent, "WindowRing", diameter + 3.2, 0.5, face, ring)
	makeDisc(parent, "WindowFrame", diameter + 1.6, 0.8, face, WHITE)
	local glass = makeDisc(parent, "Window", diameter, 1, face, GLASS_COLOR)
	glass.Reflectance = 0.15
	makeDecor(parent, "WindowBar", Vector3.new(0.5, diameter, 0.4), face * CFrame.new(0, 0, -1.1), WHITE)
	makeDecor(parent, "WindowBar", Vector3.new(diameter, 0.5, 0.4), face * CFrame.new(0, 0, -1.1), WHITE)
	local glint = makeDecor(parent, "Glint", Vector3.new(0.5, diameter / 4, 0.1), face * CFrame.new(-diameter / 4.5, diameter / 4.5, -1.05) * CFrame.Angles(0, 0, math.rad(-45)), WHITE)
	glint.Transparency = 0.2
end

-- The same windows seen from inside: a framed light-blue pane (standing proud of the
-- band, so they don't flicker where they meet).
local function buildInnerWindow(parent: Instance, face: CFrame, round: boolean, frame: Color3)
	if round then
		makeDisc(parent, "WindowFrame", ROUND_WINDOW + 2.4, 0.4, face, frame)
		makeDisc(parent, "Window", ROUND_WINDOW, 0.5, face, GLASS_COLOR)
	else
		makeDecor(parent, "WindowFrame", Vector3.new(WINDOW.X + 2.4, WINDOW.Y + 2.4, 0.4), face * CFrame.new(0, 0, -0.2), frame)
		makeDecor(parent, "Window", Vector3.new(WINDOW.X, WINDOW.Y, 0.3), face * CFrame.new(0, 0, -0.35), GLASS_COLOR)
	end
end

-- Candy stripes down a wall's outer face, around its doors.
local function buildStripes(parent: Instance, base: CFrame, length: number, openings: { Opening }, color: Color3)
	local width, period, height = 3.6, 9, STOREY - 3
	local x = -length / 2 + period / 2
	while x + width / 2 <= length / 2 - 1 do
		local blocked = false
		for _, opening in openings do
			if math.abs(x - opening.X) < opening.Width / 2 + width / 2 + 1.6 then
				blocked = true
			end
		end
		if not blocked then
			makeDecor(parent, "Stripe", Vector3.new(width, height, 0.15), base * CFrame.new(x, height / 2, -WALL / 2 - 0.275), color)
		end
		x += period
	end
end

-- A wall of the building's outside, with its windows on both faces (and the band
-- inside). `spots` are the windows along the wall; the facade's flower boxes go on
-- the front only.
local function buildOuterWall(layer: Instance, base: CFrame, length: number, openings: { Opening }, spots: { number }, room: Room, storey: number, palette: Palette, isFront: boolean)
	local facade = FACADES[storey]
	local style = room.Style
	buildWall(layer, base, length, openings, style.Wall or palette.Pastel, { Texture = facade.Texture, Tile = facade.Tile, Color = palette[facade.Wall] })
	buildBand(layer, base, length, openings, WALL / 2, style)
	if style.Wallpaper then
		buildWallpaper(layer, base, length, openings, WALL / 2, style.Wallpaper)
	end
	if facade.Stripes then
		buildStripes(layer, base, length, openings, WHITE)
	end
	local y = BAND_TOP + WINDOW.Y / 2
	for _, x in spots do
		local outer = base * CFrame.new(x, y, -WALL / 2)
		if facade.RoundWindows then
			buildRoundWindow(layer, outer, ROUND_WINDOW, palette[facade.Pop])
		else
			buildWindow(layer, outer, WINDOW, palette[facade.Frame], if facade.Shutters then palette[facade.Pop] else nil, facade.FlowerBoxes and isFront)
		end
		buildInnerWindow(layer, base * CFrame.new(x, y, WALL / 2) * CFrame.Angles(0, math.pi, 0), facade.RoundWindows, room.Style.Trim)
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

-- A round bush with a flower on top (`at`: on the ground).
local function buildBush(parent: Instance, at: CFrame, size: number, flower: Color3)
	makeBall(parent, "Bush", size, at * CFrame.new(0, size * 0.4, 0), LEAF_COLORS[1])
	makeBall(parent, "Bush", size * 0.75, at * CFrame.new(size * 0.45, size * 0.3, 0.3), LEAF_COLORS[2])
	makeBall(parent, "Bush", size * 0.7, at * CFrame.new(-size * 0.45, size * 0.28, 0.2), LEAF_COLORS[3])
	makeBall(parent, "BushFlower", 1.3, at * CFrame.new(0.6, size * 0.84, -size * 0.2), flower)
end

-- A flower pot (`at`: its bottom center).
local function buildPot(parent: Instance, at: CFrame, size: number, flower: Color3)
	makeCylinder(parent, "Pot", size, size * 0.85, at, POT_COLOR)
	makeCylinder(parent, "PotRim", size * 1.15, size * 0.25, at * CFrame.new(0, size * 0.75, 0), POT_COLOR:Lerp(WHITE, 0.2))
	makeBall(parent, "Plant", size * 1.1, at * CFrame.new(0, size * 1.35, 0), LEAF_COLORS[1])
	makeBall(parent, "PlantFlower", size * 0.4, at * CFrame.new(size * 0.2, size * 1.9, -size * 0.2), flower)
end

-- Pastel smoke puffing out of `parent`'s top.
local function addSmoke(parent: BasePart, height: number)
	local attachment = Instance.new("Attachment")
	attachment.Position = Vector3.new(0, height, 0)
	attachment.Parent = parent
	local smoke = Instance.new("ParticleEmitter")
	smoke.Texture = "rbxasset://textures/particles/smoke_main.dds"
	smoke.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 150, 210)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(160, 200, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 235, 150)),
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

-- A crooked brick chimney (`base`: its foot), puffing smoke.
local function buildChimney(parent: Instance, base: CFrame, height: number)
	makeDecor(parent, "ChimneyFoot", Vector3.new(9, 2, 9), base * CFrame.new(0, 1, 0), CAP_COLOR)
	makeDecor(parent, "Chimney", Vector3.new(7, height, 7), base * CFrame.new(0, height / 2, 0), CHIMNEY_COLOR, Enum.Material.Brick)
	makeDecor(parent, "ChimneyBand", Vector3.new(7.8, 1.2, 7.8), base * CFrame.new(0, height - 4, 0), CAP_COLOR)
	local cap = makeDecor(parent, "ChimneyCap", Vector3.new(8.6, 1.4, 8.6), base * CFrame.new(0, height + 0.7, 0), CAP_COLOR)
	addSmoke(cap, 1)
end

-- One flight of the outside stairs, rising toward +Z from (zFrom, yFrom) to a landing
-- at `yTo` (1-stud risers, 2-stud treads), with stringers and a railing outside. Plot
-- space; returns where its top step ends.
local STAIR_X = HALF_X + 1.6 -- clear of the plinth and the trim bands
local STAIR_WIDTH = 8
local function buildFlight(parent: Instance, cframe: CFrame, zFrom: number, yFrom: number, yTo: number): number
	local x = STAIR_X + STAIR_WIDTH / 2
	local steps = math.floor(yTo - yFrom) - 1 -- the landing is the last step
	local run = 2
	for index = 1, steps do
		makePart(parent, "Step", Vector3.new(STAIR_WIDTH, 1, run), cframe * CFrame.new(x, yFrom + index - 0.5, zFrom + (index - 0.5) * run), WOOD_COLOR, Enum.Material.WoodPlanks)
	end
	local zTo = zFrom + steps * run
	local rise = yTo - yFrom
	local length = math.sqrt((steps * run) ^ 2 + rise ^ 2)
	local angle = math.atan2(rise, steps * run)
	local middle = cframe * CFrame.new(0, yFrom + rise / 2 - 1, (zFrom + zTo) / 2)
	for _, sx in { STAIR_X + 0.4, STAIR_X + STAIR_WIDTH - 0.4 } do
		makeDecor(parent, "Stringer", Vector3.new(0.8, 2.4, length), middle * CFrame.new(sx, 0, 0) * CFrame.Angles(-angle, 0, 0), WOOD_DARK)
	end
	local railX = STAIR_X + STAIR_WIDTH - 0.4
	for index = 1, steps, 5 do
		makeDecor(parent, "RailPost", Vector3.new(0.6, 3.6, 0.6), cframe * CFrame.new(railX, yFrom + index + 1.8, zFrom + (index - 0.5) * run), WHITE)
	end
	makeDecor(parent, "Rail", Vector3.new(0.7, 0.5, length), middle * CFrame.new(railX, 4.6, 0) * CFrame.Angles(-angle, 0, 0), WHITE)
	return zTo
end

-- A landing at `y` from `zFrom` to `zTo`, flush with the floor there (and the trim band
-- under it), on posts, railed on the outside (and at the back, when `closedBack`).
local LANDING_X0 = HALF_X + 1.4
local LANDING_WIDTH = STAIR_X + STAIR_WIDTH - LANDING_X0 + 0.4
local LANDING_OUTER = LANDING_X0 + LANDING_WIDTH - 0.6
local function buildLanding(parent: Instance, cframe: CFrame, zFrom: number, zTo: number, y: number, closedBack: boolean)
	local x = LANDING_X0 + LANDING_WIDTH / 2
	local z = (zFrom + zTo) / 2
	makePart(parent, "Landing", Vector3.new(LANDING_WIDTH, 1.2, zTo - zFrom), cframe * CFrame.new(x, y - 0.6, z), WOOD_COLOR, Enum.Material.WoodPlanks)
	for _, postZ in { zFrom + 0.6, zTo - 0.6 } do
		makePart(parent, "LandingPost", Vector3.new(1.2, y - 1.2, 1.2), cframe * CFrame.new(LANDING_OUTER, (y - 1.2) / 2, postZ), WOOD_DARK, Enum.Material.Wood)
		makeDecor(parent, "RailPost", Vector3.new(0.6, 3.6, 0.6), cframe * CFrame.new(LANDING_OUTER, y + 1.8, postZ), WHITE)
	end
	makeDecor(parent, "Rail", Vector3.new(0.7, 0.5, zTo - zFrom), cframe * CFrame.new(LANDING_OUTER, y + 3.6, z), WHITE)
	-- invisible walls keep people on it
	local guard = makePart(parent, "Guard", Vector3.new(0.4, 6, zTo - zFrom), cframe * CFrame.new(LANDING_OUTER + 0.5, y + 3, z), WHITE)
	guard.Transparency = 1
	if closedBack then
		makeDecor(parent, "Rail", Vector3.new(LANDING_WIDTH, 0.5, 0.7), cframe * CFrame.new(x, y + 3.6, zTo - 0.6), WHITE)
		local back = makePart(parent, "Guard", Vector3.new(LANDING_WIDTH, 6, 0.4), cframe * CFrame.new(x, y + 3, zTo), WHITE)
		back.Transparency = 1
	end
end

-- The outside stairs up the +X wall: a flight to the 2nd floor's side door (under a
-- crooked little porch roof, in `upper`: it goes with the 2nd floor in the cutaway),
-- then, `toTerrace`, another on to the terrace over the back half (the 2nd floor's
-- landing is the top one without it). Plot space. Returns where the top landing is
-- along Z.
local function buildStairs(parent: Instance, upper: Instance, cframe: CFrame, palette: Palette, toTerrace: boolean): (number, number)
	local doorFrom, doorTo = SIDE_DOOR_Z - 9, SIDE_DOOR_Z + 9
	local top2, top3 = floorY(2), floorY(3)
	local steps = math.floor(top2) - 1
	buildFlight(parent, cframe, doorFrom - steps * 2, 0, top2)
	buildLanding(parent, cframe, doorFrom, doorTo, top2, not toTerrace)
	local terraceFrom, terraceTo = doorFrom, doorTo
	if toTerrace then
		terraceFrom = buildFlight(parent, cframe, doorTo, top2, top3)
		terraceTo = terraceFrom + 18
		buildLanding(parent, cframe, terraceFrom, terraceTo, top3, true)
	end

	-- the crooked porch roof over the door, on two posts
	local roofLow, roofHigh = top2 + 21, top2 + 23.5
	for _, z in { doorFrom + 0.8, doorTo - 0.8 } do
		makeDecor(upper, "PorchPost", Vector3.new(0.8, roofLow - top2, 0.8), cframe * CFrame.new(LANDING_OUTER - 0.2, top2 + (roofLow - top2) / 2, z), WHITE)
	end
	local roofWidth = LANDING_OUTER + 2 - HALF_X
	local tilt = math.atan2(roofHigh - roofLow, roofWidth)
	local porch = cframe * CFrame.new(HALF_X + roofWidth / 2, (roofLow + roofHigh) / 2 + 0.4, SIDE_DOOR_Z) * CFrame.Angles(math.rad(3), 0, -tilt)
	local slab = makeDecor(upper, "PorchRoof", Vector3.new(roofWidth + 1, 0.8, doorTo - doorFrom + 5), porch, palette.Roof)
	addTexture(slab, Enum.NormalId.Top, SHINGLE_TEXTURE, 8, palette.Roof)
	makeDecor(upper, "PorchFascia", Vector3.new(1, 1.4, doorTo - doorFrom + 5.4), porch * CFrame.new(roofWidth / 2 + 0.5, -0.2, 0), palette.Dark)
	return terraceFrom, terraceTo
end

-- A pipe running up a wall (`base`: on the ground, -X toward the wall) to `top`, a
-- storey per segment, each in that storey's layer; it bends into the wall at the top.
local function buildPipe(layers: { Instance }, base: CFrame, top: number, color: Color3, bracket: Color3)
	local gap = 3 -- from the pipe's center to the wall
	local storey = 1
	while floorY(storey) - 1 < top do
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
		storey += 1
	end
	local layer = layers[storey - 1]
	makeBall(layer, "PipeElbow", 2.4, base * CFrame.new(0, top, 0), color)
	local arm = makeDecor(layer, "Pipe", Vector3.new(gap, 2.4, 2.4), base * CFrame.new(-gap / 2, top, 0), color)
	arm.Shape = Enum.PartType.Cylinder
end

-- A round turret on a corner (`base`: on the ground at its center), on a corbel,
-- with a window per storey and a crooked stepped cone roof with a flag.
local function buildTurret(parent: Instance, base: CFrame, outward: Vector3, palette: Palette)
	local bottom, top = floorY(2) - 2.5, roofBase + 14
	makeCylinder(parent, "Corbel", 6, 2, base * CFrame.new(0, bottom - 6.5, 0), palette.Dark)
	makeCylinder(parent, "Corbel", 10, 2, base * CFrame.new(0, bottom - 4.5, 0), palette.Dark)
	makeCylinder(parent, "Corbel", 14, 2.5, base * CFrame.new(0, bottom - 2.5, 0), palette.Dark)
	makeCylinder(parent, "Turret", 16, top - bottom, base * CFrame.new(0, bottom, 0), palette.Accent)
	local windows = { roofBase + 6 }
	for storey = 2, topStorey do
		makeCylinder(parent, "TurretBand", 16.8, 1.2, base * CFrame.new(0, floorY(storey + 1) - 2, 0), palette.Dark)
		table.insert(windows, floorY(storey) + 15)
	end
	for _, y in windows do
		local position = (base * CFrame.new(0, y, 0)).Position + outward * 8
		local face = CFrame.lookAt(position, position + outward)
		makeDecor(parent, "WindowFrame", Vector3.new(5.6, 7.6, 0.6), face, WHITE)
		local glass = makeDecor(parent, "Window", Vector3.new(4, 6, 0.6), face * CFrame.new(0, 0, -0.2), GLASS_COLOR)
		glass.Reflectance = 0.15
	end
	makeCylinder(parent, "TurretEave", 19.5, 1.4, base * CFrame.new(0, top, 0), palette.Dark)
	-- the cone, tilted a little for that ramshackle look
	local cone = base * CFrame.new(0, top + 1.4, 0) * CFrame.Angles(math.rad(4), 0, math.rad(-5))
	local tiers = { 17, 13, 9, 5 }
	for index, diameter in tiers do
		local color = if index % 2 == 1 then palette.Roof else palette.Roof:Lerp(WHITE, 0.3)
		makeCylinder(parent, "TurretRoof", diameter, 4, cone * CFrame.new(0, (index - 1) * 4, 0), color)
	end
	local tip = cone * CFrame.new(0, #tiers * 4, 0)
	makeBall(parent, "TurretTip", 2.6, tip * CFrame.new(0, 1, 0), GOLD_COLOR)
	makeDecor(parent, "FlagPole", Vector3.new(0.3, 6, 0.3), tip * CFrame.new(0, 4, 0), WHITE)
	makeDecor(parent, "Flag", Vector3.new(0.2, 2.4, 4), tip * CFrame.new(0, 5.6, 2), palette.Accent)
end

-- A big clock face (`face`: its center, -Z out), showing ten past ten.
local function buildClock(parent: Instance, face: CFrame, palette: Palette)
	makeDisc(parent, "ClockRing", 17, 1.2, face, palette.Dark)
	makeDisc(parent, "Clock", 15, 1.4, face, WHITE)
	local front = face * CFrame.new(0, 0, -1.45)
	for hour = 0, 3 do
		local angle = hour * math.pi / 2
		makeDecor(parent, "ClockTick", Vector3.new(0.8, 2, 0.3), front * CFrame.Angles(0, 0, angle) * CFrame.new(0, 5.6, 0), palette.Dark)
	end
	-- Seen from the front, a hand `angle` clockwise from 12 turns the part's +Y that way.
	for _, hand in { { math.rad(300), 4.5, 0.9 }, { math.rad(60), 6.2, 0.6 } } do
		makeDecor(parent, "ClockHand", Vector3.new(hand[3], hand[2], 0.3), front * CFrame.Angles(0, 0, hand[1]) * CFrame.new(0, hand[2] / 2, -0.1), palette.Dark)
	end
	makeBall(parent, "ClockPin", 1.6, front, palette.Accent)
end

-- Frosting drips under the candy storey's cornice, along a face (`face`: at the
-- frosting band's bottom, at the face's middle, -Z out), with rainbow sprinkles on the
-- band (`height` tall, standing `out` from the wall), leaving `gap` clear around the
-- middle (over a door's sign, or the donut).
local function buildIcing(parent: Instance, face: CFrame, length: number, height: number, out: number, gap: number)
	local index = 0
	local x = -length / 2 + 5
	while x <= length / 2 - 5 do
		if math.abs(x) >= gap then
			local drip = 1.6 + ((index * 5) % 4) * 0.9
			makeCylinder(parent, "Icing", 1.6, drip, face * CFrame.new(x, -drip, -0.8), WHITE)
			makeBall(parent, "IcingDrop", 2, face * CFrame.new(x, -drip, -0.8), WHITE)
		end
		for side = 0, 1 do
			local sx = x + 2.5 + side * 3.5
			if math.abs(sx) >= gap and sx <= length / 2 - 2 then
				local tilt = math.rad(((index * 7 + side * 3) % 6) * 30)
				local color = RAINBOW[(index * 2 + side) % #RAINBOW + 1]
				makeDecor(parent, "Sprinkle", Vector3.new(0.45, 1.3, 0.3), face * CFrame.new(sx, height * (0.35 + side * 0.3), -out - 0.1) * CFrame.Angles(0, 0, tilt), color)
			end
		end
		index += 1
		x += 9
	end
end

-- A giant donut on a wall (`face`: its center on the face, -Z out), turning slowly in
-- a ring of marquee bulbs.
local function buildDonut(parent: Instance, face: CFrame, diameter: number, frosting: Color3)
	local donut = Instance.new("Model")
	donut.Name = "Donut"
	local back = face * CFrame.new(0, 0, -0.5) -- off the wall, so it turns clear of it
	makeDisc(donut, "Dough", diameter, 1.6, back, DOUGH_COLOR)
	makeDisc(donut, "Frosting", diameter * 0.86, 2, back, frosting)
	makeDisc(donut, "DonutHole", diameter * 0.3, 2.1, back, DOUGH_COLOR:Lerp(Color3.new(0, 0, 0), 0.35))
	for index = 1, 15 do
		local angle = index * math.pi * 2 / 15
		local radius = diameter * (0.22 + (index % 3) * 0.07)
		local at = back * CFrame.new(math.cos(angle) * radius, math.sin(angle) * radius, -2.05) * CFrame.Angles(0, 0, angle * 3)
		makeDecor(donut, "Sprinkle", Vector3.new(0.6, 1.8, 0.4), at, RAINBOW[index % #RAINBOW + 1])
	end
	spin(donut, parent, back, 0.4)
	local count, radius = 16, diameter / 2 + 2
	for index = 1, count do
		local angle = index * math.pi * 2 / count
		makeBulb(parent, face * CFrame.new(math.cos(angle) * radius, math.sin(angle) * radius, -0.9), index)
	end
end

-- A pinwheel on a stick (`base`: the stick's foot, -Z the way it faces), spinning.
local function buildPinwheel(parent: Instance, base: CFrame, height: number, size: number)
	makeCylinder(parent, "PinwheelStick", 0.9, height, base, WHITE)
	local hub = base * CFrame.new(0, height, -0.9)
	local wheel = Instance.new("Model")
	wheel.Name = "Pinwheel"
	for index = 0, 3 do
		-- a wedge turned to lie flat in the wheel: a triangle from the hub out
		local blade = hub * CFrame.Angles(0, 0, index * math.pi / 2) * CFrame.new(size / 4, size / 4, 0) * CFrame.Angles(0, math.pi / 2, 0)
		makeWedge(wheel, "PinwheelBlade", Vector3.new(0.4, size / 2, size / 2), blade, RAINBOW[index + 1])
	end
	makeBall(wheel, "PinwheelPin", 1.8, hub * CFrame.new(0, 0, -0.4), GOLD_COLOR)
	spin(wheel, parent, hub, 1.5)
end

-- Roof and terrace ---------------------------------------------------------------------

-- One slope of a gabled roof, from its ridge (`top`: on the roof's surface, at the
-- middle of the ridge) down to its eave (`bottom`), `length` long along the ridge
-- (`along`). Shingle rows run along the ridge. Returns the surface's CFrame (X along
-- the ridge, Y out of the roof, Z down the slope).
local function buildSlope(parent: Instance, top: Vector3, bottom: Vector3, along: Vector3, length: number, palette: Palette): CFrame
	local down = (bottom - top).Unit
	local normal = down:Cross(along)
	if normal.Y < 0 then
		along, normal = -along, -normal
	end
	local width = (bottom - top).Magnitude
	local surface = CFrame.fromMatrix((top + bottom) / 2, along, normal, down)
	local slab = makeDecor(parent, "Roof", Vector3.new(length, ROOF_THICKNESS, width), surface * CFrame.new(0, -ROOF_THICKNESS / 2, 0), palette.Roof)
	addTexture(slab, Enum.NormalId.Top, SHINGLE_TEXTURE, 9, palette.Roof)
	-- chunky trims: bargeboards up both ends and a fascia along the eave
	for _, side in { -1, 1 } do
		makeDecor(parent, "Bargeboard", Vector3.new(1.4, 2.6, width + 0.6), surface * CFrame.new(side * (length / 2 + 0.2), 0.1, 0), palette.Dark)
	end
	makeDecor(parent, "Fascia", Vector3.new(length + 2.2, 2, 1.4), surface * CFrame.new(0, -0.3, width / 2 + 0.2), palette.Dark)
	return surface
end

-- A triangular gable wall (`base`: its bottom middle, -Z out), `width` across.
local function buildGable(parent: Instance, base: CFrame, width: number, height: number, color: Color3)
	for _, side in { -1, 1 } do
		-- A wedge is tallest at its +Z: turn each half so that end meets in the middle.
		local wedge = makeWedge(parent, "Gable", Vector3.new(WALL, height, width / 2), base * CFrame.new(side * width / 4, height / 2, 0) * CFrame.Angles(0, -side * math.pi / 2, 0), color)
		for _, face in { Enum.NormalId.Left, Enum.NormalId.Right } do
			addTexture(wedge, face, SIDING_TEXTURE, FACADES[2].Tile, color)
		end
	end
end

-- The roof over the top storey (from `fromZ` to `toZ`): a gable facing the hub with
-- the clock in it, the ridge running front to back. Plot space.
local function buildRoof(layer: Instance, cframe: CFrame, fromZ: number, toZ: number, palette: Palette)
	local wallTop = floorY(topStorey + 1)
	local frontFrom, frontTo = fromZ - 4, toZ + 1
	local middle = (frontFrom + frontTo) / 2
	local ridge = (cframe * CFrame.new(0, roofBase + FRONT_RISE, middle)).Position
	local drop = OVERHANG * FRONT_RISE / HALF_X
	for _, side in { -1, 1 } do
		local eave = (cframe * CFrame.new(side * (HALF_X + OVERHANG), roofBase - drop, middle)).Position
		buildSlope(layer, ridge, eave, cframe.ZVector, frontTo - frontFrom, palette)
	end
	local cap = makeDecor(layer, "RidgeCap", Vector3.new(frontTo - frontFrom + 1.6, 2.6, 2.6), CFrame.fromMatrix(ridge + Vector3.new(0, 0.3, 0), cframe.ZVector, Vector3.yAxis), palette.Dark)
	cap.Shape = Enum.PartType.Cylinder
	local height = roofBase + FRONT_RISE - wallTop
	buildGable(layer, cframe * CFrame.new(0, wallTop, fromZ + WALL / 2), ROOM_SIZE.X, height, palette.Siding)
	buildGable(layer, cframe * CFrame.new(0, wallTop, toZ - WALL / 2) * CFrame.Angles(0, math.pi, 0), ROOM_SIZE.X, height, palette.Siding)
	buildClock(layer, cframe * CFrame.new(0, wallTop + 10, fromZ), palette)
	-- a pinwheel on the gable's peak, facing the hub
	buildPinwheel(layer, cframe * CFrame.new(0, roofBase + FRONT_RISE + 1, frontFrom + 1.5), 7, 13)
end

-- A giant lollipop (`at`: the foot of its stick, -Z the way it faces), its white
-- swirl spinning.
local function buildLollipop(parent: Instance, at: CFrame, height: number, size: number, color: Color3)
	makeCylinder(parent, "LollipopStick", 1.2, height, at, WHITE)
	local head = at * CFrame.new(0, height + size / 2 - 0.5, 0)
	local pop = Instance.new("Model")
	pop.Name = "Lollipop"
	makeDisc(pop, "Lollipop", size, 1.6, head * CFrame.new(0, 0, 0.8), color)
	local dots, turns = 12, 2
	for index = 1, dots do
		local t = index / dots
		local angle = t * turns * math.pi * 2
		local radius = t * size * 0.4
		makeBall(pop, "LollipopSwirl", size * (0.08 + t * 0.07), head * CFrame.new(math.cos(angle) * radius, math.sin(angle) * radius, -0.8), WHITE)
	end
	spin(pop, parent, head, -0.8)
end

-- A string of little triangle flags from `from` to `to` (world positions).
local function buildBunting(parent: Instance, from: Vector3, to: Vector3, colors: { Color3 })
	local length = (to - from).Magnitude
	local line = CFrame.lookAt((from + to) / 2, to)
	makeDecor(parent, "BuntingLine", Vector3.new(0.15, 0.15, length), line, WHITE)
	local count = math.floor(length / 5)
	for index = 1, count do
		local z = -length / 2 + (index - 0.5) * length / count
		-- a wedge hanging point down: its tall end at the line
		local flag = makeWedge(parent, "Bunting", Vector3.new(0.1, 2.2, 2.2), line * CFrame.new(0, -1.1, z) * CFrame.Angles(math.pi, 0, 0), colors[(index - 1) % #colors + 1])
		flag.CastShadow = false
	end
end

-- The roof of a room with nothing above it: a deck with a parapet, a few props, and
-- an opening in the +X parapet where the stairs arrive (`stairsFrom`..`stairsTo`).
-- `roomZ` is the room below's center (plot space); the storey above's room is in
-- front of it.
local function buildTerrace(layer: Instance, cframe: CFrame, storey: number, roomZ: number, stairsFrom: number, stairsTo: number, palette: Palette)
	local y = floorY(storey + 1)
	local fromZ, toZ = roomZ - ROOM_SIZE.Z / 2, roomZ + ROOM_SIZE.Z / 2
	local inner = ROOM_SIZE.X - WALL * 2
	local deck = makePart(layer, "Terrace", Vector3.new(inner, STOREY - CEILING - CEILING_THICKNESS, toZ - WALL - fromZ), cframe * CFrame.new(0, y - (STOREY - CEILING - CEILING_THICKNESS) / 2, (fromZ + toZ - WALL) / 2), DECK_COLOR, Enum.Material.WoodPlanks)
	deck.CastShadow = false

	-- the parapet, on the walls below
	local height = 3.4
	local function parapet(size: Vector3, at: Vector3)
		makePart(layer, "Parapet", size, cframe * CFrame.new(at), palette.Siding)
		makeDecor(layer, "ParapetCap", Vector3.new(size.X + 0.6, 0.6, size.Z + 0.6), cframe * CFrame.new(at + Vector3.new(0, height / 2 + 0.3, 0)), palette.Dark)
	end
	local px = HALF_X - 0.6
	parapet(Vector3.new(1.2, height, toZ - fromZ), Vector3.new(-px, y + height / 2, (fromZ + toZ) / 2))
	parapet(Vector3.new(ROOM_SIZE.X, height, 1.2), Vector3.new(0, y + height / 2, toZ - 0.6))
	for _, span in { { fromZ, stairsFrom }, { stairsTo, toZ - 1.2 } } do
		if span[2] - span[1] > 0.5 then
			parapet(Vector3.new(1.2, height, span[2] - span[1]), Vector3.new(px, y + height / 2, (span[1] + span[2]) / 2))
		end
	end

	-- props: the crooked chimney, a water tower, lollipops by the candy floor's door,
	-- planters and a table under a striped umbrella
	local function at(x: number, z: number): CFrame
		return cframe * CFrame.new(x, y, z)
	end
	buildChimney(layer, at(-52, toZ - 18) * CFrame.Angles(0, 0, math.rad(5)), 40)
	local tower = at(44, toZ - 24)
	for _, corner in { { -5, -5 }, { 5, -5 }, { -5, 5 }, { 5, 5 } } do
		makeDecor(layer, "TowerLeg", Vector3.new(1.2, 14, 1.2), tower * CFrame.new(corner[1], 7, corner[2]), WOOD_DARK, Enum.Material.Wood)
	end
	makeDecor(layer, "TowerDeck", Vector3.new(13, 0.8, 13), tower * CFrame.new(0, 14, 0), WOOD_DARK, Enum.Material.WoodPlanks)
	makeCylinder(layer, "WaterTank", 14, 11, tower * CFrame.new(0, 14.4, 0), WOOD_COLOR)
	for _, band in { 16.5, 22.5 } do
		makeCylinder(layer, "TankBand", 14.5, 0.7, tower * CFrame.new(0, band, 0), palette.Dark)
	end
	makeCylinder(layer, "TankRoof", 15.6, 1.4, tower * CFrame.new(0, 25.4, 0), palette.Roof)
	makeCylinder(layer, "TankRoof", 10, 2.4, tower * CFrame.new(0, 26.8, 0), palette.Roof:Lerp(WHITE, 0.3))
	makeCylinder(layer, "TankRoof", 4.5, 2, tower * CFrame.new(0, 29.2, 0), palette.Roof)
	makeBall(layer, "TankTip", 2, tower * CFrame.new(0, 31.6, 0), GOLD_COLOR)
	for index, offset in { { -9, -4, 0 }, { -9, 0.4, 0 }, { -9, -4, 4.4 } } do
		local crate = tower * CFrame.new(offset[1], 2 + offset[3], offset[2]) * CFrame.Angles(0, index * 0.25, 0)
		makeDecor(layer, "Crate", Vector3.new(4, 4, 4), crate, WOOD_COLOR, Enum.Material.WoodPlanks)
	end
	for _, side in { -1, 1 } do
		-- facing the terrace, beside the candy floor's door
		buildLollipop(layer, at(side * 16, fromZ + 6) * CFrame.Angles(0, math.pi, 0), 14, 12, if side < 0 then palette.CandyDeep else RAINBOW[1])
	end
	-- balloons tied to the parapet's back corners
	buildBalloons(layer, at(-HALF_X + 2.5, toZ - 2.5) * CFrame.new(0, 3.4, 0), 3, 1)
	buildBalloons(layer, at(HALF_X - 2.5, toZ - 2.5) * CFrame.new(0, 3.4, 0), 4, 3)
	-- bunting from the candy floor's wall out to poles at the back
	local colors = { RAINBOW[1], RAINBOW[2], RAINBOW[3], RAINBOW[4], RAINBOW[5] }
	for _, x in { -34, 34 } do
		local pole = at(x, toZ - 4)
		makeCylinder(layer, "BuntingPole", 0.6, 12, pole, WHITE)
		makeBall(layer, "BuntingPoleTop", 1.2, pole * CFrame.new(0, 12.4, 0), palette.Accent)
		buildBunting(layer, (at(x, fromZ + 1) * CFrame.new(0, 17, 0)).Position, (pole * CFrame.new(0, 11.6, 0)).Position, colors)
	end
	for index, spot in { { -64, fromZ + 34 }, { -64, fromZ + 74 }, { -10, toZ - 4.5 } } do
		local planter = at(spot[1], spot[2]) * (if index == 3 then CFrame.Angles(0, math.pi / 2, 0) else CFrame.identity)
		makeDecor(layer, "Planter", Vector3.new(3, 2.4, 10), planter * CFrame.new(0, 1.2, 0), WOOD_DARK, Enum.Material.Wood)
		makeDecor(layer, "PlanterLeaves", Vector3.new(2.4, 1, 9.4), planter * CFrame.new(0, 2.6, 0), LEAF_COLORS[1])
		for flower = -1, 1 do
			makeBall(layer, "Flower", 1.8, planter * CFrame.new(0, 3.2, flower * 3), FLOWER_COLORS[flower + 2])
		end
	end
	local patio = at(-12, roomZ + 10)
	makeCylinder(layer, "TableLeg", 0.8, 3, patio, WHITE)
	makeCylinder(layer, "Table", 6, 0.5, patio * CFrame.new(0, 3, 0), WHITE)
	makeCylinder(layer, "UmbrellaPole", 0.5, 10, patio * CFrame.new(0, 3.5, 0), WHITE)
	for index, diameter in { 13, 9, 5 } do
		makeCylinder(layer, "Umbrella", diameter, 1, patio * CFrame.new(0, 11 + index, 0), if index % 2 == 1 then palette.Accent else WHITE)
	end
	-- a little rooftop garden
	local garden = at(-36, roomZ + 4)
	makeDecor(layer, "GardenBed", Vector3.new(22, 1.6, 30), garden * CFrame.new(0, 0.8, 0), WOOD_DARK, Enum.Material.WoodPlanks)
	makeDecor(layer, "GardenGrass", Vector3.new(20.6, 0.4, 28.6), garden * CFrame.new(0, 1.7, 0), LEAF_COLORS[2], Enum.Material.Grass)
	for index, spot in { { -6, -9 }, { 5, -6 }, { -3, 2 }, { 6, 7 }, { -6, 10 }, { 2, 11 } } do
		makeBall(layer, "Flower", 1.8, garden * CFrame.new(spot[1], 2.6, spot[2]), FLOWER_COLORS[(index - 1) % #FLOWER_COLORS + 1])
	end
	buildBush(layer, garden * CFrame.new(-6, 1.9, -1), 4, FLOWER_COLORS[1])
	buildBush(layer, garden * CFrame.new(6, 1.9, 0), 3.4, FLOWER_COLORS[2])
	-- two striped deck chairs facing the sun
	for _, x in { 10, 18 } do
		local chair = at(x, roomZ + 14) * CFrame.Angles(0, math.rad(-20), 0)
		makeDecor(layer, "DeckChair", Vector3.new(4, 1, 7), chair * CFrame.new(0, 1.6, 0), palette.Accent)
		makeDecor(layer, "DeckChairStripe", Vector3.new(1.4, 1.05, 7.05), chair * CFrame.new(0, 1.6, 0), WHITE)
		makeDecor(layer, "DeckChair", Vector3.new(4, 1, 4.5), chair * CFrame.new(0, 3.6, 4.6) * CFrame.Angles(math.rad(55), 0, 0), palette.Accent)
		for _, side in { -1, 1 } do
			makeDecor(layer, "DeckChairLeg", Vector3.new(0.4, 1.1, 6), chair * CFrame.new(side * 1.8, 0.55, 0), WHITE)
		end
	end
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
	local fromZ = rooms[1].Z - ROOM_SIZE.Z / 2
	local toZ = rooms[#rooms].Z + ROOM_SIZE.Z / 2

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
		if style.Checker then
			buildChecker(layer, center, style.Checker, style.FloorMaterial)
		end
		RoomDecor.Build(room.ZoneId, layer, center)

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
				local doorBase = wallBase * CFrame.new(SIDE_DOOR_Z, 0, 0)
				buildDoorFrame(layer, doorBase, SIDE_DOOR, palette.Dark)
				local door = makeGlassDoor(layer, `{room.ZoneId}Shutter`, SIDE_DOOR, doorBase, style.Band)
				local sign = makeSign(layer, `{room.ZoneId}Sign`, Vector3.new(17, 4.6, 1), wallBase * CFrame.new(SIDE_DOOR_Z, SIDE_DOOR.Y + 5, -WALL / 2 - 0.55), style.SignColor, palette[facade.Pop], palette.Dark, style.Title)
				factory.Doorways[room.ZoneId] = { Label = sign, Title = style.Title, Shutter = door }
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
				buildAwning(layer, face * CFrame.new(0, ENTRANCE.Y + 1, 0), ENTRANCE.X + 4, palette.Accent)
				factory.SignLabel = makeSign(layer, "Sign", Vector3.new(40, 6.5, 1), face * CFrame.new(0, CEILING - 3.5, -2.2), SIGN_TEXT_COLOR, palette.Accent, palette.Dark, "Empty Plot")
				for _, side in { -1, 1 } do
					buildLamp(layer, face * CFrame.new(side * (ENTRANCE.X / 2 + 4), ENTRANCE.Y - 3, 0), palette.Dark)
					buildPot(layer, face * CFrame.new(side * (ENTRANCE.X / 2 + 4.5), -FLOOR_TOP, -2.4), 3, FLOWER_COLORS[if side < 0 then 1 else 4])
				end
				-- bushes along the front, and a mailbox by the path
				for index, x in { -66, -45, 45, 66 } do
					buildBush(layer, face * CFrame.new(x, -FLOOR_TOP, -3), if math.abs(x) > 60 then 5 else 5.4, FLOWER_COLORS[index])
				end
				local mailbox = face * CFrame.new(24, -FLOOR_TOP, -10)
				makeDecor(layer, "MailboxPost", Vector3.new(0.6, 3.6, 0.6), mailbox * CFrame.new(0, 1.8, 0), WOOD_DARK)
				makeDecor(layer, "Mailbox", Vector3.new(2.2, 2, 3.2), mailbox * CFrame.new(0, 4.6, 0), palette.Accent)
				makeDecor(layer, "MailboxFlag", Vector3.new(0.2, 1.4, 0.6), mailbox * CFrame.new(1.2, 5.2, 0.6), Color3.fromRGB(255, 90, 110))
				buildBalloons(layer, mailbox * CFrame.new(-1.1, 5.4, 0), 3, 0)
			elseif facade.Icing then
				-- the candy floor's emblem over the entrance: a giant spinning donut
				buildDonut(layer, face * CFrame.new(0, DONUT_Y, 0), DONUT_SIZE, RAINBOW[1])
			else
				-- a round window over the entrance, under a little striped awning
				local window = face * CFrame.new(0, BAND_TOP + WINDOW.Y / 2, 0)
				makeDisc(layer, "WindowFrame", 15, 1, window, palette[facade.Frame])
				local glass = makeDisc(layer, "Window", 12.4, 1.2, window, GLASS_COLOR)
				glass.Reflectance = 0.15
				makeDecor(layer, "WindowBar", Vector3.new(0.5, 12.4, 0.6), window * CFrame.new(0, 0, -1.2), palette[facade.Frame])
				makeDecor(layer, "WindowBar", Vector3.new(12.4, 0.5, 0.6), window * CFrame.new(0, 0, -1.2), palette[facade.Frame])
				buildAwning(layer, window * CFrame.new(0, 9.5, 0), 18, palette[facade.Pop])
				buildInnerWindow(layer, front * CFrame.new(0, BAND_TOP + WINDOW.Y / 2, WALL / 2) * CFrame.Angles(0, math.pi, 0), true, style.Trim)
				if storey == 2 then
					-- a little balcony under it, over the owner's sign
					local deck = face * CFrame.new(0, 0, -2.5)
					makeDecor(layer, "Balcony", Vector3.new(18, 0.8, 5), deck, WOOD_COLOR, Enum.Material.WoodPlanks)
					for _, x in { -8.6, -2.9, 2.9, 8.6 } do
						makeDecor(layer, "BalconyPost", Vector3.new(0.5, 3.4, 0.5), deck * CFrame.new(x, 2.1, -2.2), WHITE)
					end
					makeDecor(layer, "BalconyRail", Vector3.new(18, 0.5, 0.5), deck * CFrame.new(0, 3.8, -2.2), WHITE)
					for _, side in { -1, 1 } do
						makeDecor(layer, "BalconyRail", Vector3.new(0.5, 0.5, 5), deck * CFrame.new(side * 8.75, 3.8, 0), WHITE)
						buildPot(layer, deck * CFrame.new(side * 6, 0.4, 0), 1.8, FLOWER_COLORS[if side < 0 then 2 else 1])
					end
					buildBalloons(layer, deck * CFrame.new(8.75, 3.8, -2.2), 3, 2)
				end
			end
		else
			-- The doorway from the room in front, with the room's sign over it and a
			-- glass door, locked until the zone unlocks. Each half of the wall wears its
			-- own room's color.
			local divider = center * CFrame.new(0, 0, -halfZ)
			local half = WALL / 2
			local previous = rooms[index - 1]
			local openings = { { X = 0, Width = DOORWAY.X, Height = DOORWAY.Y } }
			buildWall(layer, divider * CFrame.new(0, 0, -half / 2), inner, openings, previous.Style.Wall or palette.Pastel, nil, half)
			buildWall(layer, divider * CFrame.new(0, 0, half / 2), inner, openings, style.Wall or palette.Pastel, nil, half)
			buildBand(layer, divider * CFrame.Angles(0, math.pi, 0), inner, openings, half, previous.Style)
			buildBand(layer, divider, inner, openings, half, style)
			if previous.Style.Wallpaper then
				buildWallpaper(layer, divider * CFrame.Angles(0, math.pi, 0), inner, openings, half, previous.Style.Wallpaper)
			end
			if style.Wallpaper then
				buildWallpaper(layer, divider, inner, openings, half, style.Wallpaper)
			end
			buildDoorFrame(layer, divider, DOORWAY, previous.Style.Trim)
			local face = divider * CFrame.new(0, 0, -half)
			local sign = makeSign(layer, `{room.ZoneId}Sign`, Vector3.new(34, 6.5, 1), face * CFrame.new(0, CEILING - 4.5, -0.55), style.SignColor, palette[facade.Pop], palette.Dark, style.Title)
			local door = makeGlassDoor(layer, `{room.ZoneId}Shutter`, DOORWAY, divider, style.Band)
			factory.Doorways[room.ZoneId] = { Label = sign, Title = style.Title, Shutter = door }
		end

		if isLast then
			-- the back wall; the top storey's opens onto the terrace behind it
			local back = center * CFrame.new(0, 0, halfZ - WALL / 2) * CFrame.Angles(0, math.pi, 0)
			local terraceDoor = storey == topStorey and storey > 1 and terraceBehindTop
			local openings = if terraceDoor then { { X = 0, Width = TERRACE_DOOR.X, Height = TERRACE_DOOR.Y } } else {}
			buildOuterWall(layer, back, inner, openings, facade.Windows, room, storey, palette, false)
			if terraceDoor then
				buildDoorFrame(layer, back, TERRACE_DOOR, palette.Dark)
				local door = makeGlassDoor(layer, `{room.ZoneId}Shutter`, TERRACE_DOOR, back, style.Band)
				local sign = makeSign(layer, `{room.ZoneId}Sign`, Vector3.new(22, 5, 1), back * CFrame.new(0, TERRACE_DOOR.Y + 5, -WALL / 2 - 0.55), style.SignColor, palette[facade.Pop], palette.Dark, style.Title)
				factory.Doorways[room.ZoneId] = { Label = sign, Title = style.Title, Shutter = door }
			end
		end
	end

	-- The trims: a stone plinth (ground floor), corner pillars, pilasters where the
	-- rooms meet, and a chunky band along the top (the next floor's ledge, or the
	-- cornice under the roof), with icing dripping off the candy floor's.
	local depth = toZ - fromZ
	local middleZ = (fromZ + toZ) / 2
	local isTop = storey == topStorey
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
	-- under it a strip in the storey's bright accent, or a thick frosting band
	local stripHeight, stripOut = if facade.Icing then 2 else 0.8, bandOut - 0.6
	local stripY = bandTop - bandHeight - stripHeight / 2
	ring("TrimStrip", stripHeight, stripOut, stripY, if facade.Icing or isTop then WHITE else palette[facade.Pop], false)
	if facade.Icing then
		local y = base + stripY - stripHeight / 2
		local faces: { { any } } = {
			{ CFrame.new(0, y, fromZ), ROOM_SIZE.X, if storey > 1 then DONUT_SIZE / 2 + 3 else 0 }, -- over the donut
			{ CFrame.new(0, y, toZ) * CFrame.Angles(0, math.pi, 0), ROOM_SIZE.X, if isTop then 14 else 0 }, -- over the terrace door's sign
			{ CFrame.new(HALF_X, y, middleZ) * CFrame.Angles(0, -math.pi / 2, 0), depth, 0 },
			{ CFrame.new(-HALF_X, y, middleZ) * CFrame.Angles(0, math.pi / 2, 0), depth, 0 },
		}
		for _, face in faces do
			buildIcing(layer, cframe * face[1], face[2], stripHeight, stripOut, face[3])
		end
	end
	if storey == 1 then
		ring("Plinth", 3, 0.8, 1.5 - FLOOR_TOP, palette.Stone, true) -- from the ground up
	end

	local pillarFrom = if storey == 1 then -FLOOR_TOP else 0
	local pillarTo = bandTop - bandHeight
	for _, corner in { { -1, fromZ }, { 1, fromZ }, { -1, toZ }, { 1, toZ } } do
		local turretCorner = storey >= 2 and corner[1] == -1 and corner[2] == FRONT_Z
		if not turretCorner then
			local foot = cframe * CFrame.new(corner[1] * HALF_X, base + pillarFrom, corner[2])
			if facade.CandyPillars then
				-- candy canes: colored and white bands, under a gumdrop
				local segment = (pillarTo - pillarFrom) / 9
				for band = 0, 8 do
					makeCylinder(layer, "Pillar", facade.PillarSize, segment, foot * CFrame.new(0, band * segment, 0), if band % 2 == 0 then palette[facade.Pillar] else WHITE)
				end
				makeBall(layer, "PillarTop", facade.PillarSize + 1.4, foot * CFrame.new(0, pillarTo - pillarFrom, 0), palette[facade.Pillar])
			else
				local pillar = makeCylinder(layer, "Pillar", facade.PillarSize, pillarTo - pillarFrom, foot, palette[facade.Pillar])
				pillar.CanCollide = true
				pillar.CanQuery = true
				makeCylinder(layer, "PillarFoot", facade.PillarSize + 1.4, 2, foot, palette.Dark)
			end
		end
	end
	for index = 2, #rooms do
		for _, side in { -1, 1 } do
			local pilaster = cframe * CFrame.new(side * (HALF_X + 0.35), base + (pillarFrom + pillarTo) / 2, rooms[index].Z - ROOM_SIZE.Z / 2)
			makeDecor(layer, "Pilaster", Vector3.new(0.7, pillarTo - pillarFrom, 3), pilaster, palette[facade.Pillar])
		end
	end
end

-- API ------------------------------------------------------------------------------

-- Builds the factory for a plot at `cframe`, `height` storeys high (all of them if nil): a
-- room for each zone in the layout up there, open or not, and the roof on top. `color`
-- is the plot's own pastel color, which tints the whole outside.
function FactoryBuilder.Build(model: Model, cframe: CFrame, color: Color3, height: number?): Factory
	topStorey = math.clamp(height or STOREYS, 1, STOREYS)
	roofBase = floorY(topStorey + 1) + 0.5
	local factory: Factory = { SignLabel = (nil :: any) :: TextLabel, Doorways = {} }
	local palette = paletteOf(color)
	local layers: { Instance } = { model }
	for level = 2, topStorey + 1 do
		local name = if level > topStorey then "Roof" else `Storey{level}`
		table.insert(layers, makeCutaway(model, name, level, cframe))
	end

	local storeys: { { Room } } = {}
	for index, spot in FactoryBuilder.Layout do
		if spot.Storey > topStorey then
			continue -- not built yet
		end
		local zoneId = Zones.List[index].Id
		storeys[spot.Storey] = storeys[spot.Storey] or {}
		table.insert(storeys[spot.Storey], { ZoneId = zoneId, Z = spot.Z, Style = ROOM_STYLES[zoneId] or ROOM_STYLES.ToyWorkshop })
	end
	for _, rooms in storeys do
		table.sort(rooms, function(a, b)
			return a.Z < b.Z
		end)
	end
	-- a terrace lies behind the top storey when the storey under it reaches further back
	local top, under = storeys[topStorey], storeys[topStorey - 1]
	terraceBehindTop = under ~= nil and under[#under].Z > top[#top].Z
	for storey, rooms in storeys do
		buildStorey(layers, cframe, storey, rooms, palette, factory)
	end

	local stairsFrom, stairsTo = buildStairs(model, layers[2], cframe, palette, topStorey >= 3)
	-- a terrace on every room with nothing above it (below the top storey)
	for storey = 1, topStorey - 1 do
		for _, room in storeys[storey] do
			local covered = false
			for _, upstairs in storeys[storey + 1] do
				covered = covered or upstairs.Z == room.Z
			end
			if not covered then
				buildTerrace(layers[storey + 1], cframe, storey, room.Z, stairsFrom, stairsTo, palette)
			end
		end
	end
	buildRoof(layers[topStorey + 1], cframe, top[1].Z - ROOM_SIZE.Z / 2, top[#top].Z + ROOM_SIZE.Z / 2, palette)
	buildTurret(layers[topStorey + 1], cframe * CFrame.new(-HALF_X - 2, 0, FRONT_Z - 2), (cframe:VectorToWorldSpace(Vector3.new(-1, 0, -1))).Unit, palette)
	for index, z in { FRONT_Z + ROOM_SIZE.Z + 10, BACK_Z - 10 } do
		local pipeColor = if index == 1 then palette.Accent else Color3.fromRGB(210, 222, 240)
		buildPipe(layers, cframe * CFrame.new(-HALF_X - 3, 0, z) * CFrame.Angles(0, math.pi, 0), floorY(3) - 4, pipeColor, palette.Dark)
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

-- Readies a freshly built factory's storeys from `fromLevel` up (and its roof) to drop in
-- on clients (TycoonFX, DropIn): each of those layers' loose parts is grouped into
-- chunks on a grid (in plot space, `cframe`), which fall one after another, bottom
-- first, layer by layer; every part is stamped with its chunk's place in line
-- (BuildIndex) and the time (Built), and the model with DropFrom and DropAt.
local CHUNK = Vector3.new(47, 15, 40)

function FactoryBuilder.PrepareDropIn(model: Model, cframe: CFrame, fromLevel: number)
	local now = workspace:GetServerTimeNow()
	local layers = {}
	for _, child in model:GetChildren() do
		local level = child:GetAttribute("Level")
		if child:IsA("Model") and typeof(level) == "number" and level >= fromLevel then
			table.insert(layers, child)
		end
	end
	table.sort(layers, function(a, b)
		return (a:GetAttribute("Level") :: number) < (b:GetAttribute("Level") :: number)
	end)
	local order = 0
	for _, layer in layers do
		local function cellOf(position: Vector3): Vector3
			local offset = cframe:PointToObjectSpace(position)
			return Vector3.new(math.floor(offset.X / CHUNK.X), math.floor(offset.Y / CHUNK.Y), math.floor(offset.Z / CHUNK.Z))
		end
		-- the pieces: a chunk Model per cell for the loose parts, and the layer's own
		-- sub-Models (spinners, balloons) as they are
		local chunks: { [Vector3]: Model } = {}
		local pieces: { { Model: Model, Cell: Vector3 } } = {}
		for _, child in layer:GetChildren() do
			if child:IsA("BasePart") then
				local cell = cellOf(child.Position)
				local chunk = chunks[cell]
				if not chunk then
					chunk = Instance.new("Model")
					chunk.Name = "Chunk"
					chunks[cell] = chunk
					table.insert(pieces, { Model = chunk, Cell = cell })
				end
				child.Parent = chunk
			elseif child:IsA("Model") then
				table.insert(pieces, { Model = child, Cell = cellOf(child:GetPivot().Position) })
			end
		end
		for _, chunk in chunks do
			chunk.Parent = layer
		end
		table.sort(pieces, function(a, b)
			if a.Cell.Y ~= b.Cell.Y then
				return a.Cell.Y < b.Cell.Y
			elseif a.Cell.Z ~= b.Cell.Z then
				return a.Cell.Z < b.Cell.Z
			end
			return a.Cell.X < b.Cell.X
		end)
		for _, piece in pieces do
			order += 1
			for _, part in piece.Model:GetDescendants() do
				if part:IsA("BasePart") then
					part:SetAttribute("BuildIndex", order)
					part:SetAttribute("Built", now)
				end
			end
		end
	end
	model:SetAttribute("DropFrom", fromLevel)
	model:SetAttribute("DropAt", now)
end

-- Shows a room's sign with `lock` under it and locks its glass door, or opens the
-- doorway when `lock` is nil.
function FactoryBuilder.SetLocked(doorway: Doorway, lock: string?)
	doorway.Label.Text = if lock then `{doorway.Title}\n{lock}` else doorway.Title
	local door = doorway.Shutter
	door.Transparency = if lock then LOCKED_GLASS else 1
	door.CanCollide = lock ~= nil
	door.CanQuery = lock ~= nil
	local gui = door:FindFirstChild("Lock")
	if gui and gui:IsA("SurfaceGui") then
		gui.Enabled = lock ~= nil
	end
end

return FactoryBuilder
