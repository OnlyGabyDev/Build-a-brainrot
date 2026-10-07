--[[
	Line Menu
	Pick which part each dropper builds, or press Equip Best (GDD §6); the UPGRADES tab
	buys the line's upgrade tracks (Config/LineUpgrades), a level at a time. The server
	builds the view (GetLines) and validates every change, so this only draws what it's
	told and sends intents.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local BrainrotModels = require(Shared:WaitForChild("BrainrotModels"))
local Brainrots = require(Config:WaitForChild("Brainrots"))
local Format = require(Shared:WaitForChild("Format"))
local LineUpgrades = require(Config:WaitForChild("LineUpgrades"))
local Rarities = require(Config:WaitForChild("Rarities"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Zones = require(Config:WaitForChild("Zones"))
local Kit = require(script.Parent:WaitForChild("Kit"))
local UpgradePreview = require(script.Parent.Parent:WaitForChild("UpgradePreview"))

local PART_TYPES = Brainrots.PartTypes
-- Same colors as the droppers in the tycoon (TycoonManager).
local PART_COLORS = {
	Head = { Color3.fromRGB(255, 140, 200), Color3.fromRGB(235, 80, 160) },
	Body = { Color3.fromRGB(255, 225, 100), Color3.fromRGB(240, 180, 40) },
	Arms = { Color3.fromRGB(120, 225, 255), Color3.fromRGB(50, 170, 240) },
	Legs = { Color3.fromRGB(170, 240, 110), Color3.fromRGB(100, 200, 60) },
}
local SIZE = Vector2.new(1000, 660)
local SELECTED_COLOR = Color3.fromRGB(255, 200, 40)
local BAD_COLOR = Color3.fromRGB(255, 90, 90)
local GOOD_COLOR = Color3.fromRGB(110, 240, 110)
local MUTED_COLOR = Color3.fromRGB(150, 145, 170)

type Option = { Id: string, Usable: boolean, UsedOn: string? }
type UpgradeView = { Key: string, Level: number, Max: number, Price: number?, Needs: string? }
type LineView = {
	Id: string,
	Zone: string,
	Index: number,
	Droppers: { [string]: boolean },
	Parts: { [string]: string },
	Options: { [string]: { Option } },
	Value: number,
	CycleTime: number,
	FullMatch: boolean,
	Upgrades: { UpgradeView }?,
}

local LineMenu = {}

local panel: Frame? = nil
local content: Frame? = nil
local body: Frame? = nil -- everything inside `content`, rebuilt on each render
local view: { LineView } = {}
local selectedLine: string? = nil
local selectedSlot = "Head"
local mode = "Parts" -- or "Upgrades"
local busy = false
local previewing = false -- an upgrade preview is playing (the menu steps aside meanwhile)
-- an upgrade track's pips by tier, like its look on the line (TycoonManager)
local TIER_COLORS = { Color3.fromRGB(110, 230, 255), Color3.fromRGB(255, 110, 220), Color3.fromRGB(255, 200, 50) }
local EMPTY_PIP = Color3.fromRGB(215, 215, 225)

local function rarityOf(brainrotId: string): Rarities.Rarity?
	local brainrot = Brainrots.ById[brainrotId]
	return brainrot and Rarities.ById[brainrot.Rarity]
end

-- How the menu calls a line: "LINE 2" in the room on show, "PLUSHIE 1" in another.
local function lineLabel(lineId: string): string
	local here: string? = nil
	for _, line in view do
		if line.Id == selectedLine then
			here = line.Zone
		end
	end
	for _, line in view do
		if line.Id == lineId then
			return if line.Zone == here then `LINE {line.Index}` else `{Zones.Tag(line.Zone)} {line.Index}`
		end
	end
	return "ANOTHER LINE"
end

local render: () -> ()

local function refresh()
	local ok, result = pcall(function()
		return Remotes.Function("GetLines"):InvokeServer()
	end)
	if ok and typeof(result) == "table" then
		view = result
	end
	if panel and panel.Visible then
		render()
	end
end

local function request(remoteName: string, failMessage: string, ...: any)
	if busy then
		return
	end
	busy = true
	local remote = Remotes.Function(remoteName)
	local ok, success, reason = pcall(remote.InvokeServer, remote, ...)
	busy = false
	if not (ok and success) then
		Kit.toast(if reason == "TooFar" then "Walk up to that line!" else failMessage, BAD_COLOR, if reason == "TooFar" then "Factory" else "Warning")
	end
	refresh()
end

-- Rendering ------------------------------------------------------------------

-- Tabs for the lines in the current line's room (3 at most), after a pill that names the
-- room and steps on to the next room with lines; then the parts/upgrades switch.
local ROOM_PILL, LINE_TAB, TAB_GAP = 150, 96, 8

local function renderTabs(parent: Frame, current: LineView)
	local rooms: { string } = {}
	for _, line in view do
		if not table.find(rooms, line.Zone) then
			table.insert(rooms, line.Zone)
		end
	end
	local x = 24
	if #rooms > 1 then
		local nextRoom = rooms[(table.find(rooms, current.Zone) or 1) % #rooms + 1]
		Kit.button({
			Position = UDim2.fromOffset(x, 14),
			Size = UDim2.fromOffset(ROOM_PILL, 44),
			Parent = parent,
		}, Kit.Colors.Rolls, `{Zones.Tag(current.Zone)} »`, function()
			for _, line in view do
				if line.Zone == nextRoom then
					selectedLine = line.Id
					break
				end
			end
			render()
		end)
		x += ROOM_PILL + TAB_GAP
	end
	for _, line in view do
		if line.Zone ~= current.Zone then
			continue
		end
		Kit.button({
			Position = UDim2.fromOffset(x, 14),
			Size = UDim2.fromOffset(LINE_TAB, 44),
			Parent = parent,
		}, if line.Id == current.Id then Kit.Colors.Purple else Kit.Colors.Grey, `LINE {line.Index}`, function()
			selectedLine = line.Id
			render()
		end)
		x += LINE_TAB + TAB_GAP
	end
	-- the line's parts, or its upgrades
	for index, spec in { { "Parts", "PARTS", "Puzzle" }, { "Upgrades", "UPGRADES", "ArrowUp" } } do
		Kit.button({
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -24 - (2 - index) * 188, 0, 14),
			Size = UDim2.fromOffset(180, 44),
			Parent = parent,
		}, if mode == spec[1] then Kit.Colors.Coins else Kit.Colors.Grey, spec[2], function()
			mode = spec[1]
			render()
		end, spec[3])
	end
end

local function renderInfo(parent: Frame, line: LineView)
	local zone = Zones.ById[line.Zone]
	local zoneName = if zone then zone.Name else line.Zone
	Kit.icon("Factory", { Position = UDim2.fromOffset(20, 64), Size = UDim2.fromOffset(36, 36), Parent = parent })
	Kit.text({
		Text = zoneName,
		Position = UDim2.fromOffset(62, 68),
		Size = UDim2.fromOffset(200, 28),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = parent,
	})
	Kit.iconText({ Position = UDim2.fromOffset(270, 68), Size = UDim2.fromOffset(300, 28), Parent = parent }, "Coin", `{Format.Number(line.Value)} / {string.format("%.1f", line.CycleTime)}s`)
	if line.FullMatch then
		Kit.text({
			Text = "FULL MATCH x2!",
			TextColor3 = GOOD_COLOR,
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -24, 0, 68),
			Size = UDim2.fromOffset(210, 28),
			TextXAlignment = Enum.TextXAlignment.Right,
			Parent = parent,
		})
	end
end

-- A rarity's gradient for a card's face, light at the top.
local function rarityColors(rarity: Rarities.Rarity): { Color3 }
	return { rarity.Color:Lerp(Kit.White, 0.55), rarity.Color:Lerp(Kit.White, 0.1) }
end

-- The four slots across the top: each a big card in its part's color, the part on it
-- (a turning figure) on its rarity's colors; the selected one rimmed in gold.
local SLOT_W, SLOT_H, SLOT_GAP, SLOT_TOP = 220, 176, 18, 108
local function renderSlot(parent: Frame, line: LineView, partType: string, index: number)
	local hasDropper = line.Droppers[partType] == true
	local brainrotId = line.Parts[partType]
	local selected = partType == selectedSlot
	local rarity = brainrotId and rarityOf(brainrotId)
	local left = (SIZE.X - 4 * SLOT_W - 3 * SLOT_GAP) / 2

	local card = Kit.new("TextButton", {
		AutoButtonColor = false,
		Text = "",
		BackgroundColor3 = Kit.White,
		Position = UDim2.fromOffset(left + (index - 1) * (SLOT_W + SLOT_GAP), SLOT_TOP),
		Size = UDim2.fromOffset(SLOT_W, SLOT_H),
		Parent = parent,
	})
	Kit.corner(card, 20)
	Kit.stroke(card, if selected then 7 else 4, if selected then SELECTED_COLOR else nil)
	Kit.gradient(card, if rarity then rarityColors(rarity) else { Color3.fromRGB(245, 245, 250), Color3.fromRGB(215, 215, 228) })
	Kit.shine(card, 18)

	local header = Kit.new("Frame", { Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = Kit.White, Parent = card })
	Kit.corner(header, 20)
	Kit.gradient(header, PART_COLORS[partType])
	Kit.text({ Text = string.upper(partType), Position = UDim2.fromOffset(0, 4), Size = UDim2.new(1, 0, 0, 32), StrokeThickness = 3, Parent = header })

	if brainrotId and rarity then
		local model = BrainrotModels.CreatePart(brainrotId, partType)
		Kit.viewport({ Position = UDim2.fromOffset(12, 42), Size = UDim2.new(1, -24, 0, 90), Parent = card }, model)
		Kit.text({ Text = Brainrots.ById[brainrotId].Name, Position = UDim2.fromOffset(8, 132), Size = UDim2.new(1, -16, 0, 24), StrokeThickness = 3, Parent = card })
		Kit.stars({ Position = UDim2.fromOffset(8, 152), Size = UDim2.new(1, -16, 0, 22), Parent = card }, rarity.Rank)
	else
		Kit.icon("Plus", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 56), Size = UDim2.fromOffset(56, 56), ImageTransparency = 0.3, Parent = card })
		Kit.text({ Text = "TAP TO PICK", TextColor3 = Color3.fromRGB(150, 145, 170), Position = UDim2.fromOffset(20, 120), Size = UDim2.new(1, -40, 0, 30), StrokeThickness = 0, Parent = card })
	end


	if not hasDropper then
		local lock = Kit.new("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = Color3.fromRGB(40, 40, 55),
			BackgroundTransparency = 0.2,
			ZIndex = 3,
			Parent = card,
		})
		Kit.corner(lock, 20)
		Kit.icon("Lock", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 40), Size = UDim2.fromOffset(64, 64), ZIndex = 4, Parent = lock })
		Kit.text({
			Text = `BUY THE {string.upper(partType)} DROPPER`,
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, 110),
			Size = UDim2.new(0.85, 0, 0, 44),
			ZIndex = 4,
			Parent = lock,
		})
	end

	card.Activated:Connect(function()
		Kit.click()
		selectedSlot = partType
		render()
	end)
