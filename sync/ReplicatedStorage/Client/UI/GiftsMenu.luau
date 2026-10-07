--[[
	GiftsMenu
	The free gifts (GDD §5 "Free gifts", Config/FreeGifts): nine gift cards, each in a
	rarer color than the last (Common up to a turning Godly rainbow) with a bigger gift,
	what's inside and the time left; an opened one gets a tick, a ready one pulses gold
	with a big OPEN!. A gift button on the HUD's right column (under the calendar) shows
	the time to the next gift, or OPEN! while one waits, and goes away once all nine are
	open (until tomorrow); a toast says when one is ready (not during Tralalero's guide).
	Services/FreeGifts times and pays them. Client only.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local FreeGifts = require(Config:WaitForChild("FreeGifts"))
local Guide = require(Config:WaitForChild("Guide"))
local Rarities = require(Config:WaitForChild("Rarities"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Rewards = require(Shared:WaitForChild("Rewards"))
local Sounds = require(Config:WaitForChild("Sounds"))
local Kit = require(script.Parent:WaitForChild("Kit"))
local Loot = require(script.Parent:WaitForChild("Loot"))

local GIFTS = FreeGifts.List
local SIZE = Vector2.new(860, 620)
local CARD = Vector2.new(252, 150)
local GOLD = Color3.fromRGB(255, 215, 60)
local GOOD_COLOR = Color3.fromRGB(120, 245, 110)
local BAD_COLOR = Color3.fromRGB(255, 90, 90)
local DARK = Color3.fromRGB(40, 32, 60)
local CLAIM_COLORS = { Color3.fromRGB(255, 240, 120), Color3.fromRGB(255, 160, 30) }
local RAINBOW = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 100, 100)),
	ColorSequenceKeypoint.new(0.25, Color3.fromRGB(255, 220, 80)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(110, 240, 130)),
	ColorSequenceKeypoint.new(0.75, Color3.fromRGB(100, 180, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(220, 120, 255)),
})
local BUTTON_TOP, BUTTON_TOP_ALONE = 300, 228 -- (under the calendar; in its place once it's gone)

local player = Players.LocalPlayer
local panel: Frame? = nil
local content: Frame? = nil
local body: Frame? = nil
local claiming = false
local animators: { (t: number, dt: number) -> () } = {}
local stops: { () -> () } = {} -- (Kit.rays' stop functions for the cards on screen)
local shownKey = ""

local GiftsMenu = {}

-- State ------------------------------------------------------------------------

-- Seconds played today (nil before the data comes).
local function played(): number?
	local start = player:GetAttribute("GiftsStart")
	return if typeof(start) == "number" then workspace:GetServerTimeNow() - start else nil
end

local function claimedSet(): { [number]: boolean }
	local set = {}
	local text = player:GetAttribute("GiftsClaimed")
	if typeof(text) == "string" then
		for number in string.gmatch(text, "%d+") do
			set[tonumber(number) :: number] = true
		end
	end
	return set
end

local function income(): number
	local value = player:GetAttribute("Income")
	return if typeof(value) == "number" then value else 0
end

-- "4:05", "1:02:30"
local function timer(seconds: number): string
	seconds = math.max(0, math.ceil(seconds))
	if seconds >= 3600 then
		return string.format("%d:%02d:%02d", seconds // 3600, seconds % 3600 // 60, seconds % 60)
	end
	return string.format("%d:%02d", seconds // 60, seconds % 60)
end

-- "5h 12m", "12m"
local function span(seconds: number): string
	seconds = math.max(0, math.floor(seconds))
	if seconds >= 3600 then
		return `{seconds // 3600}h {seconds % 3600 // 60}m`
	end
	return `{seconds // 60}m`
end

-- The gifts ready to open, and the next one still locked (and its seconds left).
local function status(): ({ number }, number?, number?)
	local seconds = played() or 0
	local claimed = claimedSet()
	local ready = {}
	local nextIndex, left = nil, nil
	for index, gift in GIFTS do
		if not claimed[index] then
			local waiting = gift.Minutes * 60 - seconds
			if waiting <= 0 then
				table.insert(ready, index)
			elseif not nextIndex then
				nextIndex, left = index, waiting
			end
		end
	end
	return ready, nextIndex, left
end

local function allOpened(): boolean
	local claimed = claimedSet()
	for index in GIFTS do
		if not claimed[index] then
			return false
		end
	end
	return true
end

-- What the cards depend on: which are open and which are ready.
local function stateKey(): string
	local ready = status()
	return `{player:GetAttribute("GiftsClaimed")}|{table.concat(ready, ",")}`
end

-- The rarity whose colors gift `index` wears (Common first, Godly last).
local function rarityOf(index: number): Rarities.Rarity
	local rank = math.clamp(math.ceil(index * #Rarities.List / #GIFTS), 1, #Rarities.List)
	return Rarities.List[rank]
end

-- Opening -----------------------------------------------------------------------

local render: () -> ()

local function claim(index: number)
	if claiming then
		return
	end
	claiming = true
	local remote = Remotes.Function("ClaimGift")
	local ok, result = pcall(remote.InvokeServer, remote, index)
	claiming = false
	if not (ok and typeof(result) == "table") then
		Kit.toast("Try again!", BAD_COLOR, "Warning")
		return
	end
	local rarity = rarityOf(index)
	local color = if rarity.Id == "Godly" then GOLD else rarity.Color
	local gui = Kit.getGui()
	Kit.flash(gui :: any, color, 70)
	Kit.confetti(gui :: any, { color, GOLD, Color3.fromRGB(120, 220, 255), Color3.fromRGB(255, 120, 220) }, 60, 70)
	Kit.playSound(Sounds.RevealBig, 0.5)
	Kit.toast(result.Text or "", GOOD_COLOR, Rewards.Icon(GIFTS[index].Reward))
	render()
	if result.Result then
		task.wait(0.6)
		Loot.Show(result.Result)
	end
end

-- Cards ----------------------------------------------------------------------------

local function renderCard(parent: GuiObject, index: number, claimed: boolean, ready: boolean)
	local gift = GIFTS[index]
	local rarity = rarityOf(index)
	local card = Kit.new("Frame", { LayoutOrder = index, BackgroundColor3 = Kit.White, ZIndex = 3, Parent = parent })
	Kit.corner(card, 20)
	Kit.stroke(card, if ready then 5 else 4, if ready then GOLD else nil)
	if rarity.Id == "Godly" then
		local gradient = Kit.new("UIGradient", { Color = RAINBOW, Rotation = 45, Parent = card })
		table.insert(animators, function(_t, dt)
			gradient.Rotation = (gradient.Rotation + dt * 50) % 360
		end)
	else
		Kit.gradient(card, { rarity.Color:Lerp(Kit.White, 0.3), rarity.Color:Lerp(Color3.new(0, 0, 0), 0.22) })
	end
	Kit.stripes(card, 0.8, 20, 3)
	Kit.shine(card, 16)
	if rarity.Rank >= 4 or ready then
		Kit.neonRim(card, if ready then GOLD else rarity.Color:Lerp(Kit.White, 0.5), 20, 5)
	end
	if rarity.Rank >= 4 then
		Kit.sheen(card, 2.4, 4)
	end
	local scale = Kit.new("UIScale", { Parent = card })

	-- the gift, bigger the later it is, wobbling over a sunburst when it's ready
	local size = 60 + index * 4
	if ready then
		local glow = Kit.new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromOffset(64, 66),
			Size = UDim2.fromOffset(size, size),
			BackgroundTransparency = 1,
			ZIndex = 5,
			Parent = card,
		})
		table.insert(stops, Kit.rays(glow, GOLD, size * 1.8, 5))
	end
	local present = Kit.icon("Gift", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(64, 66),
		Size = UDim2.fromOffset(size, size),
		ZIndex = 6,
		Parent = card,
	})
	table.insert(animators, function(t)
		if ready then
			present.Rotation = math.sin(t * 9 + index) * 12
			scale.Scale = 1 + math.sin(t * 5) * 0.025
		else
			present.Rotation = math.sin(t * 1.5 + index) * 4
		end
	end)
	Kit.text({
		Text = `GIFT {index}`,
		Position = UDim2.fromOffset(122, 12),
		Size = UDim2.fromOffset(118, 28),
		TextXAlignment = Enum.TextXAlignment.Left,
		StrokeThickness = 3,
		ZIndex = 5,
		Parent = card,
	})
	-- what's inside
	local inside = Kit.new("Frame", {
		Position = UDim2.fromOffset(120, 46),
		Size = UDim2.fromOffset(122, 44),
		BackgroundColor3 = Kit.White,
		BackgroundTransparency = 0.15,
		ZIndex = 5,
		Parent = card,
	})
	Kit.corner(inside, 12)
	Kit.stroke(inside, 2.5)
	Kit.icon(Rewards.Icon(gift.Reward), { Position = UDim2.fromOffset(4, 4), Size = UDim2.fromOffset(36, 36), ZIndex = 6, Parent = inside })
	Kit.text({
		Text = Rewards.Text(gift.Reward, income()),
		Position = UDim2.fromOffset(42, 6),
		Size = UDim2.fromOffset(76, 32),
		TextXAlignment = Enum.TextXAlignment.Left,
		StrokeThickness = 2,
		ZIndex = 6,
		Parent = inside,
	})

	if ready then
		local button = Kit.button({
			Position = UDim2.fromOffset(120, 98),
			Size = UDim2.fromOffset(122, 42),
			ZIndex = 6,
			Parent = card,
		}, CLAIM_COLORS, "OPEN!", function()
			task.spawn(claim, index)
		end)
		local pulse = Kit.new("UIScale", { Parent = button })
		table.insert(animators, function(t)
			pulse.Scale = 1 + math.sin(t * 6) * 0.05
		end)
	elseif claimed then
		local shade = Kit.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = DARK, BackgroundTransparency = 0.5, ZIndex = 8, Parent = card })
		Kit.corner(shade, 20)
		Kit.icon("Check", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(80, 80), ZIndex = 9, Parent = shade })
	else
		-- locked: the time left, ticking
		local pill = Kit.new("Frame", {
			Position = UDim2.fromOffset(120, 98),
			Size = UDim2.fromOffset(122, 42),
			BackgroundColor3 = DARK,
			BackgroundTransparency = 0.25,
			ZIndex = 5,
			Parent = card,
		})
		Kit.corner(pill, 14)
		Kit.stroke(pill, 2.5)
		Kit.icon("Clock", { Position = UDim2.fromOffset(4, 4), Size = UDim2.fromOffset(34, 34), ZIndex = 6, Parent = pill })
		local label = Kit.text({ Text = "", Position = UDim2.fromOffset(40, 6), Size = UDim2.fromOffset(76, 30), StrokeThickness = 2, ZIndex = 6, Parent = pill })
		table.insert(animators, function()
			label.Text = timer(gift.Minutes * 60 - (played() or 0))
		end)
	end
end

render = function()
	for _, stop in stops do
		stop()
	end
	table.clear(stops)
	table.clear(animators)
	if body then
		body:Destroy()
	end
	local frame = Kit.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 2, Parent = content })
	body = frame
	shownKey = stateKey()

	local _, today = Kit.iconText({
		Position = UDim2.fromOffset(30, 10),
		Size = UDim2.fromOffset(420, 32),
		ZIndex = 3,
		Parent = frame,
	}, "Clock", "")
	local _, reset = Kit.iconText({
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -30, 0, 10),
		Size = UDim2.fromOffset(330, 32),
		ZIndex = 3,
		Parent = frame,
	}, "Calendar", "")
	table.insert(animators, function()
		today.Text = `PLAYED TODAY: {span(played() or 0)}`
		local nextDay = player:GetAttribute("GiftsNext")
		reset.Text = `NEW GIFTS IN {span((if typeof(nextDay) == "number" then nextDay else 0) - workspace:GetServerTimeNow())}`
	end)

	local grid = Kit.new("Frame", {
		Position = UDim2.fromOffset(38, 52),
		Size = UDim2.fromOffset(SIZE.X - 76, 3 * CARD.Y + 2 * 14 + 20),
		BackgroundTransparency = 1,
		ZIndex = 3,
		Parent = frame,
	})
	Kit.new("UIPadding", { PaddingTop = UDim.new(0, 8), Parent = grid })
	Kit.new("UIGridLayout", {
		CellSize = UDim2.fromOffset(CARD.X, CARD.Y),
		CellPadding = UDim2.fromOffset(14, 14),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = grid,
	})
	local claimed = claimedSet()
	local ready = {}
	for _, index in (status()) do
		ready[index] = true
	end
	for index in GIFTS do
		renderCard(grid, index, claimed[index] == true, ready[index] == true)
	end
