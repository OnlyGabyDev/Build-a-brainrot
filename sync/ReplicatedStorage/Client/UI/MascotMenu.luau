--[[
	MascotMenu
	The company mascot's menu (GDD §10, Config/Mascot), opened from the mascot's prompt
	out front (Services/MascotManager sends "Open"): the brainrot turning on a card, its
	four parts on cards under it, its level, "Levels up every time you REBIRTH!", what it
	gives now and at the next rebirth (Coins, line speed, luck) and the look the next
	level adds. Its owner taps a part's card to pick another (big cards like the Line
	menu's: each part they own on its rarity's colors; mixes allowed) and has a REBIRTH
	button; anyone else just looks. Also plays the fanfare when a mascot levels up, the
	fireworks over the monuments (tag "MascotFireworks") and the marquee bulbs' chase and
	rainbow neon (tag "MascotLights"). Client only.
]]

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Client = ReplicatedStorage:WaitForChild("Client")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local BrainrotModels = require(Shared:WaitForChild("BrainrotModels"))
local Brainrots = require(Config:WaitForChild("Brainrots"))
local Effects = require(Client:WaitForChild("Effects"))
local MascotConfig = require(Config:WaitForChild("Mascot"))
local Rarities = require(Config:WaitForChild("Rarities"))
local Rebirths = require(Config:WaitForChild("Rebirths"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Sounds = require(Config:WaitForChild("Sounds"))
local Kit = require(script.Parent:WaitForChild("Kit"))
local RebirthMenu = require(script.Parent:WaitForChild("RebirthMenu"))

local SIZE = Vector2.new(900, 560)
local GOLD = Color3.fromRGB(255, 215, 60)
local GOOD_COLOR = Color3.fromRGB(120, 245, 110)
local BAD_COLOR = Color3.fromRGB(255, 90, 90)
local MUTED = Color3.fromRGB(255, 235, 250)
local HUE = Kit.Hues.Pink
-- the parts' colors, like their droppers in the tycoon (and the Line menu)
local PART_COLORS = {
	Head = { Color3.fromRGB(255, 140, 200), Color3.fromRGB(235, 80, 160) },
	Body = { Color3.fromRGB(255, 225, 100), Color3.fromRGB(240, 180, 40) },
	Arms = { Color3.fromRGB(120, 225, 255), Color3.fromRGB(50, 170, 240) },
	Legs = { Color3.fromRGB(170, 240, 110), Color3.fromRGB(100, 200, 60) },
}
local EMPTY_COLORS = { Color3.fromRGB(245, 245, 250), Color3.fromRGB(215, 215, 228) }
local SLOT = { Top = 286, Width = 94, Height = 150, Gap = 8 }
local TILE = Vector2.new(132, 152)
local FIREWORKS = { Every = 4.5, Range = 170, Colors = { Color3.fromRGB(255, 90, 120), Color3.fromRGB(255, 215, 60), Color3.fromRGB(110, 220, 255), Color3.fromRGB(150, 255, 140), Color3.fromRGB(220, 130, 255) } }
local LIGHTS = { Every = 0.18, Range = 220, Lit = Color3.fromRGB(255, 236, 170), Dim = Color3.fromRGB(150, 105, 40) }

type Info = {
	OwnerId: number,
	OwnerName: string,
	Level: number,
	Parts: { [string]: string },
	Upgrades: Rebirths.Levels,
	Mine: boolean,
}

local panel: Frame? = nil
local content: Frame? = nil
local body: Frame? = nil
local shown: Info? = nil
local picking: string? = nil -- the part type whose cards show on the right
local inventory: any = nil
local stops: { () -> () } = {}
local scroller: ScrollingFrame? = nil -- the picker's cards (where it's scrolled to stays on a re-render)
local scrolled = Vector2.zero

local MascotMenu = {}

local function percent(value: number): string
	return `+{math.floor(value * 100 + 0.5)}%`
end

local function rarityOf(brainrotId: string): Rarities.Rarity?
	local brainrot = Brainrots.ById[brainrotId]
	return brainrot and Rarities.ById[brainrot.Rarity]
end

-- A rarity's gradient for a card's face, light at the top.
local function rarityColors(brainrotId: string?): { Color3 }
	local rarity = brainrotId and rarityOf(brainrotId)
	return if rarity then { rarity.Color:Lerp(Kit.White, 0.55), rarity.Color:Lerp(Kit.White, 0.1) } else EMPTY_COLORS
end

-- What a mascot of `level` gives: { icon, name, value } rows.
local function bonuses(level: number, upgrades: Rebirths.Levels): { { string } }
	return {
		{ "Coin", "COINS", percent(Rebirths.IncomeMultiplier(level, upgrades) - 1) },
		{ "Lightning", "SPEED", percent(Rebirths.SpeedMultiplier(level, upgrades) - 1) },
		{ "Clover", "LUCK", percent(Rebirths.Luck(level, upgrades)) },
	}
end

-- The brainrot ids whose `partType` you own, the rarest first.
local function owned(partType: string): { string }
	local list = {}
	local parts = inventory and inventory.Parts or {}
	for _, brainrot in Brainrots.List do
		local have = parts[brainrot.Id]
		if have and have[partType] then
			table.insert(list, brainrot.Id)
		end
	end
	table.sort(list, function(a, b)
		local ra, rb = rarityOf(a), rarityOf(b)
		return (if ra then ra.Rank else 0) > (if rb then rb.Rank else 0)
	end)
	return list
end

local render: () -> ()

-- Puts `brainrotId`'s part on the mascot; the server rebuilds the mascot out front.
local function pick(partType: string, brainrotId: string)
	local info = shown
	if not (info and info.Mine) or info.Parts[partType] == brainrotId then
		return
	end
	local before = info.Parts[partType]
	info.Parts[partType] = brainrotId
	render()
	Kit.playSound(Sounds.Pop, 0.4, 1.2)
	local remote = Remotes.Function("SetMascotPart")
	local ok, done = pcall(remote.InvokeServer, remote, partType, brainrotId)
	if not (ok and done) and shown == info then
		info.Parts[partType] = before
		render()
		Kit.toast("Try again!", BAD_COLOR, "Warning")
	end
end

-- The mascot turning on a big card, its four parts on cards under it (its owner taps
-- one to change it).
local function renderBrainrot(parent: Frame, info: Info)
	local card = Kit.new("Frame", {
		Position = UDim2.fromOffset(20, 8),
		Size = UDim2.fromOffset(400, 268),
		BackgroundColor3 = Kit.White,
		ZIndex = 3,
		Parent = parent,
	})
	Kit.corner(card, 22)
	Kit.stroke(card, 4)
	Kit.gradient(card, { HUE.Light, HUE.Main })
	Kit.stripes(card, 0.82, 22, 3)
	table.insert(stops, Kit.rays(card, Color3.fromRGB(255, 240, 250), 420, 3))
	local model = BrainrotModels.Build(info.Parts)
	local viewport = Kit.viewport({ Size = UDim2.fromScale(1, 1), ZIndex = 4, Parent = card }, model)
	table.insert(stops, Kit.orbit(viewport, model, nil, Kit.fitDistance(model, 400 / 268) * 1.05))

	for index, partType in Brainrots.PartTypes do
		local brainrotId = info.Parts[partType]
		local rarity = brainrotId and rarityOf(brainrotId)
		local selected = picking == partType
		local slot = Kit.new("TextButton", {
			AutoButtonColor = false,
			Text = "",
			Position = UDim2.fromOffset(20 + (index - 1) * (SLOT.Width + SLOT.Gap), SLOT.Top),
			Size = UDim2.fromOffset(SLOT.Width, SLOT.Height),
			BackgroundColor3 = Kit.White,
			ZIndex = 3,
			Parent = parent,
		})
		Kit.corner(slot, 16)
		Kit.stroke(slot, if selected then 6 else 3.5, if selected then GOLD else nil)
		Kit.gradient(slot, rarityColors(brainrotId))
		Kit.shine(slot, 14)
		local header = Kit.new("Frame", { Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = Kit.White, ZIndex = 4, Parent = slot })
		Kit.corner(header, 16)
		Kit.gradient(header, PART_COLORS[partType])
		Kit.text({ Text = string.upper(partType), Position = UDim2.fromOffset(4, 3), Size = UDim2.new(1, -8, 0, 24), StrokeThickness = 2.5, ZIndex = 5, Parent = header })
		if brainrotId and rarity then
			Kit.viewport({ Position = UDim2.fromOffset(4, 32), Size = UDim2.new(1, -8, 0, 92), ZIndex = 4, Parent = slot }, (BrainrotModels.CreatePart(brainrotId, partType)))
			Kit.stars({ Position = UDim2.fromOffset(4, 126), Size = UDim2.new(1, -8, 0, 20), ZIndex = 4, Parent = slot }, rarity.Rank)
		end
		if info.Mine then
			slot.MouseEnter:Connect(function()
				Kit.pop(slot, 0.05)
			end)
			slot.Activated:Connect(function()
				Kit.click()
				picking = if picking == partType then nil else partType
				scroller = nil -- (another part's cards start at the top)
				render()
			end)
		end
	end
	if info.Mine then
		Kit.iconText({
			Position = UDim2.fromOffset(20, SLOT.Top + SLOT.Height + 8),
			Size = UDim2.fromOffset(400, 28),
			ZIndex = 3,
			Parent = parent,
		}, "Puzzle", "Tap a part to change it!", GOLD)
	end
end

-- A part to pick: a big card on its rarity's colors with the part in it, its name and
-- stars; PICKED on the one the mascot wears.
local function renderTile(parent: Instance, order: number, partType: string, brainrotId: string, picked: boolean)
	local rarity = rarityOf(brainrotId)
	local tile = Kit.new("TextButton", {
		AutoButtonColor = false,
		Text = "",
		LayoutOrder = order,
		BackgroundColor3 = Kit.White,
		ZIndex = 3,
		Parent = parent,
	})
	Kit.corner(tile, 18)
	Kit.stroke(tile, if picked then 6 else 4, if picked then GOOD_COLOR else nil)
	Kit.gradient(tile, rarityColors(brainrotId))
	Kit.shine(tile, 16)
	Kit.viewport({ Position = UDim2.fromOffset(8, 8), Size = UDim2.new(1, -16, 0, 82), ZIndex = 4, Parent = tile }, (BrainrotModels.CreatePart(brainrotId, partType)))
	Kit.text({ Text = Brainrots.ById[brainrotId].Name, Position = UDim2.fromOffset(6, 90), Size = UDim2.new(1, -12, 0, 34), StrokeThickness = 2.5, ZIndex = 4, Parent = tile })
	if rarity then
		Kit.stars({ Position = UDim2.fromOffset(6, 124), Size = UDim2.new(1, -12, 0, 24), ZIndex = 4, Parent = tile }, rarity.Rank)
	end
	if picked then
		local ribbon = Kit.new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, -2),
			Size = UDim2.fromOffset(96, 26),
			BackgroundColor3 = GOOD_COLOR,
			ZIndex = 5,
			Parent = tile,
		})
		Kit.corner(ribbon, 10)
		Kit.stroke(ribbon, 3)
		Kit.text({ Text = "PICKED", Position = UDim2.fromOffset(4, 3), Size = UDim2.new(1, -8, 1, -6), StrokeThickness = 2, ZIndex = 6, Parent = ribbon })
	end
	tile.MouseEnter:Connect(function()
		Kit.pop(tile, 0.05)
	end)
	tile.Activated:Connect(function()
		Kit.click()
		task.spawn(pick, partType, brainrotId)
	end)
