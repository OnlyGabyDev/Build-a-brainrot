--[[
	WelcomeBackMenu
	"WELCOME BACK!": what the factory made while you were away (GDD §16.7,
	Services/OfflineEarnings), a big coin over a sunburst with the amount counting up,
	the time away, and a huge COLLECT that sends the coins flying into the counter.
	Closing it collects too. It's the first join popup (UIController, before the login
	streak's calendar). Client only.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local Format = require(Shared:WaitForChild("Format"))
local Icons = require(Config:WaitForChild("Icons"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Sounds = require(Config:WaitForChild("Sounds"))
local Kit = require(script.Parent:WaitForChild("Kit"))

local SIZE = Vector2.new(640, 440)
local GOLD = Color3.fromRGB(255, 215, 60)
local RAYS_COLOR = Color3.fromRGB(255, 170, 30) -- (a pale gold vanishes on the panel)
local GOOD_COLOR = Color3.fromRGB(120, 245, 110)
local BAD_COLOR = Color3.fromRGB(255, 90, 90)
local COLLECT_COLORS = { Color3.fromRGB(255, 240, 120), Color3.fromRGB(255, 160, 30) }
local COUNT_TIME = 1.2 -- seconds for the amount to count up
local FLYING = 14 -- coins flying into the counter

local player = Players.LocalPlayer
local panel: Frame? = nil
local content: Frame? = nil
local body: Frame? = nil
local coin: ImageLabel? = nil
local amountLabel: TextLabel? = nil
local stops: { () -> () } = {}
local pulses: { UIScale } = {}
local shownAt = 0
local collecting = false
local joined = false -- the join popups have had their turn (later ones show at once)

local WelcomeBackMenu = {}

local function waiting(): number
	local coins = player:GetAttribute("OfflineCoins")
	return if typeof(coins) == "number" then coins else 0
end

-- "1h 23m", "12m"
local function away(seconds: number): string
	local minutes = math.max(1, math.floor(seconds / 60))
	if minutes >= 60 then
		return `{minutes // 60}h {minutes % 60}m`
	end
	return `{minutes}m`
end

-- Coin icons from `from` (a screen point) into the HUD's Coins counter.
local function flyToCounter(from: Vector2)
	local hud = player.PlayerGui:FindFirstChild("BrainrotUI")
	local counters = hud and hud:FindFirstChild("Counters", true)
	local counter = counters and counters:FindFirstChild("Coins") :: GuiObject?
	if not counter then
		return
	end
	local screen = player.PlayerGui:FindFirstChild("FlyingCoins") -- (TycoonFX's, for the Cash Pad)
	if not screen then
		screen = Kit.new("ScreenGui", { Name = "FlyingCoins", IgnoreGuiInset = true, ResetOnSpawn = false, DisplayOrder = 5, Parent = player.PlayerGui })
	end
	local target = counter.AbsolutePosition + Vector2.new(34, counter.AbsoluteSize.Y / 2)
	for index = 1, FLYING do
		task.delay((index - 1) * 0.04, function()
			local label = Kit.new("ImageLabel", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromOffset(from.X + math.random(-70, 70), from.Y + math.random(-50, 50)),
				Size = UDim2.fromOffset(56, 56),
				BackgroundTransparency = 1,
				ScaleType = Enum.ScaleType.Fit,
				Image = Icons.Coin,
				Parent = screen,
			})
			local tween = TweenService:Create(label, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				Position = UDim2.fromOffset(target.X, target.Y),
				Size = UDim2.fromOffset(30, 30),
			})
			tween.Completed:Once(function()
				label:Destroy()
			end)
			tween:Play()
		end)
	end
end

local function collect()
	if collecting or waiting() <= 0 then
		return
	end
	collecting = true
	local from = if coin then coin.AbsolutePosition + coin.AbsoluteSize / 2 else nil
	local remote = Remotes.Function("CollectOffline")
	local ok, coins = pcall(remote.InvokeServer, remote)
	collecting = false
	if not (ok and typeof(coins) == "number") then
		Kit.toast("Try again!", BAD_COLOR, "Warning")
		return
	end
	if coins > 0 then
		if from then
			flyToCounter(from)
		end
		Kit.confetti(Kit.getGui() :: any, { GOLD, GOOD_COLOR, Color3.fromRGB(255, 160, 30), Kit.White }, 60, 70)
		Kit.playSound(Sounds.Coins, 0.6)
		Kit.playSound(Sounds.Jingle, 0.4)
	end
	if panel then
		Kit.close(panel)
	end
end

local function render()
	for _, stop in stops do
		stop()
	end
	table.clear(stops)
	table.clear(pulses)
	if body then
		body:Destroy()
	end
	local frame = Kit.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 2, Parent = content })
	body = frame

	Kit.text({
		Text = "Your factory kept working!",
		Position = UDim2.fromOffset(24, 8),
		Size = UDim2.new(1, -48, 0, 40),
		StrokeThickness = 3.5,
		ZIndex = 3,
		Parent = frame,
	})
	local seconds = player:GetAttribute("OfflineSeconds")
	Kit.iconText({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 52),
		Size = UDim2.fromOffset(400, 30),
		ZIndex = 3,
		Parent = frame,
	}, "Clock", `Away {away(if typeof(seconds) == "number" then seconds else 0)}`)

	-- the big coin over a sunburst, bobbing
	local holder = Kit.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0, 148),
		Size = UDim2.fromOffset(120, 120),
		BackgroundTransparency = 1,
		ZIndex = 2, -- (the rays under the lines of text)
		Parent = frame,
	})
	table.insert(stops, Kit.rays(holder, RAYS_COLOR, 270, 2))
	local icon = Kit.icon("Coin", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(120, 120),
		ZIndex = 5,
		Parent = holder,
	})
	TweenService:Create(icon, TweenInfo.new(1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Rotation = 10, Position = UDim2.new(0.5, 0, 0.5, -8) }):Play()
	coin = icon
	table.insert(pulses, Kit.new("UIScale", { Parent = icon }))

	amountLabel = Kit.text({
		Text = "+0",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 206),
		Size = UDim2.fromOffset(560, 64),
		TextColor3 = GOLD,
		StrokeThickness = 5,
		ZIndex = 5,
		Parent = frame,
	})

	local button = Kit.button({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 280),
		Size = UDim2.fromOffset(380, 80),
		ZIndex = 5,
		Parent = frame,
	}, COLLECT_COLORS, "COLLECT!", function()
		task.spawn(collect)
	end, "Coin")
	Kit.stripes(button, 0.8, 14, 5)
	table.insert(pulses, Kit.new("UIScale", { Parent = button }))
	shownAt = os.clock()
