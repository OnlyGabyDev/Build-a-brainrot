--[[
	Album (was the Index; GDD §8)
	A sticker album in the blue-inventory style: a page per rarity, each with its own
	scenery (Common a sunny meadow, Uncommon leafy green, Rare the sea with bubbles,
	Legendary gold under turning rays, Mythic a pink night of twinkles, Godly a turning
	rainbow), and on it a big sticker per brainrot: the whole figure filling it (the
	parts you're missing dark), its name ("???" until you find a part), a dot per part
	and its state: x/4, CLAIM! once all 4 parts are yours, or claimed. A sticker opens
	its spread: the big brainrot, its rarity, its 4 parts and one button: CLAIM (its
	morph, its gadget and its Gems, GDD §7), then MORPH / GADGET and a line to build it on.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local BrainrotModels = require(Shared:WaitForChild("BrainrotModels"))
local Brainrots = require(Config:WaitForChild("Brainrots"))
local Format = require(Shared:WaitForChild("Format"))
local Gadgets = require(Config:WaitForChild("Gadgets"))
local Rarities = require(Config:WaitForChild("Rarities"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Zones = require(Config:WaitForChild("Zones"))
local Celebration = require(script.Parent:WaitForChild("Celebration"))
local Kit = require(script.Parent:WaitForChild("Kit"))
local Loot = require(script.Parent:WaitForChild("Loot"))

local PART_TYPES = Brainrots.PartTypes
local SIZE = Vector2.new(1000, 660)
local PAGE = Vector2.new(968, 506) -- the page, under the rarity tabs
local CARD = Vector2.new(216, 452)
local TAB = Vector2.new(150, 50)
local RIGHT = 410 -- the spread's right column starts here
local SILHOUETTE_COLOR = Color3.fromRGB(28, 26, 40)
local BAD_COLOR = Color3.fromRGB(255, 90, 90)
local GOLD = Color3.fromRGB(255, 215, 60)
local CLAIM_COLORS = { Color3.fromRGB(255, 240, 120), Color3.fromRGB(255, 160, 30) }
local CLAIMED_COLORS = { Color3.fromRGB(140, 245, 120), Color3.fromRGB(40, 175, 60) }
local MISSING_COLORS = { Color3.fromRGB(190, 150, 255), Color3.fromRGB(110, 65, 210) }
local DARK = Color3.fromRGB(60, 55, 80)
local RAINBOW = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 100, 100)),
	ColorSequenceKeypoint.new(0.25, Color3.fromRGB(255, 220, 80)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(110, 240, 130)),
	ColorSequenceKeypoint.new(0.75, Color3.fromRGB(100, 180, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(220, 120, 255)),
})

-- Each rarity's page: its sky (top to bottom) and what moves on it.
local function sky(points: { { number | Color3 } }): ColorSequence
	local keys = {}
	for _, point in points do
		table.insert(keys, ColorSequenceKeypoint.new(point[1] :: number, point[2] :: Color3))
	end
	return ColorSequence.new(keys)
end
local SCENERY: { [string]: { Sky: ColorSequence, Decor: string } } = {
	-- a sunny meadow: sky to a grass horizon
	Common = { Sky = sky({ { 0, Color3.fromRGB(120, 205, 255) }, { 0.6, Color3.fromRGB(200, 240, 255) }, { 0.62, Color3.fromRGB(125, 215, 90) }, { 1, Color3.fromRGB(55, 160, 60) } }), Decor = "Clouds" },
	Uncommon = { Sky = sky({ { 0, Color3.fromRGB(205, 255, 170) }, { 1, Color3.fromRGB(35, 160, 95) } }), Decor = "Leaves" },
	Rare = { Sky = sky({ { 0, Color3.fromRGB(130, 215, 255) }, { 1, Color3.fromRGB(25, 80, 200) } }), Decor = "Bubbles" },
	Legendary = { Sky = sky({ { 0, Color3.fromRGB(255, 240, 150) }, { 1, Color3.fromRGB(240, 130, 25) } }), Decor = "Rays" },
	Mythic = { Sky = sky({ { 0, Color3.fromRGB(255, 140, 225) }, { 1, Color3.fromRGB(90, 30, 160) } }), Decor = "Twinkles" },
	Godly = { Sky = RAINBOW, Decor = "Rainbow" },
}

type Inventory = {
	Parts: { [string]: { [string]: boolean } },
	Claimed: { [string]: number },
}
type Line = { Id: string, Index: number, Zone: string }

local player = Players.LocalPlayer
local panel: Frame? = nil
local content: Frame? = nil
local body: Frame? = nil
local inventory: Inventory = { Parts = {}, Claimed = {} }
local lineIds: { Line } = {} -- the player's lines, by room
local page = Rarities.List[1].Id -- the rarity page shown
local selected: string? = nil -- the brainrot whose spread is open
local claiming = false
local animators: { (t: number, dt: number) -> () } = {} -- what moves on the page
local cleanups: { () -> () } = {} -- orbits and sunbursts to stop on the next render

local Catalog = {}

-- Helpers --------------------------------------------------------------------

local function owns(inv: Inventory, brainrotId: string, partType: string): boolean
	local parts = inv.Parts[brainrotId]
	return parts ~= nil and parts[partType] == true
end

local function ownedCount(inv: Inventory, brainrotId: string): number
	local count = 0
	for _, partType in PART_TYPES do
		if owns(inv, brainrotId, partType) then
			count += 1
		end
	end
	return count
end

local function canClaim(inv: Inventory, brainrotId: string): boolean
	return inv.Claimed[brainrotId] == nil and ownedCount(inv, brainrotId) == #PART_TYPES
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

-- The whole brainrot, the parts you haven't found dark.
local function buildFigure(brainrotId: string): Model
	local figure = Instance.new("Model")
	for _, partType in PART_TYPES do
		local part = BrainrotModels.CreatePart(brainrotId, partType)
		if not owns(inventory, brainrotId, partType) then
			blackout(part)
		end
		part.Parent = figure
	end
	return figure
end

-- A brainrot (or one part) swaying in a viewport, the camera just far enough for all of
-- it to fit (Kit.fitDistance) in a frame `aspect` wide per 1 tall, with a little room.
local FIT_ROOM = 1.08
local function showModel(parent: GuiObject, model: Model, aspect: number, zIndex: number?): ViewportFrame
	local view = Kit.viewport({ Size = UDim2.fromScale(1, 1), ZIndex = zIndex or parent.ZIndex, Parent = parent }, model)
	local camera = view.CurrentCamera :: Camera
	table.insert(cleanups, Kit.orbit(view, model, nil, Kit.fitDistance(model, aspect, camera.FieldOfView) * FIT_ROOM))
	return view
end

-- A rarity's colors on a frame: its gradient, or the turning rainbow for Godly.
local function paintRarity(frame: GuiObject, rarity: Rarities.Rarity, lighten: number)
	if rarity.Id == "Godly" then
		local rainbow = Kit.new("UIGradient", { Color = RAINBOW, Rotation = 45, Parent = frame })
		table.insert(animators, function(_t, dt)
			rainbow.Rotation = (rainbow.Rotation + dt * 60) % 360
		end)
	else
		Kit.gradient(frame, { rarity.Color:Lerp(Kit.White, lighten), rarity.Color:Lerp(Color3.new(0, 0, 0), 0.12) })
	end
end

local function pulse(object: GuiObject, amount: number, speed: number)
	local scale = Kit.new("UIScale", { Parent = object })
	table.insert(animators, function(t)
		scale.Scale = 1 + math.sin(t * speed) * amount
	end)
end

local function lineLabel(line: Line): string
	return `{Zones.Tag(line.Zone)} {line.Index}`
end

-- Data -----------------------------------------------------------------------

local render: () -> ()

local function refresh()
	local ok, result = pcall(function()
		return Remotes.Function("GetInventory"):InvokeServer()
	end)
	if ok and typeof(result) == "table" then
		inventory = { Parts = result.Parts or {}, Claimed = result.Claimed or {} }
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

-- Actions --------------------------------------------------------------------

local function claim(brainrot: Brainrots.Brainrot)
	if claiming then
		return
	end
	claiming = true
	local remote = Remotes.Function("ClaimBrainrot")
	local ok, gems = pcall(remote.InvokeServer, remote, brainrot.Id)
	claiming = false
	if not (ok and typeof(gems) == "number") then
		Kit.toast("Try again!", BAD_COLOR, "Warning")
		return
	end
	inventory.Claimed[brainrot.Id] = os.time() -- (the server's update follows)
	render()
	Celebration.Show(brainrot.Id, gems)
end

local function equipOnLine(line: Line, brainrot: Brainrots.Brainrot)
	local remote = Remotes.Function("EquipBrainrot")
	local ok, success, reason = pcall(remote.InvokeServer, remote, line.Id, brainrot.Id)
	if ok and success then
		Kit.toast(`{lineLabel(line)} builds {brainrot.Name}!`, Color3.fromRGB(110, 240, 110), "Factory")
	elseif reason == "TooFar" then
		Kit.toast("Walk up to that line!", BAD_COLOR, "Factory")
	else
		Kit.toast("Its parts are on another line!", BAD_COLOR, "Puzzle")
	end
end

-- Morph or gadget on/off (nil turns it off), then redraw once the server confirms.
local function setChoice(remoteName: string, brainrotId: string?)
	local remote = Remotes.Function(remoteName)
	local ok, done = pcall(remote.InvokeServer, remote, brainrotId)
	if not (ok and done) then
		Kit.toast("Try again!", BAD_COLOR, "Warning")
	end
	task.wait(0.15) -- let the Morph/Gadget attribute replicate
	render()
end

-- The page -------------------------------------------------------------------

-- The rarity tabs along the top: the page's own raised and rimmed in gold, a "!" on
-- the ones with a sticker to claim.
local function renderTabs(parent: Frame)
	local index = 0
	for _, rarity in Rarities.List do
		local list = Brainrots.ByRarity[rarity.Id] or {}
		if #list == 0 then
			continue
		end
		index += 1
		local claimedHere, ready = 0, false
		for _, brainrot in list do
			if inventory.Claimed[brainrot.Id] then
				claimedHere += 1
			end
			ready = ready or canClaim(inventory, brainrot.Id)
		end
		local chosen = rarity.Id == page
		local tab = Kit.new("TextButton", {
			AutoButtonColor = false,
			Text = "",
			Position = UDim2.fromOffset(16 + (index - 1) * (TAB.X + 8), if chosen then 2 else 10),
			Size = UDim2.fromOffset(TAB.X, if chosen then TAB.Y + 10 else TAB.Y),
			BackgroundColor3 = Kit.White,
			ZIndex = if chosen then 4 else 2,
			Parent = parent,
		})
		Kit.corner(tab, 14)
		Kit.stroke(tab, if chosen then 5 else 3.5, if chosen then GOLD else nil)
		paintRarity(tab, rarity, 0.35)
		Kit.stripes(tab, 0.82, 14)
		Kit.shine(tab, 10)
		Kit.text({ Text = string.upper(rarity.Id), Position = UDim2.fromOffset(6, 5), Size = UDim2.new(1, -12, 0, 24), StrokeThickness = 2.5, ZIndex = tab.ZIndex, Parent = tab })
		Kit.text({ Text = `{claimedHere}/{#list}`, Position = UDim2.fromOffset(6, 29), Size = UDim2.new(1, -12, 0, 17), StrokeThickness = 2, ZIndex = tab.ZIndex, Parent = tab })
		if ready then
			local badge = Kit.text({
				Text = "!",
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(1, -6, 0, 6),
				Size = UDim2.fromOffset(30, 30),
				BackgroundTransparency = 0,
				BackgroundColor3 = GOLD,
				StrokeThickness = 2,
				ZIndex = tab.ZIndex + 1,
				Parent = tab,
			})
			Kit.new("UICorner", { CornerRadius = UDim.new(0.5, 0), Parent = badge })
			Kit.stroke(badge, 3)
			pulse(badge, 0.15, 6)
		end
		tab.Activated:Connect(function()
			Kit.click()
			page = rarity.Id
			selected = nil
			render()
		end)
	end
end

-- What moves on the page: clouds drifting over the meadow, leaves and bubbles rising,
-- a sunburst behind the stickers, twinkles, the turning rainbow.
local function decorate(sheet: Frame, decor: string, gradient: UIGradient)
	local random = Random.new(#decor)
	if decor == "Clouds" then
		for index = 1, 4 do
			local cloud = Kit.new("Frame", { Size = UDim2.fromOffset(150, 56), BackgroundTransparency = 1, ZIndex = 1, Parent = sheet })
			for _, puff in { { 0, 18, 64 }, { 40, 0, 72 }, { 86, 14, 60 } } do
				local ball = Kit.new("Frame", { Position = UDim2.fromOffset(puff[1], puff[2]), Size = UDim2.fromOffset(puff[3], puff[3] * 0.62), BackgroundColor3 = Kit.White, BackgroundTransparency = 0.15, ZIndex = 1, Parent = cloud })
				Kit.new("UICorner", { CornerRadius = UDim.new(0.5, 0), Parent = ball })
			end
			local y, speed, start = random:NextNumber(10, 150), random:NextNumber(10, 22), index * 260
			table.insert(animators, function(t)
				cloud.Position = UDim2.fromOffset((start + t * speed) % (PAGE.X + 200) - 170, y)
			end)
		end
	elseif decor == "Leaves" or decor == "Bubbles" then
		local bubbles = decor == "Bubbles"
		for _ = 1, 14 do
			local size = random:NextNumber(14, if bubbles then 40 else 30)
			local dot = Kit.new("Frame", {
				Size = UDim2.fromOffset(size, size),
				BackgroundColor3 = if bubbles then Kit.White else Color3.fromRGB(220, 255, 180),
				BackgroundTransparency = if bubbles then 0.82 else 0.45,
				ZIndex = 1,
				Parent = sheet,
			})
			Kit.new("UICorner", { CornerRadius = UDim.new(if bubbles then 0.5 else 0.2, 0), Parent = dot })
			if bubbles then
				Kit.new("UIStroke", { Thickness = 2, Color = Kit.White, Transparency = 0.3, Parent = dot })
			end
			local x, speed, start, phase = random:NextNumber(0, PAGE.X), random:NextNumber(18, 40), random:NextNumber(0, PAGE.Y), random:NextNumber(0, 6)
			table.insert(animators, function(t)
				local y = PAGE.Y + 40 - (start + t * speed) % (PAGE.Y + 80)
				dot.Position = UDim2.fromOffset(x + math.sin(t * 1.3 + phase) * 14, y)
				dot.Rotation = if bubbles then 0 else (t * 40 + phase * 50) % 360
			end)
		end
	elseif decor == "Rays" then
		table.insert(cleanups, Kit.rays(sheet, Color3.fromRGB(255, 250, 200), 1100, 1))
	end
	if decor == "Twinkles" or decor == "Rainbow" or decor == "Rays" then
		for _ = 1, 16 do
			local spark = Kit.icon("Sparkle", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromOffset(random:NextNumber(20, PAGE.X - 20), random:NextNumber(20, PAGE.Y - 20)),
				Size = UDim2.fromOffset(random:NextNumber(18, 36), random:NextNumber(18, 36)),
				ZIndex = 1,
				Parent = sheet,
			})
			local phase = random:NextNumber(0, 6)
			table.insert(animators, function(t)
				spark.ImageTransparency = 1 - (math.sin(t * 2.5 + phase) + 1) / 2
				spark.Rotation = (t * 30 + phase * 40) % 360
			end)
		end
	end
	if decor == "Rainbow" then
		table.insert(animators, function(_t, dt)
			gradient.Rotation = (gradient.Rotation + dt * 25) % 360
		end)
	end
end

-- A sticker: a white die-cut card, the brainrot big on its rarity's colors, its name,
-- a dot per part and what's next for it.
local function renderCard(parent: Instance, order: number, brainrot: Brainrots.Brainrot)
	local rarity = Rarities.ById[brainrot.Rarity]
	local count = ownedCount(inventory, brainrot.Id)
	local discovered = count > 0
	local claimed = inventory.Claimed[brainrot.Id] ~= nil
	local ready = canClaim(inventory, brainrot.Id)

	local card = Kit.new("TextButton", {
		AutoButtonColor = false,
		Text = "",
		LayoutOrder = order,
		Size = UDim2.fromOffset(CARD.X, CARD.Y),
		BackgroundColor3 = Kit.White,
		ZIndex = 3,
		Parent = parent,
	})
	Kit.corner(card, 26)
	Kit.stroke(card, 5, if ready then GOLD else nil)
	Kit.gradient(card, { Kit.White, Color3.fromRGB(232, 236, 248) })
	if ready then
		Kit.neonRim(card, GOLD, 26, 4)
	end

	local face = Kit.new("Frame", {
		Position = UDim2.fromOffset(10, 10),
		Size = UDim2.new(1, -20, 0, 296),
		BackgroundColor3 = Kit.White,
		ZIndex = 3,
		Parent = card,
	})
	Kit.corner(face, 18)
	Kit.stroke(face, 3)
	if discovered then
		paintRarity(face, rarity, 0.5)
	else
		Kit.gradient(face, { Color3.fromRGB(170, 170, 190), Color3.fromRGB(110, 110, 130) })
	end
	Kit.stripes(face, 0.85, 18)
	showModel(face, buildFigure(brainrot.Id), (CARD.X - 20) / 296, 4)
	Kit.shine(face, 14)
	if claimed then
		Kit.icon("Check", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -8, 0, 8), Size = UDim2.fromOffset(52, 52), Rotation = 10, ZIndex = 6, Parent = card })
	end

	Kit.text({ Text = if discovered then brainrot.Name else "???", Position = UDim2.fromOffset(8, 312), Size = UDim2.new(1, -16, 0, 34), StrokeThickness = 3, ZIndex = 4, Parent = card })

	-- a dot per part: green with a tick once it's yours
	local dots = Kit.new("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 352), Size = UDim2.fromOffset(176, 38), BackgroundTransparency = 1, ZIndex = 4, Parent = card })
	Kit.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = dots })
	for index, partType in PART_TYPES do
		local has = owns(inventory, brainrot.Id, partType)
		local dot = Kit.new("Frame", { LayoutOrder = index, Size = UDim2.fromOffset(36, 36), BackgroundColor3 = Kit.White, ZIndex = 4, Parent = dots })
		Kit.new("UICorner", { CornerRadius = UDim.new(0.5, 0), Parent = dot })
		Kit.stroke(dot, 3)
		Kit.gradient(dot, if has then CLAIMED_COLORS else { DARK:Lerp(Kit.White, 0.2), DARK })
		if has then
			Kit.icon("Check", { Position = UDim2.fromOffset(4, 4), Size = UDim2.new(1, -8, 1, -8), ZIndex = 5, Parent = dot })
		else
			Kit.text({ Text = string.sub(partType, 1, 1), Position = UDim2.fromOffset(6, 6), Size = UDim2.new(1, -12, 1, -12), TextColor3 = Color3.fromRGB(170, 165, 190), StrokeThickness = 1.5, ZIndex = 5, Parent = dot })
		end
	end

	-- what's next: CLAIM!, claimed (its morph and gadget), or the parts still missing
	local pill = Kit.new("Frame", { Position = UDim2.fromOffset(14, 398), Size = UDim2.new(1, -28, 0, 44), BackgroundColor3 = Kit.White, ZIndex = 4, Parent = card })
	Kit.corner(pill, 14)
	Kit.stroke(pill, 3.5)
	Kit.gradient(pill, if ready then CLAIM_COLORS elseif claimed then CLAIMED_COLORS else MISSING_COLORS)
	Kit.shine(pill, 10)
	if ready then
		Kit.iconText({ Position = UDim2.fromOffset(4, 6), Size = UDim2.new(1, -8, 0, 32), ZIndex = 5, Parent = pill }, "Gift", "CLAIM!")
		pulse(pill, 0.06, 5)
	elseif claimed then
		local row = Kit.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 5, Parent = pill })
		Kit.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 10), Parent = row })
		Kit.icon("Mask", { Size = UDim2.fromOffset(40, 40), ZIndex = 5, Parent = row })
		local gadget = Gadgets[brainrot.Id]
		if gadget then
			Kit.icon(gadget.Icon or "Gift", { Size = UDim2.fromOffset(38, 38), ZIndex = 5, Parent = row })
		end
	else
		Kit.iconText({ Position = UDim2.fromOffset(4, 7), Size = UDim2.new(1, -8, 0, 30), ZIndex = 5, Parent = pill }, "Puzzle", `{count}/4 PARTS`)
	end

	local scale = Kit.new("UIScale", { Parent = card })
	card.MouseEnter:Connect(function()
		TweenService:Create(scale, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1.04 }):Play()
	end)
	card.MouseLeave:Connect(function()
		TweenService:Create(scale, TweenInfo.new(0.15), { Scale = 1 }):Play()
	end)
	card.Activated:Connect(function()
		Kit.click()
		selected = brainrot.Id
		render()
	end)
