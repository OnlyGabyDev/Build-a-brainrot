--[[
	UIController
	The HUD (GDD §13): Coins, Gems and Rolls counters (Player attributes set by
	DataManager), the menu buttons, and a "Configure line" prompt on the tablet beside
	each of your own assembly lines: it flies the camera onto the tablet's screen and
	opens the Line menu there. The menus live in ReplicatedStorage/Client/UI.
]]

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TextChatService = game:GetService("TextChatService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local UI = ReplicatedStorage:WaitForChild("Client"):WaitForChild("UI")
local Format = require(Shared:WaitForChild("Format"))
local Gamepasses = require(Shared:WaitForChild("Config"):WaitForChild("Gamepasses"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Catalog = require(UI:WaitForChild("Catalog"))
local Celebration = require(UI:WaitForChild("Celebration"))
local DailyWheelMenu = require(UI:WaitForChild("DailyWheelMenu"))
local Kit = require(UI:WaitForChild("Kit"))
local LineMenu = require(UI:WaitForChild("LineMenu"))
local Loot = require(UI:WaitForChild("Loot"))
local RebirthMenu = require(UI:WaitForChild("RebirthMenu"))
local SettingsMenu = require(UI:WaitForChild("SettingsMenu"))
local Shop = require(UI:WaitForChild("Shop"))

local COUNTERS = {
	{ Stat = "Coins", Icon = "💰", Colors = Kit.Colors.Coins, Float = Color3.fromRGB(255, 235, 110), Gap = 70 },
	{ Stat = "Gems", Icon = "💎", Colors = Kit.Colors.Gems, Float = Color3.fromRGB(140, 235, 255), Gap = 110 },
	{ Stat = "Rolls", Icon = "🎲", Colors = Kit.Colors.Rolls, Float = Color3.fromRGB(255, 160, 240), Gap = 160 },
}
local COIN_BATCH = 0.7 -- Coins come in all the time: their "+N" shows at most this often
local LINE_REACH = 28 -- a bit under the server's reach, so an open here always works
local TABLET_DISTANCE = 3.4 -- studs from the tablet's screen to the camera, flown in
local TABLET_FOV = 50
local FLY_IN = TweenInfo.new(0.55, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local FLY_OUT = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
local VIP_TAG = '<font color="#FFD23C">[VIP]</font> '

local player = Players.LocalPlayer
local gui = Kit.getGui()

-- Counters -------------------------------------------------------------------
-- Top left, Pet Simulator style: a glossy pill per currency with its icon in a bubble
-- sticking out of its left end; it counts up smoothly, pops, and floats a "+N" off its
-- right end when it goes up.

local counters = Kit.new("Frame", {
	Name = "Counters",
	Position = UDim2.fromOffset(34, 84),
	Size = UDim2.fromOffset(360, 212),
	BackgroundTransparency = 1,
	Parent = gui,
})
Kit.new("UIListLayout", { Padding = UDim.new(0, 16), SortOrder = Enum.SortOrder.LayoutOrder, Parent = counters })

-- A pill that shows a Player attribute, counting up smoothly with a pop.
local function makeCounter(order: number, counter: typeof(COUNTERS[1])): Frame
	local stat = counter.Stat
	local pill = Kit.new("Frame", {
		Name = stat,
		LayoutOrder = order,
		Size = UDim2.fromOffset(236, 60),
		BackgroundColor3 = Kit.White,
		Parent = counters,
	})
	Kit.new("UICorner", { CornerRadius = UDim.new(0.5, 0), Parent = pill })
	Kit.stroke(pill, 4)
	Kit.gradient(pill, counter.Colors)
	Kit.shine(pill, 18)
	-- the icon in its bubble
	local bubble = Kit.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, 14, 0.5, 0),
		Size = UDim2.fromOffset(72, 72),
		BackgroundColor3 = Kit.White,
		ZIndex = 2,
		Parent = pill,
	})
	Kit.new("UICorner", { CornerRadius = UDim.new(0.5, 0), Parent = bubble })
	Kit.stroke(bubble, 4)
	Kit.gradient(bubble, { Kit.White, counter.Colors[1] })
	Kit.text({ Text = counter.Icon, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.72, 0.72), StrokeThickness = 0, ZIndex = 3, Parent = bubble })
	local label = Kit.text({
		Text = "0",
		Position = UDim2.fromOffset(60, 9),
		Size = UDim2.new(1, -78, 1, -18),
		TextXAlignment = Enum.TextXAlignment.Left,
		StrokeThickness = 3,
		Parent = pill,
	})

	local shown = Instance.new("NumberValue")
	shown.Changed:Connect(function(value)
		label.Text = Format.Number(math.floor(value + 0.5))
	end)
	local last = player:GetAttribute(stat) or 0
	local pending, flushing = 0, false
	local function float(amount: number)
		Kit.floatText(pill, `+{Format.Number(amount)}`, counter.Float, UDim2.new(1, counter.Gap, 0.5, 0))
		Kit.pop(bubble, 0.2)
	end
	local function update()
		local target = player:GetAttribute(stat) or 0
		if target > shown.Value then
			Kit.pop(pill, 0.08)
		end
		local gain = target - last
		last = target
		if gain > 0 and stat == "Coins" then
			-- batched, so a busy factory doesn't flood the screen
			pending += gain
			if not flushing then
				flushing = true
				task.delay(COIN_BATCH, function()
					flushing = false
					float(pending)
					pending = 0
				end)
			end
		elseif gain > 0 then
			float(gain)
		end
		TweenService:Create(shown, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Value = target }):Play()
	end
	player:GetAttributeChangedSignal(stat):Connect(update)
	shown.Value = last
	label.Text = Format.Number(last)
	return pill
