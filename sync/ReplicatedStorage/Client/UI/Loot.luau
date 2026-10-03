--[[
	Loot
	Opens Rolls and shows loot results (GDD §5). The server rolls the result; the client
	opens straight onto it: the screen dims, flashes in the rarity's color, and a reveal
	card pops up with the part won (no spinning reel: the user, 2026-10-03, before the
	release). Results queue up, so grabbing several boxes shows them one after another;
	while they pile up (a bought box storm), the rest pop into a quick feed on the right
	instead (a new Rare+ part still gets its card). With the Fast Open pass, everything
	but a new Rare+ part goes straight to the feed. The Daily Wheel uses the same overlay.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local BrainrotModels = require(Shared:WaitForChild("BrainrotModels"))
local Brainrots = require(Config:WaitForChild("Brainrots"))
local Format = require(Shared:WaitForChild("Format"))
local Rarities = require(Config:WaitForChild("Rarities"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Sounds = require(Config:WaitForChild("Sounds"))
local Kit = require(script.Parent:WaitForChild("Kit"))
local LineMenu = require(script.Parent:WaitForChild("LineMenu"))
local Upsell = require(script.Parent:WaitForChild("Upsell"))

local AUTO_CLOSE = 8 -- seconds before a reveal closes itself
local BIG_RANK = 3 -- Rare and up get the bigger reveal
local CURRENCY_ICONS = { Coins = "💰", Gems = "💎" }
local NEW_COLOR = Color3.fromRGB(120, 245, 110)
local BAD_COLOR = Color3.fromRGB(255, 90, 90)
local QUICK_LINGER = 3 -- seconds the quick feed stays on after its last result
local QUICK_GAP = 0.15 -- seconds between quick results
local FEED_HOLD = 2.6 -- seconds a quick result stays in the feed
local FEED_MAX = 6 -- quick results shown at once

export type Result = {
	Source: string, -- "Roll" | "Box"
	BoxRarity: string?,
	BrainrotId: string,
	PartType: string,
	Rarity: string,
	New: boolean,
	Currency: string?,
	Amount: number?,
}

local player = Players.LocalPlayer
local queue: { Result } = {}
local playing = false
local rolling = false
local lastQuick = -math.huge
local feed: Frame? = nil
local feedOrder = 0

local Loot = {}

-- Reveal ---------------------------------------------------------------------

-- Shows the result card and yields until it's closed.
local function reveal(parent: Frame, result: Result)
	local rarity = Rarities.ById[result.Rarity]
	local brainrot = Brainrots.ById[result.BrainrotId]
	local big = rarity.Rank >= BIG_RANK
	local closed = false
	local stopRays = Kit.rays(parent, rarity.Color, 620, 31)

	local card = Kit.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(440, 520),
		BackgroundColor3 = Kit.White,
		ZIndex = 32,
		Parent = parent,
	})
	Kit.corner(card, 26)
	Kit.stroke(card, 7, rarity.Color)
	Kit.gradient(card, Kit.Colors.Panel)
	Kit.pop(card, -0.5)

	local boxRarity = result.BoxRarity and Rarities.ById[result.BoxRarity]
	if boxRarity and rarity.Rank > boxRarity.Rank then
		Kit.text({
			Text = "⬆ RARITY UP! ⬆",
			TextColor3 = rarity.Color,
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 0, -12),
			Size = UDim2.fromOffset(380, 50),
			StrokeThickness = 4,
			ZIndex = 33,
			Parent = card,
		})
	end

	Kit.text({
		Text = if result.New then "NEW PART!" else "DUPLICATE",
		TextColor3 = if result.New then NEW_COLOR else Kit.White,
		Position = UDim2.fromOffset(20, 16),
		Size = UDim2.new(1, -40, 0, 56),
		StrokeThickness = 4,
		ZIndex = 33,
		Parent = card,
	})

	local model = BrainrotModels.CreatePart(result.BrainrotId, result.PartType)
	local viewport = Kit.viewport({
		Position = UDim2.fromOffset(40, 78),
		Size = UDim2.fromOffset(360, 230),
		ZIndex = 33,
		Parent = card,
	}, model)
	local stopOrbit = Kit.orbit(viewport, model)

	Kit.text({ Text = brainrot.Name, Position = UDim2.fromOffset(20, 314), Size = UDim2.new(1, -40, 0, 44), ZIndex = 33, Parent = card })
	Kit.text({
		Text = string.rep("⭐", rarity.Rank),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0, 78),
		Size = UDim2.fromOffset(240, 34),
		StrokeThickness = 0,
		ZIndex = 35,
		Parent = card,
	})
	Kit.text({
		Text = `{string.upper(result.PartType)}  ·  {string.upper(rarity.Id)}`,
		TextColor3 = rarity.Color,
		Position = UDim2.fromOffset(20, 358),
		Size = UDim2.new(1, -40, 0, 32),
		ZIndex = 33,
		Parent = card,
	})
	local reward = if result.New
		then "Equip it on a line!"
		else `+{Format.Number(result.Amount or 0)} {CURRENCY_ICONS[result.Currency or "Coins"] or ""}`
	Kit.text({
		Text = reward,
		TextColor3 = if result.New then Kit.White else Color3.fromRGB(255, 220, 80),
		Position = UDim2.fromOffset(20, 394),
		Size = UDim2.new(1, -40, 0, 36),
		ZIndex = 33,
		Parent = card,
	})

	local function close()
		closed = true
	end
	if result.New then
		Kit.button({ Position = UDim2.fromOffset(28, 446), Size = UDim2.fromOffset(180, 56), ZIndex = 34, Parent = card }, Kit.Colors.Purple, "EQUIP", function()
			close()
			LineMenu.Open(nil, result.PartType)
		end)
		Kit.button({ Position = UDim2.fromOffset(232, 446), Size = UDim2.fromOffset(180, 56), ZIndex = 34, Parent = card }, Kit.Colors.Green, "AWESOME!", close)
	else
		Kit.button({
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, 446),
			Size = UDim2.fromOffset(220, 56),
			ZIndex = 34,
			Parent = card,
		}, Kit.Colors.Green, "AWESOME!", close)
	end

	Kit.playSound(if big then Sounds.RevealBig else Sounds.Reveal, 0.5)
	if big then
		-- a little shake for the rare ones
		task.spawn(function()
			local home = card.Position
			for k = 1, 8 do
				card.Position = home + UDim2.fromOffset(math.random(-8, 8) * (1 - k / 9), math.random(-6, 6) * (1 - k / 9))
				task.wait(0.03)
			end
			card.Position = home
		end)
	end
	if result.New or big then
		local colors = { rarity.Color, Color3.fromRGB(255, 220, 60), Color3.fromRGB(120, 220, 255), Color3.fromRGB(255, 120, 220) }
		Kit.confetti(parent, colors, if big then 60 else 30)
	end

	local deadline = os.clock() + AUTO_CLOSE
	while not closed and os.clock() < deadline do
		task.wait(0.05)
	end
	stopOrbit()
	stopRays()
