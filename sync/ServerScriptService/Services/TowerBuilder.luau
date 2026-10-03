--[[
	TowerBuilder
	Builds what's special about Vinyl Collectibles' line (LineLayouts "Tower", GDD §6): no
	belt; a pad inside the open capsule where the figure is put together; in front of it a
	glass display tower full of gacha capsules (some turning slowly round inside), and a
	glossy white ramp with a gold curb and a glowing pink edge (RampGlow) spiralling up
	round it from the capsule's front to the lit display shelf on top (the Ship, where the
	glass case drops over the figure); the Holo Sticker cannon (the special) out front,
	aimed at the shelf; the turbo stripes up the ramp (Speed); and the Belt Boost track's
	look (display lights round the tower, chrome turning gold, holographic strips, chasing
	lights). The gachas, the capsule, the suction arm and the spray robots are
	TycoonManager's; the stations StationBuilder's.

	ProductionVisuals finds by name: Ship (the shelf), Station3 (the cannon's head),
	Station3Glow and Station3Nozzle (where the sticker flies from). The Belt Boost track
	recolors RampGlow and RampCurb.

	Line space, as in TycoonManager: `origin` on the floor at the pad, -Z toward the
	room's front.
]]

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LineLayouts = require(ReplicatedStorage.Shared.LineLayouts)
local TycoonItems = require(ReplicatedStorage.Shared.Config.TycoonItems)

local TowerBuilder = {}

local DECK = LineLayouts.Deck
local TOWER = LineLayouts.TowerSettings
local PAD_RADIUS = 9.3 -- inside the capsule's glass (10)
local SEGMENT = 2.5 -- the ramp is built in pieces about this long
local SLAB = 0.8 -- the ramp's thickness
local PANES = 16

local WHITE = Color3.new(1, 1, 1)
local CHROME_COLOR = Color3.fromRGB(215, 220, 235)
local SIGN_BACK = Color3.fromRGB(40, 28, 60)
-- Vinyl Collectibles' colors (as in TycoonManager): royal blue and navy, gold, hot-pink neon
local VINYL_BLUE = Color3.fromRGB(70, 95, 235)
local VINYL_NAVY = Color3.fromRGB(35, 40, 110)
local VINYL_GOLD = Color3.fromRGB(255, 200, 50)
local VINYL_PINK = Color3.fromRGB(255, 80, 190)
local RAMP_COLOR = Color3.fromRGB(245, 247, 255)
local TOWER_GLASS = Color3.fromRGB(205, 225, 255)
local TURBO_COLOR = Color3.fromRGB(255, 230, 60) -- the Speed upgrades' glow, as on a belt
local CAPSULE_COLORS = {
	Color3.fromRGB(255, 90, 140),
	Color3.fromRGB(90, 190, 255),
	Color3.fromRGB(255, 210, 60),
	Color3.fromRGB(130, 220, 110),
	Color3.fromRGB(190, 130, 255),
}
local HOLO_COLORS = { Color3.fromRGB(255, 120, 220), Color3.fromRGB(110, 230, 255), Color3.fromRGB(255, 230, 90), Color3.fromRGB(150, 255, 170) }

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

-- Just for looks: no collisions, no touches.
local function makeDecor(parent: Instance, name: string, size: Vector3, cframe: CFrame, color: Color3, material: Enum.Material?): Part
	local part = makePart(parent, name, size, cframe, color, material)
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	return part
end

-- An upright cylinder from `bottom` to `top` over `base`.
local function makeColumn(parent: Instance, name: string, diameter: number, bottom: number, top: number, base: CFrame, color: Color3, material: Enum.Material?): Part
	local part = makeDecor(parent, name, Vector3.new(top - bottom, diameter, diameter), base * CFrame.new(0, (bottom + top) / 2, 0) * CFrame.Angles(0, 0, math.pi / 2), color, material)
	part.Shape = Enum.PartType.Cylinder
	return part
end

local function makeBall(parent: Instance, name: string, diameter: number, cframe: CFrame, color: Color3, material: Enum.Material?): Part
	local part = makeDecor(parent, name, Vector3.one * diameter, cframe, color, material)
	part.Shape = Enum.PartType.Ball
	return part
end

