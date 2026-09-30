--[[
	Shop
	Gamepasses and Robux products (GDD §12). Prices come live from Roblox; items whose
	id is still 0 (not created yet) show "SOON". Roll packs and wheel spins give random
	rewards, so their odds are shown next to the buy buttons, before purchase (Roblox's
	paid random items policy). Purchases are granted by the server (ProcessReceipt).
]]

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local DailyWheel = require(Config:WaitForChild("DailyWheel"))
local Gamepasses = require(Config:WaitForChild("Gamepasses"))
local LootConfig = require(Config:WaitForChild("Loot"))
local Products = require(Config:WaitForChild("Products"))
local Rarities = require(Config:WaitForChild("Rarities"))
local Kit = require(script.Parent:WaitForChild("Kit"))

local SIZE = Vector2.new(980, 620)
local TABS = { "PASSES", "GEMS", "ROLLS", "SPINS" }
local TAB_KINDS = { GEMS = "Gems", ROLLS = "Rolls", SPINS = "WheelSpins" }
local GOLD_COLOR = Color3.fromRGB(255, 215, 60)
local GOOD_COLOR = Color3.fromRGB(120, 245, 110)

type Item = { Kind: string, Key: string, Id: number, Order: number, Name: string, Icon: string, Text: string }

local player = Players.LocalPlayer
local panel: Frame? = nil
local content: Frame? = nil
local body: Frame? = nil
local tab = "PASSES"
local prices: { [string]: number | false } = {}

local Shop = {}

-- Robux price of a pass or product, fetched once. Nil if unknown.
local function priceOf(kind: string, id: number): number?
	if id <= 0 then
		return nil
	end
	local key = kind .. id
	if prices[key] == nil then
		local infoType = if kind == "Pass" then Enum.InfoType.GamePass else Enum.InfoType.Product
		local ok, info = pcall(MarketplaceService.GetProductInfo, MarketplaceService, id, infoType)
		prices[key] = if ok and info and info.PriceInRobux then info.PriceInRobux else false
	end
	return prices[key] or nil
end

local function items(): { Item }
	local list: { Item } = {}
	if tab == "PASSES" then
		for key, pass in Gamepasses do
			table.insert(list, { Kind = "Pass", Key = key, Id = pass.Id, Order = pass.Order, Name = pass.Name, Icon = pass.Icon, Text = pass.Description })
		end
	else
		for key, product in Products do
			if product.Kind == TAB_KINDS[tab] then
				local text = `+{product.Amount} {product.Icon}`
				table.insert(list, { Kind = "Product", Key = key, Id = product.Id, Order = product.Order, Name = product.Name, Icon = product.Icon, Text = text })
			end
		end
	end
	table.sort(list, function(a, b)
		return a.Order < b.Order
	end)
	return list
end

local function buy(item: Item)
	if item.Kind == "Pass" and player:GetAttribute(`Pass_{item.Key}`) then
		return
	end
	if item.Id <= 0 then
		Kit.toast("Coming soon!", GOLD_COLOR)
	elseif item.Kind == "Pass" then
		MarketplaceService:PromptGamePassPurchase(player, item.Id)
	else
		MarketplaceService:PromptProductPurchase(player, item.Id)
	end
end

-- Rendering --------------------------------------------------------------------

local function renderCard(parent: Instance, item: Item)
	local owned = item.Kind == "Pass" and player:GetAttribute(`Pass_{item.Key}`) == true
	local card = Kit.new("Frame", { LayoutOrder = item.Order, BackgroundColor3 = Kit.White, Parent = parent })
	Kit.corner(card, 20)
	Kit.stroke(card, 4)
	Kit.gradient(card, if item.Kind == "Pass" then Kit.Colors.Purple else Kit.Colors.Gems)
	Kit.text({ Text = item.Icon, Position = UDim2.fromOffset(0, 8), Size = UDim2.new(1, 0, 0, 64), StrokeThickness = 0, Parent = card })
	Kit.text({ Text = item.Name, Position = UDim2.fromOffset(10, 76), Size = UDim2.new(1, -20, 0, 32), StrokeThickness = 3, Parent = card })
	Kit.text({
		Text = item.Text,
		TextColor3 = Color3.fromRGB(240, 235, 255),
		Position = UDim2.fromOffset(12, 110),
		Size = UDim2.new(1, -24, 0, 54),
		StrokeThickness = 1.5,
		Parent = card,
	})
	local button = Kit.button({
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -12),
		Size = UDim2.new(1, -28, 0, 48),
		Parent = card,
	}, if owned then Kit.Colors.Grey else Kit.Colors.Green, if owned then "OWNED ✓" elseif item.Id <= 0 then "SOON" else "...", function()
		buy(item)
	end)
	if not owned and item.Id > 0 then
		task.spawn(function()
			local price = priceOf(item.Kind, item.Id)
			local label = button:FindFirstChildOfClass("TextLabel")
			if label then
				label.Text = if price then `R$ {price}` else "BUY"
			end
		end)
	end
