--[[
	DailyLoginMenu
	The login streak's calendar (GDD §5, Config/DailyLogin): a card per day (the ones
	claimed in this streak ticked, today's gold and pulsing over a sunburst, the rest
	waiting, day 7 the big one), a huge CLAIM! and, once claimed, a countdown to the
	next. It pops up on the first join of each UTC day (UIController, after Tralalero's
	guide) and opens from the calendar button on the HUD (top right, a "!" while today's
	waits). Services/DailyLogin grants the rewards. Client only.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local DailyLogin = require(Config:WaitForChild("DailyLogin"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Sounds = require(Config:WaitForChild("Sounds"))
local Kit = require(script.Parent:WaitForChild("Kit"))
local Loot = require(script.Parent:WaitForChild("Loot"))

local DAYS = DailyLogin.Days
local SIZE = Vector2.new(900, 520)
local CARD = Vector2.new(104, 200)
local BIG_CARD = Vector2.new(160, 200) -- day 7
local GAP = 12
local GOLD = Color3.fromRGB(255, 215, 60)
local GOOD_COLOR = Color3.fromRGB(120, 245, 110)
local BAD_COLOR = Color3.fromRGB(255, 90, 90)
local CLAIM_COLORS = { Color3.fromRGB(255, 240, 120), Color3.fromRGB(255, 160, 30) }
local KIND_COLORS: { [string]: { Color3 } } = {
	Coins = Kit.Colors.Coins,
	Gems = Kit.Colors.Gems,
	Rolls = Kit.Colors.Rolls,
	Box = { Color3.fromRGB(130, 210, 255), Color3.fromRGB(40, 110, 230) },
	RarePart = { Color3.fromRGB(255, 150, 230), Color3.fromRGB(140, 60, 240) },
}

local player = Players.LocalPlayer
local panel: Frame? = nil
local content: Frame? = nil
local body: Frame? = nil
local claiming = false
local stops: { () -> () } = {}
local pulses: { UIScale } = {}
local countdown: TextLabel? = nil

local DailyLoginMenu = {}

local function day(): number
	local value = player:GetAttribute("DailyDay")
	return if typeof(value) == "number" then math.clamp(value, 1, #DAYS) else 1
end

local function ready(): boolean
	return player:GetAttribute("DailyReady") == true
end

-- "5h 12m", "12m 30s"
local function clock(seconds: number): string
	seconds = math.max(0, math.floor(seconds))
	if seconds >= 3600 then
		return `{seconds // 3600}h {seconds % 3600 // 60}m`
	end
	return `{seconds // 60}m {seconds % 60}s`
end

local function untilNext(): number
	local nextDay = player:GetAttribute("DailyNext")
	return if typeof(nextDay) == "number" then nextDay - workspace:GetServerTimeNow() else 0
end

local render: () -> ()

local function claim()
	if claiming then
		return
	end
	claiming = true
	local remote = Remotes.Function("ClaimDailyLogin")
	local ok, result = pcall(remote.InvokeServer, remote)
	claiming = false
	if not (ok and typeof(result) == "table") then
		Kit.toast("Try again!", BAD_COLOR, "Warning")
		return
	end
	local reward = DAYS[result.Day] or DAYS[1]
	local gui = Kit.getGui()
	Kit.flash(gui :: any, GOLD, 70)
	Kit.confetti(gui :: any, { GOLD, GOOD_COLOR, Color3.fromRGB(120, 220, 255), Color3.fromRGB(255, 120, 220) }, 70, 70)
	Kit.playSound(Sounds.RevealBig, 0.5)
	Kit.toast(result.Text or reward.Label, GOOD_COLOR, reward.Icon)
	if result.Result then
		-- day 7's part: shown on its reveal card
		if panel then
			Kit.close(panel)
		end
		task.wait(0.6)
		Loot.Show(result.Result)
	end
end

-- One day's card: its reward's icon and name on its colors; ticked once claimed in this
-- streak, gold and pulsing over a sunburst when it's today's.
local function renderCard(parent: Frame, index: number, x: number, claimed: boolean, today: boolean)
	local reward = DAYS[index]
	local size = if index == #DAYS then BIG_CARD else CARD
	local card = Kit.new("Frame", {
		Position = UDim2.fromOffset(x, 64 + (if today then -8 else 0)),
		Size = UDim2.fromOffset(size.X, size.Y),
		BackgroundColor3 = Kit.White,
		ZIndex = 3,
		Parent = parent,
	})
	Kit.corner(card, 18)
	Kit.stroke(card, if today then 6 else 4, if today then GOLD else nil)
	Kit.gradient(card, KIND_COLORS[reward.Kind] or Kit.Colors.Purple)
	Kit.stripes(card, 0.8, 18, 3)
	Kit.shine(card, 14)
	if today then
		Kit.neonRim(card, GOLD, 18, 5)
		table.insert(stops, Kit.rays(card, Color3.fromRGB(255, 250, 210), size.X * 1.6, 3))
		local scale = Kit.new("UIScale", { Parent = card })
		table.insert(pulses, scale)
	end
	Kit.text({ Text = if index == #DAYS then "DAY 7!" else `DAY {index}`, Position = UDim2.fromOffset(6, 8), Size = UDim2.new(1, -12, 0, 28), StrokeThickness = 3, ZIndex = 5, Parent = card })
	local iconSize = if index == #DAYS then 96 else 70
	Kit.icon(reward.Icon, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0, 92), Size = UDim2.fromOffset(iconSize, iconSize), ZIndex = 5, Parent = card })
	Kit.text({ Text = reward.Label, Position = UDim2.fromOffset(6, 140), Size = UDim2.new(1, -12, 0, 48), TextWrapped = true, StrokeThickness = 2.5, ZIndex = 5, Parent = card })
	if claimed then
		local done = Kit.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(30, 25, 45), BackgroundTransparency = 0.45, ZIndex = 6, Parent = card })
		Kit.corner(done, 18)
		Kit.icon("Check", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.48), Size = UDim2.fromOffset(72, 72), ZIndex = 7, Parent = done })
	end
