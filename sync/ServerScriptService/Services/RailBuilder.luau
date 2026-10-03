--[[
	RailBuilder
	Builds what's special about the Plushie room's line (LineLayouts "Rail", GDD §6): no
	belt; a cushy drum inside the capsule (the Pad) that the knitting machines knit the
	parts onto; a rail winding near the ceiling, from a hook garage beside the capsule out
	through its open front to another past the delivery; the stations at its stops (the
	Dye Bath's vat the brainrot is dipped into, the Sequin Shower's disco ball it swings
	under, the Bow Tier); the fluff jar it's lowered into; the turbo threads along the
	rail (Speed); and the Belt Boost track's look (glowing thread and little gold hooks
	along the rail). The knitting machines and the capsule are TycoonManager's.

	ProductionVisuals finds by name: Pad, Station1Dye (the paint in the Dye Bath's bucket:
	its top is the surface the hook dunks the brainrot under) and Station1Paint (the
	band and the drips outside, recolored with it), Station1/2/3 (the signs and the Bow Tier's head) and their Glow rims, Station2Nozzle
	(under the disco ball), Station3Nozzle (the ribbon spool the bow flies from), Ship
	(the jar's floor). The Belt Boost track recolors the RailGlow strips.

	Line space, as in TycoonManager: `origin` on the floor at the pad, -Z the way the
	brainrot leaves; a station's `spot` is on the floor under its stop on the rail.
]]

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LineLayouts = require(ReplicatedStorage.Shared.LineLayouts)
local RibbonBow = require(ReplicatedStorage.Shared.RibbonBow)
local TycoonItems = require(ReplicatedStorage.Shared.Config.TycoonItems)

local FactoryBuilder = require(script.Parent.FactoryBuilder)

local RailBuilder = {}

local DECK = LineLayouts.Deck
local CEILING = FactoryBuilder.CeilingHeight
local SEGMENT = 2 -- the rail is built in straight pieces about this long
local PAD_RADIUS = 9.3 -- inside the capsule's glass (10)
local SIGN = Vector2.new(6.6, 2.2)
local SIGN_Y = 17 -- the stations' signs, above the floor: a backdrop behind the hanging brainrot
local SPARKLE_TEXTURE = "rbxasset://textures/particles/sparkles_main.dds"

local WHITE = Color3.new(1, 1, 1)
local CHROME_COLOR = Color3.fromRGB(215, 220, 235)
local GLASS_COLOR = Color3.fromRGB(220, 238, 255)
local SIGN_BACK = Color3.fromRGB(40, 28, 60)
-- the Plushie room's machines (as in TycoonManager): magenta, violet, gold, cyan neon
local SEWING_COLOR = Color3.fromRGB(235, 65, 150)
local LAVENDER_COLOR = Color3.fromRGB(150, 95, 240)
local PLUSH_GOLD = Color3.fromRGB(255, 190, 40) -- solid gold: Metal, no reflectance
local GLOW_COLOR = Color3.fromRGB(90, 220, 255)
local CUSHION_COLOR = Color3.fromRGB(255, 175, 220)
local TURBO_COLOR = Color3.fromRGB(255, 230, 60) -- the Speed upgrades' glow, as on a belt (pink vanished on the rail's band)
local DYE_COLOR = Color3.fromRGB(140, 70, 255) -- (glossy paint, not neon: neon blooms to white)
local RAIL_COLOR = Color3.fromRGB(250, 248, 255) -- white, so it stands out against the pink room
local BOW_PINK = Color3.fromRGB(255, 80, 170)

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
	label.Text = string.upper(text)
	label.Parent = gui
	local glow = Instance.new("UIStroke")
	glow.Thickness = 3
	glow.Color = color
	glow.Parent = label
end

