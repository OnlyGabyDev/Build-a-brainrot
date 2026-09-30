--[[
	MonetizationManager
	Gamepasses and developer products (GDD §12).
	  * Gamepasses: ownership is checked on join and granted when bought mid-game. Perks
	    come from the passes' config fields (Config/Gamepasses), so services ask for a
	    perk ("RemoteLines", "AutoCollect") or a number (IncomeMultiplier, Luck), never
	    for a specific pass. Owned passes and perks are mirrored to Player attributes
	    ("Pass_<Key>", "Perk_<Name>") for the UI; the attributes are display-only.
	  * Developer products: granted in ProcessReceipt through DataManager, which records
	    each receipt so a purchase is never granted twice.
	The Daily Wheel lives in DailyWheelManager.
]]

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage.Shared
local DailyWheel = require(Shared.Config.DailyWheel)
local Gamepasses = require(Shared.Config.Gamepasses)
local Products = require(Shared.Config.Products)
local Remotes = require(Shared.Remotes)

local DataManager = require(script.Parent.DataManager)

-- Flip on to test pass perks in Studio before the passes exist.
local STUDIO_OWNS_ALL = false
local PERK_FLAGS = { "RemoteLines", "AutoCollect" }
local CURRENCY_ICONS = { Gems = "💎", Rolls = "🎲", WheelSpins = "🎡" }

local owned: { [Player]: { [string]: boolean } } = {}
local grantedCallbacks: { (player: Player, key: string) -> () } = {}
local purchasedRemote: RemoteEvent

local productsById: { [number]: Products.Product } = {}
for _, product in Products do
	if product.Id > 0 then
		productsById[product.Id] = product
	end
end

local MonetizationManager = {}

-- Gamepasses -------------------------------------------------------------------

local function ownedPasses(player: Player): { Gamepasses.Pass }
	local list = {}
	local passes: { [string]: boolean } = owned[player] or {}
	for key in passes do
		table.insert(list, Gamepasses[key])
	end
	return list
end

local function grant(player: Player, key: string)
	local passes = owned[player]
	if not passes or passes[key] then
		return
	end
	passes[key] = true
	player:SetAttribute(`Pass_{key}`, true)
	for _, perk in PERK_FLAGS do
		if (Gamepasses[key] :: any)[perk] then
			player:SetAttribute(`Perk_{perk}`, true)
		end
	end
	for _, callback in grantedCallbacks do
		task.spawn(callback, player, key)
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

-- Developer products ------------------------------------------------------------

local function processReceipt(receipt: { [string]: any }): Enum.ProductPurchaseDecision
	local player = Players:GetPlayerByUserId(receipt.PlayerId)
	local product = productsById[receipt.ProductId]
	if not (player and product and DataManager.IsLoaded(player)) then
		return Enum.ProductPurchaseDecision.NotProcessedYet -- Roblox retries later
	end
	local granted = DataManager.ProcessReceipt(player, tostring(receipt.PurchaseId), function()
		if product.Kind == "Gems" then
			DataManager.AddCurrency(player, "Gems", product.Amount)
		elseif product.Kind == "Rolls" then
			DataManager.AddRolls(player, product.Amount)
		elseif product.Kind == "WheelSpins" then
			DataManager.AddWheelSpins(player, product.Amount)
		end
	end)
	if not granted then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	purchasedRemote:FireClient(player, `Thanks! +{product.Amount} {CURRENCY_ICONS[product.Kind] or ""}`)
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

-- Public API -------------------------------------------------------------------

function MonetizationManager.Init()
	purchasedRemote = Remotes.Event("Purchased")
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
	MarketplaceService.ProcessReceipt = processReceipt
end

-- Runs `callback(player, passKey)` whenever a player gets a pass (on join or bought).
function MonetizationManager.OnPassGranted(callback: (player: Player, key: string) -> ())
	table.insert(grantedCallbacks, callback)
end

function MonetizationManager.OwnsPass(player: Player, key: string): boolean
	local passes = owned[player]
	return passes ~= nil and passes[key] == true
end

-- Whether any owned pass gives this perk flag ("RemoteLines", "AutoCollect").
function MonetizationManager.HasPerk(player: Player, perk: string): boolean
	for _, pass in ownedPasses(player) do
		if (pass :: any)[perk] then
			return true
		end
	end
	return false
end

-- × Coins on every ship from passes (VIP, 2x Coins).
function MonetizationManager.IncomeMultiplier(player: Player): number
	local multiplier = 1
	for _, pass in ownedPasses(player) do
		multiplier *= pass.IncomeMultiplier or 1
	end
	return multiplier
end

-- Extra luck from passes and a running Luck boost (the Rebirth Shop adds its own).
function MonetizationManager.Luck(player: Player): number
	local luck = if DataManager.HasBoost(player, "Luck") then DailyWheel.LuckBoost else 0
	for _, pass in ownedPasses(player) do
		luck += pass.Luck or 0
	end
	return luck
end

-- Free Daily Wheel spins per day (VIP adds one).
function MonetizationManager.FreeSpinsPerDay(player: Player): number
	local spins = DailyWheel.FreeSpinsPerDay
	for _, pass in ownedPasses(player) do
		spins += pass.FreeSpins or 0
	end
	return spins
end

return MonetizationManager
