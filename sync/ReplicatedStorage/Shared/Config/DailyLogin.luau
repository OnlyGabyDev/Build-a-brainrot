--[[
	DailyLogin
	The login calendar (GDD §5): a reward a day for 7 days, once, claimed from a calendar
	that pops up on the first join of each UTC day. A missed day just waits: the next
	visit gets the next day; once day 7 is claimed it's over (it never starts over). The
	rewards grow, day 7 the best: a MYTHIC box of your own (the user, 2026-10-07; was a new
	Rare+ part and 100 Gems). Box days show the box itself, turning, on their card.
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
		{ Kind = "Box", Label = "MYTHIC BOX", Icon = "Gift", Rarity = "Mythic" },
	} :: { Reward },
	SecondsPerDay = 86400, -- UTC days
}

return DailyLogin
