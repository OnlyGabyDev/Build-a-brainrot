--[[
	Catalog (the Index)
	Every brainrot as a card (GDD §8): its silhouette with unlocked parts in color and
	locked ones blacked out, "???" until you find one of its parts, and a badge per
	zone edition. Click a card for its details, edition rewards, and to put the whole
	brainrot on a line.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local BrainrotModels = require(Shared:WaitForChild("BrainrotModels"))
local Brainrots = require(Config:WaitForChild("Brainrots"))
local Format = require(Shared:WaitForChild("Format"))
local Gadgets = require(Config:WaitForChild("Gadgets"))
local Rarities = require(Config:WaitForChild("Rarities"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Zones = require(Config:WaitForChild("Zones"))
local Kit = require(script.Parent:WaitForChild("Kit"))

local PART_TYPES = Brainrots.PartTypes
local SIZE = Vector2.new(1000, 660)
local SILHOUETTE_COLOR = Color3.fromRGB(28, 26, 40)
local GOOD_COLOR = Color3.fromRGB(110, 240, 110)
local BAD_COLOR = Color3.fromRGB(255, 90, 90)
local MUTED_COLOR = Color3.fromRGB(175, 175, 190)
local FILTERS = { "ALL", "COMPLETED", "MISSING" }

type Inventory = {
	Parts: { [string]: { [string]: boolean } },
	Completed: { [string]: { [string]: number } },
}

local player = Players.LocalPlayer
local panel: Frame? = nil
local content: Frame? = nil
local body: Frame? = nil
local inventory: Inventory = { Parts = {}, Completed = {} }
local lineIds: { { Id: string, Index: number } } = {}
local filter = "ALL"
local rarestFirst = false
local selected: string? = nil -- the brainrot shown in details

local Catalog = {}

-- Helpers --------------------------------------------------------------------

-- Zones that exist in the game (built), in unlock order: one edition each.
local function editions(): { Zones.Zone }
	local list = {}
	for _, zone in Zones.List do
		if zone.Available then
			table.insert(list, zone)
		end
	end
	return list
end

local function ownedCount(brainrotId: string): number
	local count = 0
	for _, partType in PART_TYPES do
		local owned = inventory.Parts[brainrotId]
		if owned and owned[partType] then
			count += 1
		end
	end
	return count
end

local function isCompleted(brainrotId: string, zoneId: string?): boolean
	local done = inventory.Completed[brainrotId]
	if not done then
		return false
	end
	return if zoneId then done[zoneId] ~= nil else next(done) ~= nil
end

local function blackout(model: Model)
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Color = SILHOUETTE_COLOR
			descendant.Material = Enum.Material.SmoothPlastic
			descendant.Reflectance = 0
			if descendant:IsA("MeshPart") then
				descendant.TextureID = ""
			end
		elseif descendant:IsA("Decal") or descendant:IsA("Texture") or descendant:IsA("SurfaceAppearance") then
			descendant:Destroy()
		end
	end
end

-- The whole brainrot, with the parts you haven't unlocked blacked out.
local function buildFigure(brainrotId: string): Model
	local figure = Instance.new("Model")
	local owned = inventory.Parts[brainrotId] or {}
	for _, partType in PART_TYPES do
		local part = BrainrotModels.CreatePart(brainrotId, partType)
		if not owned[partType] then
			blackout(part)
		end
		part.Parent = figure
	end
	return figure
end

local function sortedBrainrots(): { Brainrots.Brainrot }
	local list = {}
	for order, brainrot in Brainrots.List do
		local completed = isCompleted(brainrot.Id)
		if filter == "ALL" or (filter == "COMPLETED") == completed then
			table.insert(list, { Brainrot = brainrot, Order = order })
		end
	end
	table.sort(list, function(a, b)
		local rankA = Rarities.ById[a.Brainrot.Rarity].Rank
		local rankB = Rarities.ById[b.Brainrot.Rarity].Rank
		if rankA ~= rankB then
			return if rarestFirst then rankA > rankB else rankA < rankB
		end
		return a.Order < b.Order
	end)
	local result = {}
	for _, entry in list do
		table.insert(result, entry.Brainrot)
	end
	return result
end

local render: () -> ()

local function refresh()
	local ok, result = pcall(function()
		return Remotes.Function("GetInventory"):InvokeServer()
	end)
	if ok and typeof(result) == "table" then
		inventory = result
	end
	local linesOk, view = pcall(function()
		return Remotes.Function("GetLines"):InvokeServer()
	end)
	if linesOk and typeof(view) == "table" then
		lineIds = {}
		for _, line in view do
			table.insert(lineIds, { Id = line.Id, Index = line.Index })
		end
	end
	if panel and panel.Visible then
		render()
	end
end

-- Grid -----------------------------------------------------------------------

local function renderHeader(parent: Frame)
	local totalParts, totalEditions = #Brainrots.List * #PART_TYPES, #Brainrots.List * #editions()
	local parts, completed, claimed = 0, 0, 0
	for _, brainrot in Brainrots.List do
		parts += ownedCount(brainrot.Id)
		if isCompleted(brainrot.Id) then
			completed += 1
		end
		for _, zone in editions() do
			if isCompleted(brainrot.Id, zone.Id) then
				claimed += 1
			end
		end
	end
	Kit.text({
		Text = `Parts {parts}/{totalParts}  ·  Completed {completed}/{#Brainrots.List}  ·  Editions {claimed}/{totalEditions}`,
		Position = UDim2.fromOffset(24, 14),
		Size = UDim2.fromOffset(560, 30),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = parent,
	})

	for index, name in FILTERS do
		Kit.button({
			Position = UDim2.fromOffset(24 + (index - 1) * 150, 54),
			Size = UDim2.fromOffset(140, 42),
			Parent = parent,
		}, if filter == name then Kit.Colors.Purple else Kit.Colors.Grey, name, function()
			filter = name
			render()
		end)
	end
	Kit.button({
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -24, 0, 54),
		Size = UDim2.fromOffset(210, 42),
		Parent = parent,
	}, Kit.Colors.Gems, if rarestFirst then "RARITY ▼" else "RARITY ▲", function()
		rarestFirst = not rarestFirst
		render()
	end)
end

local function renderCard(parent: Instance, order: number, brainrot: Brainrots.Brainrot)
	local rarity = Rarities.ById[brainrot.Rarity]
	local discovered = ownedCount(brainrot.Id) > 0
	local card = Kit.new("TextButton", {
		AutoButtonColor = false,
		Text = "",
		LayoutOrder = order,
		BackgroundColor3 = Kit.White,
		Parent = parent,
	})
	Kit.corner(card, 16)
	Kit.stroke(card, 4, rarity.Color)
	Kit.viewport({ Position = UDim2.fromOffset(8, 6), Size = UDim2.new(1, -16, 0, 124) }, buildFigure(brainrot.Id)).Parent = card
	Kit.text({
		Text = if discovered then brainrot.Name else "???",
		Position = UDim2.fromOffset(8, 132),
		Size = UDim2.new(1, -16, 0, 26),
		Parent = card,
	})
	Kit.text({
		Text = `{string.upper(rarity.Id)}  ·  {ownedCount(brainrot.Id)}/4`,
		TextColor3 = rarity.Color,
		Position = UDim2.fromOffset(8, 158),
		Size = UDim2.new(1, -16, 0, 18),
		Parent = card,
	})

	-- One badge per edition: ✓ claimed, 🔒 zone still locked.
	local rebirths = player:GetAttribute("Rebirths") or 0
	local zones = editions()
	for index, zone in zones do
		local width = (170 - 16 - (#zones - 1) * 4) / #zones
		local claimed = isCompleted(brainrot.Id, zone.Id)
		local locked = rebirths < zone.UnlockRebirths
		local badge = Kit.new("Frame", {
			Position = UDim2.fromOffset(8 + (index - 1) * (width + 4), 182),
			Size = UDim2.fromOffset(width, 22),
			BackgroundColor3 = if claimed then GOOD_COLOR else Color3.fromRGB(215, 215, 225),
			Parent = card,
		})
		Kit.corner(badge, 8)
		Kit.text({
			Text = zone.Edition .. (if claimed then " ✓" elseif locked then " 🔒" else ""),
			Position = UDim2.fromOffset(4, 2),
			Size = UDim2.new(1, -8, 1, -4),
			StrokeThickness = 1.5,
			Parent = badge,
		})
	end

	if isCompleted(brainrot.Id) then
		Kit.text({
			Text = "⭐",
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -4, 0, 2),
			Size = UDim2.fromOffset(32, 32),
			StrokeThickness = 0,
			Parent = card,
		})
	end

	card.Activated:Connect(function()
		Kit.click()
		selected = brainrot.Id
		render()
	end)
end

local function renderGrid(parent: Frame)
	renderHeader(parent)
	local scroller = Kit.new("ScrollingFrame", {
		Position = UDim2.fromOffset(16, 106),
		Size = UDim2.new(1, -32, 1, -118),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 10,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		Parent = parent,
	})
	Kit.new("UIGridLayout", {
		CellSize = UDim2.fromOffset(170, 212),
		CellPadding = UDim2.fromOffset(12, 12),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = scroller,
	})
	Kit.new("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingTop = UDim.new(0, 8), Parent = scroller })
	for order, brainrot in sortedBrainrots() do
		renderCard(scroller, order, brainrot)
	end
end

-- Details --------------------------------------------------------------------

local function equipOnLine(lineId: string, index: number, brainrot: Brainrots.Brainrot)
	local remote = Remotes.Function("EquipBrainrot")
	local ok, success, reason = pcall(remote.InvokeServer, remote, lineId, brainrot.Id)
	if ok and success then
		Kit.toast(`Line {index} now builds {brainrot.Name}!`, GOOD_COLOR)
	elseif reason == "TooFar" then
		Kit.toast("Walk up to that line to change it (or get Auto-Collect)!", BAD_COLOR)
	else
		Kit.toast("Some of its parts are busy on another line!", BAD_COLOR)
	end
end

-- Morph or gadget on/off (nil turns it off), then redraw once the server confirms.
local function setChoice(remoteName: string, brainrotId: string?)
	local remote = Remotes.Function(remoteName)
	local ok, done = pcall(remote.InvokeServer, remote, brainrotId)
	if not (ok and done) then
		Kit.toast("Try again in a moment!", BAD_COLOR)
	end
	task.wait(0.15) -- let the Morph/Gadget attribute replicate
	render()
end

local function renderDetails(parent: Frame, brainrot: Brainrots.Brainrot)
	local rarity = Rarities.ById[brainrot.Rarity]
	local discovered = ownedCount(brainrot.Id) > 0
	local complete = ownedCount(brainrot.Id) == #PART_TYPES

	Kit.button({ Position = UDim2.fromOffset(24, 14), Size = UDim2.fromOffset(140, 44), Parent = parent }, Kit.Colors.Grey, "◀ BACK", function()
		selected = nil
		render()
	end)

	local stage = Kit.new("Frame", {
		Position = UDim2.fromOffset(24, 70),
		Size = UDim2.fromOffset(400, 430),
		BackgroundColor3 = Kit.White,
		Parent = parent,
	})
	Kit.corner(stage, 20)
	Kit.stroke(stage, 5, rarity.Color)
	Kit.viewport({ Position = UDim2.fromOffset(10, 10), Size = UDim2.new(1, -20, 1, -20) }, buildFigure(brainrot.Id)).Parent = stage

	local x = 450
	Kit.text({
		Text = if discovered then brainrot.Name else "???",
		Position = UDim2.fromOffset(x, 66),
		Size = UDim2.fromOffset(520, 52),
		TextXAlignment = Enum.TextXAlignment.Left,
		StrokeThickness = 3.5,
		Parent = parent,
	})
	Kit.text({
		Text = `{string.upper(rarity.Id)}  ·  💰 {Format.Number(rarity.PartValue)} per part  ·  full match x2`,
		TextColor3 = rarity.Color,
		Position = UDim2.fromOffset(x, 120),
		Size = UDim2.fromOffset(520, 28),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = parent,
	})

	-- Part chips.
	local owned = inventory.Parts[brainrot.Id] or {}
	for index, partType in PART_TYPES do
		local has = owned[partType] == true
		local chip = Kit.new("Frame", {
			Position = UDim2.fromOffset(x + (index - 1) * 128, 162),
			Size = UDim2.fromOffset(118, 44),
			BackgroundColor3 = if has then GOOD_COLOR else Color3.fromRGB(120, 120, 135),
			Parent = parent,
		})
		Kit.corner(chip, 12)
		Kit.stroke(chip, 3)
		Kit.text({
			Text = string.upper(partType) .. (if has then " ✓" else " 🔒"),
			Position = UDim2.fromOffset(6, 6),
			Size = UDim2.new(1, -12, 1, -12),
			Parent = chip,
		})
	end

	-- Editions and their rewards.
	Kit.text({
		Text = "EDITIONS",
		Position = UDim2.fromOffset(x, 222),
		Size = UDim2.fromOffset(300, 30),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = parent,
	})
	local rebirths = player:GetAttribute("Rebirths") or 0
	for index, zone in editions() do
		local gems = math.floor(rarity.CompletionGems * zone.GemMultiplier)
		local status = if isCompleted(brainrot.Id, zone.Id)
			then "✓ claimed"
			elseif rebirths < zone.UnlockRebirths then `🔒 Rebirth {zone.UnlockRebirths}`
			else `ship a full one from the {zone.Name}`
		Kit.text({
			Text = `{zone.Edition}: {gems} 💎  ·  {status}`,
			TextColor3 = if isCompleted(brainrot.Id, zone.Id) then GOOD_COLOR else Kit.White,
			Position = UDim2.fromOffset(x + 12, 256 + (index - 1) * 32),
			Size = UDim2.fromOffset(510, 28),
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = parent,
		})
	end

	-- Morph and gadget, unlocked by the first completion.
	if isCompleted(brainrot.Id) then
		local morphed = player:GetAttribute("Morph") == brainrot.Id
		Kit.button({ Position = UDim2.fromOffset(x, 340), Size = UDim2.fromOffset(180, 48), Parent = parent }, Kit.Colors.Purple, if morphed then "UNMORPH" else "MORPH", function()
			setChoice("SetMorph", if morphed then nil else brainrot.Id)
		end)
		local gadget = Gadgets[brainrot.Id]
		if gadget then
			local equipped = player:GetAttribute("Gadget") == brainrot.Id
			Kit.button({
				Position = UDim2.fromOffset(x + 196, 340),
				Size = UDim2.fromOffset(250, 48),
				Parent = parent,
			}, Kit.Colors.Gems, if equipped then "UNEQUIP GADGET" else "EQUIP GADGET", function()
				setChoice("EquipGadget", if equipped then nil else brainrot.Id)
			end)
			Kit.text({
				Text = `🎁 {gadget.Name}`,
				Position = UDim2.fromOffset(x, 394),
				Size = UDim2.fromOffset(500, 26),
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = parent,
			})
		end
	else
		Kit.text({
			Text = "Complete it to unlock its morph and gadget!",
			TextColor3 = MUTED_COLOR,
			Position = UDim2.fromOffset(x, 350),
			Size = UDim2.fromOffset(520, 28),
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = parent,
		})
	end

	-- Put it on a line.
	local y = 430
	if complete and #lineIds > 0 then
		Kit.text({
			Text = "PUT IT ON A LINE",
			Position = UDim2.fromOffset(x, y),
			Size = UDim2.fromOffset(300, 30),
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = parent,
		})
		for index, line in lineIds do
			Kit.button({
				Position = UDim2.fromOffset(x + (index - 1) * 150, y + 36),
				Size = UDim2.fromOffset(140, 48),
				Parent = parent,
			}, Kit.Colors.Green, `LINE {line.Index}`, function()
				equipOnLine(line.Id, line.Index, brainrot)
			end)
		end
	else
		Kit.text({
			Text = if complete then "Buy an assembly line to build it!" else "Find all 4 parts to build a full one!",
			TextColor3 = MUTED_COLOR,
			Position = UDim2.fromOffset(x, y + 20),
			Size = UDim2.fromOffset(520, 30),
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = parent,
		})
	end
end

render = function()
	if body then
		body:Destroy()
	end
	local frame = Kit.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = content })
	body = frame
	local brainrot = selected and Brainrots.ById[selected]
	if brainrot then
		renderDetails(frame, brainrot)
	else
		renderGrid(frame)
	end
end

-- Public API -----------------------------------------------------------------

function Catalog.Open()
	if not panel then
		local newPanel, newContent = Kit.modal("Catalog", "📖 BRAINROT INDEX", Kit.Colors.Gems, SIZE)
		panel, content = newPanel, newContent
	end
	selected = nil
	Kit.open(panel :: Frame)
	refresh()
end

function Catalog.IsOpen(): boolean
	return panel ~= nil and panel.Visible
end

function Catalog.Refresh()
	if Catalog.IsOpen() then
		refresh()
	end
end

return Catalog