end

local function renderStickers(sheet: Frame)
	local row = Kit.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(1, -24, 0, CARD.Y + 12),
		BackgroundTransparency = 1,
		ZIndex = 3,
		Parent = sheet,
	})
	Kit.new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 24),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = row,
	})
	for order, brainrot in Brainrots.ByRarity[page] or {} do
		renderCard(row, order, brainrot)
	end
end

-- The spread --------------------------------------------------------------------

-- One of its 4 parts: the part turning (dark if you're missing it), its name and a tick
-- or a lock.
local function renderSlot(parent: Frame, brainrot: Brainrots.Brainrot, partType: string, index: number)
	local rarity = Rarities.ById[brainrot.Rarity]
	local has = owns(inventory, brainrot.Id, partType)
	local slot = Kit.new("Frame", {
		Position = UDim2.fromOffset(RIGHT + (index - 1) * 136, 162),
		Size = UDim2.fromOffset(126, 126),
		BackgroundColor3 = Kit.White,
		ZIndex = 3,
		Parent = parent,
	})
	Kit.corner(slot, 18)
	Kit.stroke(slot, 4)
	if has then
		paintRarity(slot, rarity, 0.55)
	else
		Kit.gradient(slot, { DARK:Lerp(Kit.White, 0.25), DARK })
	end
	Kit.stripes(slot, 0.85, 18)
	local model = BrainrotModels.CreatePart(brainrot.Id, partType)
	if not has then
		blackout(model)
	end
	local holder = Kit.new("Frame", { Position = UDim2.fromOffset(6, 4), Size = UDim2.new(1, -12, 0, 88), BackgroundTransparency = 1, ZIndex = 4, Parent = slot })
	showModel(holder, model, 114 / 88, 4)
	Kit.text({ Text = string.upper(partType), Position = UDim2.fromOffset(6, 94), Size = UDim2.new(1, -12, 0, 26), StrokeThickness = 2.5, ZIndex = 5, Parent = slot })
	Kit.icon(if has then "Check" else "Lock", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -6, 0, 6), Size = UDim2.fromOffset(38, 38), ZIndex = 6, Parent = slot })
