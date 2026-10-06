--[[
	Rarity tiers, lowest to highest (GDD §4). All numbers are placeholders to tune in playtests.
	Every rarity drops from the start (2026-10-06, the user: no rarity cap); the weights keep
	the high ones rare, and rebirths add luck (Config/Rebirths).
]]

export type Rarity = {
	Id: string,
	Rank: number, -- 1 = Common ... 6 = Godly (filled in below)
	Color: Color3,
	LootWeight: number, -- relative chance on loot boxes and Rolls (nerfed 2026-10-03: the high ones came too easily)
	PartValue: number, -- Coins each part adds to a shipped brainrot (x4 in the pacing pass, 2026-10-06)
	CompletionGems: number, -- Gems for completing in Zone 1 (scaled by each zone's GemMultiplier)
	DuplicateCurrency: string, -- what a duplicate part converts into
	DuplicateValue: number, -- how much of it (Coin duplicates also add some income, see Config/Loot)
}

local Rarities = {}

Rarities.List = {
	{
		Id = "Common",
		Rank = 0,
		Color = Color3.fromRGB(200, 205, 210),
		LootWeight = 65,
		PartValue = 20,
		CompletionGems = 10,
		DuplicateCurrency = "Coins",
		DuplicateValue = 100,
	},
	{
		Id = "Uncommon",
		Rank = 0,
		Color = Color3.fromRGB(91, 227, 91),
		LootWeight = 26,
		PartValue = 48,
		CompletionGems = 25,
		DuplicateCurrency = "Coins",
		DuplicateValue = 250,
	},
	{
		Id = "Rare",
		Rank = 0,
		Color = Color3.fromRGB(61, 165, 255),
		LootWeight = 6.5,
		PartValue = 120,
		CompletionGems = 60,
		DuplicateCurrency = "Coins",
		DuplicateValue = 600,
	},
	{
		Id = "Legendary",
		Rank = 0,
		Color = Color3.fromRGB(255, 197, 61),
		LootWeight = 2,
		PartValue = 400,
		CompletionGems = 150,
		DuplicateCurrency = "Gems",
		DuplicateValue = 30,
	},
	{
		Id = "Mythic",
		Rank = 0,
		Color = Color3.fromRGB(255, 79, 216),
		LootWeight = 0.4,
		PartValue = 1400,
		CompletionGems = 400,
		DuplicateCurrency = "Gems",
		DuplicateValue = 80,
	},
	{
		Id = "Godly",
		Rank = 0,
		Color = Color3.fromRGB(255, 255, 255), -- shown as an animated rainbow in UI
		LootWeight = 0.06,
		PartValue = 6000,
		CompletionGems = 1000,
		DuplicateCurrency = "Gems",
		DuplicateValue = 250,
	},
} :: { Rarity }

Rarities.ById = {} :: { [string]: Rarity }
for rank, rarity in Rarities.List do
	rarity.Rank = rank
	Rarities.ById[rarity.Id] = rarity
end

return Rarities
