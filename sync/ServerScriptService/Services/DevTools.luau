--[[
	DevTools (developers only: Studio, the owner's UserId, or rank 250+ in the group)
	Test helpers for playtests and live servers, reachable from the command bar or the Studio MCP
	through a BindableFunction (module requires there get separate copies, but
	instances are shared):

	  local dev = game.ServerStorage.DevCommand
	  dev:Invoke("AddCoins", player, 50000)
	  dev:Invoke("Snapshot", player)   -- before a destructive test (e.g. rebirthing)
	  dev:Invoke("Restore", player)    -- puts the data back and rebuilds the tycoon
	  dev:Invoke("ShowOnLine", player, "TrippiTroppi", lineId) -- to see its art on a line
	  dev:Invoke("BuildUpgrade", player, "ToyWorkshop_Decor_ToyTrain_2") -- a room upgrade level drops in
	  dev:Invoke("ResetPlot", player)  -- rebuilds the tycoon from the data
	  dev:Invoke("SetPurchased", player, "Floor_3", false) -- un-buys an item (free) and rebuilds
	  dev:Invoke("SetPurchasedList", player, { "ClayStudio_Room", "ClayStudio_1_Line" }, true)
	  dev:Invoke("GrantPass", player, "Sprint") -- a gamepass for this session (not saved)
	  dev:Invoke("GrantProduct", player, "Drop100") -- a developer product, free (it saves)
	  dev:Invoke("SpawnBox", player, "Legendary", 3) -- loot boxes of a rarity land round you
	  dev:Invoke("Nuke", player)          -- drops a nuke on the server (everyone dies)
	  dev:Invoke("CreateThumb", player)   -- a stage for the game's icon (/dev CreateThumb)

	The Studio MCP's own code can't invoke it any more (since 2026-10-02 its thread lacks
	the modules' capabilities), but it can set attributes: set workspace's DevRequest to
	a JSON array, the command's name then its arguments, and the result lands in
	DevResult (JSON: { ok, result }). It runs for the first player:

	  workspace:SetAttribute("DevRequest", '["AddCoins", 50000]')

	In a playtest, any of them also runs from the chat for whoever types it (words after
	the name are its arguments; numbers and true/false are read as such):

	  /dev SpawnBox Legendary 3
	  /dev GrantPass Sprint

	On live servers they run for developers only (isDeveloper), from the 🛠️ DEV menu
	(Client/UI/DevMenu, remote DevMenu) or /dev in the chat. They write real saves there:
	AddCoins and the like also reach the global leaderboards, and Nuke kills everyone.
]]

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local TextChatService = game:GetService("TextChatService")

local Shared = ReplicatedStorage.Shared
local Remotes = require(Shared.Remotes)
local BrainrotModels = require(Shared.BrainrotModels)
local Brainrots = require(Shared.Config.Brainrots)
local DataManager = require(script.Parent.DataManager)
local LootManager = require(script.Parent.LootManager)
local MonetizationManager = require(script.Parent.MonetizationManager)
local NukeManager = require(script.Parent.NukeManager)
local TycoonManager = require(script.Parent.TycoonManager)

local function isDeveloper(player: Player): boolean
	if RunService:IsStudio() or player.UserId == 114553410 then
		return true
	end
	if game.CreatorType == Enum.CreatorType.Group then
		-- (GroupService:GetRolesInGroupAsync, its replacement, lists no roles for this
		-- group's owner, so this keeps the older call)
		local ok, rank = pcall((player :: any).GetRankInGroupAsync, player, game.CreatorId)
		return ok and rank >= 250
	else
		return player.UserId == game.CreatorId
	end
end

local snapshots: { [Player]: DataManager.PlayerData } = {}

-- The game icon's scene (CreateThumb): far off over the valley, facing -Z (the way
-- brainrots face). The star is a custom brainrot, a mix of four (change THUMB_HERO to
-- try others), huge, crowned and glowing on a gold stage; two smaller brainrots flank
-- it; behind, a turning-looking sunburst; light beams, sparkles, floating loot boxes,
-- coins and a big neon sign.
local THUMB_ORIGIN = CFrame.new(0, 320, -1600)
local THUMB_HERO = { Head = "TrippiTroppi", Body = "LaVacaSaturnoSaturnita", Arms = "ChimpanziniBananini", Legs = "ChimpanziniBananini" }
local THUMB_HERO_SCALE = 4.2
local THUMB_CAMERA_YAW = 20 -- degrees round from straight in front
local THUMB_FILL = 0.72 -- how much of the frame's height the star fills
-- (matte, saturated colors: Neon blooms to white in game, so it's only for small accents)
local THUMB_PINK, THUMB_PURPLE, THUMB_GOLD = Color3.fromRGB(235, 50, 160), Color3.fromRGB(95, 35, 200), Color3.fromRGB(255, 185, 30)
local THUMB_RAINBOW = { Color3.fromRGB(255, 90, 90), Color3.fromRGB(255, 200, 60), Color3.fromRGB(90, 230, 120), Color3.fromRGB(80, 180, 255), Color3.fromRGB(200, 110, 255) }

local function thumbPart(parent: Instance, size: Vector3, cframe: CFrame, color: Color3, material: Enum.Material?, shape: Enum.PartType?): Part
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.Shape = shape or Enum.PartType.Block
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

-- A brainrot from `parts` ([partType] = brainrotId; mixes fit like on a line), `scale`
-- times its size, standing on `root`.
local function thumbBrainrot(parts: { [string]: string }, scale: number, root: CFrame): Model
	local brainrot = Instance.new("Model")
	brainrot.Name = "Brainrot"
	local homes, spread = BrainrotModels.Layout(parts)
	for _, partType in Brainrots.PartTypes do
		local part = BrainrotModels.CreatePart(parts[partType], partType, nil, spread)
		part:PivotTo(CFrame.new(homes[partType] or Vector3.zero))
		for _, child in part:GetChildren() do
			child.Parent = brainrot
		end
		part:Destroy()
	end
	brainrot.WorldPivot = CFrame.identity
	brainrot:ScaleTo(scale)
	brainrot:PivotTo(root)
	return brainrot
end

local function sparkles(part: BasePart, color: Color3, rate: number)
	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	emitter.Color = ColorSequence.new(color)
	emitter.LightEmission = 1
	emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 0) })
	emitter.Lifetime = NumberRange.new(1, 2)
	emitter.Speed = NumberRange.new(2, 5)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Rate = rate
	emitter.Parent = part
