--[[
	StarterPack
	The newcomer's bundle (Config/Gamepasses, any pass with a `Starter` reward; GDD §12):
	its parts, Coins, Rolls and a rain of loot boxes, once. It's a DataManager claim
	("Pass_<Key>"), so nothing is given twice.
	  * Sold as a developer product (`Product`, the Starter Pack now): granted in the
	    purchase's receipt, and the claim is what says it's owned on later joins.
	  * Sold as a gamepass: given whether the pass is noticed on join, bought mid-game, or
	    the data loads after the ownership check (both paths try; the claim decides).

	The offer itself (the shop card, the corner ad) is sold only for the pass's
	OfferHours after the player's first join: the "StarterOfferEnds" attribute (server
	epoch seconds) tells the client when it ends.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Format = require(Shared.Format)
local Gamepasses = require(Shared.Config.Gamepasses)
local Remotes = require(Shared.Remotes)

local DataManager = require(script.Parent.DataManager)
local LootManager = require(script.Parent.LootManager)
local MonetizationManager = require(script.Parent.MonetizationManager)

local StarterPack = {}

local purchasedRemote: RemoteEvent

-- Gives the bundle and returns the thank-you line.
local function give(player: Player, reward: Gamepasses.StarterReward): string
	for _, entry in reward.Parts do
		DataManager.AddPart(player, entry[1], entry[2])
	end
	DataManager.AddCurrency(player, "Coins", reward.Coins)
	DataManager.AddRolls(player, reward.Rolls)
	LootManager.Drop(player, reward.Boxes)
	return `STARTER PACK! +{Format.Number(reward.Coins)} Coins, +{reward.Rolls} Rolls, {reward.Boxes} boxes!`
end

local function giveOnce(player: Player, key: string, reward: Gamepasses.StarterReward)
	if not DataManager.Claim(player, `Pass_{key}`) then
		return
	end
	purchasedRemote:FireClient(player, give(player, reward))
end

-- Gives every Starter pass the player owns (if not given yet).
local function update(player: Player)
	if not DataManager.IsLoaded(player) then
		return
	end
	for key, pass in Gamepasses do
		local reward = pass.Starter
		if reward and MonetizationManager.OwnsPass(player, key) then
			giveOnce(player, key, reward)
		end
	end
end

local function onLoaded(player: Player)
	local data = DataManager.GetData(player)
	local hours = 0
	for key, pass in Gamepasses do
		hours = math.max(hours, pass.OfferHours or 0)
		-- a product bought before: its claim is the proof
		if pass.Product and data and data.Claims[`Pass_{key}`] then
			MonetizationManager.MarkOwned(player, key)
		end
	end
	if data and hours > 0 then
		player:SetAttribute("StarterOfferEnds", data.Stats.FirstJoin + hours * 60 * 60)
	end
	update(player)
end

function StarterPack.Init()
	purchasedRemote = Remotes.Event("Purchased")
	for key, pass in Gamepasses do
		local reward = pass.Starter
		if reward and pass.Product then
			-- every paid receipt gives the bundle (the shop hides it once owned, so a
			-- second one only comes from two prompts at once: not worth taking Robux for nothing)
			MonetizationManager.HandlePassProduct(key, function(player)
				DataManager.Claim(player, `Pass_{key}`)
				local thanks = give(player, reward)
				MonetizationManager.MarkOwned(player, key)
				return thanks
			end)
		end
	end
	DataManager.OnPlayerLoaded(onLoaded)
	MonetizationManager.OnPassGranted(function(player, key)
		if Gamepasses[key].Starter then
			update(player)
		end
	end)
end

return StarterPack
