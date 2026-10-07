--[[
	QuestsDaily
	The QUESTS menu's DAILY tab (GDD §5 "Daily quests", Config/DailyMissions): today's
	three quests as wide rows, green EASY, blue MEDIUM, purple HARD, each with its icon,
	goal, progress bar and reward, a pulsing CLAIM! once done and a tick once claimed; a
	gold bonus row for all three; a countdown to tomorrow's. AchievementsMenu draws it
	into its body and runs its animations. Services/DailyMissions mirrors the quests as
	the "Missions" attribute (JSON). Client only.
]]

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local DailyMissions = require(Config:WaitForChild("DailyMissions"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Rewards = require(Shared:WaitForChild("Rewards"))
local Sounds = require(Config:WaitForChild("Sounds"))
local Kit = require(script.Parent:WaitForChild("Kit"))
local Loot = require(script.Parent:WaitForChild("Loot"))

local GOLD = Color3.fromRGB(255, 215, 60)
local GOOD_COLOR = Color3.fromRGB(120, 245, 110)
local BAD_COLOR = Color3.fromRGB(255, 90, 90)
local DARK = Color3.fromRGB(40, 32, 60)
local CLAIM_COLORS = { Color3.fromRGB(255, 240, 120), Color3.fromRGB(255, 160, 30) }
local BAR_COLORS = { Color3.fromRGB(140, 245, 120), Color3.fromRGB(40, 180, 60) }
local SLOTS = {
	{ Name = "EASY", Hue = Kit.Hues.Green },
	{ Name = "MEDIUM", Hue = Kit.Hues.Blue },
	{ Name = "HARD", Hue = Kit.Hues.Purple },
}
local ROW_WIDTH = 940

local player = Players.LocalPlayer
local claiming = false
local cachedJson: string? = nil
local cached: any = nil

export type Entry = { Id: string, Goal: number, Progress: number, Claimed: boolean }
export type State = { Day: number, Next: number, Bonus: boolean, List: { Entry } }

-- The context AchievementsMenu draws it in: lists its animations go into, and a way to
-- draw the menu again.
export type Context = {
	Animators: { (t: number, dt: number) -> () },
	Updaters: { () -> () },
	Pulse: (object: GuiObject, amount: number, speed: number) -> (),
	Rerender: () -> (),
}

local QuestsDaily = {}

-- Today's quests (nil before the data comes).
function QuestsDaily.State(): State?
	local json = player:GetAttribute("Missions")
	if typeof(json) ~= "string" then
		return nil
	end
	if json ~= cachedJson then
		local ok, decoded = pcall(HttpService.JSONDecode, HttpService, json)
		cachedJson, cached = json, if ok and typeof(decoded) == "table" then decoded else nil
	end
	return cached
end

local function isDone(entry: Entry): boolean
	return entry.Progress >= entry.Goal
end

local function allClaimed(state: State): boolean
	for _, entry in state.List do
		if not entry.Claimed then
			return false
		end
	end
	return #state.List > 0
end

-- The quests done but not claimed, and whether the bonus waits.
function QuestsDaily.Ready(): ({ number }, boolean)
	local state = QuestsDaily.State()
	local ready = {}
	if not state then
		return ready, false
	end
	for index, entry in state.List do
		if isDone(entry) and not entry.Claimed then
			table.insert(ready, index)
		end
	end
	return ready, allClaimed(state) and not state.Bonus
end

function QuestsDaily.ReadyCount(): number
	local ready, bonus = QuestsDaily.Ready()
	return #ready + (if bonus then 1 else 0)
end

-- Whether every quest and the bonus are claimed today.
function QuestsDaily.AllDone(): boolean
	local state = QuestsDaily.State()
	return state ~= nil and state.Bonus
end

-- What the rows depend on beyond their bars: the day, each one done/claimed, the bonus.
function QuestsDaily.Key(): string
	local state = QuestsDaily.State()
	if not state then
		return "-"
	end
	local parts = { tostring(state.Day), if state.Bonus then "B" else "b" }
	for _, entry in state.List do
		table.insert(parts, `{entry.Id}{if isDone(entry) then "!" else ""}{if entry.Claimed then "c" else ""}`)
	end
	return table.concat(parts, ",")
end

local function income(): number
	local value = player:GetAttribute("Income")
	return if typeof(value) == "number" then value else 0
end

-- "5h 12m", "12m 30s"
local function clock(seconds: number): string
	seconds = math.max(0, math.floor(seconds))
	if seconds >= 3600 then
		return `{seconds // 3600}h {seconds % 3600 // 60}m`
	end
	return `{seconds // 60}m {seconds % 60}s`
end

local function celebrate(text: string, icon: string, result: any)
	local gui = Kit.getGui()
	Kit.flash(gui :: any, GOLD, 70)
	Kit.confetti(gui :: any, { GOLD, GOOD_COLOR, Color3.fromRGB(120, 220, 255), Color3.fromRGB(255, 120, 220) }, 60, 70)
	Kit.playSound(Sounds.RevealBig, 0.5)
	Kit.toast(text, GOOD_COLOR, icon)
	if result then
		task.wait(0.6)
		Loot.Show(result)
	end
end

local function claim(context: Context, index: number?)
	if claiming then
		return
	end
	claiming = true
	local remote = Remotes.Function(if index then "ClaimMission" else "ClaimMissionBonus")
	local ok, result
	if index then
		ok, result = pcall(remote.InvokeServer, remote, index)
	else
		ok, result = pcall(remote.InvokeServer, remote)
	end
	claiming = false
	if not (ok and typeof(result) == "table") then
		Kit.toast("Try again!", BAD_COLOR, "Warning")
		return
	end
	local reward = if index then DailyMissions.Rewards[index] else DailyMissions.Bonus
	context.Rerender()
	celebrate(result.Text or "", Rewards.Icon(reward), result.Result)
end

-- The reward on a white chip: its icon and words.
local function rewardChip(parent: GuiObject, reward: Rewards.Reward, position: UDim2, context: Context)
	local chip = Kit.new("Frame", {
		Position = position,
		Size = UDim2.fromOffset(176, 68),
		BackgroundColor3 = Kit.White,
		BackgroundTransparency = 0.15,
		ZIndex = 5,
		Parent = parent,
	})
	Kit.corner(chip, 16)
	Kit.stroke(chip, 3)
	Kit.icon(Rewards.Icon(reward), { Position = UDim2.fromOffset(6, 6), Size = UDim2.fromOffset(56, 56), ZIndex = 6, Parent = chip })
	local label = Kit.text({
		Text = "",
		Position = UDim2.fromOffset(66, 12),
		Size = UDim2.fromOffset(104, 44),
		TextXAlignment = Enum.TextXAlignment.Left,
		StrokeThickness = 2.5,
		ZIndex = 6,
		Parent = chip,
	})
	local function update()
		label.Text = Rewards.Text(reward, income())
	end
	update()
	table.insert(context.Updaters, update)
end

-- A claimed row: dimmed, with a big tick.
local function tick(row: GuiObject)
	local shade = Kit.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = DARK, BackgroundTransparency = 0.5, ZIndex = 8, Parent = row })
	Kit.corner(shade, 20)
	Kit.icon("Check", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -40, 0.5, 0), Size = UDim2.fromOffset(72, 72), ZIndex = 9, Parent = shade })
