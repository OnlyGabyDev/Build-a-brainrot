--[[
	StationBuilder
	Builds a line's upgrade stations (GDD §6), Station1 and Station2: a themed machine
	per zone beside the belt, on its far side from the button path (-X), so it never
	hides the brainrot (the user: arches over the belt, in a jumble of colors and crammed
	together, buried it). The zone's special (Station3, over the belt's end) stays in
	TycoonManager.

	Each machine stands on a foot: a cabinet in its zone's colors with a glowing band, and
	a neon sign on two posts facing the path. ProductionVisuals finds by name: the sign
	(the part named after the station, Station1: the Line upgrades also hang their bulbs
	on it), its rims ({Key}Glow, {Key}GlowTop: they flash as a brainrot passes) and the
	machine's business end ({Key}Nozzle), where it sprays, pours or blasts from. Motion
	beyond that: Atmosphere's Spinners, and sparkling ParticleEmitters.

	Line space, as in TycoonManager: `spot` is on the floor at the belt's middle, the
	belt runs along Z (brainrots ride toward -Z) and its top (the deck) is `deck` above
	the floor.
]]

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TycoonItems = require(ReplicatedStorage.Shared.Config.TycoonItems)

local StationBuilder = {}

local STATION_X = -10.5 -- the machine's middle, from the belt's middle
local CABINET = Vector3.new(4.6, 6.4, 4.6)
local CABINET_TOP = 0.6 + CABINET.Y -- above the floor
local SIGN = Vector2.new(6.6, 2.2)
local SIGN_Y = 17 -- the sign's middle, above the floor
local SPARKLE_TEXTURE = "rbxasset://textures/particles/sparkles_main.dds"

local WHITE = Color3.new(1, 1, 1)
local CHROME_COLOR = Color3.fromRGB(215, 220, 235)
local GLASS_COLOR = Color3.fromRGB(220, 238, 255)
local SIGN_BACK = Color3.fromRGB(40, 28, 60)
-- the zones' machine colors (as in TycoonManager); solid gold is Metal, no reflectance
local GANTRY_COLOR = Color3.fromRGB(150, 90, 255)
local CLAW_COLOR = Color3.fromRGB(255, 200, 60)
local SEWING_COLOR = Color3.fromRGB(235, 65, 150)
local LAVENDER_COLOR = Color3.fromRGB(150, 95, 240)
local PLUSH_GOLD = Color3.fromRGB(255, 190, 40)
local CLAY_COLOR = Color3.fromRGB(225, 120, 75)
local CLAY_LIGHT_COLOR = Color3.fromRGB(245, 180, 125)
local CLAY_DARK_COLOR = Color3.fromRGB(150, 75, 50)
local CLAY_TEAL = Color3.fromRGB(60, 205, 195)
local VINYL_BLUE = Color3.fromRGB(70, 95, 235)
local VINYL_NAVY = Color3.fromRGB(35, 40, 110)
local VINYL_GOLD = Color3.fromRGB(255, 200, 50)
local VINYL_PINK = Color3.fromRGB(255, 80, 190)

type StationColors = { Body: Color3, Trim: Color3, Glow: Color3, Foot: Color3 }

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

-- The station's name in glowing neon letters on `panel`'s front face.
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
	label.Text = string.upper(text)
	label.Parent = gui
	local glow = Instance.new("UIStroke")
	glow.Thickness = 3
	glow.Color = color
	glow.Parent = label
end

local function makeRod(parent: Instance, name: string, from: Vector3, to: Vector3, thickness: number, color: Color3, material: Enum.Material?): Part
	return makeDecor(parent, name, Vector3.new(thickness, thickness, (to - from).Magnitude), CFrame.lookAt((from + to) / 2, to), color, material)
end

-- A cylinder lying along `at`'s look direction (its -Z), `length` long.
local function makeBarrel(parent: Instance, name: string, length: number, diameter: number, at: CFrame, color: Color3, material: Enum.Material?): Part
	local part = makeDecor(parent, name, Vector3.new(length, diameter, diameter), at * CFrame.Angles(0, math.pi / 2, 0), color, material)
	part.Shape = Enum.PartType.Cylinder
	return part
end

