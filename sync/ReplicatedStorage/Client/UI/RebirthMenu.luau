--[[
	Rebirth Menu
	Rebirthing (GDD §10). The left side shows the next rebirth: its cost, what you get
	(a mascot level, unlocks) and what resets. The right side shows the company mascot
	it levels up (Config/Mascot): what it gives now and after the rebirth, and the look
	it gets next. (The Rebirth Shop that was there is gone: the mascot replaces it.)
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local Format = require(Shared:WaitForChild("Format"))
local MascotConfig = require(Config:WaitForChild("Mascot"))
local Rebirths = require(Config:WaitForChild("Rebirths"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Sounds = require(Config:WaitForChild("Sounds"))
local Zones = require(Config:WaitForChild("Zones"))
local Kit = require(script.Parent:WaitForChild("Kit"))

local SIZE = Vector2.new(920, 580)
local GOOD_COLOR = Color3.fromRGB(120, 245, 110)
local BAD_COLOR = Color3.fromRGB(255, 90, 90)
local GOLD_COLOR = Color3.fromRGB(255, 210, 60)
local MUTED_COLOR = Color3.fromRGB(175, 175, 190)
local RENDER_DELAY = 0.3 -- coalesce attribute changes (Coins tick a lot)

local player = Players.LocalPlayer
local panel: Frame? = nil
local content: Frame? = nil
local body: Frame? = nil
local renderQueued = false

local RebirthMenu = {}

local function stat(name: string): number
	return player:GetAttribute(name) or 0
end

-- The levels bought in the old Rebirth Shop (they still count).
local function levels(): Rebirths.Levels
	local result = {}
	for _, upgrade in Rebirths.Legacy do
		result[upgrade.Id] = stat(`Upgrade_{upgrade.Id}`)
	end
	return result
end

local function percent(value: number): string
	return `+{math.floor(value * 100 + 0.5)}%`
end

-- What unlocks at exactly `rebirths` rebirths: built zones.
local function unlocksAt(rebirths: number): { string }
	local list = {}
	for _, zone in Zones.List do
		if zone.Available and zone.UnlockRebirths == rebirths then
			table.insert(list, `The {zone.Name} opens!`)
		end
	end
	return list
end

local render: () -> ()

-- A line of the left column, with one of our icons before it if given.
local function line(parent: Instance, text: string, y: number, color: Color3?, height: number?, icon: string?)
	local tall = height or 28
	local indent = if icon then tall + 8 else 0
	if icon then
		Kit.icon(icon, { Position = UDim2.fromOffset(22, y - 2), Size = UDim2.fromOffset(tall + 4, tall + 4), Parent = parent })
	end
	Kit.text({
		Text = text,
		TextColor3 = color or Kit.White,
		Position = UDim2.fromOffset(24 + indent, y),
		Size = UDim2.fromOffset(400 - indent, tall),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = parent,
	})
end

local function rebirth()
	local reached = stat("Rebirths") + 1
	local remote = Remotes.Function("Rebirth")
	local ok, done = pcall(remote.InvokeServer, remote)
	if not (ok and done) then
		Kit.toast("Not enough Coins yet!", BAD_COLOR, "Coin")
		return
	end
	local gui = Kit.getGui()
	Kit.flash(gui :: any, GOLD_COLOR, 70)
	Kit.confetti(gui :: any, { GOLD_COLOR, GOOD_COLOR, Color3.fromRGB(120, 220, 255), Color3.fromRGB(255, 120, 220) }, 120, 70)
	Kit.playSound(Sounds.RevealBig, 0.6)
	Kit.toast(`REBIRTH {reached}! Your mascot is LEVEL {reached}!`, GOLD_COLOR, "Party")
	task.wait(0.2)
	render()
end

local function renderRebirth(parent: Frame)
	local rebirths = stat("Rebirths")
	local coins = stat("Coins")
	local cost = Rebirths.Cost(rebirths)
	local ready = coins >= cost

	Kit.text({
		Text = `REBIRTH {rebirths + 1}`,
		Position = UDim2.fromOffset(24, 14),
		Size = UDim2.fromOffset(420, 44),
		TextXAlignment = Enum.TextXAlignment.Left,
		StrokeThickness = 3,
		Parent = parent,
	})

	-- Progress toward the cost.
	local bar = Kit.new("Frame", {
		Position = UDim2.fromOffset(24, 66),
		Size = UDim2.fromOffset(420, 40),
		BackgroundColor3 = Color3.fromRGB(60, 55, 80),
		Parent = parent,
	})
	Kit.corner(bar, 20)
	Kit.stroke(bar, 3.5)
	local fill = Kit.new("Frame", {
		Size = UDim2.fromScale(math.clamp(coins / cost, 0.04, 1), 1),
		BackgroundColor3 = Kit.White,
		Parent = bar,
	})
	Kit.corner(fill, 20)
	Kit.gradient(fill, if ready then Kit.Colors.Green else Kit.Colors.Coins)
	Kit.stripes(fill, 0.75, 20)
	Kit.iconText({
		Position = UDim2.fromOffset(12, 7),
		Size = UDim2.new(1, -24, 0, 26),
		ZIndex = 2,
		Parent = bar,
	}, "Coin", `{Format.Number(coins)} / {Format.Number(cost)}`)

	-- What you get and what resets.
	local nextIncome = Rebirths.IncomeMultiplier(rebirths + 1, levels())
	-- (bigger lines that fill the column down to the button)
	line(parent, "YOU GET", 124, GOLD_COLOR, 36, "Gift")
	line(parent, `+1 MASCOT LEVEL (LV {rebirths + 1})`, 166, nil, 34, "Crown")
	line(parent, `+{math.floor(Rebirths.IncomeBonus * 100)}% Coins (x{string.format("%.2f", nextIncome)})`, 204, nil, 34, "Coin")
	line(parent, `+{math.floor(Rebirths.SpeedBonus * 100)}% Speed, +{math.floor(Rebirths.LuckPerRebirth * 100)}% Luck`, 244, nil, 34, "Clover")
	local y = 284
	for _, unlock in unlocksAt(rebirths + 1) do
		line(parent, unlock, y, GOOD_COLOR, 32, "Unlock")
		y += 36
	end
	line(parent, "Resets Coins and factory.\nKeeps parts, Gems and Rolls.", math.max(y + 10, 300), MUTED_COLOR, 70)

	Kit.button({
		Position = UDim2.fromOffset(24, 420),
		Size = UDim2.fromOffset(420, 64),
		Parent = parent,
	}, if ready then Kit.Colors.Green else Kit.Colors.Grey, if ready then "REBIRTH!" else `Need {Format.Number(cost - coins)} more`, function()
		if ready then
			rebirth()
		else
			Kit.toast("Keep building brainrots!", BAD_COLOR, "Factory")
		end
	end, if ready then "Rebirth" else "Coin")
end

-- The right side: the mascot out front that each rebirth levels up, what it gives now
-- and after this rebirth, and the look it gets next.
local function renderMascot(parent: Frame)
	local x = 476
	local level = stat("Rebirths")
	Kit.icon("Crown", { Position = UDim2.fromOffset(x - 4, 6), Size = UDim2.fromOffset(56, 56), Parent = parent })
	Kit.text({
		Text = `YOUR MASCOT: LV {level}`,
		TextColor3 = GOLD_COLOR,
		Position = UDim2.fromOffset(x + 58, 14),
		Size = UDim2.fromOffset(362, 44),
		TextXAlignment = Enum.TextXAlignment.Left,
		StrokeThickness = 3,
		Parent = parent,
	})
	local upgrades = levels()
	local rows = {
		{ "Coin", "COINS", Rebirths.IncomeMultiplier(level, upgrades) - 1, Rebirths.IncomeMultiplier(level + 1, upgrades) - 1 },
		{ "Lightning", "SPEED", Rebirths.SpeedMultiplier(level, upgrades) - 1, Rebirths.SpeedMultiplier(level + 1, upgrades) - 1 },
		{ "Clover", "LUCK", Rebirths.Luck(level, upgrades), Rebirths.Luck(level + 1, upgrades) },
	}
	for index, row in rows do
		local card = Kit.new("Frame", {
			Position = UDim2.fromOffset(x, 70 + (index - 1) * 84),
			Size = UDim2.fromOffset(420, 74),
			BackgroundColor3 = Kit.White,
			Parent = parent,
		})
		Kit.corner(card, 18)
		Kit.stroke(card, 4)
		Kit.gradient(card, Kit.pair(Kit.Hues.Orange))
		Kit.stripes(card, 0.84, 18)
		Kit.icon(row[1], { Position = UDim2.fromOffset(8, 8), Size = UDim2.fromOffset(58, 58), Parent = card })
		Kit.text({ Text = row[2], Position = UDim2.fromOffset(72, 20), Size = UDim2.fromOffset(110, 34), TextXAlignment = Enum.TextXAlignment.Left, Parent = card })
		Kit.text({ Text = percent(row[3]), Position = UDim2.fromOffset(184, 16), Size = UDim2.fromOffset(100, 42), Parent = card })
		Kit.icon("Arrow", { Position = UDim2.fromOffset(288, 22), Size = UDim2.fromOffset(30, 30), Parent = card })
		Kit.text({ Text = percent(row[4]), TextColor3 = GOOD_COLOR, Position = UDim2.fromOffset(320, 16), Size = UDim2.fromOffset(92, 42), Parent = card })
	end
	-- the look the next level adds
	local look = MascotConfig.NextLook(level)
	Kit.text({
		Text = "It stands in front of your factory\nand levels up every rebirth!",
		TextColor3 = MUTED_COLOR,
		Position = UDim2.fromOffset(x, 332),
		Size = UDim2.fromOffset(420, 64),
		Parent = parent,
	})
	Kit.iconText({
		Position = UDim2.fromOffset(x, 410),
		Size = UDim2.fromOffset(420, 30),
		Parent = parent,
	}, "Sparkle", if look then `At LV {look.Level}: {string.lower(look.Name)}!` else "It grows bigger every rebirth!", GOLD_COLOR)
end

render = function()
	if body then
		body:Destroy()
	end
	local frame = Kit.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = content })
	body = frame
	renderRebirth(frame)
	renderMascot(frame)
end

-- Re-renders shortly after stats change while the menu is open.
local function queueRender()
	if renderQueued or not (panel and panel.Visible) then
		return
	end
	renderQueued = true
	task.delay(RENDER_DELAY, function()
		renderQueued = false
		if panel and panel.Visible then
			render()
		end
	end)
end

for _, name in { "Coins", "Rebirths" } do
	player:GetAttributeChangedSignal(name):Connect(queueRender)
end
player.AttributeChanged:Connect(function(name)
	if string.sub(name, 1, 8) == "Upgrade_" then
		queueRender()
	end
end)

function RebirthMenu.Open()
	if not panel then
		local newPanel, newContent = Kit.modal("RebirthMenu", "REBIRTH", Kit.Hues.Gold, SIZE, "Rebirth")
		panel, content = newPanel, newContent
	end
	Kit.open(panel :: Frame)
	render()
end

return RebirthMenu
