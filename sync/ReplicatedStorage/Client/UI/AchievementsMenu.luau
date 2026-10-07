--[[
	AchievementsMenu
	The QUESTS menu: two tabs, DAILY (today's three quests: Client/UI/QuestsDaily) and
	ACHIEVEMENTS, each with a gold count while something there waits to be claimed.
	The achievements (GDD §5 "Achievements", Config/Achievements): a card per
	achievement, in the colors of the tier it's on (Common silver, Uncommon green, Rare
	blue, Legendary gold, Mythic pink, Godly a turning rainbow), each tier dressed up a
	little more (a gloss, a neon rim, a sheen, twinkles, a sunburst) with a star per
	tier; its goal, a progress bar and what the tier pays (Gems and/or Coins). A finished
	tier pulses with a big CLAIM!; claiming it pays, bursts into confetti and the card
	steps up to the next tier's colors. Ready ones come first, maxed ones last.
	Opened from the QUESTS button on the HUD (UIController), which wears a gold CLAIM!
	while a tier or a quest waits; a toast says when one is done (not during Tralalero's
	guide, nor while the menu is open). Services/AchievementManager mirrors the progress
	as attributes. Client only.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local Achievements = require(Config:WaitForChild("Achievements"))
local Format = require(Shared:WaitForChild("Format"))
local Guide = require(Config:WaitForChild("Guide"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Sounds = require(Config:WaitForChild("Sounds"))
local Kit = require(script.Parent:WaitForChild("Kit"))
local QuestsDaily = require(script.Parent:WaitForChild("QuestsDaily"))

local SIZE = Vector2.new(1000, 640)
local CARD = Vector2.new(300, 206)
local GOLD = Color3.fromRGB(255, 215, 60)
local BAD_COLOR = Color3.fromRGB(255, 90, 90)
local DARK = Color3.fromRGB(40, 32, 60)
local CLAIM_COLORS = { Color3.fromRGB(255, 240, 120), Color3.fromRGB(255, 160, 30) }
local BAR_COLORS = { Color3.fromRGB(140, 245, 120), Color3.fromRGB(40, 180, 60) }
local RAINBOW = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 100, 100)),
	ColorSequenceKeypoint.new(0.25, Color3.fromRGB(255, 220, 80)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(110, 240, 130)),
	ColorSequenceKeypoint.new(0.75, Color3.fromRGB(100, 180, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(220, 120, 255)),
})
local MAX_STARS = 8
local TWINKLES = { { 0.9, 0.12 }, { 0.62, 0.3 }, { 0.95, 0.62 }, { 0.08, 0.86 }, { 0.5, 0.08 } } -- (x, y) on the card

local player = Players.LocalPlayer
local panel: Frame? = nil
local content: Frame? = nil
local body: Frame? = nil
local claiming = false
local justClaimed: string? = nil
local stops: { () -> () } = {}
local animators: { (t: number, dt: number) -> () } = {}
local updaters: { () -> () } = {}
local shownKey = "" -- (the tiers and ready ones the cards were drawn with)
local tab = "DAILY" -- "DAILY" | "ACHIEVEMENTS"
local TAB_TOP = 64 -- (the tabs above it)

local AchievementsMenu = {}

-- State ------------------------------------------------------------------------

local function claimedOf(achievement: Achievements.Achievement): number
	local value = player:GetAttribute(`AchTier_{achievement.Id}`)
	return if typeof(value) == "number" then value else 0
end

local function progressOf(achievement: Achievements.Achievement): number
	local value = player:GetAttribute(`Ach_{achievement.Id}`)
	return if typeof(value) == "number" then value else 0
end

local function income(): number
	local value = player:GetAttribute("Income")
	return if typeof(value) == "number" then value else 0
end

type State = { Claimed: number, Total: number, Tier: number, Goal: number, Value: number, Ready: boolean, Maxed: boolean }

local function stateOf(achievement: Achievements.Achievement): State
	local claimed, total = claimedOf(achievement), Achievements.Tiers(achievement)
	local maxed = claimed >= total
	local tier = math.min(claimed + 1, total)
	local goal = Achievements.Goal(achievement, tier)
	local value = progressOf(achievement)
	return { Claimed = claimed, Total = total, Tier = tier, Goal = goal, Value = value, Ready = not maxed and value >= goal, Maxed = maxed }
end

-- How many tiers wait to be claimed (nil before the data has come).
function AchievementsMenu.ReadyCount(): number?
	if player:GetAttribute(`AchTier_{Achievements.List[1].Id}`) == nil then
		return nil
	end
	local count = 0
	for _, achievement in Achievements.List do
		if stateOf(achievement).Ready then
			count += 1
		end
	end
	return count
end

-- What the cards depend on beyond their bars: each one's tier and whether it's ready.
local function stateKey(): string
	local parts = {}
	for _, achievement in Achievements.List do
		local state = stateOf(achievement)
		table.insert(parts, `{state.Claimed}{if state.Ready then "!" else ""}`)
	end
	return tab .. table.concat(parts, ",") .. QuestsDaily.Key()
end

-- Claiming -----------------------------------------------------------------------

local render: () -> ()

local function claim(achievementId: string)
	if claiming then
		return
	end
	claiming = true
	local remote = Remotes.Function("ClaimAchievement")
	local ok, result = pcall(remote.InvokeServer, remote, achievementId)
	claiming = false
	if not (ok and typeof(result) == "table") then
		Kit.toast("Try again!", BAD_COLOR, "Warning")
		return
	end
	local rarity = Achievements.TierRarity(result.Tier)
	local color = if rarity.Id == "Godly" then GOLD else rarity.Color
	local gui = Kit.getGui()
	Kit.flash(gui :: any, color, 70)
	Kit.confetti(gui :: any, { color, GOLD, Color3.fromRGB(120, 220, 255), Color3.fromRGB(255, 120, 220) }, 60, 70)
	Kit.playSound(Sounds.RevealBig, 0.5)
	if (result.Coins or 0) > 0 then
		Kit.playSound(Sounds.Coins, 0.4)
	end
	local rewards = {}
	if (result.Gems or 0) > 0 then
		table.insert(rewards, `+{Format.Number(result.Gems)} GEMS`)
	end
	if (result.Coins or 0) > 0 then
		table.insert(rewards, `+{Format.Number(result.Coins)} COINS`)
	end
	Kit.toast(table.concat(rewards, "  "), GOLD, if (result.Gems or 0) > 0 then "Gem" else "Coin")
	justClaimed = result.Id
	task.delay(2, function()
		if justClaimed == result.Id then
			justClaimed = nil
		end
	end)
	render()
end

-- Cards ----------------------------------------------------------------------------

-- A card's colors: its tier's rarity, or the turning rainbow (Godly, and maxed ones).
local function paint(frame: GuiObject, look: number, rainbow: boolean)
	if rainbow then
		local gradient = Kit.new("UIGradient", { Color = RAINBOW, Rotation = 45, Parent = frame })
		table.insert(animators, function(_t, dt)
			gradient.Rotation = (gradient.Rotation + dt * 50) % 360
		end)
	else
		local color = Achievements.TierRarity(look).Color
		Kit.gradient(frame, { color:Lerp(Kit.White, 0.3), color:Lerp(Color3.new(0, 0, 0), 0.22) })
	end
end

local function pulse(object: GuiObject, amount: number, speed: number)
	local scale = Kit.new("UIScale", { Parent = object })
	table.insert(animators, function(t)
		scale.Scale = 1 + math.sin(t * speed) * amount
	end)
end

-- Gems and Coins a tier pays, left to right.
local function rewardRow(parent: GuiObject, achievement: Achievements.Achievement, tier: number, position: UDim2, width: number)
	local row = Kit.new("Frame", {
		Position = position,
		Size = UDim2.fromOffset(width, 30),
		BackgroundTransparency = 1,
		ZIndex = 5,
		Parent = parent,
	})
	Kit.new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = row,
	})
	local icons: { [string]: ImageLabel } = {}
	local labels: { [string]: TextLabel } = {}
	for order, kind in { "Gem", "Coin" } do
		icons[kind] = Kit.icon(kind, { LayoutOrder = order * 2 - 1, Size = UDim2.fromOffset(30, 30), ZIndex = 5, Parent = row })
		labels[kind] = Kit.text({
			Text = "",
			TextScaled = false,
			TextSize = 24,
			TextXAlignment = Enum.TextXAlignment.Left,
			AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.fromOffset(0, 28),
			LayoutOrder = order * 2,
			ZIndex = 5,
			Parent = row,
		})
	end
	local function update()
		local gems, coins = Achievements.Reward(achievement, tier, income())
		for kind, amount in { Gem = gems, Coin = coins } do
			labels[kind].Text = Format.Number(amount) .. (if kind == "Gem" then "  " else "")
			labels[kind].Visible = amount > 0
			icons[kind].Visible = amount > 0
		end
	end
	update()
	table.insert(updaters, update)
