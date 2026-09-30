--[[
	DevTools (Studio only)
	Test helpers for playtests, reachable from the command bar or the Studio MCP
	through a BindableFunction (module requires there get separate copies, but
	instances are shared):

	  local dev = game.ServerStorage.DevCommand
	  dev:Invoke("AddCoins", player, 50000)
	  dev:Invoke("Snapshot", player)   -- before a destructive test (e.g. rebirthing)
	  dev:Invoke("Restore", player)    -- puts the data back and rebuilds the tycoon

	Never created in live servers.
]]

local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

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
