--[[
	TycoonManager
	Owns the tycoon plots (GDD §2, §6): gives each player a plot when their data loads,
	builds what they've purchased, shows the purchase buttons in unlock order, and runs
	the collector + Cash Pad.

	All geometry is generated in code: FactoryBuilder builds each plot's building (a
	room per zone, two per storey), and this module the lines inside: a belt raised on a
	frame (its top is the deck), with the zone's machines on and over it. ProductionVisuals
	finds line parts by name (Belt, Assembler, Ship, HeadDropper, BodyDropper,
	ArmsDropper, LegsDropper (with the Toy Workshop's ceiling chutes, HeadChuteTop etc.,
	and the Plushie room's knitting machines, HeadKnitRing etc.), Beacon, Station1/2/3
	and their Glow) and animates the Assembler's machines (Claw: Hand, Rod, FingerLeft,
	FingerRight; PusherLeft and PusherRight: Fist, Rod; the sewing machine's Needle and
	Spools): keep those names when swapping in real art. TycoonFX finds Belt and CashPad
	(its Collected and Generation attributes).

	Bought items' parts get a Built attribute (server time) so clients play the build
	animation; every item part gets Item = its item id.
]]

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Format = require(Shared.Format)
local Remotes = require(Shared.Remotes)
local TycoonItems = require(Shared.Config.TycoonItems)
local Zones = require(Shared.Config.Zones)

local DataManager = require(script.Parent.DataManager)
local FactoryBuilder = require(script.Parent.FactoryBuilder)
local MonetizationManager = require(script.Parent.MonetizationManager)
local RoomUpgradeBuilder = require(script.Parent.RoomUpgradeBuilder)

-- Layout ---------------------------------------------------------------------
-- Plot space: origin on the ground at the plot's center, -Z (front) faces the hub.

local PLOT_COUNT = 6
local PLOT_RADIUS = 300 -- hub (world origin) to plot center; entrances at 240
local FLOOR_TOP = FactoryBuilder.FloorTop
-- Each zone is a room of the factory (GDD §10), placed by FactoryBuilder.Layout: the
-- Toy Workshop sits at the plot's center, the Plushie room behind it, and the next
-- zones upstairs.
local PLOT_COLORS = {
	Color3.fromRGB(255, 214, 165),
	Color3.fromRGB(190, 230, 255),
	Color3.fromRGB(210, 255, 200),
	Color3.fromRGB(255, 200, 230),
	Color3.fromRGB(230, 210, 255),
	Color3.fromRGB(255, 245, 180),
}

