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

local PART_TYPES = Brainrots.PartTypes
-- Same colors as the droppers in the tycoon (TycoonManager).
local PART_COLORS = {
	Head = { Color3.fromRGB(255, 140, 200), Color3.fromRGB(235, 80, 160) },
	Body = { Color3.fromRGB(255, 225, 100), Color3.fromRGB(240, 180, 40) },
	Arms = { Color3.fromRGB(120, 225, 255), Color3.fromRGB(50, 170, 240) },
	Legs = { Color3.fromRGB(170, 240, 110), Color3.fromRGB(100, 200, 60) },
}
local SIZE = Vector2.new(820, 620)
local SELECTED_COLOR = Color3.fromRGB(255, 200, 40)
local BAD_COLOR = Color3.fromRGB(255, 90, 90)
local GOOD_COLOR = Color3.fromRGB(110, 240, 110)

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
-- an upgrade track's pips by tier, like its look on the line (TycoonManager)
local TIER_COLORS = { Color3.fromRGB(110, 230, 255), Color3.fromRGB(255, 110, 220), Color3.fromRGB(255, 200, 50) }
local EMPTY_PIP = Color3.fromRGB(215, 215, 225)

local function rarityOf(brainrotId: string): Rarities.Rarity?
	local brainrot = Brainrots.ById[brainrotId]
	return brainrot and Rarities.ById[brainrot.Rarity]
end

local function lineLabel(lineId: string): string
	for _, line in view do
		if line.Id == lineId then
			return `LINE {line.Index}`
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
		Kit.toast(if reason == "TooFar" then "Walk up to that line to change it (or get Auto-Collect)!" else failMessage, BAD_COLOR)
	end
	refresh()
end

-- Rendering ------------------------------------------------------------------

local function renderTabs(parent: Frame, current: LineView)
	for index, line in view do
		local selected = line.Id == current.Id
		Kit.button({
			Position = UDim2.fromOffset(24 + (index - 1) * 150, 14),
			Size = UDim2.fromOffset(140, 44),
			Parent = parent,
		}, if selected then Kit.Colors.Purple else Kit.Colors.Grey, `LINE {line.Index}`, function()
			selectedLine = line.Id
			render()
		end)
	end
	-- the line's parts, or its upgrades
	for index, spec in { { "Parts", "🧩 PARTS" }, { "Upgrades", "⚡ UPGRADES" } } do
		Kit.button({
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -24 - (2 - index) * 160, 0, 14),
			Size = UDim2.fromOffset(150, 44),
			Parent = parent,
		}, if mode == spec[1] then Kit.Colors.Coins else Kit.Colors.Grey, spec[2], function()
			mode = spec[1]
			render()
		end)
	end
end

local function renderInfo(parent: Frame, line: LineView)
	local zone = Zones.ById[line.Zone]
	local zoneName = if zone then zone.Name else line.Zone
	local text = `🏭 {zoneName}  ·  ships 💰 {Format.Number(line.Value)} every {string.format("%.1f", line.CycleTime)}s`
	Kit.text({
		Text = text,
		Position = UDim2.fromOffset(24, 68),
		Size = UDim2.fromOffset(560, 28),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = parent,
	})
	if line.FullMatch then
		Kit.text({
			Text = "✨ FULL MATCH x2 ✨",
			TextColor3 = GOOD_COLOR,
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -24, 0, 68),
			Size = UDim2.fromOffset(210, 28),
			TextXAlignment = Enum.TextXAlignment.Right,
			Parent = parent,
		})
	end
end

