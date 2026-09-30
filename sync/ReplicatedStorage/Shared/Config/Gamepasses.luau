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
	},
	DoubleCoins = {
		Id = 0,
		Order = 2,
		Name = "2x Coins",
		Icon = "💰",
		Description = "Double Coins from every brainrot you ship.",
		IncomeMultiplier = 2,
	},
	AutoCollect = {
		Id = 0,
		Order = 3,
		Name = "Auto-Collect",
		Icon = "🧲",
		Description = "Coins bank automatically, and you can configure your lines from anywhere.",
		RemoteLines = true,
		AutoCollect = true,
	},
	Lucky = {
		Id = 0,
		Order = 4,
		Name = "Lucky",
		Icon = "🍀",
		Description = "+25% Luck on loot boxes and Rolls.",
		Luck = 0.25,
	},
	FastOpen = {
		Id = 0,
		Order = 5,
		Name = "Fast Open",
		Icon = "⚡",
		Description = "Loot wheels spin 3x faster.",
		WheelSpeed = 3,
	},
}

return Gamepasses
