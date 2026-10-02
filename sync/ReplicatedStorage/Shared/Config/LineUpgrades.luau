--[[
	Line upgrades (GDD §6): four leveled tracks every line can buy from its tablet (the
	Line menu's UPGRADES tab), besides the floor buttons. Each level is stronger than the
	last and looks better on the line (TycoonManager builds the highest level's look:
	neon halos on the droppers, chasing lights on the belt, bulbs and stars on the
	stations, a ring of lights round the delivery; gold at the top tiers).

	Every level is a tycoon item (TycoonItems: Kind "Track", "{lineId}_Up{Track}_{Level}"),
	so they save, reset on rebirth and pay out like the rest. Prices are × the line's
	price scale and the zone's PriceMultiplier. Placeholders to tune.
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
		Icon = "🔩",
		Effect = "Speed",
		Step = 0.05, -- speed tracks stay gentle: a fast line hurries the assembly show
		BasePrice = 300,
		Growth = 1.75,
		Levels = 10,
		Gate = "Legs",
		Colors = { Color3.fromRGB(255, 150, 210), Color3.fromRGB(235, 80, 160) },
	},
	{
		Key = "Belt",
		Name = "Belt Boost",
		Icon = "⚡",
		Effect = "Speed",
		Step = 0.03,
		BasePrice = 250,
		Growth = 1.7,
		Levels = 10,
		Gate = "Speed1",
		Colors = { Color3.fromRGB(130, 230, 255), Color3.fromRGB(50, 160, 245) },
	},
	{
		Key = "Upgraders",
		Name = "Super Upgraders",
		Icon = "✨",
		Effect = "Flat",
		Step = 6,
		BasePrice = 400,
		Growth = 1.75,
		Levels = 10,
		Gate = "Station1",
		Colors = { Color3.fromRGB(200, 160, 255), Color3.fromRGB(130, 80, 235) },
	},
	{
		Key = "Shipping",
		Name = "Premium Shipping",
		Icon = "📦",
		Effect = "Percent",
		Step = 0.1,
		BasePrice = 500,
		Growth = 1.8,
		Levels = 10,
		Gate = "Legs",
		Colors = { Color3.fromRGB(255, 225, 90), Color3.fromRGB(255, 160, 30) },
	},
} :: { Track }

LineUpgrades.ByKey = {} :: { [string]: Track }
for _, track in LineUpgrades.Tracks do
	LineUpgrades.ByKey[track.Key] = track
end

-- What `level` of `track` gives in all: "+24% speed", "+18 base 💰 per brainrot",
-- "+30% sale value".
function LineUpgrades.Describe(track: Track, level: number): string
	if track.Effect == "Flat" then
		return `+{track.Step * level} base 💰 per brainrot`
	end
	local percent = math.floor(track.Step * level * 100 + 0.5)
	return if track.Effect == "Speed" then `+{percent}% speed` else `+{percent}% sale value`
end

-- A level's price before the line and zone scales, rounded to two significant digits.
function LineUpgrades.BasePrice(track: Track, level: number): number
	local price = track.BasePrice * track.Growth ^ (level - 1)
	local unit = 10 ^ math.max(math.floor(math.log10(price)) - 1, 0)
	return math.floor(price / unit + 0.5) * unit
end

return LineUpgrades
