--[[
	Shop
	Gamepasses and Robux products (GDD §12). Prices come live from Roblox; items whose
	id is still 0 (not created yet) show "SOON". Box drops and wheel spins cost Gems
	(their GemPrice; the server checks and takes them). Wheel spins and box drops
	give random rewards, so their odds are shown next to the buy buttons, before
	purchase (Roblox's paid random items policy). Purchases are granted by the server
	(ProcessReceipt).
]]

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local DailyWheel = require(Config:WaitForChild("DailyWheel"))
local Gamepasses = require(Config:WaitForChild("Gamepasses"))
local LootConfig = require(Config:WaitForChild("Loot"))
local Products = require(Config:WaitForChild("Products"))
local Format = require(Shared:WaitForChild("Format"))
local Rarities = require(Config:WaitForChild("Rarities"))
local Kit = require(script.Parent:WaitForChild("Kit"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Passes = require(script.Parent:WaitForChild("Passes"))

local SIZE = Vector2.new(1040, 690)
local TABS = { "PASSES", "GEMS", "COINS", "BOXES", "SPINS" }
local TAB_ICONS = { PASSES = "Crown", GEMS = "Gem", COINS = "Coin", BOXES = "Gift", SPINS = "Wheel" }
local KIND_WORDS = { Gems = "Gems", WheelSpins = "Spins", Rolls = "Rolls" }
local TAB_KINDS = { GEMS = "Gems", COINS = "Coins", BOXES = "BoxDrop", SPINS = "WheelSpins" }
local KIND_COLORS = {
	Gems = Kit.Colors.Gems,
	Coins = Kit.Colors.Coins,
	BoxDrop = { Color3.fromRGB(255, 170, 90), Color3.fromRGB(235, 70, 120) },
	WheelSpins = Kit.Colors.Purple,
}
local GOLD_COLOR = Color3.fromRGB(255, 215, 60)
local GOOD_COLOR = Color3.fromRGB(120, 245, 110)

type Item = { Kind: string, Key: string, Id: number, Order: number, Name: string, Icon: string, Text: string, Perks: { string }, Colors: { Color3 }, Ribbon: string?, Limited: boolean?, GemPrice: number? }

local player = Players.LocalPlayer
local panel: Frame? = nil
local content: Frame? = nil
local body: Frame? = nil
local tab = "PASSES"
local bubbles: { GuiObject } = {} -- the cards' icons (they bob while the shop is open)
local countdowns: { [TextLabel]: string } = {} -- limited offers' ribbons: [label] = pass key

local Shop = {}

-- "10 min", "1 hour", "12 hours"
local function duration(seconds: number): string
	if seconds < 3600 then
		return `{math.floor(seconds / 60)} min`
	end
	local hours = math.floor(seconds / 3600)
	return if hours == 1 then "1 hour" else `{hours} hours`
end

-- What a product's card lists.
local function perksOf(product: Products.Product): { string }
	if product.Kind == "Coins" then
		return { `{duration(product.Amount)} of your income`, `At least {Format.Number(product.MinCoins or 0)} Coins` }
	elseif product.Kind == "BoxDrop" then
		local reserved = duration(LootConfig.Drops.ReservedSeconds)
		return { if product.Amount == 1 then "A box drops by you" else `{product.Amount} boxes rain round you`, `Only yours for {reserved}` }
	end
	return { `+{Format.Number(product.Amount)} {KIND_WORDS[product.Kind] or ""}` }
end

local function items(): { Item }
	local list: { Item } = {}
	if tab == "PASSES" then
		for key, pass in Gamepasses do
			-- a limited offer is gone once it's over (unless it's owned: it shows OWNED)
			if Passes.OnSale(key) or Passes.Owns(key) then
				table.insert(list, { Kind = "Pass", Key = key, Id = pass.Id, Order = pass.Order, Name = pass.Name, Icon = pass.Icon, Text = pass.Description, Perks = pass.Perks, Colors = pass.Colors, Ribbon = pass.Ribbon, Limited = pass.OfferHours ~= nil })
			end
		end
		-- the NUKE leads the page (a product: it can be bought again and again)
		for key, product in Products do
			if product.Kind == "Nuke" then
				local perks = { "A giant Bombardiro drops it", "EVERYONE in the server dies!" }
				table.insert(list, { Kind = "Product", Key = key, Id = product.Id, Order = product.Order, Name = product.Name, Icon = product.Icon, Text = perks[2], Perks = perks, Colors = { Color3.fromRGB(255, 110, 80), Color3.fromRGB(170, 20, 40) }, Ribbon = "NUKE" })
			end
		end
	else
		for key, product in Products do
			if product.Kind == TAB_KINDS[tab] then
				local perks = perksOf(product)
				table.insert(list, { Kind = "Product", Key = key, Id = product.Id, Order = product.Order, Name = product.Name, Icon = product.Icon, Text = perks[1], Perks = perks, Colors = KIND_COLORS[product.Kind] or Kit.Colors.Gems, Ribbon = product.Ribbon, GemPrice = product.GemPrice })
			end
		end
	end
	table.sort(list, function(a, b)
		return a.Order < b.Order
	end)
	return list
end

local function buy(item: Item)
	if item.Kind == "Pass" and Passes.Owns(item.Key) then
		return
	end
	if item.GemPrice then
		task.spawn(function()
			local remote = Remotes.Function("BuyWithGems")
			local ok, bought = pcall(remote.InvokeServer, remote, item.Key)
			if not (ok and bought) then
				Kit.toast(`Need {item.GemPrice} Gems!`, Color3.fromRGB(255, 90, 90), "Gem")
			end
		end)
	elseif item.Id <= 0 then
		Kit.toast("Coming soon!", GOLD_COLOR, "Clock")
	elseif item.Kind == "Pass" then
		Passes.Prompt(item.Key)
	else
		MarketplaceService:PromptProductPurchase(player, item.Id)
	end
end

-- Rendering --------------------------------------------------------------------

-- A glossy striped card in the pass's own colors: its icon big and bobbing, a ribbon in
-- the corner for the best deals, what you get as a list of ticks, and the buy button
-- with its Robux price.
local function renderCard(parent: Instance, item: Item)
	local owned = item.Kind == "Pass" and Passes.Owns(item.Key)
	local card = Kit.new("Frame", { LayoutOrder = item.Order, BackgroundColor3 = Kit.White, Parent = parent })
	Kit.corner(card, 20)
	Kit.stroke(card, 4)
	Kit.gradient(card, item.Colors)
	Kit.stripes(card, 0.84, 20)
	Kit.shine(card, 16)
	local bubble = Kit.icon(item.Icon, {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 2),
		Size = UDim2.fromOffset(86, 86),
		ZIndex = 3,
		Parent = card,
	})
	table.insert(bubbles, bubble)
	Kit.text({ Text = item.Name, Position = UDim2.fromOffset(10, 86), Size = UDim2.new(1, -20, 0, 32), StrokeThickness = 3, Parent = card })
	local tight = #item.Perks > 3 -- (four lines pack tighter, so the last stays clear of the buy button)
	for index, perk in item.Perks do
		local top = 120 + (index - 1) * (if tight then 18 else 24)
		local height = if tight then 17 else 21
		local centered = #item.Perks == 1
		if not centered then
			Kit.icon("Check", { Position = UDim2.fromOffset(10, top - 1), Size = UDim2.fromOffset(height + 2, height + 2), Parent = card })
		end
		Kit.text({
			Text = perk,
			Position = UDim2.fromOffset(if centered then 12 else 14 + height, top),
			Size = UDim2.new(1, if centered then -24 else -26 - height, 0, height),
			TextXAlignment = if centered then Enum.TextXAlignment.Center else Enum.TextXAlignment.Left,
			StrokeThickness = 1.5,
			Parent = card,
		})
	end
	if item.Ribbon and not owned then
		local ribbon = Kit.new("Frame", {
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, 14, 0, -10),
			Size = UDim2.fromOffset(118, 30),
			Rotation = 12,
			BackgroundColor3 = Kit.White,
			ZIndex = 5,
			Parent = card,
		})
		Kit.corner(ribbon, 10)
		Kit.stroke(ribbon, 3)
		Kit.gradient(ribbon, Kit.Colors.Red)
		local label = Kit.text({ Text = item.Ribbon, Position = UDim2.fromOffset(6, 4), Size = UDim2.new(1, -12, 1, -8), StrokeThickness = 2, ZIndex = 6, Parent = ribbon })
		if item.Limited then
			countdowns[label] = item.Key
		end
	end
	local button = Kit.button({
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -10),
		Size = UDim2.new(1, -24, 0, 52),
		Parent = card,
	}, if owned then Kit.Colors.Grey elseif item.GemPrice then Kit.Colors.Gems else Kit.Colors.Green, if owned then "OWNED" elseif item.GemPrice then Format.Number(item.GemPrice) elseif item.Id <= 0 then "SOON" else "...", function()
		buy(item)
	end, if owned then "Check" elseif item.GemPrice then "Gem" else nil)
	if not owned and not item.GemPrice and item.Id > 0 then
		task.spawn(function()
			local price = if item.Kind == "Pass" then Passes.PassPrice(item.Key) else Passes.PriceOf(item.Kind, item.Id)
			local label = button:FindFirstChildOfClass("TextLabel")
			if label then
				label.Text = if price then `R$ {price}` else "BUY"
			end
		end)
	end
