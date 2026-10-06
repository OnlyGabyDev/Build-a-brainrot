--[[
	Rebirth Menu
	Rebirthing and the Rebirth Shop (GDD §10). The left side shows the next rebirth:
	its cost, what you get (points, income, unlocks) and what resets. The right side
	sells permanent upgrades for Rebirth Points. The server validates everything.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local Format = require(Shared:WaitForChild("Format"))
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

local function levels(): Rebirths.Levels
	local result = {}
	for _, upgrade in Rebirths.Upgrades do
		result[upgrade.Id] = stat(`Upgrade_{upgrade.Id}`)
	end
	return result
end

-- What unlocks at exactly `rebirths` rebirths: built zones.
local function unlocksAt(rebirths: number): { string }
	local list = {}
	for _, zone in Zones.List do
		if zone.Available and zone.UnlockRebirths == rebirths then
			table.insert(list, `🔓 The {zone.Name} opens`)
		end
	end
	return list
end

local render: () -> ()

local function line(parent: Instance, text: string, y: number, color: Color3?, height: number?)
	Kit.text({
		Text = text,
		TextColor3 = color or Kit.White,
		Position = UDim2.fromOffset(24, y),
		Size = UDim2.fromOffset(400, height or 28),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = parent,
	})
end

local function rebirth()
	local reached = stat("Rebirths") + 1
	local remote = Remotes.Function("Rebirth")
	local ok, done, points = pcall(remote.InvokeServer, remote)
	if not (ok and done) then
		Kit.toast("Not enough Coins yet!", BAD_COLOR)
		return
	end
	local gui = Kit.getGui()
	Kit.flash(gui :: any, GOLD_COLOR, 70)
	Kit.confetti(gui :: any, { GOLD_COLOR, GOOD_COLOR, Color3.fromRGB(120, 220, 255), Color3.fromRGB(255, 120, 220) }, 120, 70)
	Kit.playSound(Sounds.RevealBig, 0.6)
	Kit.toast(`🎉 REBIRTH {reached}! +{points or 1} ⭐`, GOLD_COLOR)
	task.wait(0.2)
	render()
end

local function renderRebirth(parent: Frame)
	local rebirths = stat("Rebirths")
	local coins = stat("Coins")
	local cost = Rebirths.Cost(rebirths)
	local ready = coins >= cost

	Kit.text({
		Text = `🔄 REBIRTH {rebirths} → {rebirths + 1}`,
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
	Kit.text({
		Text = `💰 {Format.Number(coins)} / {Format.Number(cost)}`,
		Position = UDim2.fromOffset(12, 6),
		Size = UDim2.new(1, -24, 1, -12),
		ZIndex = 2,
		Parent = bar,
	})

	-- What you get and what resets.
	local nextIncome = Rebirths.IncomeMultiplier(rebirths + 1, levels())
	-- (bigger lines that fill the column down to the button)
	line(parent, "🎁 YOU GET", 124, GOLD_COLOR, 36)
	line(parent, `⭐ +{Rebirths.Points(math.max(coins, cost), rebirths)} Rebirth Points (more if you save up!)`, 166, nil, 34)
	line(parent, `💰 +{math.floor(Rebirths.IncomeBonus * 100)}% Coins forever (x{string.format("%.2f", nextIncome)} total)`, 204, nil, 34)
	line(parent, `🍀 +{math.floor(Rebirths.LuckPerRebirth * 100)}% Luck forever: rarer parts!`, 244, nil, 34)
	local y = 284
	for _, unlock in unlocksAt(rebirths + 1) do
		line(parent, unlock, y, GOOD_COLOR, 32)
		y += 36
	end
	line(parent, "♻️ Resets your Coins and tycoon.\n✅ Keeps parts, Gems, completions, Rolls and line setups.", math.max(y + 10, 300), MUTED_COLOR, 90)

	Kit.button({
		Position = UDim2.fromOffset(24, 420),
		Size = UDim2.fromOffset(420, 64),
		Parent = parent,
	}, if ready then Kit.Colors.Green else Kit.Colors.Grey, if ready then "🔄 REBIRTH!" else `Need 💰 {Format.Number(cost - coins)} more`, function()
		if ready then
			rebirth()
		else
			Kit.toast("Keep building brainrots!", BAD_COLOR)
		end
	end)
end

local function renderShop(parent: Frame)
	local x = 476
	Kit.text({
		Text = `⭐ {Format.Number(stat("RebirthPoints"))} REBIRTH POINTS`,
		TextColor3 = GOLD_COLOR,
		Position = UDim2.fromOffset(x, 14),
		Size = UDim2.fromOffset(420, 44),
		TextXAlignment = Enum.TextXAlignment.Left,
		StrokeThickness = 3,
		Parent = parent,
	})
	local current = levels()
	for index, upgrade in Rebirths.Upgrades do
		local level = current[upgrade.Id] or 0
		local maxed = level >= upgrade.MaxLevel
		local cost = Rebirths.UpgradeCost(upgrade, level)
		local row = Kit.new("Frame", {
			Position = UDim2.fromOffset(x, 70 + (index - 1) * 108),
			Size = UDim2.fromOffset(420, 96),
			BackgroundColor3 = Kit.White,
			Parent = parent,
		})
		Kit.corner(row, 18)
		Kit.stroke(row, 4)
		Kit.gradient(row, Kit.Colors.Purple)
		Kit.text({ Text = upgrade.Icon, Position = UDim2.fromOffset(10, 14), Size = UDim2.fromOffset(64, 64), StrokeThickness = 0, Parent = row })
		-- name, level and what it does on their own lines, each capped at one size so
		-- every row reads the same (a long name used to shrink its whole line)
		for _, spec in {
			{ upgrade.Name, 8, 30, 28, Kit.White },
			{ `LV {level}/{upgrade.MaxLevel}`, 40, 22, 20, GOLD_COLOR },
			{ `{upgrade.Description} per level`, 64, 22, 17, Color3.fromRGB(235, 225, 255) },
		} do
			local label = Kit.text({
				Text = spec[1],
				TextColor3 = spec[5],
				Position = UDim2.fromOffset(84, spec[2]),
				Size = UDim2.fromOffset(206, spec[3]),
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = row,
			})
			Kit.new("UITextSizeConstraint", { MaxTextSize = spec[4], Parent = label })
		end
		Kit.button({
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -14, 0.5, 0),
			Size = UDim2.fromOffset(110, 56),
			Parent = row,
		}, if maxed then Kit.Colors.Grey else Kit.Colors.Coins, if maxed then "MAX" else `⭐ {cost}`, function()
			if maxed then
				return
			end
			local remote = Remotes.Function("BuyUpgrade")
			local ok, done = pcall(remote.InvokeServer, remote, upgrade.Id)
			if ok and done then
				Kit.toast(`{upgrade.Icon} {upgrade.Name} Lv {level + 1}!`, GOOD_COLOR)
			else
				Kit.toast("Not enough Rebirth Points!", BAD_COLOR)
			end
			task.wait(0.15)
			render()
		end)
	end
end

render = function()
	if body then
		body:Destroy()
	end
	local frame = Kit.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = content })
	body = frame
	renderRebirth(frame)
	renderShop(frame)
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

for _, name in { "Coins", "Rebirths", "RebirthPoints" } do
	player:GetAttributeChangedSignal(name):Connect(queueRender)
end
player.AttributeChanged:Connect(function(name)
	if string.sub(name, 1, 8) == "Upgrade_" then
		queueRender()
	end
end)

function RebirthMenu.Open()
	if not panel then
		local newPanel, newContent = Kit.modal("RebirthMenu", "🔄 REBIRTH", Kit.Colors.Coins, SIZE)
		panel, content = newPanel, newContent
	end
	Kit.open(panel :: Frame)
	render()
end

return RebirthMenu
