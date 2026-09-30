--[[
	MonetizationManager
	Gamepasses for now (GDD §12): checks ownership on join, grants passes bought
	mid-game, and mirrors ownership to Player attributes ("Pass_<Key>") for the UI.
	Other services ask OwnsPass; the attributes are display-only. Developer products
	and the daily wheel come later (sprint step 12).
]]

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Gamepasses = require(ReplicatedStorage.Shared.Config.Gamepasses)

-- Flip on to test pass perks in Studio before the passes exist.
local STUDIO_OWNS_ALL = false

local owned: { [Player]: { [string]: boolean } } = {}

local MonetizationManager = {}

local function grant(player: Player, key: string)
	local passes = owned[player]
	if passes and not passes[key] then
		passes[key] = true
		player:SetAttribute(`Pass_{key}`, true)
	end
end

local function onPlayerAdded(player: Player)
	owned[player] = {}
	for key, pass in Gamepasses do
		if pass.Id > 0 then
			local ok, has = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, pass.Id)
			if ok and has then
				grant(player, key)
			end
		elseif STUDIO_OWNS_ALL and RunService:IsStudio() then
			grant(player, key)
		end
	end
end

function MonetizationManager.Init()
	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end
	Players.PlayerRemoving:Connect(function(player)
		owned[player] = nil
	end)

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
		if not purchased then
			return
		end
		for key, pass in Gamepasses do
			if pass.Id == passId then
				grant(player, key)
			end
		end
	end)
end

function MonetizationManager.OwnsPass(player: Player, key: string): boolean
	local passes = owned[player]
	return passes ~= nil and passes[key] == true
end

return MonetizationManager
