--[[
	Gamepasses (GDD §12). Create each pass on the Creator Dashboard, then paste its id
	here. An Id of 0 means "not created yet": nobody owns it, and its buy button shows
	"soon" instead of a purchase prompt.

	Perk fields are optional and read by the services that apply them.
]]

export type Pass = {
	Id: number,
	Order: number, -- position in the shop
	Name: string,
	Icon: string, -- one of ours (Config/Icons)
	Description: string,
	IncomeMultiplier: number?, -- × Coins on every ship (ProductionManager)
	Luck: number?, -- + luck on boxes and Rolls (LootManager)
	FreeSpins: number?, -- + free daily wheel spins per day (DailyWheelManager)
	RemoteLines: boolean?, -- configure lines from anywhere (ProductionManager)
	AutoCollect: boolean?, -- collector Coins bank themselves (TycoonManager)
	Sprint: number?, -- × walk speed while holding Shift (client: Sprint)
	RadarRank: number?, -- an arrow points at the nearest box of this rarity rank or up (client: LootBoxes)
	Starter: StarterReward?, -- a newcomer's bundle, granted once (Services/StarterPack)
	OfferHours: number?, -- sold only this long after the player's first join (the shop and the ads)
	-- Id is a developer product's, bought once: owning it is saved in the player's data
	-- (a DataManager claim) instead of checked with Roblox (MonetizationManager)
	Product: boolean?,
	-- the shop card (Client/UI/Shop)
	Perks: { string }, -- what you get, one short line each
	Colors: { Color3 }, -- the card's gradient, top to bottom
	Ribbon: string?, -- a corner ribbon ("BEST VALUE")
}

-- What the Starter Pack gives, once: parts ({ brainrotId, partType }), Coins, Rolls and
-- boxes raining round you.
export type StarterReward = {
	Parts: { { string } },
	Coins: number,
	Rolls: number,
	Boxes: number,
}

local Gamepasses: { [string]: Pass } = {
	-- A limited-time offer for newcomers (the user, 2026-10-03): the shop and a corner ad
	-- count down 24 h from the first join, then it's gone from the game. A developer
	-- product (the user, 2026-10-03; it was a gamepass, which could be bought on the
	-- website after the offer ended), sold once a player.
	StarterPack = {
		Id = 3716361942,
		Product = true,
		Order = 0,
		Name = "Starter Pack",
		Icon = "Party",
		Description = "A full Bombardiro Crocodilo, Tung Tung Tung Sahur's arms, 250K Coins, 3 Rolls and 10 random loot boxes.",
		Starter = {
			Parts = {
				{ "BombardiroCrocodilo", "Legs" },
				{ "BombardiroCrocodilo", "Body" },
				{ "BombardiroCrocodilo", "Arms" },
				{ "BombardiroCrocodilo", "Head" },
				{ "TungTungTungSahur", "Arms" },
			},
			Coins = 250000,
			Rolls = 3,
			Boxes = 10,
		},
		OfferHours = 24,
		Perks = { "Mythic Bombardiro!", "Tung Sahur's arms", "250K Coins + 10 boxes", "3 Rolls" },
		Colors = { Color3.fromRGB(255, 120, 200), Color3.fromRGB(140, 60, 255) },
		Ribbon = "LIMITED!", -- the shop shows the offer's countdown on it
	},
	VIP = {
		Id = 2005406894,
		Order = 1,
		Name = "VIP",
		Icon = "Crown",
		Description = "+25% Coins, a VIP chat tag and +1 free daily spin.",
		IncomeMultiplier = 1.25,
		FreeSpins = 1,
		Perks = { "+25% Coins forever", "Gold [VIP] chat tag", "+1 free daily spin" },
		Colors = { Color3.fromRGB(255, 225, 90), Color3.fromRGB(255, 150, 30) },
		Ribbon = "BEST VALUE",
	},
	DoubleCoins = {
		Id = 2004518950,
		Order = 2,
		Name = "2x Coins",
		Icon = "Coin",
		Description = "Double Coins from every brainrot you ship.",
		IncomeMultiplier = 2,
		Perks = { "x2 Coins on every ship", "Stacks with VIP!" },
		Colors = { Color3.fromRGB(140, 245, 110), Color3.fromRGB(30, 170, 70) },
		Ribbon = "POPULAR",
	},
	AutoCollect = {
		Id = 2006336907,
		Order = 3,
		Name = "Auto-Collect",
		Icon = "Magnet",
		Description = "Coins bank automatically, and you can configure your lines from anywhere.",
		RemoteLines = true,
		AutoCollect = true,
		Perks = { "Coins bank by themselves", "Set up lines from anywhere" },
		Colors = { Color3.fromRGB(120, 220, 255), Color3.fromRGB(40, 110, 240) },
	},
	Lucky = {
		Id = 2005994907,
		Order = 4,
		Name = "Lucky",
		Icon = "Clover",
		Description = "+25% Luck on loot boxes and Rolls.",
		Luck = 0.25,
		Perks = { "+25% Luck on boxes", "+25% Luck on Rolls" },
		Colors = { Color3.fromRGB(150, 245, 150), Color3.fromRGB(40, 150, 90) },
	},
	FastOpen = {
		Id = 2005940893,
		Order = 5,
		Name = "Fast Open",
		Icon = "Lightning",
		Description = "Skip the reveal: loot pops straight into a quick feed, so you open box after box.",
		Perks = { "Loot skips the reveal", "Open boxes back to back" },
		Colors = { Color3.fromRGB(255, 140, 230), Color3.fromRGB(160, 60, 255) },
	},
	Sprint = {
		Id = 2006780929,
		Order = 6,
		Name = "Sprint",
		Icon = "Shoe",
		Description = "Hold Shift to run 60% faster.",
		Sprint = 1.6,
		Perks = { "Run 60% faster!", "Hold Shift (a button on mobile)" },
		Colors = { Color3.fromRGB(255, 160, 110), Color3.fromRGB(235, 70, 80) },
	},
	BoxRadar = {
		Id = 2006924923,
		Order = 7,
		Name = "Box Radar",
		Icon = "Radar",
		Description = "An arrow over your head points to the nearest Rare (or rarer) loot box on the map.",
		RadarRank = 3, -- Rare
		Perks = { "Arrow to Rare+ boxes", "See how far away they are" },
		Colors = { Color3.fromRGB(110, 255, 200), Color3.fromRGB(20, 160, 150) },
	},
}

return Gamepasses