-- Calls `build(frame, length)` for each straight piece of the rail from `from` to `to`
-- (distances along it): `frame` is the piece's middle on the rail's center line (in the
-- world), looking the way the rail runs.
local function alongRail(origin: CFrame, curve: LineLayouts.Curve, from: number, to: number, build: (frame: CFrame, length: number) -> ())
	local count = math.max(1, math.ceil((to - from) / SEGMENT))
	for k = 0, count - 1 do
		local a = LineLayouts.At(curve, from + (to - from) * k / count)
		local b = LineLayouts.At(curve, from + (to - from) * (k + 1) / count)
		local start, finish = origin * a, origin * b
		build(CFrame.lookAt((start + finish) / 2, finish), (finish - start).Magnitude)
	end
end

-- A station's neon sign facing the button path (+X) at `at` (its middle), with its
-- glowing rims: the part is named after the station (`key`).
local function buildSign(model: Model, key: string, at: CFrame, text: string)
	local sign = makePart(model, key, Vector3.new(SIGN.X, SIGN.Y, 0.5), at * CFrame.Angles(0, -math.pi / 2, 0), SIGN_BACK)
	sign.CanCollide = false
	neonLabel(sign, text, GLOW_COLOR)
	local rim = GLOW_COLOR:Lerp(WHITE, 0.35)
	for name, y in { Glow = -1, GlowTop = 1 } do
		makeDecor(model, key .. name, Vector3.new(SIGN.X + 0.4, 0.3, 0.6), sign.CFrame * CFrame.new(0, y * (SIGN.Y / 2 + 0.15), 0), rim, Enum.Material.Neon)
	end
end

-- A little magenta control box on the floor at `base`, its sign up on two posts over it.
local function buildSignStand(model: Model, key: string, base: CFrame, text: string)
	makeColumn(model, key .. "StandFoot", 3.6, 0, 0.4, base, LAVENDER_COLOR)
	makePart(model, key .. "Stand", Vector3.new(2.4, 3, 3.2), base * CFrame.new(0, 1.9, 0), SEWING_COLOR)
	makeDecor(model, key .. "StandStripe", Vector3.new(2.5, 0.4, 3.3), base * CFrame.new(0, 1.6, 0), WHITE)
	makeDecor(model, key .. "StandTop", Vector3.new(2.7, 0.4, 3.5), base * CFrame.new(0, 3.6, 0), PLUSH_GOLD, Enum.Material.Metal)
	makeBall(model, key .. "StandLamp", 0.7, base * CFrame.new(0.9, 4.1, 1), GLOW_COLOR, Enum.Material.Neon)
	for _, z in { -1.9, 1.9 } do
		makeColumn(model, key .. "SignPost", 0.5, 3.8, SIGN_Y - SIGN.Y / 2, base * CFrame.new(0, 0, z), LAVENDER_COLOR)
	end
	buildSign(model, key, base * CFrame.new(0, SIGN_Y, 0), text)
end

-- The line ----------------------------------------------------------------------

-- The drum inside the capsule the brainrot is built on: magenta with white and gold
-- bands, a cushion on top ringed with stitches.
local function buildPad(model: Model, origin: CFrame)
	local pad = makeColumn(model, "Pad", PAD_RADIUS * 2, 0, DECK - 0.25, origin, SEWING_COLOR, Enum.Material.Fabric)
	pad.CanCollide = true
	pad.CanQuery = true
	makeColumn(model, "PadStripe", PAD_RADIUS * 2 + 0.1, 1.1, 1.5, origin, WHITE)
	makeColumn(model, "PadGlow", PAD_RADIUS * 2 + 0.12, 2.2, 2.4, origin, GLOW_COLOR, Enum.Material.Neon).CastShadow = false
	makeColumn(model, "PadTrim", PAD_RADIUS * 2 + 0.2, DECK - 0.75, DECK - 0.3, origin, PLUSH_GOLD, Enum.Material.Metal)
	makeColumn(model, "PadCushion", PAD_RADIUS * 2 - 0.4, DECK - 0.3, DECK, origin, CUSHION_COLOR, Enum.Material.Fabric)
	for k = 0, 23 do
		local angle = k / 24 * math.pi * 2
		makeDecor(model, "PadStitch", Vector3.new(0.25, 0.06, 1.1), origin * CFrame.Angles(0, angle, 0) * CFrame.new(0, DECK + 0.03, -(PAD_RADIUS - 1.1)) * CFrame.Angles(0, math.pi / 2, 0), WHITE, Enum.Material.Fabric)
	end
