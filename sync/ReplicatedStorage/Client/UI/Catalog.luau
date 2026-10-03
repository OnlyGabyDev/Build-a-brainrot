--[[
	Catalog (the Index)
	A sticker book (GDD §8): every brainrot is a big, glossy sticker with a white die-cut
	border, its rarity the sticker's background (sparkles twinkle on the rare ones, Godly
	in a turning rainbow); its figure with unlocked parts in color and locked ones blacked
	out (empty sticker pieces), "???" until you find one of its parts, and a round dot per
	zone edition (gray: zone still locked, blue: can be collected, green: collected).
	Progress bars up top. Click a sticker for the big picture with round edition buttons
	under it, its rewards, and to put the whole brainrot on a line.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

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
local CARD = Vector2.new(176, 228)
local COLUMN_WIDTH = SIZE.X - 450 - 24 -- the details' right column (it starts at x 450)
local EDITION_ICONS = { ToyWorkshop = "🧸", PlushieRoom = "🧵", ClayStudio = "🎨", VinylCollectibles = "💎", CandyFactory = "🍭" }
local EDITION_COLORS = {
	Locked = { Color3.fromRGB(190, 190, 200), Color3.fromRGB(130, 130, 145) },
	Open = { Color3.fromRGB(120, 200, 255), Color3.fromRGB(40, 110, 240) },
	Done = { Color3.fromRGB(140, 245, 120), Color3.fromRGB(40, 175, 60) },
}
local RAINBOW = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 100, 100)),
	ColorSequenceKeypoint.new(0.25, Color3.fromRGB(255, 220, 80)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(110, 240, 130)),
	ColorSequenceKeypoint.new(0.75, Color3.fromRGB(100, 180, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(220, 120, 255)),
})

type Inventory = {
	Parts: { [string]: { [string]: boolean } },
	Completed: { [string]: { [string]: number } },
}

local player = Players.LocalPlayer
local panel: Frame? = nil
local content: Frame? = nil
local body: Frame? = nil
local inventory: Inventory = { Parts = {}, Completed = {} }
local lineIds: { { Id: string, Index: number, Zone: string } } = {} -- the player's lines, by room
local filter = "ALL"
local rarestFirst = false
local selected: string? = nil -- the brainrot shown in details
local twinkles: { TextLabel } = {} -- sparkles on the rare stickers (they twinkle while the book is open)
local rainbows: { UIGradient } = {} -- the Godly stickers' backgrounds (they turn)

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

-- An edition's state for a brainrot: "Done" (collected), "Open" (can be collected: ship
-- a full one from that zone) or "Locked" (the zone needs more rebirths).
local function editionState(brainrotId: string, zone: Zones.Zone): string
	if isCompleted(brainrotId, zone.Id) then
		return "Done"
	end
	return if (player:GetAttribute("Rebirths") or 0) < zone.UnlockRebirths then "Locked" else "Open"
end