local function addSparkles(part: BasePart, color: Color3, rate: number, size: number?)
	local sparkles = Instance.new("ParticleEmitter")
	sparkles.Texture = SPARKLE_TEXTURE
	sparkles.Color = ColorSequence.new(color)
	sparkles.LightEmission = 0.8
	sparkles.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, size or 0.5), NumberSequenceKeypoint.new(1, 0) })
	sparkles.Lifetime = NumberRange.new(0.6, 1.2)
	sparkles.Rate = rate
	sparkles.Speed = NumberRange.new(0.5, 1.5)
	sparkles.SpreadAngle = Vector2.new(180, 180)
	sparkles.Parent = part
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

-- The parts every station shares; returns the middle of the cabinet's top.
local function buildStationBase(model: Model, spot: CFrame, item: TycoonItems.Item, colors: StationColors): CFrame
	local key = item.Key
	local base = spot * CFrame.new(STATION_X, 0, 0)
	makeColumn(model, key .. "Foot", CABINET.X + 1.8, 0, 0.6, base, colors.Foot)
	makePart(model, key .. "Cabinet", CABINET, base * CFrame.new(0, 0.6 + CABINET.Y / 2, 0), colors.Body)
	makeDecor(model, key .. "CabinetStripe", Vector3.new(CABINET.X + 0.1, 0.5, CABINET.Z + 0.1), base * CFrame.new(0, 2.6, 0), WHITE)
	makeDecor(model, key .. "CabinetBand", Vector3.new(CABINET.X + 0.12, 0.25, CABINET.Z + 0.12), base * CFrame.new(0, CABINET_TOP - 0.75, 0), colors.Glow, Enum.Material.Neon)
	makeDecor(model, key .. "CabinetTrim", Vector3.new(CABINET.X + 0.3, 0.5, CABINET.Z + 0.3), base * CFrame.new(0, CABINET_TOP - 0.25, 0), colors.Trim)
	-- the sign on two posts at the back, facing the button path
	local back = base * CFrame.new(-CABINET.X / 2 + 0.5, 0, 0)
	for _, z in { -1.9, 1.9 } do
		makeColumn(model, key .. "SignPost", 0.6, CABINET_TOP, SIGN_Y - SIGN.Y / 2, back * CFrame.new(0, 0, z), colors.Trim)
	end
	local at = (back * CFrame.new(0, SIGN_Y, 0)).Position
	local sign = makePart(model, key, Vector3.new(SIGN.X, SIGN.Y, 0.5), CFrame.lookAt(at, at + spot.RightVector), SIGN_BACK)
	sign.CanCollide = false
	neonLabel(sign, item.Name, colors.Glow)
	local rim = colors.Glow:Lerp(WHITE, 0.35)
	for name, y in { Glow = -1, GlowTop = 1 } do
		makeDecor(model, key .. name, Vector3.new(SIGN.X + 0.4, 0.3, 0.6), sign.CFrame * CFrame.new(0, y * (SIGN.Y / 2 + 0.15), 0), rim, Enum.Material.Neon)
	end
	return base * CFrame.new(0, CABINET_TOP, 0)
end

-- A robot arm on a cabinet (`top`: the middle of its top) holding a spray gun aimed at
-- the brainrot; the gun's glowing tip is the station's Nozzle.
local function buildSprayArm(model: Model, target: Vector3, top: CFrame, key: string, joint: Color3, gun: Color3, tip: Color3)
	makeColumn(model, key .. "Turret", 2.4, 0, 1, top, gun)
	local shoulder = top * CFrame.new(0, 1.8, 0)
	local elbow = top * CFrame.new(1, 6.4, 0)
	local wrist = top * CFrame.new(3.6, 5.2, 0)
	makeBall(model, key .. "Shoulder", 1.8, shoulder, joint)
	makeRod(model, key .. "UpperArm", shoulder.Position, elbow.Position, 0.75, CHROME_COLOR, Enum.Material.Metal)
	makeBall(model, key .. "Elbow", 1.4, elbow, joint)
	makeRod(model, key .. "Forearm", elbow.Position, wrist.Position, 0.6, CHROME_COLOR, Enum.Material.Metal)
	local aim = CFrame.lookAt(wrist.Position, target)
	makeDecor(model, key .. "Gun", Vector3.new(1.2, 1.4, 2.2), aim * CFrame.new(0, 0, -0.5), gun)
	local cup = makeDecor(model, key .. "GunCup", Vector3.new(1.2, 1.3, 1.3), aim * CFrame.new(0, 1.2, -0.2) * CFrame.Angles(0, 0, math.pi / 2), WHITE)
	cup.Shape = Enum.PartType.Cylinder
	makeBarrel(model, key .. "Nozzle", 1, 0.6, aim * CFrame.new(0, 0, -2.1), tip, Enum.Material.Neon)