end

-- A part to pick: a big tile on its rarity's colors with the part turning in it, its
-- name and stars; EQUIPPED on the one in the slot, IN USE (dimmed) on one used by
-- another line.
local TILE_W, TILE_H = 132, 152
local function renderTile(parent: Instance, order: number, text: string?, brainrotId: string?, option: Option?, onClick: () -> ())
	local rarity = brainrotId and rarityOf(brainrotId)
	local tile = Kit.new("TextButton", {
		AutoButtonColor = false,
		Text = "",
		LayoutOrder = order,
		BackgroundColor3 = Kit.White,
		Parent = parent,
	})
	Kit.corner(tile, 18)
	Kit.stroke(tile, 4)
	Kit.gradient(tile, if rarity then rarityColors(rarity) else { Color3.fromRGB(245, 245, 250), Color3.fromRGB(215, 215, 228) })
	Kit.shine(tile, 16)

	if brainrotId and option and rarity then
		local model = BrainrotModels.CreatePart(brainrotId, selectedSlot)
		Kit.viewport({ Position = UDim2.fromOffset(8, 8), Size = UDim2.new(1, -16, 0, 82), Parent = tile }, model)
		Kit.text({ Text = Brainrots.ById[brainrotId].Name, Position = UDim2.fromOffset(6, 90), Size = UDim2.new(1, -12, 0, 34), StrokeThickness = 2.5, Parent = tile })
		Kit.stars({ Position = UDim2.fromOffset(6, 124), Size = UDim2.new(1, -12, 0, 24), Parent = tile }, rarity.Rank)
		if not option.Usable then
			local dim = Kit.new("Frame", {
				Size = UDim2.fromScale(1, 1),
				BackgroundColor3 = Color3.fromRGB(40, 40, 55),
				BackgroundTransparency = 0.3,
				ZIndex = 3,
				Parent = tile,
			})
			Kit.corner(dim, 18)
			local where = if option.UsedOn then lineLabel(option.UsedOn) else "ANOTHER LINE"
			Kit.text({ Text = `IN USE\n{where}`, TextColor3 = BAD_COLOR, Position = UDim2.fromOffset(8, 50), Size = UDim2.new(1, -16, 0, 50), ZIndex = 4, Parent = dim })
		end
	else
		Kit.icon("Close", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 30), Size = UDim2.fromOffset(52, 52), ImageColor3 = Color3.fromRGB(200, 195, 215), Parent = tile })
		Kit.text({ Text = text or "", TextColor3 = Color3.fromRGB(150, 145, 170), Position = UDim2.fromOffset(10, 92), Size = UDim2.new(1, -20, 0, 30), StrokeThickness = 0, Parent = tile })
	end

	tile.MouseEnter:Connect(function()
		Kit.pop(tile, 0.05)
	end)
	tile.Activated:Connect(function()
		Kit.click()
		onClick()
	end)
	return tile