end

-- Playback -------------------------------------------------------------------

-- A dim full-screen overlay that flashes `color`, for a reveal to sit on. The caller
-- destroys it when the reveal is done.
function Loot.Overlay(color: Color3): Frame
	local screen = Kit.new("Frame", {
		Name = "LootOverlay",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(20, 10, 40),
		BackgroundTransparency = 0.4,
		Active = true,
		ZIndex = 30,
		Parent = Kit.getGui(),
	})
	Kit.playSound(Sounds.Whoosh, 0.25, 1.4)
	Kit.flash(screen, color)
	return screen
end

local function play(result: Result)
	local screen = Loot.Overlay(Rarities.ById[result.Rarity].Color)
	reveal(screen, result)
	screen:Destroy()
end

-- The quick feed: a column of small result cards on the right, newest at the bottom.
local function getFeed(): Frame
	if feed and feed.Parent then
		return feed
	end
	local column = Kit.new("Frame", {
		Name = "LootFeed",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -16, 0.55, 0),
		Size = UDim2.fromOffset(330, FEED_MAX * 70),
		BackgroundTransparency = 1,
		ZIndex = 20,
		Parent = Kit.getGui(),
	})
	Kit.new("UIListLayout", {
		Padding = UDim.new(0, 6),
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = column,
	})
	feed = column
	return column
end

