--[[
	DailyLogin
	The login streak (GDD §5): a reward a day for 7 days, claimed from a calendar that
	pops up on the first join of each UTC day. Miss a day and it starts over at day 1;
	after day 7 it goes round again. The rewards grow, day 7 the best: a new Rare+ part.
	Services/DailyLogin grants them; Client/UI/DailyLoginMenu shows the calendar.
]]

export type Reward = {
	Kind: string, -- "Coins" | "Gems" | "Rolls" | "Box" | "RarePart"
	Label: string, -- on its calendar card
	Icon: string, -- one of ours (Config/Icons)
	Amount: number?, -- Gems, Rolls
	IncomeSeconds: number?, -- Coins: seconds of the player's income...
	MinCoins: number?, -- ...but at least this many
	Rarity: string?, -- Box: a box of this rarity of your own lands in your front yard
	MinRank: number?, -- RarePart: a new part of this rarity rank or better
	Gems: number?, -- RarePart: Gems with it
}

local DailyLogin = {
	Days = {
		{ Kind = "Coins", Label = "COINS", Icon = "Coin", IncomeSeconds = 300, MinCoins = 1000 },
		{ Kind = "Rolls", Label = "1 ROLL", Icon = "Roll", Amount = 1 },
		{ Kind = "Gems", Label = "25 GEMS", Icon = "Gem", Amount = 25 },
		{ Kind = "Coins", Label = "BIG COINS", Icon = "Coin", IncomeSeconds = 1200, MinCoins = 10000 },
		{ Kind = "Box", Label = "RARE BOX", Icon = "Gift", Rarity = "Rare" },
		{ Kind = "Rolls", Label = "3 ROLLS", Icon = "Roll", Amount = 3 },
		{ Kind = "RarePart", Label = "RARE+ PART", Icon = "Star", MinRank = 3, Gems = 100 },
	} :: { Reward },
	SecondsPerDay = 86400, -- UTC days
}

return DailyLogin