local SPAWN_OFFSET = CFrame.new(0, FLOOR_TOP + 4, -54) * CFrame.Angles(0, math.pi, 0) -- facing into the plot
local FLOOR_BUTTON = Vector3.new(-30, 0, -78) -- the next floor's button, on the lawn out front
-- Where a room's opening button sits (plot space, on the floor): beside its door, on the
-- side you come from (clear of the middle line's belt end and buttons), or on the
-- outside stairs' landing.
local ROOM_BUTTONS = {
	PlushieRoom = Vector3.new(18, FactoryBuilder.FloorY(1), 55),
	ClayStudio = Vector3.new(75.7, FactoryBuilder.FloorY(2), 31),
	VinylCollectibles = Vector3.new(18, FactoryBuilder.FloorY(2), 55),
}
local OLD_BUILDING_DELAY = 2 -- seconds the old building stays (minus its top) while the new one streams in
local CASH_PAD_OFFSET = CFrame.new(0, FLOOR_TOP + 0.3, -46)

-- Line origins sit on the floor. Parts flow from the droppers (+Z) to the finishing
-- stage (-Z), along a belt raised on a chunky frame: its top is the DECK, and the
-- machines on it are measured from there.
local LINE_X = { 0, -42, 42 }
local DECK = 4 -- the belt's top, above the floor
local BELT_WIDTH = 10
local BELT_FROM, BELT_TO = -25, 53 -- the belt's ends along Z (brainrots leave at the -Z end)
local GIRDER_X = BELT_WIDTH / 2 + 0.6 -- the frame's side beams, with the rails on top
local BELT_LEGS = { -19, -2.5, 11, 23, 35, 47 } -- along Z, clear of the arches and the gantry
local DROPPER_Z = { Head = 46, Body = 36, Arms = 26, Legs = 16 }
local STATION_Z = { Station1 = -8, Station2 = -15, Station3 = -23 } -- Station3: the zone's special, at the belt's end
local SHIP_Z = -31.5 -- the finishing stage, just past the end of the belt
local SPEED_X = { Speed1 = -2, Speed2 = 2 }
-- Button spots relative to the line origin, along the line's +X side. A line shows one
-- button at a time, so Speed1 and Speed2 can share a spot.
local BUTTON_X = 13
local BUTTON_OFFSETS = {
	Line = Vector3.new(0, 0, -42),
	Head = Vector3.new(BUTTON_X, 0, 46),
	Body = Vector3.new(BUTTON_X, 0, 36),
	Arms = Vector3.new(BUTTON_X, 0, 26),
	Legs = Vector3.new(BUTTON_X, 0, 16),
	Speed1 = Vector3.new(BUTTON_X, 0, 5),
	Speed2 = Vector3.new(BUTTON_X, 0, 5),
	Station1 = Vector3.new(BUTTON_X, 0, -8),
	Station2 = Vector3.new(BUTTON_X, 0, -15),
	Station3 = Vector3.new(BUTTON_X, 0, -23),
}

local PART_COLORS = {
	Head = Color3.fromRGB(255, 105, 180),
	Body = Color3.fromRGB(255, 210, 60),
	Arms = Color3.fromRGB(80, 210, 255),
	Legs = Color3.fromRGB(140, 230, 80),
}
local STATION_COLORS = {
	Station1 = Color3.fromRGB(255, 120, 200),
	Station2 = Color3.fromRGB(120, 240, 255),
}
local METAL_COLOR = Color3.fromRGB(90, 90, 100)
local GANTRY_COLOR = Color3.fromRGB(150, 90, 255)
local CLAW_COLOR = Color3.fromRGB(255, 200, 60)
local GLOVE_COLOR = Color3.fromRGB(235, 55, 70)
local CHROME_COLOR = Color3.fromRGB(215, 220, 235)
local SEWING_COLOR = Color3.fromRGB(235, 65, 150) -- the Plushie room's machines: magenta...
local SEWING_LIGHT_COLOR = Color3.fromRGB(255, 240, 248) -- ...with cream...
local LAVENDER_COLOR = Color3.fromRGB(150, 95, 240) -- ...and violet, with gold and chrome
local PLUSH_GOLD = Color3.fromRGB(255, 190, 40) -- solid gold: Metal, no reflectance
local THREAD_COLORS = { Color3.fromRGB(120, 200, 255), Color3.fromRGB(255, 150, 90) }
local FLUFF_PINK = Color3.fromRGB(255, 150, 200)
local WHITE = Color3.new(1, 1, 1)
local BELT_COLOR = Color3.fromRGB(60, 60, 70)
local RAIL_COLOR = Color3.fromRGB(255, 170, 60)
local AFFORDABLE_COLOR = Color3.fromRGB(80, 220, 100)
local EXPENSIVE_COLOR = Color3.fromRGB(235, 80, 80)
local LOCKED_COLOR = Color3.fromRGB(150, 145, 165) -- a room upgrade that needs more rebirths
local BUTTON_COOLDOWN = 0.5

export type Plot = {
	Index: number,
	Model: Model,
	CFrame: CFrame,
	Color: Color3, -- the plot's pastel color
	Building: Model, -- the factory (FactoryBuilder), rebuilt when it grows a floor
	Storeys: number,
	LinesFolder: Folder,
	ButtonsFolder: Folder,
	SignLabel: TextLabel,
	CashPad: BasePart,
	CashLabel: TextLabel,
	Doorways: { [string]: FactoryBuilder.Doorway }, -- into every room but the first, by zone id
	Owner: Player?,
	Collected: number, -- Coins waiting on the Cash Pad
	Generation: number, -- bumped on every reset or release, so payouts in flight can tell
	Buttons: { [string]: BasePart },
	Connections: { RBXScriptConnection },
}

local plots: { Plot } = {}
local plotByPlayer: { [Player]: Plot } = {}
local buttonCooldowns: { [Player]: number } = {}

local TycoonManager = {}

-- Helpers --------------------------------------------------------------------

local function makePart(
	parent: Instance,
	name: string,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	material: Enum.Material?
): Part
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

-- Floating text above `adornee`. `size` and `height` are in studs.
local function makeBillboard(adornee: BasePart, text: string, size: Vector2, height: number, maxDistance: number): TextLabel
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromScale(size.X, size.Y)
	gui.StudsOffset = Vector3.new(0, height, 0)
	gui.MaxDistance = maxDistance
	gui.LightInfluence = 0
	gui.Parent = adornee

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Text = text
	label.Parent = gui

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2
	stroke.Parent = label
	return label
end

local function getPlayerFromHit(hit: BasePart): Player?
	local character = hit:FindFirstAncestorOfClass("Model")
	local player = character and Players:GetPlayerFromCharacter(character)
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if player and humanoid and humanoid.Health > 0 then
		return player
	end
	return nil
end

-- Whether a zone's room can be opened (or is open): it's built, the player has the
-- rebirths, and its storey is up (floors are bought: TycoonItems.Floors).
local function isZoneReachable(data: DataManager.PlayerData, zone: Zones.Zone): boolean
	if not (zone.Available and data.Rebirths >= zone.UnlockRebirths) then
		return false
	end
	local spot = FactoryBuilder.Layout[zone.Index]
	return spot == nil or spot.Storey <= TycoonItems.StoreysOf(data.Tycoon.Purchased, FactoryBuilder.BaseStoreys)
end

-- Whether a zone's room is open: reachable, and opened with Coins at its door when it
-- has an UnlockPrice (its Room item).
local function isZoneUnlocked(data: DataManager.PlayerData, zoneId: string): boolean
	local zone = Zones.ById[zoneId]
	return zone ~= nil
		and isZoneReachable(data, zone)
		and (zone.UnlockPrice == nil or data.Tycoon.Purchased[`{zoneId}_Room`] == true)
end

-- Items ----------------------------------------------------------------------

local function lineOrigin(plot: Plot, lineId: string): CFrame
	local line = TycoonItems.LinesById[lineId]
	local zone = Zones.ById[line.Zone]
	return plot.CFrame * FactoryBuilder.RoomCFrame(zone.Index) * CFrame.new(LINE_X[line.Index], 0, 0)
end

local function getLineModel(plot: Plot, lineId: string): Model
	local existing = plot.LinesFolder:FindFirstChild(lineId)
	if existing then
		return existing :: Model
	end
	local model = Instance.new("Model")
	model.Name = lineId
	model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic -- the visuals need the whole line at once
	model.Parent = plot.LinesFolder
	return model
end

-- The deck: the top of a line's belt, over its origin on the floor. The machines on
-- the line are measured from it.
local function deckOf(origin: CFrame): CFrame
	return origin * CFrame.new(0, DECK, 0)
end

-- Makes a part that's just for looks: no collisions, no touches.
local function makeDecor(parent: Instance, name: string, size: Vector3, cframe: CFrame, color: Color3, material: Enum.Material?): Part
	local part = makePart(parent, name, size, cframe, color, material)
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	return part
end

-- An upright cylinder from `bottom` to `top` over `base` (on the floor).
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

-- Gantry colors per zone: { pillars, beam, glow }. The beam's color also goes on the
-- belt's frame; the glow lines the rails and lights the beacon while the Assembler
-- works.
local GANTRY_COLORS = {
	ToyWorkshop = { Color3.fromRGB(110, 60, 200), GANTRY_COLOR, Color3.fromRGB(255, 220, 70) },
	PlushieRoom = { LAVENDER_COLOR, SEWING_COLOR, Color3.fromRGB(90, 220, 255) },
	ClayStudio = { Color3.fromRGB(150, 75, 50), Color3.fromRGB(225, 120, 75), Color3.fromRGB(60, 205, 195) },
}

-- The belt, raised on a frame: side girders with a white stripe, rails glowing on top
-- of them, short chunky legs, and a roller at each end the belt seems to wrap round.
local function buildConveyor(model: Model, origin: CFrame, colors: { Color3 })
	local length = BELT_TO - BELT_FROM
	local middle = (BELT_TO + BELT_FROM) / 2
	makePart(model, "Belt", Vector3.new(BELT_WIDTH, 1, length), origin * CFrame.new(0, DECK - 0.5, middle), BELT_COLOR)
	for _, z in { BELT_FROM, BELT_TO } do
		local roller = makeDecor(model, "BeltRoller", Vector3.new(BELT_WIDTH, 1.2, 1.2), origin * CFrame.new(0, DECK - 0.6, z), BELT_COLOR)
		roller.Shape = Enum.PartType.Cylinder
	end
	local foot = colors[1]:Lerp(Color3.new(0, 0, 0), 0.25)
	for _, side in { -1, 1 } do
		local x = side * GIRDER_X
		makePart(model, "BeltGirder", Vector3.new(1.2, 2, length + 1.4), origin * CFrame.new(x, DECK - 1, middle), colors[2])
		makeDecor(model, "BeltGirderStripe", Vector3.new(1.3, 0.45, length + 0.6), origin * CFrame.new(x, DECK - 1.1, middle), WHITE)
		local rail = if side < 0 then "RailLeft" else "RailRight"
		makePart(model, rail, Vector3.new(0.8, 1, length + 1.4), origin * CFrame.new(x, DECK + 0.5, middle), RAIL_COLOR)
		makeDecor(model, rail .. "Glow", Vector3.new(0.4, 0.12, length + 1.4), origin * CFrame.new(x, DECK + 1.06, middle), colors[3], Enum.Material.Neon)
		for _, z in BELT_LEGS do
			makePart(model, "BeltLeg", Vector3.new(1.4, DECK - 2, 1.4), origin * CFrame.new(x, (DECK - 2) / 2, z), colors[1])
			makeDecor(model, "BeltFoot", Vector3.new(2.2, 0.4, 2.2), origin * CFrame.new(x, 0.2, z), foot)
		end
	end
end

-- The Assembler: a gantry over the pad (the deck at the line's origin), with the
-- zone's machines under it, a lamp that lights the pad and a beacon that flashes while
-- it builds. Its beam's bottom is GANTRY_BOTTOM above the deck (well over the tallest
-- brainrot, so the claw can lift a head over it).
local GANTRY_BOTTOM = 13
local GANTRY_PILLAR = Vector2.new(7.6, 5.6) -- the pillars' X and Z from the pad
local SIDE_X = 7.6 -- the pushers and spools stand on pedestals this far from the pad

local function buildGantry(model: Model, origin: CFrame, colors: { Color3 })
	local deck = deckOf(origin)
	local height = DECK + GANTRY_BOTTOM
	for _, corner in { Vector2.new(-1, -1), Vector2.new(-1, 1), Vector2.new(1, -1), Vector2.new(1, 1) } do
		local base = origin * CFrame.new(GANTRY_PILLAR.X * corner.X, 0, GANTRY_PILLAR.Y * corner.Y)
		makePart(model, "AssemblerPillar", Vector3.new(1.6, height, 1.6), base * CFrame.new(0, height / 2, 0), colors[1])
		makeDecor(model, "AssemblerPillarCap", Vector3.new(2.2, 0.6, 2.2), base * CFrame.new(0, 0.3, 0), colors[1]:Lerp(Color3.new(0, 0, 0), 0.25))
	end
	local assembler = makePart(model, "Assembler", Vector3.new(17.4, 2.4, 13), deck * CFrame.new(0, GANTRY_BOTTOM + 1.2, 0), colors[2])
	makeDecor(model, "AssemblerStripe", Vector3.new(17.5, 0.5, 13.1), deck * CFrame.new(0, GANTRY_BOTTOM + 1.2, 0), WHITE)
	local lamp = Instance.new("SpotLight")
	lamp.Face = Enum.NormalId.Bottom
	lamp.Angle = 75
	lamp.Range = 18
	lamp.Brightness = 1.6
	lamp.Color = Color3.fromRGB(255, 240, 215)
	lamp.Parent = assembler
	local beacon = makeBall(model, "Beacon", 1.8, deck * CFrame.new(0, GANTRY_BOTTOM + 3.3, 0), Color3.fromRGB(120, 110, 130))
	beacon:SetAttribute("GlowColor", colors[3])
	local beaconLight = Instance.new("PointLight")
	beaconLight.Color = colors[3]
	beaconLight.Range = 14
	beaconLight.Brightness = 0
	beaconLight.Parent = beacon
end

-- The Toy Workshop's claw hangs from the gantry. Its grip point (under the hand) rests
-- CLAW_REST above the deck; the rod stretches up to the gantry as it moves.
local CLAW_REST = 9

local function buildClaw(parent: Model, origin: CFrame)
	local claw = Instance.new("Model")
	claw.Name = "Claw"
	local grip = deckOf(origin) * CFrame.new(0, CLAW_REST, 0)
	makePart(claw, "Hand", Vector3.new(2, 0.7, 2), grip * CFrame.new(0, 0.35, 0), CLAW_COLOR)
	makePart(claw, "FingerLeft", Vector3.new(0.35, 1, 1.3), grip * CFrame.new(-0.85, -0.5, 0), METAL_COLOR)
	makePart(claw, "FingerRight", Vector3.new(0.35, 1, 1.3), grip * CFrame.new(0.85, -0.5, 0), METAL_COLOR)
	local rodLength = GANTRY_BOTTOM - (CLAW_REST + 0.7)
	makePart(claw, "Rod", Vector3.new(0.45, rodLength, 0.45), grip * CFrame.new(0, 0.7 + rodLength / 2, 0), METAL_COLOR)
	claw.Parent = parent
end

-- The Toy Workshop's punch presses: a chunky machine each side of the pad, in the claw's
-- colors, with a piston barrel aimed at the pad and a big red boxing glove on a chrome
-- rod that BONKs the arms into place. The rod runs from the barrel's mouth to the glove
-- (the Fist, at the rod's -Z end); the glove's cuff and thumb (FistCuff, FistThumb) ride
-- along with the Fist, and the lamp on top (PusherLamp) flashes as it punches.
local PUSHER_X = 8.4 -- the press's middle, from the pad (clear of the tablet)
local PUNCH_Y = 3 -- the glove at rest, above the deck

local function buildPusher(parent: Model, origin: CFrame, side: number)
	local pusher = Instance.new("Model")
	pusher.Name = if side < 0 then "PusherLeft" else "PusherRight"
	local x = PUSHER_X * side
	local inward = -side -- toward the pad, along X
	local at = origin * CFrame.new(x, 0, 0)

	-- a round foot, the housing with a white stripe and a yellow cap, a lamp on top
	makeColumn(pusher, "PusherFoot", 3, 0, 0.6, at, Color3.fromRGB(85, 45, 160))
	local housingTop = DECK + PUNCH_Y + 1.4
	makePart(pusher, "PusherHousing", Vector3.new(2.4, housingTop - 0.6, 2.6), at * CFrame.new(0, 0.6 + (housingTop - 0.6) / 2, 0), GANTRY_COLOR)
	makeDecor(pusher, "PusherStripe", Vector3.new(2.5, 0.5, 2.7), at * CFrame.new(0, DECK - 0.5, 0), WHITE)
	makeDecor(pusher, "PusherCap", Vector3.new(2.7, 0.6, 2.9), at * CFrame.new(0, housingTop + 0.3, 0), CLAW_COLOR)
	makeBall(pusher, "PusherLamp", 1, at * CFrame.new(0, housingTop + 0.9, 0), Color3.fromRGB(255, 170, 40), Enum.Material.Neon)

	-- the piston barrel aimed at the pad, a yellow ring at its mouth
	local barrelY = DECK + PUNCH_Y
	local barrelLength = 2.2
	local mouthX = inward * (0.8 + barrelLength) -- from the press's middle
	local barrel = makeDecor(pusher, "PusherBarrel", Vector3.new(barrelLength, 1.8, 1.8), at * CFrame.new(mouthX - inward * barrelLength / 2, barrelY, 0), WHITE)
	barrel.Shape = Enum.PartType.Cylinder
	local muzzle = makeDecor(pusher, "PusherMuzzle", Vector3.new(0.4, 2.1, 2.1), at * CFrame.new(mouthX, barrelY, 0), CLAW_COLOR)
	muzzle.Shape = Enum.PartType.Cylinder

	-- the glove, just out of the barrel: its cuff toward the barrel, its thumb up front
	local shoulder = (at * CFrame.new(mouthX, barrelY, 0)).Position
	local glove = origin.Rotation + (at * CFrame.new(mouthX + inward, barrelY, 0)).Position
	local fist = makePart(pusher, "Fist", Vector3.one * 1.5, glove, GLOVE_COLOR)
	fist.Shape = Enum.PartType.Ball
	fist.CanCollide = false
	local cuff = makeDecor(pusher, "FistCuff", Vector3.new(0.7, 1.3, 1.3), glove * CFrame.new(-inward * 0.75, 0, 0), WHITE)
	cuff.Shape = Enum.PartType.Cylinder
	makeBall(pusher, "FistThumb", 0.65, glove * CFrame.new(inward * 0.15, 0.5, -0.55), GLOVE_COLOR)
	local rod = makePart(pusher, "Rod", Vector3.new(0.5, 0.5, (glove.Position - shoulder).Magnitude), CFrame.lookAt((shoulder + glove.Position) / 2, glove.Position), CHROME_COLOR, Enum.Material.Metal)
	rod.CanCollide = false
	pusher.Parent = parent
end

-- The Plushie Sewing Room's Assembler: a sewing-machine head whose needle stitches
-- parts on, and two thread spools on pedestals beside the pad that reel the arms in.
-- Each thread runs from its spool toward the pad, with its free end at the rod's -Z end.
local NEEDLE_REST = 9 -- the needle's tip at rest, above the deck

local function buildSewingMachine(parent: Model, origin: CFrame)
	local deck = deckOf(origin)
	makePart(parent, "NeedleHead", Vector3.new(2, 1.8, 2), deck * CFrame.new(0, GANTRY_BOTTOM - 0.9, 0), SEWING_LIGHT_COLOR)
	local needle = makePart(parent, "Needle", Vector3.new(0.28, 3.8, 0.28), deck * CFrame.new(0, NEEDLE_REST + 1.9, 0), Color3.fromRGB(215, 215, 230), Enum.Material.Metal)
	needle.CanCollide = false
	for index, side in { -1, 1 } do
		local suffix = if side < 0 then "Left" else "Right"
		local x = SIDE_X * side
		makePart(parent, `Pedestal{suffix}`, Vector3.new(2, DECK + 0.6, 2), origin * CFrame.new(x, (DECK + 0.6) / 2, 0), LAVENDER_COLOR)
		makeDecor(parent, `PedestalTrim{suffix}`, Vector3.new(2.1, 0.4, 2.1), origin * CFrame.new(x, DECK + 0.4, 0), WHITE)
		local spool = makePart(parent, `Spool{suffix}`, Vector3.new(1.4, 1.8, 1.8), deck * CFrame.new(x, 1.3, 0) * CFrame.Angles(0, 0, math.pi / 2), THREAD_COLORS[index])
		spool.Shape = Enum.PartType.Cylinder -- rotated so the spool stands upright
		local tip = (deck * CFrame.new(x - 1.2 * side, 1.3, 0)).Position
		local thread = makePart(parent, `Thread{suffix}`, Vector3.new(0.15, 0.15, 1.2), CFrame.lookAt((spool.Position + tip) / 2, tip), THREAD_COLORS[index], Enum.Material.Neon)
		thread.CanCollide = false
	end
end

-- The Toy Workshop's droppers are chutes from the ceiling (GDD §6): each part pops out
-- of a collar in the ceiling (the ChuteTop), slides down a glass tube ringed with
-- colored bands, and the chunky nozzle (the Dropper) spits it onto the belt. A neon
-- sign wrapped around the tube's middle like a bracelet (the ChuteBadge) says which part
-- it drops. `base` is on the floor under it. ProductionVisuals plays the slide.
local CHUTE_TUBE = 5.8 -- across
local CHUTE_COLLAR = 4 -- tall: it hides a part waiting to slide
local CHUTE_BANDS = { 0.1, 0.27, 0.73, 0.9 } -- along the tube, clear of the badge in the middle
local BADGE = Vector2.new(7.6, 2.6) -- each side of the neon bracelet
local BADGE_BACK = Color3.fromRGB(40, 28, 60)

-- The part's name in glowing neon letters on `panel`'s front face.
local function neonLabel(panel: BasePart, partType: string, color: Color3)
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
	label.TextColor3 = color:Lerp(Color3.new(1, 1, 1), 0.7)
	label.Text = string.upper(partType)
	label.Parent = gui
	local glow = Instance.new("UIStroke")
	glow.Thickness = 3
	glow.Color = color
	glow.Parent = label
end

-- One side of the neon sign: a dark panel with the part's name in glowing letters.
local function badgeSide(model: Model, partType: string, cframe: CFrame, size: Vector2, color: Color3)
	local panel = makeDecor(model, partType .. "ChuteBadge", Vector3.new(size.X, size.Y, 0.4), cframe, BADGE_BACK)
	neonLabel(panel, partType, color)
end

-- The neon sign around a dropper's tube or column (`middle`: its center), `scale`
-- times the usual size: a panel on each side, framed top and bottom by neon strips.
-- Named ChuteBadge so it squashes along with a chute.
local function buildBadge(model: Model, partType: string, middle: CFrame, color: Color3, scale: number?)
	local size = BADGE * (scale or 1)
	local light = color:Lerp(Color3.new(1, 1, 1), 0.35)
	local reach = size.X / 2 - 0.2
	for turn = 0, 3 do
		local side = middle * CFrame.Angles(0, turn * math.pi / 2, 0)
		badgeSide(model, partType, side * CFrame.new(0, 0, -reach), size, color)
		for _, y in { -1, 1 } do
			makeDecor(model, partType .. "ChuteBadgeRim", Vector3.new(size.X + 0.4, 0.3, 0.3), side * CFrame.new(0, y * (size.Y / 2 + 0.15), -reach - 0.1), light, Enum.Material.Neon)
		end
	end
end

local function buildChute(model: Model, base: CFrame, partType: string, color: Color3)
	local deck = deckOf(base)
	local ceiling = FactoryBuilder.CeilingHeight - DECK -- above the deck
	local light = color:Lerp(Color3.new(1, 1, 1), 0.35)
	makePart(model, partType .. "Dropper", Vector3.new(6.4, 3, 6.4), deck * CFrame.new(0, 8.5, 0), color)
	makeDecor(model, partType .. "DropperRim", Vector3.new(6.7, 0.35, 6.7), deck * CFrame.new(0, 7.1, 0), light, Enum.Material.Neon)
	makeDecor(model, partType .. "DropperMouth", Vector3.new(4.4, 0.1, 4.4), deck * CFrame.new(0, 6.9, 0), Color3.fromRGB(35, 25, 45))

	local tubeBottom, tubeTop = 10, ceiling - CHUTE_COLLAR
	local glassBottom = tubeBottom + 1.2
	makeColumn(model, partType .. "ChuteNeck", CHUTE_TUBE + 1.4, tubeBottom, glassBottom, deck, light)
	local glass = makeColumn(model, partType .. "ChuteTube", CHUTE_TUBE, glassBottom, tubeTop, deck, light, Enum.Material.Glass)
	glass.Transparency = 0.55
	for _, share in CHUTE_BANDS do
		local y = glassBottom + (tubeTop - glassBottom) * share
		makeColumn(model, partType .. "ChuteBand", CHUTE_TUBE + 0.6, y - 0.35, y + 0.35, deck, color)
	end
	makeColumn(model, partType .. "ChuteTop", CHUTE_TUBE + 1.8, tubeTop, ceiling, deck, GANTRY_COLOR)
	makeColumn(model, partType .. "ChuteRing", CHUTE_TUBE + 2.4, tubeTop - 0.3, tubeTop + 0.9, deck, color)
	makeColumn(model, partType .. "ChuteFlange", CHUTE_TUBE + 4, ceiling - 0.6, ceiling, deck, light)

	buildBadge(model, partType, deck * CFrame.new(0, (glassBottom + tubeTop) / 2, 0), color)
end

-- Plushie Sewing Room: the droppers are sock-knitting machines (GDD §6): a hot-pink
-- column beside the belt on a lavender foot, with white cuff stripes and a pom-pom,
-- whose arm reaches over the belt holding a round knitting head in the part's color
-- (the Dropper, its mouth underneath). Its needles stand in a white ring round the head
-- (KnitRing), the yarn ball on top of the arm feeds it (KnitYarn) and a crank turns on
-- the column (KnitCrank): ProductionVisuals spins all three while the part is knitted
-- down out of the mouth. A neon bracelet round the column names the part.
local KNIT_X = -9.6 -- the column, beside the belt; its arm reaches over to the belt's middle
local KNIT_COLUMN = 3.8 -- across
local KNIT_HEAD = 5 -- the knitting head, across
local KNIT_ARM = 12 -- the arm's underside, above the deck
local KNIT_HEAD_HEIGHT = 5 -- the head hangs this far under the arm: its mouth is level with a chute's

local function buildKnittingMachine(model: Model, base: CFrame, partType: string, color: Color3)
	local column = base * CFrame.new(KNIT_X, 0, 0) -- on the floor
	local light = color:Lerp(WHITE, 0.5)
	local armBottom = DECK + KNIT_ARM -- from the floor
	local armTop = armBottom + 3

	-- the column on its cushy foot
	makeColumn(model, partType .. "KnitFoot", 6.4, 0, 1.4, column, LAVENDER_COLOR)
	makeColumn(model, partType .. "KnitFootRing", 6.6, 1.1, 1.5, column, PLUSH_GOLD, Enum.Material.Metal)
	local body = makeColumn(model, partType .. "KnitColumn", KNIT_COLUMN, 1.4, armTop, column, SEWING_COLOR)
	body.CanCollide = true
	for _, y in { 2.6, armBottom - 1.6 } do
		makeColumn(model, partType .. "KnitStripe", KNIT_COLUMN + 0.3, y, y + 0.7, column, WHITE)
	end
	buildBadge(model, partType, column * CFrame.new(0, DECK + 4.6, 0), color, 0.62)

	-- the arm over the belt, with a rounded nose and a gold stripe
	local armFrom, armTo = KNIT_X - KNIT_COLUMN / 2, KNIT_HEAD / 2
	local arm = makeDecor(model, partType .. "KnitArm", Vector3.new(armTo - armFrom, 3, 4), base * CFrame.new((armFrom + armTo) / 2, armBottom + 1.5, 0), SEWING_COLOR)
	makeDecor(model, partType .. "KnitArmStripe", Vector3.new(armTo - armFrom - 0.2, 0.55, 4.1), arm.CFrame, PLUSH_GOLD, Enum.Material.Metal)
	local nose = makeDecor(model, partType .. "KnitArmNose", Vector3.new(4, 3, 3), base * CFrame.new(armTo, armBottom + 1.5, 0) * CFrame.Angles(0, math.pi / 2, 0), SEWING_COLOR)
	nose.Shape = Enum.PartType.Cylinder
	-- a thread cone on top of the column
	makeColumn(model, partType .. "KnitCone", 2.6, armTop, armTop + 1.4, column, color, Enum.Material.Fabric)
	makeColumn(model, partType .. "KnitCone", 1.9, armTop + 1.4, armTop + 2.8, column, color:Lerp(WHITE, 0.2), Enum.Material.Fabric)
	makeColumn(model, partType .. "KnitConeTip", 1, armTop + 2.8, armTop + 3.5, column, CHROME_COLOR, Enum.Material.Metal)

	-- the knitting head (the Dropper) under the arm's end, its mouth glowing underneath
	local headBottom = armBottom - KNIT_HEAD_HEIGHT
	local head = makeColumn(model, partType .. "Dropper", KNIT_HEAD, headBottom, armBottom, base, color, Enum.Material.Fabric)
	head:SetAttribute("Knitting", true)
	makeColumn(model, partType .. "DropperRim", KNIT_HEAD + 0.4, headBottom - 0.15, headBottom + 0.25, base, light, Enum.Material.Neon)
	makeColumn(model, partType .. "DropperMouth", KNIT_HEAD - 1, headBottom - 0.2, headBottom - 0.1, base, Color3.fromRGB(35, 25, 45))

	-- the needle ring round the head: a white band with a ring of needles, beaded
	local ringY = armBottom - 2.4
	local ring = Instance.new("Model")
	ring.Name = partType .. "KnitRing"
	makeColumn(ring, partType .. "KnitRingBand", KNIT_HEAD + 0.6, ringY, ringY + 0.8, base, WHITE)
	for index = 1, 12 do
		local angle = index / 12 * math.pi * 2
		local at = base * CFrame.new(math.cos(angle) * (KNIT_HEAD / 2 + 0.2), 0, math.sin(angle) * (KNIT_HEAD / 2 + 0.2))
		makeDecor(ring, partType .. "KnitNeedle", Vector3.new(0.18, 1.3, 0.18), at * CFrame.new(0, ringY + 1.4, 0), Color3.fromRGB(220, 225, 235), Enum.Material.Metal)
		makeBall(ring, partType .. "KnitNeedleBead", 0.4, at * CFrame.new(0, ringY + 2.05, 0), if index % 2 == 0 then light else LAVENDER_COLOR)
	end
	ring.WorldPivot = base * CFrame.new(0, ringY, 0)
	ring.Parent = model

	-- the yarn ball on a little cup on top of the arm, its strand running down into the head
	makeColumn(model, partType .. "KnitCup", 2.4, armTop, armTop + 0.6, base, SEWING_LIGHT_COLOR)
	local yarnAt = base * CFrame.new(0, armTop + 2.1, 0)
	local yarn = Instance.new("Model")
	yarn.Name = partType .. "KnitYarn"
	makeBall(yarn, partType .. "KnitYarnBall", 3.4, yarnAt, color, Enum.Material.Fabric)
	for _, turn in { 0.5, -0.6, 1.4 } do
		local wrap = makeDecor(yarn, partType .. "KnitYarnWrap", Vector3.new(0.3, 3.5, 3.5), yarnAt * CFrame.Angles(0, turn, math.rad(70)), light, Enum.Material.Fabric)
		wrap.Shape = Enum.PartType.Cylinder
	end
	yarn.WorldPivot = yarnAt
	yarn.Parent = model
	local strand = base * CFrame.new(0.7, (armTop + 1.2 + armBottom) / 2, -2.25)
	makeDecor(model, partType .. "KnitStrand", Vector3.new(0.14, armTop + 1.2 - armBottom, 0.14), strand, color, Enum.Material.Fabric)

	-- the crank on the column's outer side (its -X): a wheel with a knob, turning about X
	local hub = column * CFrame.new(-KNIT_COLUMN / 2 - 0.35, DECK + 8.6, 0)
	local crank = Instance.new("Model")
	crank.Name = partType .. "KnitCrank"
	local wheel = makeDecor(crank, partType .. "KnitCrankWheel", Vector3.new(0.5, 3.2, 3.2), hub, LAVENDER_COLOR)
	wheel.Shape = Enum.PartType.Cylinder
	makeDecor(crank, partType .. "KnitCrankHandle", Vector3.new(1.2, 0.35, 0.35), hub * CFrame.new(-0.6, 1.1, 0), WHITE)
	makeBall(crank, partType .. "KnitCrankKnob", 0.8, hub * CFrame.new(-1.3, 1.1, 0), light)
	crank.WorldPivot = hub
	crank.Parent = model
end

-- Finishing stages (GDD §6), past the end of the belt at `spot` (on the floor). The
-- part named Ship is where ProductionVisuals plays the zone's finish and the coins
-- burst out; its top is level with the deck.

-- Toy Workshop: a trapdoor in a platform at the end of the belt. A toy box pops up out
-- of it, the brainrot jumps in, the lid slams and the box drops back down through it.
local function buildTrapdoor(model: Model, spot: CFrame)
	makePart(model, "ShipPlatform", Vector3.new(12, DECK, 12), spot * CFrame.new(0, DECK / 2, 0), GANTRY_COLOR)
	makeDecor(model, "ShipPlatformTrim", Vector3.new(12.3, 0.6, 12.3), spot * CFrame.new(0, DECK - 0.7, 0), CLAW_COLOR)
	makeDecor(model, "ShipPlatformFoot", Vector3.new(12.6, 0.5, 12.6), spot * CFrame.new(0, 0.25, 0), Color3.fromRGB(85, 45, 160))
	local deck = deckOf(spot)
	makePart(model, "TrapdoorFrame", Vector3.new(9.6, 0.4, 9.6), deck * CFrame.new(0, 0.2, 0), WHITE)
	local ship = makePart(model, "Ship", Vector3.new(8.4, 0.5, 8.4), deck * CFrame.new(0, 0.25, 0), CLAW_COLOR)
	makeDecor(model, "TrapdoorSeam", Vector3.new(8.4, 0.52, 0.25), deck * CFrame.new(0, 0.25, 0), Color3.fromRGB(150, 100, 30))
	for _, side in { -1, 1 } do
		makeDecor(model, "TrapdoorHandle", Vector3.new(2, 0.6, 0.4), deck * CFrame.new(0, 0.3, side * 1), Color3.fromRGB(150, 100, 30))
	end
	makeBillboard(ship, "📦 SHIPPING", Vector2.new(8, 2), 9, 80)
end

-- Plushie Sewing Room: a fluff machine, a glass dome on a cushy hot-pink base, a few
-- fluff balls waiting inside. The brainrot hops in, fluff swirls around it until it's
-- puffy, and it sinks into the base.
local FLUFF_DOME = 11 -- across: the brainrot puffs up inside it

local function buildFluffMachine(model: Model, spot: CFrame)
	makeColumn(model, "FluffFoot", FLUFF_DOME + 2, 0, 1, spot, LAVENDER_COLOR)
	local ship = makeColumn(model, "Ship", FLUFF_DOME + 1, 1, DECK, spot, SEWING_COLOR, Enum.Material.Fabric)
	ship.CanCollide = true
	ship.CanQuery = true
	makeColumn(model, "FluffTrim", FLUFF_DOME + 1.4, DECK - 0.6, DECK + 0.3, spot, PLUSH_GOLD, Enum.Material.Metal)
	local deck = deckOf(spot)
	for index, offset in { Vector3.new(-2.6, 0, 1.5), Vector3.new(2.3, 0, 2), Vector3.new(0.5, 0, -2.8), Vector3.new(-1.6, 0, -1.3), Vector3.new(3, 0, -0.8) } do
		local size = 1.4 + (index % 3) * 0.35
		makeBall(model, "FluffBall", size, deck * CFrame.new(offset + Vector3.new(0, 0.3 + size / 2, 0)), if index % 2 == 0 then WHITE else Color3.fromRGB(255, 225, 240), Enum.Material.Fabric)
	end
	local dome = makeBall(model, "FluffDome", FLUFF_DOME, deck * CFrame.new(0, 0.3, 0), Color3.fromRGB(205, 235, 255), Enum.Material.Glass)
	dome.Transparency = 0.7
	local top = FLUFF_DOME / 2 + 0.3 -- the dome's top, above the deck
	makeColumn(model, "FluffCap", 3.2, DECK + top - 0.4, DECK + top + 0.6, spot, SEWING_COLOR)
	makeBall(model, "FluffKnob", 2, deck * CFrame.new(0, top + 1.3, 0), WHITE, Enum.Material.Fabric)
	makeBillboard(ship, "☁️ SHIPPING", Vector2.new(8, 2), 11, 80)
end

-- Each zone's special upgrade (Station3, GDD §6) stands over the end of the belt at
-- `spot` (on the floor); ProductionVisuals plays it as the brainrot arrives. Its part
-- named Station3 is the machine's top.

-- Toy Workshop: the Toy Packer boxes the brainrot up in store packaging (a card back, a
-- clear plastic window) before it goes into the toy box.
local CARDBOARD_COLOR = Color3.fromRGB(215, 165, 110)
local SPECIAL_LIFT = 5 -- the special machines' tops, this much over the old 8 above the deck
local function buildPacker(model: Model, spot: CFrame, name: string)
	local deck = deckOf(spot) * CFrame.new(0, SPECIAL_LIFT, 0)
	local height = DECK + 8 + SPECIAL_LIFT
	for _, side in { -1, 1 } do
		makePart(model, "PackerTower", Vector3.new(2, height, 5.4), spot * CFrame.new(side * SIDE_X, height / 2, 0), CLAW_COLOR)
		makeDecor(model, "PackerStripe", Vector3.new(2.1, 1, 5.5), spot * CFrame.new(side * SIDE_X, DECK + 5.5 + SPECIAL_LIFT, 0), GANTRY_COLOR)
		makeDecor(model, "PackerStripe", Vector3.new(2.1, 0.5, 5.5), spot * CFrame.new(side * SIDE_X, DECK + 4.4 + SPECIAL_LIFT, 0), WHITE)
	end
	local top = makePart(model, "Station3", Vector3.new(17.6, 2.8, 6), deck * CFrame.new(0, 9.4, 0), GANTRY_COLOR)
	makePart(model, "Station3Glow", Vector3.new(13, 0.3, 4.6), deck * CFrame.new(0, 7.85, 0), WHITE, Enum.Material.Neon)
	-- flat boxes waiting on top, and a roll of tape
	for index, turn in { -0.08, 0.05, -0.02 } do
		makeDecor(model, "PackerCardboard", Vector3.new(6.4, 0.5, 4.4), deck * CFrame.new(-2, 10.55 + index * 0.5, 0) * CFrame.Angles(0, turn, 0), CARDBOARD_COLOR)
	end
	local tape = makeDecor(model, "PackerTape", Vector3.new(1.2, 2.4, 2.4), deck * CFrame.new(4.5, 12, 0) * CFrame.Angles(0, math.pi / 2, 0), Color3.fromRGB(255, 225, 120))
	tape.Shape = Enum.PartType.Cylinder
	makeBillboard(top, string.upper(name), Vector2.new(8, 1.5), 3.6, 80)
end

-- A ribbon bow (`at`: its knot, -Z its front), `size` across one loop.
local function buildRibbonBow(model: Model, at: CFrame, size: number, color: Color3)
	makeBall(model, "RibbonKnot", size * 0.45, at, color, Enum.Material.Fabric)
	for _, side in { -1, 1 } do
		local loop = makeDecor(model, "RibbonLoop", Vector3.new(size * 0.22, size, size), at * CFrame.new(side * size * 0.55, size * 0.1, 0) * CFrame.Angles(0, math.pi / 2, side * math.rad(-20)), color, Enum.Material.Fabric)
		loop.Shape = Enum.PartType.Cylinder
		makeDecor(model, "RibbonTail", Vector3.new(size * 0.24, size * 0.75, size * 0.1), at * CFrame.new(side * size * 0.25, -size * 0.4, 0) * CFrame.Angles(0, 0, side * math.rad(25)), color:Lerp(WHITE, 0.2), Enum.Material.Fabric)
	end
end

-- Plushie Sewing Room: the Bow Tier ties a big ribbon bow on the brainrot's head before
-- it goes into the fluff machine. A giant bow sits on its arch, with the ribbon spool
-- behind it.
local function buildBowTier(model: Model, spot: CFrame, name: string)
	local deck = deckOf(spot) * CFrame.new(0, SPECIAL_LIFT, 0)
	local height = DECK + 8 + SPECIAL_LIFT
	for _, side in { -1, 1 } do
		makeColumn(model, "BowLeg", 1.8, 0, height, spot * CFrame.new(side * SIDE_X, 0, 0), LAVENDER_COLOR)
		makeColumn(model, "BowLegStripe", 2, DECK + 3, DECK + 3.6, spot * CFrame.new(side * SIDE_X, 0, 0), WHITE)
		makeColumn(model, "BowLegStripe", 2, DECK + 8, DECK + 8.6, spot * CFrame.new(side * SIDE_X, 0, 0), WHITE)
	end
	local top = makePart(model, "Station3", Vector3.new(17, 1.8, 3.8), deck * CFrame.new(0, 8.9, 0), LAVENDER_COLOR)
	makeDecor(model, "Station3Stripe", Vector3.new(17.1, 0.45, 3.9), deck * CFrame.new(0, 8.9, 0), WHITE)
	makePart(model, "Station3Glow", Vector3.new(13, 0.3, 3), deck * CFrame.new(0, 7.85, 0), WHITE, Enum.Material.Neon)
	-- the ribbon spool on top (pink ribbon between white rims), trailing down the back
	local spool = makeDecor(model, "BowSpool", Vector3.new(6, 2.6, 2.6), deck * CFrame.new(0, 11.1, 0.4), FLUFF_PINK, Enum.Material.Fabric)
	spool.Shape = Enum.PartType.Cylinder
	for _, side in { -1, 1 } do
		local rim = makeDecor(model, "BowSpoolRim", Vector3.new(0.4, 3.6, 3.6), deck * CFrame.new(side * 3.1, 11.1, 0.4), WHITE)
		rim.Shape = Enum.PartType.Cylinder
	end
	makeDecor(model, "BowRibbon", Vector3.new(1.6, 2.6, 0.1), deck * CFrame.new(0, 9.4, 1.95), FLUFF_PINK, Enum.Material.Fabric)
	-- and a giant bow on the arch's front
	buildRibbonBow(model, deck * CFrame.new(0, 9.9, -2.2), 3.4, SEWING_COLOR)
	makeBillboard(top, string.upper(name), Vector2.new(8, 1.5), 5.4, 80)
end

-- The upgrade arches over the belt (`spot`: on the floor under the arch). The Toy
-- Workshop's are plain colored arches (Paint Booth, Glitter Blaster); the Plushie
-- room's have lavender legs topped with yarn balls and, on the beam, the Dye Bath's
-- bucket of fabric dye or the Sequin Shower's spinning disco ball.
local ARCH_X = 7 -- its legs, from the belt's middle
local ARCH_TOP = 10.5 -- the beam's middle, above the deck (clear of the tallest brainrot)

local function buildArch(model: Model, spot: CFrame, item: TycoonItems.Item, color: Color3, legColor: Color3, material: Enum.Material?): BasePart
	local deck = deckOf(spot)
	local legHeight = DECK + ARCH_TOP - 0.75
	for _, side in { -1, 1 } do
		local leg = makePart(model, item.Key .. (if side < 0 then "LegLeft" else "LegRight"), Vector3.new(1.4, legHeight, 1.4), spot * CFrame.new(side * ARCH_X, legHeight / 2, 0), legColor)
		leg.Material = material or Enum.Material.SmoothPlastic
		makeDecor(model, item.Key .. "LegFoot", Vector3.new(2.2, 0.5, 2.2), spot * CFrame.new(side * ARCH_X, 0.25, 0), legColor:Lerp(Color3.new(0, 0, 0), 0.2))
	end
	local top = makePart(model, item.Key, Vector3.new(ARCH_X * 2 + 1.4, 1.5, 3), deck * CFrame.new(0, ARCH_TOP, 0), color, material)
	makePart(model, item.Key .. "Glow", Vector3.new(ARCH_X * 2 - 2, 0.3, 2.4), deck * CFrame.new(0, ARCH_TOP - 0.9, 0), WHITE, Enum.Material.Neon)
	return top
end

local function buildPlushieArch(model: Model, spot: CFrame, item: TycoonItems.Item)
	local deck = deckOf(spot)
	local top = buildArch(model, spot, item, SEWING_COLOR, LAVENDER_COLOR, Enum.Material.Fabric)
	makeDecor(model, item.Key .. "Stripe", Vector3.new(ARCH_X * 2 + 1.5, 0.4, 3.1), top.CFrame, WHITE)
	for _, side in { -1, 1 } do
		makeBall(model, item.Key .. "Yarn", 2, deck * CFrame.new(side * ARCH_X, ARCH_TOP + 1.7, 0), THREAD_COLORS[if side < 0 then 1 else 2], Enum.Material.Fabric)
	end
	if item.Key == "Station1" then
		makeColumn(model, "DyeBucket", 3.8, DECK + ARCH_TOP + 0.75, DECK + ARCH_TOP + 3.4, spot, Color3.fromRGB(200, 215, 235), Enum.Material.Metal)
		makeColumn(model, "DyeBucketRim", 4.1, DECK + ARCH_TOP + 3.1, DECK + ARCH_TOP + 3.5, spot, FLUFF_PINK)
		makeColumn(model, "Dye", 3.4, DECK + ARCH_TOP + 3.4, DECK + ARCH_TOP + 3.55, spot, Color3.fromRGB(150, 110, 255), Enum.Material.Neon)
	else
		local ball = Instance.new("Model")
		ball.Name = "DiscoBall"
		local center = deck * CFrame.new(0, ARCH_TOP + 2.4, 0)
		local disco = makeBall(ball, "DiscoBall", 3, center, Color3.fromRGB(225, 230, 245), Enum.Material.Foil)
		disco.Reflectance = 0.4
		for index = 0, 5 do
			local angle = index * math.pi / 3
			makeDecor(ball, "DiscoTile", Vector3.new(0.6, 0.6, 0.1), center * CFrame.new(math.cos(angle) * 1.45, (index % 2 - 0.5) * 0.8, math.sin(angle) * 1.45) * CFrame.Angles(0, -angle - math.pi / 2, 0), Color3.fromRGB(255, 180, 230), Enum.Material.Neon)
		end
		-- it spins about its upright axis (Atmosphere turns Spinners about their pivot's Z)
		ball.WorldPivot = center * CFrame.Angles(math.pi / 2, 0, 0)
		ball:SetAttribute("Speed", 1.2)
		CollectionService:AddTag(ball, "Spinner")
		ball.Parent = model
	end
	makeBillboard(top, string.upper(item.Name), Vector2.new(8, 1.5), if item.Key == "Station1" then 4.2 else 4.6, 80)
end

-- Clay Studio -------------------------------------------------------------------------
-- A stop-motion clay studio (GDD §10): terracotta machines with teal trims, white
-- cartoon gloves, a film camera flashing at every step, and a kiln to bake the
-- brainrots in.

local CLAY_COLOR = Color3.fromRGB(225, 120, 75)
local CLAY_LIGHT_COLOR = Color3.fromRGB(245, 180, 125)
local CLAY_DARK_COLOR = Color3.fromRGB(150, 75, 50)
local CLAY_TEAL = Color3.fromRGB(60, 205, 195)
local CAMERA_BLACK = Color3.fromRGB(45, 40, 55)
local KILN_COLOR = Color3.fromRGB(200, 95, 60)
local SMOKE_TEXTURE = "rbxasset://textures/particles/smoke_main.dds"

-- Droppers: play-dough presses (GDD §6, §16.18). A terracotta column beside the belt
-- (teal stripes, a crank, a neon bracelet naming the part) holds an arm over the belt
-- with a drum of clay in the part's color; its plunger (PressPlunger) pushes down and
-- the part is squeezed out of the nozzle underneath (the Dropper, attributes Knitting,
-- so it grows down out of the mouth like a knitted part, and Press). ProductionVisuals
-- moves the plunger and turns the crank (KnitCrank).
local PRESS_TRAVEL = 2.6 -- how far the plunger pushes down

local function buildClayPress(model: Model, base: CFrame, partType: string, color: Color3)
	local column = base * CFrame.new(KNIT_X, 0, 0)
	local armBottom = DECK + KNIT_ARM
	local armTop = armBottom + 3
	makeColumn(model, partType .. "PressFoot", 6.4, 0, 1.4, column, CLAY_DARK_COLOR)
	local body = makeColumn(model, partType .. "PressColumn", KNIT_COLUMN, 1.4, armTop, column, CLAY_COLOR)
	body.CanCollide = true
	for _, y in { 2.6, armBottom - 1.6 } do
		makeColumn(model, partType .. "PressStripe", KNIT_COLUMN + 0.3, y, y + 0.7, column, CLAY_TEAL)
	end
	buildBadge(model, partType, column * CFrame.new(0, DECK + 4.6, 0), color, 0.62)

	-- the arm over the belt, a teal stripe along it
	local armFrom, armTo = KNIT_X - KNIT_COLUMN / 2, KNIT_HEAD / 2
	local arm = makeDecor(model, partType .. "PressArm", Vector3.new(armTo - armFrom, 3, 4), base * CFrame.new((armFrom + armTo) / 2, armBottom + 1.5, 0), CLAY_COLOR)
	makeDecor(model, partType .. "PressArmStripe", Vector3.new(armTo - armFrom - 0.2, 0.55, 4.1), arm.CFrame, CLAY_TEAL)

	-- the press under the arm's end: a drum of clay in a cream frame, the nozzle below
	local nozzleBottom = armBottom - KNIT_HEAD_HEIGHT
	makeColumn(model, partType .. "PressFrame", KNIT_HEAD + 0.6, armBottom - 0.6, armBottom, base, CLAY_LIGHT_COLOR)
	makeColumn(model, partType .. "PressDrum", KNIT_HEAD, nozzleBottom + 1.4, armBottom - 0.6, base, color, Enum.Material.Sand)
	makeColumn(model, partType .. "PressFrame", KNIT_HEAD + 0.6, nozzleBottom + 1.2, nozzleBottom + 1.8, base, CLAY_LIGHT_COLOR)
	local nozzle = makeColumn(model, partType .. "Dropper", 3, nozzleBottom, nozzleBottom + 1.4, base, CLAY_DARK_COLOR)
	nozzle:SetAttribute("Knitting", true)
	nozzle:SetAttribute("Press", true)
	nozzle:SetAttribute("PartColor", color)
	makeColumn(model, partType .. "DropperRim", 3.4, nozzleBottom - 0.15, nozzleBottom + 0.25, base, CLAY_TEAL, Enum.Material.Neon)
	makeColumn(model, partType .. "DropperMouth", 2.2, nozzleBottom - 0.2, nozzleBottom - 0.1, base, Color3.fromRGB(35, 25, 45))

	-- the plunger: a chrome rod down through the arm into the drum, a teal handle on top
	local plunger = Instance.new("Model")
	plunger.Name = partType .. "PressPlunger"
	makeColumn(plunger, partType .. "PressRod", 1, armBottom - 1.2, armTop + 4, base, CHROME_COLOR, Enum.Material.Metal)
	makeColumn(plunger, partType .. "PressHandle", 3.6, armTop + 4, armTop + 4.9, base, CLAY_TEAL)
	makeBall(plunger, partType .. "PressKnob", 1.6, base * CFrame.new(0, armTop + 5.5, 0), WHITE)
	plunger.WorldPivot = base * CFrame.new(0, armTop, 0)
	plunger:SetAttribute("Travel", PRESS_TRAVEL)
	plunger.Parent = model

	-- the crank on the column's outer side, turning about X
	local hub = column * CFrame.new(-KNIT_COLUMN / 2 - 0.35, DECK + 8.6, 0)
	local crank = Instance.new("Model")
	crank.Name = partType .. "KnitCrank"
	local wheel = makeDecor(crank, partType .. "PressCrankWheel", Vector3.new(0.5, 3.2, 3.2), hub, CLAY_TEAL)
	wheel.Shape = Enum.PartType.Cylinder
	makeDecor(crank, partType .. "PressCrankHandle", Vector3.new(1.2, 0.35, 0.35), hub * CFrame.new(-0.6, 1.1, 0), WHITE)
	makeBall(crank, partType .. "PressCrankKnob", 0.8, hub * CFrame.new(-1.3, 1.1, 0), CLAY_LIGHT_COLOR)
	crank.WorldPivot = hub
	crank.Parent = model
end

-- The Assembler: two big white cartoon gloves hang from the gantry on rods either side
-- of the pad (HandLeft, HandRight: pivoted at the palm's middle, palm toward the pad
-- (-Z), fingers down; HandLeftRod, HandRightRod), and a film camera on a tripod by the
-- pad pops its flash bulb (ClayFlash) at every step: stop-motion!
local GLOVE_X = 5.8 -- the palms at rest, from the pad
local GLOVE_Y = 6 -- above the deck
local GLOVE_WHITE = Color3.fromRGB(250, 250, 245)
local GLOVE_LINE = Color3.fromRGB(70, 60, 80)

local function buildGlove(parent: Model, name: string, palm: CFrame)
	local glove = Instance.new("Model")
	glove.Name = name
	makeDecor(glove, "Palm", Vector3.new(2.8, 2.6, 1.3), palm, GLOVE_WHITE)
	for index, x in { -1.05, -0.35, 0.35, 1.05 } do
		makeDecor(glove, "Finger", Vector3.new(0.62, 1.5, 0.8), palm * CFrame.new(x, -1.95 + (index % 2) * 0.15, 0), GLOVE_WHITE)
		makeBall(glove, "Fingertip", 0.66, palm * CFrame.new(x, -2.75 + (index % 2) * 0.15, 0), GLOVE_WHITE)
	end
	makeBall(glove, "Thumb", 1.1, palm * CFrame.new(1.6, -0.3, -0.35), GLOVE_WHITE)
	-- the cuff at the wrist, and three stitched lines on the back of the hand
	local cuff = makeDecor(glove, "Cuff", Vector3.new(1.1, 3.2, 3.2), palm * CFrame.new(0, 1.9, 0) * CFrame.Angles(0, 0, math.pi / 2), CLAY_TEAL)
	cuff.Shape = Enum.PartType.Cylinder
	for _, x in { -0.6, 0, 0.6 } do
		makeDecor(glove, "Stitch", Vector3.new(0.14, 1.6, 0.05), palm * CFrame.new(x, 0.2, 0.66), GLOVE_LINE)
	end
	glove.WorldPivot = palm
	glove.Parent = parent
end

local function buildClayHands(parent: Model, origin: CFrame)
	local deck = deckOf(origin)
	local beam = DECK + GANTRY_BOTTOM -- the gantry's underside, above the floor
	for _, side in { -1, 1 } do
		local name = if side < 0 then "HandLeft" else "HandRight"
		local position = (deck * CFrame.new(side * GLOVE_X, GLOVE_Y, 0)).Position
		local palm = CFrame.lookAt(position, (deck * CFrame.new(0, GLOVE_Y, 0)).Position) -- -Z toward the pad
		buildGlove(parent, name, palm)
		local wrist = (palm * CFrame.new(0, 2.5, 0)).Position
		local top = (origin * CFrame.new(side * GLOVE_X, beam, 0)).Position
		local rod = makePart(parent, name .. "Rod", Vector3.new(0.45, (top - wrist).Magnitude, 0.45), CFrame.new((top + wrist) / 2) * origin.Rotation, CHROME_COLOR, Enum.Material.Metal)
		rod.CanCollide = false
	end
	-- the stop-motion camera on its tripod, by the pad's front-left, looking at it
	local foot = origin * CFrame.new(-10.4, 0, -8)
	local head = (foot * CFrame.new(0, DECK + 5.5, 0)).Position
	for index = 0, 2 do
		local angle = index / 3 * math.pi * 2
		local toe = (foot * CFrame.new(math.cos(angle) * 1.8, 0, math.sin(angle) * 1.8)).Position
		local leg = makeDecor(parent, "TripodLeg", Vector3.new(0.3, 0.3, (head - toe).Magnitude), CFrame.lookAt((head + toe) / 2, head), CAMERA_BLACK)
		leg.CanCollide = false
	end
	local aim = CFrame.lookAt(head + Vector3.new(0, 1.2, 0), (deckOf(origin) * CFrame.new(0, 3, 0)).Position)
	makeDecor(parent, "ClayCamera", Vector3.new(2.6, 2, 2.2), aim, CAMERA_BLACK)
	local lens = makeDecor(parent, "ClayCameraLens", Vector3.new(1.2, 1.4, 1.4), aim * CFrame.new(0, 0, -1.6) * CFrame.Angles(0, math.pi / 2, 0), Color3.fromRGB(90, 85, 100))
	lens.Shape = Enum.PartType.Cylinder
	makeDecor(parent, "ClayCameraGlass", Vector3.new(0.1, 1.1, 1.1), aim * CFrame.new(0, 0, -2.25) * CFrame.Angles(0, math.pi / 2, 0), Color3.fromRGB(120, 200, 255), Enum.Material.Glass).Shape = Enum.PartType.Cylinder
	for _, z in { -0.5, 0.6 } do
		local reel = makeDecor(parent, "ClayCameraReel", Vector3.new(0.3, 1.6, 1.6), aim * CFrame.new(0, 1.6, z), CAMERA_BLACK)
		reel.Shape = Enum.PartType.Cylinder
	end
	makeDecor(parent, "ClayFlashMount", Vector3.new(0.3, 1.2, 0.3), aim * CFrame.new(1, 1.4, 0), CHROME_COLOR)
	makeBall(parent, "ClayFlash", 0.9, aim * CFrame.new(1, 2.2, 0), Color3.fromRGB(255, 245, 210), Enum.Material.Neon)
end

-- Upgrade stations: terracotta arches. The Color Squish (Station1) wears a row of
-- clay balls; the Sparkle Glaze (Station2) a pot of glossy glaze dripping off the beam.
local function buildClayArch(model: Model, spot: CFrame, item: TycoonItems.Item)
	local deck = deckOf(spot)
	local top = buildArch(model, spot, item, CLAY_COLOR, CLAY_DARK_COLOR)
	makeDecor(model, item.Key .. "Stripe", Vector3.new(ARCH_X * 2 + 1.5, 0.4, 3.1), top.CFrame, CLAY_TEAL)
	if item.Key == "Station1" then
		for index, x in { -4, -1.3, 1.3, 4 } do
			makeBall(model, "ClayBlob", 2.2 - (index % 2) * 0.4, deck * CFrame.new(x, ARCH_TOP + 1.8 - (index % 2) * 0.2, 0), ({ Color3.fromRGB(255, 100, 120), Color3.fromRGB(255, 200, 60), Color3.fromRGB(90, 190, 255), Color3.fromRGB(130, 220, 110) })[index], Enum.Material.Sand)
		end
	else
		makeColumn(model, "GlazePot", 3.6, DECK + ARCH_TOP + 0.75, DECK + ARCH_TOP + 3.2, spot, CLAY_LIGHT_COLOR)
		makeColumn(model, "Glaze", 3.2, DECK + ARCH_TOP + 3.2, DECK + ARCH_TOP + 3.35, spot, Color3.fromRGB(240, 250, 255), Enum.Material.Glass)
		for _, x in { -5, -2.5, 2.5, 5 } do
			local drip = makeDecor(model, "GlazeDrip", Vector3.new(0.5, 1.4, 0.5), deck * CFrame.new(x, ARCH_TOP - 1.3, -1.6), Color3.fromRGB(235, 245, 255), Enum.Material.Glass)
			drip.Transparency = 0.2
		end
	end
	makeBillboard(top, string.upper(item.Name), Vector2.new(8, 1.5), 3.6, 80)
end

-- Special: the Stop-Motion Camera, a big film camera on a crossbar over the end of the
-- belt (Station3), its lens pointing down at the brainrot, film reels turning on top,
-- a flash umbrella beside it.
local function buildStopMotionCamera(model: Model, spot: CFrame, name: string)
	local deck = deckOf(spot) * CFrame.new(0, SPECIAL_LIFT, 0)
	local height = DECK + 8 + SPECIAL_LIFT
	for _, side in { -1, 1 } do
		makeColumn(model, "CameraLeg", 1.8, 0, height, spot * CFrame.new(side * SIDE_X, 0, 0), CLAY_DARK_COLOR)
		makeColumn(model, "CameraLegStripe", 2, DECK + 3, DECK + 3.6, spot * CFrame.new(side * SIDE_X, 0, 0), CLAY_TEAL)
		makeColumn(model, "CameraLegStripe", 2, DECK + 8, DECK + 8.6, spot * CFrame.new(side * SIDE_X, 0, 0), CLAY_TEAL)
	end
	local top = makePart(model, "Station3", Vector3.new(17, 1.8, 3.8), deck * CFrame.new(0, 8.9, 0), CLAY_COLOR)
	makeDecor(model, "Station3Stripe", Vector3.new(17.1, 0.45, 3.9), deck * CFrame.new(0, 8.9, 0), CLAY_TEAL)
	makePart(model, "Station3Glow", Vector3.new(13, 0.3, 3), deck * CFrame.new(0, 7.85, 0), WHITE, Enum.Material.Neon)
	-- the camera on the crossbar, its lens down through it
	makeDecor(model, "SnapCamera", Vector3.new(6, 3.4, 4), deck * CFrame.new(0, 11.5, 0), CAMERA_BLACK)
	makeDecor(model, "SnapCameraTrim", Vector3.new(6.1, 0.5, 4.1), deck * CFrame.new(0, 10.2, 0), CLAY_TEAL)
	makeColumn(model, "SnapLens", 2.8, DECK + SPECIAL_LIFT + 6.6, DECK + SPECIAL_LIFT + 8, spot, Color3.fromRGB(90, 85, 100))
	makeColumn(model, "SnapLensGlass", 2.2, DECK + SPECIAL_LIFT + 6.5, DECK + SPECIAL_LIFT + 6.6, spot, Color3.fromRGB(120, 200, 255), Enum.Material.Glass)
	for _, x in { -1.5, 1.5 } do
		local reel = Instance.new("Model")
		reel.Name = "SnapReel"
		local center = deck * CFrame.new(x, 14.6, 0)
		local disc = makeDecor(reel, "SnapReelDisc", Vector3.new(0.4, 3, 3), center, CAMERA_BLACK)
		disc.Shape = Enum.PartType.Cylinder
		for spoke = 0, 2 do
			makeDecor(reel, "SnapReelHole", Vector3.new(0.45, 0.7, 0.7), center * CFrame.Angles(spoke * math.pi * 2 / 3, 0, 0) * CFrame.new(0, 0.8, 0), CLAY_TEAL).Shape = Enum.PartType.Cylinder
		end
		-- (Atmosphere turns Spinners about their pivot's Z: the reel's axle is X)
		reel.WorldPivot = center * CFrame.Angles(0, math.pi / 2, 0)
		reel:SetAttribute("Speed", if x < 0 then 2 else -2)
		CollectionService:AddTag(reel, "Spinner")
		reel.Parent = model
	end
	-- the flash umbrella on a pole beside the camera
	local pole = deck * CFrame.new(4.8, 9.8, 0)
	makeDecor(model, "UmbrellaPole", Vector3.new(0.3, 4, 0.3), pole * CFrame.new(0, 2, 0), CHROME_COLOR)
	local umbrella = makeDecor(model, "FlashUmbrella", Vector3.new(0.3, 4, 4), pole * CFrame.new(0.6, 4.2, 0) * CFrame.Angles(0, 0, math.rad(-60)), WHITE)
	umbrella.Shape = Enum.PartType.Cylinder
	makeBall(model, "Station3Flash", 0.9, pole * CFrame.new(0, 4, 0), Color3.fromRGB(255, 245, 210), Enum.Material.Neon)
	makeBillboard(top, string.upper(name), Vector2.new(8, 1.5), 7.5, 80)
end

-- Delivery: a brick kiln, a dome on a terracotta base with its glowing door toward the
-- belt (KilnGlow) and a chimney puffing smoke. The base is the Ship (its top level with
-- the deck): the brainrot hops in through the door and comes out baked.
local KILN = 10 -- the dome, across

local function buildKiln(model: Model, spot: CFrame)
	makeColumn(model, "KilnFoot", KILN + 3, 0, 1, spot, CLAY_DARK_COLOR)
	local ship = makeColumn(model, "Ship", KILN + 2, 1, DECK, spot, CLAY_COLOR)
	ship.CanCollide = true
	ship.CanQuery = true
	makeColumn(model, "KilnTrim", KILN + 2.4, DECK - 0.6, DECK + 0.3, spot, CLAY_TEAL)
	local deck = deckOf(spot)
	makeBall(model, "KilnDome", KILN, deck * CFrame.new(0, 0.3, 0), KILN_COLOR, Enum.Material.Brick)
	-- the door: a glowing arch facing the belt (+Z), in a cream frame
	local door = deck * CFrame.new(0, 2.4, KILN / 2 - 0.35)
	makeDecor(model, "KilnDoorFrame", Vector3.new(0.6, 5.4, 5.4), door * CFrame.Angles(0, math.pi / 2, 0), CLAY_LIGHT_COLOR).Shape = Enum.PartType.Cylinder
	local glow = makeDecor(model, "KilnGlow", Vector3.new(0.7, 4.4, 4.4), door * CFrame.new(0, 0, 0.05) * CFrame.Angles(0, math.pi / 2, 0), Color3.fromRGB(255, 140, 40), Enum.Material.Neon)
	glow.Shape = Enum.PartType.Cylinder
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 150, 60)
	light.Range = 12
	light.Brightness = 1.2
	light.Parent = glow
	-- the chimney, smoking
	makeColumn(model, "KilnChimney", 2.4, DECK + KILN / 2 - 1, DECK + KILN / 2 + 4.5, spot * CFrame.new(-1.5, 0, -1), KILN_COLOR, Enum.Material.Brick)
	local cap = makeColumn(model, "KilnChimneyCap", 3, DECK + KILN / 2 + 4.5, DECK + KILN / 2 + 5.2, spot * CFrame.new(-1.5, 0, -1), CLAY_DARK_COLOR)
	local smoke = Instance.new("ParticleEmitter")
	smoke.Texture = SMOKE_TEXTURE
	smoke.Color = ColorSequence.new(Color3.fromRGB(235, 230, 240))
	smoke.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 1) })
	smoke.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 3) })
	smoke.Lifetime = NumberRange.new(2, 3)
	smoke.Rate = 2
	smoke.Speed = NumberRange.new(2, 3)
	smoke.EmissionDirection = Enum.NormalId.Right -- the cap is a cylinder on its side: its X is up
	smoke.Parent = cap
	makeBillboard(ship, "🔥 SHIPPING", Vector2.new(8, 2), KILN / 2 + 9, 80)
