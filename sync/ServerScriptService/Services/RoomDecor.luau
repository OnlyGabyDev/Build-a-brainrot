--[[
	RoomDecor
	Themed props inside the factory's rooms (GDD §10), so every room is lovely on its
	own, before any upgrade: the playable rooms (Toy Workshop, Plushie room) get a neon
	sign over the door, flags or string lights round the walls, race tracks or catwalks
	down the walkways between the lines with lamps over them, shelves of toys or racks of
	thread and fabric, posters, a clock, a case of brainrot plushies, giant toys and
	sewing machines; the locked rooms show their theme through their glass doors.

	Room space: `floor` is the room's floor center, -Z toward the building's front (the
	hub). Rooms are 140 × 120. The lines run along Z at X = -42, 0 and 42 (from Z = -38
	to 54), each with its buttons on its +X side: props keep to the walls, the front
	corners and the walkways' floors and ceilings, clear of the doors: the front doorway
	(Z = -60, |X| < 13), the Clay Studio's side door (X = +70 around Z = 31) and the
	Candy Factory's (Z = +60, |X| < 8). Room upgrades (RoomUpgrades) have spots of their
	own. FactoryBuilder calls RoomDecor.Build for every room.
]]

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BrainrotModels = require(ReplicatedStorage.Shared.BrainrotModels)
local Brainrots = require(ReplicatedStorage.Shared.Config.Brainrots)

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

-- A spot on a wall's inner face, room space: { X, Y, Z } on the face, and the way
-- into the room (only along X or Z). The side walls' faces are at X = ±68, an outer
-- front or back wall's at Z = ±58, a wall between two rooms' at Z = ±59.
type WallSpot = { number }

-- Things on a wall must not end in the planes of what's already on it, or they
-- flicker where they meet (z-fighting): FactoryBuilder's wainscot band stands 0.3 off the
-- wall, a window's frame 0.4 and its glass 0.5, the wallpaper 0.1. Faces go between those
-- (0.42, 0.62...), checked with tools/lab (analyze.py zfight).

-- The spot's CFrame, -Z pointing into the room.
local function wallFace(floor: CFrame, spot: WallSpot): CFrame
	local at = Vector3.new(spot[1], spot[2], spot[3])
	local inward = if math.abs(spot[1]) >= 68 then Vector3.new(-math.sign(spot[1]), 0, 0) else Vector3.new(0, 0, -math.sign(spot[3]))
	return floor * CFrame.lookAt(at, at + inward)
end

local function wedge(parent: Instance, name: string, size: Vector3, cframe: CFrame, color: Color3, material: Enum.Material?): WedgePart
	local part = Instance.new("WedgePart")
	part.Name = name
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.CastShadow = false
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.Parent = parent
	return part
end

-- A rod (length along its Z) from `from` to `to`, world positions.
local function rod(parent: Instance, name: string, thickness: number, from: Vector3, to: Vector3, color: Color3, material: Enum.Material?): Part
	return makeDecor(parent, name, Vector3.new(thickness, thickness, (to - from).Magnitude), CFrame.lookAt((from + to) / 2, to), color, material)
end

-- Text (or an emoji) on `part`'s `face`. `glow`: neon-bright, in a stroke of that color.
local function label(part: BasePart, face: Enum.NormalId, text: string, color: Color3, glow: Color3?, pixels: number?): TextLabel
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = pixels or 20
	gui.LightInfluence = 0
	if glow then
		gui.Brightness = 2.5 -- past 1, so it blooms like neon
	end
	gui.Parent = part
	local text_ = Instance.new("TextLabel")
	text_.Size = UDim2.fromScale(0.92, 0.8)
	text_.Position = UDim2.fromScale(0.04, 0.1)
	text_.BackgroundTransparency = 1
	text_.Font = Enum.Font.FredokaOne
	text_.TextScaled = true
	text_.TextColor3 = color
	text_.Text = text
	text_.Parent = gui
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = if glow then 4 else 2
	stroke.Color = glow or Color3.fromRGB(60, 40, 70)
	stroke.Parent = text_
	return text_
end

-- A neon sign on a wall (`face`: its middle on the wall, -Z into the room): a dark
-- panel framed by neon tubes, its words in glowing letters.
local SIGN_BACK = Color3.fromRGB(40, 28, 60)
local function neonSign(parent: Instance, face: CFrame, size: Vector2, text: string, color: Color3)
	local panel = makeDecor(parent, "NeonSign", Vector3.new(size.X, size.Y, 0.52), face * CFrame.new(0, 0, -0.36), SIGN_BACK)
	label(panel, Enum.NormalId.Front, text, color:Lerp(WHITE, 0.65), color)
	local tube = color:Lerp(WHITE, 0.3)
	for _, y in { -1, 1 } do
		makeDecor(parent, "NeonTube", Vector3.new(size.X + 0.6, 0.35, 0.35), face * CFrame.new(0, y * (size.Y / 2 + 0.15), -0.55), tube, Enum.Material.Neon)
	end
	for _, x in { -1, 1 } do
		makeDecor(parent, "NeonTube", Vector3.new(0.35, size.Y + 0.6, 0.35), face * CFrame.new(x * (size.X / 2 + 0.15), 0, -0.55), tube, Enum.Material.Neon)
	end