end

-- A hook garage round an end of the rail (`at`: the rail's end, `heading` the way the
-- rail runs out of it): the hooks come out of one and go into the other.
-- (`outward`: -1 at the start, where the hooks come out along `heading`; 1 at the end,
-- where `heading` runs on into it.)
local function buildGarage(model: Model, at: Vector3, heading: Vector3, outward: number)
	-- the box reaches 1.6 studs past the end and 3 along the rail, so a trolley parked
	-- at the end is out of sight; it stays level
	local flat = Vector3.new(heading.X, 0, heading.Z)
	local frame = CFrame.lookAt(at, at + (if flat.Magnitude > 1e-3 then flat.Unit else Vector3.zAxis)) * CFrame.new(0, -1.1, outward * 0.7)
	makePart(model, "HookGarage", Vector3.new(3.4, 6.4, 4.6), frame, SEWING_COLOR)
	makeDecor(model, "HookGarageStripe", Vector3.new(3.5, 0.4, 4.7), frame * CFrame.new(0, -2, 0), WHITE)
	makeDecor(model, "HookGarageTrim", Vector3.new(3.7, 0.45, 4.9), frame * CFrame.new(0, -3.1, 0), PLUSH_GOLD, Enum.Material.Metal)
	-- the dark opening the rail runs through, framed in neon
	local mouth = frame * CFrame.new(0, -0.3, outward * 2.31)
	makeDecor(model, "HookGarageMouth", Vector3.new(2.6, 5.2, 0.05), mouth, SIGN_BACK)
	for _, x in { -1.45, 1.45 } do
		makeDecor(model, "HookGarageGlow", Vector3.new(0.25, 5.4, 0.12), mouth * CFrame.new(x, 0, outward * 0.05), GLOW_COLOR, Enum.Material.Neon).CastShadow = false
	end
	makeDecor(model, "HookGarageGlow", Vector3.new(3.15, 0.25, 0.12), mouth * CFrame.new(0, 2.7, outward * 0.05), GLOW_COLOR, Enum.Material.Neon).CastShadow = false
end

local function buildRail(model: Model, origin: CFrame, curve: LineLayouts.Curve)
	-- the beam: chunky and white with a gold cap and a magenta band, a glowing strip
	-- under it
	alongRail(origin, curve, 0, curve.Length, function(frame, length)
		makeDecor(model, "RailBeam", Vector3.new(1.4, 1.4, length + 0.25), frame, RAIL_COLOR)
		makeDecor(model, "RailBand", Vector3.new(1.5, 0.35, length + 0.25), frame * CFrame.new(0, -0.15, 0), SEWING_COLOR)
		makeDecor(model, "RailCap", Vector3.new(1.6, 0.35, length + 0.25), frame * CFrame.new(0, 0.85, 0), PLUSH_GOLD, Enum.Material.Metal)
		makeDecor(model, "RailGlow", Vector3.new(0.7, 0.12, length + 0.2), frame * CFrame.new(0, -0.76, 0), GLOW_COLOR, Enum.Material.Neon).CastShadow = false
	end)
	-- chrome hangers up to the ceiling, clear of the garages
	local count = math.max(2, math.floor((curve.Length - 6) / 8.5))
	for k = 0, count do
		local point = origin * LineLayouts.At(curve, 3.5 + (curve.Length - 7) * k / count)
		local ceiling = Vector3.new(point.X, origin.Y + CEILING, point.Z)
		makeRod(model, "RailHanger", point + Vector3.new(0, 1, 0), ceiling, 0.35, CHROME_COLOR, Enum.Material.Metal)
		makeColumn(model, "RailHangerCollar", 1.4, CEILING - 0.3, CEILING, origin.Rotation + Vector3.new(point.X, origin.Y, point.Z), PLUSH_GOLD, Enum.Material.Metal)
	end
	for _, ending in { { 0, -1 }, { curve.Length, 1 } } do
		local at, heading = LineLayouts.At(curve, ending[1])
		buildGarage(model, origin * at, origin:VectorToWorldSpace(heading), ending[2])
	end