end

-- Machines -----------------------------------------------------------------------

-- Toy Workshop: the Paint Booth is a robot arm with a spray gun, an exhaust fan and its
-- paint cans; the Glitter Blaster a glitter cannon with a hopper of glitter sparkling on
-- top. Purple with white and gold, warm yellow neon.
local TOY_STATION_COLORS: StationColors = {
	Body = GANTRY_COLOR,
	Trim = CLAW_COLOR,
	Glow = Color3.fromRGB(255, 220, 70),
	Foot = Color3.fromRGB(85, 45, 160),
}
local TOY_DARK = Color3.fromRGB(110, 60, 200)
local PAINT_CANS = { Color3.fromRGB(255, 110, 190), Color3.fromRGB(90, 200, 255), Color3.fromRGB(255, 215, 60) }

local function buildPaintBooth(model: Model, spot: CFrame, item: TycoonItems.Item, target: Vector3)
	local key = item.Key
	local top = buildStationBase(model, spot, item, TOY_STATION_COLORS)
	buildSprayArm(model, target, top, key, TOY_DARK, CLAW_COLOR, Color3.fromRGB(255, 120, 200))
	-- the booth's exhaust fan on the cabinet's face toward the belt
	local face = (spot * CFrame.new(STATION_X + CABINET.X / 2 + 0.2, 4.6, 0)).Position
	local hub = CFrame.lookAt(face, face + spot.RightVector) -- its -Z faces the belt
	makeBarrel(model, key .. "FanRim", 0.3, 3.4, hub, WHITE)
	local fan = makeSpinner(model, key .. "Fan", hub, 3)
	for blade = 0, 2 do
		makeDecor(fan, key .. "FanBlade", Vector3.new(0.6, 1.4, 0.12), hub * CFrame.Angles(0, 0, blade * math.pi * 2 / 3) * CFrame.new(0, 0.75, -0.15), CLAW_COLOR)
	end
	makeBall(fan, key .. "FanHub", 0.6, hub * CFrame.new(0, 0, -0.2), TOY_DARK)
	-- paint cans by its feet
	for index, z in { -1.6, 0.1, 1.7 } do
		local can = spot * CFrame.new(STATION_X + CABINET.X / 2 + 1.1, 0, z)
		local height = 2.1 - (index % 2) * 0.3
		makeColumn(model, key .. "PaintCan", 1.2, 0.6, height, can, if index == 2 then WHITE else GANTRY_COLOR)
		makeColumn(model, key .. "PaintCanPaint", 1.25, height - 0.5, height + 0.05, can, PAINT_CANS[index])
	end
end

