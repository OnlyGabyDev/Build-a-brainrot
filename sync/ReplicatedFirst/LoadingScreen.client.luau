--[[
	LoadingScreen
	Our own loading screen (the user, 2026-10-03; v2 with the real brainrots, 2026-10-06):
	it replaces Roblox's default as soon as the client starts and stays until the game
	has loaded, your character is in the world (the server holds characters until the
	map is built: Main.server), the world round you has streamed in and its textures,
	the menus' images and the sound effects have downloaded (at most PRELOAD_TIME), then
	fades away. A pink-to-purple backdrop with turning
	rays; Tralalero bouncing over the title; a big brainrot in each bottom corner, turned
	toward the middle at three quarters, popping in a new one every few seconds with its
	rarity; small brainrots drifting up behind; a progress bar and rotating tips.

	It runs from ReplicatedFirst, before anything else has replicated, so it can't use
	Kit or any shared module: everything here is self-contained. The brainrots come
	ready built in ReplicatedFirst/LoadingBrainrots (Main.server makes them first thing);
	until they arrive (or if they never do) the screen is the title and the bar alone.
]]

local ContentProvider = game:GetService("ContentProvider")
local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local FONT = Enum.Font.FredokaOne
local INK = Color3.fromRGB(30, 25, 45)
local GOLD = Color3.fromRGB(255, 215, 60)
local TIMEOUT = 60 -- seconds: whatever happens, the screen goes by then
local MIN_TIME = 3 -- seconds: long enough to read the title and see a few brainrots
local PRELOAD_TIME = 25 -- seconds at most for the downloads, once your character is in
local SWAP_TIME = 3 -- seconds each corner brainrot stays before the next pops in
local DRIFTERS = 10
local CORNER_HEIGHT = 0.5 -- a corner brainrot's square, as a share of the screen's height...
local CORNER_WIDTH = 0.27 -- ...or of its width, whichever is smaller (tablets)
local TIPS = {
	"TIP: rare parts earn more Coins!",
	"TIP: 4 parts of one brainrot = x2 Coins!",
	"TIP: grab the boxes all over the map!",
	"TIP: every room builds its own way!",
	"TIP: Rebirth for more Coins and luck!",
	"TIP: spin the Daily Wheel every day!",
	"TIP: upgrade your lines at their tablets!",
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

-- A soft round glow (a circle fading out to its edge, roughly).
local function glow(props: { [string]: any }): Frame
	props.BorderSizePixel = 0
	props.BackgroundTransparency = props.BackgroundTransparency or 0.35
	local frame = new("Frame", props)
	new("UICorner", { CornerRadius = UDim.new(0.5, 0), Parent = frame })
	new("UIGradient", {
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(1, 1) }),
		Parent = frame,
	})
	return frame
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

-- turning rays behind everything, from just above the middle
local rays = new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.42),
	Size = UDim2.fromScale(2.4, 2.4),
	SizeConstraint = Enum.SizeConstraint.RelativeYY,
	BackgroundTransparency = 1,
	ZIndex = 1,
	Parent = back,
})
for bar = 0, 7 do
	new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1, 0.07),
		Rotation = bar * 180 / 8,
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0.88,
		BorderSizePixel = 0,
		ZIndex = 1,
		Parent = rays,
	})
end

local middle = new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromScale(0.6, 0.7),
	BackgroundTransparency = 1,
	ZIndex = 5,
	Parent = back,
})
new("UISizeConstraint", { MaxSize = Vector2.new(1100, 640), Parent = middle })
-- (Tralalero, the host, bounces here once the brainrots arrive)
local hostSpot = new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.fromScale(0.5, 0),
	Size = UDim2.fromScale(0.34, 0.34),
	BackgroundTransparency = 1,
	ZIndex = 5,
	Parent = middle,
})
new("UIAspectRatioConstraint", { Parent = hostSpot })
local title = label({
	Text = "BUILD A BRAINROT",
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.fromScale(0.5, 0.27),
	Size = UDim2.fromScale(1, 0.22),
	ZIndex = 6,
	Parent = middle,
}, 6)
new("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.new(1, 1, 1), GOLD), Parent = title })
label({ Text = "Brainrot Factory Tycoon", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.49), Size = UDim2.fromScale(0.7, 0.08), ZIndex = 6, Parent = middle }, 3)