end

local function renderRow(parent: GuiObject, index: number, entry: Entry, y: number, context: Context)
	local mission = DailyMissions.ById[entry.Id]
	local slot = SLOTS[index] or SLOTS[#SLOTS]
	if not mission then
		return
	end
	local done = isDone(entry)
	local ready = done and not entry.Claimed
	local row = Kit.new("Frame", {
		Position = UDim2.fromOffset(30, y),
		Size = UDim2.fromOffset(ROW_WIDTH, 96),
		BackgroundColor3 = Kit.White,
		ZIndex = 3,
		Parent = parent,
	})
	Kit.corner(row, 20)
	Kit.stroke(row, if ready then 5 else 4, if ready then GOLD else nil)
	Kit.gradient(row, Kit.pair(slot.Hue))
	Kit.stripes(row, 0.8, 20, 3)
	Kit.shine(row, 16)
	if ready then
		Kit.neonRim(row, GOLD, 20, 5)
		context.Pulse(row, 0.015, 5)
	end

	local badge = Kit.new("Frame", {
		Position = UDim2.fromOffset(14, 6),
		Size = UDim2.fromOffset(72, 72),
		BackgroundColor3 = DARK,
		BackgroundTransparency = 0.35,
		ZIndex = 5,
		Parent = row,
	})
	Kit.new("UICorner", { CornerRadius = UDim.new(0.5, 0), Parent = badge })
	Kit.stroke(badge, 3)
	local glyph = Kit.icon(mission.Icon, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(58, 58), ZIndex = 6, Parent = badge })
	if ready then
		table.insert(context.Animators, function(t)
			glyph.Rotation = math.sin(t * 6) * 10
		end)
	end
	local pill = Kit.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 1, 4),
		Size = UDim2.fromOffset(82, 22),
		BackgroundColor3 = slot.Hue.Dark,
		ZIndex = 7,
		Parent = badge,
	})
	Kit.new("UICorner", { CornerRadius = UDim.new(0.5, 0), Parent = pill })
	Kit.stroke(pill, 2.5)
	Kit.text({ Text = slot.Name, Position = UDim2.fromScale(0.08, 0.1), Size = UDim2.fromScale(0.84, 0.8), StrokeThickness = 2, ZIndex = 8, Parent = pill })

	Kit.text({
		Text = DailyMissions.Text(mission, entry.Goal),
		Position = UDim2.fromOffset(104, 10),
		Size = UDim2.fromOffset(460, 36),
		TextXAlignment = Enum.TextXAlignment.Left,
		StrokeThickness = 3,
		ZIndex = 5,
		Parent = row,
	})
	local track = Kit.new("Frame", {
		Position = UDim2.fromOffset(104, 54),
		Size = UDim2.fromOffset(460, 28),
		BackgroundColor3 = DARK,
		BackgroundTransparency = 0.25,
		ZIndex = 5,
		Parent = row,
	})
	Kit.new("UICorner", { CornerRadius = UDim.new(0.5, 0), Parent = track })
	Kit.stroke(track, 3)
	local fill = Kit.new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = Kit.White, ZIndex = 5, Parent = track })
	Kit.new("UICorner", { CornerRadius = UDim.new(0.5, 0), Parent = fill })
	Kit.gradient(fill, if done then CLAIM_COLORS else BAR_COLORS)
	local barText = Kit.text({ Text = "", Position = UDim2.fromScale(0.04, 0.08), Size = UDim2.fromScale(0.92, 0.84), StrokeThickness = 2.5, ZIndex = 6, Parent = track })
	local function updateBar()
		local state = QuestsDaily.State()
		local live = state and state.List[index]
		local progress = if live and live.Id == entry.Id then live.Progress else entry.Progress
		local fraction = math.clamp(progress / math.max(entry.Goal, 1), 0, 1)
		fill.Size = UDim2.fromScale(fraction, 1)
		fill.Visible = fraction > 0.02
		barText.Text = if progress >= entry.Goal then "DONE!" else DailyMissions.Progress(mission, progress, entry.Goal)
	end
	updateBar()
	table.insert(context.Updaters, updateBar)

	rewardChip(row, DailyMissions.Rewards[index], UDim2.fromOffset(584, 14), context)
	if ready then
		local button = Kit.button({
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -16, 0.5, 0),
			Size = UDim2.fromOffset(150, 60),
			ZIndex = 6,
			Parent = row,
		}, CLAIM_COLORS, "CLAIM!", function()
			task.spawn(claim, context, index)
		end)
		context.Pulse(button, 0.05, 6)
	elseif entry.Claimed then
		tick(row)
	end
