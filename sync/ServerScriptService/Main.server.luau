-- Server entry point: requires each service and initializes it, in dependency order.
local ServerScriptService = game:GetService("ServerScriptService")

local Services = ServerScriptService:WaitForChild("Services")

local DataManager = require(Services:WaitForChild("DataManager"))
local MonetizationManager = require(Services:WaitForChild("MonetizationManager"))
local TycoonManager = require(Services:WaitForChild("TycoonManager"))
local ProductionManager = require(Services:WaitForChild("ProductionManager"))
local LootManager = require(Services:WaitForChild("LootManager"))
local GadgetManager = require(Services:WaitForChild("GadgetManager"))
local RebirthManager = require(Services:WaitForChild("RebirthManager"))
local DevTools = require(Services:WaitForChild("DevTools"))

DataManager.Init()
MonetizationManager.Init()
TycoonManager.Init()
ProductionManager.Init()
LootManager.Init()
GadgetManager.Init()
RebirthManager.Init()
DevTools.Init() -- Studio only
