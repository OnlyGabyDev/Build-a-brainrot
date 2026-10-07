--[[
	AchievementManager
	Achievements in tiers (GDD §5 "Achievements", Config/Achievements). It counts what
	the others don't (boxes opened, days played, rooms opened; DataManager counts Rolls
	and wheel spins, ProductionManager brainrots built, TycoonManager line upgrades),
	mirrors each achievement for the client as attributes ("AchTier_<id>": tiers claimed,
	"Ach_<id>": its progress toward the next tier) with the player's income ("Income",
	Coins a second: the menu shows the Coins a tier pays), and pays a tier when the
	client claims it (ClaimAchievement), or every one that's done (ClaimAllAchievements).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Achievements = require(Shared.Config.Achievements)
local Brainrots = require(Shared.Config.Brainrots)
local Rarities = require(Shared.Config.Rarities)
local Remotes = require(Shared.Remotes)

local DataManager = require(script.Parent.DataManager)
local LootManager = require(script.Parent.LootManager)
local ProductionManager = require(script.Parent.ProductionManager)

local REFRESH_INTERVAL = 1 -- seconds between progress updates
local REQUEST_COOLDOWN = 0.3
local SECONDS_PER_DAY = 86400 -- UTC days

local lastRequest: { [Player]: number } = {}

local AchievementManager = {}

-- What a Counter achievement (or a daily quest) reads: "Rebirths", "Parts" (parts
-- owned), or "Counters.<name>" / "Stats.<name>".
local function sourceValue(data: DataManager.PlayerData, source: string): number
	if source == "Rebirths" then
		return data.Rebirths
	elseif source == "Parts" then
		local count = 0
		for _, owned in data.Inventory.Parts do
			for _ in owned do
				count += 1
			end
		end
		return count
	end
	local section, name = string.match(source, "^(%a+)%.(%a+)$")
	if section == "Counters" and name then
		return data.Counters[name] or 0
	elseif section == "Stats" and name then
		local value = (data.Stats :: any)[name]
		return if type(value) == "number" then value else 0
	end
	return 0
end

-- Progress toward tier `tier` (a Counter's count; 1 or 0 for Rarity and Room).
local function progress(data: DataManager.PlayerData, achievement: Achievements.Achievement, tier: number): number
	if achievement.Kind == "Rarity" then
		local rarity = Rarities.List[tier]
		for brainrotId in data.Inventory.Claimed do
			local brainrot = Brainrots.ById[brainrotId]
			if rarity and brainrot and brainrot.Rarity == rarity.Id then
				return 1
			end
		end
		return 0
	elseif achievement.Kind == "Room" then
		local zone = Achievements.Rooms[tier]
		return if zone and (data.Counters[`Room_{zone.Id}`] or 0) > 0 then 1 else 0
	end
	return sourceValue(data, achievement.Source :: string)
end

local function setAttribute(player: Player, name: string, value: any)
	if player:GetAttribute(name) ~= value then
		player:SetAttribute(name, value)
	end
end

-- Counts today and the rooms open now, then mirrors every achievement.
local function update(player: Player)
	local data = DataManager.GetData(player)
	if not data then
		return
	end
	if DataManager.SetCounterMax(player, "LastDay", os.time() // SECONDS_PER_DAY) then
		DataManager.AddCounter(player, "Days", 1)
	end
	for _, zone in Achievements.Rooms do
		if data.Tycoon.Purchased[`{zone.Id}_Room`] then
			DataManager.SetCounterMax(player, `Room_{zone.Id}`, 1)
		end
	end
	for _, achievement in Achievements.List do
		local claimed = data.Achievements[achievement.Id] or 0
		local tier = math.min(claimed + 1, Achievements.Tiers(achievement))
		setAttribute(player, `AchTier_{achievement.Id}`, claimed)
		setAttribute(player, `Ach_{achievement.Id}`, progress(data, achievement, tier))
	end
	setAttribute(player, "Income", math.floor(ProductionManager.GetIncome(player)))
end

-- Pays an achievement's next tier if it's done: its tier, Gems and Coins, or nil.
local function claimNext(player: Player, data: DataManager.PlayerData, achievement: Achievements.Achievement): (number?, number, number)
	local tier = (data.Achievements[achievement.Id] or 0) + 1
	if tier > Achievements.Tiers(achievement) or progress(data, achievement, tier) < Achievements.Goal(achievement, tier) then
		return nil, 0, 0
	end
	if not DataManager.ClaimAchievementTier(player, achievement.Id, tier) then
		return nil, 0, 0
	end
	local gems, coins = Achievements.Reward(achievement, tier, ProductionManager.GetIncome(player))
	if gems > 0 then
		DataManager.AddCurrency(player, "Gems", gems)
	end
	if coins > 0 then
		DataManager.AddCurrency(player, "Coins", coins)
	end
	return tier, gems, coins
end

local function allowed(player: Player): boolean
	local now = os.clock()
	if (lastRequest[player] or 0) + REQUEST_COOLDOWN > now then
		return false
	end
	lastRequest[player] = now
	return true
end

-- Claims an achievement's next tier: { Id, Tier, Gems, Coins } or nil.
local function onClaim(player: Player, achievementId: unknown): any
	if typeof(achievementId) ~= "string" or not allowed(player) then
		return nil
	end
	local achievement = Achievements.ById[achievementId]
	local data = DataManager.GetData(player)
	if not (achievement and data) then
		return nil
	end
	local tier, gems, coins = claimNext(player, data, achievement)
	if not tier then
		return nil
	end
	update(player)
	return { Id = achievementId, Tier = tier, Gems = gems, Coins = coins }
end

-- Claims every tier that's done, several of one achievement too:
-- { Count, Tier (the highest), Gems, Coins } or nil when none was.
local function onClaimAll(player: Player): any
	local data = DataManager.GetData(player)
	if not (data and allowed(player)) then
		return nil
	end
	local count, top, totalGems, totalCoins = 0, 0, 0, 0
	for _, achievement in Achievements.List do
		while true do
			local tier, gems, coins = claimNext(player, data, achievement)
			if not tier then
				break
			end
			count += 1
			top = math.max(top, tier)
			totalGems += gems
			totalCoins += coins
		end
	end
	if count == 0 then
		return nil
	end
	update(player)
	return { Count = count, Tier = top, Gems = totalGems, Coins = totalCoins }
end

-- Re-reads the player's achievements into their attributes (after DevTools changes them).
AchievementManager.Refresh = update
AchievementManager.SourceValue = sourceValue

function AchievementManager.Init()
	Remotes.Function("ClaimAchievement").OnServerInvoke = onClaim
	Remotes.Function("ClaimAllAchievements").OnServerInvoke = onClaimAll
	DataManager.OnPlayerLoaded(update)
	LootManager.BoxOpened.Event:Connect(function(player: Player)
		DataManager.AddCounter(player, "Boxes", 1)
	end)
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

return AchievementManager
