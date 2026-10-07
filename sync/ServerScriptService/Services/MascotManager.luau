--[[
	MascotManager
	The company mascot (GDD §10, Config/Mascot): out front of every owned factory, a
	brainrot its owner builds part by part (data.Mascot) on a stand that grows with its
	level, the owner's rebirth count. It starts small on a crate and grows into a giant
	statue: every level makes the brainrot and its stand bigger, and the looks in
	Config/Mascot join on the way (a marble pedestal, spotlights, banners, a gold stand
	with marquee bulbs, a fountain, searchlights, gold columns, a monument with its
	owner's name in neon, a crown, orbiting rings, rainbow neon). The clients animate it:
	the brainrot, searchlights, crown and rings turn (tag "SpinningStatue", attribute
	SpinSpeed; Atmosphere), the bulbs chase and the rainbow cycles (tag "MascotLights"),
	fireworks go off over the monuments (tag "MascotFireworks"; Client/UI/MascotMenu).
	A neon sign over it says whose it is, its level and its bonuses (Config/Rebirths);
	its prompt opens Client/UI/MascotMenu for anyone, and only its owner can change its
	parts (Remotes "SetMascotPart"). Rebuilt when its owner rebirths (with a "LevelUp"
	for the clients' fanfare) or changes a part.
]]

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local BrainrotModels = require(Shared.BrainrotModels)
local Brainrots = require(Shared.Config.Brainrots)
local MascotConfig = require(Shared.Config.Mascot)
local Rebirths = require(Shared.Config.Rebirths)
local Remotes = require(Shared.Remotes)

local DataManager = require(script.Parent.DataManager)
local RoomDecor = require(script.Parent.RoomDecor)
local TycoonManager = require(script.Parent.TycoonManager)

local STAGES = MascotConfig.Stages
local WOOD = Color3.fromRGB(205, 150, 92)
local WOOD_DARK = Color3.fromRGB(128, 84, 46)
local MARBLE = Color3.fromRGB(242, 238, 232)
local GOLD = Color3.fromRGB(255, 196, 50)
local NEON_GOLD = Color3.fromRGB(255, 214, 90)
local WATER = Color3.fromRGB(110, 195, 255)
local LIGHT = Color3.fromRGB(255, 244, 205)
local BULB = Color3.fromRGB(255, 236, 170)
local OUTLINE = Color3.fromRGB(30, 25, 45)
local BONUS_COLOR = Color3.fromRGB(150, 255, 140)
local JEWELS = { Color3.fromRGB(255, 70, 110), Color3.fromRGB(80, 200, 255), Color3.fromRGB(120, 255, 120) }
local PLOT_WAIT = 20 -- seconds to wait for a joining player's plot
local REQUEST_COOLDOWN = 0.2

local stands: { [Player]: Model } = {}
local lastRequest: { [Player]: number } = {}
local mascotRemote: RemoteEvent

local MascotManager = {}

local function makePart(parent: Instance, name: string, size: Vector3, cframe: CFrame, color: Color3, material: Enum.Material?): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

-- A standing cylinder `diameter` wide and `height` tall, its bottom at `bottom`.
local function makeCylinder(parent: Instance, name: string, diameter: number, height: number, bottom: Vector3, color: Color3, material: Enum.Material?): Part
	local part = makePart(parent, name, Vector3.new(height, diameter, diameter), CFrame.new(bottom + Vector3.new(0, height / 2, 0)) * CFrame.Angles(0, 0, math.pi / 2), color, material)
	part.Shape = Enum.PartType.Cylinder
	return part
end

local function makeBall(parent: Instance, name: string, diameter: number, position: Vector3, color: Color3, material: Enum.Material?): Part
	local part = makePart(parent, name, Vector3.one * diameter, CFrame.new(position), color, material)
	part.Shape = Enum.PartType.Ball
	return part
end

-- A point `radius` out at `angle` round the stand's middle (0: straight out its front,
-- -Z), `y` up.
local function around(angle: number, radius: number, y: number?): Vector3
	return Vector3.new(math.sin(angle) * radius, y or 0, -math.cos(angle) * radius)
end

-- `count` blocks round a circle `radius` out at height `y` in `frame` (each `size`, its
-- X along the circle).
local function ring(parent: Instance, name: string, count: number, radius: number, y: number, size: Vector3, color: Color3, material: Enum.Material?, frame: CFrame?): { Part }
	local parts = {}
	for index = 0, count - 1 do
		local angle = index / count * math.pi * 2
		table.insert(parts, makePart(parent, name, size, (frame or CFrame.identity) * CFrame.new(around(angle, radius, y)) * CFrame.Angles(0, -angle, 0), color, material))
	end
	return parts
end

local function emitter(parent: BasePart, color: Color3, rate: number, speed: number, size: number, up: boolean?)
	local sparkles = Instance.new("ParticleEmitter")
	sparkles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	sparkles.Color = ColorSequence.new(color)
	sparkles.LightEmission = 1
	sparkles.Size = NumberSequence.new(size, 0)
	sparkles.Lifetime = NumberRange.new(1, 1.6)
	sparkles.Speed = NumberRange.new(speed * 0.6, speed)
	sparkles.SpreadAngle = if up then Vector2.new(12, 12) else Vector2.new(180, 180)
	sparkles.EmissionDirection = Enum.NormalId.Top
	sparkles.Acceleration = if up then Vector3.new(0, -30, 0) else Vector3.zero
	sparkles.Rate = rate
	sparkles.Parent = parent
end

-- "+75% COINS · +15% SPEED · +30% LUCK": what a mascot of `level` gives (with the old
-- shop's levels).
local function bonusLine(level: number, upgrades: Rebirths.Levels?): string
	local coins = math.floor((Rebirths.IncomeMultiplier(level, upgrades) - 1) * 100 + 0.5)
	local speed = math.floor((Rebirths.SpeedMultiplier(level, upgrades) - 1) * 100 + 0.5)
	local luck = math.floor(Rebirths.Luck(level, upgrades) * 100 + 0.5)
	return `+{coins}% COINS · +{speed}% SPEED · +{luck}% LUCK`
end

-- The plot's pastel color, bold (pastel flags and bands read as white outdoors).
local function bold(color: Color3): Color3
	local hue, saturation, value = color:ToHSV()
	return Color3.fromHSV(hue, math.max(saturation, 0.7), math.max(value, 0.95))
end

-- How wide the pedestal's cap is and how tall its column at `level` (from Pedestal on):
-- quick growth up to the monument, slower after it.
local function pedestalSize(level: number): (number, number)
	local early = math.min(level, STAGES.Monument) - STAGES.Pedestal
	local late = math.clamp(level - STAGES.Monument, 0, 10)
	return 7.2 + 0.9 * early + 0.3 * late, 3 + 0.6 * early + 0.3 * late
end

-- A model that turns round its pivot on the clients (Atmosphere), `speed` radians a
-- second; tagged once the stand is in place.
local function spinner(parent: Instance, name: string, pivot: CFrame, speed: number): Model
	local model = Instance.new("Model")
	model.Name = name
	model.WorldPivot = pivot
	model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic -- (see the brainrot's)
	model:SetAttribute("SpinSpeed", speed)
	model.Parent = parent
	return model
end

-- The stand for `level` in the factory's color, for a brainrot `figure` big (its size),
-- built round the origin (its front is -Z). Returns how high its top is (where the
-- brainrot stands) and how far out its front reaches.
local function buildStand(stand: Model, level: number, pastel: Color3, figure: Vector3, ownerName: string): (number, number)
	local color = bold(pastel)
	local gold = level >= STAGES.Gold
	local rainbow = level >= STAGES.Rainbow
	local trim = if gold then GOLD else color
	local trimMaterial = if rainbow then Enum.Material.Neon elseif gold then Enum.Material.Metal else Enum.Material.Neon
	local grow = 1 + 0.06 * math.min(level, MascotConfig.Scale.Max) -- lamps, flags and bulbs grow too
	local trims: { BasePart } = {} -- (the rainbow cycles these)
	local top, foot = 0, 0 -- where the brainrot stands; how far out the stand's foot reaches

	if level >= STAGES.Pedestal then
		local width, height = pedestalSize(level)
		-- steps under it: a wide one from Gold, three from Monument (the top one taller,
		-- for its name)
		local steps = if level >= STAGES.Monument
			then { { width + 9, 1.2 }, { width + 6, 1.2 }, { width + 3, 3 } }
			elseif gold then { { width + 3, 1.2 } }
			else {}
		local y = 0
		foot = (width + 2.2) / 2
		for index, step in steps do
			makeCylinder(stand, "Step", step[1], step[2], Vector3.new(0, y, 0), MARBLE, Enum.Material.Marble)
			table.insert(trims, makeCylinder(stand, "StepTrim", step[1] + 0.3, 0.35, Vector3.new(0, y + step[2] - 0.35, 0), GOLD, trimMaterial))
			if index == 1 then
				foot = (step[1] + 0.3) / 2
			end
			y += step[2]
		end
		if level >= STAGES.Monument then
			-- a flat plaque on the top step's front, its owner's name on it in neon
			local radius, plaque = (width + 3) / 2, math.min(width, 11)
			local inner = math.sqrt(radius * radius - (plaque / 2) ^ 2) - 0.5
			local depth = radius + 0.3 - inner
			local stepBottom = y - 3
			makePart(stand, "Plaque", Vector3.new(plaque, 2.7, depth), CFrame.new(0, stepBottom + 1.35, -(inner + depth / 2)), MARBLE, Enum.Material.Marble)
			RoomDecor.NeonSign(stand, CFrame.new(0, stepBottom + 1.4, -(radius + 0.3)), Vector2.new(plaque - 1.2, 1.9), string.upper(ownerName), color)
		end
		makeCylinder(stand, "Base", width + 1.8, 1, Vector3.new(0, y, 0), MARBLE, Enum.Material.Marble)
		table.insert(trims, makeCylinder(stand, "BaseTrim", width + 2.2, 0.45, Vector3.new(0, y + 0.8, 0), trim, trimMaterial))
		makeCylinder(stand, "Column", width - 1, height, Vector3.new(0, y + 1, 0), MARBLE, Enum.Material.Marble)
		local cap = makeCylinder(stand, "Top", width, 0.7, Vector3.new(0, y + 1 + height, 0), trim, trimMaterial)
		table.insert(trims, cap)
		if gold then
			emitter(cap, GOLD, 4 + level, 3 + 0.2 * level, 0.6 * grow)
		end
		if level >= STAGES.Bulbs then
			-- marquee bulbs round the cap and the base trim (the clients chase them)
			for _, spec in { { width / 2 + 0.15, y + 1.35 + height }, { (width + 2.2) / 2 + 0.15, y + 1.02 } } do
				local count = math.floor(math.pi * 2 * spec[1] / 1.6)
				for index = 0, count - 1 do
					local bulb = makeBall(stand, "Bulb", 0.6, around(index / count * math.pi * 2, spec[1], spec[2]), BULB, Enum.Material.Neon)
					bulb.CastShadow = false
					bulb:SetAttribute("Chase", index % 3)
				end
			end
		end
		top = y + 1 + height + 0.7
	else
		-- a wooden crate with dark edges; wrapped in the factory's color from BigCrate
		local big = level >= STAGES.BigCrate
		local size = if big then Vector3.new(5.8, 3.6, 5.8) else Vector3.new(4.6, 3, 4.6) -- (over the tall grass)
		makePart(stand, "Crate", size, CFrame.new(0, size.Y / 2, 0), WOOD, Enum.Material.WoodPlanks)
		for _, x in { -1, 1 } do
			for _, z in { -1, 1 } do
				makePart(stand, "Edge", Vector3.new(0.5, size.Y + 0.06, 0.5), CFrame.new(x * (size.X / 2 - 0.2), size.Y / 2, z * (size.Z / 2 - 0.2)), WOOD_DARK, Enum.Material.Wood)
			end
		end
		if big then
			makePart(stand, "Band", Vector3.new(size.X + 0.12, size.Y + 0.12, 0.9), CFrame.new(0, size.Y / 2, 0), color)
			makePart(stand, "Band", Vector3.new(0.9, size.Y + 0.12, size.Z + 0.12), CFrame.new(0, size.Y / 2, 0), color)
		end
		top = size.Y
		foot = size.X / 2
	end

	local height = top + figure.Y -- the whole statue
	local lampRadius = foot + 1.2 + grow
	local basinRadius = foot + 3 + 1.5 * grow
	local front = foot
	if level >= STAGES.Spotlights then
		-- two lamps on the front corners, aimed up at the brainrot, each with a soft beam
		local target = Vector3.new(0, top + figure.Y * 0.45, 0)
		for _, side in { -1, 1 } do
			local aim = CFrame.lookAt(around(side * math.rad(38), lampRadius, grow), target)
			makePart(stand, "Lamp", Vector3.new(1.5, 1.5, 2.1) * grow, aim, OUTLINE, Enum.Material.Metal)
			local lens = makePart(stand, "Lens", Vector3.new(1.2 * grow, 1.2 * grow, 0.2), aim * CFrame.new(0, 0, -1.1 * grow), LIGHT, Enum.Material.Neon)
			local light = Instance.new("SpotLight")
			light.Face = Enum.NormalId.Front
			light.Angle = 45
			light.Range = math.min(26 + 2 * level, 60)
			light.Brightness = 3
			light.Color = LIGHT
			light.Parent = lens
			local length = (target - aim.Position).Magnitude - 1.5 * grow
			local beam = makePart(stand, "Beam", Vector3.new(1.3 * grow, 1.3 * grow, length), aim * CFrame.new(0, 0, -1.2 * grow - length / 2), LIGHT, Enum.Material.Neon)
			beam.Transparency = 0.86
			beam.CastShadow = false
		end
		front = lampRadius + grow
	end
	if level >= STAGES.Banners then
		-- a flag on a tall pole either side, in the factory's color, a neon ball on top
		local pole = math.max(11, height * 0.6)
		for _, side in { -1, 1 } do
			local at = around(side * math.pi / 2, foot + 1 + grow)
			makeCylinder(stand, "Pole", 0.45 * grow, pole, at, Color3.new(1, 1, 1))
			makePart(stand, "Flag", Vector3.new(0.18, 3.2 * grow, 4.4 * grow), CFrame.new(at + Vector3.new(0, pole - 2 * grow, 2.3 * grow)), color)
			table.insert(trims, makeBall(stand, "PoleTip", 0.9 * grow, at + Vector3.new(0, pole + 0.3, 0), trim, Enum.Material.Neon))
		end
	end
	if level >= STAGES.Fountain then
		-- a round basin of water with a gold rim and four jets
		local count = math.max(16, math.floor(basinRadius * 1.6))
		local segment = basinRadius * 2 * math.pi / count + 0.4
		ring(stand, "Basin", count, basinRadius, 0.65, Vector3.new(segment, 1.3, 1), MARBLE, Enum.Material.Marble)
		for _, part in ring(stand, "BasinTrim", count, basinRadius, 1.42, Vector3.new(segment, 0.25, 1.15), GOLD, trimMaterial) do
			table.insert(trims, part)
		end
		local water = makeCylinder(stand, "Water", basinRadius * 2, 0.3, Vector3.new(0, 0.4, 0), WATER, Enum.Material.Glass)
		water.Transparency = 0.3
		for index = 0, 3 do
			local jet = makePart(stand, "Jet", Vector3.one * 0.6, CFrame.new(around(index / 4 * math.pi * 2 + math.pi / 4, (foot + basinRadius) / 2, 0.7)), WATER, Enum.Material.Glass)
			jet.Transparency = 1
			emitter(jet, Color3.fromRGB(200, 235, 255), 30, 18 + level, 0.5 * grow, true)
		end
		front = basinRadius + 0.5
	end
	if level >= STAGES.Searchlights then
		-- two searchlights either side, their beams sweeping the sky
		for index, side in { -1, 1 } do
			local at = around(side * math.rad(105), basinRadius + 2.5)
			local light = spinner(stand, "Searchlight", CFrame.new(at), 0.6)
			makeCylinder(light, "SearchBase", 2.6, 1.4, at, OUTLINE, Enum.Material.Metal)
			local out = if index == 1 then Vector3.xAxis else -Vector3.xAxis
			local head = CFrame.lookAt(at + Vector3.new(0, 2.6, 0), at + Vector3.new(0, 2.6, 0) + out * 0.42 + Vector3.yAxis)
			makePart(light, "SearchHead", Vector3.new(2.4, 2.4, 2.6), head, OUTLINE, Enum.Material.Metal)
			makePart(light, "SearchLens", Vector3.new(2, 2, 0.2), head * CFrame.new(0, 0, -1.35), LIGHT, Enum.Material.Neon)
			local beam = makePart(light, "SearchBeam", Vector3.new(1.8, 1.8, 90), head * CFrame.new(0, 0, -1.5 - 45), LIGHT, Enum.Material.Neon)
			beam.Transparency = 0.8
			beam.CastShadow = false
		end
	end
	if level >= STAGES.Columns then
		-- gold columns in a half ring behind it, a neon flame on each and garlands between
		local columnHeight = math.max(12, height * 0.5)
		local thickness = 1.3 + 0.05 * level
		local tops = {}
		for index = -2, 2 do
			local at = around(math.pi + index * math.rad(24), basinRadius + 3)
			makeCylinder(stand, "ColumnFoot", thickness + 0.8, 0.8, at, MARBLE, Enum.Material.Marble)
			makeCylinder(stand, "Pillar", thickness, columnHeight, at, GOLD, Enum.Material.Metal)
			makeCylinder(stand, "ColumnHead", thickness + 0.9, 0.9, at + Vector3.new(0, columnHeight - 0.9, 0), MARBLE, Enum.Material.Marble)
			table.insert(trims, makeBall(stand, "ColumnFlame", thickness + 0.3, at + Vector3.new(0, columnHeight + thickness / 2, 0), color, Enum.Material.Neon))
			table.insert(tops, at + Vector3.new(0, columnHeight - 0.45, 0))
		end
		for index = 1, #tops - 1 do
			local a, b = tops[index], tops[index + 1]
			table.insert(trims, makePart(stand, "Garland", Vector3.new(0.45, 0.45, (b - a).Magnitude), CFrame.lookAt((a + b) / 2, b), NEON_GOLD, Enum.Material.Neon))
		end
	end
	if level >= STAGES.Crown then
		-- a gold crown floating over its head, turning
		local radius = math.clamp(math.min(figure.X, figure.Z) * 0.3, 2, 5)
		local y = height + 1 + radius * 0.3
		local crown = spinner(stand, "Crown", CFrame.new(0, y, 0), 0.8)
		ring(crown, "CrownBand", 12, radius, y, Vector3.new(radius * 2 * math.pi / 12 + 0.2, radius * 0.5, 0.5), GOLD, Enum.Material.Metal)
		for index = 0, 5 do
			local at = around(index / 6 * math.pi * 2, radius, y)
			makePart(crown, "CrownSpike", Vector3.new(0.7, radius * 0.7, 0.7), CFrame.new(at + Vector3.new(0, radius * 0.5, 0)) * CFrame.Angles(0, index, math.rad(45)), GOLD, Enum.Material.Metal)
			makeBall(crown, "Jewel", radius * 0.3, at + Vector3.new(0, radius * 0.9, 0), JEWELS[index % #JEWELS + 1], Enum.Material.Neon)
		end
	end
	if level >= STAGES.Rings then
		-- two neon gold rings orbiting it, tilted opposite ways
		local radius = math.min(math.max(figure.X, figure.Z) * 0.55 + 3, MascotConfig.MaxRadius)
		for index, tilt in { 25, -25 } do
			local center = Vector3.new(0, top + figure.Y * (0.3 + 0.25 * index), 0)
			local orbit = spinner(stand, "Orbit", CFrame.new(center), if index == 1 then 0.9 else -0.7)
			local frame = CFrame.new(center) * CFrame.Angles(math.rad(tilt), 0, 0)
			for _, part in ring(orbit, "Ring", 28, radius, 0, Vector3.new(radius * 2 * math.pi / 28 + 0.2, 0.7, 0.7), NEON_GOLD, Enum.Material.Neon, frame) do
				part.CastShadow = false
				table.insert(trims, part)
			end
		end
	end
	if rainbow then
		for index, part in trims do
			part:SetAttribute("Rainbow", index)
		end
	end
	if level >= STAGES.Bulbs then
		CollectionService:AddTag(stand, "MascotLights")
	end
	return top, front
end

-- How much bigger the sign is at `level` (it grows with the statue).
local function signGrow(level: number): number
	return 1 + 0.05 * math.min(level, MascotConfig.Scale.Max)
end

-- The neon sign over the brainrot: whose it is, its level and what it gives.
local function buildSign(anchor: BasePart, owner: Player, level: number, upgrades: Rebirths.Levels, color: Color3)
	local grow = signGrow(level)
	local gui = Instance.new("BillboardGui")
	gui.Name = "MascotSign"
	gui.Size = UDim2.fromScale(13 * grow, 4.6 * grow)
	gui.MaxDistance = 220 + 8 * level
	gui.LightInfluence = 0
	gui.Parent = anchor
	local pill = Instance.new("Frame")
	pill.Size = UDim2.fromScale(1, 1)
	pill.BackgroundColor3 = OUTLINE
	pill.BackgroundTransparency = 0.25
	pill.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.3, 0)
	corner.Parent = pill
	local rim = Instance.new("UIStroke")
	rim.Thickness = 3
	rim.Color = if level >= STAGES.Gold then GOLD else bold(color)
	rim.Parent = pill
	local rows = {
		{ `{string.upper(owner.DisplayName)}'S MASCOT`, 0.05, 0.24, Color3.new(1, 1, 1) },
		{ `LEVEL {level}`, 0.29, 0.38, GOLD },
		{ if level > 0 then bonusLine(level, upgrades) else "REBIRTH TO LEVEL ME UP!", 0.69, 0.24, BONUS_COLOR },
	}
	for _, row in rows do
		local label = Instance.new("TextLabel")
		label.BackgroundTransparency = 1
		label.Position = UDim2.fromScale(0.05, row[2])
		label.Size = UDim2.fromScale(0.9, row[3])
		label.Font = Enum.Font.FredokaOne
		label.TextScaled = true
		label.TextColor3 = row[4]
		label.Text = row[1]
		label.Parent = pill
		local stroke = Instance.new("UIStroke")
		stroke.Thickness = 2.5
		stroke.Color = OUTLINE
		stroke.Parent = label
	end
end

-- (Re)builds `player`'s mascot in front of their factory, at `level` (their rebirths
-- unless given: DevPreview). Returns where its top is.
local function build(player: Player, level: number?): Vector3?
	local plot = TycoonManager.GetPlot(player)
	local data = DataManager.GetData(player)
	if not (plot and data) then
		return nil
	end
	if stands[player] then
		stands[player]:Destroy()
		stands[player] = nil
	end
	local shownLevel = level or data.Rebirths
	local stand = Instance.new("Model")
	stand.Name = "Mascot"

	-- the brainrot first: the stand grows round its size
	local parts = {}
	for _, partType in Brainrots.PartTypes do
		local id = data.Mascot[partType]
		parts[partType] = if id and Brainrots.ById[id] then id else Brainrots.StarterId
	end
	local brainrot = BrainrotModels.Build(parts)
	brainrot.Name = "MascotBrainrot"
	-- (all of it reaches a client at once: a part streamed in while it turns would join
	-- it where the server has it, off by the angle turned, and stay there)
	brainrot.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	local box, unscaled = brainrot:GetBoundingBox()
	local offset = brainrot:GetPivot():PointToObjectSpace(box.Position)
	local reach = Vector2.new(math.abs(offset.X) + unscaled.X / 2, math.abs(offset.Z) + unscaled.Z / 2).Magnitude -- (as it turns)
	brainrot:ScaleTo(math.min(MascotConfig.ScaleAt(shownLevel), MascotConfig.MaxRadius / math.max(reach, 1)))
	local _, figure = brainrot:GetBoundingBox()
	local top, front = buildStand(stand, shownLevel, plot.Color, figure, player.DisplayName)
	brainrot:PivotTo(CFrame.new(0, top, 0))
	brainrot.Parent = stand

	-- the sign's middle over its head: half the sign (it grows), clear of the crown
	local over = figure.Y + 2 + 2.5 * signGrow(shownLevel) + (if shownLevel >= STAGES.Crown then 8 else 0)
	local anchor = makePart(stand, "SignAnchor", Vector3.one * 0.2, CFrame.new(0, top + over, 0), OUTLINE)
	anchor.Transparency = 1
	buildSign(anchor, player, shownLevel, data.Upgrades, plot.Color)
	local promptSpot = makePart(stand, "PromptSpot", Vector3.one * 0.2, CFrame.new(0, 3, -front), OUTLINE)
	promptSpot.Transparency = 1
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Mascot"
	prompt.ObjectText = `{player.DisplayName}'s`
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 13
	prompt.RequiresLineOfSight = false
	prompt.Parent = promptSpot
	local owner = player
	prompt.Triggered:Connect(function(viewer: Player)
		MascotManager.Show(viewer, owner)
	end)

	stand.WorldPivot = CFrame.identity
	local spot = MascotConfig.Spot
	stand:PivotTo(plot.CFrame * CFrame.lookAt(spot, spot + MascotConfig.Facing))
	stand:SetAttribute("Level", shownLevel)
	stand:SetAttribute("Top", top + figure.Y)
	if shownLevel >= STAGES.Monument then
		CollectionService:AddTag(stand, "MascotFireworks")
	end
	stand.Parent = plot.Model
	-- (in place: the clients turn these round where they stand)
	CollectionService:AddTag(brainrot, "SpinningStatue")
	for _, child in stand:GetChildren() do
		if child:IsA("Model") and child:GetAttribute("SpinSpeed") then
			CollectionService:AddTag(child, "SpinningStatue")
		end
	end
	stands[player] = stand
	return stand:GetPivot().Position + Vector3.new(0, top + figure.Y, 0)
end

-- Whether `spot` is within `radius` (flat) of a plot's mascot spot, built or not (boxes
-- keep off it: they spawn before the mascot is built).
function MascotManager.IsNear(spot: Vector3, radius: number): boolean
	for _, plot in TycoonManager.GetPlots() do
		local center = plot.CFrame * MascotConfig.Spot
		if Vector2.new(spot.X - center.X, spot.Z - center.Z).Magnitude < radius then
			return true
		end
	end
	return false
end

-- Opens the mascot's menu for `viewer`: whose it is, its level, its parts and the old
-- shop's levels (for its bonuses), and whether it's theirs to change.
function MascotManager.Show(viewer: Player, owner: Player)
	local data = DataManager.GetData(owner)
	if not data then
		return
	end
	mascotRemote:FireClient(viewer, "Open", {
		OwnerId = owner.UserId,
		OwnerName = owner.DisplayName,
		Level = data.Rebirths,
		Parts = table.clone(data.Mascot),
		Upgrades = table.clone(data.Upgrades),
		Mine = viewer == owner,
	})
end

-- DevTools: shows `player`'s mascot at `level` (nothing saved; their next rebirth or
-- part change puts the real one back), or the real one with no level.
function MascotManager.DevPreview(player: Player, level: number?): boolean
	return build(player, level) ~= nil
end

local function onSetPart(player: Player, partType: unknown, brainrotId: unknown): boolean
	local now = os.clock()
	if (lastRequest[player] or 0) + REQUEST_COOLDOWN > now then
		return false
	end
	lastRequest[player] = now
	if typeof(partType) ~= "string" or typeof(brainrotId) ~= "string" or not table.find(Brainrots.PartTypes, partType) or not Brainrots.ById[brainrotId] then
		return false
	end
	if not DataManager.SetMascotPart(player, partType, brainrotId) then
		return false
	end
	build(player)
	return true
end

local function onLoaded(player: Player)
	local deadline = os.clock() + PLOT_WAIT
	while not TycoonManager.GetPlot(player) and os.clock() < deadline and player.Parent do
		task.wait(0.5)
	end
	if not player.Parent then
		return
	end
	build(player)
	-- each rebirth is a level: a bigger stand, and a fanfare round it
	player:GetAttributeChangedSignal("Rebirths"):Connect(function()
		local top = build(player)
		if top then
			mascotRemote:FireAllClients("LevelUp", top, player:GetAttribute("Rebirths"))
		end
	end)
end

function MascotManager.Init()
	mascotRemote = Remotes.Event("Mascot")
	Remotes.Function("SetMascotPart").OnServerInvoke = onSetPart
	DataManager.OnPlayerLoaded(onLoaded)
	Players.PlayerRemoving:Connect(function(player)
		lastRequest[player] = nil
		if stands[player] then
			stands[player]:Destroy()
			stands[player] = nil
		end
	end)
end

return MascotManager
