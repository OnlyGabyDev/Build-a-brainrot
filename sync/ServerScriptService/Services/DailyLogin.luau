--[[
	DailyLogin
	The login streak (GDD §5, Config/DailyLogin): a reward each UTC day, claimed from
	the calendar (Client/UI/DailyLoginMenu). The next day of the 7 on each new UTC day
	you play, however many days you missed (the user, 2026-10-07: starting over could be
	farmed), round to day 1 after day 7. Mirrored for the client as
	"DailyDay" (the day to claim, or claimed today), "DailyReady" (it can be claimed)
	and "DailyNext" (os.time() when the next day starts).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local DailyLoginConfig = require(Shared.Config.DailyLogin)
local Format = require(Shared.Format)
local Remotes = require(Shared.Remotes)

local DataManager = require(script.Parent.DataManager)
local LootManager = require(script.Parent.LootManager)
local ProductionManager = require(script.Parent.ProductionManager)

local DAYS = DailyLoginConfig.Days
local REQUEST_COOLDOWN = 1
local REFRESH_INTERVAL = 30 -- seconds between refreshes (a new UTC day comes round)

local lastRequest: { [Player]: number } = {}

local DailyLogin = {}

local function utcDay(): number
	return os.time() // DailyLoginConfig.SecondsPerDay
end

-- The day to claim now (or the one claimed today) and whether it can be claimed.
local function status(data: DataManager.PlayerData): (number, boolean)
	local streak = data.DailyLogin
	local today = utcDay()
	if streak.LastDay == today then
		return math.max(streak.Day, 1), false
	end
	return streak.Day % #DAYS + 1, true -- (a first visit: day 1)
end

local function update(player: Player)
	local data = DataManager.GetData(player)
	if not data then
		return
	end
	local day, ready = status(data)
	player:SetAttribute("DailyDay", day)
	player:SetAttribute("DailyReady", ready)
	player:SetAttribute("DailyNext", (utcDay() + 1) * DailyLoginConfig.SecondsPerDay)
end

-- Gives a day's reward. Returns the line the client shows, and a part to reveal.
local function grant(player: Player, reward: DailyLoginConfig.Reward): (string, any?)
	if reward.Kind == "Coins" then
		local amount = math.floor(math.max(reward.MinCoins or 0, ProductionManager.GetIncome(player) * (reward.IncomeSeconds or 0)))
		DataManager.AddCurrency(player, "Coins", amount)
		return `+{Format.Number(amount)} COINS!`
	elseif reward.Kind == "Gems" then
		DataManager.AddCurrency(player, "Gems", reward.Amount or 0)
		return `+{reward.Amount} GEMS!`
	elseif reward.Kind == "Rolls" then
		DataManager.AddRolls(player, reward.Amount or 0)
		return `+{reward.Amount} {if reward.Amount == 1 then "ROLL" else "ROLLS"}!`
	elseif reward.Kind == "Box" then
		LootManager.GiftBox(player, reward.Rarity)
		return `A {string.upper(reward.Rarity or "")} BOX in your yard!`
	elseif reward.Kind == "RarePart" then
		if reward.Gems then
			DataManager.AddCurrency(player, "Gems", reward.Gems)
		end
		local result = LootManager.GrantRarePart(player, reward.MinRank or 3, "DailyLogin")
		return `A NEW PART + {reward.Gems or 0} GEMS!`, result
	end
	return reward.Label
end

-- Claims today's reward: { Day, Text, Result? } or nil.
local function onClaim(player: Player): any
	local now = os.clock()
	if (lastRequest[player] or 0) + REQUEST_COOLDOWN > now then
		return nil
	end
	lastRequest[player] = now
	local data = DataManager.GetData(player)
	if not data then
		return nil
	end
	local day, ready = status(data)
	if not ready or not DataManager.ClaimDailyLogin(player, day, utcDay()) then
		return nil
	end
	local text, result = grant(player, DAYS[day])
	update(player)
	return { Day = day, Text = text, Result = result }
end

-- Re-reads the player's streak into their attributes (after DevTools changes it).
DailyLogin.Refresh = update

function DailyLogin.Init()
	Remotes.Function("ClaimDailyLogin").OnServerInvoke = onClaim
	DataManager.OnPlayerLoaded(update)
	Players.PlayerRemoving:Connect(function(player)
		lastRequest[player] = nil
	end)
	task.spawn(function()
		while true do
			task.wait(REFRESH_INTERVAL)
			for _, player in Players:GetPlayers() do
				update(player)
			end
		end
	end)
end

return DailyLogin