end

-- The line's tablet (GDD §6): a little stand beside the Assembler holding a tablet,
-- themed per zone. Its screen (TabletScreen, PromptAnchor) carries the "Configure
-- line" prompt; UIController flies the camera onto it and opens the Line menu there.
local TABLET_SPOT = Vector3.new(10, 0, -2.5) -- from the line's origin, by the button path
local TABLET_FACING = Vector3.new(math.cos(math.rad(25)), 0, -math.sin(math.rad(25))) -- toward the path, a little to the front
local TABLET_SCREEN = Vector2.new(3.2, 2.4)
local TABLET_TILT = math.rad(30) -- leaning back, screen up toward you
local SCREEN_COLOR = Color3.fromRGB(28, 22, 48)

-- The screen's idle picture: a gear and the line's number in neon.
local function tabletScreen(screen: BasePart, lineIndex: number, color: Color3)
	local gui = Instance.new("SurfaceGui")
	gui.Name = "Idle"
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.LightInfluence = 0
	gui.Brightness = 2
	gui.Parent = screen
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(0.9, 0.8)
	label.Position = UDim2.fromScale(0.05, 0.1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = color:Lerp(Color3.new(1, 1, 1), 0.6)
	label.Text = `⚙️\nLINE {lineIndex}`
	label.Parent = gui
	local glow = Instance.new("UIStroke")
	glow.Thickness = 3
	glow.Color = color
	glow.Parent = label
end

local function buildTablet(model: Model, origin: CFrame, item: TycoonItems.Item, lineIndex: number)
	local spot = origin * CFrame.lookAt(TABLET_SPOT, TABLET_SPOT + TABLET_FACING) -- its -Z faces you
	local plushie = item.Zone == "PlushieRoom"
	local clay = item.Zone == "ClayStudio"
	local frameColor = if plushie then SEWING_COLOR elseif clay then CLAY_COLOR else GANTRY_COLOR
	local glowColor = if plushie then FLUFF_PINK elseif clay then CLAY_TEAL else Color3.fromRGB(255, 220, 70)
	if clay then
		-- a big clay pot for a stand
		makeColumn(model, "TabletPotFoot", 2.4, 0, 0.6, spot, CLAY_DARK_COLOR)
		local pot = makeBall(model, "TabletPot", 3, spot * CFrame.new(0, 2, 0), CLAY_COLOR, Enum.Material.Sand)
		pot.CanCollide = true
		makeColumn(model, "TabletPotNeck", 1.6, 3.2, 4, spot, CLAY_LIGHT_COLOR)
		makeColumn(model, "TabletPotStripe", 3.1, 1.8, 2.2, spot, CLAY_TEAL)
	elseif plushie then
		-- a big thread spool with chrome ends for a stand, on a violet foot
		makeColumn(model, "TabletFoot", 2.6, 0, 0.7, spot, LAVENDER_COLOR)
		makeColumn(model, "TabletSpoolEnd", 2, 0.7, 1.1, spot, CHROME_COLOR, Enum.Material.Metal)
		local thread = makeColumn(model, "TabletSpool", 1.4, 1.1, 3.4, spot, THREAD_COLORS[1], Enum.Material.Fabric)
		thread.CanCollide = true
		makeColumn(model, "TabletSpoolEnd", 2, 3.4, 3.8, spot, CHROME_COLOR, Enum.Material.Metal)
	else
		-- two toy blocks stacked up
		makePart(model, "TabletBase", Vector3.new(2.2, 0.5, 2.2), spot * CFrame.new(0, 0.25, 0), frameColor)
		makePart(model, "TabletBlock", Vector3.new(1.6, 1.6, 1.6), spot * CFrame.new(0, 1.3, 0), Color3.fromRGB(255, 90, 110))
		makePart(model, "TabletBlock", Vector3.new(1.5, 1.5, 1.5), spot * CFrame.new(0, 2.85, 0) * CFrame.Angles(0, math.rad(20), 0), CLAW_COLOR)
		makeDecor(model, "TabletMount", Vector3.new(0.8, 0.5, 0.8), spot * CFrame.new(0, 3.85, 0), METAL_COLOR)
	end
	local tablet = spot * CFrame.new(0, 4.9, 0) * CFrame.Angles(TABLET_TILT, 0, 0)
	makeDecor(model, "TabletBody", Vector3.new(TABLET_SCREEN.X + 0.6, TABLET_SCREEN.Y + 0.6, 0.35), tablet, frameColor)
	local screen = makeDecor(model, "TabletScreen", Vector3.new(TABLET_SCREEN.X, TABLET_SCREEN.Y, 0.1), tablet * CFrame.new(0, 0, -0.2), SCREEN_COLOR)
	screen.CanQuery = true -- the prompt sits on it
	screen:SetAttribute("PromptAnchor", true)
	tabletScreen(screen, lineIndex, glowColor)
	makeBall(model, "TabletButton", 0.3, tablet * CFrame.new(0, -TABLET_SCREEN.Y / 2 - 0.15, -0.2), glowColor, Enum.Material.Neon)
end

local BUILDERS: { [string]: (model: Model, origin: CFrame, item: TycoonItems.Item) -> () } = {
	Line = function(model, origin, item)
		local colors = GANTRY_COLORS[item.Zone] or GANTRY_COLORS.ToyWorkshop
		buildTablet(model, origin, item, TycoonItems.LinesById[item.LineId].Index)
		buildConveyor(model, origin, colors)
		buildGantry(model, origin, colors)
		if item.Zone == "PlushieRoom" then
			buildSewingMachine(model, origin)
		elseif item.Zone == "ClayStudio" then
			buildClayHands(model, origin)
		else
			buildClaw(model, origin)
			buildPusher(model, origin, -1)
			buildPusher(model, origin, 1)
		end

		-- Shipping: past the end of the belt, the zone's finishing stage packs the
		-- brainrot up and sends it off (ProductionVisuals plays it).
		local spot = origin * CFrame.new(0, 0, SHIP_Z)
		if item.Zone == "PlushieRoom" then
			buildFluffMachine(model, spot)
		elseif item.Zone == "ClayStudio" then
			buildKiln(model, spot)
		else
			buildTrapdoor(model, spot)
		end
	end,

	Dropper = function(model, origin, item)
		local partType = item.PartType :: string
		local base = origin * CFrame.new(0, 0, DROPPER_Z[partType])
		if item.Zone == "PlushieRoom" then
			buildKnittingMachine(model, base, partType, PART_COLORS[partType])
		elseif item.Zone == "ClayStudio" then
			buildClayPress(model, base, partType, PART_COLORS[partType])
		else
			buildChute(model, base, partType, PART_COLORS[partType])
		end
	end,

	-- A glowing turbo stripe along the belt.
	Speed = function(model, origin, item)
		local length = BELT_TO - BELT_FROM - 2
		makePart(model, item.Key, Vector3.new(0.8, 0.1, length), origin * CFrame.new(SPEED_X[item.Key], DECK + 0.05, (BELT_TO + BELT_FROM) / 2), Color3.fromRGB(255, 230, 60), Enum.Material.Neon)
	end,

	-- An arch over the belt that brainrots ride through, or the zone's special machine.
	Station = function(model, origin, item)
		local spot = origin * CFrame.new(0, 0, STATION_Z[item.Key])
		if item.Key == "Station3" then
			if item.Zone == "PlushieRoom" then
				buildBowTier(model, spot, item.Name)
			elseif item.Zone == "ClayStudio" then
				buildStopMotionCamera(model, spot, item.Name)
			else
				buildPacker(model, spot, item.Name)
			end
		elseif item.Zone == "PlushieRoom" then
			buildPlushieArch(model, spot, item)
		elseif item.Zone == "ClayStudio" then
			buildClayArch(model, spot, item)
		else
			local color = STATION_COLORS[item.Key]
			local top = buildArch(model, spot, item, color, color)
			makeBillboard(top, string.upper(item.Name), Vector2.new(8, 1.5), 2, 80)
		end
	end,
}

-- Line upgrade tracks (Config/LineUpgrades) ------------------------------------------
-- Each track's highest level is built into a Model of its own beside the line
-- ({lineId}_Up{Track}), replaced when the next level is bought, so TycoonFX pops it in
-- with a golden flash. The look climbs in tiers: cool neon (levels 1-3), hot pink with
-- gold (4-6), gold with sparkles (7-9), and at 10 the lights chase in candy colors
-- (Atmosphere's Marquee).

local TRACK_GOLD = Color3.fromRGB(255, 200, 50)
local TRACK_TIER_COLORS = {
	Color3.fromRGB(110, 230, 255),
	Color3.fromRGB(255, 110, 220),
	TRACK_GOLD,
	TRACK_GOLD,
}
local SPARKLE_TEXTURE = "rbxasset://textures/particles/sparkles_main.dds"

local function trackTier(level: number): number
	return if level >= 10 then 4 elseif level >= 7 then 3 elseif level >= 4 then 2 else 1
end

-- A glowing bulb; at the top tier its light chases along its string (Marquee, by index).
local function trackBulb(parent: Instance, at: CFrame, size: number, tier: number, index: number): Part
	local bulb = makeBall(parent, "TrackBulb", size, at, TRACK_TIER_COLORS[tier], Enum.Material.Neon)
	bulb.CastShadow = false
	if tier >= 4 then
		bulb:SetAttribute("Index", index)
		CollectionService:AddTag(bulb, "Marquee")
	end
	return bulb
end

-- Sparkles drifting off an invisible box `size` big at `at`.
local function trackSparkles(parent: Instance, at: CFrame, size: Vector3, rate: number)
	local source = makeDecor(parent, "TrackSparkles", size, at, WHITE)
	source.Transparency = 1
	local sparkles = Instance.new("ParticleEmitter")
	sparkles.Texture = SPARKLE_TEXTURE
	sparkles.Color = ColorSequence.new(TRACK_GOLD:Lerp(WHITE, 0.3))
	sparkles.LightEmission = 0.7
	sparkles.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.7), NumberSequenceKeypoint.new(1, 0) })
	sparkles.Lifetime = NumberRange.new(0.8, 1.5)
	sparkles.Rate = rate
	sparkles.Speed = NumberRange.new(1, 3)
	sparkles.SpreadAngle = Vector2.new(180, 180)
	sparkles.Parent = source
