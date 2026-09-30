--[[
	Developer products (GDD §12): Robux purchases that can be bought again and again.
	Create each on the Creator Dashboard, then paste its id here (0 = not created yet).
	Prices are set on the dashboard; the shop shows the live price.

	Roll packs and wheel spins give random rewards, so the shop shows their odds before
	purchase (Roblox's paid random items policy).
]]

export type Product = {
	Id: number,
	Order: number,
	Name: string,
	Icon: string,
	Kind: string, -- "Gems" | "Rolls" | "WheelSpins"
	Amount: number,
}

local Products: { [string]: Product } = {
	GemsSmall = { Id = 0, Order = 1, Name = "Handful of Gems", Icon = "💎", Kind = "Gems", Amount = 100 },
	GemsMedium = { Id = 0, Order = 2, Name = "Bag of Gems", Icon = "💎", Kind = "Gems", Amount = 550 },
	GemsLarge = { Id = 0, Order = 3, Name = "Chest of Gems", Icon = "💎", Kind = "Gems", Amount = 1200 },
	GemsHuge = { Id = 0, Order = 4, Name = "Vault of Gems", Icon = "💎", Kind = "Gems", Amount = 3000 },
	Rolls3 = { Id = 0, Order = 5, Name = "3 Rolls", Icon = "🎲", Kind = "Rolls", Amount = 3 },
	Rolls10 = { Id = 0, Order = 6, Name = "10 Rolls", Icon = "🎲", Kind = "Rolls", Amount = 10 },
	Spin1 = { Id = 0, Order = 7, Name = "1 Wheel Spin", Icon = "🎡", Kind = "WheelSpins", Amount = 1 },
	Spin5 = { Id = 0, Order = 8, Name = "5 Wheel Spins", Icon = "🎡", Kind = "WheelSpins", Amount = 5 },
}

return Products
