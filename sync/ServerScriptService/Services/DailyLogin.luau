--[[
	DailyLogin
	The login streak (GDD §5, Config/DailyLogin): a reward each UTC day, claimed from
	the calendar (Client/UI/DailyLoginMenu). The next of the 7 days on each new UTC day
	you play, however many days you missed, and it's over once day 7 is claimed: it never
	starts over (the user, 2026-10-07: starting over could be farmed). Mirrored for the
	client as "DailyDay" (the day to claim, or claimed today), "DailyReady" (it can be
	claimed), "DailyDone" (all 7 claimed) and "DailyNext" (os.time() when the next day
	starts).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local DailyLoginConfig = require(Shared.Config.DailyLogin)
local Remotes = require(Shared.Remotes)

local DataManager = require(script.Parent.DataManager)
local RewardManager = require(script.Parent.RewardManager)

local DAYS = DailyLoginConfig.Days
local REQUEST_COOLDOWN = 1
local REFRESH_INTERVAL = 30 -- seconds between refreshes (a new UTC day comes round)

local lastRequest: { [Player]: number } = {}

local DailyLogin = {}

local function utcDay(): number
	return os.time() // DailyLoginConfig.SecondsPerDay
end

-- The day to claim now (or the one claimed last) and whether it can be claimed.
local function status(data: DataManager.PlayerData): (number, boolean)
	local streak = data.DailyLogin
	if streak.LastDay == utcDay() or streak.Day >= #DAYS then
		return math.clamp(streak.Day, 1, #DAYS), false -- (claimed today, or all done)
	end
	return streak.Day + 1, true -- (a first visit: day 1)
end

local function update(player: Player)
	local data = DataManager.GetData(player)
	if not data then
		return
	end
	local day, ready = status(data)
	player:SetAttribute("DailyDay", day)
	player:SetAttribute("DailyReady", ready)
	player:SetAttribute("DailyDone", data.DailyLogin.Day >= #DAYS)
	player:SetAttribute("DailyNext", (utcDay() + 1) * DailyLoginConfig.SecondsPerDay)
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
	local text, result = RewardManager.Grant(player, DAYS[day], "DailyLogin")
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