end

-- The right side while picking: every `partType` you own as a big card, the rarest first.
local function renderPicker(parent: Frame, info: Info, partType: string)
	local x = 440
	local title = Kit.new("Frame", {
		Position = UDim2.fromOffset(x, 6),
		Size = UDim2.fromOffset(440, 44),
		BackgroundColor3 = Kit.White,
		ZIndex = 3,
		Parent = parent,
	})
	Kit.corner(title, 14)
	Kit.stroke(title, 3.5)
	Kit.gradient(title, PART_COLORS[partType])
	Kit.stripes(title, 0.8, 14, 4)
	Kit.text({ Text = `PICK THE {string.upper(partType)}`, Position = UDim2.fromOffset(10, 5), Size = UDim2.new(1, -20, 1, -10), StrokeThickness = 3, ZIndex = 5, Parent = title })

	local cards = Kit.new("ScrollingFrame", {
		Position = UDim2.fromOffset(x, 58),
		Size = UDim2.fromOffset(440, 352),
		BackgroundColor3 = Color3.fromRGB(255, 235, 248),
		BorderSizePixel = 0,
		ScrollBarThickness = 10,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		ZIndex = 3,
		Parent = parent,
	})
	Kit.corner(cards, 16)
	Kit.new("UIGridLayout", {
		CellSize = UDim2.fromOffset(TILE.X, TILE.Y),
		CellPadding = UDim2.fromOffset(10, 12),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = cards,
	})
	Kit.new("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingTop = UDim.new(0, 12), PaddingBottom = UDim.new(0, 10), Parent = cards })
	scroller = cards
	if not inventory then
		Kit.text({ Text = "Loading...", TextColor3 = HUE.Dark, Size = UDim2.fromOffset(400, 40), StrokeThickness = 0, ZIndex = 4, Parent = cards })
	else
		local list = owned(partType)
		for order, brainrotId in list do
			renderTile(cards, order, partType, brainrotId, info.Parts[partType] == brainrotId)
		end
		if #list < 4 then
			-- a hint card: where more parts come from
			local hint = Kit.new("Frame", { LayoutOrder = #list + 1, BackgroundColor3 = Kit.White, BackgroundTransparency = 0.4, ZIndex = 3, Parent = cards })
			Kit.corner(hint, 18)
			Kit.stroke(hint, 3, HUE.Main)
			Kit.icon("Gift", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 14), Size = UDim2.fromOffset(64, 64), ZIndex = 4, Parent = hint })
			Kit.text({ Text = "MORE FROM BOXES AND ROLLS!", TextColor3 = HUE.Dark, Position = UDim2.fromOffset(8, 84), Size = UDim2.new(1, -16, 0, 56), StrokeThickness = 0, ZIndex = 4, Parent = hint })
		end
		task.defer(function() -- (once the grid has sized the canvas)
			cards.CanvasPosition = scrolled
		end)
	end

	Kit.button({
		Position = UDim2.fromOffset(x + 120, 418),
		Size = UDim2.fromOffset(200, 58),
		ZIndex = 4,
		Parent = parent,
	}, Kit.Colors.Green, "DONE", function()
		picking = nil
		render()
	end, "Check")
end

local function renderLevel(parent: Frame, info: Info)
	local x = 440
	Kit.text({
		Text = `LEVEL {info.Level}`,
		TextColor3 = GOLD,
		Position = UDim2.fromOffset(x, 4),
		Size = UDim2.fromOffset(440, 52),
		StrokeThickness = 3.5,
		ZIndex = 3,
		Parent = parent,
	})
	Kit.iconText({
		Position = UDim2.fromOffset(x, 60),
		Size = UDim2.fromOffset(440, 30),
		ZIndex = 3,
		Parent = parent,
	}, "Rebirth", "Levels up every time you REBIRTH!")
	for _, spec in { { "NOW", 584 }, { "NEXT REBIRTH", 734 } } do
		Kit.text({ Text = spec[1], TextColor3 = MUTED, Position = UDim2.fromOffset(spec[2] - 20, 100), Size = UDim2.fromOffset(150, 24), ZIndex = 3, Parent = parent })
	end
	local now, nextUp = bonuses(info.Level, info.Upgrades), bonuses(info.Level + 1, info.Upgrades)
	for index, row in now do
		local card = Kit.new("Frame", {
			Position = UDim2.fromOffset(x, 128 + (index - 1) * 66),
			Size = UDim2.fromOffset(440, 58),
			BackgroundColor3 = Kit.White,
			ZIndex = 3,
			Parent = parent,
		})
		Kit.corner(card, 16)
		Kit.stroke(card, 3.5)
		Kit.gradient(card, Kit.pair(HUE))
		Kit.stripes(card, 0.85, 16, 3)
		Kit.icon(row[1], { Position = UDim2.fromOffset(6, 4), Size = UDim2.fromOffset(50, 50), ZIndex = 4, Parent = card })
		Kit.text({ Text = row[2], Position = UDim2.fromOffset(60, 12), Size = UDim2.fromOffset(100, 34), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 4, Parent = card })
		Kit.text({ Text = row[3], Position = UDim2.fromOffset(164, 10), Size = UDim2.fromOffset(110, 38), ZIndex = 4, Parent = card })
		Kit.icon("Arrow", { Position = UDim2.fromOffset(276, 14), Size = UDim2.fromOffset(30, 30), ZIndex = 4, Parent = card })
		Kit.text({ Text = nextUp[index][3], TextColor3 = GOOD_COLOR, Position = UDim2.fromOffset(310, 10), Size = UDim2.fromOffset(120, 38), ZIndex = 4, Parent = card })
	end
	local look = MascotConfig.NextLook(info.Level)
	Kit.iconText({
		Position = UDim2.fromOffset(x, 334),
		Size = UDim2.fromOffset(440, 30),
		ZIndex = 3,
		Parent = parent,
	}, "Sparkle", if look then `Next look: LV {look.Level}: {look.Name}` else "Every look unlocked! It still grows!", GOLD)
	if info.Mine then
		Kit.button({
			Position = UDim2.fromOffset(x + 40, 390),
			Size = UDim2.fromOffset(360, 74),
			ZIndex = 4,
			Parent = parent,
		}, Kit.pair(Kit.Hues.Gold), "REBIRTH", function()
			if panel then
				Kit.close(panel)
			end
			RebirthMenu.Open()
		end, "Rebirth")
	else
		Kit.text({
			Text = `{string.upper(info.OwnerName)}'S MASCOT`,
			Position = UDim2.fromOffset(x, 400),
			Size = UDim2.fromOffset(440, 40),
			ZIndex = 3,
			Parent = parent,
		})
	end
end

render = function()
	for _, stop in stops do
		stop()
	end
	table.clear(stops)
	scrolled = if scroller and scroller.Parent then scroller.CanvasPosition else Vector2.zero
	scroller = nil
	if body then
		body:Destroy()
		body = nil
	end
	local info = shown
	if not (info and content) then
		return
	end
	local frame = Kit.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 2, Parent = content })
	body = frame
	renderBrainrot(frame, info)
	if picking and info.Mine then
		renderPicker(frame, info, picking)
	else
		renderLevel(frame, info)
	end
