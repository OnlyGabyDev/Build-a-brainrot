--[[
	RoomDecor
	Themed props inside the factory's rooms (GDD §10), so every room is lovely on its
	own, before any upgrade: the playable rooms (Toy Workshop, Plushie room) get a neon
	sign over the door, flags or pom-poms round the walls, rugs down the walkways between
	the lines with lamps and turning mobiles over them, shelves of toys or plushies,
	posters, a clock, a quilt, giant toys; the locked rooms show their theme through
	their glass doors.

	Room space: `floor` is the room's floor center, -Z toward the building's front (the
	hub). Rooms are 140 × 120. The lines run along Z at X = -42, 0 and 42 (from Z = -38
	to 54), each with its buttons on its +X side: props keep to the walls, the front
	corners and the walkways' floors and ceilings, clear of the doors: the front doorway
	(Z = -60, |X| < 13), the Clay Studio's side door (X = +70 around Z = 31) and the
	Candy Factory's (Z = +60, |X| < 8). Room upgrades (RoomUpgrades) have spots of their
	own. FactoryBuilder calls RoomDecor.Build for every room.
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
	local panel = makeDecor(parent, "NeonSign", Vector3.new(size.X, size.Y, 0.4), face * CFrame.new(0, 0, -0.3), SIGN_BACK)
	label(panel, Enum.NormalId.Front, text, color:Lerp(WHITE, 0.65), color)
	local tube = color:Lerp(WHITE, 0.3)
	for _, y in { -1, 1 } do
		makeDecor(parent, "NeonTube", Vector3.new(size.X + 0.6, 0.35, 0.35), face * CFrame.new(0, y * (size.Y / 2 + 0.15), -0.55), tube, Enum.Material.Neon)
	end
	for _, x in { -1, 1 } do
		makeDecor(parent, "NeonTube", Vector3.new(0.35, size.Y + 0.6, 0.35), face * CFrame.new(x * (size.X / 2 + 0.15), 0, -0.55), tube, Enum.Material.Neon)
	end
end

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

-- A sagging string of fluffy pom-poms from `from` to `to` (world positions).
local function pomGarland(parent: Instance, from: Vector3, to: Vector3, colors: { Color3 }, sag: number)
	local middle = (from + to) / 2 - Vector3.new(0, sag, 0)
	local index = 0
	for _, span in { { from, middle }, { middle, to } } do
		local a, b = span[1], span[2]
		rod(parent, "GarlandLine", 0.12, a, b, WHITE).CastShadow = false
		local count = math.max(1, math.floor((b - a).Magnitude / 2.8))
		for k = 1, count do
			index += 1
			local pom = ball(parent, "PomPom", 1.2 + (index % 3) * 0.2, CFrame.new(a:Lerp(b, (k - 0.5) / count) - Vector3.new(0, 0.5, 0)), colors[(index - 1) % #colors + 1], Enum.Material.Fabric)
			pom.CastShadow = false
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

-- A flat star (`at`: its middle, facing along its Z), `size` across.
local function star(parent: Instance, at: CFrame, size: number, color: Color3, material: Enum.Material?)
	for _, turn in { 0, math.pi / 4 } do
		makeDecor(parent, "Star", Vector3.new(size * 0.7, size * 0.7, size * 0.25), at * CFrame.Angles(0, 0, turn), color, material)
	end
end

-- A framed poster on a wall (`face`: its middle on the wall, -Z into the room): a big
-- emoji on a colored background, a caption under it.
local function poster(parent: Instance, face: CFrame, size: Vector2, background: Color3, frame: Color3, emoji: string, caption: string)
	makeDecor(parent, "PosterFrame", Vector3.new(size.X + 0.8, size.Y + 0.8, 0.3), face * CFrame.new(0, 0, -0.15), frame)
	local sheet = makeDecor(parent, "Poster", Vector3.new(size.X, size.Y, 0.2), face * CFrame.new(0, 0, -0.35), background)
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
	makeDecor(parent, "ShelfBack", Vector3.new(width + 1, 12.5, 0.3), face * CFrame.new(0, 14.5, -0.15), board)
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

-- A see-through holder for an emoji standing just off a wall (`face`: on the wall).
local function wallEmoji(parent: Instance, face: CFrame, size: number, emoji: string)
	local holder = makeDecor(parent, "Picture", Vector3.new(size, size, 0.1), face, WHITE)
	holder.Transparency = 1
	emojiOn(holder, Enum.NormalId.Front, emoji)
end

-- A teddy bear sitting on `at` (-Z its front), `scale` times shelf size.
local function teddy(parent: Instance, at: CFrame, color: Color3, scale: number)
	local s = scale
	local light = color:Lerp(WHITE, 0.45)
	local dark = Color3.fromRGB(55, 40, 50)
	ball(parent, "TeddyBody", 2.2 * s, at * CFrame.new(0, 1.1 * s, 0), color, Enum.Material.Fabric)
	ball(parent, "TeddyBelly", 1.4 * s, at * CFrame.new(0, 1 * s, -0.5 * s), light, Enum.Material.Fabric)
	ball(parent, "TeddyHead", 1.8 * s, at * CFrame.new(0, 2.65 * s, -0.1 * s), color, Enum.Material.Fabric)
	for _, x in { -1, 1 } do
		ball(parent, "TeddyEar", 0.7 * s, at * CFrame.new(x * 0.7 * s, 3.45 * s, -0.1 * s), color, Enum.Material.Fabric)
		ball(parent, "TeddyPaw", 0.8 * s, at * CFrame.new(x * 1 * s, 1.5 * s, -0.4 * s), color, Enum.Material.Fabric)
		ball(parent, "TeddyFoot", 0.85 * s, at * CFrame.new(x * 0.6 * s, 0.4 * s, -0.75 * s), light, Enum.Material.Fabric)
		ball(parent, "TeddyEye", 0.25 * s, at * CFrame.new(x * 0.35 * s, 2.85 * s, -0.9 * s), dark)
	end
	ball(parent, "TeddySnout", 0.75 * s, at * CFrame.new(0, 2.5 * s, -0.85 * s), light, Enum.Material.Fabric)
	ball(parent, "TeddyNose", 0.28 * s, at * CFrame.new(0, 2.62 * s, -1.2 * s), dark)
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
	for index, crate in {
		{ At = Vector3.new(0, 0, -2.4), Size = Vector3.new(4.6, 4.2, 4.6), Turn = 0.08 },
		{ At = Vector3.new(0.2, 0, 2.4), Size = Vector3.new(4.4, 3.8, 4.4), Turn = -0.12 },
		{ At = Vector3.new(0, 4.2, -1.8), Size = Vector3.new(3.8, 3.4, 3.8), Turn = 0.3 },
		{ At = Vector3.new(0.4, 3.8, 2.6), Size = Vector3.new(3, 2.6, 3), Turn = -0.25 },
	} do
		local box = makeDecor(parent, "Crate", crate.Size, at * CFrame.new(crate.At + Vector3.new(0, crate.Size.Y / 2, 0)) * CFrame.Angles(0, crate.Turn, 0), cardboard)
		makeDecor(parent, "CrateTape", Vector3.new(crate.Size.X + 0.1, 0.5, crate.Size.Z * 0.25), box.CFrame * CFrame.new(0, crate.Size.Y / 2, 0), tape)
		label(box, Enum.NormalId.Left, prints[index], Color3.fromRGB(150, 70, 40), nil, 12)
		label(box, Enum.NormalId.Front, prints[(index % #prints) + 1], Color3.fromRGB(150, 70, 40), nil, 12)
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
	for index, x in { -60, 62.5 } do
		pendantLamp(parent, floor * CFrame.new(x, 28, 0), 6, TOY_COLORS[index + 3])
	end

	-- toy shelves on the side walls, between the windows
	local shelfBoard, shelfTrim = WHITE, Color3.fromRGB(110, 190, 255)
	wallShelf(parent, wallFace(floor, { -68, 0, 18 }), 18, shelfBoard, shelfTrim, shelfToy)
	wallShelf(parent, wallFace(floor, { 68, 0, -18 }), 18, shelfBoard, Color3.fromRGB(255, 130, 150), shelfToy)
	wallShelf(parent, wallFace(floor, { 68, 0, 18 }), 18, shelfBoard, Color3.fromRGB(255, 205, 70), shelfToy)

	-- brainrot posters by the entrance and in the corners
	poster(parent, wallFace(floor, { -20, 12, -58 }), Vector2.new(7, 9), TOY_COLORS[3], WHITE, "🦈", "TRALALERO!")
	poster(parent, wallFace(floor, { 20, 12, -58 }), Vector2.new(7, 9), TOY_COLORS[1], WHITE, "🐊", "BOMBARDIRO!")
	poster(parent, wallFace(floor, { -68, 16, -50 }), Vector2.new(7, 9), TOY_COLORS[5], WHITE, "☕", "BALLERINA!")
	poster(parent, wallFace(floor, { 68, 16, -50 }), Vector2.new(7, 9), TOY_COLORS[4], WHITE, "🍌", "CHIMPANZINI!")
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

local PLUSH_COLORS = {
	Color3.fromRGB(255, 130, 190), -- pink
	Color3.fromRGB(170, 135, 255), -- lavender
	Color3.fromRGB(120, 205, 255), -- baby blue
	Color3.fromRGB(255, 205, 110), -- butter
	Color3.fromRGB(125, 220, 170), -- mint
}

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

-- A giant sewing machine on its table, `scale` times human size (`at`: under the
-- table's middle, -Z its front).
local function sewingMachine(parent: Instance, at: CFrame, scale: number)
	local body, trim = Color3.fromRGB(240, 105, 170), Color3.fromRGB(255, 240, 248)
	local function box(name: string, size: Vector3, offset: Vector3, color: Color3, material: Enum.Material?)
		makeDecor(parent, name, size * scale, at * CFrame.new(offset * scale), color, material)
	end
	box("SewingTable", Vector3.new(20, 1, 8), Vector3.new(0, 5, 0), Color3.fromRGB(215, 160, 110), Enum.Material.Wood)
	for _, x in { -9, 9 } do
		box("SewingLeg", Vector3.new(1, 4.5, 7), Vector3.new(x, 2.25, 0), Color3.fromRGB(150, 110, 220))
	end
	box("SewingBase", Vector3.new(16, 2, 6), Vector3.new(0, 6.5, 0), body)
	box("SewingPillar", Vector3.new(3.5, 7, 5), Vector3.new(6, 11, 0), body)
	box("SewingArm", Vector3.new(15, 3, 4.6), Vector3.new(-0.5, 15.5, 0), body)
	box("SewingHead", Vector3.new(3, 4, 4), Vector3.new(-6.5, 13.5, 0), body)
	box("SewingNeedle", Vector3.new(0.3, 3, 0.3), Vector3.new(-6.5, 10, 0), Color3.fromRGB(200, 205, 215), Enum.Material.Metal)
	box("SewingStripe", Vector3.new(15.2, 0.6, 4.8), Vector3.new(-0.5, 15.5, 0), trim)
	roller(parent, "SewingWheel", 5 * scale, scale, at * CFrame.new(8.7 * scale, 14 * scale, 0), trim)
	-- a heart on its base, facing the room
	local badge = makeDecor(parent, "SewingBadge", Vector3.new(3, 3, 0.2) * scale, at * CFrame.new(0, 6.5 * scale, -3.1 * scale), WHITE)
	badge.Transparency = 1
	emojiOn(badge, Enum.NormalId.Front, "💖")
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

local SHELF_PLUSHIES: { (parent: Instance, at: CFrame, index: number) -> () } = {
	function(parent, at)
		teddy(parent, at, Color3.fromRGB(205, 150, 105), 1)
	end,
	function(parent, at, index)
		miniPackage(parent, at, PLUSH_COLORS[index % #PLUSH_COLORS + 1])
	end,
	function(parent, at, index)
		yarnBall(parent, at * CFrame.new(-0.6, 0, 0), 2, PLUSH_COLORS[index % #PLUSH_COLORS + 1])
	end,
	function(parent, at, index)
		teddy(parent, at, PLUSH_COLORS[index % #PLUSH_COLORS + 1], 0.9)
	end,
	function(parent, at, index)
		miniPackage(parent, at, PLUSH_COLORS[(index + 2) % #PLUSH_COLORS + 1])
	end,
}

local function shelfPlushie(parent: Instance, at: CFrame, index: number)
	SHELF_PLUSHIES[(index - 1) % #SHELF_PLUSHIES + 1](parent, at, index)
end

-- An embroidery hoop on a wall (`face`: its middle, -Z into the room): a wooden ring
-- round a disc of fabric with a stitched picture.
local function hoop(parent: Instance, face: CFrame, diameter: number, cloth: Color3, emoji: string)
	local ring = makeDecor(parent, "HoopRing", Vector3.new(0.6, diameter, diameter), face * CFrame.new(0, 0, -0.3) * CFrame.Angles(0, math.pi / 2, 0), WOOD, Enum.Material.Wood)
	ring.Shape = Enum.PartType.Cylinder
	local fabric = makeDecor(parent, "HoopCloth", Vector3.new(0.7, diameter - 0.9, diameter - 0.9), face * CFrame.new(0, 0, -0.3) * CFrame.Angles(0, math.pi / 2, 0), cloth, Enum.Material.Fabric)
	fabric.Shape = Enum.PartType.Cylinder
	makeDecor(parent, "HoopClasp", Vector3.new(1, 1.2, 0.8), face * CFrame.new(0, diameter / 2 + 0.3, -0.3), Color3.fromRGB(205, 210, 220), Enum.Material.Metal)
	wallEmoji(parent, face * CFrame.new(0, 0, -0.75), diameter * 0.6, emoji)
end

-- A giant sewing button on a wall (`face`: its middle, -Z into the room).
local function sewingButton(parent: Instance, face: CFrame, diameter: number, color: Color3)
	local function disc(name: string, size: number, depth: number, out: number, at: CFrame, tint: Color3)
		local part = makeDecor(parent, name, Vector3.new(depth, size, size), at * CFrame.new(0, 0, -out - depth / 2) * CFrame.Angles(0, math.pi / 2, 0), tint)
		part.Shape = Enum.PartType.Cylinder
	end
	disc("ButtonRim", diameter, 0.8, 0, face, color)
	disc("ButtonFace", diameter * 0.75, 0.2, 0.75, face, color:Lerp(Color3.new(0, 0, 0), 0.12))
	for _, offset in { Vector2.new(-1, -1), Vector2.new(-1, 1), Vector2.new(1, -1), Vector2.new(1, 1) } do
		disc("ButtonHole", diameter * 0.13, 0.2, 0.8, face * CFrame.new(offset.X * diameter * 0.13, offset.Y * diameter * 0.13, 0), INK)
	end
end

-- A patchwork quilt hung on a wall from a wooden rod (`face`: its middle, -Z into the
-- room), a big heart stitched in the middle.
local function quilt(parent: Instance, face: CFrame, columns: number, rows: number, tile: number)
	local width, height = columns * tile, rows * tile
	local hanger = roller(parent, "QuiltRod", 0.7, width + 3, face * CFrame.new(0, height / 2 + 0.9, -0.7), WOOD)
	hanger.Material = Enum.Material.Wood
	for _, x in { -1, 1 } do
		ball(parent, "QuiltRodEnd", 1.3, face * CFrame.new(x * (width / 2 + 1.6), height / 2 + 0.9, -0.7), PLUSH_COLORS[1])
	end
	makeDecor(parent, "QuiltBorder", Vector3.new(width + 1.2, height + 1.2, 0.3), face * CFrame.new(0, 0, -0.25), WHITE, Enum.Material.Fabric)
	for column = 1, columns do
		for row = 1, rows do
			local color = PLUSH_COLORS[(column + row * 2) % #PLUSH_COLORS + 1]
			makeDecor(parent, "QuiltPatch", Vector3.new(tile - 0.2, tile - 0.2, 0.3), face * CFrame.new(-width / 2 + (column - 0.5) * tile, -height / 2 + (row - 0.5) * tile, -0.5), color, Enum.Material.Fabric)
		end
	end
	wallEmoji(parent, face * CFrame.new(0, 0, -0.75), math.min(width, height) * 0.7, "💖")
end

-- A patchwork rug down a walkway (centered on `x`, from `fromZ` to `toZ`).
local function quiltRug(parent: Instance, floor: CFrame, x: number, fromZ: number, toZ: number)
	local tile = 5
	local rows = math.floor((toZ - fromZ) / tile)
	makeDecor(parent, "RugBorder", Vector3.new(tile * 2 + 0.8, 0.08, rows * tile + 0.8), floor * CFrame.new(x, 0.04, fromZ + rows * tile / 2), WHITE, Enum.Material.Fabric)
	for row = 0, rows - 1 do
		for column = 0, 1 do
			makeDecor(parent, "RugPatch", Vector3.new(tile - 0.25, 0.12, tile - 0.25), floor * CFrame.new(x + (column - 0.5) * tile, 0.06, fromZ + (row + 0.5) * tile), PLUSH_COLORS[(row + column * 3) % #PLUSH_COLORS + 1], Enum.Material.Fabric)
		end
	end
end

-- A puffy cloud lamp hanging from the ceiling (`at`: the point on the ceiling), two
-- glowing stars dangling under it.
local function cloudLamp(parent: Instance, at: CFrame, drop: number)
	makeDecor(parent, "CloudCord", Vector3.new(0.12, drop, 0.12), at * CFrame.new(0, -drop / 2, 0), WHITE)
	local cloud = at * CFrame.new(0, -drop - 1.2, 0)
	for _, puffSpot in { { 0, 0, 0, 3.6 }, { -2, -0.4, 0, 2.8 }, { 2.1, -0.3, 0.2, 3 }, { 0.6, 1, -0.3, 2.6 }, { -0.8, -0.5, 1, 2.4 }, { 0.4, -0.6, -1.1, 2.4 } } do
		ball(parent, "Cloud", puffSpot[4], cloud * CFrame.new(puffSpot[1], puffSpot[2], puffSpot[3]), WHITE, Enum.Material.Fabric).CastShadow = false
	end
	for _, x in { -1.3, 1.3 } do
		makeDecor(parent, "CloudString", Vector3.new(0.08, 1.6, 0.08), cloud * CFrame.new(x, -2.2, 0), WHITE)
		star(parent, cloud * CFrame.new(x, -3.3, 0), 1, Color3.fromRGB(255, 230, 120), Enum.Material.Neon)
	end
end

-- A basket of yarn with knitting needles stuck in it (`at`: its foot).
local function yarnBasket(parent: Instance, at: CFrame)
	cylinder(parent, "Basket", 6.4, 3, at, WOOD, Enum.Material.Wood)
	cylinder(parent, "BasketRim", 6.8, 0.6, at * CFrame.new(0, 2.7, 0), Color3.fromRGB(200, 145, 95), Enum.Material.Wood)
	for index, spot in { Vector3.new(-1.3, 3.2, 0.4), Vector3.new(1.2, 3.3, -0.3), Vector3.new(0, 3.9, 1.1) } do
		ball(parent, "BasketYarn", 2.8, at * CFrame.new(spot), PLUSH_COLORS[index], Enum.Material.Fabric)
	end
	for _, x in { -0.6, 0.6 } do
		local from = (at * CFrame.new(x * 1.5, 3.5, 0.6)).Position
		local to = (at * CFrame.new(x * 3.6, 9.5, 1.6)).Position
		rod(parent, "KnittingNeedle", 0.3, from, to, Color3.fromRGB(205, 210, 225), Enum.Material.Metal)
		ball(parent, "KnittingNeedleEnd", 0.8, CFrame.new(to), PLUSH_COLORS[1])
	end
end

local function buildPlushie(parent: Instance, floor: CFrame)
	-- the sign over the doorway, and pom-pom garlands round the walls by the ceiling
	neonSign(parent, wallFace(floor, { 0, 23.2, -59 }), Vector2.new(32, 5.4), "🧸 PLUSHIE ROOM 🧸", Color3.fromRGB(255, 110, 190))
	local function at(x: number, y: number, z: number): Vector3
		return (floor * CFrame.new(x, y, z)).Position
	end
	for _, x in { -67, 67 } do
		pomGarland(parent, at(x, 26, -56), at(x, 26, 0), PLUSH_COLORS, 1.6)
		pomGarland(parent, at(x, 26, 0), at(x, 26, 56), PLUSH_COLORS, 1.6)
	end
	for _, z in { -58, 57 } do
		pomGarland(parent, at(-66, 26, z), at(-20, 26, z), PLUSH_COLORS, 1.6)
		pomGarland(parent, at(20, 26, z), at(66, 26, z), PLUSH_COLORS, 1.6)
	end

	-- patchwork rugs down the walkways between the lines, cloud lamps and neon signs over them
	for index, x in { -19.6, 22.4 } do
		quiltRug(parent, floor, x, -25, 45)
		for _, z in { -32, -2, 30 } do
			cloudLamp(parent, floor * CFrame.new(x, 28, z), 3.5)
		end
		hangingSign(parent, floor * CFrame.new(x, 28, 14), 6, Vector2.new(11, 2.6), if index == 1 then "✂ HANDMADE ROT ✂" else "★ PLUSH FACTORY ★", PLUSH_COLORS[if index == 1 then 1 else 2])
	end

	-- the walls: a quilt on the back wall, hoops and giant buttons, plushie shelves
	quilt(parent, wallFace(floor, { 0, 16, 58 }), 6, 3, 4.6)
	for index, x in { -45, 45 } do
		sewingButton(parent, wallFace(floor, { x, 15, 58 }), 6, PLUSH_COLORS[index + 2])
	end
	for index, spot in { { -30, 14, -59 }, { -50, 15, -59 }, { 30, 14, -59 }, { 50, 15, -59 } } do
		hoop(parent, wallFace(floor, spot), 8, PLUSH_COLORS[index % #PLUSH_COLORS + 1]:Lerp(WHITE, 0.6), ({ "🌸", "🐰", "⭐", "🧁" })[index])
	end
	hoop(parent, wallFace(floor, { -68, 18, -50 }), 7, Color3.fromRGB(255, 235, 245), "🎀")
	hoop(parent, wallFace(floor, { -68, 16, 50 }), 7, Color3.fromRGB(235, 245, 255), "🧶")
	sewingButton(parent, wallFace(floor, { 68, 18, -50 }), 6.5, PLUSH_COLORS[1])
	hoop(parent, wallFace(floor, { 68, 17, 50 }), 7, Color3.fromRGB(255, 250, 230), "🌈")
	local shelfBoard, shelfTrim = Color3.fromRGB(255, 245, 250), Color3.fromRGB(240, 105, 170)
	wallShelf(parent, wallFace(floor, { -68, 0, 18 }), 18, shelfBoard, shelfTrim, shelfPlushie)
	wallShelf(parent, wallFace(floor, { 68, 0, -18 }), 18, shelfBoard, Color3.fromRGB(165, 125, 240), shelfPlushie)

	-- the big sewing machine on its table along the right wall, facing the room
	sewingMachine(parent, floor * CFrame.new(62.5, 0, 18) * CFrame.Angles(0, math.pi / 2, 0), 1)
	-- a stack of fabric bolts and a spool in the back corner
	for index, color in { PLUSH_COLORS[1], PLUSH_COLORS[3], PLUSH_COLORS[4] } do
		makeDecor(parent, "FabricBolt", Vector3.new(4, 1.8, 9), floor * CFrame.new(63, index * 1.8 - 0.9, 50) * CFrame.Angles(0, index * 0.12, 0), color, Enum.Material.Fabric)
	end
	-- by the doorway: a basket of yarn, a giant yarn ball, a spool and the pin cushion
	yarnBasket(parent, floor * CFrame.new(-22, 0, -52))
	yarnBall(parent, floor * CFrame.new(-31, 0, -54), 5, PLUSH_COLORS[3])
	yarnBall(parent, floor * CFrame.new(22, 0, -53), 6, PLUSH_COLORS[1])
	pinCushion(parent, floor * CFrame.new(31, 0, -53))
	spool(parent, floor * CFrame.new(-63, 0, 3), PLUSH_COLORS[2])
	yarnBall(parent, floor * CFrame.new(63, 0, 3), 5, PLUSH_COLORS[5])
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
