--[[
	RebirthManager
	Rebirths and the Rebirth Shop (GDD §10). Rebirthing costs Coins (Config/Rebirths),
	resets Coins and the tycoon, and gives Rebirth Points, a permanent income boost,
	rarity unlocks and new zones. Rebirth Points buy permanent shop upgrades, which
	ProductionManager (income, speed) and LootManager (luck) apply.
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

-- Returns whether it worked and the Rebirth Points gained.
local function onRebirth(player: Player): (boolean, number?)
	if not allowRequest(player) then
		return false
	end
	local data = DataManager.GetData(player)
	if not data then
		return false
	end
	local cost = Rebirths.Cost(data.Rebirths)
	local points = Rebirths.Points(data.Coins, data.Rebirths)
	if data.Coins < cost or not DataManager.Rebirth(player, cost, points) then
		return false
	end
	TycoonManager.ResetPlot(player)
	announceRemote:FireAllClients(`{player.DisplayName} reached Rebirth {data.Rebirths}!`, ANNOUNCE_COLOR, player)
	return true, points
end

local function onBuyUpgrade(player: Player, upgradeId: unknown): boolean
	if typeof(upgradeId) ~= "string" or not allowRequest(player) then
		return false
	end
	local upgrade = Rebirths.UpgradesById[upgradeId]
	local data = DataManager.GetData(player)
	if not (upgrade and data) then
		return false
	end
	local level = data.Upgrades[upgradeId] or 0
	return DataManager.BuyUpgrade(player, upgradeId, Rebirths.UpgradeCost(upgrade, level), upgrade.MaxLevel)
end

function RebirthManager.Init()
	announceRemote = Remotes.Event("Announce")
	Remotes.Function("Rebirth").OnServerInvoke = onRebirth
	Remotes.Function("BuyUpgrade").OnServerInvoke = onBuyUpgrade
	Players.PlayerRemoving:Connect(function(player)
		lastRequest[player] = nil
	end)
end

return RebirthManager