end

-- The cards wobble and tick; they redraw when a gift opens or gets ready.
RunService.RenderStepped:Connect(function(dt)
	if not (panel and panel.Visible) then
		return
	end
	if stateKey() ~= shownKey then
		render()
	end
	local t = os.clock()
	for _, animate in animators do
		animate(t, dt)
	end
end)

function GiftsMenu.Open()
	if not panel then
		local newPanel, newContent = Kit.modal("FreeGifts", "FREE GIFTS", Kit.Hues.Pink, SIZE, "Gift")
		panel, content = newPanel, newContent
	end
	Kit.open(panel :: Frame)
	render()
end

-- The gift button on the HUD's right column: the time to the next gift under it, or a
-- gold OPEN! while one waits; gone once all nine are open. A toast when one gets ready.
function GiftsMenu.Init()
	local gui = Kit.getGui()
	local button = Kit.button({
		Name = "FreeGiftsButton",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -24, 0, BUTTON_TOP),
		Size = UDim2.fromOffset(64, 64),
		Visible = false,
		Parent = gui,
	}, Kit.pair(Kit.Hues.Pink), nil, GiftsMenu.Open, "Gift")
	local pill = Kit.text({
		Text = "",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 1, 2),
		Size = UDim2.fromOffset(86, 26),
		BackgroundTransparency = 0.15,
		BackgroundColor3 = DARK,
		StrokeThickness = 2,
		ZIndex = 5,
		Parent = button,
	})
	Kit.new("UICorner", { CornerRadius = UDim.new(0.5, 0), Parent = pill })
	Kit.stroke(pill, 2.5)
	local glyph = button:FindFirstChild("Icon") :: ImageLabel?

	local knownReady: number? = nil
	task.spawn(function()
		while true do
			local seconds = played()
			if seconds then
				local ready, _, left = status()
				local calendar = gui:FindFirstChild("DailyLoginButton") :: GuiObject?
				button.Position = UDim2.new(1, -24, 0, if calendar and calendar.Visible then BUTTON_TOP else BUTTON_TOP_ALONE)
				button.Visible = not allOpened()
				if #ready > 0 then
					pill.Text = "OPEN!"
					pill.TextColor3 = GOLD
					pill.BackgroundColor3 = Color3.fromRGB(200, 60, 150)
					Kit.pop(button, 0.12)
				else
					pill.Text = if left then timer(left) else ""
					pill.TextColor3 = Kit.White
					pill.BackgroundColor3 = DARK
				end
				-- a toast when one gets ready (not on joining, during the guide, or with the menu open)
				local step = player:GetAttribute("Guide")
				local quiet = step == nil or Guide.Focused(step :: string) or (panel ~= nil and panel.Visible)
				if knownReady and #ready > knownReady and not quiet then
					Kit.toast("FREE GIFT ready!", Color3.fromRGB(255, 150, 220), "Gift")
					Kit.playSound(Sounds.Jingle, 0.35)
				end
				knownReady = #ready
			end
			task.wait(if seconds then 0.5 else 1)
		end
	end)
	if glyph then
		RunService.RenderStepped:Connect(function()
			if button.Visible then
				local t = os.clock()
				local ready = pill.Text == "OPEN!"
				glyph.Rotation = math.sin(t * (if ready then 9 else 2)) * (if ready then 14 else 6)
			end
		end)
	end
end

return GiftsMenu
