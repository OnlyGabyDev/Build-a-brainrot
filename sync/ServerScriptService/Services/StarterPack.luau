--[[
	StarterPack
	The newcomer's bundle (Config/Gamepasses, any pass with a `Starter` reward; GDD §12):
	its parts, Coins, Rolls and a rain of loot boxes, once. It's a DataManager claim, so
	nothing is given twice, whether the pass is noticed on join, bought mid-game, or the
	data loads after the ownership check (both paths try; the claim decides).

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

local function giveOnce(player: Player, key: string, reward: Gamepasses.StarterReward)
	if not DataManager.Claim(player, `Pass_{key}`) then
		return
	end
	for _, entry in reward.Parts do
		DataManager.AddPart(player, entry[1], entry[2])
	end
	DataManager.AddCurrency(player, "Coins", reward.Coins)
	DataManager.AddRolls(player, reward.Rolls)
	LootManager.Drop(player, reward.Boxes)
	purchasedRemote:FireClient(player, `🎉 Starter Pack! New parts, +{Format.Number(reward.Coins)} 💰, +{reward.Rolls} 🎲 and {reward.Boxes} boxes raining down!`)
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
	for _, pass in Gamepasses do
		hours = math.max(hours, pass.OfferHours or 0)
	end
	if data and hours > 0 then
		player:SetAttribute("StarterOfferEnds", data.Stats.FirstJoin + hours * 60 * 60)
	end
	update(player)
end

function StarterPack.Init()
	purchasedRemote = Remotes.Event("Purchased")
	DataManager.OnPlayerLoaded(onLoaded)
	MonetizationManager.OnPassGranted(function(player, key)
		if Gamepasses[key].Starter then
			update(player)
		end
	end)
end

return StarterPack
