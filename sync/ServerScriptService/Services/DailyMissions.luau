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

-- Picks today's quests: three different ones from the pool, the nth asking its nth goal.
local function pick(player: Player, data: DataManager.PlayerData)
	local pool = table.clone(Config.Pool)
	for index = #pool, 2, -1 do
		local other = random:NextInteger(1, index)
		pool[index], pool[other] = pool[other], pool[index]
	end
	local income = ProductionManager.GetIncome(player)
	local list = {}
	for slot = 1, math.min(Config.Count, #pool) do
		local mission = pool[slot]
		local goal = mission.Goals[math.min(slot, #mission.Goals)]
		if mission.Income then
			goal = math.floor(math.max(mission.MinGoal or 0, income * goal))
		end
		table.insert(list, { Id = mission.Id, Goal = goal, Base = AchievementManager.SourceValue(data, mission.Source), Claimed = false })
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