end

-- A flat gold star standing up (`at`: its middle, facing along its Z).
local function trackStar(parent: Instance, at: CFrame, size: number)
	for _, turn in { 0, math.pi / 4 } do
		makeDecor(parent, "TrackStar", Vector3.new(size * 0.7, size * 0.7, 0.3), at * CFrame.Angles(0, 0, turn), TRACK_GOLD)
	end
end

-- Droppers: a halo of lights under every dropper's mouth (where the parts come out),
-- more lights each level, a second, gold halo from tier 2, sparkles from tier 3.
local function buildDroppersLook(model: Model, origin: CFrame, level: number)
	local tier = trackTier(level)
	local deck = deckOf(origin)
	local count = 8 + level
	for _, z in DROPPER_Z do
		local mouth = deck * CFrame.new(0, 6.5, z)
		for k = 1, count do
			local angle = k / count * math.pi * 2
			trackBulb(model, mouth * CFrame.new(math.cos(angle) * 3.9, 0, math.sin(angle) * 3.9), 0.6 + tier * 0.08, tier, k)
		end
		if tier >= 2 then
			for k = 1, count do
				local angle = (k + 0.5) / count * math.pi * 2
				makeBall(model, "TrackBulb", 0.45, mouth * CFrame.new(math.cos(angle) * 4.6, 0.25, math.sin(angle) * 4.6), TRACK_GOLD, Enum.Material.Neon).CastShadow = false
			end
		end
		if tier >= 3 then
			trackSparkles(model, mouth * CFrame.new(0, -1, 0), Vector3.new(6, 1, 6), 4 + tier * 2)
		end
	end