end

local pills = {}
for order, counter in COUNTERS do
	pills[counter.Stat] = makeCounter(order, counter)
end

Kit.button({
	AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.new(1, 12, 0.5, 0),
	Size = UDim2.fromOffset(96, 50),
	Parent = pills.Rolls,
}, Kit.Colors.Green, "OPEN", Loot.OpenRoll)
Kit.button({
	AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.new(1, 12, 0.5, 0),
	Size = UDim2.fromOffset(50, 50),
	Parent = pills.Gems,
}, Kit.Colors.Green, "+", function()
	Shop.Open("GEMS")
end)

-- Menu buttons ---------------------------------------------------------------

-- Under the counters, two to a row: big glossy squares, their icons bobbing gently.
local buttons = Kit.new("Frame", {
	Name = "MenuButtons",
	Position = UDim2.fromOffset(28, 316),
	Size = UDim2.fromOffset(216, 340),
	BackgroundTransparency = 1,
	Parent = gui,
})
Kit.new("UIGridLayout", {
	CellSize = UDim2.fromOffset(100, 100),
	CellPadding = UDim2.fromOffset(14, 14),
	SortOrder = Enum.SortOrder.LayoutOrder,
	Parent = buttons,
})

local bobbing: { GuiObject } = {}
local function menuButton(order: number, icon: string, label: string, colors: { Color3 }, onClick: () -> ()): TextButton
	local button = Kit.button({ LayoutOrder = order, Parent = buttons }, colors, nil, onClick)
	local glyph = Kit.text({ Text = icon, Position = UDim2.fromScale(0.12, 0.04), Size = UDim2.fromScale(0.76, 0.58), StrokeThickness = 0, Parent = button })
	Kit.text({ Text = label, Position = UDim2.fromScale(0.06, 0.64), Size = UDim2.fromScale(0.88, 0.28), Parent = button })
	table.insert(bobbing, glyph)
	return button
end

RunService.RenderStepped:Connect(function()
	local t = os.clock()
	for index, glyph in bobbing do
		glyph.Position = UDim2.new(0.12, 0, 0.04, math.sin(t * 2.2 + index * 0.9) * 3)
		glyph.Rotation = math.sin(t * 1.6 + index) * 4
	end
end)

-- The line you're standing at, if any.
local function nearbyLine(): string?
	local index = player:GetAttribute("PlotIndex")
	local tycoons = workspace:FindFirstChild("Tycoons")
	local plot = index and tycoons and tycoons:FindFirstChild(`Plot{index}`)
	local lines = plot and plot:FindFirstChild("Lines")
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not (lines and root) then
		return nil
	end
	for _, line in lines:GetChildren() do
		local assembler = line:FindFirstChild("Assembler") :: BasePart?
		if assembler and (assembler.Position - root.Position).Magnitude <= LINE_REACH then
			return line.Name
		end
	end
	return nil
end

-- Configuring lines from anywhere is a gamepass perk (RemoteLines); at a line it's free.
local function openLines()
	if player:GetAttribute("Perk_RemoteLines") then
		LineMenu.Open()
		return
	end
	local lineId = nearbyLine()
	if lineId then
		LineMenu.Open(lineId)
		return
	end
	for _, pass in Gamepasses do
		if pass.RemoteLines and pass.Id > 0 then
			MarketplaceService:PromptGamePassPurchase(player, pass.Id)
			return
		end
	end
	Kit.toast("Walk up to a line to configure it! Remote config: Auto-Collect pass (soon)", Color3.fromRGB(255, 220, 80))
end

menuButton(1, "🏭", "LINES", Kit.Colors.Purple, openLines)
menuButton(2, "📖", "INDEX", Kit.Colors.Gems, Catalog.Open)
menuButton(3, "🔄", "REBIRTH", Kit.Colors.Coins, RebirthMenu.Open)
local wheelButton = menuButton(4, "🎡", "WHEEL", Kit.Colors.Rolls, DailyWheelMenu.Open)
menuButton(5, "🛒", "SHOP", Kit.Colors.Green, function()
	Shop.Open()
end)
SettingsMenu.Init() -- the ⚙️ button, top right