local function makeRod(parent: Instance, name: string, from: Vector3, to: Vector3, thickness: number, color: Color3, material: Enum.Material?): Part
	return makeDecor(parent, name, Vector3.new(thickness, thickness, (to - from).Magnitude), CFrame.lookAt((from + to) / 2, to), color, material)
end

-- A cylinder lying along `at`'s Z.
local function makeBarrel(parent: Instance, name: string, length: number, diameter: number, at: CFrame, color: Color3, material: Enum.Material?): Part
	local part = makeDecor(parent, name, Vector3.new(length, diameter, diameter), at * CFrame.Angles(0, math.pi / 2, 0), color, material)
	part.Shape = Enum.PartType.Cylinder
	return part
end

-- `text` in glowing neon letters on `panel`'s front face.
local function neonLabel(panel: BasePart, text: string, color: Color3)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 30
	gui.LightInfluence = 0
	gui.Brightness = 2.5 -- past 1, so it blooms like neon
	gui.Parent = panel
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(0.9, 0.78)
	label.Position = UDim2.fromScale(0.05, 0.11)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = color:Lerp(WHITE, 0.7)
	label.Text = text
	label.Parent = gui
	local glow = Instance.new("UIStroke")
	glow.Thickness = 3
	glow.Color = color
	glow.Parent = label
end

-- An empty Model turning about `pivot`'s Z (Atmosphere's Spinners), for parts to go in.
local function makeSpinner(model: Model, name: string, pivot: CFrame, speed: number): Model
	local spinner = Instance.new("Model")
	spinner.Name = name
	spinner.WorldPivot = pivot
	spinner:SetAttribute("Speed", speed)
	CollectionService:AddTag(spinner, "Spinner")
	spinner.Parent = model
	return spinner
end

-- Calls `build(frame, length, index, onHelix)` for each piece of the ramp, from where it
-- leaves the pad to its end: `frame` is the piece's middle on the ride line at the
-- ramp's top (world), facing the way it climbs (its +X: out from the tower).
local function rampPieces(origin: CFrame, layout: LineLayouts.Layout, build: (frame: CFrame, length: number, index: number, onHelix: boolean) -> ())
	local curve = LineLayouts.RailCurve(layout) :: LineLayouts.Curve
	local stops = layout.Stops :: { [string]: number }
	local helix = curve.Knots[stops.Helix]
	-- from the pad's edge
	local from = 0
	while from < curve.Length do
		local point = LineLayouts.At(curve, from)
		if Vector3.new(point.X, 0, point.Z).Magnitude >= PAD_RADIUS then
			break
		end
		from += 0.25
	end
	local count = math.max(1, math.round((curve.Length - from) / SEGMENT))
	local step = (curve.Length - from) / count
	for index = 1, count do
		local a = LineLayouts.At(curve, from + (index - 1) * step)
		local b = LineLayouts.At(curve, from + index * step)
		local frame = origin * CFrame.lookAt((a + b) / 2, b)
		build(frame, (b - a).Magnitude, index, from + (index - 0.5) * step >= helix)
	end
end

-- The line ----------------------------------------------------------------------

-- The pad inside the capsule: navy with a white stripe and a pink glow, a pale blue top
-- dotted with gold stars round its edge.
local function buildPad(model: Model, origin: CFrame)
	local pad = makeColumn(model, "Pad", PAD_RADIUS * 2, 0, DECK - 0.3, origin, VINYL_NAVY)
	pad.CanCollide = true
	pad.CanQuery = true
	makeColumn(model, "PadStripe", PAD_RADIUS * 2 + 0.1, 1, 1.4, origin, WHITE)
	makeColumn(model, "PadGlow", PAD_RADIUS * 2 + 0.12, 2.1, 2.3, origin, VINYL_PINK, Enum.Material.Neon).CastShadow = false
	makeColumn(model, "PadTop", PAD_RADIUS * 2 - 0.3, DECK - 0.3, DECK, origin, Color3.fromRGB(150, 185, 255))
	for index = 0, 11 do
		local angle = index / 12 * math.pi * 2
		local spot = origin * CFrame.new(math.sin(angle) * (PAD_RADIUS - 1.2), DECK + 0.05, math.cos(angle) * (PAD_RADIUS - 1.2)) * CFrame.Angles(0, angle, 0)
		for _, turn in { 0, math.pi / 4 } do
			makeDecor(model, "PadStar", Vector3.new(0.8, 0.1, 0.8), spot * CFrame.Angles(0, turn, 0), VINYL_GOLD)
		end
	end
