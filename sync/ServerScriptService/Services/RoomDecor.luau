--[[
	RoomDecor
	Themed props inside the factory's rooms (GDD §10), so each room shows its theme
	even while it's locked: you see it through the glass door. A first pass of big,
	readable pieces along the walls; the middle stays clear for the lines.

	Room space: `floor` is the room's floor center, -Z toward the building's front (the
	hub). Rooms are 140 × 120; props keep to the margins (|X| > 55 or |Z| > 48), clear
	of the doors: the front doorway (Z = -60, |X| < 13), the Clay Studio's side door
	(X = +70 around Z = 31) and the Candy Factory's (Z = +60, |X| < 8).
	FactoryBuilder calls RoomDecor.Build for every room.
]]

local CollectionService = game:GetService("CollectionService")

local RoomDecor = {}

local WHITE = Color3.new(1, 1, 1)

-- Helpers --------------------------------------------------------------------------

-- Props are just for looks: no collisions.
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
	local part = makeDecor(parent, name, Vector3.new(diameter, diameter, diameter), cframe, color, material)
	part.Shape = Enum.PartType.Ball
	return part
end

-- An upright cylinder standing on `base` (its bottom center).
local function cylinder(parent: Instance, name: string, diameter: number, height: number, base: CFrame, color: Color3, material: Enum.Material?): Part
	local part = makeDecor(parent, name, Vector3.new(height, diameter, diameter), base * CFrame.new(0, height / 2, 0) * CFrame.Angles(0, 0, math.pi / 2), color, material)
	part.Shape = Enum.PartType.Cylinder
	return part
end

-- Makes `model` (its parts already in) spin about `pivot`'s Z axis on the client
-- (Atmosphere turns Models tagged "Spinner" at their Speed, in radians per second).
local function spinner(model: Model, parent: Instance, pivot: CFrame, speed: number)
	model.WorldPivot = pivot
	model:SetAttribute("Speed", speed)
	CollectionService:AddTag(model, "Spinner")
	model.Parent = parent
end

-- A cylinder lying along `base`'s X axis, centered on it.
local function roller(parent: Instance, name: string, diameter: number, length: number, base: CFrame, color: Color3): Part
	local part = makeDecor(parent, name, Vector3.new(length, diameter, diameter), base, color)
	part.Shape = Enum.PartType.Cylinder
	return part
end

-- Plushie Sewing Room ---------------------------------------------------------------

local function yarnBall(parent: Instance, at: CFrame, diameter: number, color: Color3)
	ball(parent, "YarnBall", diameter, at * CFrame.new(0, diameter / 2, 0), color, Enum.Material.Fabric)
	-- a few wraps around it, and a strand trailing on the floor
	for _, angle in { -0.5, 0.2, 0.9 } do
		local wrap = roller(parent, "YarnWrap", diameter + 0.2, 0.4, at * CFrame.new(0, diameter / 2, 0) * CFrame.Angles(0, angle, math.rad(70)), color:Lerp(WHITE, 0.25))
		wrap.Material = Enum.Material.Fabric
	end
	local strand = roller(parent, "YarnStrand", 0.4, diameter * 1.4, at * CFrame.new(diameter * 0.9, 0.2, diameter * 0.2) * CFrame.Angles(0, 0.4, 0), color)
	strand.Material = Enum.Material.Fabric
end

local function spool(parent: Instance, at: CFrame, color: Color3)
	local wood = Color3.fromRGB(225, 180, 125)
	cylinder(parent, "SpoolEnd", 6, 1, at, wood, Enum.Material.Wood)
	cylinder(parent, "SpoolThread", 4.6, 5, at * CFrame.new(0, 1, 0), color, Enum.Material.Fabric)
	cylinder(parent, "SpoolEnd", 6, 1, at * CFrame.new(0, 6, 0), wood, Enum.Material.Wood)
end

