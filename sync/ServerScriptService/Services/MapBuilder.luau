--[[
	MapBuilder
	Builds the world around the factories (GDD §15): a bright green valley ringed by
	mountains, with the factories spread around it. In the middle, a big round pastel
	plaza holds the fountain with the giant Tralalero statue (and, later, the boss
	arena), with a stripe in each factory's color running out to its bridge. A river
	rings the plaza; past each wooden bridge, a path in the factory's color leads on
	to its entrance. Grassy hills and two streams (each ending in a pond) fill the
	gaps between the factories, dotted with trees, bushes, flowers, rocks, mushrooms,
	benches and lamps, with balloons floating over it all. Every gap has a striped tulip
	field with butterflies, a grove of blossom and golden trees, a turning windmill and
	birds circling above; hot air balloons drift round the valley.

	The ground, hills and water are Terrain, made here at startup; everything else is
	parts. Decor is scattered with a free-space check, so it never lands on a path, a
	stream or a factory. Loot boxes find their spots with MapBuilder.FindSpot (on the
	ground, never on water, clear of decor). The statue's spin and the balloons' bob are
	client-side (Atmosphere).
]]

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local BrainrotModels = require(Shared.BrainrotModels)
local Brainrots = require(Shared.Config.Brainrots)
local Rarities = require(Shared.Config.Rarities)

local FactoryBuilder = require(script.Parent.FactoryBuilder)
local TycoonManager = require(script.Parent.TycoonManager)
local WorkBudget = require(script.Parent.WorkBudget)

local Terrain = workspace.Terrain

-- Layout, in studs from the hub (the world's origin) ----------------------------------

local WORLD_SIZE = 2200
local PLAZA_RADIUS = 116 -- the paved plaza; then a sandy beach, the river, the far bank
local RIVER_FROM, RIVER_TO = 125, 147
local FOUNTAIN_RADIUS = 20
local CENTER_RADIUS = FOUNTAIN_RADIUS + 14 -- the mint circle around the fountain
local BRIDGE_FROM, BRIDGE_TO = 112, 160
local BRIDGE_RISE = 3
local PATH_WIDTH = 14
local PATH_TOP = 0.4
local PATH_SWAY = 7 -- the outer paths' gentle S-curve
local STREAM_END = 640 -- each stream ends in a pond this far out
local POND_RADIUS = 50
local MOUNTAIN_RING = 900
local STATUE_ID = "TralaleroTralala"
local STATUE_SCALE = 5
local SEED = 7 -- the same world on every server

-- Cartoon flagstones (decal 137260739401430) for the paths and the plaza's carpets, and
-- cartoon square tiles (decal 276550418) for the plaza; both get tinted.
local FLAGSTONE_TEXTURE = "rbxassetid://115767838404677"
local TILE_TEXTURE = "rbxassetid://276550417"
-- Cartoon water with foam outlines (Creator Store decal 86200763177816; its image id).
-- The terrain's cartoon grass is a MaterialVariant saved in the place (scripts can't
-- make one): see tools/SetupMaterials.luau.
local WATER_TEXTURE = "rbxassetid://80572692344324"
-- Two layers at different scales and speeds, so the pattern doesn't visibly repeat.
local WATER_LAYERS = {
	{ Tile = 52, Transparency = 0.45, Drift = 1.6, Shift = 0 },
	{ Tile = 29, Transparency = 0.75, Drift = 0.7, Shift = 13 },
}

-- Colors ----------------------------------------------------------------------------

local TERRAIN_COLORS = {
	[Enum.Material.Grass] = Color3.fromRGB(115, 225, 70),
	[Enum.Material.LeafyGrass] = Color3.fromRGB(80, 200, 75), -- lusher patches
	[Enum.Material.Sand] = Color3.fromRGB(255, 226, 150),
	[Enum.Material.Ground] = Color3.fromRGB(205, 150, 100),
	[Enum.Material.Rock] = Color3.fromRGB(175, 170, 210),
}
local WATER_COLOR = Color3.fromRGB(70, 205, 255)
local PAVING_COLOR = Color3.fromRGB(255, 240, 215)
local PAVING_ACCENT = Color3.fromRGB(255, 190, 225)
local CENTER_COLOR = Color3.fromRGB(190, 240, 225)
local CURB_COLOR = Color3.fromRGB(255, 255, 255)
local WOOD_COLOR = Color3.fromRGB(215, 160, 105)
local WOOD_DARK = Color3.fromRGB(165, 110, 70)
local STONE_COLOR = Color3.fromRGB(250, 248, 255)
local FOUNTAIN_WATER = Color3.fromRGB(110, 215, 255)
local LAMP_POST_COLOR = Color3.fromRGB(110, 80, 170)
local LAMP_LIGHT_COLOR = Color3.fromRGB(255, 236, 190)
local BENCH_IRON = Color3.fromRGB(80, 70, 110)
local TRUNK_COLOR = Color3.fromRGB(150, 100, 70)
local ROCK_COLORS = { Color3.fromRGB(190, 185, 215), Color3.fromRGB(165, 160, 195) }
local LEAF_SETS = { -- { main, highlight }
	{ Color3.fromRGB(100, 205, 55), Color3.fromRGB(150, 235, 90) },
	{ Color3.fromRGB(60, 180, 85), Color3.fromRGB(110, 215, 110) },
	{ Color3.fromRGB(255, 155, 205), Color3.fromRGB(255, 205, 232) }, -- cherry blossom
	{ Color3.fromRGB(255, 200, 60), Color3.fromRGB(255, 230, 120) }, -- golden
}
local FLOWER_COLORS = {
	Color3.fromRGB(255, 100, 165),
	Color3.fromRGB(255, 215, 60),
	Color3.fromRGB(150, 120, 255),
	Color3.fromRGB(255, 255, 255),
	Color3.fromRGB(255, 140, 70),
	Color3.fromRGB(90, 200, 255),
}
local BALLOON_COLORS = {
	Color3.fromRGB(255, 90, 160),
	Color3.fromRGB(255, 215, 50),
	Color3.fromRGB(90, 190, 255),
	Color3.fromRGB(170, 110, 255),
	Color3.fromRGB(110, 230, 120),
	Color3.fromRGB(255, 140, 60),
}

local MapBuilder = {}

-- Where the plaza leaves room for the leaderboards and the podium (on the paving, facing
-- the fountain: -Z toward it), filled in as the plaza is built.
MapBuilder.BoardSpots = {} :: { CFrame }
MapBuilder.PodiumSpot = nil :: CFrame?

local random = Random.new(SEED)
local hub: Folder
local ground: Folder -- what loot boxes may stand on (besides terrain): paving, bridges
local paths: { Vector3 } = {} -- points along every path, for the free-space check
local streams: { Vector3 } = {} -- points along every stream
type Area = { Center: Vector3, Radius: number }
local features: { Area } = {} -- statues, picnics, gardens... (nothing else lands on them)
local hills: { Area } = {} -- features stay off the slopes

-- Part helpers ----------------------------------------------------------------------

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

-- Just for looks: nothing collides with it or finds it.
local function makeDecor(parent: Instance, name: string, size: Vector3, cframe: CFrame, color: Color3, material: Enum.Material?): Part
	local part = makePart(parent, name, size, cframe, color, material)
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	return part
end

local function makeBall(parent: Instance, name: string, diameter: number, position: Vector3, color: Color3): Part
	local ball = makePart(parent, name, Vector3.one * diameter, CFrame.new(position), color)
	ball.Shape = Enum.PartType.Ball
	return ball
end

-- An upright cylinder standing on `base` (its bottom center).
local function makeCylinder(parent: Instance, name: string, radius: number, height: number, base: Vector3, color: Color3, material: Enum.Material?): Part
	local cframe = CFrame.new(base + Vector3.new(0, height / 2, 0)) * CFrame.Angles(0, 0, math.pi / 2)
	local part = makePart(parent, name, Vector3.new(height, radius * 2, radius * 2), cframe, color, material)
	part.Shape = Enum.PartType.Cylinder
	return part
end

