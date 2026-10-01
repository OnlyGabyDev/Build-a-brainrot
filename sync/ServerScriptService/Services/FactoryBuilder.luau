--[[
	FactoryBuilder
	Builds each plot's factory building around its lines (GDD §10): one room per zone,
	each behind the last, with walls, windows and a roof. The entrance faces the hub
	under the owner's sign, and a doorway leads into each back room, closed by a shutter
	until its zone unlocks. TycoonManager furnishes the rooms.

	Plot space: origin on the ground at the plot's center, -Z (front) faces the hub.
	Each room's roof is a Model tagged "Roof", pivoted at the room's floor center with a
	RoomSize attribute: TycoonFX fades it while you're inside, watching from above.
]]

local CollectionService = game:GetService("CollectionService")

local FactoryBuilder = {}

FactoryBuilder.RoomSize = Vector3.new(140, 1, 120) -- one zone's floor
FactoryBuilder.FloorTop = 1

local ROOM_SIZE = FactoryBuilder.RoomSize
local FLOOR_TOP = FactoryBuilder.FloorTop
local WALL_HEIGHT = 28
local WALL_THICKNESS = 2
local BAND_TOP = 8 -- the walls' lower band, up to the window sills
local WINDOW_TOP = 21
local WINDOW_WIDTH = 14
local SIDE_WINDOWS = { -36, -12, 12, 36 } -- along a room's side walls, from its center
local END_WINDOWS = { -56, -34, 34, 56 } -- along the front and back walls
local ENTRANCE_SIZE = Vector2.new(26, 18)
local DOORWAY_SIZE = Vector2.new(24, 18) -- into a back room
local TOOTH_DEPTH = 24 -- the sawtooth roof's teeth
local TOOTH_HEIGHT = 7

local WHITE = Color3.new(1, 1, 1)
local GLASS_COLOR = Color3.fromRGB(200, 235, 255)
local CHIMNEY_COLOR = Color3.fromRGB(225, 120, 95)
local CAP_COLOR = Color3.fromRGB(70, 60, 80)
local SIGN_TEXT_COLOR = Color3.fromRGB(120, 70, 200)

type Style = {
	Title: string?, -- the sign over the doorway into a back room
	SignColor: Color3?,
	Floor: Color3,
	FloorMaterial: Enum.Material,
	Wall: Color3?, -- nil: the plot's own color
	WallMaterial: Enum.Material,
	Band: Color3,
	BandMaterial: Enum.Material,
	Trim: Color3,
	Accent: Color3?, -- corner pillars and the roof's teeth; nil: the plot's color, vivid
	Ceiling: Color3,
}

local STYLES: { [string]: Style } = {
	ToyWorkshop = {
		Floor = Color3.fromRGB(236, 200, 150),
		FloorMaterial = Enum.Material.WoodPlanks,
		WallMaterial = Enum.Material.SmoothPlastic,
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
		WallMaterial = Enum.Material.Fabric,
		Band = Color3.fromRGB(255, 170, 205),
		BandMaterial = Enum.Material.Fabric,
		Trim = Color3.fromRGB(255, 120, 190),
		Accent = Color3.fromRGB(255, 150, 200),
		Ceiling = Color3.fromRGB(255, 236, 246),
	},
}

-- The plot's pastel color, punched up for accents.
local function vivid(color: Color3): Color3
	local hue, saturation, value = color:ToHSV()
	return Color3.fromHSV(hue, math.max(saturation, 0.6), math.max(value, 0.95))
end

export type Room = {
	ZoneId: string,
	Z: number, -- the room's center along the plot's Z
}

export type Doorway = {
	Label: TextLabel, -- the sign over it
	Title: string,
	Shutter: BasePart,
}

export type Factory = {
	SignLabel: TextLabel, -- the owner's sign over the entrance
	Doorways: { [string]: Doorway }, -- by zone id
}