end

local function renderSpread(sheet: Frame, brainrot: Brainrots.Brainrot)
	local rarity = Rarities.ById[brainrot.Rarity]
	local count = ownedCount(inventory, brainrot.Id)
	local claimed = inventory.Claimed[brainrot.Id] ~= nil
	local ready = canClaim(inventory, brainrot.Id)
	local gadget = Gadgets[brainrot.Id]
	local width = PAGE.X - RIGHT - 24

	local back = Kit.button({ Position = UDim2.fromOffset(16, 12), Size = UDim2.fromOffset(132, 46), ZIndex = 6, Parent = sheet }, Kit.Colors.Grey, "BACK", function()
		selected = nil
		render()
	end, "Arrow")
	local arrow = back:FindFirstChild("Icon") :: ImageLabel?
	if arrow then
		arrow.Rotation = 180
	end

	-- the big sticker
	local big = Kit.new("Frame", { Position = UDim2.fromOffset(24, 68), Size = UDim2.fromOffset(360, 424), BackgroundColor3 = Kit.White, ZIndex = 3, Parent = sheet })
	Kit.corner(big, 28)
	Kit.stroke(big, 5, if ready then GOLD else nil)
	local face = Kit.new("Frame", { Position = UDim2.fromOffset(12, 12), Size = UDim2.new(1, -24, 1, -24), BackgroundColor3 = Kit.White, ZIndex = 3, Parent = big })
	Kit.corner(face, 20)
	Kit.stroke(face, 3)
	if count > 0 then
		paintRarity(face, rarity, 0.5)
	else
		Kit.gradient(face, { Color3.fromRGB(170, 170, 190), Color3.fromRGB(110, 110, 130) })
	end
	Kit.stripes(face, 0.85, 20)
	showModel(face, buildFigure(brainrot.Id), 336 / 400, 4)
	Kit.shine(face, 16)
	if claimed then
		Kit.icon("Check", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -10, 0, 10), Size = UDim2.fromOffset(72, 72), Rotation = 10, ZIndex = 6, Parent = big })
	end

	-- its name, rarity and parts
	Kit.text({
		Text = if count > 0 then brainrot.Name else "???",
		Position = UDim2.fromOffset(RIGHT, 14),
		Size = UDim2.fromOffset(width, 56),
		TextXAlignment = Enum.TextXAlignment.Left,
		StrokeThickness = 4,
		ZIndex = 4,
		Parent = sheet,
	})
	local tag = Kit.new("Frame", { Position = UDim2.fromOffset(RIGHT, 78), Size = UDim2.fromOffset(300, 42), BackgroundColor3 = Kit.White, ZIndex = 4, Parent = sheet })
	Kit.corner(tag, 14)
	Kit.stroke(tag, 3.5)
	paintRarity(tag, rarity, 0.3)
	Kit.shine(tag, 10)
	Kit.text({ Text = string.upper(rarity.Id), Position = UDim2.fromOffset(12, 6), Size = UDim2.fromOffset(150, 30), TextXAlignment = Enum.TextXAlignment.Left, StrokeThickness = 3, ZIndex = 5, Parent = tag })
	Kit.stars({ AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(150, 30), ZIndex = 5, Parent = tag }, rarity.Rank, "Right")
	Kit.text({ Text = `PARTS {count}/4`, Position = UDim2.fromOffset(RIGHT, 128), Size = UDim2.fromOffset(240, 28), TextXAlignment = Enum.TextXAlignment.Left, StrokeThickness = 3, ZIndex = 4, Parent = sheet })
	for index, partType in PART_TYPES do
		renderSlot(sheet, brainrot, partType, index)
	end

	-- the one button
	local top = 304
	if ready then
		-- what claiming gets you, then CLAIM! over a sunburst
		local rewards = Kit.new("Frame", { Position = UDim2.fromOffset(RIGHT, top), Size = UDim2.fromOffset(width, 50), BackgroundTransparency = 1, ZIndex = 4, Parent = sheet })
		Kit.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder, Parent = rewards })
		local chips = { { "Mask", "MORPH" } }
		if gadget then
			table.insert(chips, { gadget.Icon or "Gift", "GADGET" })
		end
		table.insert(chips, { "Gem", `+{Format.Number(rarity.CompletionGems)}` })
		for order, chip in chips do
			local box = Kit.new("Frame", { LayoutOrder = order, Size = UDim2.fromOffset((width - 20) / 3, 50), BackgroundColor3 = Kit.White, ZIndex = 4, Parent = rewards })
			Kit.corner(box, 14)
			Kit.stroke(box, 3)
			Kit.gradient(box, { Kit.White, Color3.fromRGB(225, 230, 245) })
			Kit.iconText({ Position = UDim2.fromOffset(4, 9), Size = UDim2.new(1, -8, 0, 32), ZIndex = 5, Parent = box }, chip[1], chip[2], Color3.fromRGB(60, 50, 80))
		end
		local glow = Kit.new("Frame", { Position = UDim2.fromOffset(RIGHT + width / 2, top + 120), Size = UDim2.fromOffset(1, 1), BackgroundTransparency = 1, ZIndex = 3, Parent = sheet })
		table.insert(cleanups, Kit.rays(glow, GOLD, 520, 3))
		local button = Kit.button({ Position = UDim2.fromOffset(RIGHT, top + 66), Size = UDim2.fromOffset(width, 110), ZIndex = 5, Parent = sheet }, CLAIM_COLORS, "CLAIM!", function()
			task.spawn(claim, brainrot)
		end, "Gift")
		Kit.stripes(button, 0.8, 14, 5)
		pulse(button, 0.03, 4)
	elseif claimed then
		local morphed = player:GetAttribute("Morph") == brainrot.Id
		local half = (width - 10) / 2
		Kit.button({ Position = UDim2.fromOffset(RIGHT, top), Size = UDim2.fromOffset(if gadget then half else width, 64), ZIndex = 5, Parent = sheet }, Kit.Colors.Purple, if morphed then "UNMORPH" else "MORPH!", function()
			setChoice("SetMorph", if morphed then nil else brainrot.Id)
		end, "Mask")
		if gadget then
			local equipped = player:GetAttribute("Gadget") == brainrot.Id
			Kit.button({ Position = UDim2.fromOffset(RIGHT + half + 10, top), Size = UDim2.fromOffset(half, 64), ZIndex = 5, Parent = sheet }, if equipped then Kit.Colors.Grey else Kit.Colors.Green, if equipped then "UNEQUIP" else "GADGET!", function()
				setChoice("EquipGadget", if equipped then nil else brainrot.Id)
			end, if equipped then "Close" else gadget.Icon or "Gift")
			Kit.text({ Text = `{gadget.Name}: {gadget.Description or ""}`, Position = UDim2.fromOffset(RIGHT, top + 70), Size = UDim2.fromOffset(width, 22), TextXAlignment = Enum.TextXAlignment.Left, StrokeThickness = 2, ZIndex = 4, Parent = sheet })
		end
		-- build it on a line: a button per line, named by its room
		Kit.text({ Text = "BUILD IT ON A LINE", Position = UDim2.fromOffset(RIGHT, top + 98), Size = UDim2.fromOffset(width, 26), TextXAlignment = Enum.TextXAlignment.Left, StrokeThickness = 3, ZIndex = 4, Parent = sheet })
		if #lineIds == 0 then
			Kit.text({ Text = "Buy an assembly line first!", Position = UDim2.fromOffset(RIGHT, top + 130), Size = UDim2.fromOffset(width, 26), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 4, Parent = sheet })
		else
			local grid = Kit.new("ScrollingFrame", {
				Position = UDim2.fromOffset(RIGHT - 4, top + 126),
				Size = UDim2.fromOffset(width + 8, PAGE.Y - top - 132),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				ScrollBarThickness = 6,
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
				CanvasSize = UDim2.new(),
				ZIndex = 4,
				Parent = sheet,
			})
			Kit.new("UIPadding", { PaddingLeft = UDim.new(0, 4), PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4), Parent = grid })
			Kit.new("UIGridLayout", { CellSize = UDim2.fromOffset((width - 3 * 8 - 6) / 4, 42), CellPadding = UDim2.fromOffset(8, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = grid })
			for order, line in lineIds do
				Kit.button({ LayoutOrder = order, ZIndex = 5, Parent = grid }, Kit.Colors.Green, lineLabel(line), function()
					equipOnLine(line, brainrot)
				end, "Factory")
			end
		end
	else
		-- parts still missing: where they come from, and a Roll right here
		Kit.iconText({ Position = UDim2.fromOffset(RIGHT, top + 6), Size = UDim2.fromOffset(width, 34), ZIndex = 4, Parent = sheet }, "Lock", `Find {4 - count} more {if 4 - count == 1 then "part" else "parts"} to claim it!`)
		Kit.iconText({ Position = UDim2.fromOffset(RIGHT, top + 50), Size = UDim2.fromOffset(width, 30), ZIndex = 4, Parent = sheet }, "Gift", "Rolls and map boxes drop parts")
		local rolls = player:GetAttribute("Rolls") or 0
		Kit.button({ Position = UDim2.fromOffset(RIGHT, top + 98), Size = UDim2.fromOffset(width, 84), ZIndex = 5, Parent = sheet }, if rolls > 0 then Kit.Colors.Rolls else Kit.Colors.Grey, if rolls > 0 then `OPEN A ROLL ({rolls})` else "NO ROLLS LEFT", function()
			if (player:GetAttribute("Rolls") or 0) > 0 then
				if panel then
					Kit.close(panel)
				end
				Loot.OpenRoll()
			else
				Kit.toast("Grab boxes on the map!", BAD_COLOR, "Gift")
			end
		end, "Roll")
	end
end

-- Rendering --------------------------------------------------------------------

local function stopMotion()
	for _, stop in cleanups do
		stop()
	end
	table.clear(cleanups)
	table.clear(animators)
end

render = function()
	stopMotion()
	if body then
		body:Destroy()
	end
	local frame = Kit.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 2, Parent = content })
	body = frame

	-- the album's count in its title
	local claimedAll = 0
	for _ in inventory.Claimed do
		claimedAll += 1
	end
	local header = panel and panel:FindFirstChild("Header")
	local title = header and header:FindFirstChild("Title")
	if title and title:IsA("TextLabel") then
		title.Text = `ALBUM  {claimedAll}/{#Brainrots.List}`
	end

	renderTabs(frame)
	local scenery = SCENERY[page] or SCENERY.Common
	local sheet = Kit.new("Frame", {
		Position = UDim2.fromOffset(16, 66),
		Size = UDim2.fromOffset(PAGE.X, PAGE.Y),
		BackgroundColor3 = Kit.White,
		ClipsDescendants = true,
		ZIndex = 1,
		Parent = frame,
	})
	Kit.corner(sheet, 22)
	Kit.stroke(sheet, 4)
	local gradient = Kit.new("UIGradient", { Color = scenery.Sky, Rotation = if scenery.Decor == "Rainbow" then 45 else 90, Parent = sheet })
	Kit.stripes(sheet, 0.9, 22, 1)
	decorate(sheet, scenery.Decor, gradient)

	local brainrot = selected and Brainrots.ById[selected]
	if brainrot then
		renderSpread(sheet, brainrot)
	else
		renderStickers(sheet)
	end