end

function MascotMenu.Open(info: Info)
	if not panel then
		local newPanel, newContent = Kit.modal("Mascot", "MASCOT", HUE, SIZE, "Crown")
		panel, content = newPanel, newContent
		newPanel:GetPropertyChangedSignal("Visible"):Connect(function()
			if not newPanel.Visible then
				for _, stop in stops do
					stop()
				end
				table.clear(stops)
			end
		end)
	end
	shown = info
	picking = nil
	local title = (panel :: Frame):FindFirstChild("Title", true)
	if title and title:IsA("TextLabel") then
		title.Text = if info.Mine then "YOUR MASCOT" else `{string.upper(info.OwnerName)}'S MASCOT`
	end
	Kit.open(panel :: Frame)
	render()
	if info.Mine then
		task.spawn(function()
			local ok, result = pcall(function()
				return Remotes.Function("GetInventory"):InvokeServer()
			end)
			if ok and result then
				inventory = result
				if picking and shown == info then
					render()
				end
			end
		end)
	end
end

-- The marquee bulbs chase round the big mascots near you (two lit, one dark, moving on),
-- and from Rainbow its trims and bulbs cycle the rainbow.
local lit: { [Model]: { Bulbs: { BasePart }, Rainbow: { BasePart } } } = {}
local function animateLights(step: number)
	local hue = os.clock() * 0.15
	for _, stand in CollectionService:GetTagged("MascotLights") do
		if stand:IsA("Model") and stand.Parent and Effects.near(stand:GetPivot().Position, LIGHTS.Range) then
			local parts = lit[stand]
			if not parts then
				parts = { Bulbs = {}, Rainbow = {} }
				for _, part in stand:GetDescendants() do
					if part:IsA("BasePart") then
						if part:GetAttribute("Chase") then
							table.insert(parts.Bulbs, part)
						end
						if part:GetAttribute("Rainbow") then
							table.insert(parts.Rainbow, part)
						end
					end
				end
				lit[stand] = parts
			end
			local rainbow = #parts.Rainbow > 0
			for index, bulb in parts.Bulbs do
				local on = bulb:GetAttribute("Chase") ~= step % 3
				bulb.Material = if on then Enum.Material.Neon else Enum.Material.SmoothPlastic
				bulb.Color = if not on then LIGHTS.Dim elseif rainbow then Color3.fromHSV((hue + index * 0.04) % 1, 0.75, 1) else LIGHTS.Lit
			end
			for _, part in parts.Rainbow do
				part.Color = Color3.fromHSV((hue + (part:GetAttribute("Rainbow") :: number) * 0.06) % 1, 0.8, 1)
			end
		end
	end
	for stand in lit do
		if not stand.Parent then
			lit[stand] = nil
		end
	end