type Opening = {
	X: number, -- center along the wall
	Width: number,
	Bottom: number,
	Top: number,
	Window: boolean?,
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

-- A sign with text on its front face (-Z of `cframe`), in a colored border.
local function makeSign(parent: Instance, name: string, size: Vector3, cframe: CFrame, color: Color3, border: Color3, text: string): TextLabel
	makeDecor(parent, name .. "Border", size + Vector3.new(2, 2, -0.4), cframe * CFrame.new(0, 0, 0.2), border)
	local sign = makePart(parent, name, size, cframe, WHITE)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.LightInfluence = 0
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

-- Walls ----------------------------------------------------------------------------

-- Frames reach a little into their opening (FRAME_INSET), so their inner faces cover
-- the wall's cut edges instead of flickering against them.
local FRAME_INSET = 0.3
local FRAME_DEPTH = WALL_THICKNESS + 0.8

-- A window: tinted glass in a chunky frame with a cross of bars, like a toy house.
local function buildWindow(parent: Instance, center: CFrame, size: Vector2, trim: Color3)
	local glass = makePart(parent, "Window", Vector3.new(size.X, size.Y, 0.4), center, GLASS_COLOR, Enum.Material.Glass)
	glass.Transparency = 0.6
	local offset = 0.5 - FRAME_INSET -- a 1-stud frame's center past the opening's edge
	for _, side in { -1, 1 } do
		makeDecor(parent, "WindowFrame", Vector3.new(size.X + 1.4, 1, FRAME_DEPTH), center * CFrame.new(0, side * (size.Y / 2 + offset), 0), trim)
		makeDecor(parent, "WindowFrame", Vector3.new(1, size.Y, FRAME_DEPTH), center * CFrame.new(side * (size.X / 2 + offset), 0, 0), trim)
	end
	makeDecor(parent, "WindowBar", Vector3.new(0.5, size.Y, 0.8), center, trim)
	makeDecor(parent, "WindowBar", Vector3.new(size.X, 0.5, 0.8), center, trim)
end

-- A door frame around an opening that starts at the floor.
local function buildDoorFrame(parent: Instance, base: CFrame, size: Vector2, trim: Color3)
	local offset = 0.7 - FRAME_INSET -- a 1.4-stud frame's center past the opening's edge
	for _, side in { -1, 1 } do
		makeDecor(parent, "DoorFrame", Vector3.new(1.4, size.Y, FRAME_DEPTH), base * CFrame.new(side * (size.X / 2 + offset), size.Y / 2, 0), trim)
	end
	makeDecor(parent, "DoorFrame", Vector3.new(size.X + 2.2, 1.4, FRAME_DEPTH), base * CFrame.new(0, size.Y + offset, 0), trim)
end

-- A wall along the X axis of `base` (on the floor, at the wall's middle), `length`
-- long, with `openings` (sorted by X) cut into it. Each slab is split at the band, so
-- the lower band and the upper wall can differ. A `thickness` other than the walls'
-- builds half of a two-faced wall, and leaves the frames to the caller.
local function buildWall(parent: Instance, base: CFrame, length: number, openings: { Opening }, style: Style, wallColor: Color3, thickness: number?)
	local depth = thickness or WALL_THICKNESS
	local framed = thickness == nil
	local function slab(x0: number, x1: number, y0: number, y1: number)
		if x1 - x0 < 0.01 or y1 - y0 < 0.01 then
			return
		end
		local function piece(bottom: number, top: number, color: Color3, material: Enum.Material)
			local size = Vector3.new(x1 - x0, top - bottom, depth)
			makePart(parent, "Wall", size, base * CFrame.new((x0 + x1) / 2, (bottom + top) / 2, 0), color, material)
		end
		if y0 < BAND_TOP then
			piece(y0, math.min(y1, BAND_TOP), style.Band, style.BandMaterial)
		end
		if y1 > BAND_TOP then
			piece(math.max(y0, BAND_TOP), y1, wallColor, style.WallMaterial)
		end
	end

	local x = -length / 2
	for _, opening in openings do
		local left, right = opening.X - opening.Width / 2, opening.X + opening.Width / 2
		slab(x, left, 0, WALL_HEIGHT)
		slab(left, right, 0, opening.Bottom)
		slab(left, right, opening.Top, WALL_HEIGHT)
		local size = Vector2.new(opening.Width, opening.Top - opening.Bottom)
		if framed and opening.Window then
			buildWindow(parent, base * CFrame.new(opening.X, (opening.Bottom + opening.Top) / 2, 0), size, style.Trim)
		elseif framed and opening.Bottom == 0 then
			buildDoorFrame(parent, base * CFrame.new(opening.X, 0, 0), size, style.Trim)
		end
		x = right
	end
	slab(x, length / 2, 0, WALL_HEIGHT)
end

local function windows(spots: { number }): { Opening }
	local openings = {}
	for _, x in spots do
		table.insert(openings, { X = x, Width = WINDOW_WIDTH, Bottom = BAND_TOP, Top = WINDOW_TOP, Window = true })
	end
	return openings
end

local function withDoor(openings: { Opening }, size: Vector2): { Opening }
	table.insert(openings, { X = 0, Width = size.X, Bottom = 0, Top = size.Y })
	table.sort(openings, function(a, b)
		return a.X < b.X
	end)
	return openings
end

-- Outside --------------------------------------------------------------------------

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

-- A brick chimney beside the building, puffing pastel smoke.
local function buildChimney(parent: Instance, base: CFrame)
	local height = FLOOR_TOP + WALL_HEIGHT + 14
	makePart(parent, "Chimney", Vector3.new(7, height, 7), base * CFrame.new(0, height / 2, 0), CHIMNEY_COLOR, Enum.Material.Brick)
	local cap = makePart(parent, "ChimneyCap", Vector3.new(8.6, 1.4, 8.6), base * CFrame.new(0, height + 0.7, 0), CAP_COLOR)

	local attachment = Instance.new("Attachment")
	attachment.Position = Vector3.new(0, 1, 0)
	attachment.Parent = cap
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
	smoke.Parent = attachment
end

-- Rooms ----------------------------------------------------------------------------

-- The room's ceiling, topped with a sawtooth roof (the classic factory skyline) whose
-- rows of windows face the hub. None of it casts shadows, so the rooms stay sunny.
local function buildRoof(parent: Instance, zoneId: string, center: CFrame, ceiling: Color3, color: Color3)
	local roof = Instance.new("Model")
	roof.Name = `{zoneId}Roof`
	roof.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	local slab = makeDecor(roof, "Ceiling", Vector3.new(ROOM_SIZE.X, 1.5, ROOM_SIZE.Z), center * CFrame.new(0, WALL_HEIGHT + 0.75, 0), ceiling)
	slab.CastShadow = false

	local top = WALL_HEIGHT + 1.5
	local width = ROOM_SIZE.X - 6 -- inside the parapet
	for index = 1, math.floor(ROOM_SIZE.Z / TOOTH_DEPTH) do
		local z = -ROOM_SIZE.Z / 2 + (index - 0.5) * TOOTH_DEPTH
		local tooth = Instance.new("WedgePart")
		tooth.Name = "RoofTooth"
		tooth.Anchored = true
		tooth.CanCollide = false
		tooth.CanTouch = false
		tooth.CanQuery = false
		tooth.CastShadow = false
		tooth.Size = Vector3.new(width, TOOTH_HEIGHT, TOOTH_DEPTH)
		-- A wedge rises toward its +Z; turned around, its tall face looks at the hub.
		tooth.CFrame = center * CFrame.new(0, top + TOOTH_HEIGHT / 2, z) * CFrame.Angles(0, math.pi, 0)
		tooth.Color = color
		tooth.Material = Enum.Material.SmoothPlastic
		tooth.Parent = roof
		local glass = makeDecor(roof, "RoofWindow", Vector3.new(width - 6, TOOTH_HEIGHT - 2.4, 0.3), center * CFrame.new(0, top + TOOTH_HEIGHT / 2 - 0.2, z - TOOTH_DEPTH / 2 - 0.15), GLASS_COLOR)
		glass.CastShadow = false
	end

	roof.WorldPivot = center
	roof:SetAttribute("RoomSize", Vector3.new(ROOM_SIZE.X, WALL_HEIGHT, ROOM_SIZE.Z))
	CollectionService:AddTag(roof, "Roof")
	roof.Parent = parent
end

-- A low rim around the top of a room's walls, so the building keeps its outline while
-- its roof fades.
local function buildParapet(parent: Instance, center: CFrame, trim: Color3, front: boolean, back: boolean)
	local height, depth = 2.5, WALL_THICKNESS + 0.4
	local y = WALL_HEIGHT + height / 2
	for _, side in { -1, 1 } do
		local x = side * (ROOM_SIZE.X / 2 - WALL_THICKNESS / 2)
		makeDecor(parent, "Parapet", Vector3.new(depth, height, ROOM_SIZE.Z), center * CFrame.new(x, y, 0), trim)
	end
	for _, edge in { { front, -1 }, { back, 1 } } do
		if edge[1] then
			local z = edge[2] * (ROOM_SIZE.Z / 2 - WALL_THICKNESS / 2)
			makeDecor(parent, "Parapet", Vector3.new(ROOM_SIZE.X, height, depth), center * CFrame.new(0, y, z), trim)
		end
	end
end

-- Chunky colored pillars on both ends of a wall that runs along X at `z` (room space),
-- framing the building's corners.
local function buildPillars(parent: Instance, center: CFrame, z: number, color: Color3)
	local x = ROOM_SIZE.X / 2 - WALL_THICKNESS / 2
	local height = WALL_HEIGHT + 4
	for _, side in { -1, 1 } do
		makeDecor(parent, "Pillar", Vector3.new(3.4, height, 3.4), center * CFrame.new(side * x, height / 2, z), color)
	end
end

local function styleOf(room: Room): Style
	return STYLES[room.ZoneId] or STYLES.ToyWorkshop
end

-- `previous` is the room in front of this one (nil for the first).
local function buildRoom(model: Model, cframe: CFrame, room: Room, previous: Room?, isLast: boolean, color: Color3, factory: Factory)
	local style = styleOf(room)
	local wallColor = style.Wall or color
	local accent = style.Accent or vivid(color)
	local center = cframe * CFrame.new(0, FLOOR_TOP, room.Z) -- on the floor
	local halfX, halfZ = ROOM_SIZE.X / 2, ROOM_SIZE.Z / 2
	local inner = ROOM_SIZE.X - WALL_THICKNESS * 2 -- the end walls fit between the side walls

	local floor = makePart(model, `{room.ZoneId}Floor`, ROOM_SIZE, center * CFrame.new(0, -ROOM_SIZE.Y / 2, 0), style.Floor, style.FloorMaterial)
	floor.TopSurface = Enum.SurfaceType.Smooth

	for _, side in { -1, 1 } do
		local base = center * CFrame.new(side * (halfX - WALL_THICKNESS / 2), 0, 0) * CFrame.Angles(0, math.pi / 2, 0)
		buildWall(model, base, ROOM_SIZE.Z, windows(SIDE_WINDOWS), style, wallColor)
	end

	if not previous then
		-- The entrance, facing the hub, under an awning and the owner's sign.
		local front = center * CFrame.new(0, 0, -halfZ + WALL_THICKNESS / 2)
		buildWall(model, front, inner, withDoor(windows(END_WINDOWS), ENTRANCE_SIZE), style, wallColor)
		buildPillars(model, center, -halfZ + WALL_THICKNESS / 2, accent)
		local face = front * CFrame.new(0, 0, -WALL_THICKNESS / 2)
		buildAwning(model, face * CFrame.new(0, ENTRANCE_SIZE.Y + 1, 0), ENTRANCE_SIZE.X + 4, accent)
		factory.SignLabel = makeSign(model, "Sign", Vector3.new(44, 7, 1), face * CFrame.new(0, WALL_HEIGHT - 4, -0.55), SIGN_TEXT_COLOR, accent, "Empty Plot")
		buildChimney(model, cframe * CFrame.new(halfX + 5, 0, room.Z + 30))
	else
		-- The doorway from the room in front, with the room's sign over it and a
		-- shutter that stays down until the zone unlocks. Each half of the wall wears
		-- its own room's style.
		local divider = center * CFrame.new(0, 0, -halfZ)
		local half = WALL_THICKNESS / 2
		local front = styleOf(previous)
		buildWall(model, divider * CFrame.new(0, 0, -half / 2), inner, withDoor({}, DOORWAY_SIZE), front, front.Wall or color, half)
		buildWall(model, divider * CFrame.new(0, 0, half / 2), inner, withDoor({}, DOORWAY_SIZE), style, wallColor, half)
		buildDoorFrame(model, divider, DOORWAY_SIZE, front.Trim)
		buildPillars(model, center, -halfZ, accent)
		local face = divider * CFrame.new(0, 0, -WALL_THICKNESS / 2)
		local title = style.Title or room.ZoneId
		local label = makeSign(model, `{room.ZoneId}Sign`, Vector3.new(34, 6.5, 1), face * CFrame.new(0, WALL_HEIGHT - 4.5, -0.55), style.SignColor or SIGN_TEXT_COLOR, accent, title)
		local shutter = makePart(model, `{room.ZoneId}Shutter`, Vector3.new(DOORWAY_SIZE.X, DOORWAY_SIZE.Y, 0.8), divider * CFrame.new(0, DOORWAY_SIZE.Y / 2, 0), style.Band, Enum.Material.DiamondPlate)
		local gui = Instance.new("SurfaceGui")
		gui.Name = "Lock"
		gui.Face = Enum.NormalId.Front
		gui.LightInfluence = 0
		gui.Parent = shutter
		local lock = Instance.new("TextLabel")
		lock.Size = UDim2.fromScale(1, 0.5)
		lock.Position = UDim2.fromScale(0, 0.25)
		lock.BackgroundTransparency = 1
		lock.TextScaled = true
		lock.Font = Enum.Font.FredokaOne
		lock.Text = "🔒"
		lock.Parent = gui
		factory.Doorways[room.ZoneId] = { Label = label, Title = title, Shutter = shutter }
	end

	if isLast then
		local back = center * CFrame.new(0, 0, halfZ - WALL_THICKNESS / 2)
		buildWall(model, back, inner, windows(END_WINDOWS), style, wallColor)
		buildPillars(model, center, halfZ - WALL_THICKNESS / 2, accent)
	end

	buildParapet(model, center, style.Trim, true, isLast)
	buildRoof(model, room.ZoneId, center, style.Ceiling, accent)
end

-- API ------------------------------------------------------------------------------

-- Builds the factory for a plot at `cframe`, with `rooms` in order from the front.
-- `color` is the plot's own pastel color (the Toy Workshop's walls); its vivid version
-- colors the accents (awning, pillars, roof).
function FactoryBuilder.Build(model: Model, cframe: CFrame, color: Color3, rooms: { Room }): Factory
	local factory: Factory = { SignLabel = (nil :: any) :: TextLabel, Doorways = {} }
	for index, room in rooms do
		buildRoom(model, cframe, room, rooms[index - 1], index == #rooms, color, factory)
	end
	return factory
end

-- Shows a back room's sign with `lock` under it and closes its shutter, or opens the
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
