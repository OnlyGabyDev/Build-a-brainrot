--[[
	LoadingScreen
	Our own loading screen (the user, 2026-10-03): it replaces Roblox's default as soon
	as the client starts and stays until the game has loaded and your character is in
	the world (the server holds characters until the map is built: Main.server), then
	fades away. A pink-to-purple backdrop with brainrot emoji drifting up, the title, a
	bouncing 🧠, a progress bar and rotating tips.

	It runs from ReplicatedFirst, before anything else has replicated, so it can't use
	Kit or any shared module: everything here is self-contained.
]]

local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local FONT = Enum.Font.FredokaOne
local INK = Color3.fromRGB(30, 25, 45)
local GOLD = Color3.fromRGB(255, 215, 60)
local TIMEOUT = 60 -- seconds: whatever happens, the screen goes by then
local MIN_TIME = 2.5 -- seconds: long enough to read the title
local DRIFTERS = { "🧠", "🦈", "🥁", "🐊", "🍌", "☕", "🐸", "🦒", "💣", "🍉", "🐄", "👟" }
local TIPS = {
	"💡 Equip your rarest parts on a line to earn more Coins!",
	"💡 A full match (4 parts of one brainrot) ships for much more!",
	"💡 Loot boxes appear all over the map: grab them!",
	"💡 Every room has its own machines and its own edition to collect.",
	"💡 Rebirth to earn +25% income and unlock rarer parts!",
	"💡 Spin the Daily Wheel every day for free prizes!",
	"💡 Line upgrades: tap a line's tablet to make it faster and richer.",
}
local STATUS = {
	{ At = 0, Text = "Waking up the brainrots..." },
	{ At = 0.3, Text = "Building the factories..." },
	{ At = 0.6, Text = "Oiling the machines..." },
	{ At = 0.85, Text = "Almost there!" },
}

local player = Players.LocalPlayer
ReplicatedFirst:RemoveDefaultLoadingScreen()

local function new(className: string, props: { [string]: any }): any
	local instance = Instance.new(className)
	for key, value in props do
		if key ~= "Parent" then
			(instance :: any)[key] = value
		end
	end
	instance.Parent = props.Parent
	return instance
end

local function label(props: { [string]: any }, stroke: number?): TextLabel
	props.BackgroundTransparency = 1
	props.Font = FONT
	props.TextScaled = true
	props.TextColor3 = props.TextColor3 or Color3.new(1, 1, 1)
	local text = new("TextLabel", props)
	if stroke and stroke > 0 then
		new("UIStroke", { Thickness = stroke, Color = INK, Parent = text })
	end
	return text
end

local screen = new("ScreenGui", {
	Name = "LoadingScreen",
	IgnoreGuiInset = true,
	ResetOnSpawn = false,
	DisplayOrder = 100,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	Parent = player:WaitForChild("PlayerGui"),
})
local back = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = screen })
new("UIGradient", {
	Rotation = 90,
	Color = ColorSequence.new(Color3.fromRGB(255, 110, 200), Color3.fromRGB(110, 50, 220)),
	Parent = back,
})

-- emoji drifting up the screen, each its own size, speed and sway
local drifters = {}
local random = Random.new()
for index = 1, 22 do
	local size = random:NextNumber(0.05, 0.1)
	local drifter = label({
		Text = DRIFTERS[(index - 1) % #DRIFTERS + 1],
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromScale(size, size),
		TextTransparency = 0.35,
		Parent = back,
	})
	new("UIAspectRatioConstraint", { Parent = drifter })
	table.insert(drifters, {
		Label = drifter,
		X = random:NextNumber(0.03, 0.97),
		Phase = random:NextNumber(),
		Speed = random:NextNumber(0.03, 0.07),
		Sway = random:NextNumber(0.01, 0.03),
		Spin = random:NextNumber(-20, 20),
	})
end

local middle = new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromScale(0.8, 0.7),
	BackgroundTransparency = 1,
	Parent = back,
})
new("UISizeConstraint", { MaxSize = Vector2.new(1100, 640), Parent = middle })
local brain = label({ Text = "🧠", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0), Size = UDim2.fromScale(0.22, 0.26), Parent = middle })
new("UIAspectRatioConstraint", { Parent = brain })
local title = label({
	Text = "BUILD A BRAINROT",
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.fromScale(0.5, 0.27),
	Size = UDim2.fromScale(1, 0.22),
	Parent = middle,
}, 6)
new("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.new(1, 1, 1), GOLD), Parent = title })
label({ Text = "🏭 Brainrot Factory Tycoon 🏭", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.49), Size = UDim2.fromScale(0.7, 0.08), Parent = middle }, 3)

