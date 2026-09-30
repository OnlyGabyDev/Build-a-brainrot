-- Loot boxes and Rolls tuning (GDD §5). Placeholders to tune in playtests.

local Brainrots = require(script.Parent.Brainrots)
local Rarities = require(script.Parent.Rarities)

local Loot = {
	-- Map loot boxes are shared: anyone can grab any box, first come first served.
	BaseBoxes = 6, -- boxes on the map with one player...
	BoxesPerPlayer = 2, -- ...plus this many per extra player
	MaxBoxes = 20,
	RespawnTime = NumberRange.new(10, 20), -- seconds before an opened box is replaced
	SpawnRadius = NumberRange.new(30, 135), -- studs from the hub (plots start at ~150)
	OpenDistance = 14, -- studs; the server's reach check (the client opens at ~6)
	AnnounceRank = 3, -- boxes of this rarity rank and up (Rare+) are announced to everyone

	-- A box mostly gives parts of its own rarity; each tier above it is this much as
	-- likely as the one below (Common box: ~87% Common, ~13% Uncommon, ~2% Rare...).
	BoxUpgradeChance = 0.15,

	-- Coin duplicates also pay this many seconds of the player's current income, so
	-- they stay worth something as the factory grows.
	DuplicateIncomeSeconds = 15,
}

export type Odds = { [string]: number } -- [rarityId] = relative weight

local function droppable(rarity: Rarities.Rarity, rebirths: number): boolean
	return rebirths >= rarity.UnlockRebirths and #Brainrots.ByRarity[rarity.Id] > 0
end

-- A Roll: every rarity unlocked at `rebirths`, at its base loot weight (GDD §4).
-- `luck` (Rebirth Shop) gives each tier above Common that much more weight per rank.
function Loot.RollOdds(rebirths: number, luck: number?): Odds
	local odds = {}
	for _, rarity in Rarities.List do
		if droppable(rarity, rebirths) then
			odds[rarity.Id] = rarity.LootWeight * (1 + (luck or 0) * (rarity.Rank - 1))
		end
	end
	return odds
end

-- A box of `boxRarity`: its own rarity most of the time, rarer ones less and less
-- often. Only rarities unlocked at `rebirths` can drop; `luck` boosts the upgrades.
function Loot.BoxOdds(boxRarity: string, rebirths: number, luck: number?): Odds
	local odds = {}
	local weight = 1
	local upgrade = Loot.BoxUpgradeChance * (1 + (luck or 0))
	for rank = Rarities.ById[boxRarity].Rank, #Rarities.List do
		local rarity = Rarities.List[rank]
		if droppable(rarity, rebirths) then
			odds[rarity.Id] = weight
		end
		weight *= upgrade
	end
	return odds
end

return Loot