-- A red "!" on the wheel button while a spin is waiting.
local wheelBadge = Kit.text({
	Text = "!",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(1, -8, 0, 8),
	Size = UDim2.fromOffset(36, 36),
	BackgroundTransparency = 0,
	BackgroundColor3 = Color3.fromRGB(235, 60, 60),
	ZIndex = 5,
	Visible = false,
	Parent = wheelButton,
})
Kit.new("UICorner", { CornerRadius = UDim.new(0.5, 0), Parent = wheelBadge })
task.spawn(function()
	while true do
		wheelBadge.Visible = DailyWheelMenu.CanSpin()
		if wheelBadge.Visible then
			Kit.pop(wheelBadge, 0.3) -- (a little pulse, so you notice it)
		end
		task.wait(1)
	end
end)

-- Line prompts ---------------------------------------------------------------

-- Your character stands still while you're at a tablet (anchored on this client only:
-- you own your character's physics, so it just stays put).
local function setFrozen(frozen: boolean)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		root.Anchored = frozen
	end
end

-- Flies the camera onto a line's tablet screen and opens the Line menu right there, as
-- if on the tablet, then flies back once the menu closes.
local atTablet = false
local function useTablet(screen: BasePart, lineId: string)
	if atTablet then
		return
	end
	atTablet = true
	local camera = workspace.CurrentCamera
	local home, homeFov = camera.CFrame, camera.FieldOfView
	local spot = (screen.CFrame * CFrame.new(0, 0, -TABLET_DISTANCE)).Position -- out in front of its screen
	local target = CFrame.lookAt(spot, screen.Position, screen.CFrame.UpVector)
	setFrozen(true)
	camera.CameraType = Enum.CameraType.Scriptable
	Kit.click()
	TweenService:Create(camera, FLY_IN, { CFrame = target, FieldOfView = TABLET_FOV }):Play()
	task.wait(FLY_IN.Time * 0.75)
	LineMenu.Open(lineId)
	-- the menu stays open until you close it (or open another one)
	repeat
		task.wait(0.1)
	until not LineMenu.IsOpen()
	TweenService:Create(camera, FLY_OUT, { CFrame = home, FieldOfView = homeFov }):Play()
	task.wait(FLY_OUT.Time)
	camera.CameraType = Enum.CameraType.Custom
	setFrozen(false)
	atTablet = false
end

-- The part that carries a line's prompt (TycoonManager tags one per zone's machines).
local function findPromptAnchor(line: Instance): BasePart?
	local deadline = os.clock() + 10
	while line.Parent and os.clock() < deadline do
		for _, descendant in line:GetDescendants() do
			if descendant:IsA("BasePart") and descendant:GetAttribute("PromptAnchor") then
				return descendant
			end
		end
		task.wait(0.25)
	end
	return nil
end

local function addLinePrompt(line: Instance)
	local head = findPromptAnchor(line)
	if not head or head:FindFirstChild("ConfigurePrompt") then
		return
	end
	local prompt = Kit.new("ProximityPrompt", {
		Name = "ConfigurePrompt",
		ActionText = "Configure line",
		ObjectText = "Line tablet",
		HoldDuration = 0,
		MaxActivationDistance = 12,
		RequiresLineOfSight = false,
		Parent = head,
	})
	prompt.Triggered:Connect(function()
		task.spawn(useTablet, head, line.Name)
	end)
end

local function watchPlot()
	local index = player:GetAttribute("PlotIndex")
	if not index then
		return
	end
	local plot = workspace:WaitForChild("Tycoons"):WaitForChild(`Plot{index}`)
	local lines = plot:WaitForChild("Lines")
	for _, line in lines:GetChildren() do
		task.spawn(addLinePrompt, line)
	end
	lines.ChildAdded:Connect(function(line)
		task.spawn(addLinePrompt, line)
	end)
end

player:GetAttributeChangedSignal("PlotIndex"):Connect(watchPlot)
task.spawn(watchPlot)

-- New parts and completions show up in open menus right away.
Remotes.Event("InventoryUpdated").OnClientEvent:Connect(function()
	LineMenu.Refresh()
	Catalog.Refresh()
end)

-- Completions ----------------------------------------------------------------

Remotes.Event("Completion").OnClientEvent:Connect(function(_plot, _lineId, brainrotId, editions, gems, firstEver)
	Celebration.Show(brainrotId, editions, gems, firstEver)
end)

-- Big moments from other players (your own get the full banner instead).
Remotes.Event("Announce").OnClientEvent:Connect(function(text: string, color: Color3, from: Player?)
	if from ~= player then
		Kit.toast(`✨ {text} ✨`, color)
	end
end)

-- Purchases & chat -------------------------------------------------------------

-- The server thanks you once a Robux purchase is granted.
Remotes.Event("Purchased").OnClientEvent:Connect(function(text: string)
	Shop.Thanks(text)
end)

-- VIPs get a gold tag in chat.
TextChatService.OnIncomingMessage = function(message: TextChatMessage)
	local source = message.TextSource
	local sender = source and Players:GetPlayerByUserId(source.UserId)
	if sender and sender:GetAttribute("Pass_VIP") then
		local properties = Instance.new("TextChatMessageProperties")
		properties.PrefixText = VIP_TAG .. message.PrefixText
		return properties
	end
	return nil
end