-- A sticker: a white die-cut border (`frame` itself, outlined dark) round a glossy face
-- in the rarity's colors (dimmed until it's discovered), twinkling sparkles from Rare up,
-- a turning rainbow for Godly. Returns the face.
local function stickerFace(frame: GuiObject, rarity: Rarities.Rarity, discovered: boolean, inset: number, radius: number): Frame
	frame.BackgroundColor3 = Kit.White
	Kit.corner(frame, radius + inset)
	Kit.stroke(frame, 3.5)
	local face = Kit.new("Frame", {
		Name = "Face",
		Position = UDim2.fromOffset(inset, inset),
		Size = UDim2.new(1, -inset * 2, 1, -inset * 2),
		BackgroundColor3 = Kit.White,
		ZIndex = 0,
		Parent = frame,
	})
	Kit.corner(face, radius)
	local color = if discovered then rarity.Color else rarity.Color:Lerp(Color3.fromRGB(120, 120, 135), 0.65)
	if rarity.Id == "Godly" and discovered then
		table.insert(rainbows, Kit.new("UIGradient", { Color = RAINBOW, Rotation = 45, Parent = face }))
	else
		Kit.gradient(face, { color:Lerp(Kit.White, 0.45), color:Lerp(Color3.new(0, 0, 0), 0.12) })
	end
	Kit.shine(face, radius - 4)
	if discovered and rarity.Rank >= 3 then
		local random = Random.new(rarity.Rank * 7 + #twinkles)
		for _ = 1, 2 + rarity.Rank do
			local spark = Kit.text({
				Text = "✦",
				TextColor3 = Color3.fromRGB(255, 252, 220),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(random:NextNumber(0.1, 0.9), random:NextNumber(0.08, 0.6)),
				Size = UDim2.fromOffset(18 + rarity.Rank * 2, 18 + rarity.Rank * 2),
				StrokeThickness = 0,
				ZIndex = 2,
				Parent = face,
			})
			spark:SetAttribute("Phase", random:NextNumber(0, math.pi * 2))
			table.insert(twinkles, spark)
		end
	end
	return face
end

-- The twinkles and rainbows move while the book is open.
RunService.RenderStepped:Connect(function(dt)
	if not (panel and panel.Visible) then
		return
	end
	local t = os.clock()
	for _, spark in twinkles do
		if spark.Parent then
			local phase = spark:GetAttribute("Phase") or 0
			local wave = (math.sin(t * 3 + phase) + 1) / 2
			spark.TextTransparency = 1 - wave
			spark.Rotation = (t * 40 + phase * 30) % 360
		end
	end
	for _, rainbow in rainbows do
		rainbow.Rotation = (rainbow.Rotation + dt * 60) % 360
	end
end)

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
			table.insert(lineIds, { Id = line.Id, Index = line.Index, Zone = line.Zone })
		end
		table.sort(lineIds, function(a, b)
			local roomA, roomB = Zones.ById[a.Zone], Zones.ById[b.Zone]
			local orderA, orderB = if roomA then roomA.Index else 0, if roomB then roomB.Index else 0
			return if orderA ~= orderB then orderA < orderB else a.Index < b.Index
		end)
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
	-- three progress bars
	for index, bar in { { "🧩 PARTS", parts, totalParts, Kit.Colors.Rolls }, { "⭐ COMPLETED", completed, #Brainrots.List, Kit.Colors.Coins }, { "🏅 EDITIONS", claimed, totalEditions, Kit.Colors.Green } } do
		local share = if (bar[3] :: number) > 0 then (bar[2] :: number) / (bar[3] :: number) else 0
		local track = Kit.new("Frame", {
			Position = UDim2.fromOffset(24 + (index - 1) * 318, 12),
			Size = UDim2.fromOffset(300, 36),
			BackgroundColor3 = Color3.fromRGB(70, 60, 95),
			Parent = parent,
		})
		Kit.new("UICorner", { CornerRadius = UDim.new(0.5, 0), Parent = track })
		Kit.stroke(track, 3)
		if share > 0 then
			local fill = Kit.new("Frame", {
				Size = UDim2.new(math.max(share, 0.12), 0, 1, 0),
				BackgroundColor3 = Kit.White,
				Parent = track,
			})
			Kit.new("UICorner", { CornerRadius = UDim.new(0.5, 0), Parent = fill })
			Kit.gradient(fill, bar[4] :: { Color3 })
			Kit.shine(fill, 12)
		end
		Kit.text({
			Text = `{bar[1]}  {bar[2]}/{bar[3]}`,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.new(0.9, 0, 0, 26),
			StrokeThickness = 2.5,
			ZIndex = 2,
			Parent = track,
		})
	end

	for index, name in FILTERS do
		Kit.button({
			Position = UDim2.fromOffset(24 + (index - 1) * 150, 58),
			Size = UDim2.fromOffset(140, 42),
			Parent = parent,
		}, if filter == name then Kit.Colors.Purple else Kit.Colors.Grey, name, function()
			filter = name
			render()
		end)
	end
	Kit.button({
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -24, 0, 58),
		Size = UDim2.fromOffset(210, 42),
		Parent = parent,
	}, Kit.Colors.Gems, if rarestFirst then "RARITY ▼" else "RARITY ▲", function()
		rarestFirst = not rarestFirst
		render()
	end)
end

local function renderCard(parent: Instance, order: number, brainrot: Brainrots.Brainrot)
	local rarity = Rarities.ById[brainrot.Rarity]
	local count = ownedCount(brainrot.Id)
	local discovered = count > 0
	local card = Kit.new("TextButton", {
		AutoButtonColor = false,
		Text = "",
		LayoutOrder = order,
		Parent = parent,
	})
	local face = stickerFace(card, rarity, discovered, 6, 16)
	Kit.viewport({ Position = UDim2.fromOffset(6, 24), Size = UDim2.new(1, -12, 0, 128), ZIndex = 1 }, buildFigure(brainrot.Id)).Parent = face

	-- the rarity on a little tag at the top, the parts found in a bubble in the corner
	local tag = Kit.new("Frame", {
		Position = UDim2.fromOffset(8, 6),
		Size = UDim2.fromOffset(104, 22),
		BackgroundColor3 = Color3.fromRGB(40, 30, 60),
		BackgroundTransparency = 0.25,
		ZIndex = 3,
		Parent = face,
	})
	Kit.new("UICorner", { CornerRadius = UDim.new(0.5, 0), Parent = tag })
	Kit.text({ Text = string.upper(rarity.Id), TextColor3 = if rarity.Id == "Godly" then Color3.fromRGB(255, 240, 150) else rarity.Color:Lerp(Kit.White, 0.3), Position = UDim2.fromOffset(6, 2), Size = UDim2.new(1, -12, 1, -4), StrokeThickness = 1.5, ZIndex = 4, Parent = tag })
	local done = isCompleted(brainrot.Id)
	local bubble = Kit.new("Frame", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -4, 0, 2),
		Size = UDim2.fromOffset(40, 40),
		BackgroundColor3 = Kit.White,
		ZIndex = 3,
		Parent = face,
	})
	Kit.new("UICorner", { CornerRadius = UDim.new(0.5, 0), Parent = bubble })
	Kit.stroke(bubble, 3)
	Kit.gradient(bubble, if done then Kit.Colors.Coins elseif count == #PART_TYPES then Kit.Colors.Green else Kit.Colors.Grey)
	Kit.text({ Text = if done then "⭐" else `{count}/4`, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.78, 0.6), StrokeThickness = if done then 0 else 2, ZIndex = 4, Parent = bubble })

	-- a completed one shows off its rewards right on the sticker (tap it to use them)
	if done then
		local pill = Kit.new("Frame", {
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 0, 154),
			Size = UDim2.new(1, -18, 0, 26),
			BackgroundColor3 = Kit.White,
			ZIndex = 5,
			Parent = face,
		})
		Kit.corner(pill, 12)
		Kit.stroke(pill, 2.5)
		Kit.gradient(pill, Kit.Colors.Green)
		Kit.text({ Text = if Gadgets[brainrot.Id] then "🦸 MORPH + 🎁 GADGET" else "🦸 MORPH", Position = UDim2.fromOffset(6, 3), Size = UDim2.new(1, -12, 1, -6), StrokeThickness = 2, ZIndex = 6, Parent = pill })
	end

	-- its name on a ribbon, the edition dots under it
	local ribbon = Kit.new("Frame", {
		Position = UDim2.new(0, 4, 0, 156),
		Size = UDim2.new(1, -8, 0, 30),
		BackgroundColor3 = Color3.fromRGB(40, 30, 60),
		BackgroundTransparency = 0.15,
		ZIndex = 3,
		Parent = face,
	})
	Kit.corner(ribbon, 10)
	Kit.text({ Text = if discovered then brainrot.Name else "???", Position = UDim2.fromOffset(6, 3), Size = UDim2.new(1, -12, 1, -6), StrokeThickness = 2, ZIndex = 4, Parent = ribbon })
	local zones = editions()
	local dot = 24
	local start = (CARD.X - 12 - #zones * dot - (#zones - 1) * 6) / 2
	for index, zone in zones do
		local state = editionState(brainrot.Id, zone)
		local circle = Kit.new("Frame", {
			Position = UDim2.fromOffset(start + (index - 1) * (dot + 6), 190),
			Size = UDim2.fromOffset(dot, dot),
			BackgroundColor3 = Kit.White,
			ZIndex = 3,
			Parent = face,
		})
		Kit.new("UICorner", { CornerRadius = UDim.new(0.5, 0), Parent = circle })
		Kit.stroke(circle, 2.5)
		Kit.gradient(circle, EDITION_COLORS[state])
		Kit.text({ Text = if state == "Done" then "✓" elseif state == "Locked" then "🔒" else "", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.7, 0.7), StrokeThickness = 1.5, ZIndex = 4, Parent = circle })
	end

	-- it bounces when you point at it
	local scale = Kit.new("UIScale", { Parent = card })
	card.MouseEnter:Connect(function()
		scale.Scale = 1.05
	end)
	card.MouseLeave:Connect(function()
		scale.Scale = 1
	end)
	card.Activated:Connect(function()
		Kit.click()
		selected = brainrot.Id
		render()
	end)
