--[[
	Rewards
	The shape every handed-out reward shares (the login calendar, the Daily Wheel, daily
	quests, free gifts) and what it comes to: Coins are seconds of the player's income
	(never under MinCoins), the rest fixed amounts. Services/RewardManager grants them;
	menus show them with Rewards.Text and Rewards.Icon.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Format = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Format"))

export type Reward = {
	Kind: string, -- "Coins" | "Gems" | "Rolls" | "Box" | "RarePart" | "LuckBoost"
	Amount: number?, -- Gems, Rolls
	IncomeSeconds: number?, -- Coins: seconds of the player's income...
	MinCoins: number?, -- ...but at least this many
	Rarity: string?, -- Box: a box of this rarity of your own lands in your front yard
	MinRank: number?, -- RarePart: a new part of this rarity rank or better
	Gems: number?, -- RarePart: Gems with it
	Seconds: number?, -- LuckBoost: how long it lasts
	Label: string?, -- a card's own words for it (else Rewards.Text)
	Icon: string?, -- a card's own icon for it (else Rewards.Icon)
}

local Rewards = {}

local ICONS = { Coins = "Coin", Gems = "Gem", Rolls = "Roll", Box = "Gift", RarePart = "Star", LuckBoost = "Clover" }

-- The Coins a Coins reward pays at `income` Coins a second.
function Rewards.Coins(reward: Reward, income: number): number
	return math.floor(math.max(reward.MinCoins or 0, income * (reward.IncomeSeconds or 0)))
end

-- A few words for it ("+1.2K COINS", "2 ROLLS", "RARE BOX"), at `income` for Coins.
function Rewards.Text(reward: Reward, income: number): string
	local kind, amount = reward.Kind, reward.Amount or 0
	if kind == "Coins" then
		return `{Format.Number(Rewards.Coins(reward, income))} COINS`
	elseif kind == "Gems" then
		return `{Format.Number(amount)} GEMS`
	elseif kind == "Rolls" then
		return if amount == 1 then "1 ROLL" else `{amount} ROLLS`
	elseif kind == "Box" then
		return `{string.upper(reward.Rarity or "Common")} BOX`
	elseif kind == "RarePart" then
		return "RARE+ PART"
	elseif kind == "LuckBoost" then
		return `LUCK {math.floor((reward.Seconds or 0) / 60)}m`
	end
	return reward.Label or ""
end

function Rewards.Icon(reward: Reward): string
	return reward.Icon or ICONS[reward.Kind] or "Gift"
end

return Rewards
