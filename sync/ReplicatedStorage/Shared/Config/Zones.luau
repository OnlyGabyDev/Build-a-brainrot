--[[
	Factory zones, in unlock order (GDD §10). Each zone builds brainrots in its own
	edition (size + style) on its own assembly lines. Completions are tracked per zone.

	`Available = false` zones are designed but not built yet (no tycoon items/geometry).
	The first run (before any rebirth) holds every room up to the Candy Factory, each
	opened with Coins at its door (UnlockPrice); the Candy Factory needs a rebirth and its
	floor (the user, 2026-10-02).
	Economy (the economy pass, 2026-10-02): each room earns and costs 15 times the one
	before (ValueMultiplier = PriceMultiplier), so a new room is always worth opening
	however far the old ones are upgraded, and its buttons pay back like the first
	room's. Tuned with a greedy-buyer simulation (tools/economy_sim.py) for ~5 h of play
	to the first rebirth (~4.1 h for a perfect player). The later zones follow the same
	rule until their content is built.
	Style: Scale multiplies model size (big enough that the player's brainrot is the star of
	its line, not a speck in the machines); Material/Reflectance/Transparency override the
	brainrot's look when set (nil keeps the model's own look).
]]

export type Style = {
	Scale: number,
	Material: Enum.Material?,
	MaterialVariant: string?, -- a MaterialVariant in MaterialService (lives in the place file, see tools/SetupMaterials)
	Reflectance: number?,
	Transparency: number?,
}

export type Zone = {
	Id: string,
	Index: number, -- filled in below
	Name: string,
	Edition: string,
	UnlockRebirths: number,
	UnlockPrice: number?, -- Coins to open its room once the rebirths are met (a button at its door); nil: it opens by itself
	ValueMultiplier: number, -- × ship value
	PriceMultiplier: number, -- × tycoon item prices
	GemMultiplier: number, -- × completion Gems
	LineCount: number,
	Style: Style,
	SpecialStation: string?, -- the zone's own last upgrade on each line (GDD §6)
	StationNames: { [string]: string }?, -- its own names for the upgrade stations (by key)
	Available: boolean,
}

local Zones = {}

Zones.List = {
	{
		Id = "ToyWorkshop",
		Index = 0,
		Name = "Toy Workshop",
		Edition = "Toy",
		UnlockRebirths = 0,
		ValueMultiplier = 1,
		PriceMultiplier = 1,
		GemMultiplier = 1,
		LineCount = 3,
		Style = { Scale = 1.15 },
		SpecialStation = "Toy Packer",
		Available = true,
	},
	{
		Id = "PlushieRoom",
		Index = 0,
		Name = "Plushie Sewing Room",
		Edition = "Plushie",
		UnlockRebirths = 0,
		UnlockPrice = 25000,
		ValueMultiplier = 15,
		PriceMultiplier = 15,
		GemMultiplier = 1.5,
		LineCount = 3,
		Style = { Scale = 1.25, Material = Enum.Material.Fabric, MaterialVariant = "PlushKnit" },
		SpecialStation = "Bow Tier",
		StationNames = { Station1 = "Dye Bath", Station2 = "Sequin Shower" },
		Available = true,
	},
	{
		Id = "ClayStudio",
		Index = 0,
		Name = "Clay Studio",
		Edition = "Clay",
		UnlockRebirths = 0,
		UnlockPrice = 80000000, -- (opening it builds the factory's 2nd floor: TycoonItems.StoreyItems)
		ValueMultiplier = 225,
		PriceMultiplier = 225,
		GemMultiplier = 2,
		LineCount = 3,
		Style = { Scale = 1.3, Material = Enum.Material.Plaster, MaterialVariant = "PlayDough" },
		SpecialStation = "Stop-Motion Camera",
		StationNames = { Station1 = "Color Squish", Station2 = "Sparkle Glaze" },
		Available = true,
	},
	{
		Id = "VinylCollectibles",
		Index = 0,
		Name = "Vinyl Collectibles",
		Edition = "Collectible",
		UnlockRebirths = 0,
		UnlockPrice = 4000000000,
		ValueMultiplier = 3375,
		PriceMultiplier = 3375,
		GemMultiplier = 3,
		LineCount = 3,
		Style = { Scale = 1.4, Material = Enum.Material.SmoothPlastic, MaterialVariant = "VinylGloss" },
		SpecialStation = "Holo Sticker",
		StationNames = { Station1 = "Gloss Coat", Station2 = "Gold Leaf" },
		Available = true,
	},
	{
		Id = "CandyFactory",
		Index = 0,
		Name = "Candy Factory",
		Edition = "Candy",
		UnlockRebirths = 1, -- and its floor bought (TycoonItems.Floors)
		ValueMultiplier = 50625,
		PriceMultiplier = 50625,
		GemMultiplier = 4.5,
		LineCount = 3,
		Style = { Scale = 1.5, Material = Enum.Material.Glass, Transparency = 0.2 },
		Available = false,
	},
	{
		Id = "RobotPlant",
		Index = 0,
		Name = "Robot Plant",
		Edition = "Animatronic",
		UnlockRebirths = 2,
		ValueMultiplier = 759375,
		PriceMultiplier = 759375,
		GemMultiplier = 6.5,
		LineCount = 3,
		Style = { Scale = 1.7, Material = Enum.Material.DiamondPlate },
		Available = false,
	},
	{
		Id = "MadScienceLab",
		Index = 0,
		Name = "Mad Science Lab",
		Edition = "Living",
		UnlockRebirths = 3,
		ValueMultiplier = 11390625,
		PriceMultiplier = 11390625,
		GemMultiplier = 10,
		LineCount = 3,
		Style = { Scale = 2 },
		Available = false,
	},
	{
		Id = "SecretBunker",
		Index = 0,
		Name = "Secret Bunker",
		Edition = "Clone",
		UnlockRebirths = 4,
		ValueMultiplier = 170859375,
		PriceMultiplier = 170859375,
		GemMultiplier = 15,
		LineCount = 3,
		Style = { Scale = 2, Material = Enum.Material.ForceField },
		Available = false,
	},
	{
		Id = "TitanFoundry",
		Index = 0,
		Name = "Titan Foundry",
		Edition = "Giant",
		UnlockRebirths = 6,
		ValueMultiplier = 2562890625,
		PriceMultiplier = 2562890625,
		GemMultiplier = 22,
		LineCount = 3,
		Style = { Scale = 3, Material = Enum.Material.Metal },
		Available = false,
	},
	{
		Id = "OrbitalForge",
		Index = 0,
		Name = "Orbital Forge",
		Edition = "Cosmic",
		UnlockRebirths = 8,
		ValueMultiplier = 38443359375,
		PriceMultiplier = 38443359375,
		GemMultiplier = 33,
		LineCount = 3,
		Style = { Scale = 3.5, Material = Enum.Material.Glass },
		Available = false,
	},
} :: { Zone }

Zones.ById = {} :: { [string]: Zone }
for index, zone in Zones.List do
	zone.Index = index
	Zones.ById[zone.Id] = zone
end

-- A room's short name for buttons and tabs, its name's first word: "TOY", "PLUSHIE".
function Zones.Tag(zoneId: string): string
	local zone = Zones.ById[zoneId]
	local name = if zone then zone.Name else zoneId
	return string.upper(string.match(name, "^%S+") or name)
end

return Zones