end

local function renderPicker(parent: Frame, line: LineView)
	local hasDropper = line.Droppers[selectedSlot] == true
	local top = SLOT_TOP + SLOT_H + 12
	Kit.text({
		Text = if hasDropper
			then `PICK THE {string.upper(selectedSlot)}  ·  each part works on one line at a time`
			else `Buy the {string.upper(selectedSlot)} dropper to use this slot`,
		Position = UDim2.fromOffset(28, top),
		Size = UDim2.new(1, -56, 0, 28),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = parent,
	})
	if not hasDropper then
		return
	end

	local scroller = Kit.new("ScrollingFrame", {
		Position = UDim2.fromOffset(20, top + 34),
		Size = UDim2.new(1, -40, 1, -(top + 34) - 76),
		BackgroundColor3 = Color3.fromRGB(235, 230, 248),
		BorderSizePixel = 0,
		ScrollBarThickness = 10,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		Parent = parent,
	})
	Kit.corner(scroller, 16)
	Kit.new("UIGridLayout", {
		CellSize = UDim2.fromOffset(TILE_W, TILE_H),
		CellPadding = UDim2.fromOffset(12, 12),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = scroller,
	})
	Kit.new("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10), Parent = scroller })

	local current = line.Parts[selectedSlot]
	renderTile(scroller, 0, "EMPTY SLOT", nil, nil, function()
		if current then
			request("SetLinePart", "Couldn't empty that slot!", line.Id, selectedSlot, nil)
		end
	end)

	-- the rarest first; usable ones before the ones in use elsewhere
	local options: { Option } = table.clone(line.Options[selectedSlot] or {})
	table.sort(options, function(a, b)
		if a.Usable ~= b.Usable then
			return a.Usable
		end
		local ra, rb = rarityOf(a.Id), rarityOf(b.Id)
		return (if ra then ra.Rank else 0) > (if rb then rb.Rank else 0)
	end)
	for order, option in options do
		local tile = renderTile(scroller, order, nil, option.Id, option, function()
			if option.Id == current then
				return
			end
			if not option.Usable then
				Kit.toast("That part is on another line!", BAD_COLOR, "Puzzle")
				return
			end
			request("SetLinePart", "Couldn't equip that part!", line.Id, selectedSlot, option.Id)
		end)
		if option.Id == current then
			Kit.stroke(tile, 6, GOOD_COLOR)
			local ribbon = Kit.new("Frame", {
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.new(0.5, 0, 0, -4),
				Size = UDim2.fromOffset(110, 26),
				BackgroundColor3 = GOOD_COLOR,
				ZIndex = 5,
				Parent = tile,
			})
			Kit.corner(ribbon, 10)
			Kit.stroke(ribbon, 3)
			Kit.text({ Text = "EQUIPPED", Position = UDim2.fromOffset(4, 3), Size = UDim2.new(1, -8, 1, -6), StrokeThickness = 2, ZIndex = 6, Parent = ribbon })
		end
	end
end

local function renderFooter(parent: Frame, line: LineView)
	Kit.icon("Sparkle", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 22, 1, -18), Size = UDim2.fromOffset(42, 42), Parent = parent })
	Kit.text({
		Text = "All 4 from one brainrot = Coins x2!",
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 72, 1, -22),
		Size = UDim2.fromOffset(560, 32),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = parent,
	})
	Kit.button({
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -24, 1, -14),
		Size = UDim2.fromOffset(250, 58),
	}, Kit.Colors.Green, "EQUIP BEST", function()
		request("EquipBestLine", "Couldn't equip best!", line.Id)
	end, "Star").Parent = parent