-- A giant sewing machine on its table, `scale` times human size.
local function sewingMachine(parent: Instance, at: CFrame, scale: number)
	local body, trim = Color3.fromRGB(255, 150, 200), Color3.fromRGB(255, 235, 245)
	local function box(name: string, size: Vector3, offset: Vector3, color: Color3, material: Enum.Material?)
		makeDecor(parent, name, size * scale, at * CFrame.new(offset * scale), color, material)
	end
	box("SewingTable", Vector3.new(20, 1, 8), Vector3.new(0, 5, 0), Color3.fromRGB(215, 160, 110), Enum.Material.Wood)
	for _, x in { -9, 9 } do
		box("SewingLeg", Vector3.new(1, 4.5, 7), Vector3.new(x, 2.25, 0), Color3.fromRGB(110, 80, 120))
	end
	box("SewingBase", Vector3.new(16, 2, 6), Vector3.new(0, 6.5, 0), body)
	box("SewingPillar", Vector3.new(3.5, 7, 5), Vector3.new(6, 11, 0), body)
	box("SewingArm", Vector3.new(15, 3, 4.6), Vector3.new(-0.5, 15.5, 0), body)
	box("SewingHead", Vector3.new(3, 4, 4), Vector3.new(-6.5, 13.5, 0), body)
	box("SewingNeedle", Vector3.new(0.3, 3, 0.3), Vector3.new(-6.5, 10, 0), Color3.fromRGB(200, 205, 215), Enum.Material.Metal)
	box("SewingStripe", Vector3.new(15.2, 0.6, 4.8), Vector3.new(-0.5, 15.5, 0), trim)
	roller(parent, "SewingWheel", 5 * scale, scale, at * CFrame.new(8.7 * scale, 14 * scale, 0), trim)
	-- a diamond badge on its base, facing the door
	makeDecor(parent, "SewingBadge", Vector3.new(2.4, 2.4, 0.3) * scale, at * CFrame.new(0, 6.5 * scale, -3.1 * scale) * CFrame.Angles(0, 0, math.rad(45)), Color3.fromRGB(255, 90, 150))
	spool(parent, at * CFrame.new(-1 * scale, 17 * scale, 0), Color3.fromRGB(120, 200, 255))
end

local function pinCushion(parent: Instance, at: CFrame)
	cylinder(parent, "CushionBase", 5, 1.5, at, Color3.fromRGB(255, 220, 120))
	ball(parent, "Cushion", 6, at * CFrame.new(0, 3.6, 0), Color3.fromRGB(255, 90, 110), Enum.Material.Fabric)
	for index, color in { Color3.fromRGB(120, 200, 255), Color3.fromRGB(255, 230, 90), Color3.fromRGB(150, 230, 120) } do
		local tilt = CFrame.Angles(math.rad(25), index * 2.1, 0)
		local pin = at * CFrame.new(0, 4, 0) * tilt
		makeDecor(parent, "Pin", Vector3.new(0.25, 4.5, 0.25), pin * CFrame.new(0, 2.6, 0), Color3.fromRGB(210, 210, 220), Enum.Material.Metal)
		ball(parent, "PinHead", 1, pin * CFrame.new(0, 4.9, 0), color)
	end
end

local function buildPlushie(parent: Instance, floor: CFrame)
	sewingMachine(parent, floor * CFrame.new(0, 0, 51), 1.4)
	yarnBall(parent, floor * CFrame.new(-60, 0, 49), 9, Color3.fromRGB(255, 160, 200))
	yarnBall(parent, floor * CFrame.new(-50, 0, 54), 5, Color3.fromRGB(255, 225, 110))
	yarnBall(parent, floor * CFrame.new(59, 0, 46), 8, Color3.fromRGB(140, 205, 255))
	yarnBall(parent, floor * CFrame.new(24, 0, 54), 4.5, Color3.fromRGB(170, 140, 255))
	spool(parent, floor * CFrame.new(-62, 0, 10), Color3.fromRGB(255, 140, 180))
	spool(parent, floor * CFrame.new(62, 0, 0), Color3.fromRGB(170, 140, 255))
	pinCushion(parent, floor * CFrame.new(-60, 0, -42))
	-- a stack of fabric bolts
	for index, color in { Color3.fromRGB(255, 190, 220), Color3.fromRGB(190, 230, 255), Color3.fromRGB(255, 240, 180) } do
		makeDecor(parent, "FabricBolt", Vector3.new(9, 1.8, 4), floor * CFrame.new(60, index * 1.8 - 0.9, -44) * CFrame.Angles(0, index * 0.15, 0), color, Enum.Material.Fabric)
	end
