--[[
	Developer products (GDD §12): Robux purchases that can be bought again and again.
	Create each on the Creator Dashboard, then paste its id here (0 = not created yet).
	Prices are set on the dashboard; the shop shows the live price.

	Roll packs, wheel spins and box drops give random rewards, so the shop shows their
	odds before purchase (Roblox's paid random items policy).

	SuggestedPrice (Robux) is only a note for Go live: the dashboard's price is the real
	one. References (2026-10): Steal a Brainrot sells one Mythic Lucky Block for 175 R$
	and one Secret Lucky Block for 2,399 R$, and 15 minutes of 2x Server Luck for 249 R$;
	Pet Simulator 99's packs run 50 to 2,400 R$. So a box drop costs ~40 R$ a box, down
	to 25 R$ a box in the 100 pack (2,499 R$, under the 5,000 first proposed: a top pack
	near SaB's dearest single item reads as a deal, not a wall).
]]

export type Product = {
	Id: number,
	Order: number,
	Name: string,
	Icon: string,
	Kind: string, -- "Gems" | "WheelSpins" | "Coins" | "BoxDrop" | "Nuke" (also "Rolls": none sold now)
	-- Gems/Rolls/WheelSpins: how many; Coins: seconds of the buyer's income (at least
	-- MinCoins); BoxDrop: how many boxes rain onto the map round the buyer (Config/Loot.Drops)
	Amount: number,
	MinCoins: number?,
	Ribbon: string?, -- a corner ribbon on its shop card
	SuggestedPrice: number?,
	-- bought with Gems instead of Robux (the user, 2026-10-03: box drops and wheel spins);
	-- its Id stays 0. Placeholder prices.
	GemPrice: number?,
}

local Products: { [string]: Product } = {
	GemsSmall = { Id = 2005010947, Order = 1, Name = "Handful of Gems", Icon = "💎", Kind = "Gems", Amount = 100 },
	GemsMedium = { Id = 2005718930, Order = 2, Name = "Bag of Gems", Icon = "💎", Kind = "Gems", Amount = 550 },
	GemsLarge = { Id = 2006492914, Order = 3, Name = "Chest of Gems", Icon = "💎", Kind = "Gems", Amount = 1200 },
	GemsHuge = { Id = 2006768946, Order = 4, Name = "Vault of Gems", Icon = "💎", Kind = "Gems", Amount = 3000 },
	Spin1 = { Id = 0, GemPrice = 40, Order = 7, Name = "1 Wheel Spin", Icon = "🎡", Kind = "WheelSpins", Amount = 1 },
	Spin5 = { Id = 0, GemPrice = 180, Order = 8, Name = "5 Wheel Spins", Icon = "🎡", Kind = "WheelSpins", Amount = 5 },
	-- Coins grow with the factory: a pack is minutes of your own income (never less than
	-- MinCoins, so a brand-new player still gets something worth it)
	Coins10m = { Id = 2005298900, Order = 9, Name = "Pile of Coins", Icon = "💰", Kind = "Coins", Amount = 600, MinCoins = 5000, SuggestedPrice = 49 },
	Coins1h = { Id = 2006414916, Order = 10, Name = "Sack of Coins", Icon = "💰", Kind = "Coins", Amount = 3600, MinCoins = 40000, SuggestedPrice = 199 },
	Coins4h = { Id = 2006732943, Order = 11, Name = "Cart of Coins", Icon = "💰", Kind = "Coins", Amount = 14400, MinCoins = 200000, SuggestedPrice = 599 },
	Coins12h = { Id = 2004926943, Order = 12, Name = "Vault of Coins", Icon = "💰", Kind = "Coins", Amount = 43200, MinCoins = 800000, Ribbon = "BEST DEAL", SuggestedPrice = 1299 },
	-- loot boxes rain onto the map round the buyer
	Drop1 = { Id = 0, GemPrice = 50, Order = 13, Name = "1 Box Drop", Icon = "🎁", Kind = "BoxDrop", Amount = 1, SuggestedPrice = 39 },
	Drop5 = { Id = 0, GemPrice = 225, Order = 14, Name = "5 Box Drop", Icon = "🎁", Kind = "BoxDrop", Amount = 5, SuggestedPrice = 179 },
	Drop10 = { Id = 0, GemPrice = 400, Order = 15, Name = "10 Box Drop", Icon = "🎁", Kind = "BoxDrop", Amount = 10, SuggestedPrice = 329 },
	Drop25 = { Id = 0, GemPrice = 900, Order = 16, Name = "25 Box Drop", Icon = "🎁", Kind = "BoxDrop", Amount = 25, SuggestedPrice = 749 },
	Drop100 = { Id = 0, GemPrice = 3000, Order = 17, Name = "BOX STORM", Icon = "🌪️", Kind = "BoxDrop", Amount = 100, Ribbon = "BEST DEAL", SuggestedPrice = 2499 },
	-- a giant Bombardiro drops a nuke on the server: everyone dies (Config/Nuke). 2000 R$.
	Nuke = { Id = 2006888922, Order = 0, Name = "NUKE", Icon = "☢️", Kind = "Nuke", Amount = 1, SuggestedPrice = 2000 },
}

return Products
