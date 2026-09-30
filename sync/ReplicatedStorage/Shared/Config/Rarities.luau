--[[
	Rarity tiers, lowest to highest (GDD §4). All numbers are placeholders to tune in playtests.
]]

export type Rarity = {
	Id: string,
	Rank: number, -- 1 = Common ... 6 = Godly (filled in below)
	Color: Color3,
	LootWeight: number, -- relative chance on loot boxes and Rolls
	PartValue: number, -- Coins each part adds to a shipped brainrot
	CompletionGems: number, -- Gems for completing in Zone 1 (scaled by each zone's GemMultiplier)
	DuplicateCurrency: string, -- what a duplicate part converts into
	DuplicateValue: number, -- how much of it (Coin duplicates also add some income, see Config/Loot)
	UnlockRebirths: number, -- rebirths needed before this rarity can drop
}

local Rarities = {}

Rarities.List = {
	{
		Id = "Common",
		Rank = 0,
		Color = Color3.fromRGB(200, 205, 210),
		LootWeight = 60,
		PartValue = 5,
		CompletionGems = 10,
		DuplicateCurrency = "Coins",
		DuplicateValue = 100,
		UnlockRebirths = 0,
	},
	{
		Id = "Uncommon",
		Rank = 0,
		Color = Color3.fromRGB(91, 227, 91),
		LootWeight = 25,
		PartValue = 12,
		CompletionGems = 25,
		DuplicateCurrency = "Coins",
		DuplicateValue = 250,
		UnlockRebirths = 0,
	},
	{
		Id = "Rare",
		Rank = 0,
		Color = Color3.fromRGB(61, 165, 255),
		LootWeight = 10,
		PartValue = 30,
		CompletionGems = 60,
		DuplicateCurrency = "Coins",
		DuplicateValue = 600,
		UnlockRebirths = 1,
	},
	{
		Id = "Legendary",
		Rank = 0,
		Color = Color3.fromRGB(255, 197, 61),
		LootWeight = 4,
		PartValue = 100,
		CompletionGems = 150,
		DuplicateCurrency = "Gems",
		DuplicateValue = 30,
		UnlockRebirths = 4,
	},
	{
		Id = "Mythic",
		Rank = 0,
		Color = Color3.fromRGB(255, 79, 216),
		LootWeight = 0.9,
		PartValue = 350,
		CompletionGems = 400,
		DuplicateCurrency = "Gems",
		DuplicateValue = 80,
		UnlockRebirths = 10,
	},
	{
		Id = "Godly",
		Rank = 0,
		Color = Color3.fromRGB(255, 255, 255), -- shown as an animated rainbow in UI
		LootWeight = 0.1,
		PartValue = 1500,
		CompletionGems = 1000,
		DuplicateCurrency = "Gems",
		DuplicateValue = 250,
		UnlockRebirths = 20,
	},
} :: { Rarity }

Rarities.ById = {} :: { [string]: Rarity }
for rank, rarity in Rarities.List do
	rarity.Rank = rank
	Rarities.ById[rarity.Id] = rarity
end

return Rarities