local bar = new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.fromScale(0.5, 0.66),
	Size = UDim2.fromScale(0.7, 0.07),
	BackgroundColor3 = Color3.fromRGB(50, 30, 90),
	ZIndex = 6,
	Parent = middle,
})
new("UICorner", { CornerRadius = UDim.new(0.5, 0), Parent = bar })
new("UIStroke", { Thickness = 4, Color = INK, Parent = bar })
local fill = new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 7, Parent = bar })
new("UICorner", { CornerRadius = UDim.new(0.5, 0), Parent = fill })
new("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(255, 240, 140), Color3.fromRGB(255, 160, 30)), Parent = fill })
local status = label({ Text = STATUS[1].Text, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.75), Size = UDim2.fromScale(0.6, 0.07), ZIndex = 6, Parent = middle }, 3)
local random = Random.new()
local tip = label({ Text = TIPS[random:NextInteger(1, #TIPS)], AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.88), Size = UDim2.fromScale(0.8, 0.06), ZIndex = 6, Parent = middle }, 2)

-- Brainrots ------------------------------------------------------------------
-- Each one sits in its own ViewportFrame; everything moves the frames and the cameras,
-- never the models (cheap on phones).

type Slot = { Frame: ViewportFrame, Model: Model?, Focus: Vector3, Distance: number }

local function slot(props: { [string]: any }): Slot
	props.BackgroundTransparency = 1
	props.Ambient = Color3.fromRGB(190, 190, 190)
	props.LightColor = Color3.new(1, 1, 1)
	props.LightDirection = Vector3.new(-0.4, -1, 0.6)
	local frame = new("ViewportFrame", props)
	frame.CurrentCamera = new("Camera", { FieldOfView = 35, Parent = frame })
	return { Frame = frame, Model = nil, Focus = Vector3.zero, Distance = 10 }
end

local function show(target: Slot, template: Model, fit: number)
	if target.Model then
		target.Model:Destroy()
	end
	local model = template:Clone()
	model.Parent = target.Frame
	local box, size = model:GetBoundingBox()
	target.Model = model
	target.Focus = box.Position
	target.Distance = size.Magnitude * fit + 0.5
end

-- Points a slot's camera at its brainrot from `angle` round its front (positive: it
-- faces the screen's right), tilted by `roll` (a ViewportFrame can't be rotated).
local function aim(target: Slot, angle: number, lift: number, roll: number?)
	local camera = target.Frame.CurrentCamera :: Camera
	camera.CFrame = CFrame.lookAt(target.Focus + Vector3.new(math.sin(angle), lift, -math.cos(angle)).Unit * target.Distance, target.Focus)
		* CFrame.Angles(0, 0, roll or 0)
end

type Corner = Slot & { Side: number, Glow: Frame, Tag: TextLabel, Pop: UIScale, Holder: Frame }
type Drifter = Slot & { X: number, Phase: number, Speed: number, Sway: number, Spin: number, Angle: number }

local host: Slot? = nil
local corners: { Corner } = {}
local drifters: { Drifter } = {}
local templates: { Model } = {}
local nextTemplate = 0
local nextSwap = 0
local swapSide = 1

local function takeTemplate(): Model
	nextTemplate = nextTemplate % #templates + 1
	return templates[nextTemplate]
end

local function popIn(corner: Corner)
	local template = takeTemplate()
	show(corner, template, 1.3)
	local color = template:GetAttribute("Color") or Color3.new(1, 1, 1)
	corner.Glow.BackgroundColor3 = (color :: Color3):Lerp(Color3.new(1, 1, 1), 0.35)
	corner.Tag.Text = `{string.rep("★", template:GetAttribute("Rank") or 1)}\n{template:GetAttribute("Rarity") or ""}`
	corner.Tag.TextColor3 = color :: Color3
	corner.Pop.Scale = 0.55
	TweenService:Create(corner.Pop, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
end

-- Sizes the corner brainrots for this screen (the smaller of a share of its height and
-- of its width, so they stay clear of the bar on a tablet).
local function layoutCorners()
	local size = back.AbsoluteSize
	local side = math.floor(math.min(size.Y * CORNER_HEIGHT, size.X * CORNER_WIDTH))
	for _, corner in corners do
		corner.Holder.Size = UDim2.fromOffset(side, side)
	end
end

local function addBrainrots(folder: Folder)
	local hostTemplate = folder:FindFirstChild(tostring(folder:GetAttribute("Host"))) :: Model?
	for _, child in folder:GetChildren() do
		if child:IsA("Model") and child ~= hostTemplate then
			table.insert(templates, child)
		end
	end
	if #templates == 0 then
		return
	end
	for index = #templates, 2, -1 do -- shuffled, a new order every visit
		local other = random:NextInteger(1, index)
		templates[index], templates[other] = templates[other], templates[index]
	end

	-- small ones drifting up behind everything, faded, turning slowly
	for index = 1, DRIFTERS do
		local size = random:NextNumber(0.1, 0.16)
		local drifter = slot({
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromScale(size, size),
			SizeConstraint = Enum.SizeConstraint.RelativeYY,
			ImageTransparency = 0.4,
			ZIndex = 2,
			Parent = back,
		}) :: Drifter
		show(drifter, templates[(index - 1) % #templates + 1], 1.4)
		drifter.X = (index - 0.5) / DRIFTERS + random:NextNumber(-0.03, 0.03)
		drifter.Phase = random:NextNumber(0, 1.3)
		drifter.Speed = random:NextNumber(0.04, 0.07)
		drifter.Sway = random:NextNumber(0.01, 0.025)
		drifter.Spin = random:NextNumber(0.4, 0.8) * (if random:NextNumber() < 0.5 then -1 else 1)
		drifter.Angle = random:NextNumber(0, math.pi * 2)
		table.insert(drifters, drifter)
	end

	-- a big one in each bottom corner, on a glow in its rarity's color, its stars and
	-- rarity under it
	for _, side in { -1, 1 } do
		local holder = new("Frame", {
			AnchorPoint = Vector2.new(if side < 0 then 0 else 1, 1),
			Position = UDim2.new(if side < 0 then 0 else 1, -side * 8, 1, 0),
			BackgroundTransparency = 1,
			ZIndex = 3,
			Parent = back,
		})
		local pop = new("UIScale", { Parent = holder })
		local halo = glow({
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(1.1, 0.9),
			ZIndex = 3,
			Parent = holder,
		})
		local corner = slot({ Size = UDim2.fromScale(1, 1), ZIndex = 4, Parent = holder }) :: Corner
		corner.Side = side
		corner.Glow = halo
		corner.Holder = holder
		corner.Pop = pop
		corner.Tag = label({
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 1, -6),
			Size = UDim2.fromScale(0.62, 0.2),
			Text = "",
			ZIndex = 5,
			Parent = holder,
		}, 3)
		table.insert(corners, corner)
	end
	layoutCorners()
	back:GetPropertyChangedSignal("AbsoluteSize"):Connect(layoutCorners)
	for _, corner in corners do
		popIn(corner)
	end
	nextSwap = os.clock() + SWAP_TIME / 2

	-- Tralalero over the title
	if hostTemplate then
		local hostSlot = slot({ Size = UDim2.fromScale(1, 1), ZIndex = 5, Parent = hostSpot })
		show(hostSlot, hostTemplate, 1.25)
		host = hostSlot
	end
end

task.spawn(function()
	local folder = ReplicatedFirst:WaitForChild("LoadingBrainrots", TIMEOUT) :: Folder?
	if not (folder and screen.Parent) then
		return
	end
	-- (the folder can land a moment before all its brainrots do)
	local expected = folder:GetAttribute("Count") or 0
	local deadline = os.clock() + 3
	while #folder:GetChildren() < expected and os.clock() < deadline do
		task.wait(0.05)
	end
	task.wait(0.05)
	if screen.Parent then
		addBrainrots(folder)
	end
end)

-- Once the game and your character are in: the world round you streamed in, then the
-- textures in it, the menus' images and the sound effects downloaded, so they don't pop
-- in after the screen goes (the music streams on its own). Shared modules have
-- replicated by then.
local started = os.clock()
local deadline = started + TIMEOUT
local preloaded = false
-- (a Sound per effect: PreloadAsync fails audio ids given as bare strings)
local function soundsToLoad(): { Sound }
	local list = {}
	local ok, sounds = pcall(function()
		return require(ReplicatedStorage:WaitForChild("Shared", 5):WaitForChild("Config", 5):WaitForChild("Sounds", 5)) :: any
	end)
	if ok and typeof(sounds) == "table" then
		for _, id in sounds do
			if typeof(id) == "string" then -- (the music is a list: left out)
				table.insert(list, new("Sound", { SoundId = id }))
			end
		end
	end
	return list
end
task.spawn(function()
	while not (game:IsLoaded() and player.Character) and os.clock() < deadline do
		task.wait(0.1)
	end
	local stop = os.clock() + PRELOAD_TIME
	task.spawn(function()
		local character = player.Character
		local root = character and character:WaitForChild("HumanoidRootPart", 5)
		if root and root:IsA("BasePart") then
			pcall(player.RequestStreamAroundAsync, player, root.Position, 8)
		end
		local list: { any } = { workspace }
		local playerGui = player:FindFirstChild("PlayerGui")
		if playerGui then
			table.insert(list, playerGui)
		end
		local sounds = soundsToLoad()
		table.move(sounds, 1, #sounds, #list + 1, list)
		pcall(ContentProvider.PreloadAsync, ContentProvider, list)
		for _, sound in sounds do
			sound:Destroy()
		end
		preloaded = true
	end)
	while not preloaded and os.clock() < stop do
		task.wait(0.1)
	end
	preloaded = true
end)

-- Progress is an estimate: it creeps toward each stage's cap (the game loaded, the
-- character in the world, the downloads) and never reaches 1 before all are done.
local progress = 0
local function target(): number
	if not game:IsLoaded() then
		return 0.5
	elseif not player.Character then
		return 0.7
	elseif not preloaded then
		return 0.97
	end
	return 1
end

local nextTip = os.clock() + 3.5
local connection = RunService.RenderStepped:Connect(function(dt)
	local t = os.clock() - started
	rays.Rotation = t * 6
	for _, drifter in drifters do
		local y = 1.15 - ((drifter.Phase + t * drifter.Speed) % 1.3)
		drifter.Frame.Position = UDim2.fromScale(drifter.X + math.sin(t * 1.3 + drifter.Phase * 9) * drifter.Sway, y)
		aim(drifter, drifter.Angle + t * drifter.Spin, 0.25)
	end
	-- the corner ones bounce to a beat, turned in toward the middle, swaying a little
	local beat = math.abs(math.sin(t * math.pi * 1.6))
	for index, corner in corners do
		local hop = if index == 1 then beat else math.abs(math.sin(t * math.pi * 1.6 + 0.9))
		corner.Frame.Position = UDim2.new(0, 0, 0, -hop * corner.Holder.AbsoluteSize.Y * 0.06)
		aim(corner, -corner.Side * (math.rad(38) + math.sin(t * 1.2 + index) * 0.25), 0.22)
	end
	if #corners > 0 and os.clock() >= nextSwap then
		nextSwap = os.clock() + SWAP_TIME / 2 -- the two sides take turns
		popIn(corners[swapSide])
		swapSide = swapSide % #corners + 1
	end
	if host then
		hostSpot.Position = UDim2.new(0.5, 0, 0, -math.abs(math.sin(t * 3)) * 18)
		aim(host, math.rad(30) + math.sin(t * 1.4) * 0.5, 0.25, math.sin(t * 3) * 0.1)
	end
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

-- Wait for all that (or the timeout), then fade out.
while os.clock() < deadline and not (preloaded and os.clock() - started >= MIN_TIME) do
	task.wait(0.1)
end
progress = 1
status.Text = "Let's go!"
task.wait(0.4)

local fade = TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
TweenService:Create(back, fade, { BackgroundTransparency = 1 }):Play()
for _, child in back:GetDescendants() do
	if child:IsA("TextLabel") then
		TweenService:Create(child, fade, { TextTransparency = 1 }):Play()
	elseif child:IsA("UIStroke") then
		TweenService:Create(child, fade, { Transparency = 1 }):Play()
	elseif child:IsA("ViewportFrame") then
		TweenService:Create(child, fade, { ImageTransparency = 1 }):Play()
	elseif child:IsA("Frame") then
		TweenService:Create(child, fade, { BackgroundTransparency = 1 }):Play()
	end
end
task.wait(0.7)
connection:Disconnect()
screen:Destroy()
