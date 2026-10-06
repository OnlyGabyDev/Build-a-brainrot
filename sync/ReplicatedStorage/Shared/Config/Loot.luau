-- Loot boxes and Rolls tuning (GDD §5). Placeholders to tune in playtests.

local Brainrots = require(script.Parent.Brainrots)
local Rarities = require(script.Parent.Rarities)

local Loot = {
	-- Map loot boxes are shared: anyone can grab any box, first come first served.
	BaseBoxes = 18, -- boxes on the map with one player...
	BoxesPerPlayer = 6, -- ...plus this many per extra player
	MaxBoxes = 50,
	RespawnTime = NumberRange.new(10, 20), -- seconds before an opened box is replaced
	-- Boxes land all over the map, so players without fast gadgets find some too:
	-- `HomeShare` of them round a random player's front yard (`HomeOffset` studs past
	-- their factory lot's front, within `HomeSpread`), the rest anywhere `SpawnRadius`
	-- studs from the hub (the plaza to the ponds; factories sit at 300, mountains at
	-- 900). MapBuilder.FindSpot keeps them on dry, clear ground, never on a factory lot.
	SpawnRadius = NumberRange.new(40, 600),
	HomeShare = 0.5,
	HomeOffset = 40,
	HomeSpread = 130,
	OpenDistance = 14, -- studs; the server's reach check (the client opens at ~6)
	AnnounceRank = 3, -- boxes of this rarity rank and up (Rare+) are announced to everyone

	-- A box mostly gives parts of its own rarity; each tier above it is this much as
	-- likely as the one below (Common box: ~93% Common, ~7% Uncommon, ~0.6% Rare...).
	-- Luck raises it by BoxLuck per point (luck 1: x1.5).
	BoxUpgradeChance = 0.08,
	BoxLuck = 0.5,
	-- Luck (rebirths, the Rebirth Shop, the Lucky pass, the Daily Wheel's boost, bought drops) gives each
	-- rarity above Common this much more weight per point of luck per rank (luck 1: Rare
	-- x1.5, Legendary x1.75, Godly x2.25). Was 1 per rank: full luck made Legendary 3x as
	-- likely and a Godly map box 1 in 48 (2026-10-03, nerfed with the LootWeights).
	LuckPerRank = 0.25,

	-- A newcomer's first Rolls (the 3 starter ones) and first box always give a part they
	-- don't have yet (of the rolled rarity, while any is left).
	SureNew = { Roll = 3, Box = 1 },

	-- Coin duplicates also pay this many seconds of the player's current income, so
	-- they stay worth something as the factory grows.
	DuplicateIncomeSeconds = 15,

	-- Bought box drops (Config/Products, Kind "BoxDrop"): they rain onto the map round
	-- the buyer, one every `Interval` seconds, on top of the map's own boxes (they don't
	-- count toward MaxBoxes and aren't replaced when opened). Each rolls its rarity like a
	-- Roll with `Luck` extra luck on top of the buyer's. For `ReservedSeconds` only the buyer can (long enough to walk
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

-- Every rarity drops from the start (no rebirth cap), as long as it has brainrots.
local function droppable(rarity: Rarities.Rarity): boolean
	return #Brainrots.ByRarity[rarity.Id] > 0
end

-- A Roll: every rarity at its base loot weight (GDD §4). `luck` (rebirths, the Rebirth
-- Shop, passes) gives each tier above Common that much more weight per rank.
function Loot.RollOdds(luck: number?): Odds
	local odds = {}
	for _, rarity in Rarities.List do
		if droppable(rarity) then
			odds[rarity.Id] = rarity.LootWeight * (1 + (luck or 0) * Loot.LuckPerRank * (rarity.Rank - 1))
		end
	end
	return odds
end

-- A box of `boxRarity`: its own rarity most of the time, rarer ones less and less
-- often; `luck` boosts the upgrades.
function Loot.BoxOdds(boxRarity: string, luck: number?): Odds
	local odds = {}
	local weight = 1
	local upgrade = Loot.BoxUpgradeChance * (1 + (luck or 0) * Loot.BoxLuck)
	for rank = Rarities.ById[boxRarity].Rank, #Rarities.List do
		local rarity = Rarities.List[rank]
		if droppable(rarity) then
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
function Loot.DropPartOdds(luck: number): Odds
	local boxOdds = Loot.RollOdds(luck + Loot.Drops.Luck)
	local boxTotal = total(boxOdds)
	local chances: Odds = {}
	for boxRarity, weight in boxOdds do
		local partOdds = Loot.BoxOdds(boxRarity, luck)
		local partTotal = total(partOdds)
		for rarity, partWeight in partOdds do
			chances[rarity] = (chances[rarity] or 0) + weight / boxTotal * partWeight / partTotal
		end
	end
	return chances
end

return Loot