end

function MascotMenu.Init()
	Remotes.Event("Mascot").OnClientEvent:Connect(function(action: string, payload: any, level: number?)
		if action == "Open" then
			MascotMenu.Open(payload)
		elseif action == "LevelUp" and typeof(payload) == "Vector3" and Effects.near(payload, 200) then
			-- a fanfare round a mascot that just leveled up
			Effects.confetti(payload, 50)
			Effects.sparkle(payload, GOLD, 50, 26)
			Effects.flash(payload, GOLD, 6, 40, 0.8)
			Effects.ring(payload - Vector3.new(0, 2, 0), GOLD, 12, 0.7)
			Effects.sound(payload, Sounds.RevealBig, 0.6)
			if level then
				Effects.popup(payload + Vector3.new(0, 3, 0), `LEVEL {level}!`, GOLD, 4, 2)
			end
		end
	end)
	Remotes.Event("InventoryUpdated").OnClientEvent:Connect(function(newInventory)
		inventory = newInventory
	end)
	-- fireworks over the monuments near you, now and then
	task.spawn(function()
		while true do
			task.wait(FIREWORKS.Every)
			for _, stand in CollectionService:GetTagged("MascotFireworks") do
				if stand:IsA("Model") and stand.Parent then
					local top = stand:GetAttribute("Top")
					local at = stand:GetPivot().Position + Vector3.new(math.random(-8, 8), (if typeof(top) == "number" then top else 10) + math.random(10, 18), math.random(-8, 8))
					if Effects.near(at, FIREWORKS.Range) then
						local color = FIREWORKS.Colors[math.random(1, #FIREWORKS.Colors)]
						Effects.sparkle(at, color, 45, 32)
						Effects.flash(at, color, 5, 50, 0.5)
						Effects.sound(at, Sounds.Boom, 0.25, 1.8)
					end
				end
			end
		end
	end)
	task.spawn(function()
		local step = 0
		while true do
			task.wait(LIGHTS.Every)
			step += 1
			animateLights(step)
		end
	end)
end

return MascotMenu