end

local function giftBox(parent: Instance, cframe: CFrame, size: number, color: Color3)
	thumbPart(parent, Vector3.one * size, cframe, color)
	thumbPart(parent, Vector3.new(size * 0.22, size + 0.05, size + 0.05), cframe, THUMB_GOLD, Enum.Material.Metal)
	thumbPart(parent, Vector3.new(size + 0.05, size + 0.05, size * 0.22), cframe, THUMB_GOLD, Enum.Material.Metal)
	thumbPart(parent, Vector3.new(size * 1.08, size * 0.25, size * 1.08), cframe * CFrame.new(0, size * 0.5, 0), color:Lerp(Color3.new(1, 1, 1), 0.2))
	thumbPart(parent, Vector3.one * size * 0.3, cframe * CFrame.new(0, size * 0.75, 0), THUMB_GOLD, Enum.Material.Metal, Enum.PartType.Ball)
end

-- Builds the icon stage and puts `player` in front of it (anchored) to frame the shot
-- (Shift+P frees the camera in a Studio playtest). Run it again to rebuild; nothing is
-- saved.
local function createThumb(player: Player): boolean
	local old = workspace:FindFirstChild("Thumbnail")
	if old then
		old:Destroy()
	end
	local scene = Instance.new("Model")
	scene.Name = "Thumbnail"
	local o = THUMB_ORIGIN
	local random = Random.new(7)

	-- floor and the gold stage, a neon rainbow ring round it
	thumbPart(scene, Vector3.new(200, 1, 140), o * CFrame.new(0, -1, -10), THUMB_PURPLE:Lerp(Color3.new(0, 0, 0), 0.55))
	local disc = function(radius: number, y: number, color: Color3, material: Enum.Material)
		return thumbPart(scene, Vector3.new(1, radius * 2, radius * 2), o * CFrame.new(0, y, 6) * CFrame.Angles(0, 0, math.pi / 2), color, material, Enum.PartType.Cylinder)
	end
	disc(26, -0.4, THUMB_GOLD, Enum.Material.Metal)
	disc(24.5, -0.2, THUMB_PINK, Enum.Material.SmoothPlastic)
	disc(23, 0, Color3.fromRGB(250, 140, 215), Enum.Material.SmoothPlastic)
	disc(12, 0.2, THUMB_GOLD, Enum.Material.Metal)
	for index = 0, 35 do
		local angle = index / 36 * math.pi * 2
		local bulb = thumbPart(scene, Vector3.one * 1.3, o * CFrame.new(math.cos(angle) * 25.3, 0.6, 6 + math.sin(angle) * 25.3), THUMB_RAINBOW[index % #THUMB_RAINBOW + 1], Enum.Material.Neon, Enum.PartType.Ball)
		bulb.Name = "Bulb"
	end

	-- the star: the custom brainrot, turned a little toward the camera, outlined, sparkling
	local yaw = math.rad(THUMB_CAMERA_YAW)
	local hero = thumbBrainrot(THUMB_HERO, THUMB_HERO_SCALE, o * CFrame.new(0, 0.7, 6) * CFrame.Angles(0, -yaw * 0.6, 0))
	hero.Parent = scene
	local box, size = hero:GetBoundingBox()
	local highlight = Instance.new("Highlight") -- a dark cartoon outline, so it pops off the background
	highlight.FillTransparency = 1
	highlight.OutlineColor = Color3.fromRGB(30, 20, 50)
	highlight.Parent = hero
	local core = thumbPart(scene, Vector3.one, box, THUMB_GOLD)
	core.Transparency = 1
	sparkles(core, Color3.fromRGB(255, 230, 120), 14)

	-- the shot: close and from a little below, so it fills ~70% of the frame (FOV 70:
	-- the frame is 1.4 x the distance tall)
	local center = box.Position
	local distance = size.Y / (1.4 * THUMB_FILL)
	local eye = center + Vector3.new(math.sin(yaw) * distance, -size.Y * 0.18, -math.cos(yaw) * distance)
	local shot = CFrame.lookAt(eye, center + Vector3.new(0, size.Y * 0.04, 0))
	local away = (center - eye).Unit
	local flat = Vector3.new(away.X, 0, away.Z).Unit

	-- the backdrop, square behind it on the camera's line: a purple wall, a halo of rings
	local halo = CFrame.lookAt(center + flat * 40, center + flat * 80)
	thumbPart(scene, Vector3.new(260, 180, 1), halo * CFrame.new(0, 20, 2), Color3.fromRGB(60, 20, 130))
	local rings = { { 40, Color3.fromRGB(110, 40, 210) }, { 32, Color3.fromRGB(170, 50, 220) }, { 25, Color3.fromRGB(230, 60, 190) }, { 18, Color3.fromRGB(255, 110, 170) }, { 11, Color3.fromRGB(255, 190, 110) } }
	for index, ring in rings do
		thumbPart(scene, Vector3.new(0.4, ring[1] * 2, ring[1] * 2), halo * CFrame.new(0, 0, 1 - index * 0.3) * CFrame.Angles(0, math.pi / 2, 0), ring[2], Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
	end

	-- loot boxes at the frame's sides, coins tumbling in the foreground
	local side = shot.RightVector
	for index, color in { Color3.fromRGB(60, 200, 255), Color3.fromRGB(80, 230, 120) } do
		local sign = if index == 1 then -1 else 1
		local spot = center + side * sign * (size.X * 0.5 + size.Y * 0.32) + Vector3.new(0, size.Y * (if index == 1 then 0.18 else 0.3), 0) + flat * 3
		giftBox(scene, CFrame.new(spot) * CFrame.Angles(random:NextNumber(-0.4, 0.4), random:NextNumber(0, 6), random:NextNumber(-0.4, 0.4)), size.Y * 0.16, color)
	end
	for _ = 1, 26 do
		local along = random:NextNumber(0.35, 0.75)
		local spot = eye:Lerp(center, along) + side * random:NextNumber(-1, 1) * size.Y * 0.32 * along + Vector3.new(0, -size.Y * random:NextNumber(0.15, 0.4) * along, 0)
		thumbPart(scene, Vector3.new(0.3, 1.6, 1.6), CFrame.new(spot) * CFrame.Angles(random:NextNumber(-1.5, 1.5), random:NextNumber(0, 6), random:NextNumber(-1.5, 1.5)), THUMB_GOLD, Enum.Material.Metal, Enum.PartType.Cylinder)
	end
	scene.Parent = workspace

	-- the player: invisible, parked out of the shot; their camera is put on the shot
	-- (UIController reads ThumbCamera), so Shift+P (hides the UI) and a screenshot is all
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if character and root and root:IsA("BasePart") then
		root.Anchored = true
		root.CFrame = CFrame.new(eye - flat * 30 - Vector3.new(0, 20, 0))
		for _, item in character:GetDescendants() do
			if item:IsA("BasePart") or item:IsA("Decal") then
				item.Transparency = 1
			end
		end
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		end
	end
	workspace:SetAttribute("ThumbCamera", nil) -- (so a rerun moves the camera again)
	workspace:SetAttribute("ThumbCamera", shot)
	return true
end

local COMMANDS: { [string]: (player: Player, ...any) -> any } = {
	GrantPass = function(player, key)
		return MonetizationManager.GrantForTesting(player, key)
	end,
	-- Grants a developer product as if bought (Config/Products key: "Coins1h",
	-- "Drop25"...). Gems, Coins and the like are saved, so Snapshot first.
	GrantProduct = function(player, key)
		return MonetizationManager.GrantProductForTesting(player, key)
	end,
	-- Loot boxes of one rarity ("Common" ... "Godly") land round you, to watch their
	-- arrival.
	SpawnBox = function(player, rarity, count)
		return LootManager.DevSpawnBoxes(player, rarity, count)
	end,
	Nuke = function(player)
		NukeManager.Launch(player)
		return true
	end,
	CreateThumb = function(player)
		return createThumb(player)
	end,
	AddCoins = function(player, amount)
		return DataManager.AddCurrency(player, "Coins", amount)
	end,
	AddGems = function(player, amount)
		return DataManager.AddCurrency(player, "Gems", amount)
	end,
	AddRolls = function(player, amount)
		return DataManager.AddRolls(player, amount)
	end,
	AddRebirths = function(player, amount)
		return DataManager.DevAddRebirths(player, amount)
	end,
	Snapshot = function(player)
		local snapshot = DataManager.DevSnapshot(player)
		snapshots[player] = snapshot :: DataManager.PlayerData
		return snapshot ~= nil
	end,
	Restore = function(player)
		local snapshot = snapshots[player]
		if not (snapshot and DataManager.DevRestore(player, snapshot)) then
			return false
		end
		TycoonManager.ResetPlot(player)
		return true
	end,
	-- Builds a room upgrade's level as if just bought (it drops in), without touching
	-- the data; ResetPlot puts the real one back.
	BuildUpgrade = function(player, itemId)
		return TycoonManager.DevBuildUpgrade(player, itemId)
	end,
	ResetPlot = function(player)
		TycoonManager.ResetPlot(player)
		return true
	end,
	-- Marks a tycoon item bought or not (free), then rebuilds the plot from the data.
	-- It saves, so Snapshot first.
	SetPurchased = function(player, itemId, purchased)
		if not DataManager.DevSetPurchased(player, itemId, purchased == true) then
			return false
		end
		TycoonManager.ResetPlot(player)
		return true
	end,
	-- The same for several items at once, with a single rebuild.
	SetPurchasedList = function(player, itemIds, purchased)
		for _, itemId in itemIds do
			if not DataManager.DevSetPurchased(player, itemId, purchased == true) then
				return false
			end
		end
		TycoonManager.ResetPlot(player)
		return true
	end,
	-- Unlocks all 4 parts of a brainrot and equips them on a line (skipping the line
	-- rules). It saves, so Snapshot first.
	ShowOnLine = function(player, brainrotId, lineId)
		for _, partType in Brainrots.PartTypes do
			DataManager.AddPart(player, brainrotId, partType)
			DataManager.SetLinePart(player, lineId, partType, brainrotId)
		end
		return true
	end,
	GiveBrainrots = function(player)
		for _, brainrot in Brainrots.List do
			for _, partType in Brainrots.PartTypes do
				DataManager.AddPart(player, brainrot.Id, partType)
			end
		end
		return true
	end,
}

local DevTools = {}

-- Runs a command from a "/dev Name arg arg..." chat line, for the player who typed it.
local function fromChat(player: Player, message: string)
	if not isDeveloper(player) then
		return
	end
	local words = string.split(message, " ")
	if words[1] ~= "/dev" or not words[2] then
		return
	end
	local handler = COMMANDS[words[2]]
	if not handler then
		warn(`[DevTools] Unknown dev command {words[2]}`)
		return
	end
	local args = {}
	for index = 3, #words do
		local word = words[index]
		if word ~= "" then
			table.insert(args, if tonumber(word) then tonumber(word) elseif word == "true" then true elseif word == "false" then false else word)
		end
	end
	local ok, result = pcall(handler, player, table.unpack(args))
	print(`[DevTools] {words[2]}:`, ok, result)
end

function DevTools.Init()
	local command = Instance.new("BindableFunction")
	command.Name = "DevCommand"
	command.OnInvoke = function(name: string, player: Player, ...: any)
		if not isDeveloper(player) then
			return false
		end
		local handler = COMMANDS[name]
		assert(handler, `Unknown dev command {name}`)
		return handler(player, ...)
	end
	command.Parent = ServerStorage

	local devRemote = Remotes.Function("DevMenu")
	devRemote.OnServerInvoke = function(player: Player, targetUserId: number, commandName: string, ...: any)
		if not isDeveloper(player) then
			return false
		end
		local handler = COMMANDS[commandName]
		if not handler then return false end

		local targetPlayer = if targetUserId == 0 then player else Players:GetPlayerByUserId(targetUserId)
		if not targetPlayer then return false end

		local ok, result = pcall(handler, targetPlayer, ...)
		return ok and result
	end

	workspace:GetAttributeChangedSignal("DevRequest"):Connect(function()
		local request = workspace:GetAttribute("DevRequest")
		if typeof(request) ~= "string" or request == "" then
			return
		end
		workspace:SetAttribute("DevRequest", nil)
		local ok, result = pcall(function()
			local args = HttpService:JSONDecode(request)
			local player = Players:GetPlayers()[1]
			assert(player, "No player")
			if not isDeveloper(player) then
				return false
			end
			local handler = COMMANDS[args[1]]
			assert(handler, `Unknown dev command {args[1]}`)
			return handler(player, table.unpack(args, 2))
		end)
		workspace:SetAttribute("DevResult", HttpService:JSONEncode({ ok = ok, result = if ok then result else tostring(result) }))
	end)

	-- "/dev ..." in the chat: a chat command (it isn't sent as a message), or with the
	-- legacy chat, any message that starts with it
	if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
		local chatCommand = Instance.new("TextChatCommand")
		chatCommand.Name = "DevCommand"
		chatCommand.PrimaryAlias = "/dev"
		chatCommand.Triggered:Connect(function(source: TextSource, text: string)
			local player = Players:GetPlayerByUserId(source.UserId)
			if player then
				fromChat(player, text)
			end
		end)
		chatCommand.Parent = TextChatService
	else
		local function listen(player: Player)
			player.Chatted:Connect(function(message)
				fromChat(player, message)
			end)
		end
		Players.PlayerAdded:Connect(listen)
		for _, player in Players:GetPlayers() do
			listen(player)
		end
	end
end

return DevTools
