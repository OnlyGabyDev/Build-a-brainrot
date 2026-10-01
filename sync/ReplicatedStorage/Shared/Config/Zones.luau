--[[
	Factory zones, in unlock order (GDD §10). Each zone builds brainrots in its own
	edition (size + style) on its own assembly lines. Completions are tracked per zone.

	`Available = false` zones are designed but not built yet (no tycoon items/geometry).
	Style: Scale multiplies model size; Material/Reflectance/Transparency override the
	brainrot's look when set (nil keeps the model's own look).
]]

export type Style = {
	Scale: number,
	Material: Enum.Material?,
	Reflectance: number?,
	Transparency: number?,
}

export type Zone = {
	Id: string,
	Index: number, -- filled in below
	Name: string,
	Edition: string,
	UnlockRebirths: number,
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
		Style = { Scale = 0.7 },
		SpecialStation = "Toy Packer",
		Available = true,
	},
	{
		Id = "PlushieRoom",
		Index = 0,
		Name = "Plushie Sewing Room",
		Edition = "Plushie",
		UnlockRebirths = 2,
		ValueMultiplier = 2,
		PriceMultiplier = 3,
		GemMultiplier = 1.5,
		LineCount = 3,
		Style = { Scale = 0.8, Material = Enum.Material.Fabric },
		SpecialStation = "Bow Tier",
		StationNames = { Station1 = "Dye Bath", Station2 = "Sequin Shower" },
		Available = true,
	},
	{
		Id = "ClayStudio",
		Index = 0,
		Name = "Clay Studio",
		Edition = "Clay",
		UnlockRebirths = 4,
		ValueMultiplier = 3.5,
		PriceMultiplier = 8,
		GemMultiplier = 2,
		LineCount = 3,
		Style = { Scale = 0.85, Material = Enum.Material.Sand },
		Available = false,
	},
	{
		Id = "VinylCollectibles",
		Index = 0,
		Name = "Vinyl Collectibles",
		Edition = "Collectible",
		UnlockRebirths = 6,
		ValueMultiplier = 6,
		PriceMultiplier = 20,
		GemMultiplier = 3,
		LineCount = 3,
		Style = { Scale = 1, Material = Enum.Material.SmoothPlastic, Reflectance = 0.25 },
		Available = false,
	},
	{
		Id = "CandyFactory",
		Index = 0,
		Name = "Candy Factory",
		Edition = "Candy",
		UnlockRebirths = 9,
		ValueMultiplier = 10,
		PriceMultiplier = 50,
		GemMultiplier = 4.5,
		LineCount = 3,
		Style = { Scale = 1.1, Material = Enum.Material.Glass, Transparency = 0.2 },
		Available = false,
	},
	{
		Id = "RobotPlant",
		Index = 0,
		Name = "Robot Plant",
		Edition = "Animatronic",
		UnlockRebirths = 12,
		ValueMultiplier = 17,
		PriceMultiplier = 120,
		GemMultiplier = 6.5,
		LineCount = 3,
		Style = { Scale = 1.3, Material = Enum.Material.DiamondPlate },
		Available = false,
	},
	{
		Id = "MadScienceLab",
		Index = 0,
		Name = "Mad Science Lab",
		Edition = "Living",
		UnlockRebirths = 16,
		ValueMultiplier = 30,
		PriceMultiplier = 300,
		GemMultiplier = 10,
		LineCount = 3,
		Style = { Scale = 1.6 },
		Available = false,
	},
	{
		Id = "SecretBunker",
		Index = 0,
		Name = "Secret Bunker",
		Edition = "Clone",
		UnlockRebirths = 20,
		ValueMultiplier = 50,
		PriceMultiplier = 700,
		GemMultiplier = 15,
		LineCount = 3,
		Style = { Scale = 1.6, Material = Enum.Material.ForceField },
		Available = false,
	},
	{
		Id = "TitanFoundry",
		Index = 0,
		Name = "Titan Foundry",
		Edition = "Giant",
		UnlockRebirths = 25,
		ValueMultiplier = 85,
		PriceMultiplier = 1500,
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
		UnlockRebirths = 30,
		ValueMultiplier = 150,
		PriceMultiplier = 3500,
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

return Zones
