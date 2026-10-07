--[[
	The Daily Wheel (GDD §12): one free spin every 24 hours (rolling), more with VIP,
	and paid spins from the shop. Weights are percentages; the wheel shows them, since
	paid spins are random items.
]]

export type Prize = {
	Id: string,
	Label: string,
	Icon: string, -- one of ours (Config/Icons)
	Weight: number,
	Kind: string, -- "Coins" | "Gems" | "Rolls" | "LuckBoost"
	Amount: number?, -- Gems / Rolls
	IncomeSeconds: number?, -- Coins: this many seconds of the player's income...
	MinCoins: number?, -- ...but at least this many
	Seconds: number?, -- LuckBoost: how long it lasts
}

local DailyWheel = {
	FreeSpinsPerDay = 1,
	Cooldown = 24 * 60 * 60, -- a free spin comes back this long after it was used
	LuckBoost = 0.5, -- extra luck while a Luck boost is active

	Prizes = {
		{ Id = "Coins", Label = "COINS", Icon = "Coin", Weight = 30, Kind = "Coins", IncomeSeconds = 120, MinCoins = 1000 },
		{ Id = "Gems25", Label = "25 GEMS", Icon = "Gem", Weight = 22, Kind = "Gems", Amount = 25 },
		{ Id = "Roll1", Label = "1 ROLL", Icon = "Roll", Weight = 18, Kind = "Rolls", Amount = 1 },
		{ Id = "Luck", Label = "LUCK 15m", Icon = "Clover", Weight = 12, Kind = "LuckBoost", Seconds = 15 * 60 },
		{ Id = "Gems100", Label = "100 GEMS", Icon = "Gem", Weight = 8, Kind = "Gems", Amount = 100 },
		{ Id = "Roll3", Label = "3 ROLLS", Icon = "Roll", Weight = 7, Kind = "Rolls", Amount = 3 },
		{ Id = "Jackpot", Label = "500 GEMS", Icon = "Crown", Weight = 3, Kind = "Gems", Amount = 500 },
	} :: { Prize },
}

return DailyWheel
