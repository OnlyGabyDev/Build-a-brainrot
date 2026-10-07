--[[
	RewardManager
	Grants one reward of the shared shape (Shared/Rewards): the login calendar, the
	Daily Wheel, daily quests and free gifts hand theirs out through it.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Format = require(ReplicatedStorage.Shared.Format)
local Rewards = require(ReplicatedStorage.Shared.Rewards)

local DataManager = require(script.Parent.DataManager)
local LootManager = require(script.Parent.LootManager)
local ProductionManager = require(script.Parent.ProductionManager)

local RewardManager = {}

-- Gives `reward` (`source` names where a part comes from). Returns the line the client
-- shows ("+1.2K COINS!"), and a part to reveal (RarePart).
function RewardManager.Grant(player: Player, reward: Rewards.Reward, source: string): (string, any?)
	local kind, amount = reward.Kind, reward.Amount or 0
	if kind == "Coins" then
		local coins = Rewards.Coins(reward, ProductionManager.GetIncome(player))
		DataManager.AddCurrency(player, "Coins", coins)
		return `+{Format.Number(coins)} COINS!`
	elseif kind == "Gems" then
		DataManager.AddCurrency(player, "Gems", amount)
		return `+{Format.Number(amount)} GEMS!`
	elseif kind == "Rolls" then
		DataManager.AddRolls(player, amount)
		return `+{amount} {if amount == 1 then "ROLL" else "ROLLS"}!`
	elseif kind == "Box" then
		LootManager.GiftBox(player, reward.Rarity)
		return `A {string.upper(reward.Rarity or "")} BOX in your yard!`
	elseif kind == "RarePart" then
		if reward.Gems then
			DataManager.AddCurrency(player, "Gems", reward.Gems)
		end
		local result = LootManager.GrantRarePart(player, reward.MinRank or 3, source)
		return `A NEW PART + {reward.Gems or 0} GEMS!`, result
	elseif kind == "LuckBoost" then
		DataManager.AddBoost(player, "Luck", reward.Seconds or 0)
		return `LUCK BOOST {math.floor((reward.Seconds or 0) / 60)} min!`
	end
	return reward.Label or ""
end

return RewardManager