local function renderSlot(parent: Frame, line: LineView, partType: string, index: number)
	local hasDropper = line.Droppers[partType] == true
	local brainrotId = line.Parts[partType]
	local selected = partType == selectedSlot

	local card = Kit.new("TextButton", {
		AutoButtonColor = false,
		Text = "",
		BackgroundColor3 = Kit.White,
		Position = UDim2.fromOffset(32 + (index - 1) * 192, 106),
		Size = UDim2.fromOffset(180, 200),
		Parent = parent,
	})
	Kit.corner(card, 18)
	Kit.stroke(card, if selected then 6 else 4, if selected then SELECTED_COLOR else nil)

	local header = Kit.new("Frame", { Size = UDim2.new(1, 0, 0, 38), BackgroundColor3 = Kit.White, Parent = card })
	Kit.corner(header, 18)
	Kit.gradient(header, PART_COLORS[partType])
	Kit.text({ Text = string.upper(partType), Position = UDim2.fromOffset(0, 5), Size = UDim2.new(1, 0, 0, 28), Parent = header })

	local rarity = brainrotId and rarityOf(brainrotId)
	if brainrotId and rarity then
		local model = BrainrotModels.CreatePart(brainrotId, partType)
		Kit.viewport({ Position = UDim2.fromOffset(10, 42), Size = UDim2.fromOffset(160, 106), Parent = card }, model)
		Kit.text({ Text = Brainrots.ById[brainrotId].Name, Position = UDim2.fromOffset(8, 150), Size = UDim2.new(1, -16, 0, 24), Parent = card })
		Kit.text({ Text = string.upper(rarity.Id), TextColor3 = rarity.Color, Position = UDim2.fromOffset(8, 174), Size = UDim2.new(1, -16, 0, 18), Parent = card })
	else
		Kit.text({ Text = "EMPTY", TextColor3 = Color3.fromRGB(190, 190, 200), Position = UDim2.fromOffset(20, 80), Size = UDim2.new(1, -40, 0, 40), Parent = card })
	end

	if not hasDropper then
		local lock = Kit.new("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = Color3.fromRGB(40, 40, 55),
			BackgroundTransparency = 0.25,
			ZIndex = 3,
			Parent = card,
		})
		Kit.corner(lock, 18)
		Kit.text({
			Text = `🔒\nBUY THE {string.upper(partType)} DROPPER`,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(0.85, 0.5),
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

local function renderTile(parent: Instance, order: number, text: string?, brainrotId: string?, option: Option?, onClick: () -> ())
	local rarity = brainrotId and rarityOf(brainrotId)
	local tile = Kit.new("TextButton", {
		AutoButtonColor = false,
		Text = "",
		LayoutOrder = order,
		BackgroundColor3 = Kit.White,
		Parent = parent,
	})
	Kit.corner(tile, 14)
	Kit.stroke(tile, 4, if rarity then rarity.Color else nil)

	if brainrotId and option then
		local model = BrainrotModels.CreatePart(brainrotId, selectedSlot)
		Kit.viewport({ Position = UDim2.fromOffset(6, 4), Size = UDim2.new(1, -12, 0, 84), Parent = tile }, model)
		Kit.text({ Text = Brainrots.ById[brainrotId].Name, Position = UDim2.fromOffset(6, 90), Size = UDim2.new(1, -12, 0, 38), Parent = tile })
		if not option.Usable then
			local dim = Kit.new("Frame", {
				Size = UDim2.fromScale(1, 1),
				BackgroundColor3 = Color3.fromRGB(40, 40, 55),
				BackgroundTransparency = 0.35,
				ZIndex = 3,
				Parent = tile,
			})
			Kit.corner(dim, 14)
			local where = if option.UsedOn then lineLabel(option.UsedOn) else "ANOTHER LINE"
			Kit.text({ Text = `IN USE\n{where}`, TextColor3 = BAD_COLOR, Position = UDim2.fromOffset(8, 36), Size = UDim2.new(1, -16, 0, 44), ZIndex = 4, Parent = dim })
		end
	else
		Kit.text({ Text = text or "", TextColor3 = Color3.fromRGB(160, 160, 175), Position = UDim2.fromOffset(10, 40), Size = UDim2.new(1, -20, 0, 56), Parent = tile })
	end

	tile.Activated:Connect(function()
		Kit.click()
		onClick()
	end)
	return tile
end

local function renderPicker(parent: Frame, line: LineView)
	local hasDropper = line.Droppers[selectedSlot] == true
	Kit.text({
		Text = if hasDropper
			then `Pick a {string.upper(selectedSlot)} part  ·  one part, one line`
			else `Buy the {string.upper(selectedSlot)} dropper to use this slot`,
		Position = UDim2.fromOffset(24, 318),
		Size = UDim2.fromOffset(560, 26),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = parent,
	})
	if not hasDropper then
		return
	end

	local scroller = Kit.new("ScrollingFrame", {
		Position = UDim2.fromOffset(24, 350),
		Size = UDim2.new(1, -48, 0, 134),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 8,
		ScrollingDirection = Enum.ScrollingDirection.X,
		AutomaticCanvasSize = Enum.AutomaticSize.X,
		CanvasSize = UDim2.new(),
		Parent = parent,
	})
	Kit.new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 10),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = scroller,
	})
	Kit.new("UIPadding", { PaddingLeft = UDim.new(0, 6), PaddingTop = UDim.new(0, 6), Parent = scroller })

	local current = line.Parts[selectedSlot]
	local emptyTile = renderTile(scroller, 0, "✖\nEMPTY", nil, nil, function()
		if current then
			request("SetLinePart", "Couldn't empty that slot!", line.Id, selectedSlot, nil)
		end
	end)
	emptyTile.Size = UDim2.fromOffset(100, 122)

	local options: { Option } = line.Options[selectedSlot] or {}
	for order, option in options do
		local tile = renderTile(scroller, order, nil, option.Id, option, function()
			if option.Id == current then
				return
			end
			if not option.Usable then
				Kit.toast("That part is already on another line!", BAD_COLOR)
				return
			end
			request("SetLinePart", "Couldn't equip that part!", line.Id, selectedSlot, option.Id)
		end)
		tile.Size = UDim2.fromOffset(100, 122)
		if option.Id == current then
			Kit.text({
				Text = "✔",
				TextColor3 = GOOD_COLOR,
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, -4, 0, 2),
				Size = UDim2.fromOffset(28, 28),
				ZIndex = 5,
				Parent = tile,
			})
		end
	end