end

local function renderCard(parent: GuiObject, achievement: Achievements.Achievement, order: number)
	local state = stateOf(achievement)
	local look = if state.Maxed then state.Total else state.Tier -- (the tier whose colors it wears)
	local rainbow = state.Maxed or look >= 6
	local card = Kit.new("Frame", {
		Name = achievement.Id,
		LayoutOrder = order,
		BackgroundColor3 = Kit.White,
		ZIndex = 3,
		Parent = parent,
	})
	Kit.corner(card, 20)
	local outline = Kit.stroke(card, if state.Ready then 5 else 4, if state.Ready then GOLD else nil)
	paint(card, look, rainbow)
	Kit.stripes(card, if look >= 4 then 0.74 else 0.8, 20, 3)
	if look >= 2 then
		Kit.shine(card, 16)
	end
	if look >= 3 or state.Ready then
		Kit.neonRim(card, if state.Ready then GOLD else Achievements.TierRarity(look).Color:Lerp(Kit.White, 0.5), 20, 5)
	end
	if look >= 4 then
		Kit.sheen(card, if look >= 6 then 1.6 else 2.6, 4)
	end
	if look >= 4 then -- twinkles: more each tier
		for index = 1, math.min(#TWINKLES, look - 2) do
			local spot = TWINKLES[index]
			local twinkle = Kit.icon("Sparkle", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(spot[1], spot[2]),
				Size = UDim2.fromOffset(22, 22),
				ZIndex = 4,
				Parent = card,
			})
			table.insert(animators, function(t)
				local wave = (math.sin(t * 3 + index * 1.7) + 1) / 2
				twinkle.ImageTransparency = 1 - wave
				twinkle.Rotation = t * 40 + index * 30
			end)
		end
	end
	if state.Ready then
		outline.Color = GOLD
		pulse(card, 0.025, 5)
	end

	-- its icon on a round badge, a sunburst behind it from Godly up
	local badge = Kit.new("Frame", {
		Position = UDim2.fromOffset(14, 8),
		Size = UDim2.fromOffset(76, 76),
		BackgroundColor3 = DARK,
		BackgroundTransparency = 0.35,
		ZIndex = 5,
		Parent = card,
	})
	Kit.new("UICorner", { CornerRadius = UDim.new(0.5, 0), Parent = badge })
	Kit.stroke(badge, 3)
	if rainbow or state.Ready then
		table.insert(stops, Kit.rays(badge, if state.Ready then GOLD else Color3.fromRGB(255, 250, 210), 150, 4))
	end
	local glyph = Kit.icon(achievement.Icon, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(62, 62),
		ZIndex = 6,
		Parent = badge,
	})
	-- its tier on a pill over the badge's foot, in the tier's colors
	local pill = Kit.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 1, 2),
		Size = UDim2.fromOffset(74, 24),
		BackgroundColor3 = Kit.White,
		ZIndex = 7,
		Parent = badge,
	})
	Kit.new("UICorner", { CornerRadius = UDim.new(0.5, 0), Parent = pill })
	Kit.stroke(pill, 2.5)
	paint(pill, look, rainbow)
	Kit.text({
		Text = if state.Maxed then "MAX" else `TIER {state.Tier}`,
		Position = UDim2.fromScale(0.08, 0.1),
		Size = UDim2.fromScale(0.84, 0.8),
		StrokeThickness = 2,
		ZIndex = 8,
		Parent = pill,
	})
	if state.Ready then
		table.insert(animators, function(t)
			glyph.Rotation = math.sin(t * 6) * 10
		end)
	end
	if state.Maxed then
		Kit.icon("Crown", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0, -4), Size = UDim2.fromOffset(44, 44), Rotation = -12, ZIndex = 7, Parent = badge })
	end

	Kit.text({
		Text = achievement.Name,
		Position = UDim2.fromOffset(102, 14),
		Size = UDim2.fromOffset(188, 34),
		TextXAlignment = Enum.TextXAlignment.Left,
		StrokeThickness = 3,
		ZIndex = 5,
		Parent = card,
	})
	-- a star per tier reached (the one it's on included), up to MAX_STARS
	local stars = math.min(if state.Maxed then state.Total else state.Tier, MAX_STARS)
	Kit.stars({ Position = UDim2.fromOffset(100, 54), Size = UDim2.fromOffset(190, 26), ZIndex = 5, Parent = card }, stars, "Left")
	Kit.text({
		Text = if state.Maxed then "Every tier done!" else Achievements.Text(achievement, state.Tier),
		Position = UDim2.fromOffset(14, 100),
		Size = UDim2.fromOffset(272, 26),
		TextXAlignment = Enum.TextXAlignment.Left,
		StrokeThickness = 2.5,
		ZIndex = 5,
		Parent = card,
	})

	-- the progress bar
	local track = Kit.new("Frame", {
		Position = UDim2.fromOffset(12, 132),
		Size = UDim2.fromOffset(276, 26),
		BackgroundColor3 = DARK,
		BackgroundTransparency = 0.25,
		ZIndex = 5,
		Parent = card,
	})
	Kit.new("UICorner", { CornerRadius = UDim.new(0.5, 0), Parent = track })
	Kit.stroke(track, 3)
	local fill = Kit.new("Frame", {
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = Kit.White,
		ZIndex = 5,
		Parent = track,
	})
	Kit.new("UICorner", { CornerRadius = UDim.new(0.5, 0), Parent = fill })
	Kit.gradient(fill, if state.Ready or state.Maxed then CLAIM_COLORS else BAR_COLORS)
	local barText = Kit.text({
		Text = "",
		Position = UDim2.fromScale(0.04, 0.08),
		Size = UDim2.fromScale(0.92, 0.84),
		StrokeThickness = 2.5,
		ZIndex = 6,
		Parent = track,
	})
	local function updateBar()
		local value = progressOf(achievement)
		local fraction = if state.Maxed then 1 else math.clamp(value / state.Goal, 0, 1)
		fill.Size = UDim2.fromScale(fraction, 1)
		fill.Visible = fraction > 0.02
		if state.Maxed then
			barText.Text = "MAXED"
		elseif achievement.Kind ~= "Counter" then
			barText.Text = if value >= state.Goal then "DONE!" else "NOT YET"
		else
			barText.Text = `{Achievements.Amount(achievement, math.min(value, state.Goal))} / {Achievements.Amount(achievement, state.Goal)}`
		end
	end
	updateBar()
	table.insert(updaters, updateBar)

	if state.Maxed then
		return card
	end
	rewardRow(card, achievement, state.Tier, UDim2.fromOffset(14, 168), if state.Ready then 150 else 272)
	if state.Ready then
		local button = Kit.button({
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -10, 0, 162),
			Size = UDim2.fromOffset(122, 38),
			ZIndex = 6,
			Parent = card,
		}, CLAIM_COLORS, "CLAIM!", function()
			task.spawn(claim, achievement.Id)
		end)
		pulse(button, 0.05, 6)
	end
	return card
