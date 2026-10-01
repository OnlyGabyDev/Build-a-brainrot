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

	Never created in live servers.
]]

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
end

return DevTools