local function buildGlitterBlaster(model: Model, spot: CFrame, item: TycoonItems.Item, target: Vector3)
	local key = item.Key
	local top = buildStationBase(model, spot, item, TOY_STATION_COLORS)
	makeColumn(model, key .. "Turret", 3.2, 0, 0.6, top, CLAW_COLOR)
	for _, z in { -1.45, 1.45 } do
		makeDecor(model, key .. "Cradle", Vector3.new(2.2, 2.6, 0.4), top * CFrame.new(0, 1.9, z), TOY_DARK)
	end
	-- the cannon, aimed up over the belt so the glitter rains down on the brainrot; its
	-- flared gold muzzle is the Nozzle
	local pivot = (top * CFrame.new(0, 2.2, 0)).Position
	local aim = CFrame.lookAt(pivot, target + Vector3.new(0, 5.5, 0))
	makeBarrel(model, key .. "Barrel", 5.4, 2.2, aim * CFrame.new(0, 0, -1.2), GANTRY_COLOR)
	for _, z in { -0.2, -2.3 } do
		makeBarrel(model, key .. "BarrelBand", 0.4, 2.4, aim * CFrame.new(0, 0, z), WHITE)
	end
	makeBarrel(model, key .. "BarrelCap", 0.5, 2.5, aim * CFrame.new(0, 0, 1.55), CLAW_COLOR)
	makeBarrel(model, key .. "Nozzle", 0.8, 3, aim * CFrame.new(0, 0, -4.1), CLAW_COLOR)
	makeBarrel(model, key .. "Bore", 0.2, 2, aim * CFrame.new(0, 0, -4.55), SIGN_BACK)
	-- the glitter hopper: a glass ball on a gold neck, glitter glowing and sparkling inside
	local hopper = top * CFrame.new(-0.9, 4.9, 0)
	makeColumn(model, key .. "HopperNeck", 1.2, 3.1, 3.5, top * CFrame.new(-0.9, 0, 0), CLAW_COLOR)
	local glass = makeBall(model, key .. "Hopper", 3.2, hopper, GLASS_COLOR, Enum.Material.Glass)
	glass.Transparency = 0.55
	local glitter = makeBall(model, key .. "Glitter", 2.3, hopper * CFrame.new(0, -0.3, 0), Color3.fromRGB(255, 225, 120), Enum.Material.Neon)
	glitter.Transparency = 0.35
	addSparkles(glitter, Color3.fromRGB(255, 240, 170), 8, 0.45)
	makeBall(model, key .. "HopperCap", 0.9, hopper * CFrame.new(0, 1.65, 0), CLAW_COLOR)
end

-- Plushie Sewing Room: the Dye Bath is a glass tank of glowing dye, bubbling, piped over
-- the belt's edge to a spout; the Sequin Shower a disco ball on an arm over the belt's
-- edge. Magenta with gold, cyan neon.
local PLUSHIE_STATION_COLORS: StationColors = {
	Body = SEWING_COLOR,
	Trim = PLUSH_GOLD,
	Glow = Color3.fromRGB(90, 220, 255),
	Foot = LAVENDER_COLOR,
}
local DYE_COLOR = Color3.fromRGB(150, 110, 255)

local function buildDyeBath(model: Model, spot: CFrame, item: TycoonItems.Item, target: Vector3)
	local key = item.Key
	local top = buildStationBase(model, spot, item, PLUSHIE_STATION_COLORS)
	makeColumn(model, key .. "TankFoot", 4.2, 0, 0.4, top, PLUSH_GOLD, Enum.Material.Metal)
	local tank = makeColumn(model, key .. "Tank", 3.8, 0.4, 5, top, GLASS_COLOR, Enum.Material.Glass)
	tank.Transparency = 0.6
	local dye = makeColumn(model, key .. "Dye", 3.3, 0.5, 3.9, top, DYE_COLOR, Enum.Material.Neon)
	dye.Transparency = 0.2
	addSparkles(dye, Color3.fromRGB(230, 220, 255), 5, 0.4) -- bubbles
	makeColumn(model, key .. "TankLid", 4.1, 5, 5.5, top, PLUSH_GOLD, Enum.Material.Metal)
	-- the pipe up from the lid and over the belt's edge, the spout pointing down
	local bend, over = top * CFrame.new(0, 8, 0), top * CFrame.new(5.8, 8, 0)
	makeRod(model, key .. "Pipe", (top * CFrame.new(0, 5.5, 0)).Position, bend.Position, 0.8, CHROME_COLOR, Enum.Material.Metal)
	makeRod(model, key .. "Pipe", bend.Position, over.Position, 0.8, CHROME_COLOR, Enum.Material.Metal)
	for _, joint in { bend, over } do
		makeBall(model, key .. "PipeJoint", 1.1, joint, PLUSH_GOLD, Enum.Material.Metal)
	end
	makeColumn(model, key .. "Spout", 1.3, 6.4, 7.6, top * CFrame.new(5.8, 0, 0), PLUSH_GOLD, Enum.Material.Metal)
	makeBall(model, key .. "Nozzle", 0.8, top * CFrame.new(5.8, 6.1, 0), DYE_COLOR, Enum.Material.Neon)
end