end

render = function()
	for _, stop in stops do
		stop()
	end
	table.clear(stops)
	table.clear(animators)
	table.clear(updaters)
	if body then
		body:Destroy()
	end
	local frame = Kit.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 2, Parent = content })
	body = frame
	shownKey = stateKey()

	-- the tabs, each with a gold count of what waits there
	local counts = { DAILY = QuestsDaily.ReadyCount(), ACHIEVEMENTS = AchievementsMenu.ReadyCount() or 0 }
	for index, name in { "DAILY", "ACHIEVEMENTS" } do
		local button = Kit.button({
			Position = UDim2.fromOffset(30 + (index - 1) * 290, 8),
			Size = UDim2.fromOffset(276, 50),
			ZIndex = 3,
			Parent = frame,
		}, if tab == name then Kit.pair(Kit.Hues.Teal) else Kit.Colors.Grey, name, function()
			if tab ~= name then
				tab = name
				render()
			end
		end, if name == "DAILY" then "Calendar" else "Trophy")
		if counts[name] > 0 then
			local count = Kit.text({
				Text = tostring(counts[name]),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(1, -4, 0, 4),
				Size = UDim2.fromOffset(34, 34),
				BackgroundTransparency = 0,
				BackgroundColor3 = Color3.fromRGB(255, 185, 30),
				StrokeThickness = 2,
				ZIndex = 7,
				Parent = button,
			})
			Kit.new("UICorner", { CornerRadius = UDim.new(0.5, 0), Parent = count })
			Kit.stroke(count, 3)
			pulse(count, 0.08, 6)
		end
	end

	if tab == "DAILY" then
		QuestsDaily.Render(frame, TAB_TOP, { Animators = animators, Updaters = updaters, Pulse = pulse, Rerender = render })
		return
	end

	local ready = counts.ACHIEVEMENTS
	Kit.iconText({
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -30, 0, 16),
		Size = UDim2.fromOffset(380, 32),
		ZIndex = 3,
		Parent = frame,
	}, "Star", if ready > 0 then `{ready} READY!` else "Every tier pays more!", if ready > 0 then GOLD else Kit.White)

	local grid = Kit.new("ScrollingFrame", {
		Position = UDim2.fromOffset(20, TAB_TOP + 4),
		Size = UDim2.new(1, -40, 1, -TAB_TOP - 12),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 8,
		ScrollBarImageColor3 = Kit.Hues.Teal.Dark,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ZIndex = 3,
		Parent = frame,
	})
	-- (room round the cards for their pulse and outline)
	Kit.new("UIPadding", { PaddingTop = UDim.new(0, 10), PaddingLeft = UDim.new(0, 8), PaddingBottom = UDim.new(0, 12), Parent = grid })
	Kit.new("UIGridLayout", {
		CellSize = UDim2.fromOffset(CARD.X, CARD.Y),
		CellPadding = UDim2.fromOffset(14, 14),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = grid,
	})
	-- ready ones first, then the rest in the list's order, maxed ones last
	for index, achievement in Achievements.List do
		local state = stateOf(achievement)
		local order = index + (if state.Ready then 0 elseif state.Maxed then 200 else 100)
		local card = renderCard(grid, achievement, order)
		if justClaimed == achievement.Id then -- (it just stepped up a tier)
			justClaimed = nil
			Kit.pop(card, 0.18)
			Kit.flash(card, Kit.White, 9)
		end
	end
