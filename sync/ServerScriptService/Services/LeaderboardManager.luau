--[[
	LeaderboardManager
	The hub's top players (the user's request, GDD §13): four boards round the fountain
	(most Robux spent, most playtime, most rebirths, most Coins earned), each the top 10
	of every player ever (OrderedDataStores), and a podium with the top 3 by Coins
	earned standing on it as their own avatars, their names over their heads. The spots
	come from MapBuilder (the gaps between the plaza's carpets).

	Stats come from DataManager: Stats.RobuxSpent (MonetizationManager adds each
	purchase), Stats.Playtime (added here, every minute), Rebirths, Stats.TotalCoinsEarned.
	Each player's values are written every couple of minutes; the boards re-read every
	minute and a half. Studio uses stores of its own (_Studio).
]]

local CollectionService = game:GetService("CollectionService")
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Format = require(ReplicatedStorage.Shared.Format)
local DataManager = require(script.Parent.DataManager)
local MapBuilder = require(script.Parent.MapBuilder)

local LeaderboardManager = {}

local SUFFIX = if RunService:IsStudio() then "_Studio" else ""
local ROWS = 10
local PLAYTIME_TICK = 60
local WRITE_EVERY = 120
local READ_EVERY = 90
local BOARD = Vector2.new(22, 16) -- studs
local GOLD = Color3.fromRGB(255, 205, 60)
local WHITE = Color3.new(1, 1, 1)
local INK = Color3.fromRGB(30, 25, 45)
local STEP_COLORS = { Color3.fromRGB(255, 200, 50), Color3.fromRGB(205, 210, 225), Color3.fromRGB(215, 135, 70) }

local function hours(seconds: number): string
	local h = math.floor(seconds / 3600)
	return if h > 0 then `{h}h {math.floor(seconds % 3600 / 60)}m` else `{math.floor(seconds / 60)}m`
end

type Board = {
	Key: string,
	Title: string,
	Color: Color3,
	Value: (data: DataManager.PlayerData) -> number,
	Show: (value: number) -> string,
	Store: OrderedDataStore?,
	Rows: { { Name: TextLabel, Value: TextLabel } },
	Top: { { UserId: number, Value: number } },
}

local BOARDS: { Board } = {
	{ Key = "RobuxSpent", Title = "TOP ROBUX SPENT", Color = Color3.fromRGB(90, 220, 110), Value = function(data)
		return data.Stats.RobuxSpent
	end, Show = function(value)
		return `{Format.Number(value)} {Format.ROBUX}`
	end, Rows = {}, Top = {} },
	{ Key = "Playtime", Title = "TOP PLAYTIME", Color = Color3.fromRGB(90, 180, 255), Value = function(data)
		return data.Stats.Playtime
	end, Show = hours, Rows = {}, Top = {} },
	{ Key = "Rebirths", Title = "TOP REBIRTHS", Color = Color3.fromRGB(190, 120, 255), Value = function(data)
		return data.Rebirths
	end, Show = function(value)
		return `{Format.Number(value)}`
	end, Rows = {}, Top = {} },
	{ Key = "CoinsEarned", Title = "TOP MONEY EARNED", Color = GOLD, Value = function(data)
		return data.Stats.TotalCoinsEarned
	end, Show = function(value)
		return `${Format.Number(value)}`
	end, Rows = {}, Top = {} },
}
local MONEY = BOARDS[4]

local names: { [number]: string } = {}
local function nameOf(userId: number): string
	if names[userId] then
		return names[userId]
	end
	local online = Players:GetPlayerByUserId(userId)
	local ok, name = pcall(Players.GetNameFromUserIdAsync, Players, userId)
	local found = if online then online.Name elseif ok and name then name else "???"
	names[userId] = found
	return found
end

-- Building -----------------------------------------------------------------------

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

local function text(parent: Instance, value: string, size: UDim2, position: UDim2, color: Color3, align: Enum.TextXAlignment?): TextLabel
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = size
	label.Position = position
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = color
	label.TextXAlignment = align or Enum.TextXAlignment.Center
	label.Text = value
	label.Parent = parent
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2.5
	stroke.Color = INK
	stroke.Parent = label
	return label
end

