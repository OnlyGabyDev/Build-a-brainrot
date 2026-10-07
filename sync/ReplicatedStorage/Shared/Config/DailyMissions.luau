--[[
	DailyMissions (GDD §5 "Daily quests", the user 2026-10-07)
	Three quests a UTC day, picked from the pool: the first easy, the second medium, the
	third hard (each quest's Goals, in that order), each paying its slot's reward, and a
	bonus once all three are claimed. A quest counts from the day's start: what its
	Source read then is its base (the same counters as the achievements:
	Services/AchievementManager.SourceValue). Coins goals are seconds of the income the
	player had when the day's quests were picked (never under MinGoal).
	Services/DailyMissions picks and pays them; the QUESTS menu's DAILY tab shows them.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Format = require(Shared:WaitForChild("Format"))
local Rewards = require(Shared:WaitForChild("Rewards"))

export type Mission = {
	Id: string,
	Icon: string, -- one of ours (Config/Icons)
	Text: string, -- "{n}" for the amount
	One: string?, -- the text when it asks for just 1
	Source: string, -- what it counts (Services/AchievementManager.SourceValue)
	Goals: { number }, -- easy, medium, hard
	Time: boolean?, -- the amount is seconds
	Income: boolean?, -- Goals are seconds of income (Coins), at least MinGoal
	MinGoal: number?,
}

local MINUTE = 60

local DailyMissions = {}

DailyMissions.Count = 3
DailyMissions.SecondsPerDay = 86400 -- UTC days
DailyMissions.Pool = {
	{ Id = "Boxes", Icon = "Gift", Text = "Open {n} boxes", Source = "Counters.Boxes", Goals = { 4, 8, 15 } },
	{ Id = "Built", Icon = "Hammer", Text = "Build {n} brainrots", Source = "Counters.Built", Goals = { 40, 100, 250 } },
	{ Id = "Perfects", Icon = "Star", Text = "Make {n} PERFECTs", One = "Make a PERFECT", Source = "Stats.Perfects", Goals = { 5, 15, 40 } },
	{ Id = "Upgrades", Icon = "ArrowUp", Text = "Buy {n} line upgrades", One = "Buy a line upgrade", Source = "Counters.Upgrades", Goals = { 2, 5, 10 } },
	{ Id = "Playtime", Icon = "Clock", Text = "Play for {n} min", Source = "Stats.Playtime", Time = true, Goals = { 10 * MINUTE, 20 * MINUTE, 40 * MINUTE } },
	{ Id = "Coins", Icon = "Coin", Text = "Earn {n} Coins", Source = "Stats.TotalCoinsEarned", Income = true, MinGoal = 5000, Goals = { 5 * MINUTE, 10 * MINUTE, 20 * MINUTE } },
	{ Id = "Spins", Icon = "Wheel", Text = "Spin the wheel {n} times", One = "Spin the wheel", Source = "Counters.Spins", Goals = { 1, 1, 1 } },
} :: { Mission }
-- what each slot pays: easy, medium, hard
DailyMissions.Rewards = {
	{ Kind = "Coins", IncomeSeconds = 5 * MINUTE, MinCoins = 2000 },
	{ Kind = "Gems", Amount = 25 },
	{ Kind = "Rolls", Amount = 1 },
} :: { Rewards.Reward }
-- for claiming all three
DailyMissions.Bonus = { Kind = "Rolls", Amount = 2 } :: Rewards.Reward
DailyMissions.ById = {} :: { [string]: Mission }

for _, mission in DailyMissions.Pool do
	DailyMissions.ById[mission.Id] = mission
end

-- The words for a quest asking `goal`.
function DailyMissions.Text(mission: Mission, goal: number): string
	if goal == 1 and mission.One then
		return mission.One
	end
	local amount = if mission.Time then tostring(math.floor(goal / MINUTE)) else Format.Number(goal)
	return (string.gsub(mission.Text, "{n}", amount))
end

-- Progress on a quest, in its words ("3 / 8", "12 / 20 min").
function DailyMissions.Progress(mission: Mission, value: number, goal: number): string
	value = math.min(value, goal)
	if mission.Time then
		return `{math.floor(value / MINUTE)} / {math.floor(goal / MINUTE)} min`
	end
	return `{Format.Number(value)} / {Format.Number(goal)}`
end

return DailyMissions
