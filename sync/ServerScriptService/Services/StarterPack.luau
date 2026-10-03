--[[
	StarterPack
	The newcomer's bundle (Config/Gamepasses, any pass with a `Starter` reward; GDD §12):
	once, its parts, Coins and a rain of loot boxes; then its Rolls once a day for as
	long as the player owns it. Both are DataManager claims, so nothing is given twice,
	whether the pass is noticed on join, bought mid-game, or the data loads after the
	ownership check (both paths try; the claim decides).

	The offer itself (the shop card, the corner ad) is sold only for the pass's
	OfferHours after the player's first join: the "StarterOfferEnds" attribute (server
	epoch seconds) tells the client when it ends.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Format = require(Shared.Format)
local Gamepasses = require(Shared.Config.Gamepasses)
local Remotes = require(Shared.Remotes)

local DataManager = require(script.Parent.DataManager)
local LootManager = require(script.Parent.LootManager)
local MonetizationManager = require(script.Parent.MonetizationManager)

local DAY = 24 * 60 * 60
local DAILY_CHECK = 10 * 60 -- seconds between checks for the daily Rolls while playing

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
	LootManager.Drop(player, reward.Boxes)
	purchasedRemote:FireClient(player, `🎉 Starter Pack! New parts, +{Format.Number(reward.Coins)} 💰 and {reward.Boxes} boxes raining down!`)
end

local function giveDaily(player: Player, key: string, reward: Gamepasses.StarterReward)
	if reward.DailyRolls > 0 and DataManager.Claim(player, `Pass_{key}_Daily`, DAY) then
		DataManager.AddRolls(player, reward.DailyRolls)
		purchasedRemote:FireClient(player, `🎲 Your daily {reward.DailyRolls} free Rolls are here!`)
	end
end

-- Gives whatever's due for every Starter pass the player owns.
local function update(player: Player)
	if not DataManager.IsLoaded(player) then
		return
	end
	for key, pass in Gamepasses do
		local reward = pass.Starter
		if reward and MonetizationManager.OwnsPass(player, key) then
			giveOnce(player, key, reward)
			giveDaily(player, key, reward)
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
	task.spawn(function()
		while true do
			task.wait(DAILY_CHECK)
			for _, player in Players:GetPlayers() do
				update(player)
			end
		end
	end)
end

return StarterPack