end

-- The ramp: a glossy white deck, a navy face on its outer side with a glowing pink strip
-- (RampGlow), a chrome curb along the outer edge (RampCurb: gold with the Belt Boost),
-- a navy lip along the inner one, chrome posts under it.
local function buildRamp(model: Model, origin: CFrame, layout: LineLayouts.Layout)
	local width = TOWER.Width
	rampPieces(origin, layout, function(frame, length, index, onHelix)
		local deck = makePart(model, "Ramp", Vector3.new(width, SLAB, length + 0.2), frame * CFrame.new(0, -SLAB / 2, 0), RAMP_COLOR)
		deck.CanQuery = true
		makeDecor(model, "RampFace", Vector3.new(0.3, 1.4, length + 0.2), frame * CFrame.new(width / 2 + 0.1, -0.6, 0), VINYL_NAVY)
		makeDecor(model, "RampGlow", Vector3.new(0.12, 0.3, length + 0.2), frame * CFrame.new(width / 2 + 0.3, -0.6, 0), VINYL_PINK, Enum.Material.Neon).CastShadow = false
		makeDecor(model, "RampCurb", Vector3.new(0.45, 0.5, length + 0.2), frame * CFrame.new(width / 2 - 0.2, 0.25, 0), CHROME_COLOR, Enum.Material.Metal)
		makeDecor(model, "RampLip", Vector3.new(0.4, 0.35, length + 0.2), frame * CFrame.new(-width / 2 + 0.2, 0.17, 0), if onHelix then VINYL_NAVY else VINYL_GOLD)
		-- posts under its outer edge (and both edges off the tower)
		if index % 3 == 1 then
			local sides: { number } = if onHelix then { 1 } else { -1, 1 }
			for _, side in sides do
				local top = frame * CFrame.new(side * (width / 2 - 0.6), -SLAB, 0)
				local foot = Vector3.new(top.X, origin.Y, top.Z)
				makeColumn(model, "RampPost", 0.7, 0, top.Y - origin.Y, CFrame.new(foot) * origin.Rotation, CHROME_COLOR, Enum.Material.Metal)
				makeColumn(model, "RampPostFoot", 1.4, 0, 0.3, CFrame.new(foot) * origin.Rotation, VINYL_NAVY)
			end
		end
	end)
end