-- A board on two gold posts (`spot`: on the paving under its middle, -Z toward the
-- fountain), its title glowing in its color, ten rows.
local function buildBoard(parent: Instance, spot: CFrame, board: Board)
	local bottom = 3
	for _, x in { -BOARD.X / 2 + 1, BOARD.X / 2 - 1 } do
		makePart(parent, "BoardPost", Vector3.new(1, bottom + BOARD.Y + 1, 1), spot * CFrame.new(x, (bottom + BOARD.Y + 1) / 2, 0.4), GOLD, Enum.Material.Metal)
	end
	local panel = makePart(parent, "Board", Vector3.new(BOARD.X, BOARD.Y, 0.6), spot * CFrame.new(0, bottom + BOARD.Y / 2, 0), Color3.fromRGB(40, 30, 70))
	makePart(parent, "BoardFrame", Vector3.new(BOARD.X + 1, BOARD.Y + 1, 0.4), panel.CFrame * CFrame.new(0, 0, 0.3), board.Color)
	local glow = makePart(parent, "BoardGlow", Vector3.new(BOARD.X + 1.2, 0.35, 0.5), panel.CFrame * CFrame.new(0, BOARD.Y / 2 + 0.6, 0), board.Color, Enum.Material.Neon)
	glow.CanCollide = false
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 30
	gui.LightInfluence = 0
	gui.Brightness = 1.4
	gui.Parent = panel
	local title = text(gui, board.Title, UDim2.fromScale(0.92, 0.13), UDim2.fromScale(0.04, 0.02), board.Color:Lerp(WHITE, 0.4))
	local titleStroke = title:FindFirstChildOfClass("UIStroke")
	if titleStroke then
		titleStroke.Color = board.Color:Lerp(INK, 0.6)
	end
	for row = 1, ROWS do
		local y = 0.17 + (row - 1) * 0.081
		local band = Instance.new("Frame")
		band.Size = UDim2.fromScale(0.94, 0.072)
		band.Position = UDim2.fromScale(0.03, y)
		band.BackgroundColor3 = if row % 2 == 0 then Color3.fromRGB(60, 48, 100) else Color3.fromRGB(75, 60, 120)
		band.Parent = gui
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0.3, 0)
		corner.Parent = band
		local rank = text(band, `#{row}`, UDim2.fromScale(0.12, 0.9), UDim2.fromScale(0.01, 0.05), WHITE)
		rank.TextColor3 = if row <= 3 then STEP_COLORS[row] else WHITE
		local name = text(band, "...", UDim2.fromScale(0.5, 0.8), UDim2.fromScale(0.15, 0.1), WHITE, Enum.TextXAlignment.Left)
		local value = text(band, "", UDim2.fromScale(0.32, 0.8), UDim2.fromScale(0.66, 0.1), board.Color:Lerp(WHITE, 0.35), Enum.TextXAlignment.Right)
		board.Rows[row] = { Name = name, Value = value }
	end
end

-- The podium: three steps (gold in the middle, silver left, bronze right) with their
-- numbers, and a glowing sign behind.
local STEP_HEIGHTS = { 6, 4.5, 3 }
local STEP_X = { 0, -8.5, 8.5 }
local podiumFolder: Folder? = nil
local podiumSpot: CFrame? = nil
local standing: { number } = {} -- who's on it (user ids), in place order

local function buildPodium(parent: Instance, spot: CFrame)
	for place = 1, 3 do
		local step = makePart(parent, "PodiumStep", Vector3.new(8, STEP_HEIGHTS[place], 8), spot * CFrame.new(STEP_X[place], STEP_HEIGHTS[place] / 2, 0), STEP_COLORS[place], if place == 1 then Enum.Material.Metal else nil)
		-- a hair (0.05) under the step's top: level with it, the two tops z-fought
		makePart(parent, "PodiumTrim", Vector3.new(8.3, 0.4, 8.3), step.CFrame * CFrame.new(0, STEP_HEIGHTS[place] / 2 - 0.25, 0), WHITE)
		local gui = Instance.new("SurfaceGui")
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.Face = Enum.NormalId.Front
		gui.LightInfluence = 0
		gui.Parent = step
		text(gui, `{place}`, UDim2.fromScale(0.5, 0.7), UDim2.fromScale(0.25, 0.15), WHITE)
	end
	-- the sign high over the winners' name tags (the gold step's tag reaches ~19)
	local sign = makePart(parent, "PodiumSign", Vector3.new(26, 4, 0.5), spot * CFrame.new(0, 24, 6), Color3.fromRGB(40, 30, 70))
	for _, x in { -12, 12 } do
		makePart(parent, "PodiumSignPost", Vector3.new(0.8, 26, 0.8), spot * CFrame.new(x, 13, 6.4), GOLD, Enum.Material.Metal)
	end
	local gui = Instance.new("SurfaceGui")
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 30 -- scaled text tops out at 100 px: this lets it fill the face
	gui.Face = Enum.NormalId.Front
	gui.LightInfluence = 0
	gui.Brightness = 2
	gui.Parent = sign
	text(gui, "RICHEST PLAYERS", UDim2.fromScale(0.94, 0.8), UDim2.fromScale(0.03, 0.1), GOLD)
	local folder = Instance.new("Folder")
	folder.Name = "PodiumAvatars"
	folder.Parent = parent
	podiumFolder = folder
	podiumSpot = spot
end