end

-- Belt: glowing chevrons down the middle of the belt, pointing the way it runs (more
-- each level), and the rails' glow takes the tier's color.
local function buildBeltLook(model: Model, line: Model, origin: CFrame, level: number)
	local tier = trackTier(level)
	local count = 4 + level * 2
	local from, to = BELT_TO - 4, BELT_FROM + 3
	for k = 1, count do
		local tip = deckOf(origin) * CFrame.new(0, 0.05, from + (to - from) * (k - 0.5) / count)
		for _, side in { -1, 1 } do
			local arm = makeDecor(model, "TrackChevron", Vector3.new(0.45, 0.1, 2.2), tip * CFrame.Angles(0, side * math.rad(40), 0) * CFrame.new(0, 0, 1.1), TRACK_TIER_COLORS[tier], Enum.Material.Neon)
			arm.CastShadow = false
			if tier >= 4 then
				arm:SetAttribute("Index", k)
				CollectionService:AddTag(arm, "Marquee")
			end
		end
	end
	for _, name in { "RailLeftGlow", "RailRightGlow" } do
		local glow = line:FindFirstChild(name)
		if glow and glow:IsA("BasePart") then
			glow.Color = TRACK_TIER_COLORS[tier]
		end
	end
	if tier >= 3 then
		trackSparkles(model, deckOf(origin) * CFrame.new(0, 1, (BELT_FROM + BELT_TO) / 2), Vector3.new(BELT_WIDTH, 1, BELT_TO - BELT_FROM), 6 + tier * 3)
	end
