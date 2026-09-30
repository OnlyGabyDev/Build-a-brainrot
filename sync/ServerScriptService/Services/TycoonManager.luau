--[[
	TycoonManager
	Owns the tycoon plots (GDD §2, §6): gives each player a plot when their data loads,
	builds what they've purchased, shows the purchase buttons in unlock order, and runs
	the collector + Cash Pad.

	All geometry is generated here as colorful placeholders, so the game is playable
	before any art exists. ProductionVisuals finds line parts by name (Belt, Assembler,
	Ship, HeadDropper, BodyDropper, ArmsDropper, LegsDropper) and animates the
	Assembler's machines (Claw: Hand, Rod, FingerLeft, FingerRight; PusherLeft and
	PusherRight: Fist, Rod): keep those names when swapping in real art.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Format = require(Shared.Format)
local TycoonItems = require(Shared.Config.TycoonItems)
local Zones = require(Shared.Config.Zones)

local DataManager = require(script.Parent.DataManager)
local MonetizationManager = require(script.Parent.MonetizationManager)

-- Layout ---------------------------------------------------------------------
-- Plot space: origin on the ground at the plot's center, -Z (front) faces the hub.

local PLOT_COUNT = 6
local PLOT_RADIUS = 210 -- hub (world origin) to plot center
local PLOT_SIZE = Vector3.new(140, 1, 120) -- one zone's floor
local FLOOR_TOP = 1
-- Each zone is a room of the factory, further back from the hub (GDD §10). By zone
-- index: Z of the room's center. The Toy Workshop sits at the plot's center.
local ZONE_Z = { 0, 120 }
local ZONE_FLOORS = {
	PlushieRoom = { Color = Color3.fromRGB(255, 205, 228), Material = Enum.Material.Fabric, Title = "🧸 PLUSHIE SEWING ROOM" },
}
local PLOT_COLORS = {
	Color3.fromRGB(255, 214, 165),
	Color3.fromRGB(190, 230, 255),
	Color3.fromRGB(210, 255, 200),
	Color3.fromRGB(255, 200, 230),
	Color3.fromRGB(230, 210, 255),
	Color3.fromRGB(255, 245, 180),
}

local SPAWN_OFFSET = CFrame.new(0, FLOOR_TOP + 4, -52) * CFrame.Angles(0, math.pi, 0) -- facing into the plot
local CASH_PAD_OFFSET = CFrame.new(0, FLOOR_TOP + 0.3, -40)
local SIGN_OFFSET = CFrame.new(0, FLOOR_TOP + 9, -61)

-- Line origins sit on the floor. Parts flow from the droppers (+Z) to the chute (-Z).
local LINE_X = { 0, -42, 42 }
local DROPPER_Z = { Head = 40, Body = 31, Arms = 22, Legs = 13 }
local STATION_Z = { Station1 = -7, Station2 = -14 }
local SPEED_X = { Speed1 = -1.5, Speed2 = 1.5 }
-- Button spots relative to the line origin. A line shows one button at a time,
-- so Speed1 and Speed2 can share a spot.
local BUTTON_OFFSETS = {
	Line = Vector3.new(0, 0, -30),
	Head = Vector3.new(11, 0, 40),
	Body = Vector3.new(11, 0, 31),
	Arms = Vector3.new(11, 0, 22),
	Legs = Vector3.new(11, 0, 13),
	Speed1 = Vector3.new(11, 0, 4),
	Speed2 = Vector3.new(11, 0, 4),
	Station1 = Vector3.new(11, 0, -7),
	Station2 = Vector3.new(11, 0, -14),
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
local WOOD_COLOR = Color3.fromRGB(205, 150, 95)
local WOOD_LIGHT_COLOR = Color3.fromRGB(235, 190, 130)
local CLAW_COLOR = Color3.fromRGB(255, 200, 60)
local FIST_COLOR = Color3.fromRGB(235, 80, 80)
local FACE_TEXTURE = "rbxasset://textures/face.png"
local SEWING_COLOR = Color3.fromRGB(255, 170, 205)
local SEWING_LIGHT_COLOR = Color3.fromRGB(255, 235, 245)
local THREAD_COLORS = { Color3.fromRGB(120, 200, 255), Color3.fromRGB(255, 150, 90) }
local AFFORDABLE_COLOR = Color3.fromRGB(80, 220, 100)
local EXPENSIVE_COLOR = Color3.fromRGB(235, 80, 80)
local BUTTON_COOLDOWN = 0.5

export type Plot = {
	Index: number,
	Model: Model,
	CFrame: CFrame,
	LinesFolder: Folder,
	ButtonsFolder: Folder,
	SignLabel: TextLabel,
	CashLabel: TextLabel,
	ZoneLabels: { [string]: TextLabel }, -- each back room's name + lock
	Owner: Player?,
	Collected: number, -- Coins waiting on the Cash Pad
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

local function isZoneUnlocked(data: DataManager.PlayerData, zoneId: string): boolean
	local zone = Zones.ById[zoneId]
	return zone ~= nil and zone.Available and data.Rebirths >= zone.UnlockRebirths
end

-- Items ----------------------------------------------------------------------

local function lineOrigin(plot: Plot, lineId: string): CFrame
	local line = TycoonItems.LinesById[lineId]
	local zone = Zones.ById[line.Zone]
	return plot.CFrame * CFrame.new(LINE_X[line.Index], FLOOR_TOP, ZONE_Z[zone.Index])
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

-- The Assembler's claw hangs from the gantry. Its grip point (under the hand) rests
-- at `CLAW_REST_Y`; the rod stretches up to the gantry as it moves.
local CLAW_REST_Y = 7
local GANTRY_BOTTOM_Y = 11

local function buildClaw(parent: Model, origin: CFrame)
	local claw = Instance.new("Model")
	claw.Name = "Claw"
	local grip = origin * CFrame.new(0, CLAW_REST_Y, 0)
	makePart(claw, "Hand", Vector3.new(1.8, 0.6, 1.8), grip * CFrame.new(0, 0.3, 0), CLAW_COLOR)
	makePart(claw, "FingerLeft", Vector3.new(0.3, 0.9, 1.2), grip * CFrame.new(-0.75, -0.45, 0), METAL_COLOR)
	makePart(claw, "FingerRight", Vector3.new(0.3, 0.9, 1.2), grip * CFrame.new(0.75, -0.45, 0), METAL_COLOR)
	local rodLength = GANTRY_BOTTOM_Y - (CLAW_REST_Y + 0.6)
	makePart(claw, "Rod", Vector3.new(0.4, rodLength, 0.4), grip * CFrame.new(0, 0.6 + rodLength / 2, 0), METAL_COLOR)
	claw.Parent = parent
end

-- A wooden toy robot beside the pad that punches the arms into place. Its rod runs
-- from the shoulder to the fist, with the fist at the rod's -Z end.
local function buildPusher(parent: Model, origin: CFrame, side: number)
	local pusher = Instance.new("Model")
	pusher.Name = if side < 0 then "PusherLeft" else "PusherRight"
	local x = 5.6 * side
	makePart(pusher, "Body", Vector3.new(1.4, 2.6, 1.6), origin * CFrame.new(x, 1.3, 0), WOOD_COLOR, Enum.Material.Wood)
	local head = makePart(pusher, "Head", Vector3.new(1.3, 1.1, 1.3), origin * CFrame.new(x, 3.15, 0), WOOD_LIGHT_COLOR, Enum.Material.Wood)
	local face = Instance.new("Decal")
	face.Texture = FACE_TEXTURE
	face.Face = if side < 0 then Enum.NormalId.Right else Enum.NormalId.Left -- looks at the pad
	face.Parent = head
	if side > 0 then
		head:SetAttribute("PromptAnchor", true) -- the "Configure line" prompt lives here
	end

	local shoulder = (origin * CFrame.new(x - 0.7 * side, 2.2, 0)).Position
	local fist = (origin * CFrame.new(4.1 * side, 2.2, 0)).Position
	makePart(pusher, "Fist", Vector3.new(0.8, 0.8, 0.8), origin.Rotation + fist, FIST_COLOR)
	local rod = makePart(pusher, "Rod", Vector3.new(0.35, 0.35, (fist - shoulder).Magnitude), CFrame.lookAt((shoulder + fist) / 2, fist), METAL_COLOR)
	rod.CanCollide = false
	pusher.Parent = parent
end

-- The Plushie Sewing Room's Assembler: a sewing-machine head whose needle stitches
-- parts on, and two thread spools beside the pad that reel the arms in. Each thread
-- runs from its spool toward the pad, with its free end at the rod's -Z end.
local NEEDLE_REST_Y = 7 -- needle tip height at rest

local function buildSewingMachine(parent: Model, origin: CFrame)
	makePart(parent, "NeedleHead", Vector3.new(1.8, 1.6, 1.8), origin * CFrame.new(0, GANTRY_BOTTOM_Y - 0.8, 0), SEWING_LIGHT_COLOR)
	local needle = makePart(parent, "Needle", Vector3.new(0.25, 2.4, 0.25), origin * CFrame.new(0, NEEDLE_REST_Y + 1.2, 0), Color3.fromRGB(215, 215, 230), Enum.Material.Metal)
	needle.CanCollide = false
	for index, side in { -1, 1 } do
		local suffix = if side < 0 then "Left" else "Right"
		local x = 5.6 * side
		local pedestal = makePart(parent, `Pedestal{suffix}`, Vector3.new(1.4, 1.6, 1.4), origin * CFrame.new(x, 0.8, 0), SEWING_LIGHT_COLOR)
		if side > 0 then
			pedestal:SetAttribute("PromptAnchor", true)
		end
		local spool = makePart(parent, `Spool{suffix}`, Vector3.new(1.4, 1.8, 1.8), origin * CFrame.new(x, 2.3, 0) * CFrame.Angles(0, 0, math.pi / 2), THREAD_COLORS[index])
		spool.Shape = Enum.PartType.Cylinder -- rotated so the spool stands upright
		local tip = (origin * CFrame.new(x - 1.2 * side, 2.3, 0)).Position
		local thread = makePart(parent, `Thread{suffix}`, Vector3.new(0.15, 0.15, 1.2), CFrame.lookAt((spool.Position + tip) / 2, tip), THREAD_COLORS[index], Enum.Material.Neon)
		thread.CanCollide = false
	end
end

-- Gantry colors per zone: { pillars, beam }.
local GANTRY_COLORS = {
	ToyWorkshop = { Color3.fromRGB(110, 60, 200), GANTRY_COLOR },
	PlushieRoom = { SEWING_LIGHT_COLOR, SEWING_COLOR },
}

local BUILDERS: { [string]: (model: Model, origin: CFrame, item: TycoonItems.Item) -> () } = {
	Line = function(model, origin, item)
		makePart(model, "Belt", Vector3.new(8, 1, 62), origin * CFrame.new(0, 0.5, 13), Color3.fromRGB(60, 60, 70))
		for _, side in { -1, 1 } do
			local rail = if side < 0 then "RailLeft" else "RailRight"
			makePart(model, rail, Vector3.new(0.6, 1.4, 62), origin * CFrame.new(4.3 * side, 0.7, 13), Color3.fromRGB(255, 170, 60))
		end

		-- The Assembler: a gantry over the pad, with the zone's machines.
		local colors = GANTRY_COLORS[item.Zone] or GANTRY_COLORS.ToyWorkshop
		for _, corner in { Vector2.new(-1, -1), Vector2.new(-1, 1), Vector2.new(1, -1), Vector2.new(1, 1) } do
			local cframe = origin * CFrame.new(6.9 * corner.X, GANTRY_BOTTOM_Y / 2, 5 * corner.Y)
			makePart(model, "AssemblerPillar", Vector3.new(1.2, GANTRY_BOTTOM_Y, 1.2), cframe, colors[1])
		end
		makePart(model, "Assembler", Vector3.new(15, 2, 11.2), origin * CFrame.new(0, GANTRY_BOTTOM_Y + 1, 0), colors[2])
		if item.Zone == "PlushieRoom" then
			buildSewingMachine(model, origin)
		else
			buildClaw(model, origin)
			buildPusher(model, origin, -1)
			buildPusher(model, origin, 1)
		end

		local ship = makePart(model, "Ship", Vector3.new(10, 6, 6), origin * CFrame.new(0, 3, -21), Color3.fromRGB(255, 140, 50))
		makeBillboard(ship, "SHIPPING", Vector2.new(8, 2), 4.5, 80)
	end,

	Dropper = function(model, origin, item)
		local partType = item.PartType :: string
		local z = DROPPER_Z[partType]
		local dropper = makePart(model, partType .. "Dropper", Vector3.new(6, 4, 6), origin * CFrame.new(0, 10, z), PART_COLORS[partType])
		makePart(model, partType .. "DropperPillar", Vector3.new(1.2, 12.8, 1.2), origin * CFrame.new(-6, 6.4, z), METAL_COLOR)
		makePart(model, partType .. "DropperArm", Vector3.new(6, 0.8, 0.8), origin * CFrame.new(-3, 12.4, z), METAL_COLOR)
		makeBillboard(dropper, string.upper(partType), Vector2.new(5, 1.5), 3.2, 80)
	end,

	-- A glowing turbo stripe along the belt.
	Speed = function(model, origin, item)
		local stripe = Vector3.new(0.8, 0.1, 60)
		makePart(model, item.Key, stripe, origin * CFrame.new(SPEED_X[item.Key], 1.05, 13), Color3.fromRGB(255, 230, 60), Enum.Material.Neon)
	end,

	-- An arch over the belt that brainrots ride through.
	Station = function(model, origin, item)
		local z = STATION_Z[item.Key]
		local color = STATION_COLORS[item.Key]
		local top = makePart(model, item.Key, Vector3.new(11.4, 1.5, 3), origin * CFrame.new(0, 8, z), color)
		makePart(model, item.Key .. "LegLeft", Vector3.new(1, 7.25, 1), origin * CFrame.new(-5.2, 3.625, z), color)
		makePart(model, item.Key .. "LegRight", Vector3.new(1, 7.25, 1), origin * CFrame.new(5.2, 3.625, z), color)
		makePart(model, item.Key .. "Glow", Vector3.new(9, 0.3, 2.4), origin * CFrame.new(0, 7.1, z), Color3.new(1, 1, 1), Enum.Material.Neon)
		makeBillboard(top, string.upper(item.Name), Vector2.new(8, 1.5), 2, 80)
	end,
}

local function buildItem(plot: Plot, item: TycoonItems.Item)
	BUILDERS[item.Kind](getLineModel(plot, item.LineId), lineOrigin(plot, item.LineId), item)
end

-- Buttons --------------------------------------------------------------------

local function priceText(price: number): string
	return if price == 0 then "FREE" else `💰 {Format.Number(price)}`
end

local function updateButtonColors(plot: Plot)
	local coins = if plot.Owner then DataManager.GetCurrency(plot.Owner, "Coins") else 0
	for itemId, button in plot.Buttons do
		button.Color = if coins >= TycoonItems.ById[itemId].Price then AFFORDABLE_COLOR else EXPENSIVE_COLOR
	end
end

local refreshButtons: (plot: Plot) -> ()

local function onButtonTouched(plot: Plot, item: TycoonItems.Item, hit: BasePart)
	local player = getPlayerFromHit(hit)
	if not player or player ~= plot.Owner or not plot.Buttons[item.Id] then
		return
	end
	local now = os.clock()
	if (buttonCooldowns[player] or 0) > now then
		return
	end
	buttonCooldowns[player] = now + BUTTON_COOLDOWN

	if DataManager.PurchaseItem(player, item.Id, item.Price) then
		buildItem(plot, item)
		refreshButtons(plot)
	end
end

local function createButton(plot: Plot, item: TycoonItems.Item)
	local offset = BUTTON_OFFSETS[item.Key]
	local cframe = lineOrigin(plot, item.LineId) * CFrame.new(offset.X, 0.2, offset.Z)
	local button = makePart(plot.ButtonsFolder, item.Id, Vector3.new(5, 0.4, 5), cframe, AFFORDABLE_COLOR, Enum.Material.Neon)
	makeBillboard(button, `{item.Name}\n{priceText(item.Price)}`, Vector2.new(7, 2.5), 3, 60)
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
			visible = isZoneUnlocked(data, item.Zone)
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

local function updateCashLabel(plot: Plot)
	plot.CashLabel.Text = `💰 {Format.Number(plot.Collected)}\nStep here to collect!`
end

-- Each back room's sign shows its name, with a lock until the owner unlocks it.
local function updateZoneLabels(plot: Plot)
	local data = plot.Owner and DataManager.GetData(plot.Owner)
	for zoneId, label in plot.ZoneLabels do
		local zone = Zones.ById[zoneId]
		local title = ZONE_FLOORS[zoneId].Title
		label.Text = if data and data.Rebirths >= zone.UnlockRebirths then title else `{title}\n🔒 REBIRTH {zone.UnlockRebirths}`
	end
end

-- A sign with text on its front face (-Z of `cframe`).
local function makeSign(parent: Instance, name: string, size: Vector3, cframe: CFrame, color: Color3, text: string): TextLabel
	local sign = makePart(parent, name, size, cframe, Color3.new(1, 1, 1))
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

local function buildPlot(index: number, parent: Instance): Plot
	local angle = (index - 1) / PLOT_COUNT * math.pi * 2
	local center = Vector3.new(math.sin(angle), 0, math.cos(angle)) * PLOT_RADIUS
	local cframe = CFrame.lookAt(center, Vector3.zero) -- -Z faces the hub

	local model = Instance.new("Model")
	model.Name = `Plot{index}`
	model.WorldPivot = cframe
	model.Parent = parent

	makePart(model, "Floor", PLOT_SIZE, cframe * CFrame.new(0, FLOOR_TOP - PLOT_SIZE.Y / 2, 0), PLOT_COLORS[index])

	-- Back rooms for the later zones, each behind the last, with a sign over the entrance.
	local zoneLabels = {}
	for zoneId, style in ZONE_FLOORS do
		local zone = Zones.ById[zoneId]
		local z = ZONE_Z[zone.Index]
		if zone.Available and z then
			local floor = makePart(model, `{zoneId}Floor`, PLOT_SIZE, cframe * CFrame.new(0, FLOOR_TOP - PLOT_SIZE.Y / 2, z), style.Color, style.Material)
			floor.TopSurface = Enum.SurfaceType.Smooth
			local entrance = z - PLOT_SIZE.Z / 2
			zoneLabels[zoneId] = makeSign(model, `{zoneId}Sign`, Vector3.new(34, 7, 1), cframe * CFrame.new(0, FLOOR_TOP + 14, entrance), Color3.fromRGB(255, 110, 180), style.Title)
			for _, side in { -1, 1 } do
				makePart(model, `{zoneId}SignPost`, Vector3.new(1.2, 17.5, 1.2), cframe * CFrame.new(16 * side, FLOOR_TOP + 8.75, entrance), style.Color)
			end
		end
	end

	local signLabel = makeSign(model, "Sign", Vector3.new(30, 6, 1), cframe * SIGN_OFFSET, Color3.fromRGB(255, 120, 200), "Empty Plot")
	for _, side in { -1, 1 } do
		makePart(model, "SignPost", Vector3.new(1, 6, 1), cframe * CFrame.new(12 * side, FLOOR_TOP + 3, -61), METAL_COLOR)
	end

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
		LinesFolder = linesFolder,
		ButtonsFolder = buttonsFolder,
		SignLabel = signLabel,
		CashLabel = cashLabel,
		ZoneLabels = zoneLabels,
		Owner = nil,
		Collected = 0,
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
local function furnishPlot(plot: Plot, player: Player, data: DataManager.PlayerData)
	for _, item in TycoonItems.List do
		if item.Price == 0 and item.Requires == nil and isZoneUnlocked(data, item.Zone) then
			DataManager.PurchaseItem(player, item.Id, 0)
		end
	end
	for _, item in TycoonItems.List do
		if data.Tycoon.Purchased[item.Id] then
			buildItem(plot, item)
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
	updateCashLabel(plot)
	updateZoneLabels(plot)
end

-- Public API -----------------------------------------------------------------

function TycoonManager.Init()
	local folder = Instance.new("Folder")
	folder.Name = "Tycoons"
	folder.Parent = workspace
	for index = 1, PLOT_COUNT do
		plots[index] = buildPlot(index, folder)
	end

	DataManager.OnPlayerLoaded(claimPlot)
	Players.PlayerRemoving:Connect(releasePlot)
end

function TycoonManager.GetPlot(player: Player): Plot?
	return plotByPlayer[player]
end

-- Whether a world position is over any tycoon plot (any of its rooms). Plots are
-- safe zones (GDD §3).
function TycoonManager.IsInPlot(position: Vector3): boolean
	local back = ZONE_Z[#ZONE_Z] + PLOT_SIZE.Z / 2
	for _, plot in plots do
		local offset = plot.CFrame:PointToObjectSpace(position)
		if math.abs(offset.X) <= PLOT_SIZE.X / 2 and offset.Z >= -PLOT_SIZE.Z / 2 and offset.Z <= back then
			return true
		end
	end
	return false
end

-- After a rebirth (the data is already reset): clears the tycoon and furnishes it
-- again, including the free first line of any zone that just unlocked.
function TycoonManager.ResetPlot(player: Player)
	local plot = plotByPlayer[player]
	local data = DataManager.GetData(player)
	if not (plot and data) then
		return
	end
	plot.LinesFolder:ClearAllChildren()
	plot.ButtonsFolder:ClearAllChildren()
	table.clear(plot.Buttons)
	plot.Collected = 0
	updateCashLabel(plot)
	furnishPlot(plot, player, data)
end

-- Adds shipped Coins to the player's collector. They bank them on the Cash Pad, or
-- straight away with the Auto-Collect gamepass.
function TycoonManager.AddToCollector(player: Player, amount: number)
	local plot = plotByPlayer[player]
	if plot and MonetizationManager.OwnsPass(player, "AutoCollect") then
		DataManager.AddCurrency(player, "Coins", amount)
	elseif plot then
		plot.Collected += amount
		updateCashLabel(plot)
	end
end

return TycoonManager