end

local function renderFooter(parent: Frame, line: LineView)
	Kit.text({
		Text = "Full match (all 4 from one brainrot) = 💰 x2 + completion!",
		Position = UDim2.fromOffset(24, 498),
		Size = UDim2.fromOffset(520, 30),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = parent,
	})
	Kit.button({
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -24, 0, 488),
		Size = UDim2.fromOffset(220, 52),
	}, Kit.Colors.Green, "⭐ EQUIP BEST", function()
		request("EquipBestLine", "Couldn't equip best!", line.Id)
	end).Parent = parent
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
		Kit.toast("⚡ UPGRADED! Your line lights up!", GOOD_COLOR)
	else
		Kit.toast(
			if reason == "Coins"
				then "Not enough Coins!"
				elseif reason == "Locked" then "Buy what it needs first!"
				elseif reason == "Max" then "Already maxed out!"
				else "Couldn't buy that!",
			BAD_COLOR
		)
	end
	refresh()
end

local CARD = Vector2.new(372, 200)

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
		local header = Kit.new("Frame", { Size = UDim2.new(1, 0, 0, 44), BackgroundColor3 = Kit.White, Parent = card })
		Kit.corner(header, 18)
		Kit.gradient(header, track.Colors)
		Kit.text({
			Text = `{track.Icon} {string.upper(track.Name)}`,
			Position = UDim2.fromOffset(14, 6),
			Size = UDim2.new(1, -130, 0, 32),
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = header,
		})
		Kit.text({
			Text = `LV {upgrade.Level}/{upgrade.Max}`,
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -14, 0, 8),
			Size = UDim2.fromOffset(110, 28),
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
		Kit.text({
			Text = if upgrade.Level > 0 then `Now: {LineUpgrades.Describe(track, upgrade.Level)}` else "Not bought yet",
			Position = UDim2.fromOffset(14, 76),
			Size = UDim2.new(1, -28, 0, 26),
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = card,
		})
		local maxed = upgrade.Level >= upgrade.Max
		Kit.text({
			Text = if maxed then "⭐ MAXED OUT ⭐" else `Next: {LineUpgrades.Describe(track, upgrade.Level + 1)}`,
			TextColor3 = GOOD_COLOR,
			Position = UDim2.fromOffset(14, 104),
			Size = UDim2.new(1, -28, 0, 26),
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = card,
		})
		local price = upgrade.Price
		if upgrade.Needs then
			Kit.text({
				Text = `🔒 Buy the {upgrade.Needs} first`,
				TextColor3 = BAD_COLOR,
				Position = UDim2.fromOffset(14, 142),
				Size = UDim2.new(1, -28, 0, 40),
				Parent = card,
			})
		elseif price and not maxed then
			local affordable = typeof(coins) == "number" and coins >= price
			Kit.button({
				Position = UDim2.fromOffset(14, 138),
				Size = UDim2.new(1, -28, 0, 50),
				Parent = card,
			}, if affordable then Kit.Colors.Green else Kit.Colors.Red, `BUY  💰 {Format.Number(price)}`, function()
				buyUpgrade(line.Id, track.Key)
			end)
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
		local newPanel, newContent = Kit.modal("LineMenu", "🏭 ASSEMBLY LINES", Kit.Colors.Purple, SIZE)
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

function LineMenu.IsOpen(): boolean
	return panel ~= nil and panel.Visible
end

-- Re-fetches the view if the menu is open (e.g. after unlocking a part).
function LineMenu.Refresh()
	if LineMenu.IsOpen() then
		refresh()
	end
end

return LineMenu