end

-- Upgrades ------------------------------------------------------------------------

local function buyUpgrade(lineId: string, track: string)
	if busy then
		return
	end
	busy = true
	local remote = Remotes.Function("BuyLineUpgrade")
	local ok, success, reason = pcall(remote.InvokeServer, remote, lineId, track)
	busy = false
	if ok and success then
		Kit.toast("UPGRADED!", GOOD_COLOR, "ArrowUp")
	else
		Kit.toast(
			if reason == "Coins"
				then "Not enough Coins!"
				elseif reason == "Locked" then "Buy what it needs first!"
				elseif reason == "Max" then "Already maxed out!"
				else "Couldn't buy that!",
			BAD_COLOR,
			"Warning"
		)
	end
	refresh()
end

local CARD = Vector2.new(462, 222)
local PREVIEW_WIDTH = 64

-- Shows the track's next level on the line itself (UpgradePreview), the menu out of
-- the way meanwhile.
local function previewUpgrade(line: LineView, track: LineUpgrades.Track, level: number)
	local menu = panel
	if not menu then
		return
	end
	previewing = true -- (the menu still counts as open: the tablet keeps its camera)
	menu.Visible = false
	local title = `{string.upper(track.Name)} LV {level}`
	local subtitle = `{LineUpgrades.Describe(track, level)}` .. (if LineUpgrades.TierStarts[level] then `  ·  NEW LOOK: {LineUpgrades.TierStarts[level]}` else "")
	local started = UpgradePreview.Play(line.Id, track.Key, title, subtitle, function()
		previewing = false
		Kit.open(menu)
		refresh()
	end)
	if not started then
		previewing = false
		menu.Visible = true
		Kit.toast("Can't preview that now!", BAD_COLOR, "Eye")
	end