end

-- The page and stickers move while the album is open.
RunService.RenderStepped:Connect(function(dt)
	if not (panel and panel.Visible) or #animators == 0 then
		return
	end
	local t = os.clock()
	for _, animate in animators do
		animate(t, dt)
	end
end)

-- Public API -----------------------------------------------------------------

-- How many brainrots in `inv` (an Inventory sent by the server) can be claimed.
function Catalog.ClaimableCount(inv: any): number
	if typeof(inv) ~= "table" then
		return 0
	end
	local view: Inventory = { Parts = inv.Parts or {}, Claimed = inv.Claimed or {} }
	local count = 0
	for _, brainrot in Brainrots.List do
		if canClaim(view, brainrot.Id) then
			count += 1
		end
	end
	return count
end

function Catalog.Open()
	if not panel then
		local newPanel, newContent = Kit.modal("Catalog", "ALBUM", Kit.Hues.Blue, SIZE, "Album")
		panel, content = newPanel, newContent
		-- closed: stop what moves and drop the stickers (they're redrawn on opening)
		newPanel:GetPropertyChangedSignal("Visible"):Connect(function()
			if not newPanel.Visible then
				stopMotion()
				if body then
					body:Destroy()
					body = nil
				end
			end
		end)
	end
	selected = nil
	Kit.open(panel :: Frame)
	render() -- (what it knew last, until the server answers)
	task.spawn(function()
		refresh()
		-- open on the first page with a sticker to claim
		for _, rarity in Rarities.List do
			for _, brainrot in Brainrots.ByRarity[rarity.Id] or {} do
				if canClaim(inventory, brainrot.Id) then
					if page ~= rarity.Id then
						page = rarity.Id
						render()
					end
					return
				end
			end
		end
	end)
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
