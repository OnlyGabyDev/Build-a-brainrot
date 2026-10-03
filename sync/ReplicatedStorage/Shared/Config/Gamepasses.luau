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
	WheelSpeed: number?, -- × loot wheel speed (client)
	RemoteLines: boolean?, -- configure lines from anywhere (ProductionManager)
	AutoCollect: boolean?, -- collector Coins bank themselves (TycoonManager)
	Sprint: number?, -- × walk speed while holding Shift (client: Sprint)
	-- the shop card (Client/UI/Shop)
	Perks: { string }, -- what you get, one short line each
	Colors: { Color3 }, -- the card's gradient, top to bottom
	Ribbon: string?, -- a corner ribbon ("BEST VALUE")
}

local Gamepasses: { [string]: Pass } = {
	VIP = {
		Id = 0,
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
		Id = 0,
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
		Id = 0,
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
		Id = 0,
		Order = 4,
		Name = "Lucky",
		Icon = "🍀",
		Description = "+25% Luck on loot boxes and Rolls.",
		Luck = 0.25,
		Perks = { "+25% Luck on boxes", "+25% Luck on Rolls" },
		Colors = { Color3.fromRGB(150, 245, 150), Color3.fromRGB(40, 150, 90) },
	},
	FastOpen = {
		Id = 0,
		Order = 5,
		Name = "Fast Open",
		Icon = "⚡",
		Description = "Loot wheels spin 3x faster.",
		WheelSpeed = 3,
		Perks = { "Loot reels spin x3 faster", "Open boxes back to back" },
		Colors = { Color3.fromRGB(255, 140, 230), Color3.fromRGB(160, 60, 255) },
	},
	Sprint = {
		Id = 0,
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
