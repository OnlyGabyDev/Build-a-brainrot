--[[
	The brainrot roster (GDD §3). Every brainrot has the same 4 parts.
	`Color` tints the placeholder blocks until a split model exists in
	ReplicatedStorage/Assets/Brainrots/<Id>.
]]

local Rarities = require(script.Parent.Rarities)

export type Brainrot = {
	Id: string,
	Name: string,
	Rarity: string,
	Color: Color3,
}

local Brainrots = {}

Brainrots.PartTypes = table.freeze({ "Head", "Body", "Arms", "Legs" })

-- New players own all 4 parts of this one, so their first line can run a full match.
Brainrots.StarterId = "TralaleroTralala"

Brainrots.List = {
	-- Common
	{ Id = "TralaleroTralala", Name = "Tralalero Tralala", Rarity = "Common", Color = Color3.fromRGB(80, 150, 230) },
	{ Id = "BrrBrrPatapim", Name = "Brr Brr Patapim", Rarity = "Common", Color = Color3.fromRGB(110, 170, 70) },
	{ Id = "LiriliLarila", Name = "Lirilì Larilà", Rarity = "Common", Color = Color3.fromRGB(150, 200, 90) },
	{ Id = "TrippiTroppi", Name = "Trippi Troppi", Rarity = "Common", Color = Color3.fromRGB(240, 150, 90) },

	-- Uncommon
	{ Id = "BallerinaCappuccina", Name = "Ballerina Cappuccina", Rarity = "Uncommon", Color = Color3.fromRGB(255, 170, 200) },
	{ Id = "ChimpanziniBananini", Name = "Chimpanzini Bananini", Rarity = "Uncommon", Color = Color3.fromRGB(255, 220, 60) },
	{ Id = "BonecaAmbalabu", Name = "Boneca Ambalabu", Rarity = "Uncommon", Color = Color3.fromRGB(170, 120, 90) },

	-- Rare
	{ Id = "CappuccinoAssassino", Name = "Cappuccino Assassino", Rarity = "Rare", Color = Color3.fromRGB(120, 80, 60) },
	{ Id = "BombombiniGusini", Name = "Bombombini Gusini", Rarity = "Rare", Color = Color3.fromRGB(235, 235, 235) },
	{ Id = "FrigoCamelo", Name = "Frigo Camelo", Rarity = "Rare", Color = Color3.fromRGB(200, 170, 110) },

	-- Legendary
	{ Id = "TungTungTungSahur", Name = "Tung Tung Tung Sahur", Rarity = "Legendary", Color = Color3.fromRGB(190, 140, 90) },
	{ Id = "GlorboFruttodrillo", Name = "Glorbo Fruttodrillo", Rarity = "Legendary", Color = Color3.fromRGB(90, 190, 110) },

	-- Mythic
	{ Id = "BombardiroCrocodilo", Name = "Bombardiro Crocodilo", Rarity = "Mythic", Color = Color3.fromRGB(70, 120, 60) },
	{ Id = "LaVacaSaturnoSaturnita", Name = "La Vaca Saturno Saturnita", Rarity = "Mythic", Color = Color3.fromRGB(140, 110, 220) },

	-- Godly (placeholder for our own original signature brainrot)
	{ Id = "SupremoBrainrotto", Name = "Supremo Brainrotto", Rarity = "Godly", Color = Color3.fromRGB(255, 90, 90) },
} :: { Brainrot }

Brainrots.ById = {} :: { [string]: Brainrot }
Brainrots.ByRarity = {} :: { [string]: { Brainrot } }

for _, rarity in Rarities.List do
	Brainrots.ByRarity[rarity.Id] = {}
end
for _, brainrot in Brainrots.List do
	assert(Rarities.ById[brainrot.Rarity], `Brainrot {brainrot.Id} has unknown rarity {brainrot.Rarity}`)
	assert(not Brainrots.ById[brainrot.Id], `Duplicate brainrot id {brainrot.Id}`)
	Brainrots.ById[brainrot.Id] = brainrot
	table.insert(Brainrots.ByRarity[brainrot.Rarity], brainrot)
end
assert(Brainrots.ById[Brainrots.StarterId], "StarterId must be in the roster")

return Brainrots