end

-- The coin and COLLECT! pulse; the amount counts up.
RunService.RenderStepped:Connect(function()
	if not (panel and panel.Visible) then
		return
	end
	local t = os.clock()
	for _, scale in pulses do
		scale.Scale = 1 + math.sin(t * 5) * 0.04
	end
	local label = amountLabel
	if label then
		local progress = math.clamp((t - shownAt) / COUNT_TIME, 0, 1)
		local eased = 1 - (1 - progress) ^ 3
		label.Text = `+{Format.Number(math.floor(waiting() * eased))}`
	end
end)

function WelcomeBackMenu.Open()
	if not panel then
		local newPanel, newContent = Kit.modal("WelcomeBack", "WELCOME BACK!", Kit.Hues.Gold, SIZE, "Factory")
		panel, content = newPanel, newContent
		-- closing it (the X, or another menu) collects too: nothing is left behind
		newPanel:GetPropertyChangedSignal("Visible"):Connect(function()
			if not newPanel.Visible then
				task.spawn(collect)
			end
		end)
	end
	Kit.open(panel :: Frame)
	render()
	Kit.playSound(Sounds.Cash, 0.5)
end

-- Opens it if the factory made something while they were away, and yields until it's
-- closed. Returns whether it opened. After this, earnings that turn up later (Studio's
-- SetAway) show at once.
function WelcomeBackMenu.ShowIfWaiting(): boolean
	joined = true
	if waiting() <= 0 then
		return false
	end
	WelcomeBackMenu.Open()
	repeat
		task.wait(0.25)
	until not (panel and panel.Visible)
	return true
end

function WelcomeBackMenu.Init()
	player:GetAttributeChangedSignal("OfflineCoins"):Connect(function()
		if joined and waiting() > 0 and not (panel and panel.Visible) then
			WelcomeBackMenu.Open()
		end
	end)
end

return WelcomeBackMenu