end

-- The drum in the capsule and the rail (the line's own parts besides the capsule and
-- its machines).
function RailBuilder.BuildLine(model: Model, origin: CFrame, layout: LineLayouts.Layout)
	buildPad(model, origin)
	buildRail(model, origin, LineLayouts.RailCurve(layout) :: LineLayouts.Curve)
end

-- The delivery: a glass jar on a cushy base, open at the top, a few fluff balls inside.
-- The hook lowers the brainrot in, fluff swirls round it and it sinks into the base.
local JAR_RADIUS = 6
local JAR_PANES = 16
local JAR_HEIGHT = 4 -- the glass, above the jar's floor (the deck): low, so the brainrot clears it coming in

function RailBuilder.BuildShip(model: Model, spot: CFrame)
	makeColumn(model, "JarFoot", JAR_RADIUS * 2 + 2, 0, 0.8, spot, LAVENDER_COLOR)
	local ship = makeColumn(model, "Ship", JAR_RADIUS * 2 + 0.6, 0.8, DECK, spot, SEWING_COLOR, Enum.Material.Fabric)
	ship.CanCollide = true
	ship.CanQuery = true
	makeColumn(model, "JarStripe", JAR_RADIUS * 2 + 0.7, 1.6, 2, spot, WHITE)
	makeColumn(model, "JarTrim", JAR_RADIUS * 2 + 1, DECK - 0.6, DECK - 0.05, spot, PLUSH_GOLD, Enum.Material.Metal)
	local paneWidth = 2 * JAR_RADIUS * math.tan(math.pi / JAR_PANES) + 0.1
	for index = 0, JAR_PANES - 1 do
		local face = spot * CFrame.Angles(0, index / JAR_PANES * math.pi * 2, 0)
		local pane = makeDecor(model, "JarGlass", Vector3.new(paneWidth, JAR_HEIGHT, 0.2), face * CFrame.new(0, DECK + JAR_HEIGHT / 2, -JAR_RADIUS), GLASS_COLOR, Enum.Material.Glass)
		pane.Transparency = 0.75
		pane.CastShadow = false
		pane.CanCollide = true
		makeDecor(model, "JarRim", Vector3.new(paneWidth + 0.1, 0.5, 0.6), face * CFrame.new(0, DECK + JAR_HEIGHT + 0.25, -JAR_RADIUS), PLUSH_GOLD, Enum.Material.Metal)
		makeDecor(model, "JarGlow", Vector3.new(paneWidth, 0.2, 0.12), face * CFrame.new(0, DECK + JAR_HEIGHT - 0.5, -JAR_RADIUS - 0.18), GLOW_COLOR, Enum.Material.Neon).CastShadow = false
		if index % 4 == 2 then
			makeColumn(model, "JarPost", 0.5, DECK, DECK + JAR_HEIGHT + 0.5, face * CFrame.new(0, 0, -JAR_RADIUS - 0.2), PLUSH_GOLD, Enum.Material.Metal)
		end
	end
	-- fluff waiting round the edge
	for index, angle in { 0.4, 1.5, 2.6, 3.9, 5.1 } do
		local size = 1.4 + (index % 3) * 0.3
		makeBall(model, "FluffBall", size, spot * CFrame.Angles(0, angle, 0) * CFrame.new(0, DECK + size / 2, -(JAR_RADIUS - 1.4)), if index % 2 == 0 then WHITE else Color3.fromRGB(255, 225, 240), Enum.Material.Fabric)
	end
end

-- Stations ------------------------------------------------------------------------