end

-- Upgraders: lights along the top of every station the line has (front and back), a
-- gold star on each from tier 2, sparkles from tier 3. Rebuilt when a station's bought.
local function buildUpgradersLook(model: Model, line: Model, level: number)
	local tier = trackTier(level)
	for _, key in { "Station1", "Station2", "Station3" } do
		local top = line:FindFirstChild(key)
		if not (top and top:IsA("BasePart")) then
			continue
		end
		local frame, size = top.CFrame, top.Size
		local count = 5 + level
		for index, side in { -1, 1 } do
			for k = 1, count do
				local x = -size.X / 2 + (k - 0.5) * size.X / count
				trackBulb(model, frame * CFrame.new(x, size.Y / 2 + 0.15, side * (size.Z / 2 + 0.1)), 0.55, tier, k + (index - 1) * count)
			end
		end
		if tier >= 2 then
			trackStar(model, frame * CFrame.new(0, size.Y / 2 + 1.6, 0), 2.4 + tier * 0.3)
		end
		if tier >= 3 then
			trackSparkles(model, frame, Vector3.new(size.X, 1, size.Z), 4 + tier * 2)
		end
	end
end

-- Shipping: a ring of lights round the delivery (more each level), an outer gold ring
-- from tier 2, sparkles from tier 3.
local function buildShippingLook(model: Model, origin: CFrame, zoneId: string, level: number)
	local tier = trackTier(level)
	local deck = deckOf(origin * CFrame.new(0, 0, SHIP_Z))
	local radius = if zoneId == "PlushieRoom" then 5.9 else 5.4
	local count = 10 + level * 2
	for k = 1, count do
		local angle = k / count * math.pi * 2
		trackBulb(model, deck * CFrame.new(math.cos(angle) * radius, 0.4, math.sin(angle) * radius), 0.7, tier, k)
	end
	if tier >= 2 then
		for k = 1, 16 do
			local a, b = (k - 1) / 16 * math.pi * 2, k / 16 * math.pi * 2
			local from = (deck * CFrame.new(math.cos(a) * (radius + 0.6), 0.3, math.sin(a) * (radius + 0.6))).Position
			local to = (deck * CFrame.new(math.cos(b) * (radius + 0.6), 0.3, math.sin(b) * (radius + 0.6))).Position
			makeDecor(model, "TrackRing", Vector3.new(0.3, 0.3, (to - from).Magnitude), CFrame.lookAt((from + to) / 2, to), TRACK_GOLD, Enum.Material.Neon).CastShadow = false
		end
	end
	if tier >= 3 then
		trackSparkles(model, deck * CFrame.new(0, 2, 0), Vector3.new(radius * 2, 1, radius * 2), 6 + tier * 2)
	end
