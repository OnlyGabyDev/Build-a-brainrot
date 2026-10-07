--[[
	FreeGifts (GDD §5 "Free gifts", the user 2026-10-07; Pet Simulator's "Free Gifts")
	Nine gifts a UTC day, each opening after so many minutes played that day (all
	sessions together, so leaving doesn't start them over), the later ones better.
	Services/FreeGifts times and pays them; Client/UI/GiftsMenu shows them.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Rewards = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Rewards"))

export type Gift = { Minutes: number, Reward: Rewards.Reward }

local FreeGifts = {}

FreeGifts.SecondsPerDay = 86400 -- UTC days
FreeGifts.List = {
	{ Minutes = 1, Reward = { Kind = "Coins", IncomeSeconds = 60, MinCoins = 500 } },
	{ Minutes = 3, Reward = { Kind = "Gems", Amount = 10 } },
	{ Minutes = 5, Reward = { Kind = "Coins", IncomeSeconds = 180, MinCoins = 2000 } },
	{ Minutes = 10, Reward = { Kind = "Rolls", Amount = 1 } },
	{ Minutes = 15, Reward = { Kind = "Gems", Amount = 25 } },
	{ Minutes = 20, Reward = { Kind = "LuckBoost", Seconds = 10 * 60 } },
	{ Minutes = 30, Reward = { Kind = "Coins", IncomeSeconds = 600, MinCoins = 10000 } },
	{ Minutes = 45, Reward = { Kind = "Rolls", Amount = 2 } },
	{ Minutes = 60, Reward = { Kind = "Box", Rarity = "Rare" } },
} :: { Gift }

return FreeGifts