local function buildSequinShower(model: Model, spot: CFrame, item: TycoonItems.Item, target: Vector3)
	local key = item.Key
	local top = buildStationBase(model, spot, item, PLUSHIE_STATION_COLORS)
	makeColumn(model, key .. "Column", 1.4, 0, 8.6, top, LAVENDER_COLOR)
	for _, y in { 2.5, 6 } do
		makeColumn(model, key .. "ColumnStripe", 1.6, y, y + 0.5, top, WHITE)
	end
	local elbow, hand = top * CFrame.new(0, 8.2, 0), top * CFrame.new(5.6, 8.2, 0)
	makeRod(model, key .. "Arm", elbow.Position, hand.Position, 1.1, LAVENDER_COLOR)
	makeBall(model, key .. "ArmEnd", 1.3, hand, PLUSH_GOLD, Enum.Material.Metal)
	makeColumn(model, key .. "Nozzle", 0.3, 6.9, 7.6, top * CFrame.new(5.6, 0, 0), CHROME_COLOR, Enum.Material.Metal)
	-- the disco ball, spinning about its upright
	local center = top * CFrame.new(5.6, 5.4, 0)
	local ball = makeSpinner(model, key .. "DiscoBall", center * CFrame.Angles(math.pi / 2, 0, 0), 1.2)
	local disco = makeBall(ball, key .. "Disco", 3, center, Color3.fromRGB(225, 230, 245), Enum.Material.Foil)
	disco.Reflectance = 0.4
	for index = 0, 5 do
		local angle = index * math.pi / 3
		makeDecor(ball, key .. "DiscoTile", Vector3.new(0.6, 0.6, 0.1), center * CFrame.new(math.cos(angle) * 1.45, (index % 2 - 0.5) * 0.8, math.sin(angle) * 1.45) * CFrame.Angles(0, -angle - math.pi / 2, 0), Color3.fromRGB(255, 180, 230), Enum.Material.Neon)
	end
	addSparkles(disco, Color3.fromRGB(255, 200, 240), 3, 0.35)
end

-- Upgrade stations: the Color Squish (Station1) is a clay extruder, a hopper of clay
-- balls feeding a cream barrel that reaches over the belt, a crank turning on its side;
-- the Sparkle Glaze (Station2) a pot of glossy glaze whose spout arm drips over the
-- belt. Terracotta with cream, teal neon.
local CLAY_STATION_COLORS: StationColors = {
	Body = CLAY_COLOR,
	Trim = CLAY_LIGHT_COLOR,
	Glow = CLAY_TEAL,
	Foot = CLAY_DARK_COLOR,
}
local CLAY_BALLS = { Color3.fromRGB(255, 100, 120), Color3.fromRGB(255, 200, 60), Color3.fromRGB(90, 190, 255), Color3.fromRGB(130, 220, 110) }
local GLAZE_COLOR = Color3.fromRGB(240, 250, 255)

local function buildColorSquish(model: Model, spot: CFrame, item: TycoonItems.Item, target: Vector3)
	local key = item.Key
	local top = buildStationBase(model, spot, item, CLAY_STATION_COLORS)
	-- the hopper, heaped with clay
	makeDecor(model, key .. "Hopper", Vector3.new(3.2, 2.2, 3.4), top * CFrame.new(-0.5, 1.1, 0), CLAY_LIGHT_COLOR)
	makeDecor(model, key .. "HopperRim", Vector3.new(3.4, 0.4, 3.6), top * CFrame.new(-0.5, 2.3, 0), CLAY_TEAL)
	for index, offset in { Vector3.new(-1.1, 0, -0.8), Vector3.new(0.1, 0.2, 0.7), Vector3.new(-0.9, 0.3, 0.9), Vector3.new(0.2, 0, -0.9) } do
		makeBall(model, key .. "ClayBall", 1.2, top * CFrame.new(Vector3.new(-0.5, 2.9, 0) + offset), CLAY_BALLS[index], Enum.Material.Sand)
	end
	-- the extruder barrel over the belt's edge, its teal nozzle pointing down at the brainrot
	local from, to = (top * CFrame.new(1, 3.4, 0)).Position, (top * CFrame.new(4.9, 3.4, 0)).Position
	makeBarrel(model, key .. "Extruder", (to - from).Magnitude, 1.9, CFrame.lookAt((from + to) / 2, to), CLAY_LIGHT_COLOR)
	for _, x in { 2.2, 3.8 } do
		makeBarrel(model, key .. "ExtruderBand", 0.35, 2.1, CFrame.lookAt((top * CFrame.new(x, 3.4, 0)).Position, to), CLAY_TEAL)
	end
	makeDecor(model, key .. "ExtruderStand", Vector3.new(1, 2.4, 1.4), top * CFrame.new(1.4, 1.2, 0), CLAY_DARK_COLOR)
	makeColumn(model, key .. "Nozzle", 1.3, 1.7, 2.6, top * CFrame.new(5.1, 0, 0), CLAY_TEAL)
	makeColumn(model, key .. "NozzleTip", 0.8, 1.3, 1.7, top * CFrame.new(5.1, 0, 0), CLAY_TEAL, Enum.Material.Neon)
	-- a crank wheel turning on the cabinet's side
	local hub = spot * CFrame.new(STATION_X, 4.2, CABINET.Z / 2 + 0.3)
	local crank = makeSpinner(model, key .. "Crank", hub, 1.5)
	makeBarrel(crank, key .. "CrankWheel", 0.4, 3.2, hub, CLAY_TEAL)
	makeDecor(crank, key .. "CrankSpoke", Vector3.new(0.4, 2.8, 0.45), hub, WHITE)
	makeBall(crank, key .. "CrankKnob", 0.8, hub * CFrame.new(0, 1.3, 0.4), CLAY_LIGHT_COLOR)
