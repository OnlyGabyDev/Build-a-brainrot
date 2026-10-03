--[[
	Room upgrades (GDD §6): themed things to buy for a room (a zone) that make every
	line in it ship for more. Each comes in levels, bought one after another (a tycoon
	button that grows the thing: bigger, shinier, more motion), and some levels need a
	number of rebirths, so the early rooms keep growing after a rebirth, Cookie
	Clicker style. They reset on rebirth like the rest of the tycoon.

	The rooms are lovely without them (RoomDecor); these add on top. Prices are
	multiplied by the zone's PriceMultiplier. Placeholders to tune in playtests.
	RoomUpgradeBuilder (server) builds each level; TycoonItems turns them into buttons.
]]

export type Level = {
	Price: number, -- Coins, before the zone's PriceMultiplier
	Multiplier: number, -- × the ship value of every line in the room
	Rebirths: number?, -- rebirths needed before it can be bought
}

export type Upgrade = {
	Key: string,
	Name: string,
	Zone: string,
	Levels: { Level },
}

local RoomUpgrades = {}

RoomUpgrades.List = {
	-- Toy Workshop: all about boxes and toys
	{
		Key = "GiftTower",
		Name = "Gift Tower",
		Zone = "ToyWorkshop",
		Levels = {
			{ Price = 1000, Multiplier = 1.1 },
			{ Price = 8000, Multiplier = 1.1 },
			{ Price = 40000, Multiplier = 1.15 },
			{ Price = 400000, Multiplier = 1.5, Rebirths = 2 },
		},
	},
	{
		Key = "BubbleWrap",
		Name = "Bubble Wrap Popper",
		Zone = "ToyWorkshop",
		Levels = {
			{ Price = 3000, Multiplier = 1.1 },
			{ Price = 20000, Multiplier = 1.15 },
			{ Price = 100000, Multiplier = 1.2 },
		},
	},
	{
		Key = "BoxConveyor",
		Name = "Box Conveyor",
		Zone = "ToyWorkshop",
		Levels = {
			{ Price = 16000, Multiplier = 1.15 },
			{ Price = 70000, Multiplier = 1.2 },
			{ Price = 180000, Multiplier = 1.5, Rebirths = 1 },
		},
	},
	{
		Key = "JackBox",
		Name = "Jack-in-the-Box",
		Zone = "ToyWorkshop",
		Levels = {
			{ Price = 80000, Multiplier = 1.5, Rebirths = 1 },
			{ Price = 1600000, Multiplier = 2, Rebirths = 3 },
		},
	},
	{
		Key = "ToyTrain",
		Name = "Toy Train",
		Zone = "ToyWorkshop",
		Levels = {
			{ Price = 300000, Multiplier = 1.3, Rebirths = 2 },
			{ Price = 1200000, Multiplier = 1.3, Rebirths = 2 },
			{ Price = 3000000, Multiplier = 1.35, Rebirths = 3 },
			{ Price = 6000000, Multiplier = 1.35, Rebirths = 4 },
		},
	},

	-- Plushie Sewing Room: yarn, pillows, buttons, a giant plush brainrot
	{
		Key = "YarnSpinner",
		Name = "Yarn Spinner",
		Zone = "PlushieRoom",
		Levels = {
			{ Price = 4000, Multiplier = 1.1 },
			{ Price = 24000, Multiplier = 1.15 },
			{ Price = 120000, Multiplier = 1.2 },
			{ Price = 600000, Multiplier = 1.5, Rebirths = 3 },
		},
	},
	{
		Key = "PillowPile",
		Name = "Pillow Pile",
		Zone = "PlushieRoom",
		Levels = {
			{ Price = 1600, Multiplier = 1.1 },
			{ Price = 12000, Multiplier = 1.1 },
			{ Price = 60000, Multiplier = 1.15 },
		},
	},
	{
		Key = "ButtonJar",
		Name = "Button Jar",
		Zone = "PlushieRoom",
		Levels = {
			{ Price = 8000, Multiplier = 1.1 },
			{ Price = 50000, Multiplier = 1.15 },
			{ Price = 800000, Multiplier = 1.5, Rebirths = 4 },
		},
	},
	{
		Key = "GiantPlushie",
		Name = "Giant Plushie",
		Zone = "PlushieRoom",
		Levels = {
			{ Price = 300000, Multiplier = 1.3, Rebirths = 3 },
			{ Price = 1000000, Multiplier = 1.3, Rebirths = 3 },
			{ Price = 2400000, Multiplier = 1.35, Rebirths = 4 },
			{ Price = 5000000, Multiplier = 1.35, Rebirths = 5 },
		},
	},
} :: { Upgrade }

return RoomUpgrades
