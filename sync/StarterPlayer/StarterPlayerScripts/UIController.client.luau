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
local Shop = require(UI:WaitForChild("Shop"))

local COUNTERS = {
	{ Stat = "Coins", Icon = "💰", Colors = Kit.Colors.Coins },
	{ Stat = "Gems", Icon = "💎", Colors = Kit.Colors.Gems },
	{ Stat = "Rolls", Icon = "🎲", Colors = Kit.Colors.Rolls },
}
local LINE_REACH = 28 -- a bit under the server's reach, so an open here always works
local TABLET_DISTANCE = 3.4 -- studs from the tablet's screen to the camera, flown in
local TABLET_FOV = 50
local FLY_IN = TweenInfo.new(0.55, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local FLY_OUT = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
local VIP_TAG = '<font color="#FFD23C">[VIP]</font> '

local player = Players.LocalPlayer
local gui = Kit.getGui()

-- Counters -------------------------------------------------------------------

local counters = Kit.new("Frame", {
	Name = "Counters",
	AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.new(0, 28, 0.5, -70),
	Size = UDim2.fromOffset(360, 212),
	BackgroundTransparency = 1,
	Parent = gui,
})
Kit.new("UIListLayout", { Padding = UDim.new(0, 16), SortOrder = Enum.SortOrder.LayoutOrder, Parent = counters })

-- A pill that shows a Player attribute, counting up smoothly with a pop.
local function makeCounter(order: number, stat: string, icon: string, colors: { Color3 }): Frame
	local pill = Kit.new("Frame", {
		Name = stat,
		LayoutOrder = order,
		Size = UDim2.fromOffset(230, 60),
		BackgroundColor3 = Kit.White,
		Parent = counters,
	})
	Kit.new("UICorner", { CornerRadius = UDim.new(0.5, 0), Parent = pill })
	Kit.stroke(pill, 4)
	Kit.gradient(pill, colors)
	Kit.text({ Text = icon, Position = UDim2.fromOffset(-16, -10), Size = UDim2.fromOffset(76, 76), StrokeThickness = 0, Parent = pill })
	local label = Kit.text({
		Text = "0",
		Position = UDim2.fromOffset(66, 9),
		Size = UDim2.new(1, -84, 1, -18),
		TextXAlignment = Enum.TextXAlignment.Left,
		StrokeThickness = 3,
		Parent = pill,
	})

	local shown = Instance.new("NumberValue")
	shown.Changed:Connect(function(value)
		label.Text = Format.Number(math.floor(value + 0.5))
	end)
	local function update()
		local target = player:GetAttribute(stat) or 0
		if target > shown.Value then
			Kit.pop(pill, 0.08)
		end
		TweenService:Create(shown, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Value = target }):Play()
	end
	player:GetAttributeChangedSignal(stat):Connect(update)
	update()
	return pill
end

local pills = {}
for order, counter in COUNTERS do
	pills[counter.Stat] = makeCounter(order, counter.Stat, counter.Icon, counter.Colors)
end

Kit.button({
	AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.new(1, 12, 0.5, 0),
	Size = UDim2.fromOffset(96, 50),
	Parent = pills.Rolls,
}, Kit.Colors.Green, "OPEN", Loot.OpenRoll)

-- Menu buttons ---------------------------------------------------------------

local buttons = Kit.new("Frame", {
	Name = "MenuButtons",
	AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.new(0, 28, 0.5, 130),
	Size = UDim2.fromOffset(620, 110),
	BackgroundTransparency = 1,
	Parent = gui,
})
Kit.new("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal,
	Padding = UDim.new(0, 14),
	SortOrder = Enum.SortOrder.LayoutOrder,
	Parent = buttons,
})

local function menuButton(order: number, icon: string, label: string, colors: { Color3 }, onClick: () -> ()): TextButton
	local button = Kit.button({ LayoutOrder = order, Size = UDim2.fromOffset(104, 104), Parent = buttons }, colors, nil, onClick)
	Kit.text({ Text = icon, Position = UDim2.fromScale(0.1, 0.06), Size = UDim2.fromScale(0.8, 0.56), StrokeThickness = 0, Parent = button })
	Kit.text({ Text = label, Position = UDim2.fromScale(0.06, 0.64), Size = UDim2.fromScale(0.88, 0.28), Parent = button })
	return button
end

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