end

-- The cards pulse, twinkle and turn; bars follow the progress as it comes.
RunService.RenderStepped:Connect(function(dt)
	if not (panel and panel.Visible) then
		return
	end
	local t = os.clock()
	for _, animate in animators do
		animate(t, dt)
	end
end)

local function onChanged()
	if not (panel and panel.Visible) then
		return
	end
	if stateKey() ~= shownKey then
		render() -- (a tier claimed or done: the cards change)
	else
		for _, update in updaters do
			update()
		end
	end
end

-- Opens on the tab with something to claim (DAILY first), else on DAILY until today's
-- quests are all claimed.
function AchievementsMenu.Open()
	if not panel then
		local newPanel, newContent = Kit.modal("Achievements", "QUESTS", Kit.Hues.Teal, SIZE, "Trophy")
		panel, content = newPanel, newContent
	end
	if QuestsDaily.ReadyCount() > 0 then
		tab = "DAILY"
	elseif (AchievementsMenu.ReadyCount() or 0) > 0 or QuestsDaily.AllDone() then
		tab = "ACHIEVEMENTS"
	else
		tab = "DAILY"
	end
	Kit.open(panel :: Frame)
	render()
end

-- Puts a gold CLAIM! on the HUD's QUESTS button while a tier waits, and says when one is
-- done (a toast; not during Tralalero's guide, or for the ones ready on joining).
function AchievementsMenu.Init(button: GuiObject)
	local badge = Kit.text({
		Text = "CLAIM!",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(1, -10, 0, 6),
		Size = UDim2.fromOffset(76, 30),
		BackgroundTransparency = 0,
		BackgroundColor3 = Color3.fromRGB(255, 185, 30),
		StrokeThickness = 2,
		Rotation = 12,
		ZIndex = 5,
		Visible = false,
		Parent = button,
	})
	Kit.new("UICorner", { CornerRadius = UDim.new(0.5, 0), Parent = badge })
	Kit.stroke(badge, 3)

	local known: { [string]: boolean }? = nil -- (which were ready; nil until the data comes)
	-- (done in the last moment, a name and a color each: one toast for all)
	local pending: { { Name: string, Color: Color3 } } = {}
	local function quiet(): boolean -- (during the guide, and while the menu shows them)
		local step = player:GetAttribute("Guide")
		return step == nil or Guide.Focused(step :: string) or (panel ~= nil and panel.Visible)
	end
	local function announce()
		local done = table.clone(pending)
		table.clear(pending)
		if quiet() or #done == 0 then
			return
		end
		if #done == 1 then
			Kit.toast(`{done[1].Name} done! Claim it!`, done[1].Color, "Trophy")
		else
			Kit.toast(`{#done} quests done! Claim them!`, GOLD, "Trophy")
		end
		Kit.playSound(Sounds.Jingle, 0.35)
	end
	local function check()
		local count = AchievementsMenu.ReadyCount()
		local quests = QuestsDaily.State()
		if not (count and quests) then
			return
		end
		badge.Visible = count + QuestsDaily.ReadyCount() > 0
		local now: { [string]: boolean } = {}
		local function seen(key: string, ready: boolean, name: string, color: Color3)
			now[key] = ready
			if ready and known and not known[key] then
				if #pending == 0 then
					task.delay(1, announce)
				end
				table.insert(pending, { Name = name, Color = color })
			end
		end
		for _, achievement in Achievements.List do
			local state = stateOf(achievement)
			local rarity = Achievements.TierRarity(state.Tier)
			seen(achievement.Id, state.Ready, achievement.Name, if rarity.Id == "Godly" then GOLD else rarity.Color:Lerp(Kit.White, 0.3))
		end
		for _, index in (QuestsDaily.Ready()) do
			seen(`Quest_{quests.Day}_{index}`, true, "DAILY QUEST", Color3.fromRGB(140, 245, 120))
		end
		known = now
	end
	player.AttributeChanged:Connect(function(name: string)
		if string.sub(name, 1, 4) == "Ach_" or string.sub(name, 1, 8) == "AchTier_" or name == "Income" or name == "Missions" then
			check()
			onChanged()
		end
	end)
	check()
	task.spawn(function()
		while true do
			task.wait(1.2)
			if badge.Visible then
				Kit.pop(badge, 0.35)
				Kit.pop(button, 0.12)
			end
		end
	end)
end

return AchievementsMenu