end

-- Clay Studio -------------------------------------------------------------------------

local CLAY = Color3.fromRGB(215, 120, 80)
local CLAY_LIGHT = Color3.fromRGB(235, 160, 115)

local function pot(parent: Instance, at: CFrame, height: number, color: Color3)
	cylinder(parent, "PotBase", height * 0.5, height * 0.2, at, color)
	ball(parent, "PotBelly", height * 0.75, at * CFrame.new(0, height * 0.45, 0), color)
	cylinder(parent, "PotNeck", height * 0.35, height * 0.35, at * CFrame.new(0, height * 0.65, 0), color)
	cylinder(parent, "PotLip", height * 0.45, height * 0.1, at * CFrame.new(0, height * 0.95, 0), color:Lerp(WHITE, 0.15))
end

local function potteryWheel(parent: Instance, at: CFrame, scale: number)
	cylinder(parent, "WheelBase", 6 * scale, 3 * scale, at, Color3.fromRGB(120, 140, 170))
	cylinder(parent, "WheelPlate", 5 * scale, 0.5 * scale, at * CFrame.new(0, 3 * scale, 0), Color3.fromRGB(200, 205, 215), Enum.Material.Metal)
	ball(parent, "ClayLump", 3.2 * scale, at * CFrame.new(0, 4.6 * scale, 0), CLAY, Enum.Material.Sand)
	cylinder(parent, "Stool", 3 * scale, 2.5 * scale, at * CFrame.new(5 * scale, 0, 0), Color3.fromRGB(225, 180, 125), Enum.Material.Wood)
end

-- A big lumpy clay sculpture of a brainrot in the making (`at`: facing +X).
local function sculpture(parent: Instance, at: CFrame)
	cylinder(parent, "Plinth", 12, 4, at, WHITE)
	cylinder(parent, "PlinthTop", 13, 0.8, at * CFrame.new(0, 4, 0), CLAY_LIGHT)
	ball(parent, "ClayBlob", 10, at * CFrame.new(0, 9, 0), CLAY, Enum.Material.Sand)
	ball(parent, "ClayBlob", 7.5, at * CFrame.new(0.6, 15.5, 0), CLAY_LIGHT, Enum.Material.Sand)
	for _, side in { -1, 1 } do
		ball(parent, "ClayBlob", 3.2, at * CFrame.new(0, 10, side * 5.4), CLAY, Enum.Material.Sand) -- arms
		ball(parent, "ClayEye", 2.2, at * CFrame.new(3.6, 16.3, side * 1.6), WHITE)
		ball(parent, "ClayPupil", 1.1, at * CFrame.new(4.5, 16.3, side * 1.6), Color3.fromRGB(60, 40, 50))
	end
	-- a sculpting tool stuck in it
	makeDecor(parent, "SculptingTool", Vector3.new(0.4, 5, 0.4), at * CFrame.new(-2, 18, 2) * CFrame.Angles(math.rad(30), 0, math.rad(20)), Color3.fromRGB(225, 180, 125), Enum.Material.Wood)
end

local PAINT_COLORS = {
	Color3.fromRGB(255, 95, 120),
	Color3.fromRGB(255, 200, 60),
	Color3.fromRGB(90, 200, 255),
	Color3.fromRGB(120, 215, 110),
	Color3.fromRGB(185, 120, 255),
}

-- A spot on a wall's inner face, room space: { X, Y, Z } on the face, and the way
-- into the room (only along X or Z). The side walls' faces are at X = ±68, an outer
-- front or back wall's at Z = ±58, a wall between two rooms' at Z = ±59.
type WallSpot = { number }

