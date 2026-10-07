--[[
	RebirthManager
	Rebirths (GDD §10). Rebirthing costs Coins (Config/Rebirths), resets Coins and the
	tycoon, and levels up the company mascot (Services/MascotManager): more Coins, line
	speed and luck forever (ProductionManager and LootManager apply them), and new zones.
	The Rebirth Shop is gone: the mascot replaces it.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Rebirths = require(Shared.Config.Rebirths)
local Remotes = require(Shared.Remotes)

local DataManager = require(script.Parent.DataManager)
local TycoonManager = require(script.Parent.TycoonManager)

local REQUEST_COOLDOWN = 0.3
local ANNOUNCE_COLOR = Color3.fromRGB(255, 200, 60)

local lastRequest: { [Player]: number } = {}
local announceRemote: RemoteEvent

local RebirthManager = {}

local function allowRequest(player: Player): boolean
	local now = os.clock()
	if (lastRequest[player] or 0) + REQUEST_COOLDOWN > now then
		return false
	end
	lastRequest[player] = now
	return true
end

-- Returns whether it worked.
local function onRebirth(player: Player): boolean
	if not allowRequest(player) then
		return false
	end
	local data = DataManager.GetData(player)
	if not data then
		return false
	end
	local cost = Rebirths.Cost(data.Rebirths)
	if data.Coins < cost or not DataManager.Rebirth(player, cost) then
		return false
	end
	TycoonManager.ResetPlot(player)
	announceRemote:FireAllClients(`{player.DisplayName} reached Rebirth {data.Rebirths}!`, ANNOUNCE_COLOR, player)
	return true
end

function RebirthManager.Init()
	announceRemote = Remotes.Event("Announce")
	Remotes.Function("Rebirth").OnServerInvoke = onRebirth
	Players.PlayerRemoving:Connect(function(player)
		lastRequest[player] = nil
	end)
end

return RebirthManager