-- Station1, the Dye Bath: a giant paint bucket under its stop (the rail climbs over
-- it): a white can with a gold rim, glossy paint up to the brim, a wide band and paint
-- dripping down the outside in the paint's color (the Station1Paint parts: they take
-- each new color with the paint). The hook lowers the brainrot right in and pulls it
-- out painted. (It's opaque: through glass the paint looked pale, and see-through
-- paint vanished.) Its sign stands on the far side, piped into it.
local BUCKET_DIAMETER = 9.6
local BUCKET_TOP = 11.6 -- the can's rim, above the floor
local DYE_TOP = 11 -- the paint's surface: deep enough to dunk a brainrot whole
local CAN_WHITE = Color3.fromRGB(250, 248, 255)

local function buildDyeVat(model: Model, spot: CFrame, item: TycoonItems.Item)
	local key = item.Key
	makeColumn(model, key .. "VatFoot", BUCKET_DIAMETER + 1.2, 0, 0.6, spot, PLUSH_GOLD, Enum.Material.Metal)
	local can = makeColumn(model, key .. "Vat", BUCKET_DIAMETER, 0.6, DYE_TOP - 0.05, spot, CAN_WHITE) -- (just under the paint, so its surface shows)
	can.CanCollide = true
	-- the label band in the paint's color, between gold stripes
	makeColumn(model, key .. "Paint", BUCKET_DIAMETER + 0.15, 3.4, 7.6, spot, DYE_COLOR)
	for _, y in { 3.1, 7.6 } do
		makeColumn(model, key .. "VatStripe", BUCKET_DIAMETER + 0.2, y, y + 0.3, spot, PLUSH_GOLD, Enum.Material.Metal)
	end
	makeColumn(model, key .. "VatHoop", BUCKET_DIAMETER + 0.2, 1.2, 1.6, spot, SEWING_COLOR)
	-- the paint, glossy, bubbling, glowing a little
	local dye = makeColumn(model, key .. "Dye", BUCKET_DIAMETER - 0.6, 0.7, DYE_TOP, spot, DYE_COLOR)
	dye.Reflectance = 0.05
	addSparkles(dye, Color3.fromRGB(255, 255, 255), 8, 0.5) -- bubbles
	local light = Instance.new("PointLight")
	light.Color = DYE_COLOR
	light.Range = 14
	light.Brightness = 1.2
	light.Parent = dye
	-- the rim, and paint spilling over it and running down the side
	for k = 0, 15 do
		local face = spot * CFrame.Angles(0, k / 16 * math.pi * 2, 0)
		makeDecor(model, key .. "VatRim", Vector3.new(2, 0.6, 0.7), face * CFrame.new(0, BUCKET_TOP, -BUCKET_DIAMETER / 2), PLUSH_GOLD, Enum.Material.Metal)
	end
	for index, angle in { 0.3, 1.25, 2.1, 3.3, 4.2, 5.4 } do
		local length = 1.6 + (index % 3) * 1.1
		local face = spot * CFrame.Angles(0, angle, 0) * CFrame.new(0, 0, -BUCKET_DIAMETER / 2 - 0.12)
		makeDecor(model, key .. "Paint", Vector3.new(0.9, length, 0.3), face * CFrame.new(0, BUCKET_TOP - 0.3 - length / 2, 0), DYE_COLOR)
		makeBall(model, key .. "Paint", 1.05, face * CFrame.new(0, BUCKET_TOP - 0.3 - length, 0), DYE_COLOR)
		makeDecor(model, key .. "Paint", Vector3.new(1.6, 0.35, 0.4), face * CFrame.new(0, BUCKET_TOP - 0.35, 0), DYE_COLOR)
	end
	-- the bail handle, folded down against its side
	for _, side in { -1, 1 } do
		local ear = spot * CFrame.new(side * (BUCKET_DIAMETER / 2 + 0.25), BUCKET_TOP - 1.4, 0)
		makeColumn(model, key .. "HandleEar", 0.8, -0.3, 0.3, ear * CFrame.Angles(0, 0, math.pi / 2), PLUSH_GOLD, Enum.Material.Metal)
	end
	makeRod(model, key .. "Handle", (spot * CFrame.new(-BUCKET_DIAMETER / 2 - 0.45, BUCKET_TOP - 1.4, 0)).Position, (spot * CFrame.new(-BUCKET_DIAMETER / 2 - 0.45, BUCKET_TOP - 4.5, -3)).Position, 0.3, CHROME_COLOR, Enum.Material.Metal)
	-- the sign on the far side, and a chrome pipe with a gold valve from its box into the can
	local stand = spot * CFrame.new(-8.2, 0, 0)
	buildSignStand(model, key, stand, item.Name)
	makeRod(model, key .. "Pipe", (stand * CFrame.new(1.2, 2.4, 0)).Position, (spot * CFrame.new(-BUCKET_DIAMETER / 2 + 0.2, 2.4, 0)).Position, 0.7, CHROME_COLOR, Enum.Material.Metal)
	makeColumn(model, key .. "ValveStem", 0.25, 2.7, 3.2, spot * CFrame.new(-5.75, 0, 0), PLUSH_GOLD, Enum.Material.Metal)
	makeColumn(model, key .. "Valve", 1.2, 3.2, 3.45, spot * CFrame.new(-5.75, 0, 0), PLUSH_GOLD, Enum.Material.Metal)