-- The spot's CFrame, -Z pointing into the room.
local function wallFace(floor: CFrame, spot: WallSpot): CFrame
	local at = Vector3.new(spot[1], spot[2], spot[3])
	local inward = if math.abs(spot[1]) >= 68 then Vector3.new(-math.sign(spot[1]), 0, 0) else Vector3.new(0, 0, -math.sign(spot[3]))
	return floor * CFrame.lookAt(at, at + inward)
end

-- A splat of paint on a wall (`face`: its middle, on the wall, -Z into the room), with
-- a drip running down.
local function splat(parent: Instance, face: CFrame, size: number, color: Color3)
	local function blob(diameter: number, x: number, y: number)
		local part = makeDecor(parent, "PaintSplat", Vector3.new(0.2, diameter, diameter), face * CFrame.new(x, y, -0.1) * CFrame.Angles(0, math.pi / 2, 0), color)
		part.Shape = Enum.PartType.Cylinder
	end
	blob(size, 0, 0)
	blob(size * 0.35, size * 0.55, size * 0.3)
	blob(size * 0.25, -size * 0.5, size * 0.4)
	blob(size * 0.3, size * 0.2, -size * 0.45)
	makeDecor(parent, "PaintDrip", Vector3.new(size * 0.15, size * 0.8, 0.2), face * CFrame.new(-size * 0.15, -size * 0.6, -0.1), color)
	blob(size * 0.22, -size * 0.15, -size)
end

