--[[
	MascotManager
	The company mascot (GDD §10, Config/Mascot): out front of every owned factory, a
	brainrot its owner builds part by part (data.Mascot) on a stand that grows with its
	level, the owner's rebirth count: a crate, a bigger crate in the factory's color, a
	marble pedestal, spotlights, banners, gold trims, a fountain, then fireworks (the
	clients set those off: tag "MascotFireworks"). The brainrot turns slowly (tag
	"SpinningStatue", Atmosphere). A neon sign over it says whose it is, its level and
	its bonuses (Config/Rebirths); its prompt opens Client/UI/MascotMenu for anyone, and
	only its owner can change its parts (Remotes "SetMascotPart"). Rebuilt when its owner
	rebirths (with a "LevelUp" for the clients' fanfare) or changes a part.
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
local TycoonManager = require(script.Parent.TycoonManager)

local STAGES = MascotConfig.Stages
local FACING = Vector3.new(0.45, 0, -1) -- (plot space) toward the hub, turned a little to the path
local WOOD = Color3.fromRGB(205, 150, 92)
local WOOD_DARK = Color3.fromRGB(128, 84, 46)
local MARBLE = Color3.fromRGB(242, 238, 232)
local GOLD = Color3.fromRGB(255, 196, 50)
local WATER = Color3.fromRGB(110, 195, 255)
local LIGHT = Color3.fromRGB(255, 244, 205)
local OUTLINE = Color3.fromRGB(30, 25, 45)
local BONUS_COLOR = Color3.fromRGB(150, 255, 140)
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

-- The stand for `level` in the factory's `color`, built round the origin (its front is
-- -Z). Returns how high its top is (where the brainrot stands).
local function buildStand(stand: Model, level: number, pastel: Color3): number
	local color = bold(pastel)
	local gold = level >= STAGES.Gold
	local trim = if gold then GOLD else color
	local trimMaterial = if gold then Enum.Material.Metal else Enum.Material.Neon
	local top
	if level >= STAGES.Pedestal then
		makeCylinder(stand, "Base", 9, 1, Vector3.zero, MARBLE, Enum.Material.Marble)
		makeCylinder(stand, "BaseTrim", 9.4, 0.45, Vector3.new(0, 0.8, 0), trim, trimMaterial)
		makeCylinder(stand, "Column", 6.2, 3, Vector3.new(0, 1, 0), MARBLE, Enum.Material.Marble)
		local cap = makeCylinder(stand, "Top", 7.2, 0.7, Vector3.new(0, 4, 0), trim, trimMaterial)
		if gold then
			emitter(cap, GOLD, 6, 3, 0.6)
		end
		top = 4.7
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
	end

	if level >= STAGES.Spotlights then
		-- two lamps on the front corners, aimed up at the brainrot, each with a soft beam
		local target = Vector3.new(0, top + 3, 0)
		for _, side in { -1, 1 } do
			local aim = CFrame.lookAt(Vector3.new(side * 5.6, 1, -5.2), target)
			makePart(stand, "Lamp", Vector3.new(1.5, 1.5, 2.1), aim, OUTLINE, Enum.Material.Metal)
			local lens = makePart(stand, "Lens", Vector3.new(1.2, 1.2, 0.2), aim * CFrame.new(0, 0, -1.1), LIGHT, Enum.Material.Neon)
			local light = Instance.new("SpotLight")
			light.Face = Enum.NormalId.Front
			light.Angle = 45
			light.Range = 26
			light.Brightness = 3
			light.Color = LIGHT
			light.Parent = lens
			local length = (target - aim.Position).Magnitude - 1.5
			local beam = makePart(stand, "Beam", Vector3.new(1.3, 1.3, length), aim * CFrame.new(0, 0, -1.2 - length / 2), LIGHT, Enum.Material.Neon)
			beam.Transparency = 0.86
			beam.CastShadow = false
		end
	end
	if level >= STAGES.Banners then
		-- a flag on a pole either side, in the factory's color, a neon ball on top
		for _, side in { -1, 1 } do
			local x = side * 5.6
			makeCylinder(stand, "Pole", 0.45, 11, Vector3.new(x, 0, 3), Color3.new(1, 1, 1))
			makePart(stand, "Flag", Vector3.new(0.18, 3.2, 4.4), CFrame.new(x, 9, 3 + 2.3), color)
			local tip = makePart(stand, "PoleTip", Vector3.one * 0.9, CFrame.new(x, 11.3, 3), trim, Enum.Material.Neon)
			tip.Shape = Enum.PartType.Ball
		end
	end
	if level >= STAGES.Fountain then
		-- a round basin of water with four jets
		for index = 0, 15 do
			local angle = index / 16 * math.pi * 2
			makePart(stand, "Basin", Vector3.new(3.4, 1.3, 1), CFrame.new(math.cos(angle) * 8.6, 0.65, math.sin(angle) * 8.6) * CFrame.Angles(0, math.pi / 2 - angle, 0), MARBLE, Enum.Material.Marble)
		end
		local water = makeCylinder(stand, "Water", 17, 0.3, Vector3.new(0, 0.4, 0), WATER, Enum.Material.Glass)
		water.Transparency = 0.3
		for index = 0, 3 do
			local angle = index / 4 * math.pi * 2 + math.pi / 4
			local jet = makePart(stand, "Jet", Vector3.one * 0.6, CFrame.new(math.cos(angle) * 6.6, 0.7, math.sin(angle) * 6.6), WATER, Enum.Material.Glass)
			jet.Transparency = 1
			emitter(jet, Color3.fromRGB(200, 235, 255), 30, 22, 0.5, true)
		end
	end
	return top
end

-- The neon sign over the brainrot: whose it is, its level and what it gives.
local function buildSign(anchor: BasePart, owner: Player, level: number, upgrades: Rebirths.Levels, color: Color3)
	local gui = Instance.new("BillboardGui")
	gui.Name = "MascotSign"
	gui.Size = UDim2.fromScale(13, 4.6)
	gui.MaxDistance = 220
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

-- (Re)builds `player`'s mascot in front of their factory. Returns where its top is.
local function build(player: Player): Vector3?
	local plot = TycoonManager.GetPlot(player)
	local data = DataManager.GetData(player)
	if not (plot and data) then
		return nil
	end
	if stands[player] then
		stands[player]:Destroy()
		stands[player] = nil
	end
	local level = data.Rebirths
	local stand = Instance.new("Model")
	stand.Name = "Mascot"
	local top = buildStand(stand, level, plot.Color)

	local parts = {}
	for _, partType in Brainrots.PartTypes do
		local id = data.Mascot[partType]
		parts[partType] = if id and Brainrots.ById[id] then id else Brainrots.StarterId
	end
	local brainrot = BrainrotModels.Build(parts)
	brainrot.Name = "MascotBrainrot"
	brainrot:ScaleTo(MascotConfig.ScaleAt(level))
	brainrot:PivotTo(CFrame.new(0, top, 0))
	local _, size = brainrot:GetBoundingBox()
	brainrot.Parent = stand

	local anchor = makePart(stand, "SignAnchor", Vector3.one * 0.2, CFrame.new(0, top + size.Y + 3, 0), OUTLINE)
	anchor.Transparency = 1
	buildSign(anchor, player, level, data.Upgrades, plot.Color)
	local promptSpot = makePart(stand, "PromptSpot", Vector3.one * 0.2, CFrame.new(0, 2.5, -2), OUTLINE)
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
	stand:PivotTo(plot.CFrame * CFrame.lookAt(spot, spot + FACING))
	stand:SetAttribute("Level", level)
	stand:SetAttribute("Top", top + size.Y)
	if level >= STAGES.Fireworks then
		CollectionService:AddTag(stand, "MascotFireworks")
	end
	stand.Parent = plot.Model
	CollectionService:AddTag(brainrot, "SpinningStatue") -- (in place: the client spins it round where it stands)
	stands[player] = stand
	return stand:GetPivot().Position + Vector3.new(0, top + size.Y, 0)
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
