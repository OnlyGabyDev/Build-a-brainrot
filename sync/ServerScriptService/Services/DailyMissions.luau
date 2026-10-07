--[[
	DailyMissions
	Three daily quests (GDD §5 "Daily quests", Config/DailyMissions): picked from the
	pool on the first moment of each UTC day the player is in (easy, medium, hard), each
	counting from that moment (its source's value then is its base), paid when claimed,
	with a bonus once all three are. Mirrored for the client as the "Missions" attribute
	(JSON: { Day, Next, Bonus, List = { { Id, Goal, Progress, Claimed } } }); the QUESTS
	menu claims them (ClaimMission, ClaimMissionBonus).
]]

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Config = require(Shared.Config.DailyMissions)
local LineUpgrades = require(Shared.Config.LineUpgrades)
local TycoonItems = require(Shared.Config.TycoonItems)
local Remotes = require(Shared.Remotes)

local AchievementManager = require(script.Parent.AchievementManager)
local DataManager = require(script.Parent.DataManager)
local ProductionManager = require(script.Parent.ProductionManager)
local RewardManager = require(script.Parent.RewardManager)

local REFRESH_INTERVAL = 1
local REQUEST_COOLDOWN = 0.3

local random = Random.new()
local lastRequest: { [Player]: number } = {}

local DailyMissions = {}

local function today(): number
	return os.time() // Config.SecondsPerDay
end

-- A goal as a round number: two digits, then zeros (1,437 -> 1,400).
local function round(goal: number): number
	if goal < 100 then
		return math.max(1, math.floor(goal + 0.5))
	end
	local unit = 10 ^ (math.floor(math.log10(goal)) - 1)
	return math.floor(goal / unit + 0.5) * unit
end

-- The lines the player owns, and the upgrade levels left to buy on them.
local function linesOwned(data: DataManager.PlayerData): (number, number)
	local purchased = data.Tycoon.Purchased
	local lines, left = 0, 0
	for _, line in TycoonItems.Lines do
		if purchased[line.UnlockItemId] then
			lines += 1
			for _, track in LineUpgrades.Tracks do
				left += track.Levels - TycoonItems.TrackLevel(purchased, line.Id, track.Key)
			end
		end
	end
	return lines, left
end

-- What a quest asks of this player in `slot` (1 easy .. 3 hard), or nil when they can't do it today.
local function goalOf(player: Player, data: DataManager.PlayerData, mission: Config.Mission, slot: number): number?
	local goal = mission.Goals[math.min(slot, #mission.Goals)]
	if mission.Rate then
		local income, built, perfects = ProductionManager.GetRates(player)
		local rate = if mission.Rate == "Coins" then income elseif mission.Rate == "Built" then built else perfects
		local least = if mission.MinGoals then mission.MinGoals[math.min(slot, #mission.MinGoals)] else 1
		return math.max(least, round(rate * goal))
	elseif mission.PerLine then
		local lines, left = linesOwned(data)
		if lines == 0 then
			return goal -- a newcomer's first line isn't up yet
		end
		goal = math.min(math.floor(goal * (1 + (lines - 1) * mission.PerLine) + 0.5), left)
		return if goal >= 1 then goal else nil -- every owned line maxed out
	end
	return goal
end

-- Picks today's quests: three different ones from the pool, the nth asking its nth goal.
local function pick(player: Player, data: DataManager.PlayerData)
	local pool = table.clone(Config.Pool)
	for index = #pool, 2, -1 do
		local other = random:NextInteger(1, index)
		pool[index], pool[other] = pool[other], pool[index]
	end
	local list = {}
	for _, mission in pool do
		if #list == Config.Count then
			break
		end
		local goal = goalOf(player, data, mission, #list + 1)
		if goal then
			table.insert(list, { Id = mission.Id, Goal = goal, Base = AchievementManager.SourceValue(data, mission.Source), Claimed = false })
		end
	end
	DataManager.SetDailyMissions(player, today(), list)
end

local function progressOf(data: DataManager.PlayerData, entry: DataManager.DailyMission): number
	local mission = Config.ById[entry.Id]
	return if mission then math.max(0, AchievementManager.SourceValue(data, mission.Source) - entry.Base) else 0
end

-- Picks a new day's quests when the day turns, then mirrors them.
local function update(player: Player)
	local data = DataManager.GetData(player)
	if not data then
		return
	end
	if data.Missions.Day ~= today() then
		pick(player, data)
	end
	local list = {}
	for _, entry in data.Missions.List do
		table.insert(list, { Id = entry.Id, Goal = entry.Goal, Progress = progressOf(data, entry), Claimed = entry.Claimed })
	end
	local json = HttpService:JSONEncode({
		Day = data.Missions.Day,
		Next = (data.Missions.Day + 1) * Config.SecondsPerDay,
		Bonus = data.Missions.Bonus,
		List = list,
	})
	if player:GetAttribute("Missions") ~= json then
		player:SetAttribute("Missions", json)
	end
end

local function allow(player: Player): boolean
	local now = os.clock()
	if (lastRequest[player] or 0) + REQUEST_COOLDOWN > now then
		return false
	end
	lastRequest[player] = now
	return true
end

-- Claims today's quest `index`: { Index, Text, Result? } or nil.
local function onClaim(player: Player, index: unknown): any
	if typeof(index) ~= "number" or not allow(player) then
		return nil
	end
	local data = DataManager.GetData(player)
	local entry = data and data.Missions.List[index]
	if not (data and entry and data.Missions.Day == today()) or progressOf(data, entry) < entry.Goal then
		return nil
	end
	local reward = Config.Rewards[index]
	if not (reward and DataManager.ClaimDailyMission(player, index)) then
		return nil
	end
	local text, result = RewardManager.Grant(player, reward, "DailyMission")
	update(player)
	return { Index = index, Text = text, Result = result }
end

-- Claims the bonus for all three: { Text, Result? } or nil.
local function onClaimBonus(player: Player): any
	if not allow(player) then
		return nil
	end
	local data = DataManager.GetData(player)
	if not (data and data.Missions.Day == today() and DataManager.ClaimDailyMissionBonus(player)) then
		return nil
	end
	local text, result = RewardManager.Grant(player, Config.Bonus, "DailyMission")
	update(player)
	return { Text = text, Result = result }
end

-- Studio testing: new quests now (as if a new day began), then mirrors them.
function DailyMissions.DevNewDay(player: Player): boolean
	local data = DataManager.GetData(player)
	if not data then
		return false
	end
	pick(player, data)
	update(player)
	return true
end

function DailyMissions.Init()
	Remotes.Function("ClaimMission").OnServerInvoke = onClaim
	Remotes.Function("ClaimMissionBonus").OnServerInvoke = onClaimBonus
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

return DailyMissions