end
RoomDecor.NeonSign = neonSign -- (FactoryBuilder's elevator wears one too)

-- A sagging string of triangle flags from `from` to `to` (world positions).
local function bunting(parent: Instance, from: Vector3, to: Vector3, colors: { Color3 }, sag: number)
	local middle = (from + to) / 2 - Vector3.new(0, sag, 0)
	local index = 0
	for _, span in { { from, middle }, { middle, to } } do
		local a, b = span[1], span[2]
		local length = (b - a).Magnitude
		local line = CFrame.lookAt((a + b) / 2, b)
		makeDecor(parent, "BuntingLine", Vector3.new(0.12, 0.12, length), line, WHITE).CastShadow = false
		local count = math.max(1, math.floor(length / 3.4))
		for k = 1, count do
			index += 1
			local z = -length / 2 + (k - 0.5) * length / count
			-- a wedge hanging point down, its tall end at the line
			wedge(parent, "Bunting", Vector3.new(0.1, 2, 1.8), line * CFrame.new(0, -1, z) * CFrame.Angles(math.pi, 0, 0), colors[(index - 1) % #colors + 1])
		end
	end
end

-- A bunch of balloons on strings, tied at `at`, bobbing (Atmosphere bobs Models
-- tagged "Bobbing"). `seed` picks their colors.
local function balloons(parent: Instance, at: CFrame, count: number, seed: number, colors: { Color3 })
	local bunch = Instance.new("Model")
	bunch.Name = "Balloons"
	for index = 1, count do
		local angle = index * 2.4 + seed
		local top = at * CFrame.new(math.cos(angle) * 1.8, 7 + (index % 3) * 1.3, math.sin(angle) * 1.8)
		local color = colors[(index + seed) % #colors + 1]
		local balloon = ball(bunch, "Balloon", 3.2, top, color)
		balloon.Reflectance = 0.1
		ball(bunch, "BalloonKnot", 0.6, top * CFrame.new(0, -1.7, 0), color)
		rod(bunch, "BalloonString", 0.1, at.Position, (top * CFrame.new(0, -1.9, 0)).Position, WHITE)
	end
	bunch.WorldPivot = at
	CollectionService:AddTag(bunch, "Bobbing")
	bunch.Parent = parent
end

-- A lamp hanging from the ceiling (`at`: the point on the ceiling) on a cord `drop`
-- long: a colored dome shade over a glowing bulb.
local function pendantLamp(parent: Instance, at: CFrame, drop: number, color: Color3)
	makeDecor(parent, "LampCord", Vector3.new(0.15, drop, 0.15), at * CFrame.new(0, -drop / 2, 0), Color3.fromRGB(70, 55, 80))
	local shade = at * CFrame.new(0, -drop, 0)
	ball(parent, "LampShade", 3.6, shade * CFrame.new(0, -0.7, 0), color)
	cylinder(parent, "LampRim", 3.8, 0.4, shade * CFrame.new(0, -1.2, 0), WHITE)
	ball(parent, "LampBulb", 1.6, shade * CFrame.new(0, -1.5, 0), Color3.fromRGB(255, 240, 190), Enum.Material.Neon).CastShadow = false
end

-- A two-sided neon sign hanging from the ceiling on two chains (`at`: the point on the
-- ceiling over its middle, -Z one of its faces), its bottom `drop` below the ceiling.
local function hangingSign(parent: Instance, at: CFrame, drop: number, size: Vector2, text: string, color: Color3)
	local middle = at * CFrame.new(0, -drop + size.Y / 2, 0)
	local panel = makeDecor(parent, "HangingSign", Vector3.new(size.X, size.Y, 0.4), middle, SIGN_BACK)
	label(panel, Enum.NormalId.Front, text, color:Lerp(WHITE, 0.65), color)
	label(panel, Enum.NormalId.Back, text, color:Lerp(WHITE, 0.65), color)
	local tube = color:Lerp(WHITE, 0.3)
	for _, y in { -1, 1 } do
		makeDecor(parent, "NeonTube", Vector3.new(size.X + 0.6, 0.35, 0.6), middle * CFrame.new(0, y * (size.Y / 2 + 0.15), 0), tube, Enum.Material.Neon)
	end
	for _, x in { -1, 1 } do
		makeDecor(parent, "NeonTube", Vector3.new(0.35, size.Y + 0.6, 0.6), middle * CFrame.new(x * (size.X / 2 + 0.15), 0, 0), tube, Enum.Material.Neon)
		local top = (middle * CFrame.new(x * size.X * 0.35, size.Y / 2 + 0.3, 0)).Position
		rod(parent, "SignChain", 0.15, top, (at * CFrame.new(x * size.X * 0.35, 0, 0)).Position, Color3.fromRGB(190, 195, 210), Enum.Material.Metal)
	end
end

-- A framed poster on a wall (`face`: its middle on the wall, -Z into the room): a big
-- emoji on a colored background, a caption under it.
local function poster(parent: Instance, face: CFrame, size: Vector2, background: Color3, frame: Color3, emoji: string, caption: string)
	makeDecor(parent, "PosterFrame", Vector3.new(size.X + 0.8, size.Y + 0.8, 0.42), face * CFrame.new(0, 0, -0.21), frame)
	local sheet = makeDecor(parent, "Poster", Vector3.new(size.X, size.Y, 0.2), face * CFrame.new(0, 0, -0.38), background)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 16
	gui.LightInfluence = 0
	gui.Parent = sheet
	local picture = Instance.new("TextLabel")
	picture.Size = UDim2.fromScale(0.9, 0.66)
	picture.Position = UDim2.fromScale(0.05, 0.04)
	picture.BackgroundTransparency = 1
	picture.TextScaled = true
	picture.Text = emoji
	picture.Parent = gui
	local words = Instance.new("TextLabel")
	words.Size = UDim2.fromScale(0.9, 0.24)
	words.Position = UDim2.fromScale(0.05, 0.72)
	words.BackgroundTransparency = 1
	words.Font = Enum.Font.FredokaOne
	words.TextScaled = true
	words.TextColor3 = WHITE
	words.Text = caption
	words.Parent = gui
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2
	stroke.Color = frame:Lerp(Color3.new(0, 0, 0), 0.4)
	stroke.Parent = words
end

-- A wall shelf (`face`: on the wall at the floor under the shelf's middle, -Z into
-- the room): a back board with a scalloped top, two shelves on brackets, and a row
-- of things on each (`things` builds one at a CFrame on the shelf, by index).
local function wallShelf(parent: Instance, face: CFrame, width: number, board: Color3, trim: Color3, things: (parent: Instance, at: CFrame, index: number) -> ())
	makeDecor(parent, "ShelfBack", Vector3.new(width + 1, 12.5, 0.42), face * CFrame.new(0, 14.5, -0.21), board)
	local scallops = math.floor(width / 3)
	for index = 0, scallops do
		-- discs standing in the wall's plane, their tops peeking over the board
		local disc = makeDecor(parent, "ShelfScallop", Vector3.new(0.3, 2.6, 2.6), face * CFrame.new(-width / 2 + 0.5 + index * width / scallops, 20.7, -0.2) * CFrame.Angles(0, math.pi / 2, 0), trim)
		disc.Shape = Enum.PartType.Cylinder
	end
	local count = 0
	for _, y in { 9.6, 15.2 } do
		makeDecor(parent, "Shelf", Vector3.new(width + 1, 0.5, 3.2), face * CFrame.new(0, y - 0.25, -1.6), trim)
		for _, x in { -1, 1 } do
			wedge(parent, "ShelfBracket", Vector3.new(0.4, 1.6, 1.6), face * CFrame.new(x * width / 2, y - 1.3, -0.95) * CFrame.Angles(0, 0, math.pi), board:Lerp(Color3.new(0, 0, 0), 0.2))
		end
		local slots = math.max(2, math.floor(width / 4.2))
		for k = 1, slots do
			count += 1
			things(parent, face * CFrame.new(-width / 2 + (k - 0.5) * width / slots, y, -1.6), count)
		end
	end
end

-- An emoji on `part`'s `face`, filling most of it.
local function emojiOn(part: BasePart, face: Enum.NormalId, emoji: string)
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 12
	gui.LightInfluence = 0
	gui.Parent = part
	local text = Instance.new("TextLabel")
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundTransparency = 1
	text.TextScaled = true
	text.Text = emoji
	text.Parent = gui
end

-- Toy Workshop -------------------------------------------------------------------------

local TOY_COLORS = {
	Color3.fromRGB(255, 95, 110), -- red
	Color3.fromRGB(255, 205, 60), -- yellow
	Color3.fromRGB(70, 165, 255), -- blue
	Color3.fromRGB(110, 210, 95), -- green
	Color3.fromRGB(175, 115, 255), -- purple
	Color3.fromRGB(255, 150, 60), -- orange
}
local WOOD = Color3.fromRGB(225, 175, 120)
local INK = Color3.fromRGB(55, 40, 60)

-- Little toys for the shelves (`at`: on the shelf, -Z toward the room).

-- A collectible blind box: a colored card box with a clear window, a little figure
-- inside, a hanging tab on top.
local function miniPackage(parent: Instance, at: CFrame, color: Color3)
	makeDecor(parent, "MiniBox", Vector3.new(2, 2.8, 1.2), at * CFrame.new(0, 1.4, 0.1), color)
	makeDecor(parent, "MiniBoxTab", Vector3.new(1.2, 0.6, 0.15), at * CFrame.new(0, 3.1, 0.6), color:Lerp(Color3.new(0, 0, 0), 0.2))
	ball(parent, "MiniFigure", 0.9, at * CFrame.new(0, 1.9, -0.35), color:Lerp(WHITE, 0.55))
	cylinder(parent, "MiniFigureBody", 0.7, 0.8, at * CFrame.new(0, 0.7, -0.35), color:Lerp(WHITE, 0.3))
	local window = makeDecor(parent, "MiniWindow", Vector3.new(1.6, 2, 0.1), at * CFrame.new(0, 1.55, -0.55), Color3.fromRGB(220, 240, 255))
	window.Transparency = 0.55
	window.Reflectance = 0.2
end

-- A tin wind-up robot: boxy body and head, an antenna, a key in its back.
local function windupRobot(parent: Instance, at: CFrame, color: Color3)
	local metal = Color3.fromRGB(205, 210, 225)
	makeDecor(parent, "RobotBody", Vector3.new(1.6, 1.6, 1.1), at * CFrame.new(0, 1.2, 0), color, Enum.Material.Metal)
	makeDecor(parent, "RobotHead", Vector3.new(1.2, 1, 1), at * CFrame.new(0, 2.5, 0), metal, Enum.Material.Metal)
	for _, x in { -0.3, 0.3 } do
		ball(parent, "RobotEye", 0.3, at * CFrame.new(x, 2.55, -0.5), Color3.fromRGB(120, 230, 255), Enum.Material.Neon)
		makeDecor(parent, "RobotLeg", Vector3.new(0.45, 0.45, 0.6), at * CFrame.new(x * 1.6, 0.22, 0), metal, Enum.Material.Metal)
	end
	makeDecor(parent, "RobotAntenna", Vector3.new(0.12, 0.6, 0.12), at * CFrame.new(0, 3.3, 0), metal)
	ball(parent, "RobotAntennaTip", 0.35, at * CFrame.new(0, 3.65, 0), Color3.fromRGB(255, 80, 100), Enum.Material.Neon)
	makeDecor(parent, "RobotKey", Vector3.new(0.9, 0.5, 0.12), at * CFrame.new(0, 1.3, 0.75), Color3.fromRGB(255, 200, 60))
end

local function toyCar(parent: Instance, at: CFrame, color: Color3)
	makeDecor(parent, "CarBody", Vector3.new(3.2, 1, 1.8), at * CFrame.new(0, 1, 0), color)
	makeDecor(parent, "CarCabin", Vector3.new(1.8, 0.9, 1.6), at * CFrame.new(-0.2, 1.95, 0), Color3.fromRGB(190, 230, 255))
	makeDecor(parent, "CarRoof", Vector3.new(1.9, 0.2, 1.7), at * CFrame.new(-0.2, 2.45, 0), color)
	for _, x in { -1.05, 1.05 } do
		for _, z in { -0.95, 0.95 } do
			local wheel = makeDecor(parent, "CarWheel", Vector3.new(0.45, 1, 1), at * CFrame.new(x, 0.5, z) * CFrame.Angles(0, math.pi / 2, 0), Color3.fromRGB(50, 45, 60))
			wheel.Shape = Enum.PartType.Cylinder
		end
	end
end

local function toyRocket(parent: Instance, at: CFrame)
	local red = Color3.fromRGB(255, 80, 90)
	cylinder(parent, "RocketBody", 1.5, 2.8, at * CFrame.new(0, 0.4, 0), Color3.fromRGB(245, 245, 250))
	ball(parent, "RocketNose", 1.5, at * CFrame.new(0, 3.2, 0), red)
	ball(parent, "RocketTip", 0.7, at * CFrame.new(0, 3.95, 0), red)
	ball(parent, "RocketWindow", 0.7, at * CFrame.new(0, 2.3, -0.6), Color3.fromRGB(110, 200, 255))
	for index = 0, 2 do
		local turn = at * CFrame.Angles(0, index * math.pi * 2 / 3, 0)
		makeDecor(parent, "RocketFin", Vector3.new(0.2, 1.4, 1), turn * CFrame.new(0, 0.7, 0.9), red)
	end
end

local function beachBall(parent: Instance, at: CFrame)
	local center = at * CFrame.new(0, 1.2, 0)
	ball(parent, "BeachBall", 2.4, center, Color3.fromRGB(255, 95, 110))
	for index, color in { WHITE, Color3.fromRGB(70, 165, 255), Color3.fromRGB(255, 205, 60) } do
		local band = makeDecor(parent, "BeachBallBand", Vector3.new(0.45, 2.46, 2.46), center * CFrame.Angles(0, index * math.pi / 3, 0), color)
		band.Shape = Enum.PartType.Cylinder
	end
end

local SHELF_TOYS: { (parent: Instance, at: CFrame, index: number) -> () } = {
	function(parent, at, index)
		miniPackage(parent, at, TOY_COLORS[index % #TOY_COLORS + 1])
	end,
	function(parent, at)
		toyRocket(parent, at)
	end,
	function(parent, at, index)
		windupRobot(parent, at, TOY_COLORS[(index + 2) % #TOY_COLORS + 1])
	end,
	function(parent, at, index)
		toyCar(parent, at, TOY_COLORS[index % #TOY_COLORS + 1])
	end,
	function(parent, at, index)
		miniPackage(parent, at, TOY_COLORS[(index + 3) % #TOY_COLORS + 1])
	end,
	function(parent, at)
		beachBall(parent, at)
	end,
}

local function shelfToy(parent: Instance, at: CFrame, index: number)
	SHELF_TOYS[(index - 1) % #SHELF_TOYS + 1](parent, at, index)
end

-- An arcade claw machine (`at`: its foot, -Z its front): a cabinet with a joystick and
-- a glowing button, a glass case of plush prizes with the claw hanging over them, and a
-- lit-up header with chasing bulbs.
local function clawMachine(parent: Instance, at: CFrame, color: Color3)
	local dark = color:Lerp(Color3.new(0, 0, 0), 0.35)
	makeDecor(parent, "ClawCabinet", Vector3.new(5.6, 4.4, 5.6), at * CFrame.new(0, 2.2, 0), color)
	makeDecor(parent, "ClawCabinetTrim", Vector3.new(5.8, 0.35, 5.8), at * CFrame.new(0, 4.3, 0), TOY_COLORS[2], Enum.Material.Neon)
	makeDecor(parent, "ClawPrizeDoor", Vector3.new(1.8, 1.4, 0.2), at * CFrame.new(1.2, 1.2, -2.85), INK)
	makeDecor(parent, "ClawStick", Vector3.new(0.25, 1, 0.25), at * CFrame.new(-1.2, 4.9, -2.3), Color3.fromRGB(60, 50, 70))
	ball(parent, "ClawStickKnob", 0.7, at * CFrame.new(-1.2, 5.45, -2.3), TOY_COLORS[1])
	ball(parent, "ClawButton", 0.9, at * CFrame.new(0.4, 4.5, -2.4), TOY_COLORS[4], Enum.Material.Neon)
	-- the glass case, its corner posts, and the prizes in it
	local glass = makeDecor(parent, "ClawGlass", Vector3.new(5.2, 6, 5.2), at * CFrame.new(0, 7.4, 0), Color3.fromRGB(215, 240, 255), Enum.Material.Glass)
	glass.Transparency = 0.7
	for _, corner in { Vector2.new(-1, -1), Vector2.new(-1, 1), Vector2.new(1, -1), Vector2.new(1, 1) } do
		makeDecor(parent, "ClawPost", Vector3.new(0.4, 6, 0.4), at * CFrame.new(corner.X * 2.65, 7.4, corner.Y * 2.65), dark)
	end
	for index = 1, 9 do
		local angle = index * 2.3
		ball(parent, "ClawPrize", 1.2 + (index % 3) * 0.2, at * CFrame.new(math.cos(angle) * 1.4, 5.1 + (index % 2) * 0.6, math.sin(angle) * 1.4), TOY_COLORS[index % #TOY_COLORS + 1], Enum.Material.Fabric)
	end
	makeDecor(parent, "ClawRod", Vector3.new(0.2, 2, 0.2), at * CFrame.new(0.6, 9.4, 0.4), Color3.fromRGB(205, 210, 225), Enum.Material.Metal)
	makeDecor(parent, "ClawHand", Vector3.new(0.9, 0.5, 0.9), at * CFrame.new(0.6, 8.2, 0.4), TOY_COLORS[2])
	for index = 0, 2 do
		local finger = at * CFrame.new(0.6, 7.6, 0.4) * CFrame.Angles(0, index * math.pi * 2 / 3, 0)
		makeDecor(parent, "ClawFinger", Vector3.new(0.15, 1, 0.15), finger * CFrame.new(0, 0, -0.45) * CFrame.Angles(math.rad(-20), 0, 0), Color3.fromRGB(205, 210, 225), Enum.Material.Metal)
	end
	-- the header: a neon CLAW sign front and back, bulbs chasing round its edge
	local header = makeDecor(parent, "ClawHeader", Vector3.new(5.8, 1.8, 5.8), at * CFrame.new(0, 11.3, 0), dark)
	label(header, Enum.NormalId.Front, "CLAW", TOY_COLORS[2]:Lerp(WHITE, 0.5), TOY_COLORS[2])
	label(header, Enum.NormalId.Back, "CLAW", TOY_COLORS[2]:Lerp(WHITE, 0.5), TOY_COLORS[2])
	local count = 0
	for side = 0, 3 do
		local edge = at * CFrame.Angles(0, side * math.pi / 2, 0)
		for k = 0, 3 do
			count += 1
			local bulb = ball(parent, "ClawBulb", 0.55, edge * CFrame.new(-2.2 + k * 1.47, 12.4, -2.95), Color3.fromRGB(255, 215, 130), Enum.Material.Neon)
			bulb.CastShadow = false
			bulb:SetAttribute("Index", count)
			CollectionService:AddTag(bulb, "Marquee")
		end
	end
end

-- A stack of shipping crates (`at`: on the floor under the stack): cardboard boxes
-- with tape, printed with the BRAINROT TOYS logo, FRAGILE and arrows.
local function shippingCrates(parent: Instance, at: CFrame)
	local cardboard = Color3.fromRGB(210, 160, 105)
	local tape = Color3.fromRGB(240, 205, 130)
	local prints = { "BRAINROT\nTOYS ★", "FRAGILE!", "⬆ ⬆", "BRAINROT\nTOYS ★" }
	-- in a box only as tall as its lines: in a square one, TextScaled breaks a word to
	-- get bigger letters ("FRA GILE!")
	local function stamp(box: BasePart, face: Enum.NormalId, text: string)
		local printed = label(box, face, text, Color3.fromRGB(150, 70, 40), nil, 30)
		local height = if string.find(text, "\n") then 0.6 else 0.35
		printed.Size = UDim2.fromScale(0.92, height)
		printed.Position = UDim2.fromScale(0.04, (1 - height) / 2)
	end
	for index, crate in {
		{ At = Vector3.new(0, 0, -2.4), Size = Vector3.new(4.6, 4.2, 4.6), Turn = 0.08 },
		{ At = Vector3.new(0.2, 0, 2.4), Size = Vector3.new(4.4, 3.8, 4.4), Turn = -0.12 },
		{ At = Vector3.new(0, 4.2, -1.8), Size = Vector3.new(3.8, 3.4, 3.8), Turn = 0.3 },
		{ At = Vector3.new(0.4, 3.8, 2.6), Size = Vector3.new(3, 2.6, 3), Turn = -0.25 },
	} do
		local box = makeDecor(parent, "Crate", crate.Size, at * CFrame.new(crate.At + Vector3.new(0, crate.Size.Y / 2, 0)) * CFrame.Angles(0, crate.Turn, 0), cardboard)
		makeDecor(parent, "CrateTape", Vector3.new(crate.Size.X + 0.1, 0.5, crate.Size.Z * 0.25), box.CFrame * CFrame.new(0, crate.Size.Y / 2, 0), tape)
		stamp(box, Enum.NormalId.Left, prints[index])
		stamp(box, Enum.NormalId.Front, prints[(index % #prints) + 1])
	end
end

-- A toy race track down a walkway (centered on `x`, from `fromZ` to `toZ`): an orange
-- lane with blue bumpers, a dashed white middle line and a checkered finish line.
local function raceTrack(parent: Instance, floor: CFrame, x: number, fromZ: number, toZ: number)
	local length = toZ - fromZ
	local middle = (fromZ + toZ) / 2
	makeDecor(parent, "Track", Vector3.new(10, 0.12, length), floor * CFrame.new(x, 0.06, middle), Color3.fromRGB(255, 125, 25))
	for _, side in { -1, 1 } do
		makeDecor(parent, "TrackBumper", Vector3.new(0.7, 0.4, length), floor * CFrame.new(x + side * 5.1, 0.2, middle), Color3.fromRGB(40, 120, 255))
	end
	for z = fromZ + 2, toZ - 2, 4 do
		makeDecor(parent, "TrackDash", Vector3.new(0.35, 0.13, 2), floor * CFrame.new(x, 0.07, z), WHITE)
	end
	for row = 0, 1 do
		for column = 0, 9 do
			makeDecor(parent, "TrackFinish", Vector3.new(1, 0.14, 1), floor * CFrame.new(x - 4.5 + column, 0.08, toZ - 1.5 + row), if (row + column) % 2 == 0 then INK else WHITE)
		end
	end
end

-- A pegboard on a wall (`face`: its middle, -Z into the room) with giant toy tools
-- hung on pegs: a hammer, a wrench and a screwdriver.
local function toolBoard(parent: Instance, face: CFrame, width: number)
	local height = 13
	makeDecor(parent, "PegboardFrame", Vector3.new(width + 1.2, height + 1.2, 0.4), face * CFrame.new(0, 0, -0.2), TOY_COLORS[5])
	makeDecor(parent, "Pegboard", Vector3.new(width, height, 0.3), face * CFrame.new(0, 0, -0.4), Color3.fromRGB(245, 210, 155), Enum.Material.Wood)
	local third = width / 3
	-- the hammer
	local hammer = face * CFrame.new(-third, 0, -0.9) * CFrame.Angles(0, 0, math.rad(-12))
	makeDecor(parent, "HammerHandle", Vector3.new(0.9, 7.5, 0.6), hammer * CFrame.new(0, -0.8, 0), WOOD, Enum.Material.Wood)
	makeDecor(parent, "HammerHead", Vector3.new(4, 1.8, 1.3), hammer * CFrame.new(0, 3.4, 0), TOY_COLORS[1])
	makeDecor(parent, "HammerGrip", Vector3.new(1.1, 2.2, 0.8), hammer * CFrame.new(0, -3.4, 0), TOY_COLORS[2])
	-- the wrench
	local wrench = face * CFrame.new(0, 0, -0.9) * CFrame.Angles(0, 0, math.rad(8))
	makeDecor(parent, "WrenchHandle", Vector3.new(1.1, 7, 0.6), wrench, TOY_COLORS[3])
	for _, y in { -1, 1 } do
		local ring = makeDecor(parent, "WrenchEnd", Vector3.new(0.6, 2.8, 2.8), wrench * CFrame.new(0, y * 3.8, 0) * CFrame.Angles(0, math.pi / 2, 0), TOY_COLORS[3])
		ring.Shape = Enum.PartType.Cylinder
		makeDecor(parent, "WrenchJaw", Vector3.new(1, 1.4, 0.7), wrench * CFrame.new(0, y * 4.6, 0), Color3.fromRGB(245, 210, 155), Enum.Material.Wood)
	end
	-- the screwdriver
	local driver = face * CFrame.new(third, 0, -0.9) * CFrame.Angles(0, 0, math.rad(-6))
	local handle = makeDecor(parent, "DriverHandle", Vector3.new(3.4, 1.8, 1.8), driver * CFrame.new(0, -2, 0) * CFrame.Angles(0, 0, math.pi / 2), TOY_COLORS[2])
	handle.Shape = Enum.PartType.Cylinder
	local band = makeDecor(parent, "DriverBand", Vector3.new(0.5, 1.9, 1.9), driver * CFrame.new(0, -0.6, 0) * CFrame.Angles(0, 0, math.pi / 2), TOY_COLORS[1])
	band.Shape = Enum.PartType.Cylinder
	makeDecor(parent, "DriverShaft", Vector3.new(0.4, 4.6, 0.4), driver * CFrame.new(0, 1.7, 0), Color3.fromRGB(205, 210, 225), Enum.Material.Metal)
	-- pegs over each tool
	for _, x in { -third, 0, third } do
		ball(parent, "Peg", 0.6, face * CFrame.new(x, height / 2 - 1.2, -0.6), INK)
	end
end

-- A big toy clock on a wall (`face`: its middle, -Z into the room): colored dots for
-- the hours, and a minute hand that sweeps round (a Spinner about the wall's normal).
local function toyClock(parent: Instance, face: CFrame, diameter: number)
	local function disc(name: string, size: number, depth: number, out: number, color: Color3)
		local part = makeDecor(parent, name, Vector3.new(depth, size, size), face * CFrame.new(0, 0, -out - depth / 2) * CFrame.Angles(0, math.pi / 2, 0), color)
		part.Shape = Enum.PartType.Cylinder
	end
	disc("ClockRim", diameter + 1.4, 0.6, 0, TOY_COLORS[1])
	disc("ClockFace", diameter, 0.3, 0.6, WHITE)
	for hour = 1, 12 do
		local angle = hour / 12 * math.pi * 2
		ball(parent, "ClockDot", if hour % 3 == 0 then 1.3 else 0.8, face * CFrame.new(math.sin(angle) * diameter * 0.4, math.cos(angle) * diameter * 0.4, -1), TOY_COLORS[hour % #TOY_COLORS + 1])
	end
	makeDecor(parent, "ClockHourHand", Vector3.new(0.7, diameter * 0.24, 0.2), face * CFrame.new(0, 0, -1.1) * CFrame.Angles(0, 0, math.rad(-60)) * CFrame.new(0, diameter * 0.12, 0), INK)
	local hand = Instance.new("Model")
	hand.Name = "ClockHand"
	makeDecor(hand, "ClockMinuteHand", Vector3.new(0.5, diameter * 0.38, 0.2), face * CFrame.new(0, diameter * 0.19, -1.3), TOY_COLORS[3])
	spinner(hand, parent, face * CFrame.new(0, 0, -1.3), -0.5)
	ball(parent, "ClockPin", 1, face * CFrame.new(0, 0, -1.45), TOY_COLORS[2])
end

local function buildToy(parent: Instance, floor: CFrame)
	-- the sign over the entrance, and flags round the walls up by the ceiling (clear of
	-- the doorway's sign on the back wall)
	neonSign(parent, wallFace(floor, { 0, 23.2, -58 }), Vector2.new(30, 5.4), "🪀 TOY WORKSHOP 🪀", TOY_COLORS[2])
	local function at(x: number, y: number, z: number): Vector3
		return (floor * CFrame.new(x, y, z)).Position
	end
	for _, x in { -67, 67 } do
		bunting(parent, at(x, 26, -56), at(x, 26, 0), TOY_COLORS, 1.6)
		bunting(parent, at(x, 26, 0), at(x, 26, 56), TOY_COLORS, 1.6)
	end
	for _, z in { -57, 58 } do
		bunting(parent, at(-66, 26, z), at(-21, 26, z), TOY_COLORS, 1.6)
		bunting(parent, at(21, 26, z), at(66, 26, z), TOY_COLORS, 1.6)
	end

	-- toy race tracks down the walkways between the lines, lamps and neon signs over them
	for index, x in { -17.6, 24.4 } do
		raceTrack(parent, floor, x, -25, 47)
		for k, z in { -32, -2, 30 } do
			pendantLamp(parent, floor * CFrame.new(x, 28, z), 5, TOY_COLORS[(index + k) % #TOY_COLORS + 1])
		end
		hangingSign(parent, floor * CFrame.new(x, 28, 14), 6, Vector2.new(11, 2.6), if index == 1 then "⚡ 100% BRAINROT ⚡" else "★ TOY FACTORY ★", TOY_COLORS[if index == 1 then 2 else 3])
	end
	for index, x in { -55.5, 57.5 } do -- inside the Box Conveyor's loop (a room upgrade)
		pendantLamp(parent, floor * CFrame.new(x, 28, 0), 6, TOY_COLORS[index + 3])
	end

	-- toy shelves on the side walls, between the windows
	local shelfBoard, shelfTrim = WHITE, Color3.fromRGB(110, 190, 255)
	wallShelf(parent, wallFace(floor, { -68, 0, 18 }), 18, shelfBoard, shelfTrim, shelfToy)
	wallShelf(parent, wallFace(floor, { 68, 0, -18 }), 18, shelfBoard, Color3.fromRGB(255, 130, 150), shelfToy)
	wallShelf(parent, wallFace(floor, { 68, 0, 18 }), 18, shelfBoard, Color3.fromRGB(255, 205, 70), shelfToy)

	-- brainrot posters by the entrance and in the corners (the front-right one's wall has
	-- the lift's door)
	poster(parent, wallFace(floor, { -20, 12, -58 }), Vector2.new(7, 9), TOY_COLORS[3], WHITE, "🦈", "TRALALERO!")
	poster(parent, wallFace(floor, { 20, 12, -58 }), Vector2.new(7, 9), TOY_COLORS[1], WHITE, "🐊", "BOMBARDIRO!")
	poster(parent, wallFace(floor, { -68, 16, -50 }), Vector2.new(7, 9), TOY_COLORS[5], WHITE, "☕", "BALLERINA!")
	poster(parent, wallFace(floor, { -68, 14, 50 }), Vector2.new(7, 9), TOY_COLORS[6], WHITE, "🥁", "TUNG TUNG!")
	poster(parent, wallFace(floor, { 68, 14, 50 }), Vector2.new(7, 9), TOY_COLORS[2], WHITE, "🐘", "LIRILÌ!")

	-- the back wall: a pegboard of giant toy tools, and a big clock
	toolBoard(parent, wallFace(floor, { -40, 15, 59 }), 24)
	toyClock(parent, wallFace(floor, { 40, 15, 59 }), 12)

	-- an arcade claw machine by the left wall, shipping crates by the right one
	clawMachine(parent, floor * CFrame.new(-61, 0, -35) * CFrame.Angles(0, -math.pi / 2, 0), TOY_COLORS[5])
	shippingCrates(parent, floor * CFrame.new(62.5, 0, -37))

	-- balloons either side of the entrance, tied to toy blocks
	for index, x in { -19, 19 } do
		local weight = floor * CFrame.new(x, 0, -55)
		makeDecor(parent, "BalloonWeight", Vector3.one * 1.6, weight * CFrame.new(0, 0.8, 0) * CFrame.Angles(0, 0.4 * index, 0), TOY_COLORS[index + 4])
		balloons(parent, weight * CFrame.new(0, 1.6, 0), 4, index * 2, TOY_COLORS)
	end
end

-- Plushie Sewing Room ---------------------------------------------------------------
-- A plush factory, not a nursery: glossy magenta and violet with gold and chrome, neon
-- everywhere, industrial sewing kit (thread cone racks, fabric bolts, a stuffing silo,
-- a giant sewing machine), dress forms in brainrot knits, and a lit glass case of the
-- best-selling brainrot plushies (real brainrots, knitted).

local PLUSH_COLORS = {
	Color3.fromRGB(255, 70, 160), -- magenta
	Color3.fromRGB(140, 90, 255), -- violet
	Color3.fromRGB(40, 200, 255), -- cyan
	Color3.fromRGB(255, 200, 50), -- yellow
	Color3.fromRGB(60, 220, 140), -- green
	Color3.fromRGB(255, 120, 60), -- orange
}
local PLUSH_GOLD = Color3.fromRGB(255, 190, 40) -- plain, not Metal: Metal mirrors the sky and turns olive
local CHROME = Color3.fromRGB(215, 220, 235)
local PLUM = Color3.fromRGB(70, 35, 105)
local KNIT = "PlushKnit" -- the room's MaterialVariant (tools/SetupMaterials)

-- A sagging string of bulbs from `from` to `to` (world positions) whose lights chase
-- along it (Atmosphere's Marquee). `start`: the index before its first bulb, so strings
-- that meet keep the chase running; returns its last.
local function stringLights(parent: Instance, from: Vector3, to: Vector3, sag: number, start: number): number
	local middle = (from + to) / 2 - Vector3.new(0, sag, 0)
	local index = start
	for _, span in { { from, middle }, { middle, to } } do
		local a, b = span[1], span[2]
		rod(parent, "LightWire", 0.12, a, b, PLUM).CastShadow = false
		local count = math.max(1, math.floor((b - a).Magnitude / 2.6))
		for k = 1, count do
			index += 1
			local bulb = ball(parent, "Bulb", 0.9, CFrame.new(a:Lerp(b, (k - 0.5) / count) - Vector3.new(0, 0.45, 0)), Color3.fromRGB(255, 215, 130), Enum.Material.Neon)
			bulb.CastShadow = false
			bulb:SetAttribute("Index", index)
			CollectionService:AddTag(bulb, "Marquee")
		end
	end
	return index
end

-- A catwalk down a walkway (centered on `x`, from `fromZ` to `toZ`): a magenta carpet
-- on a gold edge, white stitches down both sides like a sewing pattern, and chasing
-- floor lights along it.
local function runway(parent: Instance, floor: CFrame, x: number, fromZ: number, toZ: number, carpet: Color3?)
	local length, width = toZ - fromZ, 9
	local middle = floor * CFrame.new(x, 0, (fromZ + toZ) / 2)
	makeDecor(parent, "RunwayEdge", Vector3.new(width + 1.2, 0.08, length + 1.2), middle * CFrame.new(0, 0.04, 0), PLUSH_GOLD)
	makeDecor(parent, "Runway", Vector3.new(width, 0.12, length), middle * CFrame.new(0, 0.06, 0), carpet or PLUSH_COLORS[1], Enum.Material.Fabric)
	local stitches = math.floor(length / 3)
	local lights = math.floor(length / 7)
	for _, side in { -1, 1 } do
		for k = 0, stitches - 1 do
			makeDecor(parent, "RunwayStitch", Vector3.new(0.3, 0.16, 1.4), middle * CFrame.new(side * (width / 2 - 1), 0.07, -length / 2 + (k + 0.5) * length / stitches), WHITE, Enum.Material.Fabric)
		end
		for k = 0, lights - 1 do
			local light = makeDecor(parent, "RunwayLight", Vector3.new(0.2, 0.9, 0.9), middle * CFrame.new(side * (width / 2 + 0.6), 0.1, -length / 2 + (k + 0.5) * length / lights) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(255, 215, 130), Enum.Material.Neon)
			light.Shape = Enum.PartType.Cylinder
			light.CastShadow = false
			light:SetAttribute("Index", k)
			CollectionService:AddTag(light, "Marquee")
		end
	end
end

-- A giant thread spool hanging from the ceiling on a chrome rod (`at`: the point on the
-- ceiling), slowly turning, a ring of light under it.
local function spoolLamp(parent: Instance, at: CFrame, drop: number, color: Color3)
	rod(parent, "SpoolHanger", 0.3, at.Position, (at * CFrame.new(0, -drop, 0)).Position, CHROME, Enum.Material.Metal)
	local model = Instance.new("Model")
	model.Name = "SpoolLamp"
	local top = at * CFrame.new(0, -drop, 0)
	cylinder(model, "SpoolLampEnd", 5.4, 0.6, top * CFrame.new(0, -0.6, 0), CHROME, Enum.Material.Metal)
	cylinder(model, "SpoolLampThread", 4.2, 3.4, top * CFrame.new(0, -4, 0), color, Enum.Material.Fabric)
	for _, y in { -3.2, -1.9 } do
		cylinder(model, "SpoolLampWrap", 4.4, 0.3, top * CFrame.new(0, y, 0), color:Lerp(WHITE, 0.35), Enum.Material.Fabric)
	end
	cylinder(model, "SpoolLampEnd", 5.4, 0.6, top * CFrame.new(0, -4.6, 0), CHROME, Enum.Material.Metal)
	cylinder(model, "SpoolLampGlow", 4.6, 0.2, top * CFrame.new(0, -4.8, 0), Color3.fromRGB(255, 235, 200), Enum.Material.Neon).CastShadow = false
	spinner(model, parent, top * CFrame.new(0, -2.6, 0) * CFrame.Angles(math.pi / 2, 0, 0), 0.5)
end

-- A rack of industrial thread cones on a wall (`face`: on the wall at the floor under
-- its middle, -Z into the room): chrome shelves on a plum board in a gold frame, rows
-- of tall cones in every color, a neon sign on top.
local function threadRack(parent: Instance, face: CFrame, columns: number, rows: number)
	local spacing, rowHeight, bottom = 2.6, 4.2, 8
	local width, height = columns * spacing + 1.4, rows * rowHeight + 1
	makeDecor(parent, "RackBoard", Vector3.new(width, height, 0.4), face * CFrame.new(0, bottom + height / 2, -0.2), PLUM)
	for _, x in { -1, 1 } do
		makeDecor(parent, "RackFrame", Vector3.new(0.6, height + 0.6, 0.8), face * CFrame.new(x * (width / 2 + 0.3), bottom + height / 2, -0.4), PLUSH_GOLD)
	end
	for _, y in { bottom - 0.3, bottom + height + 0.3 } do
		makeDecor(parent, "RackFrame", Vector3.new(width + 1.2, 0.6, 0.8), face * CFrame.new(0, y, -0.4), PLUSH_GOLD)
	end
	for row = 1, rows do
		local y = bottom + 0.6 + (row - 1) * rowHeight
		makeDecor(parent, "RackShelf", Vector3.new(width - 0.4, 0.3, 1.8), face * CFrame.new(0, y, -1.1), CHROME, Enum.Material.Metal)
		for column = 1, columns do
			local at = face * CFrame.new(-width / 2 + 0.7 + (column - 0.5) * spacing, y + 0.15, -1.1)
			local color = PLUSH_COLORS[(column + row * 2) % #PLUSH_COLORS + 1]
			cylinder(parent, "ConeFoot", 1.7, 0.3, at, WHITE)
			cylinder(parent, "Cone", 1.9, 1.3, at * CFrame.new(0, 0.3, 0), color, Enum.Material.Fabric)
			cylinder(parent, "Cone", 1.4, 1.3, at * CFrame.new(0, 1.6, 0), color:Lerp(WHITE, 0.15), Enum.Material.Fabric)
			cylinder(parent, "ConeTip", 0.7, 0.6, at * CFrame.new(0, 2.9, 0), WHITE)
		end
	end
	neonSign(parent, face * CFrame.new(0, bottom + height + 2.4, 0), Vector2.new(width * 0.6, 2.8), "🧵 THREAD", PLUSH_COLORS[3])
end

-- A rack of fabric bolts on a wall (`face`: on the wall at the floor under its middle):
-- chrome cubbies, each bolt's rolled end facing the room, a neon sign on top.
local function fabricRack(parent: Instance, face: CFrame, columns: number, rows: number)
	local cell, depth, bottom = 3.4, 4.6, 1
	local width, height = columns * cell, rows * cell
	for column = 0, columns do
		-- (the posts end inside the top and bottom shelves, and the shelves stand a little
		-- proud of them: shared faces flicker)
		makeDecor(parent, "RackPost", Vector3.new(0.4, height + 0.3, depth), face * CFrame.new(-width / 2 + column * cell, bottom + height / 2, -depth / 2), CHROME, Enum.Material.Metal)
	end
	for row = 0, rows do
		makeDecor(parent, "RackShelf", Vector3.new(width + 0.4, 0.4, depth + 0.06), face * CFrame.new(0, bottom + row * cell, -(depth + 0.06) / 2), if row == 0 or row == rows then PLUSH_GOLD else CHROME, Enum.Material.Metal)
	end
	for column = 1, columns do
		for row = 1, rows do
			local color = PLUSH_COLORS[(column * 2 + row) % #PLUSH_COLORS + 1]
			local center = face * CFrame.new(-width / 2 + (column - 0.5) * cell, bottom + (row - 0.5) * cell + 0.15, -depth / 2 - 0.3)
			local axis = CFrame.Angles(0, math.pi / 2, 0) -- the roll runs out of the wall
			roller(parent, "FabricBolt", cell - 0.7, depth - 0.4, center * axis, color).Material = Enum.Material.Fabric
			roller(parent, "BoltStripe", cell - 0.55, 0.4, center * CFrame.new(0, 0, -depth / 2 + 1.2) * axis, color:Lerp(WHITE, 0.5)).Material = Enum.Material.Fabric
			roller(parent, "BoltCore", 0.8, depth - 0.2, center * axis, PLUM)
		end
	end
	neonSign(parent, face * CFrame.new(0, bottom + height + 2.4, 0), Vector2.new(width * 0.65, 2.8), "✂ FABRIC", PLUSH_COLORS[1])
end

-- A dress form (`at`: its foot, -Z its front) wearing a chunky knit sweater with a
-- brainrot on the chest: hips, a narrow waist, a chest and broad round shoulders on a
-- chrome pole, a measuring tape round its neck.
local function dressForm(parent: Instance, at: CFrame, color: Color3, emoji: string)
	cylinder(parent, "FormFoot", 2.8, 0.4, at, CHROME, Enum.Material.Metal)
	cylinder(parent, "FormPole", 0.45, 3.4, at * CFrame.new(0, 0.4, 0), CHROME, Enum.Material.Metal)
	local function knit(part: Part)
		part.Material = Enum.Material.Fabric
		part.MaterialVariant = KNIT
	end
	knit(cylinder(parent, "FormHips", 3, 1.4, at * CFrame.new(0, 3.8, 0), color))
	knit(cylinder(parent, "FormWaist", 2.3, 1.2, at * CFrame.new(0, 5.2, 0), color))
	knit(cylinder(parent, "FormChest", 3.2, 2.2, at * CFrame.new(0, 6.4, 0), color))
	knit(roller(parent, "FormShoulders", 1.9, 3.6, at * CFrame.new(0, 8.7, 0), color))
	for _, x in { -1.8, 1.8 } do
		knit(ball(parent, "FormShoulder", 1.9, at * CFrame.new(x, 8.7, 0), color))
	end
	knit(cylinder(parent, "FormCollar", 1.7, 0.5, at * CFrame.new(0, 9.4, 0), color:Lerp(WHITE, 0.35)))
	cylinder(parent, "FormNeck", 1, 1.3, at * CFrame.new(0, 9.9, 0), Color3.fromRGB(245, 225, 205))
	ball(parent, "FormCap", 1.2, at * CFrame.new(0, 11.3, 0), PLUSH_GOLD)
	-- the measuring tape, hanging down both sides of its chest
	for _, x in { -0.8, 0.8 } do
		rod(parent, "FormTape", 0.3, (at * CFrame.new(x * 0.6, 9.8, -0.5)).Position, (at * CFrame.new(x, 6.2, -1.65)).Position, Color3.fromRGB(255, 220, 60))
	end
	local logo = makeDecor(parent, "FormLogo", Vector3.new(2, 2, 0.1), at * CFrame.new(0, 7.3, -1.68), WHITE)
	logo.Transparency = 1
	emojiOn(logo, Enum.NormalId.Front, emoji)
end

-- A stuffing silo (`at`: its foot): a tall glass tank on a chrome base with fluff
-- tumbling round inside (a Spinner), a pipe up into the ceiling, and a pressure gauge.
local function stuffingSilo(parent: Instance, at: CFrame, height: number)
	cylinder(parent, "SiloBase", 8.4, 1.6, at, CHROME, Enum.Material.Metal)
	cylinder(parent, "SiloBand", 8.6, 0.5, at * CFrame.new(0, 1.2, 0), PLUSH_COLORS[1])
	local glass = cylinder(parent, "SiloTank", 7, height, at * CFrame.new(0, 1.6, 0), Color3.fromRGB(215, 235, 255), Enum.Material.Glass)
	glass.Transparency = 0.6
	for _, y in { 1.6 + height / 3, 1.6 + height * 2 / 3 } do
		cylinder(parent, "SiloRing", 7.3, 0.4, at * CFrame.new(0, y, 0), PLUSH_GOLD)
	end
	cylinder(parent, "SiloCap", 7.6, 1.2, at * CFrame.new(0, 1.6 + height, 0), CHROME, Enum.Material.Metal)
	local capTop = 2.8 + height
	cylinder(parent, "SiloPipe", 1.5, 28 - capTop, at * CFrame.new(0, capTop, 0), CHROME, Enum.Material.Metal)
	-- the fluff inside, tumbling round
	local fluff = Instance.new("Model")
	fluff.Name = "SiloFluff"
	local count = math.floor(height * 1.4)
	for index = 1, count do
		local angle = index * 2.4
		local radius = 1.2 + (index % 3) * 0.7
		local y = 2.4 + (index - 0.5) / count * (height - 1.6)
		ball(fluff, "Fluff", 1.6 + (index % 4) * 0.3, at * CFrame.new(math.cos(angle) * radius, y, math.sin(angle) * radius), if index % 3 == 0 then Color3.fromRGB(255, 205, 230) else WHITE, Enum.Material.Fabric).CastShadow = false
	end
	spinner(fluff, parent, at * CFrame.new(0, 1.6 + height / 2, 0) * CFrame.Angles(math.pi / 2, 0, 0), 0.9)
	-- a pressure gauge on the base, facing the room (-Z)
	local gauge = at * CFrame.new(0, 3.4, -3.9)
	local dial = makeDecor(parent, "SiloGauge", Vector3.new(0.4, 2, 2), gauge * CFrame.Angles(0, math.pi / 2, 0), WHITE)
	dial.Shape = Enum.PartType.Cylinder
	makeDecor(parent, "SiloGaugeNeedle", Vector3.new(0.15, 0.8, 0.1), gauge * CFrame.new(0.2, 0.2, -0.25) * CFrame.Angles(0, 0, -0.6), Color3.fromRGB(255, 60, 80), Enum.Material.Neon)
end

-- The BEST SELLERS case on a wall (`face`: on the wall at the floor under its middle,
-- -Z into the room): a gold-framed glass cabinet lit inside, its shelves of knitted
-- brainrot plushies (the real ones, in the room's edition), a neon sign on top.
local BEST_SELLERS = {
	"TralaleroTralala",
	"TungTungTungSahur",
	"BallerinaCappuccina",
	"ChimpanziniBananini",
	"BombardiroCrocodilo",
	"CappuccinoAssassino",
}
local SHOWCASE_SCALE = 0.58

-- A brainrot in `zoneId`'s edition, shelf-sized, standing on `root`.
local function figure(id: string, root: CFrame, zoneId: string): Model
	local brainrot = Instance.new("Model")
	brainrot.Name = "Plushie"
	for _, partType in Brainrots.PartTypes do
		local part = BrainrotModels.CreatePart(id, partType, zoneId)
		for _, child in part:GetChildren() do
			child.Parent = brainrot
		end
		part:Destroy()
	end
	brainrot.WorldPivot = CFrame.identity
	brainrot:ScaleTo(SHOWCASE_SCALE)
	brainrot:PivotTo(root)
	return brainrot
end

local function bestSellers(parent: Instance, face: CFrame, width: number, zoneId: string, title: string, color: Color3)
	local depth, bottom, height = 3.4, 8.5, 12.5
	local shelves = { bottom + 0.5, bottom + 6.6 }
	makeDecor(parent, "CaseBack", Vector3.new(width, height, 0.3), face * CFrame.new(0, bottom + height / 2, -0.2), Color3.fromRGB(255, 235, 248)) -- light, so the plushies pop
	for _, x in { -1, 1 } do
		makeDecor(parent, "CaseSide", Vector3.new(0.6, height + 1.2, depth + 0.4), face * CFrame.new(x * (width / 2 + 0.3), bottom + height / 2, -depth / 2), PLUSH_GOLD)
	end
	for _, y in { bottom - 0.3, bottom + height + 0.3 } do
		makeDecor(parent, "CaseRail", Vector3.new(width + 1.2, 0.6, depth + 0.4), face * CFrame.new(0, y, -depth / 2), PLUSH_GOLD)
	end
	local glass = makeDecor(parent, "CaseGlass", Vector3.new(width, height, 0.15), face * CFrame.new(0, bottom + height / 2, -depth), Color3.fromRGB(220, 240, 255), Enum.Material.Glass)
	glass.Transparency = 0.8
	local strip = makeDecor(parent, "CaseLight", Vector3.new(width - 1, 0.2, 0.6), face * CFrame.new(0, bottom + height - 0.3, -depth / 2), Color3.fromRGB(255, 240, 210), Enum.Material.Neon)
	local light = Instance.new("SurfaceLight")
	light.Face = Enum.NormalId.Bottom
	light.Angle = 120
	light.Range = 14
	light.Brightness = 1.4
	light.Color = Color3.fromRGB(255, 235, 210)
	light.Parent = strip
	local perShelf = math.ceil(#BEST_SELLERS / #shelves)
	for index, id in BEST_SELLERS do
		local shelf = math.ceil(index / perShelf)
		local slot = (index - 1) % perShelf
		local y = shelves[shelf]
		if shelf > 1 then
			makeDecor(parent, "CaseShelf", Vector3.new(width, 0.3, depth - 0.2), face * CFrame.new(0, y - 0.15, -depth / 2), CHROME, Enum.Material.Metal)
		end
		local x = -width / 2 + (slot + 0.5) * width / perShelf
		local doll = figure(id, face * CFrame.new(x, y, -depth / 2), zoneId)
		doll.Parent = parent
	end
	neonSign(parent, face * CFrame.new(0, bottom + height + 2.6, 0), Vector2.new(width * 0.75, 3), title, color)
end

-- A giant industrial sewing machine on its table, `scale` times human size (`at`: under
-- the table's middle, -Z its front): glossy magenta with chrome and gold, a spool on
-- top, a hand wheel, a light under its arm and a glowing badge.
local function sewingMachine(parent: Instance, at: CFrame, scale: number)
	local body, trim = PLUSH_COLORS[1], CHROME
	local function box(name: string, size: Vector3, offset: Vector3, color: Color3, material: Enum.Material?): Part
		return makeDecor(parent, name, size * scale, at * CFrame.new(offset * scale), color, material)
	end
	box("SewingTable", Vector3.new(20, 1, 8), Vector3.new(0, 5, 0), PLUM)
	box("SewingTableEdge", Vector3.new(20.4, 0.4, 8.4), Vector3.new(0, 5.25, 0), PLUSH_GOLD) -- (its top under the table's)
	for _, x in { -9, 9 } do
		box("SewingLeg", Vector3.new(1, 4.5, 7), Vector3.new(x, 2.25, 0), CHROME, Enum.Material.Metal)
	end
	box("SewingBase", Vector3.new(16, 2, 6), Vector3.new(0, 6.5, 0), body)
	box("SewingPillar", Vector3.new(3.5, 7, 5), Vector3.new(6, 11, 0), body)
	box("SewingArm", Vector3.new(15, 3, 4.6), Vector3.new(-0.5, 15.5, 0), body)
	box("SewingHead", Vector3.new(3, 4, 4), Vector3.new(-6.5, 13.5, 0), body)
	box("SewingNeedle", Vector3.new(0.3, 3, 0.3), Vector3.new(-6.5, 10, 0), CHROME, Enum.Material.Metal)
	box("SewingStripe", Vector3.new(15.2, 0.6, 4.8), Vector3.new(-0.5, 15.5, 0), PLUSH_GOLD)
	box("SewingLight", Vector3.new(2, 0.2, 2), Vector3.new(-6.5, 11.4, 0), Color3.fromRGB(255, 240, 210), Enum.Material.Neon).CastShadow = false
	roller(parent, "SewingWheel", 5 * scale, scale, at * CFrame.new(8.7 * scale, 14 * scale, 0), trim).Material = Enum.Material.Metal
	-- the badge on its base, facing the room
	local badge = box("SewingBadge", Vector3.new(9, 1.4, 0.2), Vector3.new(0, 6.5, -3.1), PLUM)
	label(badge, Enum.NormalId.Front, "ROT-O-MATIC 3000", PLUSH_GOLD:Lerp(WHITE, 0.4), PLUSH_GOLD, 30)
	-- its spool on top, and the thread down to the needle
	cylinder(parent, "SewingSpoolEnd", 3 * scale, 0.5 * scale, at * CFrame.new(-1 * scale, 17 * scale, 0), CHROME, Enum.Material.Metal)
	cylinder(parent, "SewingSpool", 2.2 * scale, 2.6 * scale, at * CFrame.new(-1 * scale, 17.5 * scale, 0), PLUSH_COLORS[3], Enum.Material.Fabric)
	cylinder(parent, "SewingSpoolEnd", 3 * scale, 0.5 * scale, at * CFrame.new(-1 * scale, 20.1 * scale, 0), CHROME, Enum.Material.Metal)
	-- fabric running under the needle
	makeDecor(parent, "SewingCloth", Vector3.new(10, 0.15, 5) * scale, at * CFrame.new(-6 * scale, 7.6 * scale, 0) * CFrame.Angles(0, 0.15, 0), PLUSH_COLORS[2], Enum.Material.Fabric).MaterialVariant = KNIT
end

-- A giant spool of thread on the floor (`at`: its foot), chrome ends.
local function floorSpool(parent: Instance, at: CFrame, color: Color3)
	cylinder(parent, "SpoolEnd", 6, 1, at, CHROME, Enum.Material.Metal)
	cylinder(parent, "SpoolThread", 4.6, 5, at * CFrame.new(0, 1, 0), color, Enum.Material.Fabric)
	for _, y in { 2.4, 4.2 } do
		cylinder(parent, "SpoolWrap", 4.8, 0.35, at * CFrame.new(0, y, 0), color:Lerp(WHITE, 0.35), Enum.Material.Fabric)
	end
	cylinder(parent, "SpoolEnd", 6, 1, at * CFrame.new(0, 6, 0), CHROME, Enum.Material.Metal)
	cylinder(parent, "SpoolCap", 1.4, 0.6, at * CFrame.new(0, 7, 0), PLUSH_GOLD)
end

local function buildPlushie(parent: Instance, floor: CFrame)
	-- the sign over the doorway, and chasing string lights round the walls by the ceiling
	neonSign(parent, wallFace(floor, { 0, 23.2, -59 }), Vector2.new(32, 5.4), "🧵 PLUSH FACTORY 🧵", PLUSH_COLORS[1])
	local function at(x: number, y: number, z: number): Vector3
		return (floor * CFrame.new(x, y, z)).Position
	end
	local index = 0
	index = stringLights(parent, at(-66, 26, -57), at(-66, 26, 0), 1.6, index)
	index = stringLights(parent, at(-66, 26, 0), at(-66, 26, 57), 1.6, index)
	index = stringLights(parent, at(-66, 26, 57), at(-21, 26, 57), 1.6, index)
	index = stringLights(parent, at(21, 26, 57), at(66, 26, 57), 1.6, index)
	index = stringLights(parent, at(66, 26, 57), at(66, 26, 0), 1.6, index)
	index = stringLights(parent, at(66, 26, 0), at(66, 26, -57), 1.6, index)
	index = stringLights(parent, at(66, 26, -58), at(20, 26, -58), 1.6, index)
	stringLights(parent, at(-20, 26, -58), at(-66, 26, -58), 1.6, index)

	-- catwalks down the walkways between the lines, spool lamps and neon signs over them
	for index_, x in { -19.6, 22.4 } do
		runway(parent, floor, x, -25, 45)
		for k, z in { -32, -2, 30 } do
			spoolLamp(parent, floor * CFrame.new(x, 28, z), 2.5, PLUSH_COLORS[(index_ + k) % #PLUSH_COLORS + 1])
		end
		hangingSign(parent, floor * CFrame.new(x, 28, 14), 6, Vector2.new(11, 2.6), if index_ == 1 then "✂ HANDMADE ROT ✂" else "★ 100% KNITTED ★", PLUSH_COLORS[if index_ == 1 then 1 else 3])
	end
	for index_, x in { -60, 62.5 } do
		pendantLamp(parent, floor * CFrame.new(x, 28, 0), 6, PLUSH_COLORS[index_ + 1])
	end

	-- the back wall: the best sellers case, brainrot plush ads either side of it
	bestSellers(parent, wallFace(floor, { 0, 0, 58 }), 20, "PlushieRoom", "🏆 BEST SELLERS 🏆", PLUSH_GOLD)
	poster(parent, wallFace(floor, { -45, 14, 58 }), Vector2.new(7, 9), PLUSH_COLORS[6], PLUSH_GOLD, "🍌", "NEW DROP!")
	poster(parent, wallFace(floor, { 45, 14, 58 }), Vector2.new(7, 9), PLUSH_COLORS[5], PLUSH_GOLD, "🐘", "LIMITED!")
	-- the front wall: plush ads by the doorway
	for index_, ad in { { -50, "🦈", "TRALALERO PLUSH" }, { -30, "🐊", "BOMBARDIRO PLUSH" }, { 30, "🥁", "SAHUR PLUSH" }, { 50, "☕", "BALLERINA PLUSH" } } do
		poster(parent, wallFace(floor, { ad[1] :: number, 14, -59 }), Vector2.new(7, 9), PLUSH_COLORS[index_], PLUSH_GOLD, ad[2] :: string, ad[3] :: string)
	end

	-- the side walls: a rack of thread cones, a rack of fabric bolts
	threadRack(parent, wallFace(floor, { -68, 0, 18 }), 7, 3)
	fabricRack(parent, wallFace(floor, { 68, 0, -18 }), 5, 4)

	-- the giant sewing machine along the right wall, facing the room, and the stuffing
	-- silo in the back-right corner
	sewingMachine(parent, floor * CFrame.new(62.5, 0, 18) * CFrame.Angles(0, math.pi / 2, 0), 1)
	stuffingSilo(parent, floor * CFrame.new(62.5, 0, 50), 15)
	neonSign(parent, wallFace(floor, { 68, 21.5, 50 }), Vector2.new(9, 2.6), "☁ STUFFING", Color3.fromRGB(150, 220, 255))

	-- by the doorway, dress forms in brainrot knits; a giant spool by the left wall
	for index_, form in { { -32, "🦈" }, { -20, "🥁" }, { 20, "🐸" }, { 32, "🍌" } } do
		dressForm(parent, floor * CFrame.new(form[1] :: number, 0, -53) * CFrame.Angles(0, math.pi, 0), PLUSH_COLORS[(index_ + 1) % #PLUSH_COLORS + 1], form[2] :: string)
	end
	floorSpool(parent, floor * CFrame.new(-63, 0, 3), PLUSH_COLORS[2])
end

-- Clay Studio -------------------------------------------------------------------------
-- A stop-motion film studio (GDD §10): a deep terracotta floor and orange walls, teal
-- neon and gold. Lighting trusses hang over the walkways with spotlights aimed at the
-- turntables, film-strip runners down the walkways, giant film reels turning on the
-- back wall with a strip of film between them, an ON AIR sign, movie posters of brainrot
-- claymations, a storyboard, a shelf of miniature sets and clay maquettes, a pegboard of
-- sculpting tools, tubs of clay, a film camera on a dolly by the director's chair, a
-- sculpting desk, and a giant sculpture turning on its plinth. The turntables are wide:
-- props keep to the walls, the front of the room and the back corners.

local CLAY = Color3.fromRGB(215, 120, 80)
local CLAY_LIGHT = Color3.fromRGB(235, 160, 115)
local CLAY_DARK = Color3.fromRGB(140, 70, 50)
local CLAY_TEAL = Color3.fromRGB(60, 205, 195)
local CLAY_GOLD = Color3.fromRGB(255, 190, 40)
local FILM = Color3.fromRGB(35, 30, 45)
local STEEL = Color3.fromRGB(70, 65, 80)
local CLAY_COLORS = { -- play-dough
	Color3.fromRGB(255, 95, 120),
	Color3.fromRGB(255, 200, 60),
	Color3.fromRGB(90, 200, 255),
	Color3.fromRGB(120, 215, 110),
	Color3.fromRGB(185, 120, 255),
	Color3.fromRGB(255, 140, 60),
}
local PAINT_COLORS = CLAY_COLORS

local function pot(parent: Instance, at: CFrame, height: number, color: Color3)
	cylinder(parent, "PotBase", height * 0.5, height * 0.2, at, color)
	ball(parent, "PotBelly", height * 0.75, at * CFrame.new(0, height * 0.45, 0), color)
	cylinder(parent, "PotNeck", height * 0.35, height * 0.35, at * CFrame.new(0, height * 0.65, 0), color)
	cylinder(parent, "PotLip", height * 0.45, height * 0.1, at * CFrame.new(0, height * 0.95, 0), color:Lerp(WHITE, 0.15))
end

-- A big lumpy clay sculpture of a brainrot in the making on a plinth that slowly turns
-- (`at`: on the floor under it).
local function sculpture(parent: Instance, at: CFrame)
	cylinder(parent, "Plinth", 12, 3.2, at, WHITE)
	cylinder(parent, "PlinthBand", 12.3, 0.6, at * CFrame.new(0, 1.2, 0), CLAY_TEAL, Enum.Material.Neon).CastShadow = false
	cylinder(parent, "PlinthRim", 12.6, 0.5, at * CFrame.new(0, 3.1, 0), CLAY_GOLD, Enum.Material.Metal)
	local turning = Instance.new("Model")
	turning.Name = "Sculpture"
	local top = at * CFrame.new(0, 3.6, 0)
	cylinder(turning, "PlinthTop", 11, 0.6, top, CLAY_LIGHT)
	ball(turning, "ClayBlob", 9, top * CFrame.new(0, 4.6, 0), CLAY, Enum.Material.Sand)
	ball(turning, "ClayBlob", 7, top * CFrame.new(0.5, 10.6, 0), CLAY_LIGHT, Enum.Material.Sand)
	for _, side in { -1, 1 } do
		ball(turning, "ClayBlob", 3, top * CFrame.new(0, 5.6, side * 5), CLAY, Enum.Material.Sand) -- arms
		ball(turning, "ClayEye", 2.1, top * CFrame.new(3.3, 11.4, side * 1.5), WHITE)
		ball(turning, "ClayPupil", 1.05, top * CFrame.new(4.15, 11.4, side * 1.5), Color3.fromRGB(60, 40, 50))
	end
	-- a sculpting tool stuck in it, and a few dabs of colored clay
	makeDecor(turning, "SculptingTool", Vector3.new(0.4, 5, 0.4), top * CFrame.new(-2, 13.4, 2) * CFrame.Angles(math.rad(30), 0, math.rad(20)), Color3.fromRGB(225, 180, 125), Enum.Material.Wood)
	for index, offset in { Vector3.new(3.4, 6, -2.4), Vector3.new(-2, 8.6, 3), Vector3.new(2.6, 13.6, 1.6), Vector3.new(-3.2, 4.6, -2) } do
		ball(turning, "ClayDab", 1.4, top * CFrame.new(offset), CLAY_COLORS[index], Enum.Material.Sand)
	end
	spinner(turning, parent, top * CFrame.Angles(math.pi / 2, 0, 0), 0.35)
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

-- A film strip laid down a walkway (centered on `x`, from `fromZ` to `toZ`): dark film
-- with sprocket holes along both edges and a frame of color every few studs.
local function filmRunner(parent: Instance, floor: CFrame, x: number, fromZ: number, toZ: number)
	local length, width = toZ - fromZ, 7
	local middle = floor * CFrame.new(x, 0, (fromZ + toZ) / 2)
	makeDecor(parent, "FilmRunner", Vector3.new(width, 0.08, length), middle * CFrame.new(0, 0.04, 0), FILM)
	local holes = math.floor(length / 2.2)
	for _, side in { -1, 1 } do
		for k = 0, holes - 1 do
			makeDecor(parent, "FilmHole", Vector3.new(0.8, 0.1, 0.9), middle * CFrame.new(side * (width / 2 - 0.75), 0.05, -length / 2 + (k + 0.5) * length / holes), Color3.fromRGB(250, 240, 220))
		end
	end
	local frames = math.floor(length / 5)
	for k = 0, frames - 1 do
		local color = CLAY_COLORS[k % #CLAY_COLORS + 1]
		makeDecor(parent, "FilmFrame", Vector3.new(width - 3.2, 0.1, 3.8), middle * CFrame.new(0, 0.05, -length / 2 + (k + 0.5) * length / frames), color:Lerp(WHITE, 0.15))
	end
end

-- A lighting truss hung under the ceiling along Z (centered on `x`, from `fromZ` to
-- `toZ`): two black beams braced together on chrome hangers, spotlights hanging off it
-- aimed at `targets` (room space), every other one a real light.
local function truss(parent: Instance, floor: CFrame, x: number, fromZ: number, toZ: number, targets: { Vector3 })
	local y = 25.2
	local length = toZ - fromZ
	local middle = floor * CFrame.new(x, y, (fromZ + toZ) / 2)
	for _, side in { -1, 1 } do
		makeDecor(parent, "TrussBeam", Vector3.new(0.5, 0.5, length), middle * CFrame.new(side * 1.1, 0, 0), STEEL)
	end
	for k = 0, math.floor(length / 4) do
		makeDecor(parent, "TrussBrace", Vector3.new(2.2, 0.3, 0.3), middle * CFrame.new(0, 0, -length / 2 + k * 4), STEEL)
	end
	for _, z in { fromZ + 3, (fromZ + toZ) / 2, toZ - 3 } do
		rod(parent, "TrussHanger", 0.25, (floor * CFrame.new(x, y, z)).Position, (floor * CFrame.new(x, 28, z)).Position, Color3.fromRGB(200, 205, 215), Enum.Material.Metal)
	end
	for index, target in targets do
		local z = fromZ + (index - 0.5) / #targets * length
		local yoke = floor * CFrame.new(x, y - 0.5, z)
		makeDecor(parent, "SpotYoke", Vector3.new(0.3, 1.4, 0.3), yoke * CFrame.new(0, -0.5, 0), STEEL)
		local aim = CFrame.lookAt((yoke * CFrame.new(0, -1.6, 0)).Position, (floor * CFrame.new(target)).Position)
		local can = makeDecor(parent, "SpotCan", Vector3.new(2.2, 1.7, 1.7), aim * CFrame.Angles(0, math.pi / 2, 0), FILM)
		can.Shape = Enum.PartType.Cylinder
		makeDecor(parent, "SpotRing", Vector3.new(0.3, 1.9, 1.9), aim * CFrame.new(0, 0, -1.1) * CFrame.Angles(0, math.pi / 2, 0), CLAY_GOLD, Enum.Material.Metal).Shape = Enum.PartType.Cylinder
		local lens = makeDecor(parent, "SpotLens", Vector3.new(0.12, 1.4, 1.4), aim * CFrame.new(0, 0, -1.2) * CFrame.Angles(0, math.pi / 2, 0), Color3.fromRGB(255, 240, 205), Enum.Material.Neon)
		lens.Shape = Enum.PartType.Cylinder
		lens.CastShadow = false
		if index % 2 == 1 then
			local light = Instance.new("SpotLight")
			light.Face = Enum.NormalId.Right -- (the lens is a cylinder turned to face the target: its X)
			light.Angle = 45
			light.Range = 34
			light.Brightness = 1.1
			light.Color = Color3.fromRGB(255, 235, 200)
			light.Parent = lens
		end
	end
end

-- A giant film reel on a wall (`face`: its middle, -Z into the room), turning.
local function wallReel(parent: Instance, face: CFrame, diameter: number, speed: number)
	local reel = Instance.new("Model")
	reel.Name = "FilmReel"
	local hub = face * CFrame.new(0, 0, -0.6)
	-- nested discs, each ending in planes of its own (the face toward the room, then the
	-- back): disc -0.25/0.25, rim -0.2/0.2, film -0.3/0.3, holes -0.38/0.28, hub -0.67/0.23
	roller(reel, "ReelDisc", diameter, 0.5, hub * CFrame.Angles(0, math.pi / 2, 0), FILM)
	roller(reel, "ReelRim", diameter + 0.4, 0.4, hub * CFrame.Angles(0, math.pi / 2, 0), CLAY_GOLD).Material = Enum.Material.Metal
	roller(reel, "ReelFilm", diameter * 0.72, 0.6, hub * CFrame.Angles(0, math.pi / 2, 0), Color3.fromRGB(90, 70, 60))
	for k = 0, 4 do
		local angle = k / 5 * math.pi * 2
		local hole = roller(reel, "ReelHole", diameter * 0.2, 0.66, hub * CFrame.new(math.cos(angle) * diameter * 0.24, math.sin(angle) * diameter * 0.24, -0.05) * CFrame.Angles(0, math.pi / 2, 0), CLAY_TEAL)
		hole.Material = Enum.Material.Neon
		hole.CastShadow = false
	end
	roller(reel, "ReelHub", diameter * 0.16, 0.9, hub * CFrame.new(0, 0, -0.22) * CFrame.Angles(0, math.pi / 2, 0), CLAY_GOLD).Material = Enum.Material.Metal
	spinner(reel, parent, hub, speed)
end

-- A strip of film along a wall from `from` to `to` (wall spots at the same height): dark
-- film with sprocket holes and frames of color, running between the reels.
local function wallFilm(parent: Instance, floor: CFrame, from: WallSpot, to: WallSpot)
	local a, b = wallFace(floor, from), wallFace(floor, to)
	local length = (b.Position - a.Position).Magnitude
	local middle = a:Lerp(b, 0.5) * CFrame.new(0, 0, -0.3)
	makeDecor(parent, "WallFilm", Vector3.new(length, 2.8, 0.15), middle, FILM)
	local frames = math.floor(length / 3.6)
	for k = 0, frames - 1 do
		local x = -length / 2 + (k + 0.5) * length / frames
		makeDecor(parent, "WallFilmFrame", Vector3.new(2.6, 1.6, 0.05), middle * CFrame.new(x, 0, -0.1), CLAY_COLORS[k % #CLAY_COLORS + 1]:Lerp(WHITE, 0.2))
		for _, y in { -1.15, 1.15 } do
			makeDecor(parent, "WallFilmHole", Vector3.new(0.6, 0.35, 0.05), middle * CFrame.new(x - 0.9, y, -0.1), Color3.fromRGB(250, 240, 220))
			makeDecor(parent, "WallFilmHole", Vector3.new(0.6, 0.35, 0.05), middle * CFrame.new(x + 0.9, y, -0.1), Color3.fromRGB(250, 240, 220))
		end
	end
end

-- The storyboard on a wall (`face`: its middle, -Z into the room): a cork board in a
-- terracotta frame, six sketch cards of a brainrot's big scene pinned to it.
local STORYBOARD = { "🦈", "💥", "🥁", "😱", "🍝", "🏆" }
local function storyboard(parent: Instance, face: CFrame)
	local size = Vector2.new(16, 9.4)
	makeDecor(parent, "BoardFrame", Vector3.new(size.X + 1, size.Y + 1, 0.4), face * CFrame.new(0, 0, -0.2), CLAY_DARK)
	makeDecor(parent, "Cork", Vector3.new(size.X, size.Y, 0.3), face * CFrame.new(0, 0, -0.4), Color3.fromRGB(205, 160, 105), Enum.Material.Sand)
	for index, emoji in STORYBOARD do
		local column, row = (index - 1) % 3, math.floor((index - 1) / 3)
		local card = face * CFrame.new(-5.2 + column * 5.2, 2.2 - row * 4.4, -0.6) * CFrame.Angles(0, 0, math.rad((index % 3 - 1) * 4))
		local sheet = makeDecor(parent, "SketchCard", Vector3.new(4.4, 3.4, 0.08), card, WHITE)
		emojiOn(sheet, Enum.NormalId.Front, emoji)
		ball(parent, "Pin", 0.45, card * CFrame.new(0, 1.5, -0.1), CLAY_COLORS[index], Enum.Material.Neon).CastShadow = false
	end
	neonSign(parent, face * CFrame.new(0, size.Y / 2 + 2.4, 0), Vector2.new(11, 2.2), "✏ STORYBOARD", CLAY_TEAL)
end

-- Little things for the shelf of sets (`at`: on the shelf, -Z toward the room): tiny
-- stop-motion sets and clay maquettes of brainrots, in turn.
local function setPiece(parent: Instance, at: CFrame, index: number)
	local kind = index % 4
	local color = CLAY_COLORS[index % #CLAY_COLORS + 1]
	if kind == 0 then
		-- a little house: a block with a roof wedge and a lit window
		makeDecor(parent, "SetHouse", Vector3.new(2.2, 2, 2), at * CFrame.new(0, 1, 0), color:Lerp(WHITE, 0.3))
		wedge(parent, "SetRoof", Vector3.new(2.4, 1.2, 1.2), at * CFrame.new(0, 2.6, -0.6), CLAY_DARK)
		wedge(parent, "SetRoof", Vector3.new(2.4, 1.2, 1.2), at * CFrame.new(0, 2.6, 0.6) * CFrame.Angles(0, math.pi, 0), CLAY_DARK)
		makeDecor(parent, "SetWindow", Vector3.new(0.7, 0.7, 0.1), at * CFrame.new(0, 1.1, -1.02), Color3.fromRGB(255, 225, 120), Enum.Material.Neon)
	elseif kind == 1 then
		-- a clay maquette: a lumpy brainrot with googly eyes
		ball(parent, "Maquette", 2, at * CFrame.new(0, 1, 0), color, Enum.Material.Sand)
		ball(parent, "Maquette", 1.4, at * CFrame.new(0, 2.4, 0), color:Lerp(WHITE, 0.2), Enum.Material.Sand)
		for _, x in { -0.32, 0.32 } do
			ball(parent, "MaquetteEye", 0.5, at * CFrame.new(x, 2.55, -0.6), WHITE)
			ball(parent, "MaquettePupil", 0.25, at * CFrame.new(x, 2.55, -0.82), INK)
		end
	elseif kind == 2 then
		-- a little tree
		cylinder(parent, "SetTrunk", 0.4, 1.2, at, Color3.fromRGB(140, 90, 60))
		ball(parent, "SetTree", 1.9, at * CFrame.new(0, 2, 0), Color3.fromRGB(90, 200, 110), Enum.Material.Sand)
		ball(parent, "SetTree", 1.2, at * CFrame.new(0.5, 2.8, 0), Color3.fromRGB(120, 220, 120), Enum.Material.Sand)
	else
		-- a crescent moon on a stick, and a star
		cylinder(parent, "SetStick", 0.15, 2.6, at, STEEL)
		ball(parent, "SetMoon", 1.4, at * CFrame.new(0, 2.9, 0), Color3.fromRGB(255, 230, 140), Enum.Material.Neon).CastShadow = false
		ball(parent, "SetMoonBite", 1.1, at * CFrame.new(0.45, 3.1, -0.2), FILM)
	end
end

-- A sculpting tool on the pegboard (`at`: its middle on the board, -Z into the room).
local function sculptingTool(parent: Instance, at: CFrame, index: number)
	local handle = Color3.fromRGB(225, 175, 120)
	local kind = index % 4
	makeDecor(parent, "ToolPeg", Vector3.new(0.3, 0.3, 0.6), at * CFrame.new(0, 2.4, -0.3), STEEL)
	if kind == 0 then -- a loop tool
		makeDecor(parent, "ToolHandle", Vector3.new(0.5, 3.4, 0.5), at * CFrame.new(0, 0.3, -0.4), handle, Enum.Material.Wood)
		local loop = makeDecor(parent, "ToolLoop", Vector3.new(0.15, 1.3, 1.3), at * CFrame.new(0, 2.4, -0.4) * CFrame.Angles(0, math.pi / 2, 0), Color3.fromRGB(205, 210, 225), Enum.Material.Metal)
		loop.Shape = Enum.PartType.Cylinder
	elseif kind == 1 then -- a rolling pin
		roller(parent, "RollingPin", 1.1, 4, at * CFrame.new(0, 0, -0.6) * CFrame.Angles(0, 0, math.pi / 2), handle)
		roller(parent, "RollingPinHandle", 0.5, 5.4, at * CFrame.new(0, 0, -0.6) * CFrame.Angles(0, 0, math.pi / 2), CLAY_DARK)
	elseif kind == 2 then -- a brush, its tip in clay
		makeDecor(parent, "BrushHandle", Vector3.new(0.4, 3.6, 0.4), at * CFrame.new(0, 0.4, -0.4), CLAY_TEAL)
		makeDecor(parent, "BrushTip", Vector3.new(0.7, 1, 0.5), at * CFrame.new(0, -1.9, -0.4), CLAY_COLORS[index % #CLAY_COLORS + 1])
	else -- a knife tool
		makeDecor(parent, "ToolHandle", Vector3.new(0.5, 2.6, 0.5), at * CFrame.new(0, 0.8, -0.4), handle, Enum.Material.Wood)
		wedge(parent, "ToolBlade", Vector3.new(0.12, 2, 0.6), at * CFrame.new(0, -1.5, -0.4) * CFrame.Angles(math.pi, 0, 0), Color3.fromRGB(205, 210, 225), Enum.Material.Metal)
	end
end

local function pegboard(parent: Instance, face: CFrame, width: number)
	local height = 9
	makeDecor(parent, "Pegboard", Vector3.new(width, height, 0.3), face * CFrame.new(0, 13.5, -0.2), Color3.fromRGB(245, 225, 195))
	makeDecor(parent, "PegboardFrame", Vector3.new(width + 0.8, height + 0.8, 0.25), face * CFrame.new(0, 13.5, -0.05), CLAY_TEAL)
	local count = math.floor(width / 2.4)
	for k = 0, count - 1 do
		sculptingTool(parent, face * CFrame.new(-width / 2 + (k + 0.5) * width / count, 13.5 + (k % 2) * 0.8 - 0.4, -0.35), k)
	end
	neonSign(parent, face * CFrame.new(0, 13.5 + height / 2 + 2, 0), Vector2.new(9, 2), "🛠 TOOLS", CLAY_TEAL)
end

-- Tubs of clay on a wall shelf's things (`at`: on the shelf): a tub of each color, its
-- lid off, the clay heaped in it.
local function clayTub(parent: Instance, at: CFrame, index: number)
	local color = CLAY_COLORS[index % #CLAY_COLORS + 1]
	cylinder(parent, "Tub", 2.6, 2, at, WHITE)
	cylinder(parent, "TubBand", 2.7, 0.5, at * CFrame.new(0, 0.9, 0), color)
	ball(parent, "TubClay", 2.2, at * CFrame.new(0, 1.9, 0), color, Enum.Material.Sand)
end

-- A movie camera on a dolly (`at`: on the floor under it, -Z where it looks): a track
-- of two rails, a wheeled cart, a column, the camera with two reels on top.
local function movieCamera(parent: Instance, at: CFrame)
	for _, x in { -1.6, 1.6 } do
		makeDecor(parent, "DollyRail", Vector3.new(0.35, 0.3, 14), at * CFrame.new(x, 0.15, 3), Color3.fromRGB(190, 195, 210), Enum.Material.Metal)
	end
	for k = 0, 6 do
		makeDecor(parent, "DollyTie", Vector3.new(4.2, 0.2, 0.6), at * CFrame.new(0, 0.1, -3 + k * 2), Color3.fromRGB(140, 95, 65), Enum.Material.Wood)
	end
	makeDecor(parent, "DollyCart", Vector3.new(4, 1, 4.6), at * CFrame.new(0, 1.2, 0), CLAY_TEAL)
	for _, x in { -1.6, 1.6 } do
		for _, z in { -1.6, 1.6 } do
			roller(parent, "DollyWheel", 1, 0.4, at * CFrame.new(x, 0.6, z), FILM)
		end
	end
	cylinder(parent, "DollyColumn", 1, 5.4, at * CFrame.new(0, 1.7, 0), STEEL)
	local body = at * CFrame.new(0, 8.6, 0) * CFrame.Angles(math.rad(-6), 0, 0)
	makeDecor(parent, "MovieCamera", Vector3.new(2.6, 2.6, 4.2), body, FILM)
	makeDecor(parent, "MovieCameraStripe", Vector3.new(2.7, 0.4, 4.3), body * CFrame.new(0, -0.5, 0), CLAY_GOLD)
	roller(parent, "MovieLens", 1.8, 1.6, body * CFrame.new(0, 0, -2.7) * CFrame.Angles(0, math.pi / 2, 0), STEEL)
	roller(parent, "MovieLensGlass", 1.4, 0.1, body * CFrame.new(0, 0, -3.55) * CFrame.Angles(0, math.pi / 2, 0), Color3.fromRGB(120, 200, 255)).Material = Enum.Material.Glass
	for _, z in { -0.9, 1.3 } do
		local center = body * CFrame.new(0, 2.6, z)
		local reel = Instance.new("Model")
		reel.Name = "CameraReel"
		roller(reel, "CameraReelDisc", 2.6, 0.3, center, FILM)
		for k = 0, 2 do
			local angle = k / 3 * math.pi * 2
			roller(reel, "CameraReelHole", 0.6, 0.35, center * CFrame.new(0, math.cos(angle) * 0.7, math.sin(angle) * 0.7), CLAY_TEAL)
		end
		spinner(reel, parent, center * CFrame.Angles(0, math.pi / 2, 0), if z < 0 then 1.4 else -1.4)
	end
	-- a red tally light on top: recording
	ball(parent, "TallyLight", 0.6, body * CFrame.new(0.9, 1.5, -1.6), Color3.fromRGB(255, 60, 70), Enum.Material.Neon).CastShadow = false
end

-- The director's chair (`at`: on the floor under it, -Z its front), DIRECTOR on its back,
-- a megaphone on the seat.
local function directorChair(parent: Instance, at: CFrame)
	for _, x in { -1.6, 1.6 } do
		for _, z in { -1, 1 } do
			makeDecor(parent, "ChairLeg", Vector3.new(0.35, 4.2, 0.35), at * CFrame.new(x, 2.1, z) * CFrame.Angles(z * math.rad(14), 0, 0), Color3.fromRGB(140, 95, 65), Enum.Material.Wood)
		end
		makeDecor(parent, "ChairArm", Vector3.new(0.4, 0.3, 2.6), at * CFrame.new(x, 5.2, 0.2), Color3.fromRGB(140, 95, 65), Enum.Material.Wood)
		makeDecor(parent, "ChairPost", Vector3.new(0.35, 4, 0.35), at * CFrame.new(x, 6.4, 1.2), Color3.fromRGB(140, 95, 65), Enum.Material.Wood)
	end
	makeDecor(parent, "ChairSeat", Vector3.new(3.4, 0.25, 2.4), at * CFrame.new(0, 4.2, 0), CLAY_TEAL, Enum.Material.Fabric)
	local back = makeDecor(parent, "ChairBack", Vector3.new(3.4, 1.8, 0.2), at * CFrame.new(0, 7, 1.25), CLAY_TEAL, Enum.Material.Fabric)
	label(back, Enum.NormalId.Back, "DIRECTOR", WHITE, nil, 30)
	-- the megaphone on the seat
	local cone = at * CFrame.new(0.4, 4.9, -0.2) * CFrame.Angles(0, math.rad(30), 0)
	roller(parent, "Megaphone", 1, 2.2, cone, Color3.fromRGB(255, 200, 60))
	roller(parent, "MegaphoneBell", 1.6, 0.4, cone * CFrame.new(1.2, 0, 0), WHITE)
end

-- A sculpting desk (`at`: on the floor under its middle, -Z toward the room): a wide
-- table, lumps of clay, a half-made head on a stand, tools and a lamp.
local function sculptingDesk(parent: Instance, at: CFrame)
	makeDecor(parent, "DeskTop", Vector3.new(11, 0.7, 5.6), at * CFrame.new(0, 4.3, 0), Color3.fromRGB(225, 175, 120), Enum.Material.Wood)
	for _, x in { -5, 5 } do
		makeDecor(parent, "DeskLeg", Vector3.new(0.8, 4, 5), at * CFrame.new(x, 2, 0), CLAY_DARK)
	end
	local top = at * CFrame.new(0, 4.65, 0)
	cylinder(parent, "BustStand", 0.6, 1.6, top * CFrame.new(-2.6, 0, 0.6), STEEL)
	ball(parent, "Bust", 2.8, top * CFrame.new(-2.6, 2.9, 0.6), CLAY, Enum.Material.Sand)
	for _, x in { -0.5, 0.5 } do
		ball(parent, "BustEye", 0.6, top * CFrame.new(-2.6 + x, 3.2, -0.6), WHITE)
	end
	for index, spot in { Vector3.new(1, 0.6, -0.8), Vector3.new(2.6, 0.5, 0.6), Vector3.new(3.8, 0.55, -1) } do
		ball(parent, "ClayLump", 1.4 + index * 0.2, top * CFrame.new(spot), CLAY_COLORS[index + 1], Enum.Material.Sand)
	end
	roller(parent, "DeskRollingPin", 0.7, 3.4, top * CFrame.new(1.6, 0.35, 1.6), Color3.fromRGB(225, 175, 120))
	-- the desk lamp, bent over the bust
	cylinder(parent, "LampBase", 1.4, 0.3, top * CFrame.new(4.4, 0, 1.6), STEEL)
	local elbow = (top * CFrame.new(4.4, 3.4, 1.6)).Position
	rod(parent, "LampArm", 0.25, (top * CFrame.new(4.4, 0.3, 1.6)).Position, elbow, STEEL)
	local head = (top * CFrame.new(1.2, 4.6, 0.8)).Position
	rod(parent, "LampArm", 0.25, elbow, head, STEEL)
	ball(parent, "LampShade", 1.6, CFrame.new(head), CLAY_TEAL)
	ball(parent, "LampBulb", 0.8, CFrame.new(head - Vector3.new(0, 0.6, 0)), Color3.fromRGB(255, 240, 200), Enum.Material.Neon).CastShadow = false
	makeDecor(parent, "Stool", Vector3.new(2.6, 2.8, 2.6), at * CFrame.new(-1, 1.4, -4.6), CLAY_TEAL)
end

-- A film studio light on a stand (`at`: its foot, -Z where it points), a real spotlight.
local function studioLight(parent: Instance, at: CFrame)
	for index = 0, 2 do
		local angle = index / 3 * math.pi * 2
		local toe = (at * CFrame.new(math.cos(angle) * 2.4, 0, math.sin(angle) * 2.4)).Position
		local top = (at * CFrame.new(0, 3, 0)).Position
		rod(parent, "LightLeg", 0.3, toe, top, Color3.fromRGB(50, 45, 60))
	end
	makeDecor(parent, "LightPole", Vector3.new(0.4, 11, 0.4), at * CFrame.new(0, 8.5, 0), Color3.fromRGB(50, 45, 60))
	local head = at * CFrame.new(0, 14.5, 0) * CFrame.Angles(math.rad(-25), 0, 0)
	local housing = makeDecor(parent, "LightHousing", Vector3.new(3, 3, 3.4), head, Color3.fromRGB(45, 40, 55))
	makeDecor(parent, "LightLens", Vector3.new(2.4, 2.4, 0.2), head * CFrame.new(0, 0, -1.75), Color3.fromRGB(255, 245, 215), Enum.Material.Neon)
	for _, side in { -1, 1 } do
		makeDecor(parent, "LightFlap", Vector3.new(0.15, 2.8, 1.2), head * CFrame.new(side * 1.6, 0, -2.2) * CFrame.Angles(0, side * math.rad(25), 0), Color3.fromRGB(45, 40, 55))
	end
	local light = Instance.new("SpotLight")
	light.Face = Enum.NormalId.Front
	light.Angle = 60
	light.Range = 40
	light.Brightness = 1.2
	light.Color = Color3.fromRGB(255, 240, 215)
	light.Parent = housing
end

-- The ON AIR sign (`face`: its middle on the wall, -Z into the room): red neon in a
-- frame of chasing bulbs.
local function onAirSign(parent: Instance, face: CFrame)
	local size = Vector2.new(13, 3.6)
	neonSign(parent, face, size, "● ON AIR", Color3.fromRGB(255, 60, 75))
	local index = 0
	for _, y in { -1, 1 } do
		for k = 0, 7 do
			index += 1
			local bulb = ball(parent, "Bulb", 0.7, face * CFrame.new(-size.X / 2 - 0.3 + k * (size.X + 0.6) / 7, y * (size.Y / 2 + 0.9), -0.4), Color3.fromRGB(255, 215, 130), Enum.Material.Neon)
			bulb.CastShadow = false
			bulb:SetAttribute("Index", if y < 0 then 16 - k else k)
			CollectionService:AddTag(bulb, "Marquee")
		end
	end
end

local function buildClay(parent: Instance, floor: CFrame)
	-- the sign over the side door off the outside stairs (X = +70, Z = 31), and chasing
	-- string lights round the walls by the ceiling
	neonSign(parent, wallFace(floor, { 68, 22.5, 31 }), Vector2.new(22, 4.4), "🎬 CLAY STUDIO 🎬", Color3.fromRGB(255, 140, 70))
	local function at(x: number, y: number, z: number): Vector3
		return (floor * CFrame.new(x, y, z)).Position
	end
	local index = 0
	index = stringLights(parent, at(-66, 26, -57), at(-66, 26, 0), 1.6, index)
	index = stringLights(parent, at(-66, 26, 0), at(-66, 26, 57), 1.6, index)
	index = stringLights(parent, at(-66, 26, 57), at(-21, 26, 57), 1.6, index)
	index = stringLights(parent, at(21, 26, 57), at(66, 26, 57), 1.6, index)
	index = stringLights(parent, at(66, 26, 57), at(66, 26, 44), 1.2, index)
	index = stringLights(parent, at(66, 26, 18), at(66, 26, -57), 1.6, index)
	stringLights(parent, at(66, 26, -57), at(-66, 26, -57), 2, index)

	-- the walkways between the turntables: film-strip runners, lighting trusses over
	-- them with spotlights on the tables either side, and a hanging sign on each
	for index_, x in { -21, 21 } do
		filmRunner(parent, floor, x, -44, 46)
		truss(parent, floor, x, -36, 42, {
			Vector3.new(x - 21, 4, 4),
			Vector3.new(x + 21, 4, 4),
			Vector3.new(x - 21, 4, 18),
			Vector3.new(x + 21, 4, 18),
		})
		hangingSign(parent, floor * CFrame.new(x, 25, -30), 4, Vector2.new(12, 2.6), if index_ == 1 then "🎬 LIGHTS, CAMERA, CLAY!" else "★ 100% HANDMADE ★", if index_ == 1 then Color3.fromRGB(255, 140, 70) else CLAY_TEAL)
	end

	-- the front wall: ON AIR over the middle, brainrot claymation posters between the
	-- windows and in the corners
	onAirSign(parent, wallFace(floor, { 0, 16, -58 }))
	for _, ad in {
		{ -39, 14, "🥁", "TUNG TUNG: THE MOVIE" },
		{ 39, 14, "🦈", "JAWS OF TRALALERO" },
		{ -63.5, 14, "🐊", "BOMBARDIRO RETURNS" },
		{ 63.5, 14, "🍌", "CHIMPANZINI 2" },
	} do
		local x = ad[1] :: number
		poster(parent, wallFace(floor, { x, ad[2] :: number, -58 }), Vector2.new(7.5, 10), CLAY_COLORS[if x > 0 then 3 else 5], CLAY_GOLD, ad[3] :: string, ad[4] :: string)
	end

	-- the back wall: two giant film reels turning, the film running between them over the
	-- doorway, and a shelf of sets and clay maquettes beside it
	wallReel(parent, wallFace(floor, { -42, 19.5, 59 }), 9.5, 0.6)
	wallReel(parent, wallFace(floor, { 42, 19.5, 59 }), 9.5, 0.6)
	wallFilm(parent, floor, { -37, 21.5, 59 }, { 37, 21.5, 59 })
	wallShelf(parent, wallFace(floor, { -24, -6, 59 }), 14, Color3.fromRGB(245, 225, 195), CLAY_TEAL, setPiece)
	-- (lowered: its board reaches up to 20.7 - 6, under the film between the reels)

	-- the left wall: the storyboard, a shelf of miniature sets, a giant clapperboard
	storyboard(parent, wallFace(floor, { -68, 14, -18 }))
	wallShelf(parent, wallFace(floor, { -68, 0, 18 }), 18, Color3.fromRGB(245, 225, 195), CLAY, setPiece)
	local clap = wallFace(floor, { -68, 13, 50 })
	makeDecor(parent, "WallClapBoard", Vector3.new(8, 6, 0.4), clap * CFrame.new(0, 0, -0.2), FILM)
	for k = 0, 5 do
		makeDecor(parent, "WallClapStripe", Vector3.new(1.2, 1.4, 0.45), clap * CFrame.new(-3.3 + k * 1.33, 3.7, -0.2) * CFrame.Angles(0, 0, math.rad(-20)), if k % 2 == 0 then WHITE else FILM)
	end
	local slate = makeDecor(parent, "WallClapSlate", Vector3.new(7, 4.4, 0.1), clap * CFrame.new(0, -0.4, -0.45), FILM)
	label(slate, Enum.NormalId.Front, "SCENE 67\nTAKE 2", WHITE, CLAY_TEAL, 24)

	-- the right wall: a pegboard of sculpting tools, tubs of clay on a shelf
	pegboard(parent, wallFace(floor, { 68, 0, -18 }), 16)
	wallShelf(parent, wallFace(floor, { 68, 0, 14 }), 13, Color3.fromRGB(245, 225, 195), CLAY_TEAL, clayTub)

	-- paint splats up the walls where there's room
	for index_, spot in { { -68, 22, -36 }, { -68, 22, 36 }, { 68, 22, -43 }, { -50, 6, -58 }, { 50, 6, -58 }, { -60, 6, 59 } } :: { WallSpot } do
		splat(parent, wallFace(floor, spot), 3.4 + (index_ % 3) * 0.8, PAINT_COLORS[index_ % #PAINT_COLORS + 1])
	end

	-- the front-left corner: the movie camera on its dolly, the director's chair, a light
	movieCamera(parent, floor * CFrame.new(-55, 0, -44) * CFrame.Angles(0, math.rad(215), 0))
	directorChair(parent, floor * CFrame.new(-44, 0, -51) * CFrame.Angles(0, math.rad(205), 0))
	studioLight(parent, floor * CFrame.new(-64, 0, -36) * CFrame.Angles(0, math.rad(-120), 0))
	-- the front-right corner: the sculpting desk against the front wall, a light
	sculptingDesk(parent, floor * CFrame.new(52, 0, -54.5) * CFrame.Angles(0, math.pi, 0))
	studioLight(parent, floor * CFrame.new(63.5, 0, -40) * CFrame.Angles(0, math.rad(140), 0))
	-- the back-left corner: the giant sculpture turning on its plinth, pots by it
	sculpture(parent, floor * CFrame.new(-58, 0, 47))
	pot(parent, floor * CFrame.new(-64, 0, 36), 7, CLAY)
	pot(parent, floor * CFrame.new(-48, 0, 54), 6, CLAY_LIGHT)
	-- the back-right corner: buckets of clay slip
	for index_, spot in { Vector3.new(62, 0, 50), Vector3.new(57, 0, 54), Vector3.new(62.5, 0, 55) } do
		cylinder(parent, "Bucket", 4, 3.6, floor * CFrame.new(spot), Color3.fromRGB(150, 180, 220))
		cylinder(parent, "Slip", 3.6, 0.3, floor * CFrame.new(spot + Vector3.new(0, 3.4, 0)), CLAY_COLORS[index_])
	end
	-- splats of clay on the floor at the front, where people walk in
	local random = Random.new(9)
	for k = 1, 14 do
		local spot = floor * CFrame.new(random:NextNumber(-40, 40), 0.06, random:NextNumber(-55, -32))
		local size = random:NextNumber(1.4, 3)
		local blob = makeDecor(parent, "FloorSplat", Vector3.new(0.08, size, size), spot * CFrame.Angles(0, 0, math.pi / 2), CLAY_COLORS[k % #CLAY_COLORS + 1])
		blob.Shape = Enum.PartType.Cylinder
	end
end

-- Vinyl Collectibles --------------------------------------------------------------------
-- A designer-toy gallery (GDD §10): a glossy navy checker floor (the white ramps and the
-- glossy figures pop on it), royal blue striped walls over a hot-pink band, gold trims.
-- Each line is a spiral display tower (LineLayouts "Tower"); round them: the GRAIL in a
-- glass case behind velvet ropes, a giant gacha machine, a wall of mystery boxes, THE
-- COLLECTION, boxed figures, figures on pedestals under spotlights, drop posters.

local VINYL_BLUE = Color3.fromRGB(70, 95, 235)
local VINYL_NAVY = Color3.fromRGB(35, 40, 110)
local VINYL_PINK = Color3.fromRGB(255, 80, 190)
local VINYL_GOLD = Color3.fromRGB(255, 200, 50)
local VINYL_GLASS = Color3.fromRGB(215, 232, 255)
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
	label(holder, Enum.NormalId.Front, "⭐", WHITE, nil, 12)
end

-- A see-through pane (not Glass: Glass hides what's behind it and washes its colors out).
local function pane(parent: Instance, size: Vector3, cframe: CFrame)
	local glass = makeDecor(parent, "Glass", size, cframe, VINYL_GLASS)
	glass.Transparency = 0.7
	glass.CastShadow = false
	return glass
end

-- THE GRAIL (`at`: on the floor under it, -Z its front): the rarest figure, turning
-- slowly in a gold-framed glass case on a navy plinth, lit from above, behind velvet
-- ropes on gold stanchions.
local function grail(parent: Instance, at: CFrame, id: string)
	cylinder(parent, "GrailPlinth", 7, 3.6, at, VINYL_NAVY)
	cylinder(parent, "GrailPlinthTrim", 7.4, 0.5, at * CFrame.new(0, 3.3, 0), VINYL_GOLD, Enum.Material.Metal)
	cylinder(parent, "GrailPlinthGlow", 7.5, 0.25, at * CFrame.new(0, 1.2, 0), VINYL_PINK, Enum.Material.Neon).CastShadow = false
	local floor = at * CFrame.new(0, 3.8, 0)
	-- the figure on a little gold turntable, turning
	local turning = Instance.new("Model")
	turning.Name = "GrailFigure"
	cylinder(turning, "GrailStand", 4, 0.4, floor, VINYL_GOLD, Enum.Material.Metal)
	local doll = figure(id, floor * CFrame.new(0, 0.4, 0), "VinylCollectibles")
	doll.Parent = turning
	spinner(turning, parent, floor * CFrame.Angles(math.pi / 2, 0, 0), 0.4)
	-- the case: glass on four sides, gold posts and a gold top with a light in it
	local height = 7.5
	for side = 0, 3 do
		local face = floor * CFrame.Angles(0, side * math.pi / 2, 0) * CFrame.new(0, height / 2, -2.6)
		pane(parent, Vector3.new(5.2, height, 0.15), face)
		makeDecor(parent, "GrailPost", Vector3.new(0.35, height, 0.35), face * CFrame.new(2.6, 0, 0), VINYL_GOLD, Enum.Material.Metal)
	end
	local lid = makeDecor(parent, "GrailLid", Vector3.new(5.8, 0.5, 5.8), floor * CFrame.new(0, height + 0.25, 0), VINYL_GOLD, Enum.Material.Metal)
	local light = Instance.new("SpotLight")
	light.Face = Enum.NormalId.Bottom
	light.Angle = 70
	light.Range = 12
	light.Brightness = 2.5
	light.Color = Color3.fromRGB(255, 240, 220)
	light.Parent = lid
	ball(parent, "GrailCrown", 1.2, floor * CFrame.new(0, height + 1.1, 0), VINYL_PINK, Enum.Material.Neon)
	-- velvet ropes round it, sagging between gold stanchions
	local posts = {}
	for k = 0, 5 do
		local angle = (k + 0.5) / 6 * math.pi * 2
		local foot = at * CFrame.new(math.sin(angle) * 6.5, 0, math.cos(angle) * 6.5)
		cylinder(parent, "StanchionFoot", 1.4, 0.3, foot, VINYL_GOLD, Enum.Material.Metal)
		cylinder(parent, "Stanchion", 0.35, 3.4, foot, VINYL_GOLD, Enum.Material.Metal)
		ball(parent, "StanchionTop", 0.6, foot * CFrame.new(0, 3.5, 0), VINYL_GOLD, Enum.Material.Metal)
		table.insert(posts, (foot * CFrame.new(0, 3.2, 0)).Position)
	end
	for k = 1, #posts - 1 do -- (open at the back, toward the wall)
		local a, b = posts[k], posts[k + 1]
		local low = (a + b) / 2 - Vector3.new(0, 0.8, 0)
		rod(parent, "VelvetRope", 0.3, a, low, Color3.fromRGB(200, 30, 70), Enum.Material.Fabric)
		rod(parent, "VelvetRope", 0.3, low, b, Color3.fromRGB(200, 30, 70), Enum.Material.Fabric)
	end
end

-- A giant gacha machine (`at`: its foot, -Z its front): a hot-pink cabinet with a coin
-- slot, a gold crank turning and a chute, under a huge clear globe of capsules (a heap,
-- and more swirling round), a gold cap and a GACHA! sign.
local function giantGacha(parent: Instance, at: CFrame)
	makeDecor(parent, "GachaCabinet", Vector3.new(9, 8, 8), at * CFrame.new(0, 4, 0), VINYL_PINK)
	makeDecor(parent, "GachaCabinetStripe", Vector3.new(9.1, 0.8, 8.1), at * CFrame.new(0, 2, 0), WHITE)
	makeDecor(parent, "GachaCabinetTrim", Vector3.new(9.4, 0.6, 8.4), at * CFrame.new(0, 8, 0), VINYL_GOLD, Enum.Material.Metal)
	makeDecor(parent, "GachaFoot", Vector3.new(9.6, 0.6, 8.6), at * CFrame.new(0, 0.3, 0), VINYL_NAVY)
	-- the front: a coin slot, the chute's flap and a big gold crank turning
	local front = at * CFrame.new(0, 0, -4.05)
	local plate = makeDecor(parent, "GachaSlotPlate", Vector3.new(2.6, 1.6, 0.2), front * CFrame.new(-2.5, 6, 0), VINYL_GOLD, Enum.Material.Metal)
	label(plate, Enum.NormalId.Front, "🪙 1", VINYL_NAVY, nil, 24)
	makeDecor(parent, "GachaChute", Vector3.new(3.4, 2.6, 0.3), front * CFrame.new(2, 2.6, 0), VINYL_NAVY)
	makeDecor(parent, "GachaChuteFlap", Vector3.new(3, 2.2, 0.2), front * CFrame.new(2, 2.6, -0.15), Color3.fromRGB(220, 240, 255))
	local hub = front * CFrame.new(-2.5, 3.3, -0.3)
	local crank = Instance.new("Model")
	crank.Name = "GachaCrank"
	local wheel = makeDecor(crank, "GachaCrankWheel", Vector3.new(0.5, 3.2, 3.2), hub * CFrame.Angles(0, math.pi / 2, 0), VINYL_GOLD, Enum.Material.Metal)
	wheel.Shape = Enum.PartType.Cylinder
	makeDecor(crank, "GachaCrankBar", Vector3.new(3.8, 0.6, 0.6), hub * CFrame.new(0, 0, -0.3), WHITE)
	spinner(crank, parent, hub, 0.8)
	-- the globe, clear, full of capsules
	local globeAt = at * CFrame.new(0, 13.4, 0)
	cylinder(parent, "GachaGlobeCollar", 7.4, 1, at * CFrame.new(0, 8.3, 0), VINYL_NAVY)
	local globe = ball(parent, "GachaGlobe", 11, globeAt, VINYL_GLASS)
	globe.Transparency = 0.72
	globe.CastShadow = false
	local random = Random.new(11)
	for k = 1, 16 do
		local angle = random:NextNumber(0, math.pi * 2)
		local out = random:NextNumber(0, 3.4)
		ball(parent, "GachaCapsule", 1.9, globeAt * CFrame.new(math.cos(angle) * out, -3.6 + (k % 3) * 0.9, math.sin(angle) * out), FIGURE_COLORS[k % #FIGURE_COLORS + 1])
	end
	local swirl = Instance.new("Model")
	swirl.Name = "GachaSwirl"
	for k = 0, 7 do
		local angle = k / 8 * math.pi * 2
		ball(swirl, "GachaCapsule", 1.6, globeAt * CFrame.new(math.cos(angle) * 3.4, 0.6 + (k % 2) * 1.2, math.sin(angle) * 3.4), FIGURE_COLORS[k % #FIGURE_COLORS + 1])
	end
	spinner(swirl, parent, globeAt * CFrame.Angles(math.pi / 2, 0, 0), 0.9)
	cylinder(parent, "GachaCap", 3, 1, at * CFrame.new(0, 18.7, 0), VINYL_GOLD, Enum.Material.Metal)
	ball(parent, "GachaCapKnob", 1.6, at * CFrame.new(0, 20.1, 0), VINYL_PINK, Enum.Material.Neon)
	local sign = makeDecor(parent, "GachaSign", Vector3.new(8, 2.6, 0.3), at * CFrame.new(0, 23.2, 0) * CFrame.Angles(0, math.pi, 0), Color3.fromRGB(40, 28, 60))
	label(sign, Enum.NormalId.Back, "GACHA!", Color3.fromRGB(255, 230, 245), VINYL_PINK, 30)
	label(sign, Enum.NormalId.Front, "GACHA!", Color3.fromRGB(255, 230, 245), VINYL_PINK, 30)
	rod(parent, "GachaSignPole", 0.3, (at * CFrame.new(0, 20.6, 0)).Position, (at * CFrame.new(0, 21.9, 0)).Position, VINYL_GOLD)
end

-- A wall of mystery boxes (`face`: on the wall at the floor under its middle, -Z into the
-- room): rows of colored boxes with a big ? on each, on gold shelves, a neon sign on top.
local function mysteryWall(parent: Instance, face: CFrame)
	local columns, rows = 5, 3
	makeDecor(parent, "MysteryBoard", Vector3.new(columns * 4.2 + 1.4, rows * 4.6 + 1.2, 0.3), face * CFrame.new(0, 3 + rows * 2.3, -0.2), VINYL_NAVY)
	for row = 0, rows - 1 do
		local y = 3.5 + row * 4.6
		makeDecor(parent, "MysteryShelf", Vector3.new(columns * 4.2 + 1, 0.4, 2.55), face * CFrame.new(0, y - 0.2, -1.525), VINYL_GOLD, Enum.Material.Metal)
		for column = 0, columns - 1 do
			local color = FIGURE_COLORS[(row * columns + column) % #FIGURE_COLORS + 1]
			local box = makeDecor(parent, "MysteryBox", Vector3.new(3.4, 3.4, 2.2), face * CFrame.new(-(columns - 1) * 2.1 + column * 4.2, y + 1.7, -1.5) * CFrame.Angles(0, math.rad((column % 2) * 8 - 4), 0), color)
			label(box, Enum.NormalId.Front, "?", WHITE, color:Lerp(Color3.new(0, 0, 0), 0.35), 20)
			makeDecor(parent, "MysteryRibbon", Vector3.new(0.5, 3.45, 2.25), box.CFrame, WHITE)
		end
	end
	neonSign(parent, face * CFrame.new(0, 4.6 + rows * 4.6, 0), Vector2.new(18, 3.2), "🎁 MYSTERY BOXES 🎁", VINYL_PINK)
end

-- A display pedestal under a spotlight (`at`: its foot) with a real vinyl figure on top.
local function pedestal(parent: Instance, at: CFrame, id: string, lampSide: number)
	cylinder(parent, "Pedestal", 5, 4, at, WHITE)
	cylinder(parent, "PedestalTrim", 5.3, 0.4, at * CFrame.new(0, 3.2, 0), VINYL_PINK, Enum.Material.Neon).CastShadow = false
	cylinder(parent, "PedestalTop", 5.6, 0.6, at * CFrame.new(0, 4, 0), VINYL_GOLD, Enum.Material.Metal)
	figure(id, at * CFrame.new(0, 4.6, 0), "VinylCollectibles").Parent = parent
	local lamp = at * CFrame.new(lampSide * 4, 0, -4)
	cylinder(parent, "SpotlightStand", 0.5, 12, lamp, VINYL_NAVY)
	local head = makeDecor(parent, "Spotlight", Vector3.new(2, 2, 2.6), CFrame.lookAt((lamp * CFrame.new(0, 12, 0)).Position, (at * CFrame.new(0, 7, 0)).Position), VINYL_NAVY)
	local glow = makeDecor(parent, "SpotlightGlow", Vector3.new(1.4, 1.4, 0.2), head.CFrame * CFrame.new(0, 0, -1.35), Color3.fromRGB(255, 245, 200), Enum.Material.Neon)
	local light = Instance.new("SpotLight")
	light.Face = Enum.NormalId.Front
	light.Angle = 40
	light.Range = 16
	light.Brightness = 1.5
	light.Color = Color3.fromRGB(255, 240, 220)
	light.Parent = glow
end

local function buildVinyl(parent: Instance, floor: CFrame)
	-- the sign over the doorway from the Clay Studio, and chasing string lights
	neonSign(parent, wallFace(floor, { 0, 23.2, -59 }), Vector2.new(34, 5.4), "✨ VINYL COLLECTIBLES ✨", VINYL_PINK)
	local function at(x: number, y: number, z: number): Vector3
		return (floor * CFrame.new(x, y, z)).Position
	end
	local index = 0
	index = stringLights(parent, at(-66, 26, -58), at(-66, 26, 0), 1.6, index)
	index = stringLights(parent, at(-66, 26, 0), at(-66, 26, 57), 1.6, index)
	index = stringLights(parent, at(-66, 26, 57), at(66, 26, 57), 2.2, index)
	index = stringLights(parent, at(66, 26, 57), at(66, 26, 0), 1.6, index)
	index = stringLights(parent, at(66, 26, 0), at(66, 26, -58), 1.6, index)
	index = stringLights(parent, at(66, 26, -58), at(20, 26, -58), 1.6, index)
	stringLights(parent, at(-20, 26, -58), at(-66, 26, -58), 1.6, index)

	-- royal blue carpets down the walkways between the towers, lamps and neon signs
	-- over them
	for index_, x in { -19.6, 22.4 } do
		runway(parent, floor, x, -18, 45, VINYL_BLUE)
		for k, z in { -32, -2, 30 } do
			pendantLamp(parent, floor * CFrame.new(x, 28, z), 5, if (index_ + k) % 2 == 0 then VINYL_PINK else VINYL_GOLD)
		end
		hangingSign(parent, floor * CFrame.new(x, 28, 14), 6, Vector2.new(12, 2.6), if index_ == 1 then "✨ MINT CONDITION ✨" else "★ LIMITED EDITION ★", if index_ == 1 then VINYL_PINK else VINYL_GOLD)
	end

	-- the front wall, either side of the doorway: drop posters
	poster(parent, wallFace(floor, { -32, 14, -59 }), Vector2.new(8, 10), VINYL_PINK, VINYL_GOLD, "🦈", "NEW DROP!")
	poster(parent, wallFace(floor, { 32, 14, -59 }), Vector2.new(8, 10), VINYL_BLUE, VINYL_GOLD, "🥁", "LIMITED RUN")
	-- the left wall: the wall of mystery boxes; the right wall: chase posters; gold stars
	mysteryWall(parent, wallFace(floor, { -68, 0, -10 }))
	poster(parent, wallFace(floor, { 68, 14, -18 }), Vector2.new(8, 10), Color3.fromRGB(120, 70, 220), VINYL_GOLD, "👑", "CHASE 1/144")
	poster(parent, wallFace(floor, { 68, 14, 18 }), Vector2.new(8, 10), VINYL_PINK, VINYL_GOLD, "🐊", "SOLD OUT!")
	local spots: { WallSpot } = { { -68, 19, 24 }, { 68, 21, 0 }, { 50, 19, -59 } }
	for index_, spot in spots do
		wallStar(parent, wallFace(floor, spot), 6 + (index_ % 2) * 2)
	end

	-- the collection case on the back wall: real brainrot figures, glossy vinyl
	bestSellers(parent, wallFace(floor, { 0, 0, 58 }), 20, "VinylCollectibles", "💎 THE COLLECTION 💎", VINYL_PINK)
	-- a shelf of boxed figures beside it, clear of the first line
	local shelf = floor * CFrame.new(-24, 0, 55.5)
	for _, x in { -10, 10 } do
		makeDecor(parent, "ShelfSide", Vector3.new(1, 16, 4), shelf * CFrame.new(x, 8, 0), WHITE)
	end
	for row = 0, 2 do
		makeDecor(parent, "Shelf", Vector3.new(20, 0.6, 4), shelf * CFrame.new(0, 1 + row * 5, 0), Color3.fromRGB(130, 175, 255))
		for column = 0, 2 do
			figureBox(parent, shelf * CFrame.new(-6 + column * 6, 1.3 + row * 5, 0), FIGURE_COLORS[(row * 3 + column) % #FIGURE_COLORS + 1])
		end
	end
	-- figures on pedestals under spotlights in the back corners
	pedestal(parent, floor * CFrame.new(62, 0, 52) * CFrame.Angles(0, math.rad(20), 0), "BombardiroCrocodilo", -1)
	pedestal(parent, floor * CFrame.new(-59, 0, 47) * CFrame.Angles(0, math.rad(-20), 0), "LaVacaSaturnoSaturnita", 1)
	-- the front corners: THE GRAIL behind its velvet ropes, and the giant gacha machine
	grail(parent, floor * CFrame.new(-54, 0, -49) * CFrame.Angles(0, math.rad(200), 0), "DragonCannelloni")
	neonSign(parent, wallFace(floor, { -54, 17, -59 }), Vector2.new(14, 3), "👑 THE GRAIL 👑", VINYL_GOLD)
	giantGacha(parent, floor * CFrame.new(56, 0, -49) * CFrame.Angles(0, math.rad(160), 0))
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
	candyCane(parent, floor * CFrame.new(58, 0, -40) * CFrame.Angles(0, math.pi, 0), Color3.fromRGB(120, 200, 255), 1.6) -- (clear of the lift's door)
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
	ToyWorkshop = buildToy,
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
