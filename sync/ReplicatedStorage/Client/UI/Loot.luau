--[[
	Loot
	Opens Rolls and shows loot results (GDD §5): a prize reel (a strip of glossy rarity
	cards in a lit gold frame, case-opening style) spins and stops on the server's result
	under the marker, then a reveal card shows the part. The server rolled the result
	before any of this plays; the reel is only for show. Results queue up, so grabbing
	several boxes plays their reels one after another; while they pile up (a bought box
	storm), the rest skip the reel and pop into a quick feed on the right instead (a
	new Rare+ part still gets the full reel). The Daily Wheel uses the same reel.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local BrainrotModels = require(Shared:WaitForChild("BrainrotModels"))
local Brainrots = require(Config:WaitForChild("Brainrots"))
local Format = require(Shared:WaitForChild("Format"))
local Gamepasses = require(Config:WaitForChild("Gamepasses"))
local LootConfig = require(Config:WaitForChild("Loot"))
local Rarities = require(Config:WaitForChild("Rarities"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Sounds = require(Config:WaitForChild("Sounds"))
local Kit = require(script.Parent:WaitForChild("Kit"))
local LineMenu = require(script.Parent:WaitForChild("LineMenu"))

local SLOT_COUNT = 12
local CARD = 260 -- a reel card, square (big: you see the parts on it)
local PITCH = 286 -- card to card
local REEL = Vector2.new(1480, 380) -- (of the 1600 x 900 design screen)
local MIN_TARGET = 64 -- the winning card is the slot's first time round the strip from here
-- The spin, in cards: it starts very fast and its speed falls off quickly (FALLOFF per
-- second) toward CRAWL cards a second, for FAST seconds; then for the last SLOW seconds it
-- crawls to a stop. The speed never jumps between the two.
local FAST, SLOW = 2.4, 2.0
local FALLOFF = 3
local CRAWL = 1.2
local FIGURE_SPEED = 25 -- cards a second: faster than this, the cards are a blur (no parts drawn)
local TICK_GAP = 0.035 -- seconds between ticks at full speed
local RARE_RIM = 5 -- rarity rank (Mythic) from which a card has a gold rim
-- A near miss (the user's call): this often, when there's a rarer prize than the one
-- won, the card right after the winner is one of the rarer ones and the strip stops on
-- the winner's far edge, as close to it as it gets, before settling back. Only how the
-- reel looks: the prize is the server's roll, and the shop's odds stay true.
local NEAR_MISS_CHANCE = 0.65
local REEL_BACK = { Color3.fromRGB(60, 36, 110), Color3.fromRGB(26, 16, 58) }
local REEL_GOLD = Color3.fromRGB(255, 205, 70)
local BULB_COLORS = { Color3.fromRGB(255, 235, 120), Color3.fromRGB(255, 110, 220), Color3.fromRGB(110, 230, 255) }
local AUTO_CLOSE = 8 -- seconds before a reveal closes itself
local BIG_RANK = 3 -- Rare and up get the bigger reveal
local CURRENCY_ICONS = { Coins = "💰", Gems = "💎" }
local NEW_COLOR = Color3.fromRGB(120, 245, 110)
local BAD_COLOR = Color3.fromRGB(255, 90, 90)
local LAYOUT_SEED = 7 -- a fixed shuffle, so the rarity wheel always looks the same
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

-- A wheel slot: a rarity (Key: its id), or another prize (the Daily Wheel's). With a
-- PartType, its cards show a part of that type from a brainrot of that rarity.
export type Slot = { Key: string, Label: string, Color: Color3, Stars: number?, PartType: string? }
-- The part a reel card shows.
type Figure = { BrainrotId: string, PartType: string }

local player = Players.LocalPlayer
local queue: { Result } = {}
local playing = false
local rolling = false
local lastQuick = -math.huge
local feed: Frame? = nil
local feedOrder = 0
local tickSound: Sound? = nil

local Loot = {}

local function playTick()
	if not tickSound then
		tickSound = Kit.new("Sound", { SoundId = Sounds.Click, Volume = 0.5, PlaybackSpeed = 1.7, Parent = SoundService })
	end
	SoundService:PlayLocalSound(tickSound :: Sound)
end

-- Wheel slots ----------------------------------------------------------------

-- One slot per rarity that could drop, plus extra slots roughly matching the odds
-- (the same odds the server rolled with, from Config/Loot).
local function buildSlots(result: Result): { Slot }
	local rebirths = player:GetAttribute("Rebirths") or 0
	local luck = player:GetAttribute("Luck") or 0 -- total luck, kept fresh by LootManager
	local odds = if result.Source == "Box" and result.BoxRarity
		then LootConfig.BoxOdds(result.BoxRarity, rebirths, luck)
		else LootConfig.RollOdds(rebirths, luck)
	odds[result.Rarity] = odds[result.Rarity] or 0 -- the result always has a slot

	local total, likeliest = 0, result.Rarity
	for rarityId, weight in odds do
		total += weight
		if weight > odds[likeliest] then
			likeliest = rarityId
		end
	end

	local slots: { Slot } = {}
	local function add(rarity: Rarities.Rarity)
		table.insert(slots, { Key = rarity.Id, Label = string.upper(rarity.Id), Color = rarity.Color, Stars = rarity.Rank, PartType = result.PartType })
	end
	for rank = #Rarities.List, 1, -1 do -- rarest first, so each is guaranteed a slot
		local rarity = Rarities.List[rank]
		local weight = odds[rarity.Id]
		if weight then
			local count = math.max(1, math.floor(weight / total * SLOT_COUNT + 0.5))
			for _ = 1, count do
				if #slots < SLOT_COUNT then
					add(rarity)
				end
			end
		end
	end
	while #slots < SLOT_COUNT do
		add(Rarities.ById[likeliest])
	end

	local shuffle = Random.new(LAYOUT_SEED)
	for index = #slots, 2, -1 do
		local other = shuffle:NextInteger(1, index)
		slots[index], slots[other] = slots[other], slots[index]
	end
	return slots
end

-- The slot the wheel lands on: a random one showing the result.
local function pickTarget(slots: { Slot }, result: Result): number
	local matches = {}
	for index, slot in slots do
		if slot.Key == result.Rarity then
			table.insert(matches, index)
		end
	end
	if #matches == 0 then
		return 1
	end
	return matches[math.random(1, #matches)]
end

-- Reel -----------------------------------------------------------------------

local RAINBOW = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 90, 90)),
	ColorSequenceKeypoint.new(0.25, Color3.fromRGB(255, 220, 70)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(100, 240, 120)),
	ColorSequenceKeypoint.new(0.75, Color3.fromRGB(90, 180, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(220, 110, 255)),
})

-- A glossy card for `slot`: its color top to bottom (Godly in a rainbow), stars for its
-- rarity, and its label, or with a `figure`, that part (in a holder the reel fills when
-- the card comes into view: showFigures) over its brainrot's name.
local function reelCard(parent: Frame, slot: Slot, x: number, figure: Figure?): Frame
	local card = Kit.new("Frame", {
		Position = UDim2.new(0, x, 0.5, -CARD / 2),
		Size = UDim2.fromOffset(CARD, CARD),
		BackgroundColor3 = Kit.White,
		ZIndex = 33,
		Parent = parent,
	})
	Kit.corner(card, 22)
	local rim = Kit.stroke(card, 4)
	if (slot.Stars or 0) >= RARE_RIM then
		-- the rarest ones shine gold as they fly by
		rim.Color = REEL_GOLD
		rim.Thickness = 7
	end
	if slot.Key == "Godly" then
		Kit.new("UIGradient", { Color = RAINBOW, Rotation = 45, Parent = card })
	else
		Kit.gradient(card, { slot.Color:Lerp(Kit.White, 0.35), slot.Color:Lerp(Color3.new(0, 0, 0), 0.18) })
	end
	Kit.shine(card, 16)
	local stars = slot.Stars
	if figure then
		card:SetAttribute("BrainrotId", figure.BrainrotId)
		card:SetAttribute("PartType", figure.PartType)
		Kit.new("Frame", { Name = "Figure", Position = UDim2.fromOffset(12, 46), Size = UDim2.fromOffset(CARD - 24, CARD - 104), BackgroundTransparency = 1, ZIndex = 34, Parent = card })
		Kit.text({ Text = string.rep("⭐", stars or 1), AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 10), Size = UDim2.new(0.8, 0, 0, 34), StrokeThickness = 0, ZIndex = 34, Parent = card })
		local brainrot = Brainrots.ById[figure.BrainrotId]
		Kit.text({
			Text = if brainrot then brainrot.Name else slot.Label,
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 1, -12),
			Size = UDim2.new(0.9, 0, 0, 46),
			StrokeThickness = 3,
			ZIndex = 35,
			Parent = card,
		})
		Kit.new("UIScale", { Name = "PopScale", Parent = card })
		return card
	end
	if stars then
		Kit.text({
			Text = string.rep("⭐", stars),
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, 24),
			Size = UDim2.new(0.86, 0, 0, 60),
			StrokeThickness = 0,
			ZIndex = 34,
			Parent = card,
		})
	end
	Kit.text({
		Text = slot.Label,
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -22),
		Size = UDim2.new(0.9, 0, 0, if stars then 84 else CARD - 60),
		StrokeThickness = 3,
		ZIndex = 34,
		Parent = card,
	})
	Kit.new("UIScale", { Name = "PopScale", Parent = card })
	return card
end

type Reel = { Root: Frame, Strip: Frame, Cards: { Frame }, Marker: Frame, Bulbs: { Frame }, Width: number, Target: number, NearMiss: boolean }

-- The reel on the overlay: a dark frame with a gold rim and chasing bulbs, the strip of
-- cards clipped inside it (faded at the ends), the gold marker in the middle, and its
-- title in a pill above it. The strip cycles through `slots` in order, round and round
-- (each prize about as often as it comes up, so a rare one keeps flying by), and stops
-- on `slots[target]` its first time round from MIN_TARGET (the reel's Target card).
-- Part slots show a random brainrot of their rarity on each card, the Target `prize`.
local function buildReel(parent: Frame, slots: { Slot }, target: number, title: string, prize: Figure?): Reel
	local root = Kit.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(REEL.X, REEL.Y),
		BackgroundColor3 = Kit.White,
		ZIndex = 31,
		Parent = parent,
	})
	Kit.corner(root, 30)
	Kit.stroke(root, 7, REEL_GOLD)
	Kit.gradient(root, REEL_BACK)

	-- the title, in a pill over the top edge
	local pill = Kit.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 0, 22),
		Size = UDim2.fromOffset(440, 74),
		BackgroundColor3 = Kit.White,
		ZIndex = 38,
		Parent = root,
	})
	Kit.new("UICorner", { CornerRadius = UDim.new(0.5, 0), Parent = pill })
	Kit.stroke(pill, 5)
	Kit.gradient(pill, Kit.Colors.Rolls)
	Kit.shine(pill, 24)
	Kit.text({
		Text = string.gsub(title, "\n", "  ·  "),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(0.86, 0, 0, 46),
		StrokeThickness = 3,
		ZIndex = 39,
		Parent = pill,
	})

	-- chasing bulbs along the top and bottom edges
	local bulbs = {}
	for row = 0, 1 do
		for k = 0, 15 do
			local bulb = Kit.new("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0, 60 + k * (REEL.X - 120) / 15, row, if row == 0 then 12 else -12),
				Size = UDim2.fromOffset(14, 14),
				BackgroundColor3 = BULB_COLORS[k % #BULB_COLORS + 1],
				ZIndex = 32,
				Parent = root,
			})
			Kit.new("UICorner", { CornerRadius = UDim.new(0.5, 0), Parent = bulb })
			table.insert(bulbs, bulb)
		end
	end

	-- the strip, clipped inside the frame
	local width = REEL.X - 36
	local clip = Kit.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(width, CARD + 30),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		ZIndex = 32,
		Parent = root,
	})
	local strip = Kit.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 32, Parent = clip })
	local random = Random.new()
	local cards = {}
	local count = #slots
	local targetAt = MIN_TARGET + (target - 1 - (MIN_TARGET - 1) % count) % count
	-- (and enough cards after it to fill the reel's right half)
	for index = 1, targetAt + math.ceil(width / 2 / PITCH) + 1 do
		local slot = slots[(index - 1) % count + 1]
		local figure: Figure? = nil
		local pool = Brainrots.ByRarity[slot.Key]
		if index == targetAt and prize then
			figure = prize
		elseif slot.PartType and pool and #pool > 0 then
			figure = { BrainrotId = pool[random:NextInteger(1, #pool)].Id, PartType = slot.PartType :: string }
		end
		cards[index] = reelCard(strip, slot, (index - 1) * PITCH, figure)
	end
	-- the near miss: a rarer prize right after the winner
	local rarer = {}
	for _, slot in slots do
		if (slot.Stars or 0) > (slots[target].Stars or 0) then
			table.insert(rarer, slot)
		end
	end
	local nearMiss = #rarer > 0 and random:NextNumber() < NEAR_MISS_CHANCE
	if nearMiss then
		local slot = rarer[random:NextInteger(1, #rarer)]
		local pool = Brainrots.ByRarity[slot.Key]
		local figure: Figure? = if slot.PartType and pool and #pool > 0
			then { BrainrotId = pool[random:NextInteger(1, #pool)].Id, PartType = slot.PartType :: string }
			else nil
		cards[targetAt + 1]:Destroy()
		cards[targetAt + 1] = reelCard(strip, slot, targetAt * PITCH, figure)
	end
	-- the ends fade into the frame
	for side = 0, 1 do
		local fade = Kit.new("Frame", {
			AnchorPoint = Vector2.new(side, 0),
			Position = UDim2.fromScale(side, 0),
			Size = UDim2.new(0, 170, 1, 0),
			BackgroundColor3 = REEL_BACK[2]:Lerp(REEL_BACK[1], 0.5),
			BorderSizePixel = 0,
			ZIndex = 36,
			Parent = clip,
		})
		Kit.new("UIGradient", { Transparency = NumberSequence.new(if side == 0 then 0 else 1, if side == 0 then 1 else 0), Parent = fade })
	end

	-- the marker: a gold line down the middle with a pointer at each end
	local marker = Kit.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(0, 6, 1, -20),
		BackgroundColor3 = REEL_GOLD,
		BorderSizePixel = 0,
		ZIndex = 37,
		Parent = root,
	})
	Kit.stroke(marker, 2)
	for _, y in { 0, 1 } do
		local pointer = Kit.new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, y),
			Size = UDim2.fromOffset(30, 30),
			Rotation = 45,
			BackgroundColor3 = REEL_GOLD,
			ZIndex = 37,
			Parent = marker,
		})
		Kit.corner(pointer, 6)
		Kit.stroke(pointer, 3)
	end
	Kit.new("UIScale", { Name = "PopScale", Parent = marker })
	return { Root = root, Strip = strip, Cards = cards, Marker = marker, Bulbs = bulbs, Width = width, Target = targetAt, NearMiss = nearMiss }
end

-- The parts in view: each card near `center` (a card index) gets its part in a viewport
-- as it comes into view, and the ones the strip has left behind let theirs go, so only
-- a few viewports are ever alive.
local FIGURE_REACH = 4 -- cards either side of the marker that can be in view
local function showFigures(reel: Reel, center: number)
	for index, card in reel.Cards do
		local holder = card:FindFirstChild("Figure")
		if not holder then
			continue
		end
		local view = holder:FindFirstChildOfClass("ViewportFrame")
		local near = math.abs(index - center) <= FIGURE_REACH
		if near and not view then
			local id, partType = card:GetAttribute("BrainrotId"), card:GetAttribute("PartType")
			if typeof(id) == "string" and typeof(partType) == "string" then
				Kit.viewport({ Size = UDim2.fromScale(1, 1), ZIndex = 34, Parent = holder }, (BrainrotModels.CreatePart(id, partType)))
			end
		elseif view and not near then
			view:Destroy()
		end
	end
end

-- Where the strip sits (its X offset) with the middle of card `index` (plus `nudge`)
-- under the marker.
local function stripX(reel: Reel, index: number, nudge: number): number
	return reel.Width / 2 - ((index - 1) * PITCH + CARD / 2 + nudge)
end

-- How far the strip has run (in cards) `t` seconds into a spin of `distance` cards, and
-- how fast it's going: very fast at first, the speed falling off quickly (toward CRAWL)
-- for `fast` seconds, then easing from where it got to down to a stop over the last
-- `slow` seconds. The starting speed is solved so the two meet without a jump and the
-- strip ends exactly `distance` cards on.
local function spinAt(t: number, distance: number, fast: number, slow: number): (number, number)
	local tail = math.exp(-FALLOFF * fast) -- what's left of the extra speed when the crawl starts
	local extra = math.max(distance - CRAWL * (fast + slow / 2), 0) / ((1 - tail) / FALLOFF + tail * slow / 2)
	if t <= fast then
		local falling = math.exp(-FALLOFF * t)
		return CRAWL * t + extra * (1 - falling) / FALLOFF, CRAWL + extra * falling
	end
	local quick = CRAWL * fast + extra * (1 - tail) / FALLOFF
	local crawl = CRAWL + extra * tail
	local u = math.min(t - fast, slow)
	return quick + crawl * u - crawl * u * u / (2 * slow), crawl * (1 - u / slow)
end

-- Spins the strip from a few cards in to its Target card (see spinAt), ticking as cards
-- pass the marker (the marker bounces), the bulbs chasing; it stops a little off the
-- card's middle, then settles onto it. The parts show on the cards once it's slow enough
-- to see them.
local function spin(reel: Reel)
	-- stop anywhere on the card, for suspense (a near miss: on its far edge, by the rare one)
	local nudge = if reel.NearMiss then CARD * (0.4 + math.random() * 0.06) else (math.random() - 0.5) * CARD * 0.7
	local from, to = stripX(reel, 3, 0), stripX(reel, reel.Target, nudge)
	local distance = (from - to) / PITCH
	local speedUp = if player:GetAttribute("Pass_FastOpen") then Gamepasses.FastOpen.WheelSpeed or 1 else 1
	local fast, slow = FAST / speedUp, SLOW / speedUp
	local lastCard, lastTick = -1, 0
	local function place(x: number, speed: number)
		reel.Strip.Position = UDim2.fromOffset(x, 0)
		local under = math.floor((reel.Width / 2 - x) / PITCH)
		if under ~= lastCard then
			lastCard = under
			if os.clock() - lastTick >= TICK_GAP then
				lastTick = os.clock()
				playTick()
				Kit.pop(reel.Marker, 0.25)
			end
		end
		if speed < FIGURE_SPEED then
			showFigures(reel, under + 1)
		end
	end
	local chase = RunService.RenderStepped:Connect(function()
		local step = math.floor(os.clock() * 12)
		for index, bulb in reel.Bulbs do
			bulb.BackgroundTransparency = if (index + step) % 3 == 0 then 0 else 0.55
		end
	end)
	local started = os.clock()
	while true do
		local t = os.clock() - started
		local run, speed = spinAt(t, distance, fast, slow)
		place(from - run * PITCH, speed)
		if t >= fast + slow then
			break
		end
		RunService.RenderStepped:Wait()
	end
	if reel.NearMiss then
		task.wait(0.35) -- (a beat right by the rare one)
	end
	local value = Instance.new("NumberValue")
	value.Value = to
	value.Changed:Connect(function(x)
		place(x, 0)
	end)
	local settle = TweenService:Create(value, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Value = stripX(reel, reel.Target, 0) })
	settle:Play()
	settle.Completed:Wait()
	chase:Disconnect()
	for _, bulb in reel.Bulbs do
		bulb.BackgroundTransparency = 0
	end
	value:Destroy()
end

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

-- Shows the prize reel on a dim overlay, spins it until slot `target` stops under the
-- marker, and flashes `color`. Returns the overlay: the caller shows its reveal on it,
-- then destroys it.
-- (`prize`: the part won, for a reel of parts: its card shows it)
function Loot.PlayWheel(slots: { Slot }, target: number, hubText: string, color: Color3, prize: Figure?): Frame
	local screen = Kit.new("Frame", {
		Name = "LootOverlay",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(20, 10, 40),
		BackgroundTransparency = 0.4,
		Active = true,
		ZIndex = 30,
		Parent = Kit.getGui(),
	})
	local reel = buildReel(screen, slots, target, hubText, prize)
	Kit.new("UIScale", { Name = "PopScale", Parent = reel.Root })
	Kit.pop(reel.Root, -0.4)
	Kit.playSound(Sounds.Whoosh, 0.25, 1.4)
	task.wait(0.25)
	spin(reel)
	-- the winner pops out of the strip
	local winner = reel.Cards[reel.Target]
	local scale = winner:FindFirstChild("PopScale") :: UIScale
	TweenService:Create(scale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1.18 }):Play()
	local rim = winner:FindFirstChildOfClass("UIStroke")
	if rim then
		rim.Color = REEL_GOLD
		rim.Thickness = 6
	end
	Kit.playSound(Sounds.Coin, 0.4, 1.2)
	Kit.flash(screen, color)
	task.wait(0.6)
	reel.Root:Destroy()
	return screen
end

local function play(result: Result)
	local slots = buildSlots(result)
	local target = pickTarget(slots, result)
	local subtitle = if result.BoxRarity then `{string.upper(result.BoxRarity)} BOX` else "ROLL"
	local hubText = `{subtitle}\n{string.upper(result.PartType)}`
	local screen = Loot.PlayWheel(slots, target, hubText, Rarities.ById[result.Rarity].Color, { BrainrotId = result.BrainrotId, PartType = result.PartType })
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

-- While results pile up (or just did), they go to the quick feed; a new Rare+ part
-- always gets its reel.
local function isQuick(result: Result): boolean
	if result.New and Rarities.ById[result.Rarity].Rank >= BIG_RANK then
		return false
	end
	return #queue > 0 or os.clock() - lastQuick < QUICK_LINGER
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

-- Queues a loot result (from a Roll or a box) to spin and reveal.
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
