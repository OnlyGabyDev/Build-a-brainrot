--[[
	Loot
	Opens Rolls and shows loot results (GDD §5): a prize wheel spins and lands on the
	server's result, then a reveal card shows the part. The server rolled the result
	before any of this plays; the wheel is only for show. Results queue up, so grabbing
	several boxes plays their wheels one after another.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
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
local WHEEL_SIZE = 480
local SLOT_RADIUS = 172
local SPIN_TIME = 3.2
local SPIN_TURNS = 4
local AUTO_CLOSE = 8 -- seconds before a reveal closes itself
local BIG_RANK = 3 -- Rare and up get the bigger reveal
local CURRENCY_ICONS = { Coins = "💰", Gems = "💎" }
local NEW_COLOR = Color3.fromRGB(120, 245, 110)
local BAD_COLOR = Color3.fromRGB(255, 90, 90)
local LAYOUT_SEED = 7 -- a fixed shuffle, so the rarity wheel always looks the same

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

export type Slot = { Key: string, Label: string, Color: Color3 }

local player = Players.LocalPlayer
local queue: { Result } = {}
local playing = false
local rolling = false
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
		table.insert(slots, { Key = rarity.Id, Label = string.upper(rarity.Id), Color = rarity.Color })
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

-- Wheel ----------------------------------------------------------------------

local function circle(parent: Instance)
	Kit.new("UICorner", { CornerRadius = UDim.new(0.5, 0), Parent = parent })
end

local function buildWheel(parent: Frame, slots: { Slot }, hubText: string): (Frame, Frame, { Frame })
	local wheel = Kit.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(WHEEL_SIZE, WHEEL_SIZE),
		BackgroundColor3 = Kit.White,
		ZIndex = 31,
		Parent = parent,
	})
	circle(wheel)
	Kit.stroke(wheel, 8)
	Kit.gradient(wheel, Kit.Colors.Rolls)

	local spinner = Kit.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 32, Parent = wheel })
	local cards = {}
	for index, slot in slots do
		local angle = (index - 1) / #slots * math.pi * 2
		local card = Kit.new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, math.sin(angle) * SLOT_RADIUS, 0.5, -math.cos(angle) * SLOT_RADIUS),
			Size = UDim2.fromOffset(92, 92),
			Rotation = math.deg(angle),
			BackgroundColor3 = slot.Color,
			ZIndex = 33,
			Parent = spinner,
		})
		Kit.corner(card, 18)
		Kit.stroke(card, 4)
		Kit.text({
			Text = slot.Label,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(0.9, 0.55),
			ZIndex = 34,
			Parent = card,
		})
		cards[index] = card
	end

	local hub = Kit.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(170, 170),
		BackgroundColor3 = Kit.White,
		ZIndex = 35,
		Parent = wheel,
	})
	circle(hub)
	Kit.stroke(hub, 6)
	Kit.gradient(hub, Kit.Colors.Purple)
	Kit.text({
		Text = hubText,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.75, 0.5),
		ZIndex = 36,
		Parent = hub,
	})

	Kit.text({
		Text = "▼",
		TextColor3 = Color3.fromRGB(255, 220, 60),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, -WHEEL_SIZE / 2 - 18),
		Size = UDim2.fromOffset(80, 80),
		StrokeThickness = 4,
		ZIndex = 40,
		Parent = wheel,
	})
	return wheel, spinner, cards
end

-- Spins so the target slot stops under the pointer, ticking as slots pass it.
local function spin(spinner: Frame, slotCount: number, target: number)
	local step = 360 / slotCount
	local jitter = (math.random() - 0.5) * step * 0.6 -- stop anywhere on the slot, for suspense
	local final = SPIN_TURNS * 360 + (360 - (target - 1) * step) % 360 + jitter

	local value = Instance.new("NumberValue")
	local lastSlot = 0
	value.Changed:Connect(function(rotation)
		spinner.Rotation = rotation
		local slot = math.floor((rotation + step / 2) / step)
		if slot ~= lastSlot then
			lastSlot = slot
			playTick()
		end
	end)
	local speed = if player:GetAttribute("Pass_FastOpen") then Gamepasses.FastOpen.WheelSpeed or 1 else 1
	local info = TweenInfo.new(SPIN_TIME / speed, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	local tween = TweenService:Create(value, info, { Value = final })
	tween:Play()
	tween.Completed:Wait()
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

-- Shows a prize wheel on a dim overlay, spins it until slot `target` is under the
-- pointer, and flashes `color`. Returns the overlay: the caller shows its reveal on
-- it, then destroys it.
function Loot.PlayWheel(slots: { Slot }, target: number, hubText: string, color: Color3): Frame
	local screen = Kit.new("Frame", {
		Name = "LootOverlay",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.45,
		Active = true,
		ZIndex = 30,
		Parent = Kit.getGui(),
	})
	local wheel, spinner, cards = buildWheel(screen, slots, hubText)
	Kit.pop(wheel, -0.6)
	spin(spinner, #slots, target)
	Kit.pop(cards[target], 0.35)
	Kit.flash(screen, color)
	task.wait(0.45)
	wheel:Destroy()
	return screen
end

local function play(result: Result)
	local slots = buildSlots(result)
	local target = pickTarget(slots, result)
	local subtitle = if result.BoxRarity then `{string.upper(result.BoxRarity)} BOX` else "ROLL"
	local hubText = `{subtitle}\n{string.upper(result.PartType)}`
	local screen = Loot.PlayWheel(slots, target, hubText, Rarities.ById[result.Rarity].Color)
	reveal(screen, result)
	screen:Destroy()
end

local function processQueue()
	if playing then
		return
	end
	playing = true
	while #queue > 0 do
		local result = table.remove(queue, 1) :: Result
		local ok, err = pcall(play, result)
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