end

-- Station2, the Sequin Shower: a disco ball hanging from the ceiling beside its stop,
-- turning, sequins raining off it onto the brainrot swinging past under it. Its sign
-- stands on the far side.
local function buildSequinShower(model: Model, spot: CFrame, item: TycoonItems.Item)
	local key = item.Key
	buildSignStand(model, key, spot * CFrame.new(-10.5, 0, 0), item.Name)
	local hang = spot * CFrame.new(3.2, 0, 0)
	local ballY = 19.8 -- just over the rail (17): the brainrot swings by under it
	makeColumn(model, key .. "Hanger", 0.3, ballY + 1.6, CEILING, hang, CHROME_COLOR, Enum.Material.Metal)
	makeColumn(model, key .. "HangerCollar", 1.6, CEILING - 0.3, CEILING, hang, PLUSH_GOLD, Enum.Material.Metal)
	makeColumn(model, key .. "BallCap", 1, ballY + 1.4, ballY + 1.8, hang, PLUSH_GOLD, Enum.Material.Metal)
	local center = hang * CFrame.new(0, ballY, 0)
	local spinner = makeSpinner(model, key .. "DiscoBall", center * CFrame.Angles(math.pi / 2, 0, 0), 1.2)
	local disco = makeBall(spinner, key .. "Disco", 3.2, center, Color3.fromRGB(225, 230, 245), Enum.Material.Foil)
	disco.Reflectance = 0.4
	for index = 0, 7 do
		local angle = index * math.pi / 4
		makeDecor(spinner, key .. "DiscoTile", Vector3.new(0.6, 0.6, 0.1), center * CFrame.new(math.cos(angle) * 1.55, (index % 2 - 0.5) * 0.8, math.sin(angle) * 1.55) * CFrame.Angles(0, -angle - math.pi / 2, 0), if index % 2 == 0 then Color3.fromRGB(255, 180, 230) else GLOW_COLOR, Enum.Material.Neon)
	end
	addSparkles(disco, Color3.fromRGB(255, 200, 240), 5, 0.4)
	makeBall(model, key .. "Nozzle", 0.5, hang * CFrame.new(0, ballY - 1.8, 0), CHROME_COLOR, Enum.Material.Metal)
	-- a jar of sequins on the sign's box
	local jar = spot * CFrame.new(-10.5 + 0.2, 4.6, -0.6)
	local glass = makeBall(model, key .. "SequinJar", 1.6, jar, GLASS_COLOR, Enum.Material.Glass)
	glass.Transparency = 0.5
	makeBall(model, key .. "Sequins", 1.1, jar * CFrame.new(0, -0.15, 0), Color3.fromRGB(255, 150, 220), Enum.Material.Neon)