end

-- A card per track: its level in pips, what it gives now and next, and a buy button.
local function renderUpgrades(parent: Frame, line: LineView)
	local coins = Players.LocalPlayer:GetAttribute("Coins")
	local upgrades: { UpgradeView } = line.Upgrades or {}
	for index, upgrade in upgrades do
		local track = LineUpgrades.ByKey[upgrade.Key]
		if not track then
			continue
		end
		local column, row = (index - 1) % 2, (index - 1) // 2
		local card = Kit.new("Frame", {
			BackgroundColor3 = Kit.White,
			Position = UDim2.fromOffset(24 + column * (CARD.X + 28), 106 + row * (CARD.Y + 16)),
			Size = UDim2.fromOffset(CARD.X, CARD.Y),
			Parent = parent,
		})
		Kit.corner(card, 18)
		Kit.stroke(card, 4)
		Kit.gradient(card, { Kit.White, track.Colors[1]:Lerp(Kit.White, 0.7) })
		Kit.shine(card, 18)
		local header = Kit.new("Frame", { Size = UDim2.new(1, 0, 0, 44), BackgroundColor3 = Kit.White, Parent = card })
		Kit.corner(header, 18)
		Kit.gradient(header, track.Colors)
		Kit.stripes(header, 0.8, 18)
		Kit.icon(track.Icon, { Position = UDim2.fromOffset(4, -8), Size = UDim2.fromOffset(56, 56), ZIndex = 2, Parent = header })
		Kit.text({
			Text = string.upper(track.Name),
			Position = UDim2.fromOffset(64, 6),
			Size = UDim2.new(1, -200, 0, 32),
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = header,
		})
		Kit.text({
			Text = `LV {upgrade.Level}/{upgrade.Max}`,
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -14, 0, 8),
			Size = UDim2.fromOffset(112, 28),
			TextXAlignment = Enum.TextXAlignment.Right,
			Parent = header,
		})
		local pipWidth = (CARD.X - 28) / upgrade.Max
		for level = 1, upgrade.Max do
			local tier = if level >= 7 then 3 elseif level >= 4 then 2 else 1
			local pip = Kit.new("Frame", {
				Position = UDim2.fromOffset(14 + (level - 1) * pipWidth, 54),
				Size = UDim2.fromOffset(pipWidth - 6, 14),
				BackgroundColor3 = if level <= upgrade.Level then TIER_COLORS[tier] else EMPTY_PIP,
				Parent = card,
			})
			Kit.corner(pip, 6)
		end
		-- what it gives now » next, in big numbers, and what they're of (or the new look
		-- the next level brings, when it starts a tier)
		local maxed = upgrade.Level >= upgrade.Max
		local nextLevel = math.min(upgrade.Level + 1, upgrade.Max)
		local half = (CARD.X - 28) / 2
		for side, spec in { { "NOW", upgrade.Level, Kit.White }, { if maxed then "MAXED" else "NEXT", nextLevel, GOOD_COLOR } } do
			local x = 14 + (side - 1) * (half + 26) -- (the arrow goes between them)
			Kit.text({
				Text = spec[1] :: string,
				Position = UDim2.fromOffset(x, 72),
				Size = UDim2.fromOffset(half - 26, 16),
				TextColor3 = MUTED_COLOR,
				StrokeThickness = 1.5,
				Parent = card,
			})
			Kit.text({
				Text = LineUpgrades.Amount(track, spec[2] :: number),
				Position = UDim2.fromOffset(x, 86),
				Size = UDim2.fromOffset(half - 26, 42),
				TextColor3 = spec[3] :: Color3,
				StrokeThickness = 3,
				Parent = card,
			})
		end
		if not maxed then
			Kit.text({ Text = "»", Position = UDim2.fromOffset(14 + half - 20, 90), Size = UDim2.fromOffset(40, 30), TextColor3 = GOOD_COLOR, Parent = card })
		end
		local newLook = not maxed and LineUpgrades.TierStarts[nextLevel]
		Kit.text({
			Text = if newLook then `NEW LOOK: {newLook}!` elseif maxed then "MAXED OUT!" else LineUpgrades.Unit(track),
			Position = UDim2.fromOffset(14, 130),
			Size = UDim2.new(1, -28, 0, 20),
			TextColor3 = if newLook or maxed then SELECTED_COLOR else MUTED_COLOR,
			StrokeThickness = 1.5,
			Parent = card,
		})

		local price = upgrade.Price
		if upgrade.Needs then
			Kit.iconText({
				Position = UDim2.fromOffset(14, 166),
				Size = UDim2.new(1, -28, 0, 32),
				Parent = card,
			}, "Lock", `Buy the {upgrade.Needs} first`, BAD_COLOR)
		elseif price and not maxed then
			local affordable = typeof(coins) == "number" and coins >= price
			Kit.button({
				Position = UDim2.fromOffset(14, 156),
				Size = UDim2.new(1, -28 - PREVIEW_WIDTH - 10, 0, 54),
				Parent = card,
			}, if affordable then Kit.Colors.Green else Kit.Colors.Red, Format.Number(price), function()
				buyUpgrade(line.Id, track.Key)
			end, "Coin")
			-- the eye: fly over to the line and see the next level there
			Kit.button({
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, -14, 0, 156),
				Size = UDim2.fromOffset(PREVIEW_WIDTH, 54),
				Parent = card,
			}, Kit.Colors.Gems, nil, function()
				previewUpgrade(line, track, nextLevel)
			end, "Eye")
		end
	end