end

-- A track's Model beside its line, fresh for every level.
local function getTrackModel(plot: Plot, item: TycoonItems.Item): Model
	local name = `{item.LineId}_Up{item.Key}`
	local old = plot.LinesFolder:FindFirstChild(name)
	if old then
		old:Destroy()
	end
	local fresh = Instance.new("Model")
	fresh.Name = name
	fresh.Parent = plot.LinesFolder
	return fresh
end

local function buildTrackLook(model: Model, plot: Plot, item: TycoonItems.Item)
	local lineId = item.LineId :: string
	local origin = lineOrigin(plot, lineId)
	local line = getLineModel(plot, lineId)
	local level = item.Level :: number
	if item.Key == "Droppers" then
		buildDroppersLook(model, origin, level)
	elseif item.Key == "Belt" then
		buildBeltLook(model, line, origin, level)
	elseif item.Key == "Upgraders" then
		buildUpgradersLook(model, line, level)
	elseif item.Key == "Shipping" then
		buildShippingLook(model, origin, item.Zone, level)
	end
end

-- A zone's room: the center of its floor, in the world.
local function roomFloor(plot: Plot, zoneId: string): CFrame
	return plot.CFrame * FactoryBuilder.RoomCFrame(Zones.ById[zoneId].Index)
end

-- A room upgrade's Model (in the Lines folder, so TycoonFX plays its build animation
-- too). Each level replaces the one before with a fresh Model, so clients see it
-- tagged anew (RoomFX).
local function getDecorModel(plot: Plot, item: TycoonItems.Item): Model
	local name = `{item.Zone}_Decor_{item.Key}`
	local old = plot.LinesFolder:FindFirstChild(name)
	if old then
		old:Destroy()
	end
	local fresh = Instance.new("Model")
	fresh.Name = name
	fresh.ModelStreamingMode = Enum.ModelStreamingMode.Atomic -- RoomFX needs the whole thing at once
	fresh.Parent = plot.LinesFolder
	return fresh
end

-- A whole plot being furnished at once (claimed, or rebuilt after a rebirth): clients
-- drop it all in (TycoonFX, DropIn), each line and room upgrade in turn (its Wave),
-- each piece in the order it was built (BuildIndex).
type Arrival = { Waves: { [Model]: number }, Count: number, Order: number }

-- Builds an item's parts onto its line (or a room upgrade's level into its room). Each
-- part is tagged with its item, and a freshly bought one (or one in an `arrival`) also
-- with the server time it was built, so clients can play the build animation
-- (TycoonFX) for new things only.
local syncBuilding: (plot: Plot, dropIn: boolean) -> ()
local updateZoneLabels: (plot: Plot) -> ()

local function buildItem(plot: Plot, item: TycoonItems.Item, bought: boolean?, arrival: Arrival?)
	if item.Kind == "Floor" then
		syncBuilding(plot, bought == true or arrival ~= nil)
		return
	elseif item.Kind == "Room" then
		updateZoneLabels(plot) -- its door opens
		return
	end
	local model = if item.Kind == "Decor"
		then getDecorModel(plot, item)
		elseif item.Kind == "Track" then getTrackModel(plot, item)
		else getLineModel(plot, item.LineId :: string)
	local existing = {}
	for _, descendant in model:GetDescendants() do
		existing[descendant] = true
	end
	if item.Kind == "Decor" then
		local floor = roomFloor(plot, item.Zone)
		RoomUpgradeBuilder.Build(model, floor, item.Key, item.Level :: number)
		-- its bonus so far (every level up to this one), shown over it (and by the
		-- Jack-in-the-Box when it pops)
		local bonus = 1
		for _, level in TycoonItems.DecorByZone[item.Zone] do
			if level.Key == item.Key and (level.Level :: number) <= (item.Level :: number) then
				bonus *= level.Multiplier :: number
			end
		end
		model:SetAttribute("Bonus", bonus)
		local anchor = makeDecor(model, "BonusTag", Vector3.one, floor * CFrame.new(RoomUpgradeBuilder.TagSpot(item.Key)), WHITE)
		anchor.Transparency = 1
		local tag = makeBillboard(anchor, `{item.Name} Lv{item.Level}\n+{math.floor((bonus - 1) * 100 + 0.5)}% room 💰`, Vector2.new(9, 2.4), 0, 70)
		tag.TextColor3 = Color3.fromRGB(255, 225, 90)
	elseif item.Kind == "Track" then
		buildTrackLook(model, plot, item)
	else
		BUILDERS[item.Kind](model, lineOrigin(plot, item.LineId :: string), item)
	end
	local now = workspace:GetServerTimeNow()
	local wave: number? = nil
	if arrival then
		wave = arrival.Waves[model]
		if not wave then
			arrival.Count += 1
			wave = arrival.Count
			arrival.Waves[model] = wave
		end
	end
	local order = 0
	for _, descendant in model:GetDescendants() do
		if not existing[descendant] and descendant:IsA("BasePart") then
			descendant:SetAttribute("Item", item.Id)
			if arrival then
				arrival.Order += 1
				descendant:SetAttribute("Built", now)
				descendant:SetAttribute("BuildIndex", arrival.Order)
				descendant:SetAttribute("Wave", wave)
			elseif bought then
				descendant:SetAttribute("Built", now)
				if item.Kind == "Decor" then
					-- the order it was built in: a room upgrade drops in that way (DropIn)
					order += 1
					descendant:SetAttribute("BuildIndex", order)
				end
			end
		end
	end
end

-- Buttons --------------------------------------------------------------------

local function priceText(price: number): string
	return if price == 0 then "FREE" else `💰 {Format.Number(price)}`
end

-- A room upgrade level the owner hasn't the rebirths for yet: its button shows, gray,
-- with what it needs.
local function isLocked(plot: Plot, item: TycoonItems.Item): boolean
	local data = plot.Owner and DataManager.GetData(plot.Owner)
	return (item.Rebirths or 0) > (if data then data.Rebirths else 0)
end

local function updateButtonColors(plot: Plot)
	local coins = if plot.Owner then DataManager.GetCurrency(plot.Owner, "Coins") else 0
	for itemId, button in plot.Buttons do
		local item = TycoonItems.ById[itemId]
		if isLocked(plot, item) then
			button.Color = LOCKED_COLOR
		else
			button.Color = if coins >= item.Price then AFFORDABLE_COLOR else EXPENSIVE_COLOR
		end
	end
end

local refreshButtons: (plot: Plot) -> ()

local function onButtonTouched(plot: Plot, item: TycoonItems.Item, hit: BasePart)
	local player = getPlayerFromHit(hit)
	if not player or player ~= plot.Owner or not plot.Buttons[item.Id] or isLocked(plot, item) then
		return
	end
	local now = os.clock()
	if (buttonCooldowns[player] or 0) > now then
		return
	end
	buttonCooldowns[player] = now + BUTTON_COOLDOWN

	if DataManager.PurchaseItem(player, item.Id, item.Price) then
		buildItem(plot, item, true)
		if item.Kind == "Room" then
			-- the room's free first line arrives with it
			local data = DataManager.GetData(player)
			for _, free in TycoonItems.List do
				if data and free.Zone == item.Zone and free.Price == 0 and free.Requires == nil and free.Kind ~= "Room" then
					if DataManager.PurchaseItem(player, free.Id, 0) then
						buildItem(plot, free, true)
					end
				end
			end
		end
		refreshButtons(plot)
		-- the Upgraders track lights every station up: give the new one its lights too
		local data = DataManager.GetData(player)
		local lineId = item.LineId
		if item.Kind == "Station" and data and lineId then
			local level = TycoonItems.TrackLevel(data.Tycoon.Purchased, lineId, "Upgraders")
			if level > 0 then
				buildItem(plot, TycoonItems.TracksByLine[lineId].Upgraders[level])
			end
		end
	end
end

local function createButton(plot: Plot, item: TycoonItems.Item)
	local cframe: CFrame
	local text: string
	if item.Kind == "Room" then
		local spot = ROOM_BUTTONS[item.Zone] or Vector3.new(18, FactoryBuilder.FloorY(1), 55)
		cframe = plot.CFrame * CFrame.new(spot.X, spot.Y + 0.2, spot.Z)
		text = `🔓 {item.Name}\n{priceText(item.Price)}`
	elseif item.Kind == "Floor" then
		-- the next floor's button, on the lawn in front of the factory
		cframe = plot.CFrame * CFrame.new(FLOOR_BUTTON.X, 0.2, FLOOR_BUTTON.Z)
		text = if isLocked(plot, item)
			then `🏗️ {item.Name}\n🔒 REBIRTH {item.Rebirths}`
			else `🏗️ {item.Name}\n{priceText(item.Price)}`
	elseif item.Kind == "Decor" then
		-- a room upgrade's button sits by its spot in the room
		local spot = RoomUpgradeBuilder.ButtonSpot(item.Key)
		cframe = roomFloor(plot, item.Zone) * CFrame.new(spot.X, 0.2, spot.Z)
		local title = `{item.Name} Lv{item.Level}`
		text = if isLocked(plot, item)
			then `{title}\n🔒 REBIRTH {item.Rebirths}`
			else `{title}\n{priceText(item.Price)}\nx{item.Multiplier} room income`
	else
		local offset = BUTTON_OFFSETS[item.Key]
		cframe = lineOrigin(plot, item.LineId :: string) * CFrame.new(offset.X, 0.2, offset.Z)
		text = `{item.Name}\n{priceText(item.Price)}`
	end
	local big = item.Kind == "Floor" or item.Kind == "Room"
	local size = if item.Kind == "Floor" then 8 elseif item.Kind == "Room" then 6 else 5
	local button = makePart(plot.ButtonsFolder, item.Id, Vector3.new(size, 0.4, size), cframe, AFFORDABLE_COLOR, Enum.Material.Neon)
	makeBillboard(button, text, if big then Vector2.new(12, 3.6) elseif item.Kind == "Decor" then Vector2.new(7.5, 3.4) else Vector2.new(7, 2.5), if big then 4 else 3, if big then 150 else 60)
	button.Touched:Connect(function(hit)
		onButtonTouched(plot, item, hit)
	end)
	plot.Buttons[item.Id] = button
end

-- Shows exactly the buttons the owner can buy next: not owned, requirement owned,
-- zone unlocked.
refreshButtons = function(plot: Plot)
	local data = plot.Owner and DataManager.GetData(plot.Owner)
	for _, item in TycoonItems.List do
		local visible = false
		if data then
			local purchased = data.Tycoon.Purchased
			local zone = Zones.ById[item.Zone]
			local open = if item.Kind == "Room" then zone ~= nil and isZoneReachable(data, zone) else isZoneUnlocked(data, item.Zone)
			visible = item.Kind ~= "Track" -- bought from the line's tablet, not a button
				and open
				and not purchased[item.Id]
				and (item.Requires == nil or purchased[item.Requires] == true)
		end

		local button = plot.Buttons[item.Id]
		if visible and not button then
			createButton(plot, item)
		elseif not visible and button then
			button:Destroy()
			plot.Buttons[item.Id] = nil
		end
	end
	updateButtonColors(plot)
