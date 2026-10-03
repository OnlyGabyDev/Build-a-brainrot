--[[
	MonetizationManager
	Gamepasses and developer products (GDD §12).
	  * Gamepasses: ownership is checked on join and granted when bought mid-game. Perks
	    come from the passes' config fields (Config/Gamepasses), so services ask for a
	    perk ("RemoteLines", "AutoCollect") or a number (IncomeMultiplier, Luck), never
	    for a specific pass. Owned passes and perks are mirrored to Player attributes
	    ("Pass_<Key>", "Perk_<Name>") for the UI; the attributes are display-only.
	  * Developer products: granted in ProcessReceipt through DataManager, which records
	    each receipt so a purchase is never granted twice. Products with a GemPrice (box
	    drops, wheel spins) are bought with Gems instead (remote BuyWithGems), through the
	    same handlers.
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
local NukeManager = require(script.Parent.NukeManager)

-- Flip on to test pass perks in Studio before the passes exist.
local STUDIO_OWNS_ALL = false
local PERK_FLAGS = { "RemoteLines", "AutoCollect" }
local passPrices: { [number]: number } = {} -- Robux, fetched once (for the Robux-spent leaderboard)

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

-- How each product Kind is granted: it gives the player the goods and returns the
-- thank-you line. Kinds that need another service (Coins: income; BoxDrop: the map)
-- are registered by it at Init (MonetizationManager.HandleProduct), so this module
-- doesn't require them (they require it).
type ProductHandler = (player: Player, product: Products.Product) -> string
local productHandlers: { [string]: ProductHandler } = {
	Gems = function(player, product)
		DataManager.AddCurrency(player, "Gems", product.Amount)
		return `Thanks! +{product.Amount} 💎`
	end,
	Rolls = function(player, product)
		DataManager.AddRolls(player, product.Amount)
		return `Thanks! +{product.Amount} 🎲`
	end,
	WheelSpins = function(player, product)
		DataManager.AddWheelSpins(player, product.Amount)
		return `Thanks! +{product.Amount} 🎡`
	end,
	Nuke = function(player)
		NukeManager.Launch(player)
		return "☢️ NUKE INCOMING! ☢️"
	end,
}

local function processReceipt(receipt: { [string]: any }): Enum.ProductPurchaseDecision
	local player = Players:GetPlayerByUserId(receipt.PlayerId)
	local product = productsById[receipt.ProductId]
	local handler = product and productHandlers[product.Kind]
	if not (player and product and handler and DataManager.IsLoaded(player)) then
		return Enum.ProductPurchaseDecision.NotProcessedYet -- Roblox retries later
	end
	local thanks: string? = nil
	local granted = DataManager.ProcessReceipt(player, tostring(receipt.PurchaseId), function()
		thanks = handler(player, product)
		DataManager.AddStat(player, "RobuxSpent", tonumber(receipt.CurrencySpent) or 0)
	end)
	if not granted then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	-- (no `thanks` when this receipt was already granted: a retry after a failed save)
	purchasedRemote:FireClient(player, thanks or "Thanks!")
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

-- A product bought with Gems: the server checks its price and takes the Gems before
-- granting it with the same handler as a Robux purchase. True if it went through.
local function buyWithGems(player: Player, key: unknown): boolean
	local product = if type(key) == "string" then Products[key] else nil
	local handler = product and productHandlers[product.Kind]
	if not (product and product.GemPrice and handler and DataManager.IsLoaded(player)) then
		return false
	end
	if not DataManager.SpendCurrency(player, "Gems", product.GemPrice) then
		return false
	end
	purchasedRemote:FireClient(player, handler(player, product))
	return true
end

-- Public API -------------------------------------------------------------------

function MonetizationManager.Init()
	purchasedRemote = Remotes.Event("Purchased")
	Remotes.Function("BuyWithGems").OnServerInvoke = buyWithGems
	NukeManager.Init()
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
		-- what it cost, for the Robux-spent leaderboard
		local price = passPrices[passId]
		if not price then
			local ok, info = pcall(MarketplaceService.GetProductInfo, MarketplaceService, passId, Enum.InfoType.GamePass)
			price = if ok and info and info.PriceInRobux then info.PriceInRobux else 0
			passPrices[passId] = price
		end
		DataManager.AddStat(player, "RobuxSpent", price)
	end)
	MarketplaceService.ProcessReceipt = processReceipt
end

-- Studio only: gives `player` a pass for this session (DevTools' GrantPass), to test
-- its perks before the passes exist. Nothing is saved: ownership is Roblox's.
function MonetizationManager.GrantForTesting(player: Player, key: string): boolean
	if not (RunService:IsStudio() and Gamepasses[key]) then
		return false
	end
	grant(player, key)
	return true
end

-- Studio only: grants a product as if bought (DevTools' GrantProduct), to test it
-- before its id exists. Nothing is charged and no receipt is kept.
function MonetizationManager.GrantProductForTesting(player: Player, key: string): boolean
	local product = Products[key]
	local handler = product and productHandlers[product.Kind]
	if not (RunService:IsStudio() and handler and DataManager.IsLoaded(player)) then
		return false
	end
	purchasedRemote:FireClient(player, handler(player, product))
	return true
end

-- Registers how products of `kind` are granted (see productHandlers). Call it at Init.
function MonetizationManager.HandleProduct(kind: string, handler: ProductHandler)
	assert(productHandlers[kind] == nil, `product kind {kind} already has a handler`)
	productHandlers[kind] = handler
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
