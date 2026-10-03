--[[
	DevTools (Studio only)
	Test helpers for playtests, reachable from the command bar or the Studio MCP
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

	Never created in live servers.
]]

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local TextChatService = game:GetService("TextChatService")

local BrainrotModels = require(ReplicatedStorage.Shared.BrainrotModels)
local Brainrots = require(ReplicatedStorage.Shared.Config.Brainrots)
local RoomDecor = require(script.Parent.RoomDecor)
local DataManager = require(script.Parent.DataManager)
local LootManager = require(script.Parent.LootManager)
local MonetizationManager = require(script.Parent.MonetizationManager)
local NukeManager = require(script.Parent.NukeManager)
local TycoonManager = require(script.Parent.TycoonManager)

local snapshots: { [Player]: DataManager.PlayerData } = {}

-- The game icon's scene (CreateThumb): far off over the valley, facing -Z (the way
-- brainrots face). Brainrots: { id, x, scale, turn (degrees) }.
local THUMB_ORIGIN = CFrame.new(0, 320, -1600)
local THUMB_BRAINROTS = {
	{ "TralaleroTralala", 0, 2.4, 0 },
	{ "TungTungTungSahur", -11, 2.0, 18 },
	{ "BombardiroCrocodilo", 11.5, 1.8, -18 },
	{ "CappuccinoAssassino", -20, 1.5, 28 },
	{ "LaVacaSaturnoSaturnita", 20.5, 1.5, -28 },
}
local THUMB_PINK, THUMB_PURPLE, THUMB_GOLD = Color3.fromRGB(255, 90, 190), Color3.fromRGB(120, 60, 230), Color3.fromRGB(255, 195, 40)

local function thumbPart(parent: Instance, size: Vector3, cframe: CFrame, color: Color3, material: Enum.Material?, shape: Enum.PartType?): Part
	local part = Instance.new("Part")
	part.Anchored = true
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

local function wholeBrainrot(id: string, scale: number, root: CFrame): Model
	local brainrot = Instance.new("Model")
	brainrot.Name = id
	for _, partType in Brainrots.PartTypes do
		local part = BrainrotModels.CreatePart(id, partType)
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

-- Builds a stage for the game's icon: brainrots in a row on a round stage, a neon
-- BUILD A BRAINROT sign over them, a pink/purple sunburst behind, gold coins round
-- their feet; puts `player` in front of it (anchored) to frame the shot (Shift+P frees
-- the camera in a Studio playtest). Run it again to rebuild; nothing is saved.
local function createThumb(player: Player): boolean
	local old = workspace:FindFirstChild("Thumbnail")
	if old then
		old:Destroy()
	end
	local scene = Instance.new("Model")
	scene.Name = "Thumbnail"
	local o = THUMB_ORIGIN
	-- the stage and the floor round it
	thumbPart(scene, Vector3.new(160, 1, 120), o * CFrame.new(0, -1, -20), THUMB_PURPLE:Lerp(Color3.new(0, 0, 0), 0.4))
	thumbPart(scene, Vector3.new(2, 56, 56), o * CFrame.new(0, 0, 4) * CFrame.Angles(0, 0, math.pi / 2), THUMB_PINK, Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
	thumbPart(scene, Vector3.new(1.6, 58, 58), o * CFrame.new(0, -0.3, 4) * CFrame.Angles(0, 0, math.pi / 2), THUMB_GOLD, Enum.Material.Metal, Enum.PartType.Cylinder)
	-- the sunburst behind
	local center = o * CFrame.new(0, 14, 30)
	for index = 0, 23 do
		local color = if index % 2 == 0 then THUMB_PINK else THUMB_PURPLE
		thumbPart(scene, Vector3.new(7, 120, 0.5), center * CFrame.Angles(0, 0, index * math.pi / 12) * CFrame.new(0, 60, 0), color, Enum.Material.Neon)
	end
	thumbPart(scene, Vector3.new(0.6, 30, 30), center * CFrame.new(0, 0, -0.4) * CFrame.Angles(0, math.pi / 2, 0), Color3.fromRGB(255, 240, 160), Enum.Material.Neon, Enum.PartType.Cylinder)
	-- the brainrots
	for _, spec in THUMB_BRAINROTS do
		local id, x, scale, turn = spec[1] :: string, spec[2] :: number, spec[3] :: number, spec[4] :: number
		if Brainrots.ById[id] then
			wholeBrainrot(id, scale, o * CFrame.new(x, 0.5, 4 + math.abs(x) * 0.25) * CFrame.Angles(0, math.rad(turn), 0)).Parent = scene
		end
	end
	-- the sign
	RoomDecor.NeonSign(scene, o * CFrame.new(0, 27, 12), Vector2.new(34, 7), "BUILD A BRAINROT", Color3.fromRGB(255, 220, 60))
	-- coins round their feet
	local random = Random.new(7)
	for _ = 1, 40 do
		local angle = random:NextNumber(0, math.pi * 2)
		local radius = random:NextNumber(16, 27)
		local spot = o * CFrame.new(math.cos(angle) * radius, 1.2, 4 + math.sin(angle) * radius * 0.6)
		thumbPart(scene, Vector3.new(0.4, 2.2, 2.2), spot * CFrame.Angles(random:NextNumber(-0.6, 0.6), random:NextNumber(0, 6), math.pi / 2 + random:NextNumber(-0.5, 0.5)), THUMB_GOLD, Enum.Material.Metal, Enum.PartType.Cylinder)
	end
	scene.Parent = workspace
	-- the player, in front, looking at it
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		root.Anchored = true
		local eye = o * CFrame.new(0, 3.5, -42)
		root.CFrame = CFrame.lookAt(eye.Position, (o * CFrame.new(0, 3.5, 0)).Position)
	end
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
	-- arrival. Opening one of a rarity you haven't unlocked needs its rebirths.
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
}

local DevTools = {}

-- Runs a command from a "/dev Name arg arg..." chat line, for the player who typed it.
local function fromChat(player: Player, message: string)
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
	if not RunService:IsStudio() then
		return
	end
	local command = Instance.new("BindableFunction")
	command.Name = "DevCommand"
	command.OnInvoke = function(name: string, player: Player, ...: any)
		local handler = COMMANDS[name]
		assert(handler, `Unknown dev command {name}`)
		return handler(player, ...)
	end
	command.Parent = ServerStorage

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
