-- Server entry point: requires each service and initializes it, in dependency order.
local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- The world is built over several frames (Services/WorkBudget): nobody spawns until
-- it's there (no falling through ground that isn't filled in yet).
Players.CharacterAutoLoads = false

-- The loading screen's brainrots (ReplicatedFirst/LoadingScreen): every brainrot built
-- whole, first thing, into ReplicatedFirst, so a joining player gets them before
-- anything else (~1K parts, ~70 ms).
do
	local Shared = ReplicatedStorage:WaitForChild("Shared")
	local BrainrotModels = require(Shared:WaitForChild("BrainrotModels"))
	local Brainrots = require(Shared.Config.Brainrots)
	local Rarities = require(Shared.Config.Rarities)
	local folder = Instance.new("Folder")
	folder.Name = "LoadingBrainrots"
	for _, brainrot in Brainrots.List do
		local figure = Instance.new("Model")
		figure.Name = brainrot.Id
		for _, partType in Brainrots.PartTypes do
			BrainrotModels.CreatePart(brainrot.Id, partType).Parent = figure
		end
		local rarity = Rarities.ById[brainrot.Rarity]
		figure:SetAttribute("Rarity", string.upper(rarity.Id))
		figure:SetAttribute("Rank", rarity.Rank)
		figure:SetAttribute("Color", rarity.Color)
		figure.Parent = folder
	end
	folder:SetAttribute("Count", #Brainrots.List)
	folder:SetAttribute("Host", Brainrots.StarterId)
	folder.Parent = ReplicatedFirst
end

local Services = ServerScriptService:WaitForChild("Services")

local DataManager = require(Services:WaitForChild("DataManager"))
local BadgeManager = require(Services:WaitForChild("BadgeManager"))
local MonetizationManager = require(Services:WaitForChild("MonetizationManager"))
local TycoonManager = require(Services:WaitForChild("TycoonManager"))
local ProductionManager = require(Services:WaitForChild("ProductionManager"))
local MapBuilder = require(Services:WaitForChild("MapBuilder"))
local LootManager = require(Services:WaitForChild("LootManager"))
local GadgetManager = require(Services:WaitForChild("GadgetManager"))
local RebirthManager = require(Services:WaitForChild("RebirthManager"))
local MascotManager = require(Services:WaitForChild("MascotManager"))
local DailyWheelManager = require(Services:WaitForChild("DailyWheelManager"))
local DailyLogin = require(Services:WaitForChild("DailyLogin"))
local AchievementManager = require(Services:WaitForChild("AchievementManager"))
local DailyMissions = require(Services:WaitForChild("DailyMissions"))
local FreeGifts = require(Services:WaitForChild("FreeGifts"))
local OfflineEarnings = require(Services:WaitForChild("OfflineEarnings"))
local DevTools = require(Services:WaitForChild("DevTools"))
local AnalyticsManager = require(Services:WaitForChild("AnalyticsManager"))
local LeaderboardManager = require(Services:WaitForChild("LeaderboardManager"))
local StarterPack = require(Services:WaitForChild("StarterPack"))
local GuideManager = require(Services:WaitForChild("GuideManager"))

DataManager.Init()
BadgeManager.Init()
MonetizationManager.Init()
TycoonManager.Init()
MapBuilder.Init() -- lays the hub out around the plots
Players.CharacterAutoLoads = true
for _, player in Players:GetPlayers() do
	if not player.Character then
		task.spawn(player.LoadCharacter, player)
	end
end
LeaderboardManager.Init() -- the boards and the podium, in the spots the plaza left
ProductionManager.Init()
LootManager.Init()
StarterPack.Init() -- after LootManager (its boxes) and MonetizationManager (its pass)
GuideManager.Init() -- Tralalero's guide
GadgetManager.Init()
RebirthManager.Init()
MascotManager.Init() -- the company mascot out front (after TycoonManager: it stands on the plots)
DailyWheelManager.Init()
DailyLogin.Init() -- the login streak
AchievementManager.Init() -- achievements in tiers
DailyMissions.Init() -- three daily quests
FreeGifts.Init() -- gifts for time played each day
OfflineEarnings.Init() -- what the factory made while you were away
DevTools.Init() -- developers only (Studio, the owner, group admins)
AnalyticsManager.Init() -- funnel and economy events (last: after every service that banks Coins as a player leaves)