local function buildClay(parent: Instance, floor: CFrame)
	-- paint splats up the walls, between the windows (and clear of the side door at
	-- +X, Z = 31, and the doorway in the back)
	local spots: { WallSpot } = {
		{ -68, 15, -18 },
		{ -68, 18, 18 },
		{ -68, 14, 51 },
		{ 68, 17, -18 },
		{ 68, 14, 14 },
		{ -32, 17, 59 },
		{ 46, 14, 59 },
		{ -39, 22, -58 },
		{ 39, 16, -58 },
	}
	for index, spot in spots do
		splat(parent, wallFace(floor, spot), 5 + (index % 3) * 1.2, PAINT_COLORS[index % #PAINT_COLORS + 1])
	end
	-- across from the side door (X = +70, Z = 31): the sculpture, between big pots
	sculpture(parent, floor * CFrame.new(-60, 0, 31))
	pot(parent, floor * CFrame.new(-61, 0, 16), 12, CLAY)
	pot(parent, floor * CFrame.new(-60, 0, 46), 9, CLAY_LIGHT)
	potteryWheel(parent, floor * CFrame.new(-58, 0, -6), 1.5)
	potteryWheel(parent, floor * CFrame.new(-58, 0, -34), 1.5)
	-- a shelf of pots on the back wall
	for _, y in { 5, 11 } do
		makeDecor(parent, "Shelf", Vector3.new(30, 0.8, 5), floor * CFrame.new(-26, y, 55), Color3.fromRGB(225, 180, 125), Enum.Material.Wood)
	end
	for index = 1, 5 do
		pot(parent, floor * CFrame.new(-44 + index * 6, 5.4, 55), 4 + (index % 2) * 1.2, if index % 2 == 0 then CLAY else CLAY_LIGHT)
		pot(parent, floor * CFrame.new(-44 + index * 6, 11.4, 55), 3.8 + ((index + 1) % 2) * 1.2, if index % 2 == 1 then CLAY else Color3.fromRGB(240, 205, 170))
	end
	pot(parent, floor * CFrame.new(60, 0, -50), 8, Color3.fromRGB(240, 205, 170))
	pot(parent, floor * CFrame.new(54, 0, -53), 5, CLAY)
	-- buckets of clay slip by the door
	for index, z in { 48, 54 } do
		cylinder(parent, "Bucket", 4, 3.6, floor * CFrame.new(62, 0, z), Color3.fromRGB(150, 180, 220))
		cylinder(parent, "Slip", 3.6, 0.3, floor * CFrame.new(62, 3.4, z), if index == 1 then CLAY else CLAY_LIGHT)
	end
end

-- Vinyl Collectibles --------------------------------------------------------------------

local FIGURE_COLORS = {
	Color3.fromRGB(255, 120, 170),
	Color3.fromRGB(110, 200, 255),
	Color3.fromRGB(255, 210, 80),
	Color3.fromRGB(150, 230, 120),
	Color3.fromRGB(190, 140, 255),
	Color3.fromRGB(255, 160, 90),
}

-- A boxed collectible: a box with a window, a figure inside.
local function figureBox(parent: Instance, at: CFrame, color: Color3)
	makeDecor(parent, "FigureBox", Vector3.new(3.4, 4.6, 2.4), at * CFrame.new(0, 2.3, 0), color:Lerp(WHITE, 0.55))
	makeDecor(parent, "FigureBoxTop", Vector3.new(3.6, 0.8, 2.6), at * CFrame.new(0, 4.4, 0), color)
	ball(parent, "Figure", 1.8, at * CFrame.new(0, 2.6, -0.9), color)
	local window = makeDecor(parent, "FigureWindow", Vector3.new(2.6, 3, 0.2), at * CFrame.new(0, 2.2, -1.25), Color3.fromRGB(220, 240, 255), Enum.Material.Glass)
	window.Transparency = 0.5
end

-- A big gold star on a wall (`face`: on the wall, -Z into the room).
local function wallStar(parent: Instance, face: CFrame, size: number)
	local holder = makeDecor(parent, "WallStar", Vector3.new(size, size, 0.2), face * CFrame.new(0, 0, -0.15), WHITE)
	holder.Transparency = 1
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.LightInfluence = 0
	gui.PixelsPerStud = 12
	gui.Parent = holder
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.Font = Enum.Font.FredokaOne
	label.Text = "⭐"
	label.Parent = gui
end

local function buildVinyl(parent: Instance, floor: CFrame)
	local spots: { WallSpot } = {
		{ -68, 17, -18 },
		{ -68, 19, 18 },
		{ 68, 18, -18 },
		{ 68, 16, 18 },
		{ 36, 18, -59 },
		{ -36, 17, -59 },
	}
	for index, spot in spots do
		wallStar(parent, wallFace(floor, spot), 6 + (index % 2) * 2)
	end
	-- display shelves along the back wall
	local shelf = floor * CFrame.new(-28, 0, 55.5)
	for _, x in { -14, 14 } do
		makeDecor(parent, "ShelfSide", Vector3.new(1, 16, 4), shelf * CFrame.new(x, 8, 0), WHITE)
	end
	for row = 0, 2 do
		makeDecor(parent, "Shelf", Vector3.new(28, 0.6, 4), shelf * CFrame.new(0, 1 + row * 5, 0), Color3.fromRGB(130, 175, 255))
		for column = 0, 3 do
			figureBox(parent, shelf * CFrame.new(-9 + column * 6, 1.3 + row * 5, 0), FIGURE_COLORS[(row * 4 + column) % #FIGURE_COLORS + 1])
		end
	end
	-- pedestals with shiny collectibles, under spotlights
	for index, spot in { Vector3.new(56, 0, 50), Vector3.new(-58, 0, 46) } do
		local at = floor * CFrame.new(spot)
		cylinder(parent, "Pedestal", 5, 4, at, WHITE)
		cylinder(parent, "PedestalTop", 5.6, 0.6, at * CFrame.new(0, 4, 0), Color3.fromRGB(130, 175, 255))
		local shiny = ball(parent, "Collectible", 3.6, at * CFrame.new(0, 6.4, 0), FIGURE_COLORS[index * 2])
		shiny.Reflectance = 0.3
		local lamp = at * CFrame.new(4, 0, 4)
		cylinder(parent, "SpotlightStand", 0.5, 12, lamp, Color3.fromRGB(80, 90, 120))
		local head = makeDecor(parent, "Spotlight", Vector3.new(2, 2, 2.6), lamp * CFrame.new(0, 12, 0) * CFrame.Angles(math.rad(35), math.rad(225), 0), Color3.fromRGB(80, 90, 120))
		makeDecor(parent, "SpotlightGlow", Vector3.new(1.4, 1.4, 0.2), head.CFrame * CFrame.new(0, 0, -1.35), Color3.fromRGB(255, 245, 200), Enum.Material.Neon)
	end
	-- a giant boxed figure by the door
	local giant = floor * CFrame.new(60, 0, -46)
	makeDecor(parent, "GiantBox", Vector3.new(8, 12, 6), giant * CFrame.new(0, 6, 0), Color3.fromRGB(255, 200, 225))
	makeDecor(parent, "GiantBoxTop", Vector3.new(8.4, 1.4, 6.4), giant * CFrame.new(0, 11.5, 0), Color3.fromRGB(255, 120, 170))
	ball(parent, "GiantFigure", 4.6, giant * CFrame.new(0, 6.5, -2.5), Color3.fromRGB(110, 200, 255))
end

-- Candy Factory ---------------------------------------------------------------------------

local CANDY_COLORS = {
	Color3.fromRGB(255, 120, 180),
	Color3.fromRGB(120, 215, 255),
	Color3.fromRGB(255, 220, 90),
	Color3.fromRGB(150, 235, 130),
	Color3.fromRGB(200, 150, 255),
}

-- A giant lollipop (`at`: the foot of its stick, -Z the way it faces), its white
-- swirl spinning (Atmosphere turns Models tagged "Spinner").
local function lollipop(parent: Instance, at: CFrame, height: number, size: number, color: Color3)
	cylinder(parent, "LollipopStick", 1, height, at, WHITE)
	local head = at * CFrame.new(0, height + size / 2 - 0.5, 0)
	local pop = Instance.new("Model")
	pop.Name = "Lollipop"
	roller(pop, "Lollipop", size, 1.4, head * CFrame.Angles(0, math.pi / 2, 0), color)
	local dots, turns = 12, 2
	for index = 1, dots do
		local t = index / dots
		local angle = t * turns * math.pi * 2
		local radius = t * size * 0.4
		ball(pop, "LollipopSwirl", size * (0.08 + t * 0.07), head * CFrame.new(math.cos(angle) * radius, math.sin(angle) * radius, -0.7), WHITE)
	end
	spinner(pop, parent, head, -0.8)
end

-- A candy cane `scale` times the base size: striped segments up, then a crook bending
-- over toward +X.
local function candyCane(parent: Instance, at: CFrame, color: Color3, scale: number)
	local segment, radius, thickness = 2.4 * scale, 2 * scale, 1.8 * scale
	for index = 0, 4 do
		cylinder(parent, "CandyCane", thickness, segment, at * CFrame.new(0, index * segment, 0), if index % 2 == 0 then color else WHITE)
	end
	-- pieces around an arc, each lying along it (a cylinder's axis is its X)
	local center = at * CFrame.new(radius, 5 * segment, 0)
	for index, degrees in { 30, 90, 150 } do
		local theta = math.rad(degrees)
		local cframe = center * CFrame.new(-radius * math.cos(theta), radius * math.sin(theta), 0) * CFrame.Angles(0, 0, math.atan2(math.cos(theta), math.sin(theta)))
		roller(parent, "CandyCane", thickness, segment, cframe, if index % 2 == 1 then WHITE else color)
	end
end

local function gumdrop(parent: Instance, at: CFrame, size: number, color: Color3)
	cylinder(parent, "Gumdrop", size, size * 0.5, at, color)
	ball(parent, "Gumdrop", size, at * CFrame.new(0, size * 0.5, 0), color)
	-- sugar crystals
	for index = 1, 3 do
		local angle = index * 2.1
		ball(parent, "Sugar", size * 0.12, at * CFrame.new(math.cos(angle) * size * 0.3, size * 0.9, math.sin(angle) * size * 0.3), WHITE)
	end
end

local function wrappedCandy(parent: Instance, at: CFrame, color: Color3, scale: number)
	roller(parent, "Candy", 3 * scale, 3.4 * scale, at * CFrame.new(0, 1.5 * scale, 0), color)
	roller(parent, "CandyStripe", 3.05 * scale, 0.8 * scale, at * CFrame.new(0, 1.5 * scale, 0), WHITE)
	for _, side in { -1, 1 } do
		roller(parent, "CandyWrapper", 2.4 * scale, 1.2 * scale, at * CFrame.new(side * 2.4 * scale, 1.5 * scale, 0), color:Lerp(WHITE, 0.4))
	end
end

-- A gumball machine (`at`: its foot, -Z its front): a glass globe full of gumballs on
-- a colored stand with a coin slot.
local function gumballMachine(parent: Instance, at: CFrame, color: Color3)
	local metal = Color3.fromRGB(215, 220, 230)
	cylinder(parent, "GumballFoot", 8, 1, at, color)
	cylinder(parent, "GumballStand", 4.6, 6, at * CFrame.new(0, 1, 0), color)
	makeDecor(parent, "GumballBox", Vector3.new(6.4, 4, 6.4), at * CFrame.new(0, 8.5, 0), color)
	makeDecor(parent, "GumballSlot", Vector3.new(2.4, 2.4, 0.3), at * CFrame.new(0, 9, -3.3), metal, Enum.Material.Metal)
	makeDecor(parent, "GumballKnob", Vector3.new(0.6, 1.6, 0.6), at * CFrame.new(0, 9, -3.6), color:Lerp(Color3.new(0, 0, 0), 0.25))
	makeDecor(parent, "GumballChute", Vector3.new(1.8, 1.2, 0.8), at * CFrame.new(0, 7.2, -3.4), metal, Enum.Material.Metal)
	local globe = at * CFrame.new(0, 15.5, 0)
	local radius = 5
	local index = 0
	for y = -3, 0.6, 1.8 do
		local room = math.sqrt(radius * radius - y * y) - 1.4 -- keep each gumball inside the glass
		for ring = 1, 2 do
			local r = math.min(room, ring * 1.55)
			local count = if ring == 1 then 3 else 7
			for k = 1, count do
				index += 1
				local angle = k * math.pi * 2 / count + y
				ball(parent, "Gumball", 2.4, globe * CFrame.new(math.cos(angle) * r, y, math.sin(angle) * r), CANDY_COLORS[index % #CANDY_COLORS + 1])
			end
		end
	end
	local glass = ball(parent, "GumballGlobe", radius * 2, globe, Color3.fromRGB(225, 245, 255))
	glass.Transparency = 0.6
	glass.Reflectance = 0.1
	cylinder(parent, "GumballCap", 4.6, 1.6, globe * CFrame.new(0, radius - 0.6, 0), color)
	ball(parent, "GumballTop", 2.2, globe * CFrame.new(0, radius + 1.2, 0), color)
end

-- A giant cupcake (`at`: its foot): a ribbed paper cup, swirls of frosting, sprinkles
-- and a cherry.
local function cupcake(parent: Instance, at: CFrame, cup: Color3, frosting: Color3)
	cylinder(parent, "CupcakeCup", 8, 5.5, at, cup)
	for index = 1, 10 do
		local angle = index * math.pi * 2 / 10
		makeDecor(parent, "CupcakeRib", Vector3.new(0.7, 5.5, 0.4), at * CFrame.new(math.cos(angle) * 3.95, 2.75, math.sin(angle) * 3.95) * CFrame.Angles(0, -angle + math.pi / 2, 0), WHITE)
	end
	cylinder(parent, "CupcakeCake", 8.6, 1.2, at * CFrame.new(0, 5.5, 0), Color3.fromRGB(240, 185, 120))
	local swirls = { { 6.6, 4.2 }, { 8.9, 3.2 }, { 11.2, 2.1 } } -- each swirl's center height and radius
	for _, swirl in swirls do
		ball(parent, "Frosting", swirl[2] * 2, at * CFrame.new(0, swirl[1], 0), frosting)
	end
	-- sprinkles on the two lower swirls, 30° up their sides
	for index = 1, 12 do
		local swirl = swirls[index % 2 + 1]
		local angle = index * math.pi * 2 / 12
		local r, y = swirl[2] * 0.866, swirl[1] + swirl[2] * 0.5
		makeDecor(parent, "Sprinkle", Vector3.new(0.3, 1, 0.3), at * CFrame.new(math.cos(angle) * r, y, math.sin(angle) * r) * CFrame.Angles(index, 0, index * 0.7), CANDY_COLORS[index % #CANDY_COLORS + 1])
	end
	ball(parent, "Cherry", 2.2, at * CFrame.new(0, 13.6, 0), Color3.fromRGB(235, 40, 70))
	makeDecor(parent, "CherryStem", Vector3.new(0.25, 1.8, 0.25), at * CFrame.new(0.4, 15.2, 0) * CFrame.Angles(0, 0, math.rad(-20)), Color3.fromRGB(90, 160, 60))
end

local function buildCandy(parent: Instance, floor: CFrame)
	-- giant lollipops along the front wall, facing the door at the back
	for index, x in { -40, -14, 14, 40 } do
		lollipop(parent, floor * CFrame.new(x, 0, -54) * CFrame.Angles(0, math.pi, 0), 11 + (index % 2) * 4, 10, CANDY_COLORS[index])
	end
	candyCane(parent, floor * CFrame.new(-63, 0, -52), Color3.fromRGB(255, 90, 120), 1.6)
	candyCane(parent, floor * CFrame.new(60, 0, -52) * CFrame.Angles(0, math.pi, 0), Color3.fromRGB(120, 200, 255), 1.6)
	gumballMachine(parent, floor * CFrame.new(-60, 0, -24) * CFrame.Angles(0, -math.pi / 2, 0), Color3.fromRGB(255, 70, 110))
	gumballMachine(parent, floor * CFrame.new(60, 0, 14) * CFrame.Angles(0, math.pi / 2, 0), Color3.fromRGB(80, 170, 255))
	cupcake(parent, floor * CFrame.new(-59, 0, 22), Color3.fromRGB(255, 150, 200), Color3.fromRGB(255, 245, 250))
	cupcake(parent, floor * CFrame.new(59, 0, -24), Color3.fromRGB(120, 215, 255), Color3.fromRGB(255, 160, 210))
	for index, spot in { Vector3.new(-62, 0, -6), Vector3.new(-60, 0, 40), Vector3.new(62, 0, -6), Vector3.new(62, 0, 32), Vector3.new(-30, 0, 54) } do
		gumdrop(parent, floor * CFrame.new(spot), 4 + (index % 3) * 1.5, CANDY_COLORS[index])
	end
	-- a chocolate vat
	local vat = floor * CFrame.new(54, 0, 48)
	cylinder(parent, "Vat", 13, 6, vat, Color3.fromRGB(235, 225, 240), Enum.Material.Metal)
	cylinder(parent, "Chocolate", 12, 0.4, vat * CFrame.new(0, 5.8, 0), Color3.fromRGB(120, 70, 45))
	cylinder(parent, "VatRim", 13.6, 0.8, vat * CFrame.new(0, 6, 0), Color3.fromRGB(255, 150, 200))
	makeDecor(parent, "VatPaddle", Vector3.new(0.6, 9, 0.6), vat * CFrame.new(1.5, 8, 0) * CFrame.Angles(0, 0, math.rad(20)), Color3.fromRGB(225, 180, 125), Enum.Material.Wood)
	wrappedCandy(parent, floor * CFrame.new(-54, 0, 50), CANDY_COLORS[3], 1.8)
	wrappedCandy(parent, floor * CFrame.new(28, 0, 53), CANDY_COLORS[5], 1.8)
end

-- API --------------------------------------------------------------------------------

local BUILDERS: { [string]: (Instance, CFrame) -> () } = {
	PlushieRoom = buildPlushie,
	ClayStudio = buildClay,
	VinylCollectibles = buildVinyl,
	CandyFactory = buildCandy,
}

-- Builds `zoneId`'s props into `parent` (rooms without any are left as they are).
function RoomDecor.Build(zoneId: string, parent: Instance, floor: CFrame)
	local build = BUILDERS[zoneId]
	if build then
		build(parent, floor)
	end
end

return RoomDecor