-- Puts `userId`'s avatar on step `place`, a statue (it's spared by the nuke).
local function standOn(place: number, userId: number, value: number)
	local folder, spot = podiumFolder, podiumSpot
	if not (folder and spot) then
		return
	end
	local ok, avatar = pcall(Players.CreateHumanoidModelFromUserId, Players, userId)
	if not (ok and avatar) then
		return
	end
	avatar.Name = `Top{place}`
	-- a statue: only its root is anchored, so its joints keep every accessory in place
	for _, descendant in avatar:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.CanCollide = false
			descendant.CanTouch = false
			descendant.CanQuery = false
		elseif descendant:IsA("Script") or descendant:IsA("LocalScript") then
			descendant:Destroy()
		end
	end
	local root = avatar:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		avatar:Destroy()
		return
	end
	root.Anchored = true
	local humanoid = avatar:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	end
	CollectionService:AddTag(avatar, "NukeProof")
	avatar.Parent = folder
	avatar:ScaleTo(1.5)
	-- stand it on the step, facing the fountain, its feet on the top
	local top = spot * CFrame.new(STEP_X[place], STEP_HEIGHTS[place], 0)
	avatar:PivotTo(top)
	task.wait() -- (let the accessories settle on their joints)
	local lowest = math.huge
	for _, part in avatar:GetDescendants() do
		if part:IsA("BasePart") and (string.find(part.Name, "Foot") or string.find(part.Name, "Leg")) then
			lowest = math.min(lowest, part.Position.Y - part.Size.Y / 2)
		end
	end
	if lowest < math.huge then
		avatar:PivotTo(top + Vector3.new(0, top.Y - lowest, 0))
	end
	-- the name over its head
	local head = avatar:FindFirstChild("Head") :: BasePart?
	if head then
		-- sized in studs (narrower than the 8.5 between steps), so neighbors' tags never
		-- run into each other however far you stand; over the avatar's very top, hats and
		-- all
		local frame, size = avatar:GetBoundingBox()
		local tag = Instance.new("BillboardGui")
		tag.Size = UDim2.fromScale(8, 2.6)
		tag.StudsOffsetWorldSpace = Vector3.new(0, frame.Position.Y + size.Y / 2 - head.Position.Y + 1.5, 0)
		tag.MaxDistance = 220
		tag.Parent = head
		text(tag, nameOf(userId), UDim2.fromScale(1, 0.55), UDim2.fromScale(0, 0), WHITE)
		text(tag, MONEY.Show(value), UDim2.fromScale(1, 0.42), UDim2.fromScale(0, 0.58), GOLD)
	end
end

local function refreshPodium()
	local top = MONEY.Top
	local ids = {}
	for place = 1, 3 do
		ids[place] = if top[place] then top[place].UserId else 0
	end
	if ids[1] == standing[1] and ids[2] == standing[2] and ids[3] == standing[3] then
		return
	end
	standing = ids
	if podiumFolder then
		podiumFolder:ClearAllChildren()
	end
	for place = 1, 3 do
		local entry = top[place]
		if entry then
			task.spawn(standOn, place, entry.UserId, entry.Value)
		end
	end
end

-- Reading and writing ------------------------------------------------------------------

local function write(player: Player)
	local data = DataManager.GetData(player)
	if not (data and DataManager.IsSaved(player)) then
		return
	end
	for _, board in BOARDS do
		local store = board.Store
		if store then
			local value = math.floor(board.Value(data))
			pcall(store.SetAsync, store, tostring(player.UserId), value)
		end
	end
end

local function read(board: Board)
	local store = board.Store
	if not store then
		return
	end
	local ok, pages = pcall(store.GetSortedAsync, store, false, ROWS)
	if not (ok and pages) then
		return
	end
	local top = {}
	for _, entry in (pages :: DataStorePages):GetCurrentPage() do
		local userId = tonumber(entry.key)
		if userId and type(entry.value) == "number" then
			table.insert(top, { UserId = userId, Value = entry.value })
		end
	end
	board.Top = top
	for row = 1, ROWS do
		local entry = top[row]
		local labels = board.Rows[row]
		if labels then
			labels.Name.Text = if entry then nameOf(entry.UserId) else "—"
			labels.Value.Text = if entry then board.Show(entry.Value) else ""
		end
	end
end

local function readAll()
	for _, board in BOARDS do
		read(board)
	end
	refreshPodium()
end

function LeaderboardManager.Init()
	local hub = workspace:FindFirstChild("Hub") or workspace
	local folder = Instance.new("Folder")
	folder.Name = "Leaderboards"
	folder.Parent = hub
	for index, board in BOARDS do
		local spot = MapBuilder.BoardSpots[index]
		if spot then
			buildBoard(folder, spot, board)
		end
		local ok, store = pcall(DataStoreService.GetOrderedDataStore, DataStoreService, `Top_{board.Key}{SUFFIX}`)
		board.Store = if ok then store else nil
	end
	if MapBuilder.PodiumSpot then
		buildPodium(folder, MapBuilder.PodiumSpot)
	end

	-- a player's values go up as soon as they've loaded, then every couple of minutes
	DataManager.OnPlayerLoaded(function(player)
		task.wait(5)
		write(player)
		readAll()
	end)
	task.spawn(function()
		while true do
			task.wait(PLAYTIME_TICK)
			for _, player in Players:GetPlayers() do
				DataManager.AddStat(player, "Playtime", PLAYTIME_TICK)
			end
		end
	end)
	task.spawn(function()
		while true do
			task.wait(WRITE_EVERY)
			for _, player in Players:GetPlayers() do
				write(player)
			end
		end
	end)
	task.spawn(function()
		task.wait(8)
		while true do
			readAll()
			task.wait(READ_EVERY)
		end
	end)
end

return LeaderboardManager