end

local function renderGrid(parent: Frame)
	renderHeader(parent)
	local scroller = Kit.new("ScrollingFrame", {
		Position = UDim2.fromOffset(16, 108),
		Size = UDim2.new(1, -32, 1, -120),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 10,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		Parent = parent,
	})
	Kit.new("UIGridLayout", {
		CellSize = UDim2.fromOffset(CARD.X, CARD.Y),
		CellPadding = UDim2.fromOffset(12, 12),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = scroller,
	})
	Kit.new("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10), Parent = scroller })
	for order, brainrot in sortedBrainrots() do
		renderCard(scroller, order, brainrot)
	end
end

-- Details --------------------------------------------------------------------

-- A line's button label: its room and number ("TOY 1", "PLUSHIE 2").
local function lineLabel(line: { Index: number, Zone: string }): string
	return `{Zones.Tag(line.Zone)} {line.Index}`
end

local function equipOnLine(line: { Id: string, Index: number, Zone: string }, brainrot: Brainrots.Brainrot)
	local remote = Remotes.Function("EquipBrainrot")
	local ok, success, reason = pcall(remote.InvokeServer, remote, line.Id, brainrot.Id)
	if ok and success then
		Kit.toast(`{lineLabel(line)} now builds {brainrot.Name}!`, GOOD_COLOR)
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
		Position = UDim2.fromOffset(24, 68),
		Size = UDim2.fromOffset(400, 412),
		Parent = parent,
	})
	local face = stickerFace(stage, rarity, discovered, 9, 20)
	local figure = buildFigure(brainrot.Id)
	local view = Kit.viewport({ Position = UDim2.fromOffset(8, 8), Size = UDim2.new(1, -16, 1, -16), ZIndex = 1 }, figure)
	view.Parent = face
	local stopOrbit = Kit.orbit(view, figure)
	view.Destroying:Connect(stopOrbit)

	-- round edition buttons under it: gray (zone locked), blue (can be collected), green
	-- (collected); tap one to read about it
	local zones = editions()
	local hint = Kit.text({
		Text = "Tap an edition!",
		TextColor3 = MUTED_COLOR,
		Position = UDim2.fromOffset(24, 552),
		Size = UDim2.fromOffset(400, 24),
		Parent = parent,
	})
	local size = 58
	local start = 24 + (400 - #zones * size - (#zones - 1) * 14) / 2
	for index, zone in zones do
		local state = editionState(brainrot.Id, zone)
		local button = Kit.button({
			Position = UDim2.fromOffset(start + (index - 1) * (size + 14), 488),
			Size = UDim2.fromOffset(size, size),
			Parent = parent,
		}, EDITION_COLORS[state], nil, function()
			local gems = math.floor(rarity.CompletionGems * zone.GemMultiplier)
			hint.Text = if state == "Done"
				then `{zone.Edition} edition: collected! (+{gems} 💎)`
				elseif state == "Locked" then `{zone.Edition} edition: 🔒 Rebirth {zone.UnlockRebirths}`
				else `{zone.Edition} edition: ship a full one from the {zone.Name} (+{gems} 💎)`
			hint.TextColor3 = if state == "Done" then GOOD_COLOR elseif state == "Open" then Color3.fromRGB(140, 210, 255) else MUTED_COLOR
		end)
		local round = button:FindFirstChildOfClass("UICorner")
		if round then
			round.CornerRadius = UDim.new(0.5, 0)
		end
		Kit.text({ Text = EDITION_ICONS[zone.Id] or string.sub(zone.Edition, 1, 1), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.45), Size = UDim2.fromScale(0.62, 0.62), StrokeThickness = 0, Parent = button })
		if state ~= "Open" then
			Kit.text({ Text = if state == "Done" then "✓" else "🔒", AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, 4, 1, 4), Size = UDim2.fromOffset(24, 24), StrokeThickness = 2, Parent = button })
		end
	end

	local x = 450
	Kit.text({
		Text = if discovered then brainrot.Name else "???",
		Position = UDim2.fromOffset(x, 66),
		Size = UDim2.fromOffset(COLUMN_WIDTH, 52),
		TextXAlignment = Enum.TextXAlignment.Left,
		StrokeThickness = 3.5,
		Parent = parent,
	})
	Kit.text({
		Text = `{string.upper(rarity.Id)}  ·  💰 {Format.Number(rarity.PartValue)} per part  ·  full match x2`,
		TextColor3 = rarity.Color,
		Position = UDim2.fromOffset(x, 120),
		Size = UDim2.fromOffset(COLUMN_WIDTH, 28),
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
			BackgroundColor3 = Kit.White,
			Parent = parent,
		})
		Kit.corner(chip, 12)
		Kit.stroke(chip, 3)
		Kit.gradient(chip, if has then Kit.Colors.Green else Kit.Colors.Grey)
		Kit.shine(chip, 8)
		Kit.text({
			Text = string.upper(partType) .. (if has then " ✓" else " 🔒"),
			Position = UDim2.fromOffset(6, 6),
			Size = UDim2.new(1, -12, 1, -12),
			Parent = chip,
		})
	end

	-- Editions and their rewards: a pill each, two to a row (the round buttons under the
	-- figure say more when tapped).
	Kit.text({
		Text = "EDITIONS",
		Position = UDim2.fromOffset(x, 218),
		Size = UDim2.fromOffset(300, 28),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = parent,
	})
	local pill = Vector2.new((COLUMN_WIDTH - 10) / 2, 32)
	local y = 252
	for index, zone in editions() do
		local state = editionState(brainrot.Id, zone)
		local gems = math.floor(rarity.CompletionGems * zone.GemMultiplier)
		local status = if state == "Done" then "✓" elseif state == "Locked" then `🔒 R{zone.UnlockRebirths}` else "ship one!"
		local chip = Kit.new("Frame", {
			Position = UDim2.fromOffset(x + ((index - 1) % 2) * (pill.X + 10), y + (index - 1) // 2 * (pill.Y + 6)),
			Size = UDim2.fromOffset(pill.X, pill.Y),
			BackgroundColor3 = Kit.White,
			Parent = parent,
		})
		Kit.corner(chip, 12)
		Kit.stroke(chip, 2.5)
		Kit.gradient(chip, EDITION_COLORS[state])
		Kit.text({
			Text = `{EDITION_ICONS[zone.Id] or ""} {zone.Edition}  {gems} 💎  {status}`,
			Position = UDim2.fromOffset(8, 4),
			Size = UDim2.new(1, -16, 1, -8),
			StrokeThickness = 2,
			Parent = chip,
		})
	end
	y += math.ceil(#editions() / 2) * (pill.Y + 6) + 8

	-- Morph and gadget, unlocked by the first completion: a framed REWARDS box, so you
	-- see they're there (locked ones say what you'd get).
	local gadget = Gadgets[brainrot.Id]
	local unlocked = isCompleted(brainrot.Id)
	local box = Kit.new("Frame", {
		Position = UDim2.fromOffset(x, y),
		Size = UDim2.fromOffset(COLUMN_WIDTH, 128),
		BackgroundColor3 = Kit.White,
		Parent = parent,
	})
	Kit.corner(box, 16)
	Kit.stroke(box, 4, if unlocked then Color3.fromRGB(255, 200, 40) else nil)
	Kit.gradient(box, if unlocked then { Color3.fromRGB(255, 235, 150), Color3.fromRGB(255, 170, 60) } else { Color3.fromRGB(200, 195, 215), Color3.fromRGB(150, 145, 170) })
	Kit.text({
		Text = if unlocked then "🎁 YOUR REWARDS" else "🔒 COMPLETE IT TO UNLOCK",
		Position = UDim2.fromOffset(12, 6),
		Size = UDim2.new(1, -24, 0, 26),
		TextXAlignment = Enum.TextXAlignment.Left,
		StrokeThickness = 2.5,
		Parent = box,
	})
	local half = (COLUMN_WIDTH - 36) / 2
	if unlocked then
		local morphed = player:GetAttribute("Morph") == brainrot.Id
		Kit.button({ Position = UDim2.fromOffset(12, 38), Size = UDim2.fromOffset(half, 52), Parent = box }, Kit.Colors.Purple, if morphed then "🔄 UNMORPH" else "🦸 MORPH!", function()
			setChoice("SetMorph", if morphed then nil else brainrot.Id)
		end)
		if gadget then
			local equipped = player:GetAttribute("Gadget") == brainrot.Id
			Kit.button({ Position = UDim2.fromOffset(24 + half, 38), Size = UDim2.fromOffset(half, 52), Parent = box }, if equipped then Kit.Colors.Grey else Kit.Colors.Green, if equipped then "✖ UNEQUIP" else `{gadget.Icon or "🎁"} GADGET!`, function()
				setChoice("EquipGadget", if equipped then nil else brainrot.Id)
			end)
		end
	end
	Kit.text({
		Text = if gadget then `{gadget.Icon or "🎁"} {gadget.Name}: {gadget.Description or ""}` else "🦸 Morph into it!",
		Position = UDim2.fromOffset(12, if unlocked then 96 else 44),
		Size = UDim2.new(1, -24, 0, if unlocked then 24 else 60),
		TextWrapped = true,
		StrokeThickness = 2,
		Parent = box,
	})
	y += 140

	-- Put it on a line: a button per line, named by its room, in a grid that scrolls
	-- when there are more lines than fit.
	if complete and #lineIds > 0 then
		Kit.text({
			Text = "PUT IT ON A LINE",
			Position = UDim2.fromOffset(x, y),
			Size = UDim2.fromOffset(300, 28),
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = parent,
		})
		local grid = Kit.new("ScrollingFrame", {
			Position = UDim2.fromOffset(x - 4, y + 30),
			Size = UDim2.new(0, COLUMN_WIDTH + 8, 1, -(y + 30) - 10),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 6,
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			CanvasSize = UDim2.new(),
			Parent = parent,
		})
		Kit.new("UIPadding", { PaddingLeft = UDim.new(0, 4), PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4), Parent = grid })
		Kit.new("UIGridLayout", {
			CellSize = UDim2.fromOffset((COLUMN_WIDTH - 3 * 8 - 6) / 4, 42),
			CellPadding = UDim2.fromOffset(8, 8),
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = grid,
		})
		for order, line in lineIds do
			Kit.button({ LayoutOrder = order, Parent = grid }, Kit.Colors.Green, lineLabel(line), function()
				equipOnLine(line, brainrot)
			end)
		end
	else
		Kit.text({
			Text = if complete then "Buy an assembly line to build it!" else "Find all 4 parts to build a full one!",
			TextColor3 = MUTED_COLOR,
			Position = UDim2.fromOffset(x, y + 10),
			Size = UDim2.fromOffset(COLUMN_WIDTH, 28),
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = parent,
		})
	end
end

render = function()
	if body then
		body:Destroy()
	end
	table.clear(twinkles)
	table.clear(rainbows)
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
		local newPanel, newContent = Kit.modal("Catalog", "📖 BRAINROT STICKER BOOK", Kit.Colors.Gems, SIZE)
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