end

local function buildSparkleGlaze(model: Model, spot: CFrame, item: TycoonItems.Item, target: Vector3)
	local key = item.Key
	local top = buildStationBase(model, spot, item, CLAY_STATION_COLORS)
	-- the pot of glaze, glistening
	local pot = top * CFrame.new(-0.4, 0, 0)
	makeColumn(model, key .. "Pot", 3.6, 0, 2.8, pot, CLAY_LIGHT_COLOR)
	makeColumn(model, key .. "PotStripe", 3.7, 1.1, 1.5, pot, CLAY_TEAL)
	makeColumn(model, key .. "PotRim", 4, 2.6, 3.1, pot, CLAY_TEAL)
	local glaze = makeColumn(model, key .. "Glaze", 3.2, 3, 3.15, pot, GLAZE_COLOR, Enum.Material.Glass)
	addSparkles(glaze, Color3.new(1, 1, 1), 5, 0.4)
	-- the spout arm up out of the pot and over the belt's edge, dripping
	local elbow, hand = top * CFrame.new(-0.4, 6.4, 0), top * CFrame.new(5.2, 5.6, 0)
	makeRod(model, key .. "Spout", (pot * CFrame.new(0, 3, 0)).Position, elbow.Position, 0.8, CLAY_LIGHT_COLOR)
	makeBall(model, key .. "SpoutJoint", 1.1, elbow, CLAY_TEAL)
	makeRod(model, key .. "Spout", elbow.Position, hand.Position, 0.8, CLAY_LIGHT_COLOR)
	makeColumn(model, key .. "SpoutMouth", 1.2, 4.9, 5.7, top * CFrame.new(5.2, 0, 0), CLAY_TEAL)
	local drop = makeBall(model, key .. "Nozzle", 0.8, top * CFrame.new(5.2, 4.5, 0), GLAZE_COLOR, Enum.Material.Glass)
	drop.Transparency = 0.2
	for index, x in { 2, 3.6 } do
		local armY = 6.4 - 0.8 * (x + 0.4) / 5.6 -- the arm's middle, over this spot
		local length = 0.9 + index * 0.3
		local drip = makeDecor(model, key .. "GlazeDrip", Vector3.new(0.35, length, 0.35), top * CFrame.new(x, armY - 0.3 - length / 2, 0), GLAZE_COLOR, Enum.Material.Glass)
		drip.Transparency = 0.25
	end
end

-- Upgrade stations: the Gloss Coat (Station1) is a white robot arm with a gloss gun and
-- chrome spray cans; the Gold Leaf (Station2) a gold roll turning between two arms, a
-- stack of gold leaf and a blower aimed at the brainrot. Royal blue with gold, hot-pink
-- neon.
local VINYL_STATION_COLORS: StationColors = {
	Body = VINYL_BLUE,
	Trim = VINYL_GOLD,
	Glow = VINYL_PINK,
	Foot = VINYL_NAVY,
}

