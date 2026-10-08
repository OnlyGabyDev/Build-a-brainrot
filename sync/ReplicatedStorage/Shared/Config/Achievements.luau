--[[
	Achievements (GDD §5 "Achievements", the user 2026-10-07)
	Goals in tiers: claiming a tier opens the next, which asks more and pays more, and
	its card looks better (each tier wears a rarity's colors: Common, Uncommon ... Godly,
	then the rainbow with more stars). Each tier pays Gems and/or Coins (seconds of the
	player's income, never less than MIN_COINS_PER_SECOND a second).

	Kinds, and what their progress counts (Services/AchievementManager):
	  "Counter": a lifetime counter (Data.Counters[Counter], or a Stat / Data field)
	  "Rarity": tier n asks for a claimed brainrot of the nth rarity
	  "Room": tier n asks for the nth room after the first opened, ever
	The client (Client/UI/AchievementsMenu) shows them from the same table.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Brainrots = require(Shared:WaitForChild("Config"):WaitForChild("Brainrots"))
local Rarities = require(Shared:WaitForChild("Config"):WaitForChild("Rarities"))
local Zones = require(Shared:WaitForChild("Config"):WaitForChild("Zones"))
local Format = require(Shared:WaitForChild("Format"))

export type Achievement = {
	Id: string,
	Name: string,
	Icon: string, -- one of ours (Config/Icons)
	Kind: string, -- "Counter" | "Rarity" | "Room"
	-- Counter: where it reads ("Counters.<name>", "Stats.<name>", "Rebirths", "Parts")
	Source: string?,
	Goals: { number }?, -- Counter: the amount each tier asks
	Text: string?, -- Counter: the goal, "{n}" for the amount
	One: string?, -- Counter: the goal when it asks for just 1 ("Rebirth once")
	Time: boolean?, -- Counter: the amount is seconds (shown as 1h, 30m)
	Gems: number, -- the Gem ladder times this (0: no Gems)
	Coins: number, -- the Coins ladder times this (0: no Coins)
}

local GEM_LADDER = { 5, 10, 20, 30, 50, 75, 100, 150, 200, 300 }
local COIN_SECONDS = { 120, 300, 600, 900, 1200, 1800, 2700, 3600, 5400, 7200 }
local MIN_COINS_PER_SECOND = 10

local ROOMS = {} -- the rooms opened with Coins, in order (the Room kind's tiers)
for _, zone in Zones.List do
	if zone.Available and zone.UnlockPrice then
		table.insert(ROOMS, zone)
	end
end

local ALL_PARTS = #Brainrots.List * #Brainrots.PartTypes
local PART_GOALS = {}
for _, goal in { 8, 12, 20, 30, 45, 75, 140 } do -- (8 tiers at most, the last every part)
	if goal < ALL_PARTS then
		table.insert(PART_GOALS, goal)
	end
end
table.insert(PART_GOALS, ALL_PARTS)

local MINUTE, HOUR = 60, 3600

local Achievements = {}

Achievements.List = {
	{ Id = "Rooms", Name = "GRAND OPENING", Icon = "Unlock", Kind = "Room", Gems = 2, Coins = 1 },
	{ Id = "Built", Name = "BUILDER", Icon = "Hammer", Kind = "Counter", Source = "Counters.Built", Text = "Build {n} brainrots", Goals = { 25, 100, 500, 2500, 10000, 50000, 250000, 1000000 }, Gems = 0, Coins = 1 },
	{ Id = "Parts", Name = "COLLECTOR", Icon = "Puzzle", Kind = "Counter", Source = "Parts", Text = "Collect {n} parts", Goals = PART_GOALS, Gems = 1, Coins = 0 },
	{ Id = "Rarity", Name = "RARITY HUNTER", Icon = "Album", Kind = "Rarity", Gems = 2, Coins = 0 },
	{ Id = "Boxes", Name = "BOX HUNTER", Icon = "Gift", Kind = "Counter", Source = "Counters.Boxes", Text = "Open {n} boxes", Goals = { 5, 20, 50, 150, 400, 1000, 2500, 5000 }, Gems = 1, Coins = 1 },
	{ Id = "Coins", Name = "TYCOON", Icon = "Coin", Kind = "Counter", Source = "Stats.TotalCoinsEarned", Text = "Earn {n} Coins", Goals = { 10e3, 1e6, 50e6, 1e9, 20e9, 300e9, 5e12, 100e12 }, Gems = 0, Coins = 1 },
	{ Id = "Rebirths", Name = "REBORN", Icon = "Rebirth", Kind = "Counter", Source = "Rebirths", Text = "Rebirth {n} times", One = "Rebirth once", Goals = { 1, 2, 3, 5, 8, 12, 20, 30 }, Gems = 2, Coins = 0 },
	{ Id = "Perfects", Name = "PERFECTIONIST", Icon = "Star", Kind = "Counter", Source = "Stats.Perfects", Text = "Make {n} PERFECTs", One = "Make a PERFECT", Goals = { 1, 10, 50, 250, 1000, 5000, 25000 }, Gems = 1, Coins = 1 },
	{ Id = "Playtime", Name = "TIME FLIES", Icon = "Clock", Kind = "Counter", Source = "Stats.Playtime", Text = "Play for {n}", Time = true, Goals = { 10 * MINUTE, 30 * MINUTE, HOUR, 3 * HOUR, 8 * HOUR, 24 * HOUR, 48 * HOUR, 100 * HOUR }, Gems = 1, Coins = 1 },
	{ Id = "Days", Name = "COME BACK", Icon = "Calendar", Kind = "Counter", Source = "Counters.Days", Text = "Play on {n} days", Goals = { 2, 3, 5, 7, 14, 30, 60, 100 }, Gems = 2, Coins = 0 },
	{ Id = "Upgrades", Name = "UPGRADER", Icon = "ArrowUp", Kind = "Counter", Source = "Counters.Upgrades", Text = "Buy {n} line upgrades", Goals = { 5, 25, 75, 200, 500, 1500 }, Gems = 0, Coins = 1 },
	{ Id = "Rolls", Name = "LUCKY ROLLER", Icon = "Roll", Kind = "Counter", Source = "Counters.Rolls", Text = "Open {n} Rolls", Goals = { 3, 10, 25, 75, 200, 500 }, Gems = 1, Coins = 0 },
	{ Id = "Spins", Name = "SPINNER", Icon = "Wheel", Kind = "Counter", Source = "Counters.Spins", Text = "Spin the wheel {n} times", One = "Spin the wheel once", Goals = { 1, 5, 15, 40, 100, 250 }, Gems = 1, Coins = 1 },
} :: { Achievement }

Achievements.ById = {} :: { [string]: Achievement }
for _, achievement in Achievements.List do
	Achievements.ById[achievement.Id] = achievement
end

Achievements.Rooms = ROOMS

-- How many tiers it has.
function Achievements.Tiers(achievement: Achievement): number
	if achievement.Kind == "Rarity" then
		return #Rarities.List
	elseif achievement.Kind == "Room" then
		return #ROOMS
	end
	return #(achievement.Goals :: { number })
end

-- What tier `tier` asks for: the amount (1 for Rarity and Room: done or not).
function Achievements.Goal(achievement: Achievement, tier: number): number
	if achievement.Kind == "Counter" then
		local goals = achievement.Goals :: { number }
		return goals[math.clamp(tier, 1, #goals)]
	end
	return 1
end

-- "1h 30m", "10m", "45s"
local function duration(seconds: number): string
	if seconds >= HOUR then
		local hours, minutes = seconds // HOUR, seconds % HOUR // MINUTE
		return if minutes > 0 then `{hours}h {minutes}m` else `{hours}h`
	elseif seconds >= MINUTE then
		return `{seconds // MINUTE}m`
	end
	return `{math.floor(seconds)}s`
end

-- An amount as the achievement shows it (a time, or a short number).
function Achievements.Amount(achievement: Achievement, value: number): string
	if achievement.Time then
		return duration(value)
	end
	return Format.Number(value)
end

-- What tier `tier` asks, in a few words.
function Achievements.Text(achievement: Achievement, tier: number): string
	if achievement.Kind == "Rarity" then
		local rarity = Rarities.List[math.clamp(tier, 1, #Rarities.List)]
		return `Claim a {string.upper(rarity.Id)} brainrot`
	elseif achievement.Kind == "Room" then
		local zone = ROOMS[math.clamp(tier, 1, #ROOMS)]
		return if zone then `Open the {zone.Name}` else ""
	end
	local goal = Achievements.Goal(achievement, tier)
	if goal == 1 and achievement.One then
		return achievement.One
	end
	local amount = Achievements.Amount(achievement, goal)
	return (string.gsub(achievement.Text :: string, "{n}", amount))
end

-- What tier `tier` pays: Gems, and Coins for an income of `income` a second.
function Achievements.Reward(achievement: Achievement, tier: number, income: number): (number, number)
	local step = math.clamp(tier, 1, #GEM_LADDER)
	local gems = GEM_LADDER[step] * achievement.Gems
	local seconds = COIN_SECONDS[step] * achievement.Coins
	local coins = if seconds > 0 then math.floor(math.max(seconds * MIN_COINS_PER_SECOND, income * seconds)) else 0
	return gems, coins
end

-- The rarity whose colors tier `tier` wears (Godly from the 6th up).
function Achievements.TierRarity(tier: number): Rarities.Rarity
	return Rarities.List[math.clamp(tier, 1, #Rarities.List)]
end

return Achievements