-- The glass display tower: a navy plinth, glass walls framed in gold, a heap of gacha
-- capsules inside and more of them turning slowly round in a spiral, and the lit display
-- shelf on top (the Ship).
local function buildTower(model: Model, origin: CFrame)
	local center = origin * CFrame.new(TOWER.Center)
	local radius = TOWER.Radius
	local top = TOWER.Top
	local plinth = makeColumn(model, "TowerPlinth", radius * 2 + 1.6, 0, 1.2, center, VINYL_NAVY)
	plinth.CanCollide = true
	makeColumn(model, "TowerPlinthTrim", radius * 2 + 1.8, 1, 1.4, center, VINYL_GOLD, Enum.Material.Metal)
	makeColumn(model, "TowerPlinthGlow", radius * 2 + 1.9, 0.45, 0.65, center, VINYL_PINK, Enum.Material.Neon).CastShadow = false
	-- the glass (not Glass: it would hide the capsules behind it), framed in gold
	local width = 2 * radius * math.tan(math.pi / PANES) + 0.05
	for index = 0, PANES - 1 do
		local angle = (index + 0.5) / PANES * math.pi * 2
		local pane = makePart(model, "TowerGlass", Vector3.new(width, top - 2.6, 0.2), center * CFrame.Angles(0, angle, 0) * CFrame.new(0, (1.4 + top - 1.2) / 2, -radius), TOWER_GLASS)
		pane.Transparency = 0.62
		pane.CastShadow = false
		if index % 2 == 0 then
			makeColumn(model, "TowerFrame", 0.35, 1.4, top - 1.2, center * CFrame.Angles(0, index / PANES * math.pi * 2, 0) * CFrame.new(0, 0, -radius - 0.1), VINYL_GOLD, Enum.Material.Metal)
		end
	end
	makeColumn(model, "TowerCore", 0.5, 1.4, top - 1.2, center, VINYL_PINK, Enum.Material.Neon).CastShadow = false
	-- a heap of capsules at the bottom...
	local random = Random.new(7)
	for index = 1, 12 do
		local angle = random:NextNumber(0, math.pi * 2)
		local out = random:NextNumber(1, radius - 1.3)
		makeBall(model, "TowerCapsule", 1.6, center * CFrame.new(math.cos(angle) * out, 2.1 + (index % 3) * 0.8, math.sin(angle) * out), CAPSULE_COLORS[index % #CAPSULE_COLORS + 1])
	end
	-- ...and more of them turning round the core, in a spiral up the tower
	local turning = makeSpinner(model, "TowerCapsules", center * CFrame.new(0, top / 2, 0) * CFrame.Angles(math.pi / 2, 0, 0), 0.5)
	for index = 0, 11 do
		local angle = index * 1.05
		makeBall(turning, "TowerCapsule", 1.4, center * CFrame.new(math.cos(angle) * 3.4, 4.2 + index * 0.52, math.sin(angle) * 3.4), CAPSULE_COLORS[index % #CAPSULE_COLORS + 1])
	end
	-- the top band and the shelf, lit from underneath its rim and from inside
	makeColumn(model, "TowerBand", radius * 2 + 0.4, top - 1.2, top - 0.4, center, VINYL_NAVY)
	local shelf = makeColumn(model, "Ship", radius * 2 + 0.4, top - 0.4, top, center, RAMP_COLOR)
	shelf.CanCollide = true
	shelf.CanQuery = true
	shelf:SetAttribute("Shelf", true) -- (ProductionVisuals: the glass case drops a short way up here, and shrinks away)
	makeColumn(model, "ShelfRim", radius * 2 + 0.9, top - 1, top - 0.15, center, VINYL_GOLD, Enum.Material.Metal)
	makeColumn(model, "ShelfGlow", radius * 2 + 1.1, top - 0.8, top - 0.55, center, VINYL_PINK, Enum.Material.Neon).CastShadow = false
	local light = Instance.new("SpotLight")
	light.Face = Enum.NormalId.Right -- the cylinder's X: up
	light.Angle = 100
	light.Range = 14
	light.Brightness = 2
	light.Color = Color3.fromRGB(255, 240, 225)
	light.Shadows = false
	light.Parent = shelf
end

-- The pad, the ramp and the tower.
function TowerBuilder.BuildLine(model: Model, origin: CFrame, layout: LineLayouts.Layout)
	buildPad(model, origin)
	buildRamp(model, origin, layout)
	buildTower(model, origin)
end

-- Speed upgrades: a glowing turbo stripe up the ramp, one each (the inner side, then the
-- outer).
function TowerBuilder.BuildSpeed(model: Model, origin: CFrame, layout: LineLayouts.Layout, item: TycoonItems.Item)
	local x = if item.Key == "Speed1" then -1.6 else 1.6
	rampPieces(origin, layout, function(frame, length)
		makeDecor(model, item.Key, Vector3.new(0.45, 0.06, length + 0.15), frame * CFrame.new(x, 0.03, 0), TURBO_COLOR, Enum.Material.Neon).CastShadow = false
	end)
end

-- Station3, the Holo Sticker (the special): a cannon out front on a royal blue column
-- (`spot`: on the floor under it, -Z toward the tower), its gold barrel aimed at the
-- shelf; a roll of holographic star stickers turning on top, and a neon sign on its
-- outer side.
function TowerBuilder.BuildSticker(model: Model, spot: CFrame, item: TycoonItems.Item)
	local key = item.Key
	makeColumn(model, key .. "Foot", 5.4, 0, 0.8, spot, VINYL_NAVY)
	makeColumn(model, key .. "FootRing", 5.6, 0.6, 1, spot, VINYL_GOLD, Enum.Material.Metal)
	local column = makeColumn(model, key .. "Column", 2.8, 0.8, 11, spot, VINYL_BLUE)
	column.CanCollide = true
	for _, y in { 3, 7.4 } do
		makeColumn(model, key .. "ColumnStripe", 3.1, y, y + 0.6, spot, VINYL_GOLD)
	end
	-- the head: the machine's top (Station3), a glowing band under it
	makePart(model, key, Vector3.new(4.6, 2.6, 4.6), spot * CFrame.new(0, 12.3, 0), VINYL_BLUE)
	makeDecor(model, key .. "Stripe", Vector3.new(4.7, 0.5, 4.7), spot * CFrame.new(0, 12.5, 0), WHITE)
	makeDecor(model, key .. "Glow", Vector3.new(4.9, 0.3, 4.9), spot * CFrame.new(0, 11.1, 0), VINYL_PINK, Enum.Material.Neon).CastShadow = false
	makeDecor(model, key .. "Cap", Vector3.new(4.9, 0.4, 4.9), spot * CFrame.new(0, 13.75, 0), VINYL_GOLD, Enum.Material.Metal)
	-- the sticker roll on top, turning about its axle (along X)
	local center = spot * CFrame.new(0, 15.3, 0)
	local roll = makeSpinner(model, key .. "Roll", center * CFrame.Angles(0, math.pi / 2, 0), 1.5)
	local drum = makeDecor(roll, key .. "RollDrum", Vector3.new(3.8, 2.6, 2.6), center, WHITE)
	drum.Shape = Enum.PartType.Cylinder
	for index = 0, 5 do
		local angle = index / 6 * math.pi * 2
		makeDecor(roll, key .. "RollStar", Vector3.new(0.5, 0.8, 0.8), center * CFrame.new(-1.2 + (index % 3) * 1.2, math.cos(angle) * 1.3, math.sin(angle) * 1.3) * CFrame.Angles(angle, 0, 0), HOLO_COLORS[index % #HOLO_COLORS + 1], Enum.Material.Neon)
	end
	for _, x in { -2, 2 } do
		makeDecor(roll, key .. "RollRim", Vector3.new(0.3, 3.2, 3.2), center * CFrame.new(x, 0, 0), VINYL_GOLD).Shape = Enum.PartType.Cylinder
	end
	for _, x in { -2.4, 2.4 } do
		makeDecor(model, key .. "RollArm", Vector3.new(0.4, 2.4, 1), spot * CFrame.new(x, 14.6, 0), VINYL_NAVY)
	end
	-- the barrel, aimed at the shelf; its glowing muzzle is the Nozzle
	local from = (spot * CFrame.new(0, 12.3, -2.3)).Position
	local aim = CFrame.lookAt(from, (spot * CFrame.new(0, TOWER.Top + 5, -TOWER.Cannon)).Position) -- the figure on the shelf
	makeBarrel(model, key .. "Barrel", 1.8, 1.7, aim * CFrame.new(0, 0, -0.6), VINYL_GOLD, Enum.Material.Metal)
	makeBarrel(model, key .. "BarrelBand", 0.3, 1.9, aim * CFrame.new(0, 0, -0.9), VINYL_PINK, Enum.Material.Neon)
	makeBarrel(model, key .. "Nozzle", 0.4, 1.3, aim * CFrame.new(0, 0, -1.6), HOLO_COLORS[2], Enum.Material.Neon)
	-- its name in neon on the column's outer side, toward the room
	local sign = makeDecor(model, key .. "Sign", Vector3.new(6.4, 1.8, 0.3), spot * CFrame.new(0, 6, 1.7) * CFrame.Angles(0, math.pi, 0), SIGN_BACK)
	neonLabel(sign, "⭐ " .. string.upper(item.Name), VINYL_PINK)
	for _, y in { -1.05, 1.05 } do
		makeDecor(model, key .. "SignTube", Vector3.new(6.7, 0.2, 0.35), sign.CFrame * CFrame.new(0, y, 0), VINYL_PINK:Lerp(WHITE, 0.3), Enum.Material.Neon).CastShadow = false
	end
end

-- The Belt Boost track's look on a tower: the ramp's glowing edge takes the tier's color;
-- display lights on chrome stands gather round the tower aimed at the ramp (more each
-- level); from tier 2 the curb and the stands turn gold; from tier 3 holographic strips
-- run up the tower's frame and sparkles drift over the shelf; at the top tier chasing
-- lights run up the ramp's edge.
export type TrackLook = {
	Tier: number,
	Color: Color3,
	Gold: Color3,
	Bulb: (parent: Instance, at: CFrame, size: number, tier: number, index: number) -> Part,
	Sparkles: (parent: Instance, at: CFrame, size: Vector3, rate: number) -> (),
}

-- where round the tower the lights stand, in the order they come (degrees: clear of the
-- stations, the cannon, the way in and the buttons)
local LIGHT_DEGREES = { 95, 275, 155, 205, 300, 80 }
local LIGHT_RADIUS = 15.5

-- A display light: a lamp on a stand, aimed at the ramp at its angle.
local function displayLight(model: Model, origin: CFrame, degrees: number, color: Color3, gold: Color3, tier: number)
	local foot = origin * LineLayouts.TowerSpot(degrees, LIGHT_RADIUS)
	local height = 13
	local stand = if tier >= 2 then gold else CHROME_COLOR
	for index = 0, 2 do
		local spread = (index + 0.5) / 3 * math.pi * 2
		local toe = (foot * CFrame.new(math.cos(spread) * 1.3, 0, math.sin(spread) * 1.3)).Position
		makeRod(model, "LightLeg", toe, (foot * CFrame.new(0, 2.6, 0)).Position, 0.25, VINYL_NAVY)
	end
	makeColumn(model, "LightPole", 0.35, 2.6, height, foot, stand, Enum.Material.Metal)
	local aimAt = (origin * LineLayouts.TowerSpot(degrees)).Position + Vector3.new(0, LineLayouts.TowerHeight(degrees) + 4, 0)
	local lamp = CFrame.lookAt((foot * CFrame.new(0, height + 0.8, 0)).Position, aimAt)
	makeDecor(model, "LightHead", Vector3.new(1.8, 1.8, 2.4), lamp, if tier >= 2 then gold else VINYL_NAVY, if tier >= 2 then Enum.Material.Metal else nil)
	local face = makeDecor(model, "LightGlow", Vector3.new(1.4, 1.4, 0.1), lamp * CFrame.new(0, 0, -1.25), color:Lerp(WHITE, 0.55), Enum.Material.Neon)
	face.CastShadow = false
	local light = Instance.new("SpotLight")
	light.Face = Enum.NormalId.Front
	light.Angle = 50
	light.Range = 18
	light.Brightness = 1
	light.Color = color:Lerp(WHITE, 0.6)
	light.Shadows = false
	light.Parent = face
end

function TowerBuilder.BuildTrackLook(model: Model, line: Model, origin: CFrame, layout: LineLayouts.Layout, level: number, look: TrackLook)
	for _, child in line:GetChildren() do
		if child:IsA("BasePart") then
			if child.Name == "RampGlow" then
				child.Color = look.Color
			elseif child.Name == "RampCurb" and look.Tier >= 2 then
				child.Color = look.Gold
			end
		end
	end
	local lights = math.min(1 + math.ceil(level * 0.5), #LIGHT_DEGREES)
	for index = 1, lights do
		displayLight(model, origin, LIGHT_DEGREES[index], look.Color, look.Gold, look.Tier)
	end
	if look.Tier >= 3 then
		local center = origin * CFrame.new(TOWER.Center)
		for index = 0, PANES / 2 - 1 do
			local strip = center * CFrame.Angles(0, (index * 2 + 1) / PANES * math.pi * 2, 0) * CFrame.new(0, (1.4 + TOWER.Top - 1.2) / 2, -TOWER.Radius - 0.15)
			makeDecor(model, "HoloStrip", Vector3.new(0.3, TOWER.Top - 2.6, 0.12), strip, HOLO_COLORS[index % #HOLO_COLORS + 1], Enum.Material.Neon).CastShadow = false
		end
		look.Sparkles(model, center * CFrame.new(0, TOWER.Top + 3, 0), Vector3.new(TOWER.Radius * 2, 1, TOWER.Radius * 2), 4 + look.Tier * 2)
	end
	if look.Tier >= 4 then
		rampPieces(origin, layout, function(frame, _, index)
			look.Bulb(model, frame * CFrame.new(TOWER.Width / 2 - 0.2, 0.75, 0), 0.5, look.Tier, index)
		end)
	end
end

return TowerBuilder