end

-- The odds of a random purchase, shown before buying.
local function renderOdds(parent: Frame, title: string, lines: { { Text: string, Color: Color3 } })
	local box = Kit.new("Frame", {
		Position = UDim2.fromOffset(600, 70),
		Size = UDim2.fromOffset(356, 460),
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
			Position = UDim2.fromOffset(20, 52 + (index - 1) * 36),
			Size = UDim2.new(1, -40, 0, 30),
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = box,
		})
	end
end

local function percent(weight: number, total: number): string
	local value = weight / total * 100
	return if value >= 1 then string.format("%.1f%%", value) else string.format("%.2f%%", value)
end

local function rollOddsLines(): { { Text: string, Color: Color3 } }
	local odds = LootConfig.RollOdds(player:GetAttribute("Rebirths") or 0, player:GetAttribute("Luck") or 0)
	local total = 0
	for _, weight in odds do
		total += weight
	end
	local lines = {}
	for _, rarity in Rarities.List do
		local weight = odds[rarity.Id]
		if weight then
			table.insert(lines, { Text = `{rarity.Id}: {percent(weight, total)}`, Color = rarity.Color })
		end
	end
	table.insert(lines, { Text = "Part type: 25% each", Color = Kit.White })
	return lines
end

local function wheelOddsLines(): { { Text: string, Color: Color3 } }
	local total = 0
	for _, prize in DailyWheel.Prizes do
		total += prize.Weight
	end
	local lines = {}
	for _, prize in DailyWheel.Prizes do
		table.insert(lines, { Text = `{prize.Icon} {prize.Label}: {percent(prize.Weight, total)}`, Color = Kit.White })
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

	for index, name in TABS do
		Kit.button({
			Position = UDim2.fromOffset(24 + (index - 1) * 150, 14),
			Size = UDim2.fromOffset(140, 44),
			Parent = frame,
		}, if tab == name then Kit.Colors.Coins else Kit.Colors.Grey, name, function()
			tab = name
			render()
		end)
	end

	local hasOdds = tab == "ROLLS" or tab == "SPINS"
	local grid = Kit.new("Frame", {
		Position = UDim2.fromOffset(24, 70),
		Size = UDim2.fromOffset(if hasOdds then 560 else 932, 460),
		BackgroundTransparency = 1,
		Parent = frame,
	})
	Kit.new("UIGridLayout", {
		CellSize = UDim2.fromOffset(220, 222),
		CellPadding = UDim2.fromOffset(14, 14),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = grid,
	})
	for _, item in items() do
		renderCard(grid, item)
	end

	if tab == "ROLLS" then
		renderOdds(frame, "ODDS PER ROLL", rollOddsLines())
	elseif tab == "SPINS" then
		renderOdds(frame, "WHEEL ODDS", wheelOddsLines())
	end
end

-- Public API -------------------------------------------------------------------

-- Opens the shop, optionally on a tab ("PASSES", "GEMS", "ROLLS", "SPINS").
function Shop.Open(openTab: string?)
	if not panel then
		local newPanel, newContent = Kit.modal("Shop", "🛒 SHOP", Kit.Colors.Coins, SIZE)
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
	Kit.toast(text, GOOD_COLOR)
	Kit.confetti(Kit.getGui() :: any, { GOLD_COLOR, GOOD_COLOR, Color3.fromRGB(120, 220, 255) }, 50, 70)
end

return Shop