-- A slab from `from` to `to` (the slab's top-center line), `width` wide.
local function makeSlab(parent: Instance, name: string, from: Vector3, to: Vector3, width: number, thickness: number, color: Color3, material: Enum.Material?): Part
	local length = (to - from).Magnitude
	local cframe = CFrame.lookAt((from + to) / 2, to) * CFrame.new(0, -thickness / 2, 0)
	return makePart(parent, name, Vector3.new(width, thickness, length), cframe, color, material)
end

-- Tiles `image` over one face of `part`, see-through and tinted the part's color
-- (`whiten` lightens the tint), so the part's own color shows with the pattern drawn
-- over it. `along` shifts it down the part's Z, so stretches laid end to end continue
-- the pattern.
local function tile(part: BasePart, face: Enum.NormalId, image: string, studs: number, transparency: number, whiten: number, along: number?)
	local texture = Instance.new("Texture")
	texture.Texture = image
	texture.Face = face
	texture.StudsPerTileU = studs
	texture.StudsPerTileV = studs
	texture.OffsetStudsV = (along or 0) % studs
	texture.Color3 = part.Color:Lerp(Color3.new(1, 1, 1), whiten)
	texture.Transparency = transparency
	texture.Parent = part
end

-- A flat triangle (a, b, c) made of two wedges (the classic two-wedge trick).
local function makeTriangle(parent: Instance, a: Vector3, b: Vector3, c: Vector3, color: Color3)
	local ab, ac, bc = b - a, c - a, c - b
	local abd, acd, bcd = ab:Dot(ab), ac:Dot(ac), bc:Dot(bc)
	if abd > acd and abd > bcd then
		c, a = a, c
	elseif acd > bcd and acd > abd then
		a, b = b, a
	end
	ab, ac, bc = b - a, c - a, c - b
	local right = ac:Cross(ab).Unit
	local up = bc:Cross(right).Unit
	local back = bc.Unit
	local height = math.abs(ab:Dot(up))
	for index, spec in { { ab, (a + b) / 2, 1 }, { ac, (a + c) / 2, -1 } } do
		local wedge = Instance.new("WedgePart")
		wedge.Name = "Canvas" .. index
		wedge.Anchored = true
		wedge.CanCollide = false
		wedge.CanQuery = false
		wedge.CanTouch = false
		wedge.Color = color
		wedge.Material = Enum.Material.Fabric
		local edge, middle, flip = spec[1] :: Vector3, spec[2] :: Vector3, spec[3] :: number
		wedge.Size = Vector3.new(0.3, height, math.abs(edge:Dot(back)))
		wedge.CFrame = CFrame.fromMatrix(middle, right * flip, up, back * flip)
		wedge.Parent = parent
	end
end

local function onGround(angle: number, radius: number): Vector3
	return Vector3.new(math.sin(angle) * radius, 0, math.cos(angle) * radius)
end

-- Terrain ---------------------------------------------------------------------------

-- Terrain snaps to a 4-stud grid, so flat surfaces can only sit at some heights.
-- Measured: a block filled up to Y = t has its surface at t + 2 (so the valley's grass,
-- filled up to -2, is at 0); a cylinder filled up to -4 has its surface at -2 (the
-- sandy banks and beaches); water filled up to -4 stands at -4.
local GROUND_FILL_TOP = -2
local BANK_FILL_TOP = -4
local WATER_TOP = -4
local BED_TOP = -8 -- dug channels keep their sand below this

local function fillDisc(center: Vector3, radius: number, top: number, material: Enum.Material)
	Terrain:FillCylinder(CFrame.new(center.X, top - 6, center.Z), 12, radius, material)
end

-- Digs a round pool down to the bed and fills it with water.
local function pool(center: Vector3, radius: number)
	Terrain:FillCylinder(CFrame.new(center.X, BED_TOP + 8, center.Z), 16, radius, Enum.Material.Air)
	Terrain:FillCylinder(CFrame.new(center.X, (BED_TOP + WATER_TOP) / 2, center.Z), WATER_TOP - BED_TOP, radius, Enum.Material.Water)
end

-- Repaints the ground at `cframe` (a point on the surface, turned as wanted) with
-- `material`, keeping its height. The tall animated grass only grows on Grass, so
-- LeafyGrass makes a trimmed lawn under paths and props, and Ground a flower bed.
local function paint(cframe: CFrame, size: Vector2, material: Enum.Material)
	Terrain:FillBlock(cframe * CFrame.new(0, -6, 0), Vector3.new(size.X, 8, size.Y), material)
end

-- A round hill: the cap of a ball sunk into the ground, `footprint` wide at its base.
local function hill(center: Vector3, footprint: number, height: number, material: Enum.Material?)
	local radius = (footprint * footprint + height * height) / (2 * height)
	Terrain:FillBall(Vector3.new(center.X, height - radius - 2, center.Z), radius, material or Enum.Material.Grass)
end

-- A stream's winding course from the island's river out to its pond.
local function streamCourse(angle: number): { Vector3 }
	local forward = onGround(angle, 1)
	local side = Vector3.new(forward.Z, 0, -forward.X)
	local course = {}
	for radius = RIVER_TO - 8, STREAM_END, 4 do
		local sway = math.min(30, (radius - RIVER_TO) * 0.4) * math.sin(radius / 55)
		table.insert(course, forward * radius + side * sway)
	end
	return course
end

local function buildTerrain(streamAngles: { number }, hillSpots: { { Vector3 | number } })
	for material, color in TERRAIN_COLORS do
		Terrain:SetMaterialColor(material, color)
	end
	Terrain.WaterColor = WATER_COLOR
	Terrain.WaterTransparency = 0.35
	Terrain.WaterReflectance = 0.4
	Terrain.WaterWaveSize = 0.12
	Terrain.WaterWaveSpeed = 8

	Terrain:FillBlock(CFrame.new(0, GROUND_FILL_TOP - 4, 0), Vector3.new(WORLD_SIZE, 8, WORLD_SIZE), Enum.Material.Grass)
	-- Patches of lusher grass (turned blocks, flush with the rest), so the valley isn't
	-- one flat green.
	for _ = 1, 170 do
		local radius = math.sqrt(random:NextNumber(150 ^ 2, (MOUNTAIN_RING + 100) ^ 2))
		local center = onGround(random:NextNumber(0, math.pi * 2), radius)
		local size = random:NextNumber(14, 40)
		local cframe = CFrame.new(center.X, GROUND_FILL_TOP - 4, center.Z) * CFrame.Angles(0, random:NextNumber(0, math.pi), 0)
		Terrain:FillBlock(cframe, Vector3.new(size, 8, size * random:NextNumber(0.5, 1)), Enum.Material.LeafyGrass)
		WorkBudget.Step()
	end

	-- The river around the plaza: sandy banks, dug out and filled with water, then the
	-- island's sand back in the middle (the plaza's paving covers most of it).
	fillDisc(Vector3.zero, RIVER_TO + 8, BANK_FILL_TOP, Enum.Material.Sand)
	pool(Vector3.zero, RIVER_TO)
	fillDisc(Vector3.zero, RIVER_FROM, BANK_FILL_TOP, Enum.Material.Sand)

	-- The streams: banks first along the whole course, then the water, so a bank
	-- never refills water laid down before it.
	for _, angle in streamAngles do
		local course = streamCourse(angle)
		local pond = course[#course]
		for _, point in course do
			if point.Magnitude > RIVER_TO + 4 then -- no sandbars in the river itself
				fillDisc(point, 16, BANK_FILL_TOP, Enum.Material.Sand)
			end
			table.insert(streams, point)
			WorkBudget.Step()
		end
		fillDisc(pond, POND_RADIUS + 8, BANK_FILL_TOP, Enum.Material.Sand)
		for _, point in course do
			pool(point, 11)
			WorkBudget.Step()
		end
		pool(pond, POND_RADIUS)
		table.insert(streams, pond)
	end

	for _, spot in hillSpots do
		hill(spot[1] :: Vector3, spot[2] :: number, spot[3] :: number)
		WorkBudget.Step()
	end

	-- Mountains close the valley (tall enough to hide the world's edge).
	for index = 1, 26 do
		local angle = index / 26 * math.pi * 2 + random:NextNumber(-0.04, 0.04)
		local footprint = random:NextNumber(140, 190)
		hill(onGround(angle, MOUNTAIN_RING + random:NextNumber(0, 80)), footprint, random:NextNumber(120, 160))
		WorkBudget.Step()
	end

	local baseplate = workspace:FindFirstChild("Baseplate")
	if baseplate and baseplate:IsA("BasePart") then
		baseplate.Transparency = 1
		baseplate.CanCollide = false
		baseplate.CanQuery = false
		for _, child in baseplate:GetChildren() do
			if child:IsA("Texture") or child:IsA("Decal") then
				child:Destroy()
			end
		end
	end
end

-- Where things can go -------------------------------------------------------------

local function nearAny(points: { Vector3 }, position: Vector3, distance: number): boolean
	local flat = position * Vector3.new(1, 0, 1)
	for _, point in points do
		if (point - flat).Magnitude < distance then
			return true
		end
	end
	return false
end

-- Whether `position` (on the ground) is clear of the island, paths, streams and
-- factories by `clearance` studs.
local function isFree(position: Vector3, clearance: number, plots: { TycoonManager.Plot }): boolean
	local flat = position * Vector3.new(1, 0, 1)
	if flat.Magnitude < RIVER_TO + 8 + clearance or flat.Magnitude > MOUNTAIN_RING - 120 then
		return false
	end
	if nearAny(paths, flat, PATH_WIDTH / 2 + 3 + clearance) or nearAny(streams, flat, 18 + clearance) then
		return false
	end
	for _, area in features do
		if (area.Center - flat).Magnitude < area.Radius + clearance then
			return false
		end
	end
	for _, plot in plots do
		local offset = plot.CFrame:PointToObjectSpace(flat)
		if math.abs(offset.X) < 85 + clearance and offset.Z > -85 - clearance and offset.Z < 195 + clearance then
			return false
		end
	end
	return true
end

-- The ground's height under (x, z): terrain or paving, never water.
local function groundAt(x: number, z: number): Vector3?
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { Terrain, ground }
	local hit = workspace:Raycast(Vector3.new(x, 400, z), Vector3.new(0, -500, 0), params)
	if hit and hit.Material ~= Enum.Material.Water then
		return hit.Position
	end
	return nil
end

-- A free, flat spot for a feature `radius` wide near `angle`/`distance` (jittering
-- around it), claimed so nothing else lands there. Nil if there's no room.
local function claimSpot(angle: number, distance: number, radius: number, plots: { TycoonManager.Plot }): Vector3?
	for attempt = 0, 30 do
		local jitter = if attempt == 0 then 0 else 1
		local flat = onGround(angle + jitter * random:NextNumber(-0.15, 0.15), distance + jitter * random:NextNumber(-40, 40))
		local onHill = false
		for _, area in hills do
			if (area.Center - flat).Magnitude < area.Radius + radius then
				onHill = true
				break
			end
		end
		local spot = not onHill and isFree(flat, radius, plots) and groundAt(flat.X, flat.Z)
		if spot then
			table.insert(features, { Center = flat, Radius = radius })
			return spot
		end
	end
	return nil
end

-- Tries random spots in a ring until `place` gets one that's free.
local function scatter(count: number, minRadius: number, maxRadius: number, clearance: number, plots: { TycoonManager.Plot }, place: (Vector3) -> ())
	local placed, tries = 0, 0
	while placed < count and tries < count * 30 do
		tries += 1
		local radius = math.sqrt(random:NextNumber(minRadius * minRadius, maxRadius * maxRadius))
		local flat = onGround(random:NextNumber(0, math.pi * 2), radius)
		local spot = isFree(flat, clearance, plots) and groundAt(flat.X, flat.Z)
		if spot then
			place(spot)
			placed += 1
			WorkBudget.Step()
		end
	end
end

-- Decor ------------------------------------------------------------------------------

local function buildLamp(parent: Instance, base: Vector3)
	makeCylinder(parent, "LampBase", 1.4, 1, base, LAMP_POST_COLOR)
	makeCylinder(parent, "LampPost", 0.55, 12, base, LAMP_POST_COLOR)
	local bulb = makeBall(parent, "LampBulb", 3, base + Vector3.new(0, 13.2, 0), LAMP_LIGHT_COLOR)
	bulb.Material = Enum.Material.Neon
	bulb.CanCollide = false
	makeCylinder(parent, "LampCap", 1.9, 0.6, base + Vector3.new(0, 14.4, 0), LAMP_POST_COLOR)
	makeBall(parent, "LampTop", 0.9, base + Vector3.new(0, 15.3, 0), LAMP_POST_COLOR)
	local light = Instance.new("PointLight")
	light.Color = LAMP_LIGHT_COLOR
	light.Range = 18
	light.Brightness = 1
	light.Shadows = false
	light.Parent = bulb
end

-- A park bench whose seat faces `cframe`'s -Z, standing on the ground at `cframe`.
local function buildBench(parent: Instance, cframe: CFrame)
	local bench = Instance.new("Model")
	bench.Name = "Bench"
	for _, x in { -2.6, 2.6 } do
		makePart(bench, "Leg", Vector3.new(0.4, 1.6, 2.2), cframe * CFrame.new(x, 0.8, 0), BENCH_IRON)
		makePart(bench, "Arm", Vector3.new(0.4, 0.4, 2.2), cframe * CFrame.new(x, 2.4, 0), BENCH_IRON)
		makePart(bench, "Back", Vector3.new(0.4, 2.4, 0.4), cframe * CFrame.new(x, 2.4, 1), BENCH_IRON)
	end
	for index, z in { -0.7, 0, 0.7 } do
		makePart(bench, "Seat", Vector3.new(6.4, 0.3, 0.55), cframe * CFrame.new(0, 1.75, z), if index == 2 then WOOD_DARK else WOOD_COLOR, Enum.Material.Wood)
	end
	for _, y in { 2.6, 3.4 } do
		makePart(bench, "Backrest", Vector3.new(6.4, 0.5, 0.25), cframe * CFrame.new(0, y, 1.15), WOOD_COLOR, Enum.Material.Wood)
	end
	bench.Parent = parent
end

-- A round, puffy tree: a trunk under a cluster of leafy balls, lighter on top.
local function buildPuffTree(parent: Instance, base: Vector3, scale: number, leaves: { Color3 })
	local tree = Instance.new("Model")
	tree.Name = "Tree"
	local trunk = 7 * scale
	makeCylinder(tree, "Trunk", 1.1 * scale, trunk + 2 * scale, base - Vector3.new(0, 1, 0), TRUNK_COLOR, Enum.Material.Wood)
	local top = base + Vector3.new(0, trunk, 0)
	local balls = {
		{ Vector3.new(0, 3, 0), 11, 1 },
		{ Vector3.new(3.4, 2, 1.6), 7.5, 1 },
		{ Vector3.new(-3.2, 2.2, -1.8), 7, 1 },
		{ Vector3.new(-0.6, 1.6, 3.4), 6.5, 1 },
		{ Vector3.new(1.2, 6.4, -0.8), 7.5, 2 },
		{ Vector3.new(-1.8, 5.6, 2), 6, 2 },
	}
	for _, ball in balls do
		makeBall(tree, "Leaves", (ball[2] :: number) * scale, top + (ball[1] :: Vector3) * scale, leaves[ball[3] :: number])
	end
	tree.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	tree.Parent = parent
end

-- A chunky, blocky tree in the style of the big simulator games.
local function buildBlockTree(parent: Instance, base: Vector3, scale: number, leaves: { Color3 })
	local tree = Instance.new("Model")
	tree.Name = "Tree"
	local turn = CFrame.Angles(0, random:NextNumber(0, math.pi), 0)
	local trunk = 8 * scale
	makePart(tree, "Trunk", Vector3.new(1.8, trunk + 1, 1.8) * Vector3.new(scale, 1, scale), CFrame.new(base + Vector3.new(0, trunk / 2 - 0.5, 0)) * turn, TRUNK_COLOR, Enum.Material.Wood)
	makePart(tree, "Root", Vector3.new(3, 1.2, 3) * scale, CFrame.new(base + Vector3.new(0, 0.3, 0)) * turn, TRUNK_COLOR, Enum.Material.Wood)
	local top = CFrame.new(base + Vector3.new(0, trunk, 0)) * turn
	makePart(tree, "Leaves", Vector3.new(10, 7, 10) * scale, top * CFrame.new(0, 2.5 * scale, 0), leaves[1])
	makePart(tree, "Leaves", Vector3.new(6.5, 4.5, 6.5) * scale, top * CFrame.new(0.8 * scale, 7.2 * scale, -0.6 * scale) * CFrame.Angles(0, 0.4, 0), leaves[2])
	makePart(tree, "Leaves", Vector3.new(5, 4, 5) * scale, top * CFrame.new(4.2 * scale, 1.6 * scale, 3 * scale) * CFrame.Angles(0, 0.7, 0), leaves[1])
	tree.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	tree.Parent = parent
end

local function buildTree(parent: Instance, base: Vector3)
	local leaves = LEAF_SETS[random:NextInteger(1, #LEAF_SETS)]
	local scale = random:NextNumber(0.85, 1.3)
	if random:NextNumber() < 0.5 then
		buildPuffTree(parent, base, scale, leaves)
	else
		buildBlockTree(parent, base, scale, leaves)
	end
end

local function flowerColor(): Color3
	return FLOWER_COLORS[random:NextInteger(1, #FLOWER_COLORS)]
end

-- A round bush dotted with flowers.
local function buildBush(parent: Instance, base: Vector3, scale: number?)
	local size = 6 * (scale or 1)
	makeBall(parent, "Bush", size, base + Vector3.new(0, size * 0.3, 0), LEAF_SETS[1][1])
	makeBall(parent, "Bush", size * 0.6, base + Vector3.new(size * 0.35, size * 0.2, size * 0.2), LEAF_SETS[1][2])
	local color = flowerColor()
	for index = 1, 6 do
		local angle = index / 6 * math.pi * 2
		local spot = base + Vector3.new(math.sin(angle) * size * 0.42, size * 0.45 + random:NextNumber(-0.4, 0.8), math.cos(angle) * size * 0.42)
		makeDecor(parent, "Flower", Vector3.one * 1.2, CFrame.new(spot), color).Shape = Enum.PartType.Ball
	end
end

-- A little patch of flowers in two colors, with a leafy tuft; on terrain, in a bed of
-- soil.
local function buildFlowers(parent: Instance, base: Vector3, onTerrain: boolean?)
	if onTerrain ~= false then
		paint(CFrame.new(base) * CFrame.Angles(0, random:NextNumber(0, math.pi), 0), Vector2.new(7, 7), Enum.Material.Ground)
	end
	local colors = { flowerColor(), flowerColor() }
	makeBall(parent, "Tuft", 2.2, base + Vector3.new(0, 0.2, 0), LEAF_SETS[2][2]).CanCollide = false
	for index = 1, 5 do
		local spot = base + Vector3.new(random:NextNumber(-2.6, 2.6), random:NextNumber(0.5, 1.1), random:NextNumber(-2.6, 2.6))
		makeDecor(parent, "Flower", Vector3.one * 0.9, CFrame.new(spot), colors[index % 2 + 1]).Shape = Enum.PartType.Ball
	end
end

local function buildRocks(parent: Instance, base: Vector3)
	local size = random:NextNumber(3, 6)
	makeBall(parent, "Rock", size, base + Vector3.new(0, size * 0.2, 0), ROCK_COLORS[1]).Material = Enum.Material.Slate
	makeBall(parent, "Rock", size * 0.6, base + Vector3.new(size * 0.55, 0, size * 0.2), ROCK_COLORS[2]).Material = Enum.Material.Slate
end

-- A toadstool or two: a cream stem under a red, white-spotted cap.
local function buildMushrooms(parent: Instance, base: Vector3)
	for index = 1, random:NextInteger(1, 3) do
		local spot = base + Vector3.new(random:NextNumber(-2, 2), 0, random:NextNumber(-2, 2))
		local scale = random:NextNumber(0.7, 1.3) * (if index == 1 then 1.3 else 1)
		makeCylinder(parent, "MushroomStem", 0.45 * scale, 1.6 * scale, spot, Color3.fromRGB(255, 245, 225))
		local capTop = spot + Vector3.new(0, 2.2 * scale, 0)
		makeCylinder(parent, "MushroomCap", 1.5 * scale, 0.8 * scale, capTop - Vector3.new(0, 0.6 * scale, 0), Color3.fromRGB(240, 70, 80))
		for dot = 1, 3 do
			local angle = dot / 3 * math.pi * 2
			makeDecor(parent, "MushroomDot", Vector3.one * 0.45 * scale, CFrame.new(capTop + Vector3.new(math.sin(angle), -0.4, math.cos(angle)) * scale * Vector3.new(0.8, 1, 0.8)), Color3.new(1, 1, 1)).Shape = Enum.PartType.Ball
		end
	end
end

local function buildBalloon(parent: Instance, position: Vector3)
	local color = BALLOON_COLORS[random:NextInteger(1, #BALLOON_COLORS)]
	local balloon = makeDecor(parent, "Balloon", Vector3.new(3.4, 4, 3.4), CFrame.new(position), color)
	balloon.Shape = Enum.PartType.Ball
	balloon.Reflectance = 0.15
	makeDecor(parent, "BalloonString", Vector3.new(0.08, 6, 0.08), CFrame.new(position - Vector3.new(0, 5, 0)), Color3.new(1, 1, 1))
end

-- By the water ---------------------------------------------------------------------------

local LILY_COLOR = Color3.fromRGB(70, 185, 90)
local REED_COLOR = Color3.fromRGB(80, 160, 70)
local CATTAIL_COLOR = Color3.fromRGB(140, 90, 60)
local DUCK_COLOR = Color3.fromRGB(255, 220, 50)
local BEAK_COLOR = Color3.fromRGB(255, 140, 40)

-- A see-through skin just over the water with the cartoon water texture, its V running
-- along `cframe`'s Z (the flow; -Z is downstream). Terrain water can't take a texture,
-- so this does. `along` is how far down the flow the stretch's middle is: each texture
-- is offset by it, so the pattern runs on seamlessly from one stretch to the next. The
-- client makes it drift (Atmosphere, tag "FlowingWater", Base and Drift attributes).
local function waterSkin(parent: Instance, cframe: CFrame, size: Vector2, along: number)
	local skin = makeDecor(parent, "WaterSkin", Vector3.new(size.X, 0.05, size.Y), cframe + Vector3.new(0, WATER_TOP + 0.08 - cframe.Y, 0), WATER_COLOR)
	skin.Transparency = 1
	skin.CastShadow = false
	for _, layer in WATER_LAYERS do
		local texture = Instance.new("Texture")
		texture.Texture = WATER_TEXTURE
		texture.Face = Enum.NormalId.Top
		texture.StudsPerTileU = layer.Tile
		texture.StudsPerTileV = layer.Tile
		texture.OffsetStudsU = layer.Shift
		texture.OffsetStudsV = along % layer.Tile
		texture.Transparency = layer.Transparency
		texture:SetAttribute("Base", along)
		texture:SetAttribute("Drift", layer.Drift)
		texture.Parent = skin
		CollectionService:AddTag(texture, "FlowingWater")
	end
end

-- Skins the plaza's river (in arcs), the streams (stretch by stretch) and the ponds.
local function skinWater(parent: Instance, streamAngles: { number })
	local middle = (RIVER_FROM + RIVER_TO) / 2
	local arcs = 72
	local arc = 2 * math.pi * middle / arcs
	for index = 1, arcs do
		local angle = (index - 0.5) / arcs * math.pi * 2
		local center = onGround(angle, middle)
		local along = Vector3.new(math.cos(angle), 0, -math.sin(angle)) -- around the ring
		waterSkin(parent, CFrame.lookAt(center, center + along), Vector2.new(RIVER_TO - RIVER_FROM + 8, arc), (index - 0.5) * arc)
	end
	for _, angle in streamAngles do
		local course = streamCourse(angle)
		local travelled = 0
		for index = 3, #course - 2, 2 do
			local from, to = course[index], course[index + 2]
			local length = (to - from).Magnitude
			waterSkin(parent, CFrame.lookAt((from + to) / 2, to), Vector2.new(24, length), travelled + length / 2)
			travelled += length
		end
		local pond = course[#course]
		waterSkin(parent, CFrame.new(pond) * CFrame.Angles(0, angle, 0), Vector2.new(POND_RADIUS * 2 + 6, POND_RADIUS * 2 + 6), 0)
	end
end

local function buildLilyPad(parent: Instance, position: Vector3)
	local radius = random:NextNumber(1.4, 2.6)
	makeCylinder(parent, "LilyPad", radius, 0.15, Vector3.new(position.X, WATER_TOP - 0.02, position.Z), LILY_COLOR).CanCollide = false
	if random:NextNumber() < 0.4 then
		local flower = makeDecor(parent, "LilyFlower", Vector3.one * 1.1, CFrame.new(position.X, WATER_TOP + 0.5, position.Z), if random:NextNumber() < 0.5 then FLOWER_COLORS[1] else Color3.new(1, 1, 1))
		flower.Shape = Enum.PartType.Ball
	end
end

-- A clump of reeds with brown cattail tops.
local function buildReeds(parent: Instance, base: Vector3)
	for _ = 1, random:NextInteger(3, 5) do
		local spot = base + Vector3.new(random:NextNumber(-1.2, 1.2), 0, random:NextNumber(-1.2, 1.2))
		local height = random:NextNumber(3, 5)
		local tilt = CFrame.Angles(random:NextNumber(-0.15, 0.15), 0, random:NextNumber(-0.15, 0.15))
		local stem = CFrame.new(spot) * tilt
		makeDecor(parent, "Reed", Vector3.new(0.25, height, 0.25), stem * CFrame.new(0, height / 2, 0), REED_COLOR)
		makeDecor(parent, "Cattail", Vector3.new(0.5, 1.1, 0.5), stem * CFrame.new(0, height - 0.3, 0), CATTAIL_COLOR)
	end
end

-- A big rubber duck bobbing on the water (it's a toy factory, after all).
local function buildDuck(parent: Instance, position: Vector3, facing: number)
	local duck = Instance.new("Model")
	duck.Name = "RubberDuck"
	local base = CFrame.new(position.X, WATER_TOP, position.Z) * CFrame.Angles(0, facing, 0)
	makeDecor(duck, "Body", Vector3.new(3.2, 2.4, 4), base * CFrame.new(0, 0.6, 0), DUCK_COLOR).Shape = Enum.PartType.Ball
	makeDecor(duck, "Head", Vector3.one * 2.2, base * CFrame.new(0, 2.3, -1.2), DUCK_COLOR).Shape = Enum.PartType.Ball
	makeDecor(duck, "Beak", Vector3.new(1.2, 0.5, 1), base * CFrame.new(0, 2.1, -2.4), BEAK_COLOR)
	makeDecor(duck, "Tail", Vector3.new(1.2, 1, 1), base * CFrame.new(0, 1.4, 1.9) * CFrame.Angles(0.5, 0, 0), DUCK_COLOR)
	for _, side in { -1, 1 } do
		makeDecor(duck, "Eye", Vector3.one * 0.45, base * CFrame.new(side * 0.65, 2.65, -2.1), Color3.fromRGB(30, 25, 45)).Shape = Enum.PartType.Ball
	end
	duck.Parent = parent
end

local function buildLog(parent: Instance, base: Vector3, turn: number)
	local length = random:NextNumber(6, 9)
	local log = makeCylinder(parent, "Log", 0.9, length, base, CATTAIL_COLOR, Enum.Material.Wood)
	log.CFrame = CFrame.new(base + Vector3.new(0, 0.6, 0)) * CFrame.Angles(0, turn, 0) -- lying down, along X
	for _, side in { -1, 1 } do
		local ring = makeDecor(parent, "LogEnd", Vector3.new(0.1, 1.7, 1.7), log.CFrame * CFrame.new(side * length / 2, 0, 0), Color3.fromRGB(235, 200, 150), Enum.Material.Wood)
		ring.Shape = Enum.PartType.Cylinder
	end
end

-- Lily pads, reeds, rocks, logs and ducks along a stream and around the plaza's river.
local function dressWater(parent: Instance, streamAngles: { number })
	skinWater(parent, streamAngles)
	for _, angle in streamAngles do
		local course = streamCourse(angle)
		for index = 6, #course - 1, 3 do
			local here = course[index]
			local across = (course[index + 1] - here).Unit:Cross(Vector3.yAxis)
			local side = if index % 2 == 0 then 1 else -1
			if random:NextNumber() < 0.7 then
				buildLilyPad(parent, here + across * random:NextNumber(-7, 7))
			end
			if index % 4 == 0 then
				buildReeds(parent, here + across * side * 13.5 + Vector3.new(0, -2, 0))
			elseif index % 9 == 0 then
				buildRocks(parent, here + across * side * 15 + Vector3.new(0, -2, 0))
			elseif index % 13 == 0 then
				buildLog(parent, here + across * side * 15 + Vector3.new(0, -2, 0), random:NextNumber(0, math.pi))
			end
		end
		-- The pond: lily pads, reeds around the bank, a duck family.
		local pond = course[#course]
		for _ = 1, 14 do
			buildLilyPad(parent, pond + onGround(random:NextNumber(0, math.pi * 2), random:NextNumber(8, POND_RADIUS - 6)))
		end
		for index = 1, 10 do
			buildReeds(parent, pond + onGround(index / 10 * math.pi * 2 + random:NextNumber(-0.1, 0.1), POND_RADIUS + 3) + Vector3.new(0, -2, 0))
		end
		for index = 1, 3 do
			buildDuck(parent, pond + onGround(angle + index * 0.6, 20 - index * 4), angle + index)
		end
	end
	-- The plaza's river.
	for index = 1, 40 do
		local angle = index / 40 * math.pi * 2 + random:NextNumber(-0.05, 0.05)
		buildLilyPad(parent, onGround(angle, random:NextNumber(RIVER_FROM + 3, RIVER_TO - 3)))
		if index % 3 == 0 then
			buildReeds(parent, onGround(angle + 0.04, RIVER_TO + 3) + Vector3.new(0, -2, 0))
		end
	end
	for index = 1, 4 do
		local angle = index / 4 * math.pi * 2 + 0.3
		buildDuck(parent, onGround(angle, (RIVER_FROM + RIVER_TO) / 2), angle + math.pi / 2)
	end
end

-- Between the factories --------------------------------------------------------------

local SHOWCASE = { "TungTungTungSahur", "BallerinaCappuccina", "BombardiroCrocodilo", "ChimpanziniBananini", "LaVacaSaturnoSaturnita", "SupremoBrainrotto" }
local BLOCK_COLORS = { Color3.fromRGB(255, 90, 90), Color3.fromRGB(80, 170, 255), Color3.fromRGB(255, 210, 50), Color3.fromRGB(110, 210, 90), Color3.fromRGB(190, 110, 255) }
local CHECKER_COLORS = { Color3.fromRGB(255, 90, 110), Color3.fromRGB(255, 255, 255) }

local SHOWCASE_SCALE = 2.2
local GOLD_COLOR = Color3.fromRGB(255, 215, 80)

-- A floating sign: the brainrot's name over its rarity, in the rarity's color.
local function nameSign(adornee: BasePart, height: number, name: string, rarity: string, color: Color3)
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromScale(14, 4)
	gui.StudsOffset = Vector3.new(0, height, 0)
	gui.MaxDistance = 160
	gui.LightInfluence = 0
	gui.Parent = adornee
	for index, text in { name, rarity } do
		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, if index == 1 then 0.6 else 0.4)
		label.Position = UDim2.fromScale(0, if index == 1 then 0 else 0.6)
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.FredokaOne
		label.TextScaled = true
		label.TextColor3 = if index == 1 then Color3.new(1, 1, 1) else color
		label.Text = text
		label.Parent = gui
		local stroke = Instance.new("UIStroke")
		stroke.Thickness = 3
		stroke.Color = Color3.fromRGB(40, 30, 60)
		stroke.Parent = label
	end
end

-- A showcase: a brainrot on a two-tier pedestal trimmed in its rarity's color, under a
-- floating name sign, with sparkles, four glowing orbs on posts and a ring of flowers
-- around it. The client spins the statue slowly (tag "SpinningStatue").
local function buildShowcase(parent: Instance, base: Vector3, brainrotId: string, facing: number)
	local info = Brainrots.ById[brainrotId]
	local rarity = info and Rarities.ById[info.Rarity]
	if not (info and rarity) then
		return
	end
	local color = if rarity.Id == "Godly" then GOLD_COLOR else rarity.Color
	local spot = Instance.new("Model")
	spot.Name = "ShowcaseSpot"
	makeCylinder(spot, "PedestalBase", 8, 1.2, base, STONE_COLOR, Enum.Material.Marble)
	makeCylinder(spot, "PedestalRing", 8.5, 0.5, base + Vector3.new(0, 0.9, 0), color)
	makeCylinder(spot, "Pedestal", 5.5, 3.2, base + Vector3.new(0, 1.2, 0), STONE_COLOR, Enum.Material.Marble)
	local top = makeCylinder(spot, "PedestalTop", 6, 0.6, base + Vector3.new(0, 4.4, 0), color, Enum.Material.Neon)

	local statue = Instance.new("Model")
	statue.Name = "Showcase"
	for _, partType in Brainrots.PartTypes do
		BrainrotModels.CreatePart(brainrotId, partType).Parent = statue
	end
	statue.WorldPivot = CFrame.identity
	statue:ScaleTo(SHOWCASE_SCALE)
	statue:PivotTo(CFrame.new(base + Vector3.new(0, 5, 0)) * CFrame.Angles(0, facing, 0))
	CollectionService:AddTag(statue, "SpinningStatue")
	statue.Parent = spot
	local _, size = statue:GetBoundingBox()
	nameSign(top, size.Y + 4, info.Name, string.upper(rarity.Id), color)

	local attachment = Instance.new("Attachment")
	-- The top is a cylinder turned on its side: its local X is world up, so turn the
	-- attachment back upright (particles fly along its Y).
	attachment.CFrame = CFrame.new(0.4, 0, 0) * CFrame.Angles(0, 0, -math.pi / 2)
	attachment.Parent = top
	local sparkles = Instance.new("ParticleEmitter")
	sparkles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	sparkles.Color = ColorSequence.new(color:Lerp(Color3.new(1, 1, 1), 0.3))
	sparkles.LightEmission = 0.6
	sparkles.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.8), NumberSequenceKeypoint.new(1, 0) })
	sparkles.Lifetime = NumberRange.new(1.5, 2.5)
	sparkles.Rate = 8
	sparkles.Speed = NumberRange.new(2, 4)
	sparkles.SpreadAngle = Vector2.new(60, 60)
	sparkles.Acceleration = Vector3.new(0, 1.5, 0)
	sparkles.Parent = attachment

	for index = 1, 4 do
		local post = base + onGround(facing + math.pi / 4 + index * math.pi / 2, 10.5)
		makeCylinder(spot, "OrbPost", 0.35, 4, post, Color3.new(1, 1, 1))
		local orb = makeBall(spot, "Orb", 1.6, post + Vector3.new(0, 4.6, 0), color)
		orb.Material = Enum.Material.Neon
		orb.CanCollide = false
		local light = Instance.new("PointLight")
		light.Color = color
		light.Range = 10
		light.Brightness = 0.8
		light.Shadows = false
		light.Parent = orb
	end
	for index = 1, 8 do
		local angle = facing + index / 8 * math.pi * 2
		for petal = 1, 3 do
			local spotOnRing = base + onGround(angle + petal * 0.07, 13) + Vector3.new(0, 0.5 + petal * 0.15, 0)
			makeDecor(spot, "Flower", Vector3.one * 1.2, CFrame.new(spotOnRing), FLOWER_COLORS[(index + petal) % #FLOWER_COLORS + 1]).Shape = Enum.PartType.Ball
		end
	end
	spot.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	spot.Parent = parent
end

-- A short white picket fence along `from` → `to`.
local function buildFence(parent: Instance, from: Vector3, to: Vector3)
	local length = (to - from).Magnitude
	local along = (to - from).Unit
	for _, y in { 1.2, 2.4 } do
		makeSlab(parent, "FenceRail", from + Vector3.new(0, y + 0.2, 0), to + Vector3.new(0, y + 0.2, 0), 0.25, 0.4, CURB_COLOR)
	end
	for step = 0, math.floor(length / 1.5) do
		local spot = from + along * step * 1.5
		makePart(parent, "Picket", Vector3.new(0.5, 3.2, 0.25), CFrame.lookAt(spot + Vector3.new(0, 1.6, 0), spot + Vector3.new(0, 1.6, 0) + along), CURB_COLOR)
	end
end

-- A picnic spot: a checkered blanket, a basket, and a little table.
local function buildPicnic(parent: Instance, base: Vector3, turn: number)
	local origin = CFrame.new(base) * CFrame.Angles(0, turn, 0)
	for x = 0, 3 do
		for z = 0, 3 do
			makeDecor(parent, "Blanket", Vector3.new(2, 0.1, 2), origin * CFrame.new(-3 + x * 2, 0.08, -3 + z * 2), CHECKER_COLORS[(x + z) % 2 + 1], Enum.Material.Fabric)
		end
	end
	makePart(parent, "Basket", Vector3.new(2, 1.4, 1.4), origin * CFrame.new(1.5, 0.8, 0.5), WOOD_COLOR, Enum.Material.WoodPlanks)
	makeDecor(parent, "BasketHandle", Vector3.new(2, 0.3, 0.3), origin * CFrame.new(1.5, 1.9, 0.5), WOOD_DARK)
	makeBall(parent, "Apple", 0.7, (origin * CFrame.new(-1, 0.45, 1)).Position, Color3.fromRGB(240, 60, 70))
	makeBall(parent, "Apple", 0.7, (origin * CFrame.new(-0.4, 0.45, 1.6)).Position, Color3.fromRGB(120, 210, 80))
	-- the table, beside the blanket
	local picnicTable = origin * CFrame.new(0, 0, 8)
	makePart(parent, "PicnicTable", Vector3.new(7, 0.4, 3.4), picnicTable * CFrame.new(0, 2.6, 0), WOOD_COLOR, Enum.Material.WoodPlanks)
	for _, z in { -2.6, 2.6 } do
		makePart(parent, "PicnicSeat", Vector3.new(7, 0.3, 1), picnicTable * CFrame.new(0, 1.5, z), WOOD_COLOR, Enum.Material.WoodPlanks)
	end
	for _, x in { -2.8, 2.8 } do
		makePart(parent, "PicnicLeg", Vector3.new(0.4, 2.6, 5.6), picnicTable * CFrame.new(x, 1.3, 0), WOOD_DARK, Enum.Material.Wood)
	end
end

-- A little fenced garden: white pickets around a square of flowers and a bush.
local function buildGarden(parent: Instance, base: Vector3, turn: number)
	local origin = CFrame.new(base) * CFrame.Angles(0, turn, 0)
	local corners = {}
	for _, corner in { Vector2.new(-1, -1), Vector2.new(1, -1), Vector2.new(1, 1), Vector2.new(-1, 1) } do
		table.insert(corners, (origin * CFrame.new(corner.X * 7, 0, corner.Y * 7)).Position)
	end
	for index = 1, 4 do
		if index ~= 1 then -- the front stays open, like a gate
			buildFence(parent, corners[index], corners[index % 4 + 1])
		end
	end
	buildBush(parent, base, 0.8)
	for _, offset in { Vector3.new(-4, 0, -4), Vector3.new(4, 0, 4), Vector3.new(4, 0, -4), Vector3.new(-4, 0, 4) } do
		buildFlowers(parent, (origin * CFrame.new(offset)).Position)
	end
end

-- A stack of giant toy blocks with letters.
local function buildToyBlocks(parent: Instance, base: Vector3, turn: number)
	local letters = { "A", "B", "C", "★", "♥" }
	local spots = { Vector3.new(-2.2, 2, 0), Vector3.new(2.2, 2, 0.4), Vector3.new(0, 6, 0.2) }
	for index, offset in spots do
		local block = makePart(parent, "ToyBlock", Vector3.one * 4, CFrame.new(base + offset) * CFrame.Angles(0, turn + index * 0.3, 0), BLOCK_COLORS[random:NextInteger(1, #BLOCK_COLORS)])
		for _, face in { Enum.NormalId.Front, Enum.NormalId.Back, Enum.NormalId.Left, Enum.NormalId.Right } do
			local gui = Instance.new("SurfaceGui")
			gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
			gui.PixelsPerStud = 30 -- scaled text tops out at 100 px: this lets it fill the face
			gui.Face = face
			gui.LightInfluence = 0
			gui.Parent = block
			local label = Instance.new("TextLabel")
			label.Size = UDim2.fromScale(0.8, 0.8)
			label.Position = UDim2.fromScale(0.1, 0.1)
			label.BackgroundTransparency = 1
			label.Font = Enum.Font.FredokaOne
			label.TextScaled = true
			label.TextColor3 = Color3.new(1, 1, 1)
			label.Text = letters[random:NextInteger(1, #letters)]
			label.Parent = gui
			local stroke = Instance.new("UIStroke")
			stroke.Thickness = 3
			stroke.Color = Color3.fromRGB(40, 30, 60)
			stroke.Parent = label
		end
	end
end

-- A giant swirly lollipop stuck in the grass.
local function buildLollipop(parent: Instance, base: Vector3, turn: number)
	local height = random:NextNumber(8, 12)
	makeCylinder(parent, "LollipopStick", 0.35, height, base, Color3.new(1, 1, 1))
	local center = CFrame.new(base + Vector3.new(0, height + 2.6, 0)) * CFrame.Angles(0, turn, 0)
	local colors = { BLOCK_COLORS[random:NextInteger(1, #BLOCK_COLORS)], Color3.new(1, 1, 1) }
	-- Rings of candy, each smaller one a touch thicker so it shows on both faces.
	for ring = 1, 4 do
		local disc = makeDecor(parent, "Lollipop", Vector3.new(0.8 + ring * 0.06, (5 - ring) * 1.4, (5 - ring) * 1.4), center * CFrame.Angles(0, math.pi / 2, 0), colors[ring % 2 + 1])
		disc.Shape = Enum.PartType.Cylinder
	end
end

-- Life between the factories ------------------------------------------------------------
-- The gaps between the factories looked empty, flat and still (the user, 2026-10-02):
-- each gets a striped tulip field on dark soil, a windmill turning on its big hill (or by
-- the pond), a grove of blossom and golden trees, butterflies over the flowers and birds
-- circling above; hot air balloons drift round the whole valley. The motion is
-- client-side (Atmosphere): Spinners turn about their pivot's Z, and Butterfly models
-- flutter round their Home.

local TULIP_COLORS = {
	Color3.fromRGB(255, 60, 90),
	Color3.fromRGB(255, 210, 40),
	Color3.fromRGB(255, 110, 190),
	Color3.fromRGB(150, 90, 255),
	Color3.fromRGB(255, 130, 40),
	Color3.fromRGB(255, 255, 255),
}
local BUTTERFLY_COLORS = {
	Color3.fromRGB(255, 120, 200),
	Color3.fromRGB(255, 215, 60),
	Color3.fromRGB(110, 200, 255),
	Color3.fromRGB(190, 130, 255),
	Color3.fromRGB(255, 150, 70),
}
local HOT_AIR_COLORS = {
	{ Color3.fromRGB(255, 90, 120), Color3.fromRGB(255, 215, 60) },
	{ Color3.fromRGB(80, 175, 255), Color3.fromRGB(255, 255, 255) },
	{ Color3.fromRGB(160, 100, 255), Color3.fromRGB(255, 150, 210) },
	{ Color3.fromRGB(255, 140, 50), Color3.fromRGB(90, 220, 140) },
	{ Color3.fromRGB(255, 215, 60), Color3.fromRGB(255, 90, 160) },
}
local WINDMILL_WALL = Color3.fromRGB(255, 250, 240)
local WINDOW_BLUE = Color3.fromRGB(120, 200, 255)
local BIRD_COLOR = Color3.fromRGB(70, 75, 120)

-- Makes `model` turn about `pivot`'s Z axis at `speed` radians per second (Atmosphere).
local function spin(model: Model, pivot: CFrame, speed: number)
	model.WorldPivot = pivot
	model:SetAttribute("Speed", speed)
	CollectionService:AddTag(model, "Spinner")
end

local function decorBall(parent: Instance, name: string, diameter: number, cframe: CFrame, color: Color3, material: Enum.Material?): Part
	local ball = makeDecor(parent, name, Vector3.one * diameter, cframe, color, material)
	ball.Shape = Enum.PartType.Ball
	return ball
end

-- A disc or drum: a cylinder `across` wide and `depth` deep, its axis along `cframe`'s Z.
local function decorDisc(parent: Instance, name: string, across: number, depth: number, cframe: CFrame, color: Color3, material: Enum.Material?): Part
	local disc = makeDecor(parent, name, Vector3.new(depth, across, across), cframe * CFrame.Angles(0, math.pi / 2, 0), color, material)
	disc.Shape = Enum.PartType.Cylinder
	return disc
end

-- A field of tulips (`base`: its middle, turned by `turn`): rows of one color each on
-- dark soil, every row a different color, like the bulb fields in Holland, over hedges
-- of leaves.
local FIELD_ROWS, FIELD_LENGTH, ROW_SPACING = 9, 34, 3.6
local FIELD_RADIUS = 25 -- what it claims
local TULIP_SIZE = Vector3.new(1.5, 1.6, 1.5) -- the cup

-- A tulip (`at`: the cup's middle): an egg-shaped cup with two pointed petals rising
-- from its rim, a V between them. Turn each one at random: the points show from the side.
local function buildTulip(parent: Instance, at: CFrame, color: Color3)
	local cup = makeDecor(parent, "Tulip", TULIP_SIZE, at, color)
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = cup
	for _, turn in { 0, math.pi } do
		local petal = Instance.new("WedgePart")
		petal.Name = "TulipPetal"
		petal.Anchored = true
		petal.CanCollide = false
		petal.CanQuery = false
		petal.CanTouch = false
		petal.Color = color
		petal.Material = Enum.Material.SmoothPlastic
		petal.Size = Vector3.new(TULIP_SIZE.X * 0.8, 0.9, TULIP_SIZE.Z / 2)
		-- its tall face outward, sloping down to the notch in the middle
		petal.CFrame = at * CFrame.Angles(0, turn, 0) * CFrame.new(0, 0.85, TULIP_SIZE.Z / 4)
		petal.Parent = parent
	end
end

local function buildTulipField(parent: Instance, base: Vector3, turn: number)
	local origin = CFrame.new(base) * CFrame.Angles(0, turn, 0)
	paint(origin, Vector2.new(FIELD_ROWS * ROW_SPACING + 3, FIELD_LENGTH + 4), Enum.Material.Ground)
	local field = Instance.new("Model")
	field.Name = "TulipField"
	local first = random:NextInteger(0, #TULIP_COLORS - 1)
	local count = math.floor(FIELD_LENGTH / 2.6)
	for row = 0, FIELD_ROWS - 1 do
		local x = (row - (FIELD_ROWS - 1) / 2) * ROW_SPACING
		local color = TULIP_COLORS[(first + row) % #TULIP_COLORS + 1]
		makeDecor(field, "TulipLeaves", Vector3.new(2, 1.4, FIELD_LENGTH), origin * CFrame.new(x, 0.7, 0), LEAF_SETS[2][1])
		for k = 0, count - 1 do
			local z = -FIELD_LENGTH / 2 + (k + 0.5) * FIELD_LENGTH / count
			local at = origin * CFrame.new(x + random:NextNumber(-0.2, 0.2), 2.1 + random:NextNumber(-0.2, 0.3), z)
			buildTulip(field, at * CFrame.Angles(0, random:NextNumber(0, math.pi), 0), color)
		end
	end
	field.Parent = parent
end

-- A butterfly (a body and two wings) that flutters round `home` (Atmosphere).
local function buildButterfly(parent: Instance, home: Vector3)
	local fly = Instance.new("Model")
	fly.Name = "Butterfly"
	local color = BUTTERFLY_COLORS[random:NextInteger(1, #BUTTERFLY_COLORS)]
	makeDecor(fly, "Body", Vector3.new(0.35, 0.35, 1.3), CFrame.new(home), Color3.fromRGB(60, 45, 70)).CastShadow = false
	for _, side in { -1, 1 } do
		makeDecor(fly, if side < 0 then "WingLeft" else "WingRight", Vector3.new(1.7, 0.1, 1.7), CFrame.new(home + Vector3.new(side * 0.9, 0, 0)), color).CastShadow = false
	end
	fly:SetAttribute("Home", home)
	fly:SetAttribute("Phase", random:NextNumber(0, math.pi * 2))
	fly.ModelStreamingMode = Enum.ModelStreamingMode.Atomic -- the client needs all three parts
	CollectionService:AddTag(fly, "Butterfly")
	fly.Parent = parent
end

-- A windmill (`base`: on the ground; -Z of `facing` toward the hub): a white tower in
-- three tiers banded in `color`, a door and round windows, a pointy cap in `color`, and
-- four sails turning on the front.
local function buildWindmill(parent: Instance, base: Vector3, facing: number, color: Color3)
	local mill = Instance.new("Model")
	mill.Name = "Windmill"
	local origin = CFrame.new(base) * CFrame.Angles(0, facing, 0)
	local tiers = { { 11, 0, 8 }, { 9.4, 8, 7 }, { 8, 15, 6 } } -- { across, bottom, height }
	for _, tier in tiers do
		makeCylinder(mill, "WindmillTower", tier[1] / 2, tier[3], base + Vector3.new(0, tier[2], 0), WINDMILL_WALL)
		-- (the band's top a hair under the tier's, or the ledge flickers)
		makeCylinder(mill, "WindmillBand", tier[1] / 2 + 0.2, 0.8, base + Vector3.new(0, tier[2] + tier[3] - 0.85, 0), color)
	end
	makeDecor(mill, "WindmillDoor", Vector3.new(3, 5, 0.8), origin * CFrame.new(0, 2.5, -5.2), WOOD_DARK, Enum.Material.Wood)
	for _, y in { 11.5, 17.8 } do
		local depth = if y < 15 then -4.6 else -3.9
		decorDisc(mill, "WindmillWindowFrame", 2.8, 0.4, origin * CFrame.new(0, y, depth), Color3.new(1, 1, 1))
		decorDisc(mill, "WindmillWindow", 2.1, 0.5, origin * CFrame.new(0, y, depth), WINDOW_BLUE)
	end
	-- the cap: rings narrowing to a point, and a knob
	for index, ring in { { 9.4, 1.6 }, { 7, 1.5 }, { 4.6, 1.4 }, { 2.2, 1.2 } } do
		makeCylinder(mill, "WindmillCap", ring[1] / 2, ring[2], base + Vector3.new(0, 21 + (index - 1) * 1.5, 0), color)
	end
	decorBall(mill, "WindmillKnob", 1.4, CFrame.new(base + Vector3.new(0, 27.4, 0)), Color3.new(1, 1, 1))
	-- the sails, on an axle out of the front of the top tier
	local axle = origin * CFrame.new(0, 18.5, -6.6)
	decorDisc(mill, "WindmillAxle", 1, 3, origin * CFrame.new(0, 18.5, -5), WOOD_DARK)
	local sails = Instance.new("Model")
	sails.Name = "WindmillSails"
	decorBall(sails, "SailHub", 2.2, axle, color)
	for k = 0, 3 do
		local arm = axle * CFrame.Angles(0, 0, k * math.pi / 2 + math.pi / 4)
		makeDecor(sails, "SailSpar", Vector3.new(0.6, 15, 0.6), arm * CFrame.new(0, 7.5, 0), WOOD_DARK, Enum.Material.Wood)
		makeDecor(sails, "Sail", Vector3.new(3.4, 10, 0.2), arm * CFrame.new(2, 9.5, -0.3), if k % 2 == 0 then color else Color3.new(1, 1, 1), Enum.Material.Fabric)
	end
	spin(sails, axle, 0.7)
	sails.Parent = mill
	mill.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	mill.Parent = parent
end

-- A grove of blossom and golden trees (with a green one or two) round `center`.
local function buildGrove(parent: Instance, center: Vector3, count: number)
	local sets = { LEAF_SETS[3], LEAF_SETS[4], LEAF_SETS[3], LEAF_SETS[1] }
	for index = 1, count do
		local angle = index / count * math.pi * 2 + random:NextNumber(-0.3, 0.3)
		local spot = center + onGround(angle, random:NextNumber(5, 14))
		local at = groundAt(spot.X, spot.Z)
		if at then
			local leaves = sets[index % #sets + 1]
			if random:NextNumber() < 0.5 then
				buildPuffTree(parent, at, random:NextNumber(0.9, 1.3), leaves)
			else
				buildBlockTree(parent, at, random:NextNumber(0.9, 1.3), leaves)
			end
		end
	end
	buildFlowers(parent, center)
end

-- A flock of birds circling over `center` (a Spinner about the upright).
local function buildFlock(parent: Instance, center: Vector3, count: number)
	local flock = Instance.new("Model")
	flock.Name = "Flock"
	for index = 1, count do
		local angle = index / count * math.pi * 1.2
		local at = center + onGround(angle, 22 + random:NextNumber(-4, 6)) + Vector3.new(0, random:NextNumber(-3, 3), 0)
		local heading = Vector3.new(math.cos(angle), 0, -math.sin(angle)) -- along the circle, the way it turns
		local bird = CFrame.lookAt(at, at + heading)
		makeDecor(flock, "Bird", Vector3.new(0.6, 0.6, 1.6), bird, BIRD_COLOR).CastShadow = false
		for _, side in { -1, 1 } do
			makeDecor(flock, "BirdWing", Vector3.new(2.6, 0.15, 0.9), bird * CFrame.Angles(0, 0, side * math.rad(18)) * CFrame.new(side * 1.3, 0, 0), BIRD_COLOR).CastShadow = false
		end
	end
	-- the pivot's Z points down, so a negative speed turns it the way the birds face
	spin(flock, CFrame.new(center) * CFrame.Angles(math.pi / 2, 0, 0), -0.3)
	flock.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	flock.Parent = parent
end

-- A hot air balloon that drifts round the valley at `height`, `radius` from the hub (a
-- Spinner about the hub's upright): a striped envelope, ropes, a wicker basket and a
-- burner flame.
local function buildHotAirBalloon(parent: Instance, radius: number, height: number, angle: number, speed: number, colors: { Color3 })
	local balloon = Instance.new("Model")
	balloon.Name = "HotAirBalloon"
	local center = onGround(angle, radius) + Vector3.new(0, height, 0)
	local size = 22
	decorBall(balloon, "Envelope", size, CFrame.new(center), colors[1]).CastShadow = false
	for _, y in { -4, 0, 4 } do
		local across = math.sqrt((size / 2) ^ 2 - y ^ 2) * 2 + 0.3
		local band = makeDecor(balloon, "EnvelopeBand", Vector3.new(1.4, across, across), CFrame.new(center + Vector3.new(0, y, 0)) * CFrame.Angles(0, 0, math.pi / 2), colors[2])
		band.Shape = Enum.PartType.Cylinder
		band.CastShadow = false
	end
	decorBall(balloon, "EnvelopeCap", 7, CFrame.new(center + Vector3.new(0, 8.6, 0)), colors[2]).CastShadow = false
	local skirt = makeDecor(balloon, "Skirt", Vector3.new(4, 7, 7), CFrame.new(center + Vector3.new(0, -11.5, 0)) * CFrame.Angles(0, 0, math.pi / 2), colors[1])
	skirt.Shape = Enum.PartType.Cylinder
	local basketTop = center + Vector3.new(0, -19, 0)
	for k = 0, 3 do
		local a = k * math.pi / 2 + math.pi / 4
		local top = center + Vector3.new(math.cos(a) * 3.2, -13.5, math.sin(a) * 3.2)
		local bottom = basketTop + Vector3.new(math.cos(a) * 2, 0, math.sin(a) * 2)
		makeDecor(balloon, "Rope", Vector3.new(0.2, 0.2, (top - bottom).Magnitude), CFrame.lookAt((top + bottom) / 2, bottom), WOOD_DARK)
	end
	makeDecor(balloon, "Basket", Vector3.new(4.4, 3.2, 4.4), CFrame.new(basketTop - Vector3.new(0, 1.6, 0)), WOOD_COLOR, Enum.Material.WoodPlanks)
	makeDecor(balloon, "BasketRim", Vector3.new(4.8, 0.5, 4.8), CFrame.new(basketTop), WOOD_DARK)
	decorBall(balloon, "Flame", 1.6, CFrame.new(center + Vector3.new(0, -15, 0)), Color3.fromRGB(255, 170, 50), Enum.Material.Neon)
	spin(balloon, CFrame.new(0, height, 0) * CFrame.Angles(math.pi / 2, 0, 0), speed)
	balloon.ModelStreamingMode = Enum.ModelStreamingMode.Persistent -- part of the sky, seen from everywhere
	balloon.Parent = parent
end

-- The island and its fountain ----------------------------------------------------------

-- The starter brainrot, built from its four parts and blown up to a giant statue.
local function buildStatue(parent: Instance, base: Vector3)
	if not Brainrots.ById[STATUE_ID] then
		return
	end
	local statue = Instance.new("Model")
	statue.Name = "Statue"
	for _, partType in Brainrots.PartTypes do
		BrainrotModels.CreatePart(STATUE_ID, partType).Parent = statue
	end
	statue.WorldPivot = CFrame.identity
	statue:ScaleTo(STATUE_SCALE)
	statue:PivotTo(CFrame.new(base))
	statue.ModelStreamingMode = Enum.ModelStreamingMode.Persistent -- a landmark you see from anywhere
	statue.Parent = parent
end

local function buildFountain(parent: Instance)
	local fountain = Instance.new("Model")
	fountain.Name = "Fountain"
	-- The basin is solid; the water sits just above its rim, so it looks full to the brim.
	makeCylinder(fountain, "Basin", FOUNTAIN_RADIUS, 2.6, Vector3.zero, STONE_COLOR, Enum.Material.Marble)
	makeCylinder(fountain, "BasinTrim", FOUNTAIN_RADIUS + 0.6, 0.8, Vector3.new(0, 2.2, 0), PAVING_ACCENT)
	local water = makeCylinder(fountain, "Water", FOUNTAIN_RADIUS - 1.5, 0.1, Vector3.new(0, 3, 0), FOUNTAIN_WATER)
	water.Transparency = 0.15
	water.Reflectance = 0.2
	water.CanCollide = false
	makeCylinder(fountain, "Pedestal", 6, 7, Vector3.new(0, 2.6, 0), STONE_COLOR, Enum.Material.Marble)
	makeCylinder(fountain, "PedestalCap", 7, 1, Vector3.new(0, 9.6, 0), PAVING_ACCENT)

	-- Jets of water arcing out from under the cap into the basin. The jets hang off an
	-- unrotated anchor (the cylinders are turned on their side).
	local anchor = makeDecor(fountain, "JetAnchor", Vector3.one, CFrame.new(0, 10, 0), FOUNTAIN_WATER)
	anchor.Transparency = 1
	for index = 1, 6 do
		local angle = index / 6 * math.pi * 2
		local origin = Vector3.new(math.sin(angle) * 7, 0, math.cos(angle) * 7)
		local direction = Vector3.new(math.sin(angle), 1.6, math.cos(angle))
		local attachment = Instance.new("Attachment")
		-- Particles fly along the attachment's +Y, so turn its look direction up into Y.
		attachment.CFrame = CFrame.lookAt(origin, origin + direction) * CFrame.Angles(-math.pi / 2, 0, 0)
		attachment.Parent = anchor
		local jet = Instance.new("ParticleEmitter")
		jet.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		jet.Color = ColorSequence.new(Color3.fromRGB(200, 240, 255))
		jet.LightEmission = 0.4
		jet.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 0.3) })
		jet.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 0.6) })
		jet.Lifetime = NumberRange.new(0.9, 1.1)
		jet.Rate = 40
		jet.Speed = NumberRange.new(14, 16)
		jet.SpreadAngle = Vector2.new(4, 4)
		jet.Acceleration = Vector3.new(0, -40, 0)
		jet.Parent = attachment
	end

	fountain.Parent = parent
	buildStatue(parent, Vector3.new(0, 10.6, 0))
end

-- A round planter on the plaza: a white rim around soil, with a little tree and flowers.
local function buildPlanter(parent: Instance, base: Vector3)
	makeCylinder(parent, "Planter", 7, 1.6, base, CURB_COLOR)
	makeCylinder(parent, "PlanterSoil", 6.2, 0.2, base + Vector3.new(0, 1.5, 0), Color3.fromRGB(150, 105, 75))
	buildPuffTree(parent, base + Vector3.new(0, 1.6, 0), 0.6, LEAF_SETS[random:NextInteger(1, #LEAF_SETS)])
	for index = 1, 8 do
		local angle = index / 8 * math.pi * 2
		local spot = base + Vector3.new(math.sin(angle) * 4.8, 2.1, math.cos(angle) * 4.8)
		makeDecor(parent, "Flower", Vector3.one * 1.1, CFrame.new(spot), FLOWER_COLORS[index % #FLOWER_COLORS + 1]).Shape = Enum.PartType.Ball
	end
end

local TENT_COLORS = { Color3.fromRGB(255, 120, 190), Color3.fromRGB(255, 255, 255) }
local TENT_EDGE = 52 -- the canopy's rim, above the statue's head
local TENT_TOP = 76
local TENT_RADIUS = 36

-- A carousel-style striped tent over the fountain, the hub's landmark (like the big
-- tent in Adopt Me's center): striped canvas with a scalloped valance, candy-striped
-- poles between the carpets, and a golden ball and pennant on top.
local function buildTent(parent: Instance, plotAngles: { number })
	local tent = Instance.new("Model")
	tent.Name = "Tent"
	local apex = Vector3.new(0, TENT_TOP, 0)
	local gap = math.pi / #plotAngles
	local slices = #plotAngles * 3
	for index = 1, slices do
		local from = plotAngles[1] + gap + (index - 1) / slices * math.pi * 2
		local to = from + math.pi * 2 / slices
		local rim = Vector3.new(0, TENT_EDGE, 0)
		makeTriangle(tent, apex, onGround(from, TENT_RADIUS) + rim, onGround(to, TENT_RADIUS) + rim, TENT_COLORS[index % 2 + 1])
		-- a round scallop hanging off the rim, in the other color
		local middle = onGround((from + to) / 2, TENT_RADIUS * math.cos(math.pi / slices)) + rim - Vector3.new(0, 1.6, 0)
		local outward = onGround((from + to) / 2, 1)
		local scallop = makeDecor(tent, "Scallop", Vector3.new(0.3, 6.6, 6.6), CFrame.lookAt(middle, middle + outward) * CFrame.Angles(0, math.pi / 2, 0), TENT_COLORS[(index + 1) % 2 + 1], Enum.Material.Fabric)
		scallop.Shape = Enum.PartType.Cylinder
	end
	for _, angle in plotAngles do
		local base = onGround(angle + gap, TENT_RADIUS - 4) + Vector3.new(0, PATH_TOP, 0)
		local height = TENT_EDGE + 3 - PATH_TOP
		makeCylinder(tent, "Pole", 0.9, height, base, CURB_COLOR)
		for y = 3, height - 3, 5 do
			local stripe = makeCylinder(tent, "PoleStripe", 1.05, 1.8, base + Vector3.new(0, y, 0), TENT_COLORS[1])
			stripe.CanCollide = false
		end
	end
	makeBall(tent, "TentTop", 3.4, apex + Vector3.new(0, 1.2, 0), GOLD_COLOR).CanCollide = false
	makeCylinder(tent, "FlagPole", 0.25, 9, apex, CURB_COLOR).CanCollide = false
	local flagTop = apex + Vector3.new(0, 8.8, 0)
	makeTriangle(tent, flagTop, flagTop - Vector3.new(0, 3, 0), flagTop + Vector3.new(5, -1.5, 0), TENT_COLORS[1])
	tent.ModelStreamingMode = Enum.ModelStreamingMode.Persistent -- a landmark you see from anywhere
	tent.Parent = parent
end

-- A string of little triangle flags sagging between two points.
local function buildBunting(parent: Instance, from: Vector3, to: Vector3, sag: number, colors: { Color3 })
	local count = 8
	local points = {}
	for index = 0, count do
		local t = index / count
		table.insert(points, from:Lerp(to, t) - Vector3.new(0, sag * 4 * t * (1 - t), 0))
	end
	for index = 1, count do
		local a, b = points[index], points[index + 1]
		makeSlab(parent, "BuntingRope", a, b, 0.12, 0.12, CURB_COLOR).CanCollide = false
		local left, right = a:Lerp(b, 0.15), a:Lerp(b, 0.85)
		makeTriangle(parent, left, right, (left + right) / 2 - Vector3.new(0, 2.2, 0), colors[index % #colors + 1])
	end
end

-- A low hedge dotted with flowers, curving along the plaza's rim from `from` to `to`.
local function buildHedge(parent: Instance, radius: number, from: number, to: number)
	local pieces = math.max(1, math.floor((to - from) * radius / 7))
	for index = 1, pieces do
		local a0 = from + (index - 1) / pieces * (to - from)
		local a1 = from + index / pieces * (to - from)
		local p0, p1 = onGround(a0, radius), onGround(a1, radius)
		local middle = (p0 + p1) / 2 + Vector3.new(0, PATH_TOP + 1.1, 0)
		makePart(parent, "Hedge", Vector3.new(2.6, 2.2, (p1 - p0).Magnitude + 0.6), CFrame.lookAt(middle, middle + (p1 - p0)), LEAF_SETS[2][1])
		makeDecor(parent, "Flower", Vector3.one * 0.9, CFrame.new(middle + Vector3.new(0, 1.2, 0)), flowerColor()).Shape = Enum.PartType.Ball
	end
end

-- The big round plaza, a stone platform over the island's sand: layered discs of cartoon
-- tiles (each smaller one a hair higher, so they ring without flickering), the fountain
-- in a mint circle under a striped tent, and a flagstone carpet in each factory's color
-- running from the circle out to its bridge, between lamps hung with bunting. Hedges
-- line the rim between the carpets; benches, bushes, planters and flowers fill in.
local function buildPlaza(parent: Instance, plots: { TycoonManager.Plot }, plotAngles: { number })
	local function disc(name: string, radius: number, top: number, color: Color3)
		local part = makeCylinder(ground, name, radius, 3, Vector3.new(0, top - 3, 0), color)
		-- the turned cylinder's top is its Right face
		tile(part, Enum.NormalId.Right, TILE_TEXTURE, 10, 0.55, 0.6)
	end
	makeCylinder(ground, "PlazaBorder", PLAZA_RADIUS + 2, 3, Vector3.new(0, PATH_TOP - 3.08, 0), CURB_COLOR)
	disc("Plaza", PLAZA_RADIUS - 2, PATH_TOP - 0.06, PAVING_COLOR)
	disc("PlazaRing", 92, PATH_TOP - 0.04, PAVING_ACCENT)
	disc("Plaza", 86, PATH_TOP - 0.02, PAVING_COLOR)
	disc("PlazaCenter", CENTER_RADIUS, PATH_TOP, CENTER_COLOR)
	buildFountain(parent)
	buildTent(parent, plotAngles)

	local lift = Vector3.new(0, PATH_TOP + 0.05, 0)
	local gap = math.pi / #plotAngles
	for index, angle in plotAngles do
		local color = FactoryBuilder.Vivid(plots[index].Color)
		local from, to = onGround(angle, CENTER_RADIUS) + lift, onGround(angle, BRIDGE_FROM + 2) + lift
		local carpet = makeSlab(ground, "Carpet", from, to, PATH_WIDTH, 0.3, color)
		tile(carpet, Enum.NormalId.Top, FLAGSTONE_TEXTURE, 12, 0.62, 0.15)
		local across = (to - from).Unit:Cross(Vector3.yAxis)
		for _, s in { -1, 1 } do
			local edge = across * s * (PATH_WIDTH / 2 + 0.4) + Vector3.new(0, 0.1, 0)
			makeSlab(parent, "CarpetEdge", from + edge, to + edge, 0.8, 0.45, CURB_COLOR)
		end
		local lamps = {}
		for _, side in { -1, 1 } do
			local base = onGround(angle + side * math.rad(8), PLAZA_RADIUS - 6) + Vector3.new(0, PATH_TOP, 0)
			buildLamp(parent, base)
			table.insert(lamps, base + Vector3.new(0, 12.6, 0))
		end
		buildBunting(parent, lamps[1], lamps[2], 3, { color, Color3.new(1, 1, 1), BLOCK_COLORS[(index % #BLOCK_COLORS) + 1] })
		buildHedge(parent, PLAZA_RADIUS - 4, angle + math.rad(12), angle + 2 * gap - math.rad(12))

		local between = angle + gap
		buildBush(parent, onGround(between, FOUNTAIN_RADIUS + 4.5) + Vector3.new(0, PATH_TOP, 0), 0.8)
		local seat = onGround(between, CENTER_RADIUS + 7) + Vector3.new(0, PATH_TOP, 0)
		buildBench(parent, CFrame.lookAt(seat, Vector3.new(0, PATH_TOP, 0))) -- facing the fountain
		-- the leaderboards and the podium stand in five of the gaps, facing the fountain
		-- (LeaderboardManager builds them there); the last gap keeps its planter
		local spot = CFrame.lookAt(onGround(between, 62) + Vector3.new(0, PATH_TOP, 0), Vector3.new(0, PATH_TOP, 0))
		if index == 3 then
			MapBuilder.PodiumSpot = spot
		elseif index <= 5 then
			table.insert(MapBuilder.BoardSpots, spot)
		else
			buildPlanter(parent, onGround(between, 66) + Vector3.new(0, PATH_TOP, 0))
		end
		buildFlowers(parent, onGround(between + 0.12, PLAZA_RADIUS - 12) + Vector3.new(0, PATH_TOP, 0), false)
		buildFlowers(parent, onGround(between - 0.12, PLAZA_RADIUS - 12) + Vector3.new(0, PATH_TOP, 0), false)
	end
end

-- Bridges and paths --------------------------------------------------------------------

-- An arched wooden bridge over the river, along `angle`, its posts in `color`.
local function buildBridge(parent: Instance, angle: number, color: Color3)
	local bridge = Instance.new("Model")
	bridge.Name = "Bridge"
	local up = Vector3.new(0, BRIDGE_RISE, 0)
	local deckTop = Vector3.new(0, PATH_TOP, 0)
	local stops = { -- along the bridge: where it rises, runs flat, and comes down
		onGround(angle, BRIDGE_FROM) + deckTop,
		onGround(angle, RIVER_FROM + 2) + deckTop + up,
		onGround(angle, RIVER_TO - 2) + deckTop + up,
		onGround(angle, BRIDGE_TO) + deckTop,
	}
	local side = Vector3.new(math.cos(angle), 0, -math.sin(angle))
	-- A trimmed lawn where the bridge lands (on dry ground only: painting fills the
	-- volume, so it must stay off the river), so the tall grass doesn't poke through.
	local landFrom, landTo = RIVER_TO + 5, BRIDGE_TO + 8
	local landing = onGround(angle, (landFrom + landTo) / 2)
	paint(CFrame.lookAt(landing, landing + onGround(angle, 1)), Vector2.new(PATH_WIDTH + 10, landTo - landFrom), Enum.Material.LeafyGrass)
	for index = 1, 3 do
		local from, to = stops[index], stops[index + 1]
		makeSlab(ground, "BridgeDeck", from, to, PATH_WIDTH, 0.8, WOOD_COLOR, Enum.Material.WoodPlanks)
		for _, s in { -1, 1 } do
			local offset = side * s * (PATH_WIDTH / 2 + 0.3)
			makeSlab(bridge, "BridgeRail", from + offset + Vector3.new(0, 3, 0), to + offset + Vector3.new(0, 3, 0), 0.6, 0.6, CURB_COLOR)
			makeSlab(bridge, "BridgeEdge", from + offset + Vector3.new(0, 0.6, 0), to + offset + Vector3.new(0, 0.6, 0), 0.8, 1, WOOD_DARK, Enum.Material.Wood)
		end
	end
	-- Posts along the rails, and piers under the middle.
	for index, stop in stops do
		for _, s in { -1, 1 } do
			local post = stop + side * s * (PATH_WIDTH / 2 + 0.3)
			makePart(bridge, "BridgePost", Vector3.new(0.9, 3.6, 0.9), CFrame.new(post + Vector3.new(0, 1.5, 0)), color)
			makeBall(bridge, "BridgePostTop", 1.3, post + Vector3.new(0, 3.6, 0), color)
			if index == 2 or index == 3 then
				makeCylinder(bridge, "BridgePier", 1.2, 9, stop + side * s * (PATH_WIDTH / 2 - 1.5) - Vector3.new(0, 9.5, 0), WOOD_DARK, Enum.Material.Wood)
			end
		end
	end
	bridge.Parent = parent
end

-- A gently winding path in the factory's color, with white curbs, from its bridge to
-- its entrance, with lamps, a bench and flowers along the way.
local function buildPath(parent: Instance, angle: number, entrance: Vector3, color: Color3, sway: number)
	local forward = onGround(angle, 1)
	local side = Vector3.new(forward.Z, 0, -forward.X)
	local fromRadius, toRadius = BRIDGE_TO, (entrance * Vector3.new(1, 0, 1)).Magnitude
	local points = {}
	local steps = 16
	for step = 0, steps do
		local t = step / steps
		local radius = fromRadius + (toRadius - fromRadius) * t
		table.insert(points, forward * radius + side * sway * math.sin(t * math.pi * 2) + Vector3.new(0, PATH_TOP, 0))
	end

	-- Short stretches that overlap a little at each end (every other one a hair higher,
	-- so the overlaps don't flicker), paved in flagstones tinted the factory's color,
	-- the pattern running on from stretch to stretch. White curbs line both sides, with
	-- little posts hiding the curbs' joints.
	local travelled = 0
	for index = 1, #points - 1 do
		local from, to = points[index], points[index + 1]
		local along = (to - from).Unit
		local length = (to - from).Magnitude
		local lift = Vector3.new(0, if index % 2 == 0 then 0.03 else 0, 0)
		local slab = makeSlab(ground, "Path", from - along * 0.8 + lift, to + along * 0.8 + lift, PATH_WIDTH, 0.6, color)
		tile(slab, Enum.NormalId.Top, FLAGSTONE_TEXTURE, 12, 0.62, 0.15, travelled + length / 2)
		travelled += length
		local flat = CFrame.lookAt((from + to) / 2 * Vector3.new(1, 0, 1), to * Vector3.new(1, 0, 1))
		paint(flat, Vector2.new(PATH_WIDTH + 8, length + 8), Enum.Material.LeafyGrass)
		local across = along:Cross(Vector3.yAxis)
		for _, s in { -1, 1 } do
			local offset = across * s * (PATH_WIDTH / 2 + 0.5) + Vector3.new(0, 0.3, 0)
			makeSlab(parent, "Curb", from + offset, to + offset, 1, 0.9, CURB_COLOR)
			makeCylinder(parent, "CurbPost", 0.7, 1.1, from + offset - Vector3.new(0, 0.6, 0), CURB_COLOR)
		end
	end
	for _, point in points do -- for the free-space check (the plaza and river are off-limits anyway)
		table.insert(paths, point * Vector3.new(1, 0, 1))
	end

	-- Lamps on both sides near the bridge, then a bench and flowers halfway.
	for _, s in { -1, 1 } do
		buildLamp(parent, points[2] * Vector3.new(1, 0, 1) + side * s * (PATH_WIDTH / 2 + 4))
	end
	local seat = points[4] * Vector3.new(1, 0, 1) - side * (PATH_WIDTH / 2 + 4)
	buildBench(parent, CFrame.lookAt(seat, seat + side)) -- facing the path
	buildFlowers(parent, seat + forward * 7)
	buildFlowers(parent, points[5] * Vector3.new(1, 0, 1) + side * (PATH_WIDTH / 2 + 5))
end

-- A little plank footbridge across a stream.
local function buildFootbridge(parent: Instance, course: { Vector3 }, index: number)
	local here, nextPoint = course[index], course[index + 1]
	local along = (nextPoint - here).Unit
	local across = along:Cross(Vector3.yAxis)
	local from, to = here - across * 18 + Vector3.new(0, 0.4, 0), here + across * 18 + Vector3.new(0, 0.4, 0)
	local middle = here + Vector3.new(0, 2.2, 0)
	for _, s in { -1, 1 } do -- trimmed lawn at both ends (never over the water)
		local foot = here + across * s * 21
		paint(CFrame.lookAt(foot, foot + across), Vector2.new(12, 8), Enum.Material.LeafyGrass)
	end
	makeSlab(ground, "FootbridgeDeck", from, middle, 8, 0.6, WOOD_COLOR, Enum.Material.WoodPlanks)
	makeSlab(ground, "FootbridgeDeck", middle, to, 8, 0.6, WOOD_COLOR, Enum.Material.WoodPlanks)
	for _, s in { -1, 1 } do
		local offset = along * s * 4 + Vector3.new(0, 2.6, 0)
		makeSlab(parent, "FootbridgeRail", from + offset, middle + offset, 0.5, 0.5, CURB_COLOR)
		makeSlab(parent, "FootbridgeRail", middle + offset, to + offset, 0.5, 0.5, CURB_COLOR)
	end
end

-- API --------------------------------------------------------------------------------

export type SpotOptions = {
	Near: Vector3?, -- look within `Spread` studs of this point (still inside the ring)
	Spread: number?,
	Accept: ((spot: Vector3) -> boolean)?, -- an extra test (e.g. clear of other boxes)
}

-- A spot for a loot box near a random point between `minRadius` and `maxRadius` from
-- the hub: on the ground (never water), clear of decor and buildings. With `Near`,
-- bought box drops rain round the buyer. Nil if none turned up.
function MapBuilder.FindSpot(minRadius: number, maxRadius: number, rng: Random, options: SpotOptions?): Vector3?
	local near = options and options.Near
	local spread = options and options.Spread or 40
	local accept = options and options.Accept
	local overlap = OverlapParams.new()
	overlap.FilterType = Enum.RaycastFilterType.Exclude
	overlap.FilterDescendantsInstances = { ground }
	for _ = 1, 25 do
		local flat: Vector3
		if near then
			local reach = math.sqrt(rng:NextNumber(0, 1)) * spread
			local angle = rng:NextNumber(0, math.pi * 2)
			flat = Vector3.new(near.X + math.cos(angle) * reach, 0, near.Z + math.sin(angle) * reach)
			local fromHub = flat.Magnitude
			if fromHub < minRadius or fromHub > maxRadius then
				-- pulled back into the ring along the same line from the hub
				local direction = if fromHub > 0.01 then flat / fromHub else Vector3.xAxis
				flat = direction * math.clamp(fromHub, minRadius, maxRadius)
			end
		else
			local radius = math.sqrt(rng:NextNumber(minRadius * minRadius, maxRadius * maxRadius))
			flat = onGround(rng:NextNumber(0, math.pi * 2), radius)
		end
		local spot = groundAt(flat.X, flat.Z)
		if spot and (not accept or accept(spot)) and #workspace:GetPartBoundsInRadius(spot + Vector3.new(0, 2.5, 0), 3, overlap) == 0 then
			return spot
		end
	end
	return nil
end

-- What the Low Performance setting hides (Client/Performance): the small, many,
-- purely decorative things. Trees, windmills, balloons, statues and the paths stay.
local DETAIL_NAMES = {
	TulipField = true, Flower = true, Butterfly = true, Tuft = true, Bush = true, Rock = true,
	MushroomDot = true, MushroomStem = true, MushroomCap = true, Reed = true, Cattail = true,
	LilyPad = true, LilyFlower = true, RubberDuck = true, Flock = true,
}
local function tagDetail(item: Instance)
	if DETAIL_NAMES[item.Name] then
		CollectionService:AddTag(item, "Detail")
	end
end

-- Builds the world once, after TycoonManager has laid out the plots.
function MapBuilder.Init()
	local started = os.clock()
	local plots = TycoonManager.GetPlots()
	hub = Instance.new("Folder")
	hub.Name = "Hub"
	ground = Instance.new("Folder")
	ground.Name = "Ground"
	ground.Parent = hub

	local plotAngles = {}
	for _, plot in plots do
		local position = plot.CFrame.Position
		table.insert(plotAngles, math.atan2(position.X, position.Z))
	end
	local gap = math.pi / #plots -- from a factory's path to the middle of the next gap

	-- Two opposite gaps get streams; the others get a row of hills. Every factory gets
	-- a big hill behind it. (Footprints keep clear of the factories and paths.)
	local streamAngles, hillSpots = {}, {}
	local millHills: { Vector3 } = {} -- each gap without a stream gets a windmill on its big hill
	for index, angle in plotAngles do
		local between = angle + gap
		if index == 2 or index == 5 then
			table.insert(streamAngles, between)
		else
			table.insert(hillSpots, { onGround(between, 205), 45, 22 })
			table.insert(hillSpots, { onGround(between, 320), 35, 16 })
			table.insert(hillSpots, { onGround(between, 470), 60, 30 })
			table.insert(millHills, onGround(between, 470))
		end
		table.insert(hillSpots, { onGround(angle, 620), 70, 32 })
	end
	for _, spot in hillSpots do
		table.insert(hills, { Center = spot[1] :: Vector3, Radius = spot[2] :: number })
	end
	buildTerrain(streamAngles, hillSpots)
	task.wait() -- fresh terrain only answers raycasts from the next frame on

	-- A trimmed lawn under every factory (and its garden path), so the animated grass
	-- doesn't poke through its floors. Then the paths: everything else checks it stays off them.
	local lot = FactoryBuilder.Lot
	for _, plot in plots do
		local lawn = Vector2.new(lot.HalfWidth * 2 + 4, lot.Back - lot.Front + 4)
		paint(plot.CFrame * CFrame.new(0, 0, (lot.Front + lot.Back) / 2), lawn, Enum.Material.LeafyGrass)
		paint(plot.CFrame * CFrame.new(FactoryBuilder.GardenLawn.Center), FactoryBuilder.GardenLawn.Size, Enum.Material.LeafyGrass)
		WorkBudget.Step()
	end
	for index, plot in plots do
		local entrance = (plot.CFrame * CFrame.new(0, 0, -60)).Position
		local sway = if index % 2 == 0 then PATH_SWAY else -PATH_SWAY
		local color = FactoryBuilder.Vivid(plot.Color)
		buildPath(hub, plotAngles[index], entrance, color, sway)
		buildBridge(hub, plotAngles[index], color)
		WorkBudget.Step()
	end
	buildPlaza(hub, plots, plotAngles)
	for _, angle in streamAngles do
		local course = streamCourse(angle)
		buildFootbridge(hub, course, math.floor(#course * 0.3))
	end
	dressWater(hub, streamAngles)

	-- Something to find in every gap between factories: a brainrot statue, a picnic, a
	-- garden (with butterflies), toy blocks and lollipops.
	local life = Instance.new("Folder")
	life.Name = "Life"
	life.Parent = hub
	for index, angle in plotAngles do
		local between = angle + gap
		local isStream = table.find(streamAngles, between) ~= nil
		local side = if isStream then 0.3 else 0
		local function place(offset: number, distance: number, radius: number, build: (Vector3, number) -> ())
			local spot = claimSpot(between + offset, distance, radius, plots)
			if spot then
				local facing = math.atan2(spot.X, spot.Z) -- toward the hub
				paint(CFrame.new(spot) * CFrame.Angles(0, facing, 0), Vector2.new(radius * 2, radius * 2), Enum.Material.LeafyGrass)
				build(spot, facing)
			end
		end
		place(side, if isStream then 200 else 268, 14, function(spot, facing)
			buildShowcase(hub, spot, SHOWCASE[(index - 1) % #SHOWCASE + 1], facing)
		end)
		place(-side - 0.2, if isStream then 210 else 390, 12, function(spot, facing)
			buildPicnic(hub, spot, facing)
		end)
		place(side + 0.18, 340, 10, function(spot, facing)
			buildGarden(hub, spot, facing)
			for _ = 1, 3 do
				buildButterfly(life, spot + Vector3.new(random:NextNumber(-5, 5), 1.5, random:NextNumber(-5, 5)))
			end
		end)
		place(-side + 0.22, 420, 6, function(spot, facing)
			buildToyBlocks(hub, spot, facing)
		end)
		for _, offset in { -0.14, 0.14 } do
			place(offset, 175, 4, function(spot, facing)
				buildLollipop(hub, spot, facing)
			end)
		end
		WorkBudget.Step()
	end

	-- Life in every gap (see "Life between the factories"): a tulip field with
	-- butterflies, a grove, a windmill by the pond where there's a stream (the others
	-- get theirs on the big hill, below), birds circling above.
	for index, angle in plotAngles do
		local between = angle + gap
		local isStream = table.find(streamAngles, between) ~= nil
		local field = claimSpot(between - (if isStream then 0.3 else 0.24), 470, FIELD_RADIUS, plots)
		if field then
			local facing = math.atan2(field.X, field.Z)
			paint(CFrame.new(field) * CFrame.Angles(0, facing, 0), Vector2.new(FIELD_RADIUS * 2, FIELD_RADIUS * 2), Enum.Material.LeafyGrass)
			buildTulipField(life, field, facing)
			for _ = 1, 7 do
				buildButterfly(life, field + Vector3.new(random:NextNumber(-14, 14), 3, random:NextNumber(-14, 14)))
			end
		end
		local grove = claimSpot(between + (if isStream then 0.34 else 0.22), if isStream then 470 else 590, 16, plots)
		if grove then
			buildGrove(life, grove, 6)
		end
		if isStream then
			local mill = claimSpot(between + 0.13, 575, 9, plots)
			if mill then
				paint(CFrame.new(mill), Vector2.new(18, 18), Enum.Material.LeafyGrass)
				buildWindmill(life, mill, math.atan2(mill.X, mill.Z), BALLOON_COLORS[index % #BALLOON_COLORS + 1])
			end
		end
		buildFlock(life, onGround(between + random:NextNumber(-0.1, 0.1), 430) + Vector3.new(0, random:NextNumber(80, 105), 0), 5)
		WorkBudget.Step()
	end

	-- Trees on the hills' tops (a windmill on the big ones), then decor scattered over
	-- the valley.
	for _, spot in hillSpots do
		local center = spot[1] :: Vector3
		local top = groundAt(center.X, center.Z)
		local mill = table.find(millHills, center)
		if top and mill then
			buildWindmill(life, top - Vector3.new(0, 0.5, 0), math.atan2(top.X, top.Z), BALLOON_COLORS[(mill * 2) % #BALLOON_COLORS + 1])
		elseif top then
			buildTree(hub, top)
			buildFlowers(hub, top + Vector3.new(8, 0, 4))
		end
	end
	local decor = Instance.new("Folder")
	decor.Name = "Decor"
	decor.Parent = hub
	local from, to = RIVER_TO + 10, MOUNTAIN_RING - 120
	scatter(170, from, to, 6, plots, function(spot)
		buildTree(decor, spot)
	end)
	scatter(60, from, to, 4, plots, function(spot)
		buildBush(decor, spot, random:NextNumber(0.8, 1.3))
	end)
	scatter(160, from, to, 3, plots, function(spot)
		buildFlowers(decor, spot)
	end)
	scatter(40, from, to, 4, plots, function(spot)
		buildRocks(decor, spot)
	end)
	scatter(26, from, to, 3, plots, function(spot)
		buildMushrooms(decor, spot)
	end)

	-- Hot air balloons drifting round the valley: over the plaza, or out behind the
	-- factories (their ring, 232 to 486 from the hub, grows taller as floors are added).
	local orbits = { { 190, 165 }, { 540, 175 }, { 150, 185 }, { 610, 170 }, { 520, 195 } } -- { radius, height }
	for index, colors in HOT_AIR_COLORS do
		local orbit = orbits[index]
		local speed = (if index % 2 == 0 then -1 else 1) * random:NextNumber(0.012, 0.02)
		buildHotAirBalloon(life, orbit[1], orbit[2], index / #HOT_AIR_COLORS * math.pi * 2 + 0.3, speed, colors)
	end

	-- Balloons drifting over the plaza and the valley (always streamed in: the client
	-- bobs them, and they're few).
	local balloons = Instance.new("Model")
	balloons.Name = "Balloons"
	balloons.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	for _ = 1, 36 do
		local radius = random:NextNumber(10, 260)
		buildBalloon(balloons, onGround(random:NextNumber(0, math.pi * 2), radius) + Vector3.new(0, random:NextNumber(45, 110), 0))
	end
	balloons.Parent = hub

	-- Players spawn at the hub for a moment before their plot takes them in; keep the
	-- spawn pad out of the fountain and out of sight.
	local spawn = workspace:FindFirstChildOfClass("SpawnLocation")
	if spawn then
		spawn.CFrame = CFrame.new(0, PATH_TOP + 0.5, -(FOUNTAIN_RADIUS + 6))
		spawn.Transparency = 1
		spawn.CanCollide = false
		for _, child in spawn:GetChildren() do
			if child:IsA("Decal") then
				child:Destroy()
			end
		end
	end

	-- The small stuff (Low Performance hides it on a player's client: Client/Performance)
	for _, item in hub:GetChildren() do
		tagDetail(item)
	end
	for _, folder in { life, decor } do
		for _, item in folder:GetChildren() do
			tagDetail(item)
		end
	end

	hub:SetAttribute("BuildSeconds", os.clock() - started) -- for checking startup cost
	hub.Parent = workspace
end

return MapBuilder
