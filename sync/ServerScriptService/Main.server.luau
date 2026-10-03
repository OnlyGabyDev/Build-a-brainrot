-- Server entry point: requires each service and initializes it, in dependency order.
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

-- The world is built over several frames (Services/WorkBudget): nobody spawns until
-- it's there (no falling through ground that isn't filled in yet).
Players.CharacterAutoLoads = false

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
local DailyWheelManager = require(Services:WaitForChild("DailyWheelManager"))
local DevTools = require(Services:WaitForChild("DevTools"))
local LeaderboardManager = require(Services:WaitForChild("LeaderboardManager"))
local StarterPack = require(Services:WaitForChild("StarterPack"))

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
GadgetManager.Init()
RebirthManager.Init()
DailyWheelManager.Init()
DevTools.Init() -- Studio only
