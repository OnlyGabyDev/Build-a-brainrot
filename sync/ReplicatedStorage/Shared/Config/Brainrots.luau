--[[
	The brainrot roster (GDD §3). Every brainrot has the same 4 parts. Real memes only:
	each one comes from its creator's original post (the 2025 "Italian brainrot" wave on
	TikTok), never one a game made up; our block art follows that original image.
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
	{ Id = "TimCheese", Name = "Tim Cheese", Rarity = "Common", Color = Color3.fromRGB(150, 150, 160) },
	{ Id = "TaTaTaTaSahur", Name = "Ta Ta Ta Ta Sahur", Rarity = "Common", Color = Color3.fromRGB(176, 82, 56) },
	{ Id = "TricTracBaraboom", Name = "Tric Trac Baraboom", Rarity = "Common", Color = Color3.fromRGB(104, 150, 84) },
	{ Id = "Fluriflura", Name = "Fluriflura", Rarity = "Common", Color = Color3.fromRGB(250, 140, 40) },
	{ Id = "TalpaDiFero", Name = "Talpa Di Fero", Rarity = "Common", Color = Color3.fromRGB(150, 154, 162) },
	{ Id = "SvininaBombardino", Name = "Svinina Bombardino", Rarity = "Common", Color = Color3.fromRGB(240, 160, 160) },
	{ Id = "CactoHipopotamo", Name = "Cacto Hipopotamo", Rarity = "Common", Color = Color3.fromRGB(86, 156, 74) },
	{ Id = "BambiniCrostini", Name = "Bambini Crostini", Rarity = "Common", Color = Color3.fromRGB(230, 156, 62) },
	{ Id = "PandacciniBananini", Name = "Pandaccini Bananini", Rarity = "Common", Color = Color3.fromRGB(250, 214, 52) },
	{ Id = "TigroligreFrutonni", Name = "Tigroligre Frutonni", Rarity = "Common", Color = Color3.fromRGB(240, 140, 40) },
	{ Id = "AvocadiniGuffo", Name = "Avocadini Guffo", Rarity = "Common", Color = Color3.fromRGB(96, 156, 56) },
	{ Id = "PeachiFoxilini", Name = "Peachi Foxilini", Rarity = "Common", Color = Color3.fromRGB(244, 150, 120) },
	{ Id = "SalaminoPenguino", Name = "Salamino Penguino", Rarity = "Common", Color = Color3.fromRGB(186, 44, 48) },

	-- Uncommon
	{ Id = "BallerinaCappuccina", Name = "Ballerina Cappuccina", Rarity = "Uncommon", Color = Color3.fromRGB(255, 170, 200) },
	{ Id = "ChimpanziniBananini", Name = "Chimpanzini Bananini", Rarity = "Uncommon", Color = Color3.fromRGB(255, 220, 60) },
	{ Id = "BonecaAmbalabu", Name = "Boneca Ambalabu", Rarity = "Uncommon", Color = Color3.fromRGB(170, 120, 90) },
	{ Id = "BanditoBobritto", Name = "Bandito Bobritto", Rarity = "Uncommon", Color = Color3.fromRGB(150, 100, 58) },
	{ Id = "TrulimeroTrulicina", Name = "Trulimero Trulicina", Rarity = "Uncommon", Color = Color3.fromRGB(225, 80, 60) },
	{ Id = "BananitaDolphinita", Name = "Bananita Dolphinita", Rarity = "Uncommon", Color = Color3.fromRGB(250, 214, 60) },
	{ Id = "PerochelloLemonchello", Name = "Perochello Lemonchello", Rarity = "Uncommon", Color = Color3.fromRGB(252, 214, 48) },
	{ Id = "MangoliniParrocini", Name = "Mangolini Parrocini", Rarity = "Uncommon", Color = Color3.fromRGB(252, 178, 36) },
	{ Id = "PenguinoCocosino", Name = "Penguino Cocosino", Rarity = "Uncommon", Color = Color3.fromRGB(126, 80, 46) },
	{ Id = "SpioniroGolubiro", Name = "Spioniro Golubiro", Rarity = "Uncommon", Color = Color3.fromRGB(186, 112, 62) },
	{ Id = "LionelCactuseli", Name = "Lionel Cactuseli", Rarity = "Uncommon", Color = Color3.fromRGB(92, 156, 66) },
	{ Id = "DulDulDul", Name = "Dul Dul Dul", Rarity = "Uncommon", Color = Color3.fromRGB(132, 92, 60) },
	{ Id = "Carloo", Name = "Carloo", Rarity = "Uncommon", Color = Color3.fromRGB(104, 124, 74) },

	-- Rare
	{ Id = "CappuccinoAssassino", Name = "Cappuccino Assassino", Rarity = "Rare", Color = Color3.fromRGB(120, 80, 60) },
	{ Id = "BombombiniGusini", Name = "Bombombini Gusini", Rarity = "Rare", Color = Color3.fromRGB(235, 235, 235) },
	{ Id = "FrigoCamelo", Name = "Frigo Camelo", Rarity = "Rare", Color = Color3.fromRGB(200, 170, 110) },
	{ Id = "BurbaloniLoliloli", Name = "Burbaloni Loliloli", Rarity = "Rare", Color = Color3.fromRGB(128, 84, 50) },
	{ Id = "BlueberrinniOctopusini", Name = "Blueberrinni Octopusini", Rarity = "Rare", Color = Color3.fromRGB(96, 116, 210) },
	{ Id = "StrawberrelliFlamingelli", Name = "Strawberrelli Flamingelli", Rarity = "Rare", Color = Color3.fromRGB(222, 40, 56) },
	{ Id = "RhinoToasterino", Name = "Rhino Toasterino", Rarity = "Rare", Color = Color3.fromRGB(206, 212, 222) },
	{ Id = "CavalloVirtuoso", Name = "Cavallo Virtuoso", Rarity = "Rare", Color = Color3.fromRGB(204, 44, 40) },
	{ Id = "CocosiniMama", Name = "Cocosini Mama", Rarity = "Rare", Color = Color3.fromRGB(204, 150, 96) },
	{ Id = "GanganzelliTrulala", Name = "Ganganzelli Trulala", Rarity = "Rare", Color = Color3.fromRGB(244, 132, 28) },
	{ Id = "TirilikalikaTirilikalako", Name = "Tirilikalika Tirilikalako", Rarity = "Rare", Color = Color3.fromRGB(200, 112, 40) },

	-- Legendary
	{ Id = "TungTungTungSahur", Name = "Tung Tung Tung Sahur", Rarity = "Legendary", Color = Color3.fromRGB(190, 140, 90) },
	{ Id = "GlorboFruttodrillo", Name = "Glorbo Fruttodrillo", Rarity = "Legendary", Color = Color3.fromRGB(90, 190, 110) },
	{ Id = "OrangutiniAnanassini", Name = "Orangutini Ananassini", Rarity = "Legendary", Color = Color3.fromRGB(214, 104, 36) },
	{ Id = "ZibraZubraZibralini", Name = "Zibra Zubra Zibralini", Rarity = "Legendary", Color = Color3.fromRGB(70, 150, 70) },
	{ Id = "GorilloWatermelondrillo", Name = "Gorillo Watermelondrillo", Rarity = "Legendary", Color = Color3.fromRGB(40, 40, 46) },
	{ Id = "SixtySeven", Name = "67", Rarity = "Legendary", Color = Color3.fromRGB(238, 122, 38) },
	{ Id = "BallerinoLololo", Name = "Ballerino Lololo", Rarity = "Legendary", Color = Color3.fromRGB(236, 208, 180) },
	{ Id = "PotHotspot", Name = "Pot Hotspot", Rarity = "Legendary", Color = Color3.fromRGB(96, 176, 164) },

	-- Mythic
	{ Id = "BombardiroCrocodilo", Name = "Bombardiro Crocodilo", Rarity = "Mythic", Color = Color3.fromRGB(70, 120, 60) },
	{ Id = "LaVacaSaturnoSaturnita", Name = "La Vaca Saturno Saturnita", Rarity = "Mythic", Color = Color3.fromRGB(140, 110, 220) },
	{ Id = "GirafaCelestre", Name = "Girafa Celestre", Rarity = "Mythic", Color = Color3.fromRGB(234, 64, 70) },
	{ Id = "OrcaleroOrcala", Name = "Orcalero Orcala", Rarity = "Mythic", Color = Color3.fromRGB(32, 34, 42) },
	{ Id = "EspressoSignora", Name = "Espresso Signora", Rarity = "Mythic", Color = Color3.fromRGB(240, 226, 200) },
	{ Id = "TigriliniWatermelini", Name = "Tigrilini Watermelini", Rarity = "Mythic", Color = Color3.fromRGB(118, 178, 70) },

	-- Godly
	{ Id = "DragonCannelloni", Name = "Dragon Cannelloni", Rarity = "Godly", Color = Color3.fromRGB(242, 200, 116) },
	{ Id = "TrenostruzzoTurbo3000", Name = "Trenostruzzo Turbo 3000", Rarity = "Godly", Color = Color3.fromRGB(60, 140, 76) },
	{ Id = "NuclearoDinossauro", Name = "Nuclearo Dinossauro", Rarity = "Godly", Color = Color3.fromRGB(98, 94, 84) },
	{ Id = "KetupatKepat", Name = "Ketupat Kepat", Rarity = "Godly", Color = Color3.fromRGB(110, 172, 60) },
	{ Id = "TorrtuginniDragonfrutini", Name = "Torrtuginni Dragonfrutini", Rarity = "Godly", Color = Color3.fromRGB(228, 50, 132) },
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

local function words(name: string): { string }
	local list = {}
	for word in string.gmatch(name, "%S+") do
		table.insert(list, word)
	end
	return list
end

-- The name of a build ([partType] = brainrotId): its own name when every part comes from
-- one brainrot, or a mash-up of its head's first word and its body's last one ("Tung
-- Tralala"; a short first word takes the next one along: "La Vaca Sahur").
function Brainrots.NameOf(parts: { [string]: string }): string
	local first = parts.Head or parts.Body or parts.Arms or parts.Legs
	local second: string? = nil
	for _, partType in { "Body", "Legs", "Arms", "Head" } do
		local id = parts[partType]
		if id and id ~= first then
			second = id
			break
		end
	end
	local one = first and Brainrots.ById[first]
	if not one then
		return "???"
	end
	local other = second and Brainrots.ById[second]
	if not other then
		return one.Name
	end
	local head, tail = words(one.Name), words(other.Name)
	local start = head[1]
	if #start <= 2 and head[2] then
		start ..= " " .. head[2]
	end
	return `{start} {tail[#tail]}`
end

-- The rarest tier among a build's parts.
function Brainrots.TopRarity(parts: { [string]: string }): string
	local best, rank = "Common", -1
	for _, id in parts do
		local brainrot = Brainrots.ById[id]
		local rarity = brainrot and Rarities.ById[brainrot.Rarity]
		if rarity and rarity.Rank > rank then
			best, rank = rarity.Id, rarity.Rank
		end
	end
	return best
end

return Brainrots
