--[[
	OfflineEarnings
	The factory keeps working while you're away (GDD §16.7): on joining, a share of the
	income you had when you left, for the time away (capped). Client/UI/WelcomeBackMenu
	shows it with a big COLLECT that banks it; if they never press it, it's banked as
	they leave. Every save stamps the time and the income (DataManager.SetLastSeen).
	Mirrored as the Player attributes "OfflineCoins" (waiting) and "OfflineSeconds" (the
	time away it counted).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Remotes = require(Shared.Remotes)

local DataManager = require(script.Parent.DataManager)
local ProductionManager = require(script.Parent.ProductionManager)

local SHARE = 0.25 -- of the income while away...
local MAX_SECONDS = 2 * 3600 -- ...for up to this long
local MIN_SECONDS = 120 -- shorter absences pay nothing (a quick rejoin)

local waiting: { [Player]: number } = {}

local OfflineEarnings = {}

local function set(player: Player, coins: number, seconds: number)
	if coins > 0 then
		waiting[player] = coins
	else
		waiting[player] = nil
	end
	player:SetAttribute("OfflineCoins", if coins > 0 then coins else nil)
	player:SetAttribute("OfflineSeconds", if coins > 0 then seconds else nil)
end

-- What `seconds` away pays at `income` Coins a second.
local function earnings(income: number, seconds: number): number
	if seconds < MIN_SECONDS then
		return 0
	end
	return math.floor(income * SHARE * math.min(seconds, MAX_SECONDS))
end

-- On joining: what the factory made since the last save.
local function onLoaded(player: Player)
	local data = DataManager.GetData(player)
	local stats = data and data.Stats
	if not (stats and stats.LastSeen > 0) then
		return
	end
	local seconds = os.time() - stats.LastSeen
	set(player, earnings(stats.LastIncome, seconds), seconds)
end

local function bank(player: Player): number
	local coins = waiting[player]
	if not coins then
		return 0
	end
	set(player, 0, 0)
	DataManager.AddCurrency(player, "Coins", coins)
	return coins
end

-- Studio testing (DevTools): earnings as if they'd been away `hours` at today's income.
function OfflineEarnings.DevSetAway(player: Player, hours: number): number
	local seconds = math.floor(hours * 3600)
	local coins = earnings(ProductionManager.GetIncome(player), seconds)
	set(player, coins, seconds)
	return coins
end

function OfflineEarnings.Init()
	Remotes.Function("CollectOffline").OnServerInvoke = bank
	DataManager.OnPlayerLoaded(onLoaded)
	DataManager.OnBeforeSave(function(player, leaving)
		if leaving then
			bank(player) -- never lost
		end
		DataManager.SetLastSeen(player, ProductionManager.GetIncome(player))
	end)
	Players.PlayerRemoving:Connect(function(player)
		task.defer(function() -- (after the last save has banked it)
			waiting[player] = nil
		end)
	end)
end

return OfflineEarnings