local function buildGlossCoat(model: Model, spot: CFrame, item: TycoonItems.Item, target: Vector3)
	local key = item.Key
	local top = buildStationBase(model, spot, item, VINYL_STATION_COLORS)
	buildSprayArm(model, target, top, key, VINYL_NAVY, WHITE, VINYL_PINK)
	for _, z in { -1.3, 1.3 } do
		local can = top * CFrame.new(1.5, 0, z * 1.15)
		makeColumn(model, key .. "SprayCan", 1, 0, 1.8, can, CHROME_COLOR, Enum.Material.Metal)
		makeColumn(model, key .. "SprayCanCap", 0.8, 1.8, 2.3, can, VINYL_PINK)
	end
end

local function buildGoldLeaf(model: Model, spot: CFrame, item: TycoonItems.Item, target: Vector3)
	local key = item.Key
	local top = buildStationBase(model, spot, item, VINYL_STATION_COLORS)
	-- the gold roll between two navy arms, turning
	local axle = top * CFrame.new(-0.6, 2.4, 0)
	for _, z in { -1.9, 1.9 } do
		makeDecor(model, key .. "RollArm", Vector3.new(1, 3, 0.4), top * CFrame.new(-0.6, 1.5, z), VINYL_NAVY)
	end
	local roll = makeSpinner(model, key .. "Roll", axle, 1.2)
	makeBarrel(roll, key .. "RollDrum", 3.4, 2.6, axle, VINYL_GOLD, Enum.Material.Metal)
	for _, z in { -1, 1 } do
		makeDecor(roll, key .. "RollStripe", Vector3.new(0.3, 2.7, 0.3), axle * CFrame.new(0, 0, z), WHITE)
	end
	-- a stack of gold leaf at the front edge
	for index = 0, 3 do
		makeDecor(model, key .. "GoldLeaf", Vector3.new(1.8, 0.12, 1.8), top * CFrame.new(1.4, 0.1 + index * 0.15, -1.2) * CFrame.Angles(0, index * 0.3, 0), VINYL_GOLD)
	end
	-- the blower: a navy box on a post with a flared gold mouth aimed at the brainrot
	makeColumn(model, key .. "BlowerPost", 0.7, 0, 4.4, top * CFrame.new(1.6, 0, 1.2), VINYL_NAVY)
	local mouth = (top * CFrame.new(1.6, 5, 1.2)).Position
	local aim = CFrame.lookAt(mouth, target + Vector3.new(0, 1, 0))
	makeDecor(model, key .. "Blower", Vector3.new(1.6, 1.6, 2.2), aim * CFrame.new(0, 0, 0.4), VINYL_NAVY)
	makeBarrel(model, key .. "Nozzle", 0.9, 2, aim * CFrame.new(0, 0, -1.1), VINYL_GOLD, Enum.Material.Metal)
	makeBarrel(model, key .. "NozzleGlow", 0.15, 1.5, aim * CFrame.new(0, 0, -1.6), VINYL_PINK, Enum.Material.Neon)
end

type Builder = (model: Model, spot: CFrame, item: TycoonItems.Item, target: Vector3) -> ()
local BUILDERS: { [string]: { [string]: Builder } } = {
	ToyWorkshop = { Station1 = buildPaintBooth, Station2 = buildGlitterBlaster },
	PlushieRoom = { Station1 = buildDyeBath, Station2 = buildSequinShower },
	ClayStudio = { Station1 = buildColorSquish, Station2 = buildSparkleGlaze },
	VinylCollectibles = { Station1 = buildGlossCoat, Station2 = buildGoldLeaf },
}

-- Builds `item` (a Station1 or Station2) into its line's `model`, at `spot` (on the
-- floor at the belt's middle) on a belt whose top is `deck` above the floor. `reach`:
-- the machine's middle this far from `spot` (out on its -X side) instead of a belt's
-- -STATION_X (a turntable's ride is narrower than a belt's frame).
function StationBuilder.Build(model: Model, spot: CFrame, item: TycoonItems.Item, deck: number, reach: number?)
	local builders = BUILDERS[item.Zone] or BUILDERS.ToyWorkshop
	local target = (spot * CFrame.new(0, deck + 4.5, 0)).Position
	local at = if reach then spot * CFrame.new(-reach - STATION_X, 0, 0) else spot
	builders[item.Key](model, at, item, target)
end

return StationBuilder