end

-- The cards' icons bob while the shop is open, and limited offers count down.
RunService.RenderStepped:Connect(function()
	if not (panel and panel.Visible) then
		return
	end
	local t = os.clock()
	for index, bubble in bubbles do
		bubble.Position = UDim2.new(0.5, 0, 0, 2 + math.sin(t * 2.4 + index) * 3)
		bubble.Rotation = math.sin(t * 1.7 + index) * 5
	end
	for label, key in countdowns do
		label.Text = Passes.Clock(Passes.OfferLeft(key) or 0)
	end
end)

-- The odds of a random purchase, shown before buying.
local function renderOdds(parent: Frame, title: string, lines: { { Text: string, Color: Color3 } })
	local box = Kit.new("Frame", {
		Position = UDim2.fromOffset(648, 74),
		Size = UDim2.new(0, 368, 1, -84),
		BackgroundColor3 = Color3.fromRGB(55, 45, 85),
		Parent = parent,
	})
	Kit.corner(box, 18)
	Kit.stroke(box, 4)
	Kit.text({ Text = title, TextColor3 = GOLD_COLOR, Position = UDim2.fromOffset(14, 10), Size = UDim2.new(1, -28, 0, 34), Parent = box })
	for index, line in lines do
		Kit.text({
			Text = line.Text,
			TextColor3 = line.Color,
			Position = UDim2.fromOffset(20, 54 + (index - 1) * 40),
			Size = UDim2.new(1, -40, 0, 32),
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = box,
		})
	end