end

-- Plots ----------------------------------------------------------------------

-- The Cash Pad's label, plus a Collected attribute clients use to pile coins on it.
local function updateCashLabel(plot: Plot)
	plot.CashLabel.Text = `💰 {Format.Number(plot.Collected)}\nStep here to collect!`
	plot.CashPad:SetAttribute("Collected", plot.Collected)
end

-- On a reset or release: voids the payouts in flight, and tells clients the Cash Pad's
-- coming wipe isn't a collect.
local function newGeneration(plot: Plot)
	plot.Generation += 1
	plot.CashPad:SetAttribute("Generation", plot.Generation)
end

-- Each room's doorway stays shuttered, its sign showing a lock, until the owner
-- unlocks the zone. Rooms of zones that aren't built yet stay shut, "coming soon"
-- once the owner has the rebirths.
updateZoneLabels = function(plot: Plot)
	local data = plot.Owner and DataManager.GetData(plot.Owner)
	for zoneId, doorway in plot.Doorways do
		local zone = Zones.ById[zoneId]
		local rebirths = if data then data.Rebirths else 0
		if rebirths < zone.UnlockRebirths then
			FactoryBuilder.SetLocked(doorway, `🔒 REBIRTH {zone.UnlockRebirths}`)
		elseif not zone.Available then
			FactoryBuilder.SetLocked(doorway, "🚧 COMING SOON")
		elseif data and isZoneUnlocked(data, zoneId) then
			FactoryBuilder.SetLocked(doorway, nil)
		else
			FactoryBuilder.SetLocked(doorway, `🔓 💰 {Format.Number(zone.UnlockPrice or 0)}`)
		end
	end
end

-- (Re)builds the plot's factory `storeys` high. With `dropFrom`, the storeys from there
-- up (and the roof) drop in on clients (FactoryBuilder.PrepareDropIn, TycoonFX). The old
-- building's top goes at once; the rest of it stays a moment while the new one streams
-- in (they're the same down there), so the plot never blinks empty.
local function rebuildBuilding(plot: Plot, storeys: number, dropFrom: number?)
	local old = plot.Building
	local keep = math.min(storeys, plot.Storeys) -- the old storeys the new building shares
	local building = Instance.new("Model")
	building.Name = "Building"
	local factory = FactoryBuilder.Build(building, plot.CFrame, plot.Color, storeys)
	if dropFrom then
		FactoryBuilder.PrepareDropIn(building, plot.CFrame, dropFrom)
	end
	building.Parent = plot.Model
	plot.Building = building
	plot.Storeys = storeys
	plot.SignLabel = factory.SignLabel
	plot.Doorways = factory.Doorways
	plot.SignLabel.Text = if plot.Owner then `{plot.Owner.DisplayName}'s Brainrot Factory` else "Empty Plot"
	updateZoneLabels(plot)
	for _, child in old:GetChildren() do
		local level = child:GetAttribute("Level")
		if typeof(level) == "number" and level > keep then
			child:Destroy()
		end
	end
	task.delay(OLD_BUILDING_DELAY, function()
		old:Destroy()
	end)
end

-- Makes the plot's factory as tall as its owner's floors (2 storeys, without one). A
-- new floor drops in when `dropIn`.
syncBuilding = function(plot: Plot, dropIn: boolean)
	local data = plot.Owner and DataManager.GetData(plot.Owner)
	local storeys = if data
		then TycoonItems.StoreysOf(data.Tycoon.Purchased, FactoryBuilder.BaseStoreys)
		else FactoryBuilder.BaseStoreys
	if storeys ~= plot.Storeys then
		rebuildBuilding(plot, storeys, if dropIn and storeys > plot.Storeys then plot.Storeys + 1 else nil)
	end
end

local function buildPlot(index: number, parent: Instance): Plot
	local angle = (index - 1) / PLOT_COUNT * math.pi * 2
	local center = Vector3.new(math.sin(angle), 0, math.cos(angle)) * PLOT_RADIUS
	local cframe = CFrame.lookAt(center, Vector3.zero) -- -Z faces the hub

	local model = Instance.new("Model")
	model.Name = `Plot{index}`
	model.WorldPivot = cframe
	model.Parent = parent

	local building = Instance.new("Model")
	building.Name = "Building"
	local factory = FactoryBuilder.Build(building, cframe, PLOT_COLORS[index], FactoryBuilder.BaseStoreys)
	building.Parent = model

	local cashPad = makePart(model, "CashPad", Vector3.new(8, 0.6, 8), cframe * CASH_PAD_OFFSET, Color3.fromRGB(255, 215, 0), Enum.Material.Neon)
	local cashLabel = makeBillboard(cashPad, "", Vector2.new(8, 3), 4, 100)

	local linesFolder = Instance.new("Folder")
	linesFolder.Name = "Lines"
	linesFolder.Parent = model
	local buttonsFolder = Instance.new("Folder")
	buttonsFolder.Name = "Buttons"
	buttonsFolder.Parent = model

	local plot: Plot = {
		Index = index,
		Model = model,
		CFrame = cframe,
		Color = PLOT_COLORS[index],
		Building = building,
		Storeys = FactoryBuilder.BaseStoreys,
		LinesFolder = linesFolder,
		ButtonsFolder = buttonsFolder,
		SignLabel = factory.SignLabel,
		CashPad = cashPad,
		CashLabel = cashLabel,
		Doorways = factory.Doorways,
		Owner = nil,
		Collected = 0,
		Generation = 0,
		Buttons = {},
		Connections = {},
	}
	updateCashLabel(plot)
	updateZoneLabels(plot)

	cashPad.Touched:Connect(function(hit)
		local player = getPlayerFromHit(hit)
		if player and player == plot.Owner and plot.Collected > 0 then
			local amount = plot.Collected
			plot.Collected = 0
			DataManager.AddCurrency(player, "Coins", amount)
			updateCashLabel(plot)
		end
	end)

	return plot
end

local function teleportToPlot(plot: Plot, character: Model)
	task.spawn(function()
		if not character:WaitForChild("HumanoidRootPart", 5) then
			return
		end
		task.wait() -- let the default spawn finish placing the character first
		if plot.Owner and plot.Owner.Character == character then
			character:PivotTo(plot.CFrame * SPAWN_OFFSET)
		end
	end)
end

-- Builds everything the owner has bought (granting the free starting items of every
-- unlocked zone first), then shows their next buttons.
-- Builds everything the player owns into the plot, dropping it all in on clients.
local function furnishPlot(plot: Plot, player: Player, data: DataManager.PlayerData)
	-- saves from before rooms were bought (a zone opened with its rebirths): a room with
	-- lines already in it is open
	for _, line in TycoonItems.Lines do
		local room = `{line.Zone}_Room`
		if TycoonItems.ById[room] and not data.Tycoon.Purchased[room] and data.Tycoon.Purchased[line.UnlockItemId] then
			DataManager.PurchaseItem(player, room, 0)
		end
	end
	syncBuilding(plot, true) -- as tall as its floors (a rebirth takes them away)
	local arrival: Arrival = { Waves = {}, Count = 0, Order = 0 }
	for _, item in TycoonItems.List do
		if item.Price == 0 and item.Requires == nil and isZoneUnlocked(data, item.Zone) then
			DataManager.PurchaseItem(player, item.Id, 0)
		end
	end
	for _, item in TycoonItems.List do
		local purchased = data.Tycoon.Purchased
		-- (a room upgrade or a line upgrade track shows only its highest level)
		local outgrown = (item.Kind == "Decor" and purchased[`{item.Zone}_Decor_{item.Key}_{(item.Level :: number) + 1}`])
			or (item.Kind == "Track" and purchased[`{item.LineId}_Up{item.Key}_{(item.Level :: number) + 1}`])
		if purchased[item.Id] and not outgrown then
			buildItem(plot, item, nil, arrival)
		end
	end
	refreshButtons(plot)
	updateZoneLabels(plot)
end

local function claimPlot(player: Player)
	local data = DataManager.GetData(player)
	if plotByPlayer[player] or not data then
		return
	end
	local plot: Plot? = nil
	for _, candidate in plots do
		if not candidate.Owner then
			plot = candidate
			break
		end
	end
	if not plot then
		warn(`[TycoonManager] No free plot for {player.Name}. Set the place's Max Players to {PLOT_COUNT}.`)
		return
	end

	plot.Owner = player
	plotByPlayer[player] = plot
	plot.SignLabel.Text = `{player.DisplayName}'s Brainrot Factory`
	player:SetAttribute("PlotIndex", plot.Index)
	furnishPlot(plot, player, data)

	table.insert(
		plot.Connections,
		player:GetAttributeChangedSignal("Coins"):Connect(function()
			updateButtonColors(plot)
		end)
	)
	table.insert(
		plot.Connections,
		player.CharacterAdded:Connect(function(character)
			teleportToPlot(plot, character)
		end)
	)
	if player.Character then
		teleportToPlot(plot, player.Character)
	end
end

local function releasePlot(player: Player)
	buttonCooldowns[player] = nil
	local plot = plotByPlayer[player]
	if not plot then
		return
	end
	plotByPlayer[player] = nil
	newGeneration(plot)

	for _, connection in plot.Connections do
		connection:Disconnect()
	end
	table.clear(plot.Connections)
	plot.LinesFolder:ClearAllChildren()
	plot.ButtonsFolder:ClearAllChildren()
	table.clear(plot.Buttons)
	plot.Owner = nil
	plot.Collected = 0
	plot.SignLabel.Text = "Empty Plot"
	syncBuilding(plot, false) -- back to 2 storeys
	updateCashLabel(plot)
	updateZoneLabels(plot)
end

-- Public API -----------------------------------------------------------------

-- A line upgrade track's next level, bought from the line's tablet (the Line menu).
-- Returns whether it was bought, and why not: "Max", "Locked" (its gate isn't bought,
-- or the zone isn't unlocked) or "Coins".
local function onBuyLineUpgrade(player: Player, lineId: unknown, track: unknown): (boolean, string?)
	if typeof(lineId) ~= "string" or typeof(track) ~= "string" then
		return false, nil
	end
	local plot = plotByPlayer[player]
	local data = DataManager.GetData(player)
	local tracks = TycoonItems.TracksByLine[lineId]
	local levels = tracks and tracks[track]
	if not (plot and data and levels) then
		return false, nil
	end
	local now = os.clock()
	if (buttonCooldowns[player] or 0) > now then
		return false, nil
	end
	buttonCooldowns[player] = now + BUTTON_COOLDOWN
	local purchased = data.Tycoon.Purchased
	local item = levels[TycoonItems.TrackLevel(purchased, lineId, track) + 1]
	if not item then
		return false, "Max"
	end
	if not isZoneUnlocked(data, item.Zone) or (item.Requires and not purchased[item.Requires]) then
		return false, "Locked"
	end
	if not DataManager.PurchaseItem(player, item.Id, item.Price) then
		return false, "Coins"
	end
	buildItem(plot, item, true)
	return true, nil
end

function TycoonManager.Init()
	local folder = Instance.new("Folder")
	folder.Name = "Tycoons"
	folder.Parent = workspace
	for index = 1, PLOT_COUNT do
		plots[index] = buildPlot(index, folder)
	end
	Remotes.Function("BuyLineUpgrade").OnServerInvoke = onBuyLineUpgrade

	DataManager.OnPlayerLoaded(claimPlot)
	Players.PlayerRemoving:Connect(releasePlot)
end

function TycoonManager.GetPlot(player: Player): Plot?
	return plotByPlayer[player]
end

-- Every plot, owned or not (MapBuilder lays the hub out around them).
function TycoonManager.GetPlots(): { Plot }
	return plots
end

-- Whether a world position is over any tycoon plot (its building and outside stairs).
-- Plots are safe zones (GDD §3).
function TycoonManager.IsInPlot(position: Vector3): boolean
	local lot = FactoryBuilder.Lot
	for _, plot in plots do
		local offset = plot.CFrame:PointToObjectSpace(position)
		if math.abs(offset.X) <= lot.HalfWidth and offset.Z >= lot.Front and offset.Z <= lot.Back then
			return true
		end
	end
	return false
end

-- After a rebirth (the data is already reset): clears the tycoon and furnishes it
-- again, including the free first line of any zone that just unlocked. Brainrots
-- still on the belts are dropped, and so are the Cash Pad's Coins.
function TycoonManager.ResetPlot(player: Player)
	local plot = plotByPlayer[player]
	local data = DataManager.GetData(player)
	if not (plot and data) then
		return
	end
	newGeneration(plot)
	plot.LinesFolder:ClearAllChildren()
	plot.ButtonsFolder:ClearAllChildren()
	table.clear(plot.Buttons)
	plot.Collected = 0
	updateCashLabel(plot)
	furnishPlot(plot, player, data)
end

-- Studio testing (DevTools): builds a room upgrade's level as if just bought (so it
-- drops in), without touching the player's data; ResetPlot puts the real one back.
function TycoonManager.DevBuildUpgrade(player: Player, itemId: string): boolean
	local plot = plotByPlayer[player]
	local item = TycoonItems.ById[itemId]
	if not (plot and item and item.Kind == "Decor") then
		return false
	end
	buildItem(plot, item, true)
	return true
end

-- Adds shipped Coins to the player's collector. They bank them on the Cash Pad, or
-- straight away with the Auto-Collect gamepass.
function TycoonManager.AddToCollector(player: Player, amount: number)
	local plot = plotByPlayer[player]
	if plot and MonetizationManager.HasPerk(player, "AutoCollect") then
		DataManager.AddCurrency(player, "Coins", amount)
	elseif plot then
		plot.Collected += amount
		updateCashLabel(plot)
	end
end

return TycoonManager
