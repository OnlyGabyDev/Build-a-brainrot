-- Loot boxes and Rolls tuning (GDD §5). Placeholders to tune in playtests.

local Brainrots = require(script.Parent.Brainrots)
local Rarities = require(script.Parent.Rarities)

local Loot = {
	-- Map loot boxes are shared: anyone can grab any box, first come first served.
	BaseBoxes = 10, -- boxes on the map with one player...
	BoxesPerPlayer = 3, -- ...plus this many per extra player
	MaxBoxes = 30,
	RespawnTime = NumberRange.new(10, 20), -- seconds before an opened box is replaced
	-- Studs from the hub: the plaza, the bridges and the valley up to the factories'
	-- entrances (at ~240). MapBuilder.FindSpot keeps them on dry, clear ground.
	SpawnRadius = NumberRange.new(30, 225),
	OpenDistance = 14, -- studs; the server's reach check (the client opens at ~6)
	AnnounceRank = 3, -- boxes of this rarity rank and up (Rare+) are announced to everyone

	-- A box mostly gives parts of its own rarity; each tier above it is this much as
	-- likely as the one below (Common box: ~87% Common, ~13% Uncommon, ~2% Rare...).
	BoxUpgradeChance = 0.15,

	-- Coin duplicates also pay this many seconds of the player's current income, so
	-- they stay worth something as the factory grows.
	DuplicateIncomeSeconds = 15,

	-- Bought box drops (Config/Products, Kind "BoxDrop"): they rain onto the map round
	-- the buyer, one every `Interval` seconds, on top of the map's own boxes (they don't
	-- count toward MaxBoxes and aren't replaced when opened). Each rolls its rarity like a
	-- Roll with `Luck` extra luck, from the rarities the buyer has unlocked, so the buyer
	-- can open every one. For `ReservedSeconds` only the buyer can (long enough to walk
	-- round a 100-box storm: they paid for it), then they're anyone's, and at once if
	-- the buyer leaves. At most `MaxBought` are out at once; the rest wait their turn.
	Drops = {
		Luck = 1,
		Interval = 0.12, -- seconds between boxes (100 rain down in 12 s)
		Spread = 45, -- studs round the buyer
		ReservedSeconds = 120,
		MaxBought = 120,
	},
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

local function total(odds: Odds): number
	local sum = 0
	for _, weight in odds do
		sum += weight
	end
	return sum
end

-- The chance of each rarity for the part one box of a bought drop gives (0..1; what
-- the shop shows before purchase): the box's rarity rolls like a Roll with the drop's
-- extra luck (Drops.Luck), then opening it may upgrade it like any box (BoxOdds).
-- `luck` is the buyer's own (they open their boxes).
function Loot.DropPartOdds(rebirths: number, luck: number): Odds
	local boxOdds = Loot.RollOdds(rebirths, luck + Loot.Drops.Luck)
	local boxTotal = total(boxOdds)
	local chances: Odds = {}
	for boxRarity, weight in boxOdds do
		local partOdds = Loot.BoxOdds(boxRarity, rebirths, luck)
		local partTotal = total(partOdds)
		for rarity, partWeight in partOdds do
			chances[rarity] = (chances[rarity] or 0) + weight / boxTotal * partWeight / partTotal
		end
	end
	return chances
end

return Loot