-- One result in the quick feed: no reel, no overlay; it slides in, then fades.
local function quickShow(result: Result)
	local rarity = Rarities.ById[result.Rarity]
	local brainrot = Brainrots.ById[result.BrainrotId]
	local column = getFeed()
	feedOrder += 1
	local card = Kit.new("Frame", { LayoutOrder = feedOrder, Size = UDim2.fromOffset(330, 64), BackgroundColor3 = Kit.White, ZIndex = 20, Parent = column })
	Kit.corner(card, 14)
	Kit.stroke(card, 3)
	Kit.gradient(card, { rarity.Color:Lerp(Kit.White, 0.3), rarity.Color:Lerp(Color3.new(0, 0, 0), 0.3) })
	Kit.shine(card, 10)
	Kit.text({
		Text = if result.New then "✨ NEW PART!" else `+{Format.Number(result.Amount or 0)} {CURRENCY_ICONS[result.Currency or "Coins"] or ""}`,
		TextColor3 = if result.New then NEW_COLOR else Color3.fromRGB(255, 225, 90),
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromOffset(12, 5),
		Size = UDim2.new(1, -90, 0, 28),
		StrokeThickness = 2.5,
		ZIndex = 21,
		Parent = card,
	})
	Kit.text({
		Text = `{brainrot.Name} · {string.upper(result.PartType)}`,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromOffset(12, 34),
		Size = UDim2.new(1, -24, 0, 24),
		StrokeThickness = 2,
		ZIndex = 21,
		Parent = card,
	})
	Kit.text({
		Text = string.rep("⭐", rarity.Rank),
		TextXAlignment = Enum.TextXAlignment.Right,
		Position = UDim2.new(1, -96, 0, 6),
		Size = UDim2.fromOffset(84, 22),
		StrokeThickness = 0,
		ZIndex = 21,
		Parent = card,
	})
	Kit.pop(card, 0.25)
	Kit.playSound(if result.New then Sounds.Reveal else Sounds.Coin, 0.3, 1.05 + math.random() * 0.2)
	-- only the newest FEED_MAX stay
	local cards = {}
	for _, child in column:GetChildren() do
		if child:IsA("Frame") then
			table.insert(cards, child)
		end
	end
	table.sort(cards, function(a, b)
		return a.LayoutOrder < b.LayoutOrder
	end)
	for index = 1, #cards - FEED_MAX do
		cards[index]:Destroy()
	end
	task.delay(FEED_HOLD, function()
		if card.Parent then
			TweenService:Create(card, TweenInfo.new(0.3), { BackgroundTransparency = 1 }):Play()
			for _, child in card:GetDescendants() do
				if child:IsA("TextLabel") then
					TweenService:Create(child, TweenInfo.new(0.3), { TextTransparency = 1 }):Play()
				elseif child:IsA("UIStroke") then
					TweenService:Create(child, TweenInfo.new(0.3), { Transparency = 1 }):Play()
				elseif child:IsA("Frame") then
					TweenService:Create(child, TweenInfo.new(0.3), { BackgroundTransparency = 1 }):Play()
				end
			end
			task.wait(0.35)
			card:Destroy()
		end
	end)
end

-- While results pile up (or just did), or with the Fast Open pass, they go to the quick
-- feed; a new Rare+ part always gets its card.
local function isQuick(result: Result): boolean
	if result.New and Rarities.ById[result.Rarity].Rank >= BIG_RANK then
		return false
	end
	return player:GetAttribute("Pass_FastOpen") == true or #queue > 0 or os.clock() - lastQuick < QUICK_LINGER
end

local function processQueue()
	if playing then
		return
	end
	playing = true
	while #queue > 0 do
		local result = table.remove(queue, 1) :: Result
		local quick = isQuick(result)
		if quick then
			lastQuick = os.clock()
		end
		-- the corner ad: skip the reveals while they pile up, or find rarer parts
		Upsell.Offer(if quick then { "FastOpen", "Lucky" } else { "Lucky", "FastOpen" })
		local ok, err = pcall(if quick then quickShow else play, result)
		if quick then
			task.wait(QUICK_GAP)
		end
		if not ok then
			warn(`[Loot] couldn't show a result: {err}`)
			local leftover = Kit.getGui():FindFirstChild("LootOverlay")
			if leftover then
				leftover:Destroy()
			end
		end
	end
	playing = false
	LineMenu.Refresh()
end

-- Public API -----------------------------------------------------------------

-- Queues a loot result (from a Roll or a box) to reveal.
function Loot.Show(result: Result)
	table.insert(queue, result)
	task.spawn(processQueue)
end

-- Opens one of the player's Rolls.
function Loot.OpenRoll()
	if rolling then
		return
	end
	if (player:GetAttribute("Rolls") or 0) < 1 then
		Kit.toast("No Rolls left! Grab loot boxes around the map.", BAD_COLOR)
		return
	end
	rolling = true
	local ok, result = pcall(function()
		return Remotes.Function("OpenRoll"):InvokeServer()
	end)
	rolling = false
	if ok and result then
		Loot.Show(result)
	else
		Kit.toast("Couldn't open a Roll. Try again!", BAD_COLOR)
	end
end

return Loot
