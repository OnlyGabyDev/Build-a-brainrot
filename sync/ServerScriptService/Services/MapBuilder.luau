--[[
	MapBuilder
	Dresses up the hub between the factories (GDD §15): grass instead of the gray
	baseplate, a round pastel plaza with a path in each factory's color leading to its
	entrance, a fountain with a giant Tralalero statue in the middle, lamps, trees,
	flower bushes, and rolling hills around the world.

	Loot boxes spawn on the plaza (Config/Loot SpawnRadius), so everything solid stays
	off that ring: the fountain sits inside it, and the lamps and trees outside it.
	The statue's slow spin is client-side (Atmosphere).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local BrainrotModels = require(Shared.BrainrotModels)
local Brainrots = require(Shared.Config.Brainrots)
local Loot = require(Shared.Config.Loot)

local FactoryBuilder = require(script.Parent.FactoryBuilder)
local TycoonManager = require(script.Parent.TycoonManager)

local PLAZA_RADIUS = 150 -- reaches the factories' entrances
local FOUNTAIN_RADIUS = 20
local STATUE_ID = "TralaleroTralala"
local STATUE_SCALE = 5
local SEED = 7 -- the same trees and hills every server

local GRASS_COLOR = Color3.fromRGB(130, 210, 95)
local PAVING_COLOR = Color3.fromRGB(255, 240, 215)
local BORDER_COLOR = Color3.fromRGB(255, 255, 255)
local RING_COLOR = Color3.fromRGB(255, 190, 220)
local CENTER_COLOR = Color3.fromRGB(190, 240, 225)
local STONE_COLOR = Color3.fromRGB(250, 248, 255)
local WATER_COLOR = Color3.fromRGB(120, 210, 255)
local LAMP_POST_COLOR = Color3.fromRGB(110, 80, 170)
local LAMP_LIGHT_COLOR = Color3.fromRGB(255, 236, 190)
local TRUNK_COLOR = Color3.fromRGB(150, 100, 70)
local LEAF_COLORS = {
	Color3.fromRGB(110, 205, 90),
	Color3.fromRGB(150, 225, 100),
	Color3.fromRGB(255, 175, 210), -- cherry blossom
}
local FLOWER_COLORS = {
	Color3.fromRGB(255, 110, 170),
	Color3.fromRGB(255, 215, 70),
	Color3.fromRGB(150, 130, 255),
	Color3.fromRGB(255, 255, 255),
}
local HILL_COLORS = {
	Color3.fromRGB(95, 180, 85),
	Color3.fromRGB(110, 195, 95),
	Color3.fromRGB(85, 170, 100),
}

local MapBuilder = {}

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

local function makeBall(parent: Instance, name: string, diameter: number, position: Vector3, color: Color3): Part
	local ball = makePart(parent, name, Vector3.one * diameter, CFrame.new(position), color)
	ball.Shape = Enum.PartType.Ball
	return ball
end

-- An upright cylinder standing on `bottom` (Y) at `center` (XZ).
local function makeCylinder(parent: Instance, name: string, radius: number, height: number, center: Vector3, color: Color3, material: Enum.Material?): Part
	local cframe = CFrame.new(center.X, center.Y + height / 2, center.Z) * CFrame.Angles(0, 0, math.pi / 2)
	local part = makePart(parent, name, Vector3.new(height, radius * 2, radius * 2), cframe, color, material)
	part.Shape = Enum.PartType.Cylinder
	return part
end

-- A paved disc whose top sits at `top`. Smaller discs sit a hair higher, so they
-- layer into colored rings without flickering.
local function makeDisc(parent: Instance, name: string, radius: number, top: number, color: Color3, material: Enum.Material?): Part
	return makeCylinder(parent, name, radius, 0.3, Vector3.new(0, top - 0.3, 0), color, material)
end

local function onGround(angle: number, radius: number, y: number?): Vector3
	return Vector3.new(math.sin(angle) * radius, y or 0, math.cos(angle) * radius)
end

-- Ground and plaza -----------------------------------------------------------------

local function dressGround()
	local baseplate = workspace:FindFirstChild("Baseplate")
	if baseplate and baseplate:IsA("BasePart") then
		baseplate.Color = GRASS_COLOR
		baseplate.Material = Enum.Material.Grass
		for _, child in baseplate:GetChildren() do
			if child:IsA("Texture") or child:IsA("Decal") then
				child:Destroy() -- the default gray grid
			end
		end
	end
	-- Players spawn at the hub for a moment before their plot takes them in; keep the
	-- spawn pad out of the fountain and out of sight.
	local spawn = workspace:FindFirstChildOfClass("SpawnLocation")
	if spawn then
		spawn.CFrame = CFrame.new(0, 0.5, -(FOUNTAIN_RADIUS + 8))
		spawn.Transparency = 1
		spawn.CanCollide = false
		for _, child in spawn:GetChildren() do
			if child:IsA("Decal") then
				child:Destroy()
			end
		end
	end
end

local function buildPlaza(parent: Instance, plots: { TycoonManager.Plot })
	makeDisc(parent, "PlazaBorder", PLAZA_RADIUS, 0.3, BORDER_COLOR)
	makeDisc(parent, "Plaza", PLAZA_RADIUS - 4, 0.32, PAVING_COLOR, Enum.Material.Pavement)
	makeDisc(parent, "PlazaRing", 112, 0.34, RING_COLOR)
	makeDisc(parent, "Plaza", 106, 0.36, PAVING_COLOR, Enum.Material.Pavement)
	makeDisc(parent, "PlazaCenter", FOUNTAIN_RADIUS + 14, 0.38, CENTER_COLOR)

	-- A path in each factory's color, from the fountain to its entrance.
	local from, to = FOUNTAIN_RADIUS + 14, PLAZA_RADIUS - 2
	for _, plot in plots do
		local entrance = plot.CFrame.Position * Vector3.new(1, 0, 1)
		local direction = entrance.Unit
		local middle = direction * (from + to) / 2 + Vector3.new(0, 0.4 - 0.05, 0)
		local path = makePart(parent, "Path", Vector3.new(14, 0.1, to - from), CFrame.lookAt(middle, middle + direction), FactoryBuilder.Vivid(plot.Color))
		path.CanCollide = false
	end
end

-- The fountain -----------------------------------------------------------------------

-- The starter brainrot, built from its four parts and blown up to a giant statue.
local function buildStatue(parent: Instance, base: Vector3)
	if not Brainrots.ById[STATUE_ID] then
		return
	end
	local statue = Instance.new("Model")
	statue.Name = "Statue"
	for _, partType in Brainrots.PartTypes do
		local part = BrainrotModels.CreatePart(STATUE_ID, partType)
		part.Parent = statue
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
	local water = makeCylinder(fountain, "Water", FOUNTAIN_RADIUS - 1.5, 0.1, Vector3.new(0, 2.6, 0), WATER_COLOR)
	water.Transparency = 0.15
	water.Reflectance = 0.2
	water.CanCollide = false
	makeCylinder(fountain, "Pedestal", 6, 7, Vector3.new(0, 2.6, 0), STONE_COLOR, Enum.Material.Marble)
	makeCylinder(fountain, "PedestalCap", 7, 1, Vector3.new(0, 9.6, 0), STONE_COLOR, Enum.Material.Marble)

	-- Jets of water arcing out from under the cap into the basin. The jets hang off an
	-- unrotated anchor (the cylinders are turned on their side).
	local anchor = makePart(fountain, "JetAnchor", Vector3.one, CFrame.new(0, 10, 0), WATER_COLOR)
	anchor.Transparency = 1
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
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

-- Decor ------------------------------------------------------------------------------

local function buildLamp(parent: Instance, position: Vector3)
	makeCylinder(parent, "LampPost", 0.6, 12, position, LAMP_POST_COLOR)
	makeCylinder(parent, "LampBase", 1.4, 1, position, LAMP_POST_COLOR)
	local bulb = makeBall(parent, "LampBulb", 3, position + Vector3.new(0, 13.2, 0), LAMP_LIGHT_COLOR)
	bulb.Material = Enum.Material.Neon
	bulb.CanCollide = false
	makeCylinder(parent, "LampCap", 1.8, 0.6, position + Vector3.new(0, 14.4, 0), LAMP_POST_COLOR)
	local light = Instance.new("PointLight")
	light.Color = LAMP_LIGHT_COLOR
	light.Range = 18
	light.Brightness = 1
	light.Shadows = false
	light.Parent = bulb
end

-- A round, toy-like tree: a trunk with a few stacked balls of leaves.
local function buildTree(parent: Instance, position: Vector3, scale: number, color: Color3)
	local tree = Instance.new("Model")
	tree.Name = "Tree"
	local trunkHeight = 8 * scale
	makePart(tree, "Trunk", Vector3.new(2, trunkHeight, 2) * scale, CFrame.new(position + Vector3.new(0, trunkHeight / 2, 0)), TRUNK_COLOR, Enum.Material.Wood)
	local top = position + Vector3.new(0, trunkHeight, 0)
	makeBall(tree, "Leaves", 10 * scale, top + Vector3.new(0, 2 * scale, 0), color)
	makeBall(tree, "Leaves", 7 * scale, top + Vector3.new(2.5, 5, -1.5) * scale, color:Lerp(Color3.new(1, 1, 1), 0.12))
	makeBall(tree, "Leaves", 6 * scale, top + Vector3.new(-2.5, 4.5, 1.5) * scale, color:Lerp(Color3.new(0, 0, 0), 0.06))
	tree.Parent = parent
end

-- A round bush dotted with flowers.
local function buildBush(parent: Instance, position: Vector3, random: Random)
	makeBall(parent, "Bush", 6, position + Vector3.new(0, 1.8, 0), LEAF_COLORS[1])
	for index = 1, 7 do
		local angle = index / 7 * math.pi * 2
		local spot = position + Vector3.new(math.sin(angle) * 2.6, 2.4 + random:NextNumber(-0.6, 1.4), math.cos(angle) * 2.6)
		local flower = makeBall(parent, "Flower", 1.3, spot, FLOWER_COLORS[random:NextInteger(1, #FLOWER_COLORS)])
		flower.CanCollide = false
	end
end

local function buildDecor(parent: Instance, plots: { TycoonManager.Plot })
	local random = Random.new(SEED)
	local count = #plots
	local lampRadius = math.max(Loot.SpawnRadius.Max + 6, PLAZA_RADIUS - 8)
	for _, plot in plots do
		local position = plot.CFrame.Position
		local angle = math.atan2(position.X, position.Z)
		local between = angle + math.pi / count -- the gap to the next factory

		-- Lamps on both sides of the path, at the plaza's edge.
		for _, side in { -1, 1 } do
			buildLamp(parent, onGround(angle + side * math.rad(8), lampRadius))
		end
		-- Flower bushes around the fountain, between the paths.
		buildBush(parent, onGround(between, FOUNTAIN_RADIUS + 6), random)
		-- A little grove in the gap between this factory and the next.
		for index, radius in { 172, 210, 252, 300, 350 } do
			local offset = if index % 2 == 0 then 0.04 else -0.04
			local color = LEAF_COLORS[random:NextInteger(1, #LEAF_COLORS)]
			buildTree(parent, onGround(between + offset, radius), random:NextNumber(0.8, 1.1) + index * 0.06, color)
		end
	end

	-- A ring of trees around the whole town, then a ring of overlapping hills that
	-- closes the valley (and hides the world's edge). Hills further out vanish in the
	-- pastel haze, so they stay close and big.
	for index = 1, 44 do
		local angle = index / 44 * math.pi * 2 + random:NextNumber(-0.04, 0.04)
		local color = LEAF_COLORS[random:NextInteger(1, #LEAF_COLORS)]
		buildTree(parent, onGround(angle, random:NextNumber(440, 520)), random:NextNumber(1.1, 1.6), color)
	end
	for index = 1, 22 do
		local angle = index / 22 * math.pi * 2 + random:NextNumber(-0.05, 0.05)
		local size = random:NextNumber(260, 380)
		local hill = makeBall(parent, "Hill", size, onGround(angle, random:NextNumber(630, 700), -size * 0.28), HILL_COLORS[random:NextInteger(1, #HILL_COLORS)])
		hill.Material = Enum.Material.Grass
	end
end

-- API ------------------------------------------------------------------------------

-- Builds the hub once, after TycoonManager has laid out the plots.
function MapBuilder.Init()
	local plots = TycoonManager.GetPlots()
	local hub = Instance.new("Folder")
	hub.Name = "Hub"
	dressGround()
	buildPlaza(hub, plots)
	buildFountain(hub)
	buildDecor(hub, plots)
	hub.Parent = workspace
end

return MapBuilder