end

render = function()
	for _, stop in stops do
		stop()
	end
	table.clear(stops)
	table.clear(pulses)
	countdown = nil
	if body then
		body:Destroy()
	end
	local frame = Kit.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 2, Parent = content })
	body = frame

	local current, open = day(), ready()
	-- (this streak's days before today are claimed; today's too once it's claimed)
	local claimedUpTo = if open then current - 1 else current
	Kit.text({
		Text = if open then `DAY {current}: your reward is ready!` else "Come back tomorrow!",
		Position = UDim2.fromOffset(24, 10),
		Size = UDim2.new(1, -48, 0, 40),
		StrokeThickness = 3.5,
		ZIndex = 3,
		Parent = frame,
	})
	local width = (#DAYS - 1) * CARD.X + BIG_CARD.X + (#DAYS - 1) * GAP
	local x = (SIZE.X - width) / 2
	for index = 1, #DAYS do
		renderCard(frame, index, x, index <= claimedUpTo, open and index == current)
		x += (if index == #DAYS then BIG_CARD.X else CARD.X) + GAP
	end

	if open then
		local button = Kit.button({
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, 290),
			Size = UDim2.fromOffset(400, 92),
			ZIndex = 5,
			Parent = frame,
		}, CLAIM_COLORS, "CLAIM!", function()
			task.spawn(claim)
		end, "Gift")
		Kit.stripes(button, 0.8, 14, 5)
		table.insert(pulses, Kit.new("UIScale", { Parent = button }))
	else
		countdown = Kit.text({
			Text = "",
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, 300),
			Size = UDim2.fromOffset(600, 50),
			TextColor3 = GOLD,
			StrokeThickness = 4,
			ZIndex = 3,
			Parent = frame,
		})
	end
	Kit.iconText({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 396),
		Size = UDim2.fromOffset(760, 30),
		ZIndex = 3,
		Parent = frame,
	}, "Calendar", "Come back every day! Miss one and it starts over.")
end

-- Today's card and the CLAIM! button pulse, the countdown ticks.
RunService.RenderStepped:Connect(function()
	if not (panel and panel.Visible) then
		return
	end
	local t = os.clock()
	for _, scale in pulses do
		scale.Scale = 1 + math.sin(t * 5) * 0.04
	end
	if countdown then
		countdown.Text = `NEXT REWARD IN {clock(untilNext())}`
	end
end)

-- Redraw as the server's word changes (a claim, a new day).
for _, name in { "DailyDay", "DailyReady" } do
	player:GetAttributeChangedSignal(name):Connect(function()
		if panel and panel.Visible then
			render()
		end
	end)
end

function DailyLoginMenu.Open()
	if not panel then
		local newPanel, newContent = Kit.modal("DailyLogin", "DAILY REWARDS", Kit.Hues.Orange, SIZE, "Calendar")
		panel, content = newPanel, newContent
	end
	Kit.open(panel :: Frame)
	render()
end

-- Opens the calendar if today's reward waits, and yields until it's closed. Returns
-- whether it opened.
function DailyLoginMenu.ShowIfReady(): boolean
	if not ready() then
		return false
	end
	DailyLoginMenu.Open()
	repeat
		task.wait(0.25)
	until not (panel and panel.Visible)
	return true
end

-- The calendar button on the HUD (top right, under the settings), a "!" pulsing on it
-- while today's reward waits.
function DailyLoginMenu.Init()
	local button = Kit.button({
		Name = "DailyLoginButton",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -24, 0, 228),
		Size = UDim2.fromOffset(64, 64),
		Parent = Kit.getGui(),
	}, Kit.pair(Kit.Hues.Orange), nil, DailyLoginMenu.Open, "Calendar")
	local badge = Kit.text({
		Text = "!",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, 6, 0, 6),
		Size = UDim2.fromOffset(30, 30),
		BackgroundTransparency = 0,
		BackgroundColor3 = Color3.fromRGB(235, 60, 60),
		StrokeThickness = 2,
		ZIndex = 5,
		Visible = false,
		Parent = button,
	})
	Kit.new("UICorner", { CornerRadius = UDim.new(0.5, 0), Parent = badge })
	Kit.stroke(badge, 3)
	task.spawn(function()
		while true do
			badge.Visible = ready()
			if badge.Visible then
				Kit.pop(badge, 0.3)
			end
			task.wait(1)
		end
	end)
end

return DailyLoginMenu
