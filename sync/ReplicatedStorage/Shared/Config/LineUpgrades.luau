--[[
	Line upgrades (GDD §6): four leveled tracks every line can buy from its tablet (the
	Line menu's UPGRADES tab), besides the floor buttons. Each level is stronger than the
	last and looks better on the line (TycoonManager builds the highest level's look:
	neon halos on the droppers, chasing lights on the belt, bulbs and stars on the
	stations, a ring of lights round the delivery; gold at the top tiers).

	Every level is a tycoon item (TycoonItems: Kind "Track", "{lineId}_Up{Track}_{Level}"),
	so they save, reset on rebirth and pay out like the rest. Prices are × the line's
	price scale and the zone's PriceMultiplier. v5.6 (the economy study): each level costs
	1.35x the last (was 1.7-1.8x) and the value tracks are gentler, so a run's buttons get
	bought before its rebirth and the numbers stay small (tools/economy_sim.py).
]]

export type Track = {
	Key: string,
	Name: string,
	Icon: string,
	-- "Speed": the line cycles (1 + Step × level) times as fast; "Flat": every brainrot
	-- is worth Step × level more base Coins (before every multiplier); "Percent": every
	-- brainrot sells for (1 + Step × level) times as much.
	Effect: string,
	Step: number,
	BasePrice: number,
	Growth: number, -- each level costs this many times the one before
	Levels: number,
	Gate: string, -- the line's floor item (by key) to buy before the first level
	Colors: { Color3 }, -- its card's gradient in the Line menu
}

local LineUpgrades = {}

LineUpgrades.Tracks = {
	{
		Key = "Droppers",
		Name = "Dropper Power",
		Icon = "Nut",
		Effect = "Speed",
		Step = 0.05, -- speed tracks stay gentle: a fast line hurries the assembly show
		BasePrice = 600,
		Growth = 1.35,
		Levels = 10,
		Gate = "Legs",
		Colors = { Color3.fromRGB(255, 150, 210), Color3.fromRGB(235, 80, 160) },
	},
	{
		Key = "Belt",
		Name = "Belt Boost",
		Icon = "Lightning",
		Effect = "Speed",
		Step = 0.03,
		BasePrice = 500,
		Growth = 1.35,
		Levels = 10,
		Gate = "Speed1",
		Colors = { Color3.fromRGB(130, 230, 255), Color3.fromRGB(50, 160, 245) },
	},
	{
		Key = "Upgraders",
		Name = "Super Upgraders",
		Icon = "Sparkle",
		Effect = "Flat",
		Step = 4, -- a Common part is worth 20 (was 24: v5.6, the economy study)
		BasePrice = 800,
		Growth = 1.35,
		Levels = 10,
		Gate = "Station1",
		Colors = { Color3.fromRGB(200, 160, 255), Color3.fromRGB(130, 80, 235) },
	},
	{
		Key = "Shipping",
		Name = "Premium Shipping",
		Icon = "Gift",
		Effect = "Percent",
		Step = 0.05,
		BasePrice = 1000,
		Growth = 1.35,
		Levels = 10,
		Gate = "Legs",
		Colors = { Color3.fromRGB(255, 225, 90), Color3.fromRGB(255, 160, 30) },
	},
} :: { Track }

LineUpgrades.ByKey = {} :: { [string]: Track }
for _, track in LineUpgrades.Tracks do
	LineUpgrades.ByKey[track.Key] = track
end

-- How much `level` of `track` gives in all, as a big number: "+24%", "+18".
function LineUpgrades.Amount(track: Track, level: number): string
	if track.Effect == "Flat" then
		return `+{track.Step * level}`
	end
	return `+{math.floor(track.Step * level * 100 + 0.5)}%`
end

-- What a track's amount is of: "speed", "base 💰 per brainrot", "sale value".
function LineUpgrades.Unit(track: Track): string
	return if track.Effect == "Flat" then "base Coins per brainrot" elseif track.Effect == "Speed" then "speed" else "sale value"
end

-- What `level` of `track` gives in all: "+24% speed", "+18 base Coins per brainrot",
-- "+30% sale value".
function LineUpgrades.Describe(track: Track, level: number): string
	return `{LineUpgrades.Amount(track, level)} {LineUpgrades.Unit(track)}`
end

-- The look tiers every track climbs on the line (TycoonManager's track looks): the
-- tier of `level` (1-4) and, for the level each tier starts at, what it brings.
LineUpgrades.TierStarts = { [4] = "HOT PINK + GOLD", [7] = "GOLD + SPARKLES", [10] = "CHASING LIGHTS" } :: { [number]: string }

function LineUpgrades.Tier(level: number): number
	return if level >= 10 then 4 elseif level >= 7 then 3 elseif level >= 4 then 2 else 1
end

-- A level's price before the line and zone scales, rounded to two significant digits.
function LineUpgrades.BasePrice(track: Track, level: number): number
	local price = track.BasePrice * track.Growth ^ (level - 1)
	local unit = 10 ^ math.max(math.floor(math.log10(price)) - 1, 0)
	return math.floor(price / unit + 0.5) * unit
end

return LineUpgrades