local bar = new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.fromScale(0.5, 0.66),
	Size = UDim2.fromScale(0.7, 0.07),
	BackgroundColor3 = Color3.fromRGB(50, 30, 90),
	Parent = middle,
})
new("UICorner", { CornerRadius = UDim.new(0.5, 0), Parent = bar })
new("UIStroke", { Thickness = 4, Color = INK, Parent = bar })
local fill = new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = Color3.new(1, 1, 1), Parent = bar })
new("UICorner", { CornerRadius = UDim.new(0.5, 0), Parent = fill })
new("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(255, 240, 140), Color3.fromRGB(255, 160, 30)), Parent = fill })
local status = label({ Text = STATUS[1].Text, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.75), Size = UDim2.fromScale(0.6, 0.07), Parent = middle }, 3)
local tip = label({ Text = TIPS[random:NextInteger(1, #TIPS)], AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.88), Size = UDim2.fromScale(0.9, 0.06), Parent = middle }, 2)

-- Progress is an estimate: it creeps toward each stage's cap (the game loaded, then the
-- character in the world) and never reaches 1 before both are done.
local started = os.clock()
local progress = 0
local function target(): number
	if not game:IsLoaded() then
		return 0.6
	elseif not player.Character then
		return 0.95
	end
	return 1
end

local nextTip = os.clock() + 3.5
local connection = RunService.RenderStepped:Connect(function(dt)
	local t = os.clock() - started
	for _, drifter in drifters do
		local y = 1.1 - ((drifter.Phase + t * drifter.Speed) % 1.2)
		drifter.Label.Position = UDim2.fromScale(drifter.X + math.sin(t * 1.3 + drifter.Phase * 9) * drifter.Sway, y)
		drifter.Label.Rotation = math.sin(t + drifter.Phase * 5) * drifter.Spin
	end
	brain.Position = UDim2.new(0.5, 0, 0, -math.abs(math.sin(t * 3)) * 18)
	brain.Rotation = math.sin(t * 3) * 6
	progress += (target() - progress) * math.min(1, dt * 1.6)
	fill.Size = UDim2.fromScale(math.max(progress, 0.06), 1)
	for _, stage in STATUS do
		if progress >= stage.At then
			status.Text = stage.Text
		end
	end
	if os.clock() >= nextTip then
		nextTip = os.clock() + 3.5
		tip.Text = TIPS[random:NextInteger(1, #TIPS)]
	end
end)

-- Wait for the game and the character (or the timeout), then fade out.
local deadline = os.clock() + TIMEOUT
while os.clock() < deadline and not (game:IsLoaded() and player.Character and os.clock() - started >= MIN_TIME) do
	task.wait(0.1)
end
progress = 1
status.Text = "Let's go! 🚀"
task.wait(0.4)

local fade = TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
TweenService:Create(back, fade, { BackgroundTransparency = 1 }):Play()
for _, child in back:GetDescendants() do
	if child:IsA("TextLabel") then
		TweenService:Create(child, fade, { TextTransparency = 1 }):Play()
	elseif child:IsA("UIStroke") then
		TweenService:Create(child, fade, { Transparency = 1 }):Play()
	elseif child:IsA("Frame") then
		TweenService:Create(child, fade, { BackgroundTransparency = 1 }):Play()
	end
end
task.wait(0.7)
connection:Disconnect()
screen:Destroy()
