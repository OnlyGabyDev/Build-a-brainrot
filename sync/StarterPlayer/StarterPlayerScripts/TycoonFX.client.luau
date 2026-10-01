--[[
	TycoonFX
	Makes the tycoons feel alive (GDD §13). Purely cosmetic, on this client only:
	  * The belts roll: ribbed rubber and glowing arrows scroll toward the chute.
	  * Freshly bought items pop into place piece by piece, bottom first, with a
	    cha-ching and a puff (TycoonManager tags new parts with a Built time).
	  * The Cash Pad piles up coins while money waits on it, glows, and bursts into a
	    fountain of coins (flying into your Coins counter) when you collect.
	  * Buttons you can afford get a bouncing arrow.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Format = require(Shared:WaitForChild("Format"))
local Sounds = require(Shared:WaitForChild("Config"):WaitForChild("Sounds"))
local TycoonItems = require(Shared:WaitForChild("Config"):WaitForChild("TycoonItems"))
local Effects = require(ReplicatedStorage:WaitForChild("Client"):WaitForChild("Effects"))

local BELT_RIBS = "rbxassetid://17320090479"
local BELT_ARROWS = "rbxassetid://7140341425"
local BELT_SPEED = 6 -- studs per second
local BUILD_WINDOW = 2 -- seconds: parts built longer ago than this just appear
local BUILD_STAGGER = 0.035 -- seconds between parts popping in
local BUILD_POP_TIME = 0.35
local COIN_COLOR = Color3.fromRGB(255, 215, 60)
local AFFORDABLE_COLOR = Color3.fromRGB(80, 220, 100) -- TycoonManager's affordable button color
local ARROW_COLOR = Color3.fromRGB(255, 240, 90)
local PILE_MAX = 14

local player = Players.LocalPlayer

local function isOwnPlot(plot: Instance): boolean
	return plot.Name == `Plot{player:GetAttribute("PlotIndex")}`
end

-- Belts ----------------------------------------------------------------------

-- On a Top face, a texture's U runs along the part's X and V along its Z, and raising
-- an offset slides the texture toward +X / +Z. The arrow image points to -U.
-- The rubber ribs go straight on the belt (they run across it and scroll along V
-- toward the chute, the belt's -Z). The arrows go on a thin see-through skin turned so
-- its -X is the belt's -Z, so they point at the chute and scroll along U.
local scrolling: { [Texture]: boolean } = {} -- texture → scrolls along U (else V)

local function addTexture(part: BasePart, image: string, tile: Vector2, color: Color3, transparency: number, alongU: boolean)
	local texture = Instance.new("Texture")
	texture.Texture = image
	texture.Face = Enum.NormalId.Top
	texture.StudsPerTileU = tile.X
	texture.StudsPerTileV = tile.Y
	texture.Color3 = color
	texture.Transparency = transparency
	texture.Parent = part
	scrolling[texture] = alongU
	texture.Destroying:Once(function()
		scrolling[texture] = nil
	end)
end

local function decorateBelt(belt: BasePart)
	addTexture(belt, BELT_RIBS, Vector2.new(belt.Size.X, 3), Color3.fromRGB(200, 195, 220), 0.35, false)

	local skin = Instance.new("Part")
	skin.Name = "BeltSkin"
	skin.Anchored = true
	skin.CanCollide = false
	skin.CanQuery = false
	skin.CanTouch = false
	skin.Transparency = 1
	skin.Size = Vector3.new(belt.Size.Z, 0.05, belt.Size.X)
	skin.CFrame = belt.CFrame * CFrame.new(0, belt.Size.Y / 2 + 0.03, 0) * CFrame.Angles(0, -math.pi / 2, 0)
	skin.Parent = belt
	addTexture(skin, BELT_ARROWS, Vector2.new(6, belt.Size.X), Color3.fromRGB(255, 255, 255), 0.7, true)
end

local beltOffset = 0
RunService.RenderStepped:Connect(function(dt)
	beltOffset += dt * BELT_SPEED
	for texture, alongU in scrolling do
		if alongU then
			texture.OffsetStudsU = -(beltOffset % texture.StudsPerTileU)
		else
			texture.OffsetStudsV = -(beltOffset % texture.StudsPerTileV)
		end
	end
end)

-- Build animations -----------------------------------------------------------

-- The line model (a child of a plot's Lines folder) a part belongs to.
local function lineOf(part: Instance): Model?
	local node = part.Parent
	while node and node.Parent do
		if node.Parent.Name == "Lines" and node:IsA("Model") then
			return node
		end
		node = node.Parent
	end
	return nil
end

local pending: { [Model]: { BasePart } } = {}
local fullSizes: { [BasePart]: Vector3 } = {} -- parts waiting to pop in, shrunk to a speck

-- Pops a batch of freshly built parts in, bottom first.
local function playBuild(line: Model, parts: { BasePart })
	table.sort(parts, function(a, b)
		return a.Position.Y - a.Size.Y / 2 < b.Position.Y - b.Size.Y / 2
	end)
	local total = #parts * BUILD_STAGGER + BUILD_POP_TIME
	line:SetAttribute("BuildingUntil", os.clock() + total + 0.1)

	local low, high = Vector3.new(math.huge, math.huge, math.huge), Vector3.new(-math.huge, -math.huge, -math.huge)
	for index, part in parts do
		local size = fullSizes[part] or part.Size
		fullSizes[part] = nil
		low = low:Min(part.Position - size / 2)
		high = high:Max(part.Position + size / 2)
		task.delay((index - 1) * BUILD_STAGGER, function()
			if part.Parent then
				TweenService:Create(part, TweenInfo.new(BUILD_POP_TIME, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = size }):Play()
			end
		end)
	end

	local center = (low + high) / 2
	local floor = Vector3.new(center.X, low.Y + 0.2, center.Z)
	local itemId = parts[1]:GetAttribute("Item")
	local item = typeof(itemId) == "string" and TycoonItems.ById[itemId] or nil
	Effects.sound(center, Sounds.Cash, 0.4)
	Effects.puff(floor, Color3.fromRGB(255, 255, 255), 12, 1.2)
	Effects.ring(floor, COIN_COLOR, math.max(high.X - low.X, high.Z - low.Z) * 0.6 + 3)
	Effects.sparkle(center, COIN_COLOR, 20)
	-- A little rising "pop pop pop" as it builds up.
	local pops = math.min(#parts, 6)
	for index = 1, pops do
		task.delay(total * (index - 1) / pops, function()
			Effects.sound(center, Sounds.Pop, 0.35, 0.9 + index * 0.12)
		end)
	end
	if item and item.Kind == "Line" then
		task.delay(total, function()
			Effects.sound(center, Sounds.Jingle, 0.4)
			Effects.confetti(center + Vector3.new(0, 4, 0), 40)
		end)
	end
end

local function queueBuild(part: BasePart)
	local built = part:GetAttribute("Built")
	if typeof(built) ~= "number" or workspace:GetServerTimeNow() - built > BUILD_WINDOW then
		return
	end
	local line = lineOf(part)
	if not line then
		return
	end
	local batch = pending[line]
	if not batch then
		batch = {}
		pending[line] = batch
		-- Everything an item builds arrives together; gather it for a moment.
		task.delay(0.05, function()
			pending[line] = nil
			playBuild(line, batch :: { BasePart })
		end)
	end
	fullSizes[part] = part.Size
	part.Size = part.Size * 0.02 -- hidden until its turn
	table.insert(batch, part)
end

local function watchLines(lines: Instance)
	local function onDescendant(descendant: Instance)
		if descendant:IsA("BasePart") then
			if descendant.Name == "Belt" then
				-- A belt that's popping in gets its skin once it's full size.
				local built = descendant:GetAttribute("Built")
				local fresh = typeof(built) == "number" and workspace:GetServerTimeNow() - built < BUILD_WINDOW
				task.delay(if fresh then 1.5 else 0, function()
					if descendant.Parent then
						decorateBelt(descendant)
					end
				end)
			end
			task.defer(queueBuild, descendant) -- attributes land with the part, but be safe
		end
	end
	for _, descendant in lines:GetDescendants() do
		onDescendant(descendant)
	end
	lines.DescendantAdded:Connect(onDescendant)
end

-- Cash Pad -------------------------------------------------------------------

-- Coins flying from a world point into the HUD's Coins counter.
local flyGui: ScreenGui? = nil

local function flyToCounter(from: Vector3, count: number)
	local camera = workspace.CurrentCamera
	local hud = player.PlayerGui:FindFirstChild("BrainrotUI")
	local counters = hud and hud:FindFirstChild("Counters")
	local counter = counters and counters:FindFirstChild("Coins") :: GuiObject?
	if not (camera and counter) then
		return
	end
	local point, visible = camera:WorldToViewportPoint(from)
	if not visible then
		return
	end
	if not (flyGui and flyGui.Parent) then
		local screen = Instance.new("ScreenGui")
		screen.Name = "FlyingCoins"
		screen.IgnoreGuiInset = true
		screen.ResetOnSpawn = false
		screen.DisplayOrder = 5
		screen.Parent = player.PlayerGui
		flyGui = screen
	end
	local target = counter.AbsolutePosition + Vector2.new(34, counter.AbsoluteSize.Y / 2)
	for index = 1, count do
		task.delay((index - 1) * 0.05, function()
			local label = Instance.new("TextLabel")
			label.AnchorPoint = Vector2.new(0.5, 0.5)
			label.Size = UDim2.fromOffset(44, 44)
			label.BackgroundTransparency = 1
			label.TextScaled = true
			label.Font = Enum.Font.FredokaOne
			label.Text = "💰"
			label.Position = UDim2.fromOffset(point.X + math.random(-40, 40), point.Y + math.random(-30, 30))
			label.Parent = flyGui
			local tween = TweenService:Create(label, TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				Position = UDim2.fromOffset(target.X, target.Y),
				Size = UDim2.fromOffset(28, 28),
			})
			tween.Completed:Once(function()
				label:Destroy()
			end)
			tween:Play()
		end)
	end
end

-- Coin spots for the pile on the pad: a ring at the bottom, a smaller one on top of
-- it, then a couple at the peak.
local PILE_SPOTS = {}
for index = 0, 6 do
	local angle = index / 7 * math.pi * 2
	table.insert(PILE_SPOTS, Vector3.new(math.cos(angle) * 1.4, 0, math.sin(angle) * 1.4))
end
for index = 0, 4 do
	local angle = index / 5 * math.pi * 2 + 0.4
	table.insert(PILE_SPOTS, Vector3.new(math.cos(angle) * 0.8, 0.28, math.sin(angle) * 0.8))
end
table.insert(PILE_SPOTS, Vector3.new(0.2, 0.56, 0))
table.insert(PILE_SPOTS, Vector3.new(-0.3, 0.5, 0.3))

local function watchCashPad(plot: Instance, pad: BasePart)
	local coins: { BasePart } = {}
	local glow = Instance.new("PointLight")
	glow.Color = COIN_COLOR
	glow.Range = 12
	glow.Brightness = 0
	glow.Shadows = false
	glow.Parent = pad
	local glowTween: Tween? = nil

	local function setPile(count: number)
		local top = pad.CFrame * CFrame.new(0, pad.Size.Y / 2 + 0.12, 0)
		while #coins < count do
			local spot = PILE_SPOTS[#coins + 1]
			local coin = Effects.makeCoin(1.1)
			coin.CFrame = top * CFrame.new(spot) * CFrame.Angles(math.random() * 0.3, math.random() * math.pi, math.pi / 2 + (math.random() - 0.5) * 0.3)
			local size = coin.Size
			coin.Size = size * 0.1
			coin.Parent = pad
			TweenService:Create(coin, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = size }):Play()
			table.insert(coins, coin)
		end
		while #coins > count do
			(table.remove(coins) :: BasePart):Destroy()
		end

		if count > 0 and not glowTween then
			glow.Brightness = 0.6
			local tween = TweenService:Create(glow, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Brightness = 2.2 })
			tween:Play()
			glowTween = tween
		elseif count == 0 and glowTween then
			glowTween:Cancel()
			glowTween = nil
			glow.Brightness = 0
		end
	end

	local function collected(amount: number)
		local top = pad.Position + Vector3.new(0, pad.Size.Y / 2 + 0.5, 0)
		Effects.sound(top, Sounds.Cash, 0.5)
		Effects.sound(top, Sounds.Coins, 0.4)
		Effects.sparkle(top, COIN_COLOR, 30, 18)
		Effects.ring(top - Vector3.new(0, 0.4, 0), COIN_COLOR, 7)
		Effects.flash(top + Vector3.new(0, 2, 0), COIN_COLOR, 3, 20)
		Effects.popup(top + Vector3.new(0, 3, 0), `+{Format.Number(amount)} 💰`, COIN_COLOR, 2.4, 1.4)
		for _ = 1, 8 do
			local angle = math.random() * math.pi * 2
			local landing = top + Vector3.new(math.cos(angle), 0, math.sin(angle)) * (2 + math.random() * 3)
			Effects.coins(top, landing, 1)
		end
		if isOwnPlot(plot) then
			flyToCounter(top, math.clamp(math.floor(math.log10(amount + 1) * 2), 3, 10))
		end
	end

	local last = 0
	local generation = pad:GetAttribute("Generation")
	local function update()
		local amount = pad:GetAttribute("Collected")
		local value = if typeof(amount) == "number" then amount else 0
		-- A plot reset (rebirth, owner leaving) wipes the pad too: no burst for that.
		local reset = pad:GetAttribute("Generation") ~= generation
		if value == 0 and last > 0 and not reset and Effects.near(pad.Position, 150) then
			collected(last)
		end
		last = value
		generation = pad:GetAttribute("Generation")
		setPile(if value <= 0 then 0 else math.clamp(math.floor(math.log10(value + 1) * 2.5), 1, PILE_MAX))
	end
	pad:GetAttributeChangedSignal("Collected"):Connect(update)
	update()
end

-- Buttons ----------------------------------------------------------------------

-- Your affordable buttons get a bouncing arrow over them.
local arrows: { [BasePart]: BillboardGui } = {}

local function watchButton(plot: Instance, button: BasePart)
	if not isOwnPlot(plot) then
		return
	end
	local gui = Instance.new("BillboardGui")
	gui.Name = "AffordArrow"
	gui.Size = UDim2.fromScale(2.4, 2.4)
	gui.StudsOffset = Vector3.new(0, 6.5, 0)
	gui.LightInfluence = 0
	gui.MaxDistance = 70
	gui.Parent = button
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.Text = "▼"
	label.TextColor3 = ARROW_COLOR
	label.Parent = gui
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 3
	stroke.Color = Color3.fromRGB(30, 25, 45)
	stroke.Parent = label

	local function update()
		gui.Enabled = button.Color == AFFORDABLE_COLOR
	end
	button:GetPropertyChangedSignal("Color"):Connect(update)
	update()
	arrows[button] = gui
	button.Destroying:Once(function()
		arrows[button] = nil
	end)
end

RunService.RenderStepped:Connect(function()
	local bounce = math.abs(math.sin(os.clock() * 4)) * 1.2
	for _, gui in arrows do
		gui.StudsOffset = Vector3.new(0, 6 + bounce, 0)
	end
end)

-- Plots ------------------------------------------------------------------------

local function watchPlot(plot: Instance)
	task.spawn(function()
		watchLines(plot:WaitForChild("Lines"))
	end)
	task.spawn(function()
		local pad = plot:WaitForChild("CashPad")
		if pad:IsA("BasePart") then
			watchCashPad(plot, pad)
		end
	end)
	task.spawn(function()
		local buttons = plot:WaitForChild("Buttons")
		local function onButton(button: Instance)
			if button:IsA("BasePart") then
				watchButton(plot, button)
			end
		end
		for _, button in buttons:GetChildren() do
			onButton(button)
		end
		buttons.ChildAdded:Connect(onButton)
		-- Arrows are only for your own plot, which you might not have yet.
		player:GetAttributeChangedSignal("PlotIndex"):Connect(function()
			for _, button in buttons:GetChildren() do
				if button:IsA("BasePart") and not arrows[button] then
					watchButton(plot, button)
				end
			end
		end)
	end)
end

local tycoons = workspace:WaitForChild("Tycoons")
for _, plot in tycoons:GetChildren() do
	watchPlot(plot)
end
tycoons.ChildAdded:Connect(watchPlot)
