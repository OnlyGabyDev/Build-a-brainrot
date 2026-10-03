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
	Icon: string,
	Description: string,
	IncomeMultiplier: number?, -- × Coins on every ship (ProductionManager)
	Luck: number?, -- + luck on boxes and Rolls (LootManager)
	FreeSpins: number?, -- + free daily wheel spins per day (DailyWheelManager)
	RemoteLines: boolean?, -- configure lines from anywhere (ProductionManager)
	AutoCollect: boolean?, -- collector Coins bank themselves (TycoonManager)
	Sprint: number?, -- × walk speed while holding Shift (client: Sprint)
	Starter: StarterReward?, -- a newcomer's bundle, granted once (Services/StarterPack)
	OfferHours: number?, -- sold only this long after the player's first join (the shop and the ads)
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
	-- count down 24 h from the first join, then it's gone from the game. (A pass can still
	-- be bought from its page on the website afterwards; it grants the same way.)
	StarterPack = {
		Id = 0,
		Order = 0,
		Name = "Starter Pack",
		Icon = "🎉",
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
		Perks = { "Bombardiro (Mythic!) + Sahur arms", "💰 250K Coins + 🎁 10 boxes", "🎲 3 Rolls" },
		Colors = { Color3.fromRGB(255, 120, 200), Color3.fromRGB(140, 60, 255) },
		Ribbon = "LIMITED!", -- the shop shows the offer's countdown on it
	},
	VIP = {
		Id = 2005406894,
		Order = 1,
		Name = "VIP",
		Icon = "👑",
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
		Icon = "💰",
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
		Icon = "🧲",
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
		Icon = "🍀",
		Description = "+25% Luck on loot boxes and Rolls.",
		Luck = 0.25,
		Perks = { "+25% Luck on boxes", "+25% Luck on Rolls" },
		Colors = { Color3.fromRGB(150, 245, 150), Color3.fromRGB(40, 150, 90) },
	},
	FastOpen = {
		Id = 2005940893,
		Order = 5,
		Name = "Fast Open",
		Icon = "⚡",
		Description = "Skip the reveal: loot pops straight into a quick feed, so you open box after box.",
		Perks = { "Loot skips the reveal", "Open boxes back to back" },
		Colors = { Color3.fromRGB(255, 140, 230), Color3.fromRGB(160, 60, 255) },
	},
	Sprint = {
		Id = 2006780929,
		Order = 6,
		Name = "Sprint",
		Icon = "👟",
		Description = "Hold Shift to run 60% faster.",
		Sprint = 1.6,
		Perks = { "Hold Shift to run", "60% faster (a button on mobile)" },
		Colors = { Color3.fromRGB(255, 160, 110), Color3.fromRGB(235, 70, 80) },
	},
}

return Gamepasses