end

local function percent(weight: number, total: number): string
	local value = weight / total * 100
	return if value >= 1 then string.format("%.1f%%", value) else string.format("%.2f%%", value)
end

-- One box of a bought drop: the part's rarity (the box's roll and the upgrade when it's
-- opened, combined), for the player's luck.
local function dropOddsLines(): { { Text: string, Color: Color3 } }
	local chances = LootConfig.DropPartOdds(player:GetAttribute("Luck") or 0)
	local lines = {}
	for _, rarity in Rarities.List do
		local chance = chances[rarity.Id]
		if chance then
			table.insert(lines, { Text = `{rarity.Id}: {percent(chance, 1)}`, Color = rarity.Color })
		end
	end
	table.insert(lines, { Text = "Part type: 25% each", Color = Kit.White })
	table.insert(lines, { Text = "Duplicates: Coins or Gems", Color = Kit.White })
	return lines
end

local function wheelOddsLines(): { { Text: string, Color: Color3 } }
	local total = 0
	for _, prize in DailyWheel.Prizes do
		total += prize.Weight
	end
	local lines = {}
	for _, prize in DailyWheel.Prizes do
		table.insert(lines, { Text = `{prize.Label}: {percent(prize.Weight, total)}`, Color = Kit.White })
	end
	return lines
end

local render: () -> ()

render = function()
	if body then
		body:Destroy()
	end
	local frame = Kit.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = content })
	body = frame
	table.clear(bubbles)
	table.clear(countdowns)

	for index, name in TABS do
		Kit.button({
			Position = UDim2.fromOffset(24 + (index - 1) * 166, 14),
			Size = UDim2.fromOffset(156, 48),
			Parent = frame,
		}, if tab == name then Kit.Colors.Coins else Kit.Colors.Grey, name, function()
			tab = name
			render()
		end, TAB_ICONS[name])
	end

	local hasOdds = tab == "SPINS" or tab == "BOXES"
	-- (it scrolls: the passes and the NUKE take three rows)
	local grid = Kit.new("ScrollingFrame", {
		Position = UDim2.fromOffset(20, 66),
		Size = UDim2.new(0, if hasOdds then 620 else 1004, 1, -70),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 8,
		ScrollBarImageColor3 = Kit.Hues.Green.Dark,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		Parent = frame,
	})
	-- (room above and right for the corner ribbons)
	Kit.new("UIPadding", { PaddingTop = UDim.new(0, 14), PaddingRight = UDim.new(0, 16), PaddingBottom = UDim.new(0, 10), Parent = grid })
	Kit.new("UIGridLayout", {
		-- three a row beside the odds (the five box drops take two rows), four without
		CellSize = if hasOdds then UDim2.fromOffset(190, 256) else UDim2.fromOffset(232, 256),
		CellPadding = UDim2.fromOffset(12, 12),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = grid,
	})
	for _, item in items() do
		renderCard(grid, item)
	end

	if tab == "SPINS" then
		renderOdds(frame, "WHEEL ODDS", wheelOddsLines())
	elseif tab == "BOXES" then
		renderOdds(frame, "ODDS PER BOX", dropOddsLines())
	end
end

-- Public API -------------------------------------------------------------------

-- Opens the shop, optionally on a tab ("PASSES", "GEMS", "COINS", "BOXES", "SPINS").
function Shop.Open(openTab: string?)
	if not panel then
		local newPanel, newContent = Kit.modal("Shop", "SHOP", Kit.Hues.Green, SIZE, "Cart")
		panel, content = newPanel, newContent
		-- Show new passes as owned as soon as they're granted.
		player.AttributeChanged:Connect(function(name)
			if string.sub(name, 1, 5) == "Pass_" and panel and panel.Visible then
				render()
			end
		end)
	end
	if openTab and table.find(TABS, openTab) then
		tab = openTab
	end
	Kit.open(panel :: Frame)
	render()
end

-- The thank-you after a Robux purchase (sent by the server once it's granted).
function Shop.Thanks(text: string)
	Kit.toast(text, GOOD_COLOR, "Party")
	Kit.confetti(Kit.getGui() :: any, { GOLD_COLOR, GOOD_COLOR, Color3.fromRGB(120, 220, 255) }, 50, 70)
end

return Shop
