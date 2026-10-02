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

	The Studio MCP's own code can't invoke it any more (since 2026-10-02 its thread lacks
	the modules' capabilities), but it can set attributes: set workspace's DevRequest to
	a JSON array, the command's name then its arguments, and the result lands in
	DevResult (JSON: { ok, result }). It runs for the first player:

	  workspace:SetAttribute("DevRequest", '["AddCoins", 50000]')

	Never created in live servers.
]]

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local Brainrots = require(ReplicatedStorage.Shared.Config.Brainrots)
local DataManager = require(script.Parent.DataManager)
local TycoonManager = require(script.Parent.TycoonManager)

local snapshots: { [Player]: DataManager.PlayerData } = {}

local COMMANDS: { [string]: (player: Player, ...any) -> any } = {
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
end

return DevTools