end

-- Station3, the Bow Tier (the zone's special): a machine beside its stop with a
-- ribbon spool on an arm toward the brainrot; the bow flies off it onto the head. A
-- giant bow on the cabinet's front, the sign at its back.
local function buildBowTier(model: Model, spot: CFrame, item: TycoonItems.Item)
	local key = item.Key
	local base = spot * CFrame.new(-9.5, 0, 0)
	makeColumn(model, key .. "Foot", 6.4, 0, 0.6, base, LAVENDER_COLOR)
	makePart(model, key .. "Cabinet", Vector3.new(4.6, 6.4, 4.6), base * CFrame.new(0, 3.8, 0), SEWING_COLOR)
	makeDecor(model, key .. "CabinetStripe", Vector3.new(4.7, 0.5, 4.7), base * CFrame.new(0, 2.6, 0), WHITE)
	makeDecor(model, key .. "CabinetBand", Vector3.new(4.72, 0.25, 4.72), base * CFrame.new(0, 6.25, 0), GLOW_COLOR, Enum.Material.Neon)
	makeDecor(model, key .. "CabinetTrim", Vector3.new(4.9, 0.5, 4.9), base * CFrame.new(0, 6.7, 0), PLUSH_GOLD, Enum.Material.Metal) -- (its top under the cabinet's)
	RibbonBow.Build(model, base * CFrame.new(2.75, 4.2, 0) * CFrame.Angles(0, -math.pi / 2, 0), 4, BOW_PINK)
	-- the sign on posts at the back
	local back = base * CFrame.new(-1.8, 0, 0)
	for _, z in { -1.9, 1.9 } do
		makeColumn(model, key .. "SignPost", 0.5, 7, SIGN_Y - SIGN.Y / 2, back * CFrame.new(0, 0, z), LAVENDER_COLOR)
	end
	buildSign(model, key .. "Sign", back * CFrame.new(0, SIGN_Y, 0), item.Name)
	-- the column and its head (the Station3 part, which stamps as it ties the bow)
	local column = spot * CFrame.new(-8.7, 0, 0)
	makeColumn(model, key .. "Column", 1.6, 7, 12.6, column, LAVENDER_COLOR)
	makeColumn(model, key .. "ColumnStripe", 1.8, 9.5, 10, column, WHITE)
	makePart(model, key, Vector3.new(3.4, 1.8, 3.6), column * CFrame.new(0, 13.5, 0), LAVENDER_COLOR)
	makeDecor(model, key .. "Stripe", Vector3.new(3.5, 0.45, 3.7), column * CFrame.new(0, 13.5, 0), WHITE)
	makeDecor(model, key .. "Glow", Vector3.new(3, 0.25, 3.2), column * CFrame.new(0, 12.5, 0), WHITE, Enum.Material.Neon)
	-- the ribbon spool on a bracket off its front, toward the brainrot
	makeDecor(model, key .. "Bracket", Vector3.new(1.6, 0.4, 0.6), column * CFrame.new(2.4, 13.8, 0), PLUSH_GOLD, Enum.Material.Metal)
	local hub = column * CFrame.new(3.2, 14.6, 0)
	makeBarrel(model, key .. "Nozzle", 2.4, 1.8, hub, BOW_PINK)
	for _, z in { -1.3, 1.3 } do
		makeBarrel(model, key .. "SpoolRim", 0.25, 2.4, hub * CFrame.new(0, 0, z), WHITE)
	end
end

-- Builds `item` (Station1, Station2 or Station3) at `spot`, on the floor under its stop.
function RailBuilder.BuildStation(model: Model, spot: CFrame, item: TycoonItems.Item)
	if item.Key == "Station1" then
		buildDyeVat(model, spot, item)
	elseif item.Key == "Station2" then
		buildSequinShower(model, spot, item)
	else
		buildBowTier(model, spot, item)
	end
end

-- Speed upgrades: a glowing turbo thread along the rail, one side each.
function RailBuilder.BuildSpeed(model: Model, origin: CFrame, layout: LineLayouts.Layout, item: TycoonItems.Item)
	local curve = LineLayouts.RailCurve(layout) :: LineLayouts.Curve
	local side = if item.Key == "Speed1" then -1 else 1
	alongRail(origin, curve, 0, curve.Length, function(frame, length)
		makeDecor(model, item.Key, Vector3.new(0.4, 0.4, length + 0.1), frame * CFrame.new(side * 0.88, 0.25, 0), TURBO_COLOR, Enum.Material.Neon).CastShadow = false
	end)
end

-- The Belt Boost track's look on the rail: its glow takes the tier's color, little gold
-- hooks hang along both its sides (more each level), a gold thread runs along its top
-- from tier 2, sparkles from tier 3, and chasing lights at the top tier.
export type TrackLook = {
	Tier: number,
	Color: Color3,
	Gold: Color3,
	Bulb: (parent: Instance, at: CFrame, size: number, tier: number, index: number) -> Part,
	Sparkles: (parent: Instance, at: CFrame, size: Vector3, rate: number) -> (),
}

function RailBuilder.BuildTrackLook(model: Model, line: Model, origin: CFrame, layout: LineLayouts.Layout, level: number, look: TrackLook)
	local curve = LineLayouts.RailCurve(layout) :: LineLayouts.Curve
	local stops = layout.Stops :: { [string]: number }
	local from, to = curve.Knots[stops.Out], curve.Knots[stops.Ship]
	for _, child in line:GetChildren() do
		if child.Name == "RailGlow" and child:IsA("BasePart") then
			child.Color = look.Color
		end
	end
	-- the hooks, short enough that a brainrot passes under them
	local count = 2 + level * 2
	for k = 1, count do
		local at, heading = LineLayouts.At(curve, from + (to - from) * (k - 0.5) / count)
		local side = if k % 2 == 0 then 1 else -1
		local top = CFrame.lookAt(origin * at, origin * at + origin:VectorToWorldSpace(heading)) * CFrame.new(side * 1.1, -0.7, 0)
		makeDecor(model, "TrackHook", Vector3.new(0.16, 0.9, 0.16), top * CFrame.new(0, -0.45, 0), look.Gold, Enum.Material.Metal)
		makeDecor(model, "TrackHookBend", Vector3.new(0.16, 0.16, 0.5), top * CFrame.new(0, -0.9, -0.17), look.Gold, Enum.Material.Metal)
		makeBall(model, "TrackHookYarn", 0.45, top * CFrame.new(0, -0.95, -0.42), look.Color, Enum.Material.Neon).CastShadow = false
	end
	if look.Tier >= 2 then
		alongRail(origin, curve, 0, curve.Length, function(frame, length)
			makeDecor(model, "TrackThread", Vector3.new(0.3, 0.1, length + 0.1), frame * CFrame.new(0, 1.05, 0), look.Gold, Enum.Material.Neon).CastShadow = false
		end)
	end
	if look.Tier >= 3 then
		for k = 0, 3 do
			local a = origin * LineLayouts.At(curve, from + (to - from) * k / 4)
			local b = origin * LineLayouts.At(curve, from + (to - from) * (k + 1) / 4)
			look.Sparkles(model, CFrame.lookAt((a + b) / 2, b), Vector3.new(2, 1, (b - a).Magnitude), 4 + look.Tier * 2)
		end
	end
	if look.Tier >= 4 then
		local bulbs = 28
		for k = 1, bulbs do
			local at, heading = LineLayouts.At(curve, curve.Length * (k - 0.5) / bulbs)
			for index, side in { -1, 1 } do
				local frame = CFrame.lookAt(origin * at, origin * at + origin:VectorToWorldSpace(heading))
				look.Bulb(model, frame * CFrame.new(side * 0.85, 1.1, 0), 0.45, look.Tier, k + (index - 1) * bulbs)
			end
		end
	end
end

return RailBuilder