end

render = function()
	if body then
		body:Destroy()
	end
	local frame = Kit.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = content })
	body = frame

	if #view == 0 then
		Kit.text({
			Text = "Buy your first assembly line to start building brainrots!",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.45),
			Size = UDim2.fromOffset(640, 60),
			Parent = frame,
		})
		return
	end

	local line = view[1]
	for _, candidate in view do
		if candidate.Id == selectedLine then
			line = candidate
		end
	end
	selectedLine = line.Id

	renderTabs(frame, line)
	renderInfo(frame, line)
	if mode == "Upgrades" then
		renderUpgrades(frame, line)
		return
	end
	for index, partType in PART_TYPES do
		renderSlot(frame, line, partType, index)
	end
	renderPicker(frame, line)
	renderFooter(frame, line)
end

-- Public API -----------------------------------------------------------------

local function ensurePanel(): Frame
	if not panel then
		local newPanel, newContent = Kit.modal("LineMenu", "ASSEMBLY LINES", Kit.Hues.Purple, SIZE, "Factory")
		panel, content = newPanel, newContent
	end
	return panel :: Frame
end

-- Opens the menu, optionally on a given line and slot.
function LineMenu.Open(lineId: string?, partType: string?)
	local menu = ensurePanel()
	if lineId then
		selectedLine = lineId
	end
	if partType and table.find(PART_TYPES, partType) then
		selectedSlot = partType
	end
	Kit.open(menu)
	refresh()
end

-- (also while it's stepped aside for an upgrade preview: it comes back after)
function LineMenu.IsOpen(): boolean
	return panel ~= nil and (panel.Visible or previewing)
end

-- Re-fetches the view if the menu is open (e.g. after unlocking a part).
function LineMenu.Refresh()
	if LineMenu.IsOpen() then
		refresh()
	end
end

return LineMenu