end

local function renderBonus(parent: GuiObject, state: State, y: number, context: Context)
	local claimedCount = 0
	for _, entry in state.List do
		if entry.Claimed then
			claimedCount += 1
		end
	end
	local ready = allClaimed(state) and not state.Bonus
	local row = Kit.new("Frame", {
		Position = UDim2.fromOffset(30, y),
		Size = UDim2.fromOffset(ROW_WIDTH, 92),
		BackgroundColor3 = Kit.White,
		ZIndex = 3,
		Parent = parent,
	})
	Kit.corner(row, 20)
	Kit.stroke(row, 5, if ready then GOLD else nil)
	Kit.gradient(row, Kit.pair(Kit.Hues.Gold))
	Kit.stripes(row, 0.74, 20, 3)
	Kit.shine(row, 16)
	Kit.sheen(row, 2.5, 4)
	Kit.neonRim(row, if ready then GOLD else Kit.Hues.Gold.Neon, 20, 5)
	if ready then
		context.Pulse(row, 0.015, 5)
	end
	local gift = Kit.icon("Gift", { Position = UDim2.fromOffset(16, 6), Size = UDim2.fromOffset(80, 80), ZIndex = 6, Parent = row })
	table.insert(context.Animators, function(t)
		gift.Rotation = math.sin(t * (if ready then 6 else 2)) * (if ready then 10 else 5)
	end)
	Kit.text({
		Text = "Finish all 3 quests!",
		Position = UDim2.fromOffset(110, 10),
		Size = UDim2.fromOffset(450, 36),
		TextXAlignment = Enum.TextXAlignment.Left,
		StrokeThickness = 3,
		ZIndex = 5,
		Parent = row,
	})
	-- a tick per quest claimed
	for index = 1, DailyMissions.Count do
		local filled = index <= claimedCount
		local dot = Kit.new("Frame", {
			Position = UDim2.fromOffset(110 + (index - 1) * 44, 50),
			Size = UDim2.fromOffset(34, 34),
			BackgroundColor3 = if filled then Color3.fromRGB(80, 210, 90) else DARK,
			BackgroundTransparency = if filled then 0 else 0.4,
			ZIndex = 5,
			Parent = row,
		})
		Kit.new("UICorner", { CornerRadius = UDim.new(0.5, 0), Parent = dot })
		Kit.stroke(dot, 3)
		if filled then
			Kit.icon("Check", { Position = UDim2.fromOffset(3, 3), Size = UDim2.fromOffset(28, 28), ZIndex = 6, Parent = dot })
		end
	end
	rewardChip(row, DailyMissions.Bonus, UDim2.fromOffset(584, 12), context)
	if ready then
		local button = Kit.button({
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -16, 0.5, 0),
			Size = UDim2.fromOffset(150, 60),
			ZIndex = 6,
			Parent = row,
		}, CLAIM_COLORS, "CLAIM!", function()
			task.spawn(claim, context, nil)
		end)
		context.Pulse(button, 0.05, 6)
	elseif state.Bonus then
		tick(row)
	end
end

-- Draws the tab into `frame` (its top at `top`).
function QuestsDaily.Render(frame: GuiObject, top: number, context: Context)
	local state = QuestsDaily.State()
	if not state then
		Kit.text({ Text = "Loading...", Position = UDim2.fromOffset(0, top + 120), Size = UDim2.new(1, 0, 0, 40), ZIndex = 3, Parent = frame })
		return
	end
	for index, entry in state.List do
		renderRow(frame, index, entry, top + 8 + (index - 1) * 106, context)
	end
	renderBonus(frame, state, top + 8 + DailyMissions.Count * 106 + 4, context)
	local _, label = Kit.iconText({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, top + 8 + DailyMissions.Count * 106 + 106),
		Size = UDim2.fromOffset(700, 30),
		ZIndex = 3,
		Parent = frame,
	}, "Clock", "")
	local function update()
		local current = QuestsDaily.State()
		label.Text = `NEW QUESTS IN {clock((if current then current.Next else 0) - workspace:GetServerTimeNow())}`
	end
	update()
	table.insert(context.Animators, function()
		update()
	end)
end

return QuestsDaily
