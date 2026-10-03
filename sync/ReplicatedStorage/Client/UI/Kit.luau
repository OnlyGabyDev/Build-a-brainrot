--[[
	UI Kit
	The shared look and building blocks for every menu (GDD §1, §13), Pet Simulator X
	style: chunky rounded panels, thick dark outlines, gradients, bouncy buttons and a
	click on every press. Everything is designed at 1600x900 and scaled to the screen.
	Client only.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local Sounds = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("Sounds"))

local DESIGN_SIZE = Vector2.new(1600, 900)
local WHITE = Color3.new(1, 1, 1)

local Kit = {}

Kit.Font = Enum.Font.FredokaOne
Kit.Outline = Color3.fromRGB(30, 25, 45)
Kit.White = WHITE
-- Gradient pairs, top to bottom.
Kit.Colors = {
	Coins = { Color3.fromRGB(255, 225, 90), Color3.fromRGB(255, 160, 30) },
	Gems = { Color3.fromRGB(120, 235, 255), Color3.fromRGB(40, 130, 255) },
	Rolls = { Color3.fromRGB(255, 140, 230), Color3.fromRGB(170, 70, 255) },
	Green = { Color3.fromRGB(130, 245, 110), Color3.fromRGB(40, 180, 60) },
	Red = { Color3.fromRGB(255, 120, 120), Color3.fromRGB(220, 50, 60) },
	Purple = { Color3.fromRGB(190, 140, 255), Color3.fromRGB(120, 70, 230) },
	Grey = { Color3.fromRGB(205, 205, 215), Color3.fromRGB(150, 150, 165) },
	Panel = { Color3.fromRGB(255, 252, 245), Color3.fromRGB(238, 228, 212) },
}

local gui: ScreenGui? = nil
local clickSound: Sound? = nil
local openModal: Frame? = nil

-- Creates an instance, sets its properties (Parent last) and parents `children` to it.
function Kit.new(className: string, props: { [string]: any }?, children: { Instance }?): any
	local instance = Instance.new(className)
	local properties: { [string]: any } = props or {}
	local kids: { Instance } = children or {}
	local parent = nil
	for key, value in properties do
		if key == "Parent" then
			parent = value
		else
			(instance :: any)[key] = value
		end
	end
	for _, child in kids do
		child.Parent = instance
	end
	instance.Parent = parent
	return instance
end

function Kit.corner(parent: Instance, radius: number?): UICorner
	return Kit.new("UICorner", { CornerRadius = UDim.new(0, radius or 16), Parent = parent })
end

-- A thick dark outline around a frame or button (not its text).
function Kit.stroke(parent: Instance, thickness: number?, color: Color3?): UIStroke
	return Kit.new("UIStroke", {
		Thickness = thickness or 4,
		Color = color or Kit.Outline,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = parent,
	})
end

function Kit.gradient(parent: Instance, colors: { Color3 }): UIGradient
	return Kit.new("UIGradient", {
		Color = ColorSequence.new(colors[1], colors[2] or colors[1]),
		Rotation = 90,
		Parent = parent,
	})
end

-- Chunky white text with a dark outline. `props` overrides the defaults.
function Kit.text(props: { [string]: any }): TextLabel
	local label = Kit.new("TextLabel", {
		BackgroundTransparency = 1,
		Font = Kit.Font,
		TextScaled = true,
		TextColor3 = WHITE,
		Size = UDim2.fromScale(1, 1),
	})
	local strokeThickness = props.StrokeThickness or 2.5
	for key, value in props do
		if key ~= "StrokeThickness" and key ~= "Parent" then
			(label :: any)[key] = value
		end
	end
	Kit.new("UIStroke", { Thickness = strokeThickness, Color = Kit.Outline, Parent = label })
	label.Parent = props.Parent
	return label
end

function Kit.click()
	if not clickSound then
		clickSound = Kit.new("Sound", { SoundId = Sounds.Click, Volume = 0.6, Parent = SoundService })
	end
	SoundService:PlayLocalSound(clickSound :: Sound)
end

-- Plays a one-off UI sound.
function Kit.playSound(soundId: string, volume: number, speed: number?)
	local sound = Kit.new("Sound", { SoundId = soundId, Volume = volume, PlaybackSpeed = speed or 1, Parent = SoundService })
	SoundService:PlayLocalSound(sound)
	task.delay(6, function()
		sound:Destroy()
	end)
end

-- A quick scale pop on any GuiObject (e.g. a counter that just went up).
function Kit.pop(object: GuiObject, amount: number?)
	local scale = object:FindFirstChild("PopScale") :: UIScale?
	if not scale then
		scale = Kit.new("UIScale", { Name = "PopScale", Parent = object })
	end
	local popScale = scale :: UIScale
	popScale.Scale = 1 + (amount or 0.12)
	TweenService:Create(popScale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
end

-- A glossy highlight across the top of a button or pill (under its text: ZIndex 0).
function Kit.shine(parent: GuiObject, radius: number?): Frame
	local gloss = Kit.new("Frame", {
		Name = "Shine",
		Position = UDim2.new(0, 5, 0, 4),
		Size = UDim2.new(1, -10, 0.42, 0),
		BackgroundColor3 = WHITE,
		BackgroundTransparency = 0.62,
		BorderSizePixel = 0,
		ZIndex = 0,
		Parent = parent,
	})
	Kit.corner(gloss, radius or 10)
	Kit.new("UIGradient", {
		Transparency = NumberSequence.new(0, 0.7),
		Rotation = 90,
		Parent = gloss,
	})
	return gloss
end

-- Text that floats up from `position` (in `parent`) and fades, like "+1.2K".
function Kit.floatText(parent: GuiObject, text: string, color: Color3, position: UDim2, zIndex: number?)
	local label = Kit.text({
		Text = text,
		TextColor3 = color,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = position,
		Size = UDim2.fromOffset(180, 38),
		StrokeThickness = 3,
		ZIndex = zIndex or 20,
		Parent = parent,
	})
	Kit.pop(label, 0.4)
	local info = TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(label, info, { Position = position - UDim2.fromOffset(0, 46), TextTransparency = 1 }):Play()
	TweenService:Create(label:FindFirstChildOfClass("UIStroke") :: UIStroke, info, { Transparency = 1 }):Play()
	task.delay(1, function()
		label:Destroy()
	end)
end

-- A chunky, bouncy button. `colors` is a gradient pair from Kit.Colors.
function Kit.button(props: { [string]: any }, colors: { Color3 }, text: string?, onClick: () -> ()): TextButton
	local button = Kit.new("TextButton", {
		AutoButtonColor = false,
		Text = "",
		BackgroundColor3 = WHITE,
		Size = UDim2.fromOffset(160, 56),
	})
	for key, value in props do
		if key ~= "Parent" then
			(button :: any)[key] = value
		end
	end
	Kit.corner(button, 14)
	Kit.stroke(button, 3.5)
	Kit.gradient(button, colors)
	Kit.shine(button, 10)
	if text then
		Kit.text({
			Text = text,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(0.88, 0.68),
			Parent = button,
		})
	end

	local scale = Kit.new("UIScale", { Parent = button })
	local function to(value: number)
		TweenService:Create(scale, TweenInfo.new(0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = value }):Play()
	end
	button.MouseEnter:Connect(function()
		to(1.06)
	end)
	button.MouseLeave:Connect(function()
		to(1)
	end)
	button.MouseButton1Down:Connect(function()
		to(0.92)
	end)
	button.MouseButton1Up:Connect(function()
		to(1.06)
	end)
	button.Activated:Connect(function()
		Kit.click()
		onClick()
	end)
	button.Parent = props.Parent
	return button
end

-- An ON/OFF switch: a pill (green ON, grey OFF) with a knob that slides across.
-- Clicking it calls `onChange(newValue)`; returns a function that shows a value
-- without calling it (for changes made elsewhere).
function Kit.toggle(props: { [string]: any }, value: boolean, onChange: (on: boolean) -> ()): (on: boolean) -> ()
	local on = value
	local track = Kit.new("TextButton", {
		AutoButtonColor = false,
		Text = "",
		BackgroundColor3 = WHITE,
		Size = UDim2.fromOffset(132, 50),
	})
	for key, prop in props do
		if key ~= "Parent" then
			(track :: any)[key] = prop
		end
	end
	Kit.new("UICorner", { CornerRadius = UDim.new(0.5, 0), Parent = track })
	Kit.stroke(track, 3.5)
	local gradient = Kit.gradient(track, Kit.Colors.Grey)
	Kit.shine(track, 20)
	local label = Kit.text({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.new(0.5, 0, 0.6, 0),
		Parent = track,
	})
	local knob = Kit.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.new(0, 40, 0, 40),
		BackgroundColor3 = WHITE,
		Parent = track,
	})
	Kit.new("UICorner", { CornerRadius = UDim.new(0.5, 0), Parent = knob })
	Kit.stroke(knob, 3)

	local function show(state: boolean, animate: boolean)
		on = state
		local colors = if state then Kit.Colors.Green else Kit.Colors.Grey
		gradient.Color = ColorSequence.new(colors[1], colors[2])
		label.Text = if state then "ON" else "OFF"
		label.Position = UDim2.fromScale(if state then 0.32 else 0.68, 0.5)
		local target = UDim2.new(if state then 1 else 0, if state then -27 else 27, 0.5, 0)
		if animate then
			TweenService:Create(knob, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Position = target }):Play()
		else
			knob.Position = target
		end
	end
	show(on, false)
	track.Activated:Connect(function()
		Kit.click()
		show(not on, true)
		Kit.pop(track, 0.08)
		onChange(on)
	end)
	track.Parent = props.Parent
	return function(state: boolean)
		if state ~= on then
			show(state, true)
		end
	end
end

-- A ViewportFrame showing `model` from the front (models face -Z).
function Kit.viewport(props: { [string]: any }, model: Model): ViewportFrame
	local frame = Kit.new("ViewportFrame", {
		BackgroundTransparency = 1,
		Ambient = Color3.fromRGB(190, 190, 190),
		LightColor = WHITE,
		LightDirection = Vector3.new(-0.4, -1, 0.6),
	})
	for key, value in props do
		if key ~= "Parent" then
			(frame :: any)[key] = value
		end
	end
	local camera = Kit.new("Camera", { FieldOfView = 35, Parent = frame })
	frame.CurrentCamera = camera
	model.Parent = frame
	local box, size = model:GetBoundingBox()
	local distance = size.Magnitude * 1.5 + 0.5
	camera.CFrame = CFrame.lookAt(box.Position + Vector3.new(0.35, 0.3, -1).Unit * distance, box.Position)
	frame.Parent = props.Parent
	return frame
end

-- The one ScreenGui every menu lives in, scaled to the screen.
function Kit.getGui(): ScreenGui
	if gui and gui.Parent then
		return gui
	end
	local screen = Kit.new("ScreenGui", {
		Name = "BrainrotUI",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = Players.LocalPlayer:WaitForChild("PlayerGui"),
	})
	local scale = Kit.new("UIScale", { Parent = screen })
	local function rescale()
		local camera = workspace.CurrentCamera
		local size = if camera then camera.ViewportSize else DESIGN_SIZE
		scale.Scale = math.clamp(math.min(size.X / DESIGN_SIZE.X, size.Y / DESIGN_SIZE.Y), 0.45, 1.4)
	end
	rescale()
	if workspace.CurrentCamera then
		workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(rescale)
	end
	gui = screen
	return screen
end

-- A centered menu panel with a colored title bar and a close button. Returns the
-- panel (hidden) and its content area (below the title bar).
function Kit.modal(name: string, title: string, colors: { Color3 }, size: Vector2): (Frame, Frame)
	local panel = Kit.new("Frame", {
		Name = name,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(size.X, size.Y),
		BackgroundColor3 = WHITE,
		Visible = false,
		ZIndex = 10,
		Parent = Kit.getGui(),
	})
	Kit.corner(panel, 24)
	Kit.stroke(panel, 5)
	Kit.gradient(panel, Kit.Colors.Panel)
	Kit.new("UIScale", { Name = "OpenScale", Parent = panel })

	local header = Kit.new("Frame", {
		Name = "Header",
		Size = UDim2.new(1, 0, 0, 72),
		BackgroundColor3 = WHITE,
		Parent = panel,
	})
	Kit.corner(header, 24)
	Kit.gradient(header, colors)
	Kit.text({
		Text = title,
		Position = UDim2.fromOffset(24, 12),
		Size = UDim2.new(1, -110, 0, 48),
		TextXAlignment = Enum.TextXAlignment.Left,
		StrokeThickness = 3,
		Parent = header,
	})
	Kit.button({
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -14, 0, 10),
		Size = UDim2.fromOffset(52, 52),
		Parent = header,
	}, Kit.Colors.Red, "X", function()
		Kit.close(panel)
	end)

	local content = Kit.new("Frame", {
		Name = "Content",
		Position = UDim2.fromOffset(0, 72),
		Size = UDim2.new(1, 0, 1, -72),
		BackgroundTransparency = 1,
		Parent = panel,
	})
	return panel, content
end

-- Shows a panel with a whoosh and a bounce (up from a little lower), closing whichever
-- menu was open.
function Kit.open(panel: Frame)
	if openModal and openModal ~= panel then
		openModal.Visible = false
	end
	openModal = panel
	local shown = panel:GetAttribute("Shown")
	panel:SetAttribute("Shown", (if typeof(shown) == "number" then shown else 0) + 1) -- (cancels a close still shrinking it)
	panel.Visible = true
	local home = panel:GetAttribute("Home")
	if typeof(home) ~= "UDim2" then
		home = panel.Position
		panel:SetAttribute("Home", home)
	end
	local bounce = TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	panel.Position = (home :: UDim2) + UDim2.fromOffset(0, 40)
	TweenService:Create(panel, bounce, { Position = home }):Play()
	local scale = panel:FindFirstChild("OpenScale") :: UIScale?
	if scale then
		scale.Scale = 0.6
		TweenService:Create(scale, bounce, { Scale = 1 }):Play()
	end
	Kit.playSound(Sounds.Whoosh, 0.22, 1.7)
end

function Kit.close(panel: Frame)
	if openModal == panel then
		openModal = nil
	end
	if not panel.Visible then
		return
	end
	local scale = panel:FindFirstChild("OpenScale") :: UIScale?
	if not scale then
		panel.Visible = false
		return
	end
	Kit.playSound(Sounds.Pop, 0.18, 1.4)
	local shown = panel:GetAttribute("Shown")
	TweenService:Create(scale, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Scale = 0.8 }):Play()
	task.delay(0.1, function()
		if panel:GetAttribute("Shown") == shown then
			panel.Visible = false
			scale.Scale = 1
		end
	end)
end

-- Hype effects ---------------------------------------------------------------

-- A full-screen flash that fades out.
function Kit.flash(parent: GuiObject, color: Color3, zIndex: number?)
	local frame = Kit.new("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = color,
		BackgroundTransparency = 0.2,
		ZIndex = zIndex or 45,
		Parent = parent,
	})
	TweenService:Create(frame, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 1 }):Play()
	task.delay(0.6, function()
		frame:Destroy()
	end)
end

-- A burst of confetti from the middle of `parent`.
function Kit.confetti(parent: GuiObject, colors: { Color3 }, count: number, zIndex: number?)
	for _ = 1, count do
		local piece = Kit.new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.45),
			Size = UDim2.fromOffset(math.random(10, 18), math.random(10, 18)),
			BackgroundColor3 = colors[math.random(1, #colors)],
			Rotation = math.random(0, 360),
			ZIndex = zIndex or 44,
			Parent = parent,
		})
		local angle = math.random() * math.pi * 2
		local distance = math.random(220, 520)
		TweenService:Create(piece, TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = UDim2.new(0.5, math.cos(angle) * distance, 0.45, math.sin(angle) * distance + 140),
			Rotation = piece.Rotation + math.random(-360, 360),
			BackgroundTransparency = 1,
		}):Play()
		task.delay(1.3, function()
			piece:Destroy()
		end)
	end
end

-- A sunburst behind something special: two wheels of light rays turning opposite
-- ways round a soft glow, in `color`. Returns a function that stops and removes it.
function Kit.rays(parent: GuiObject, color: Color3, size: number, zIndex: number): () -> ()
	local holder = Kit.new("Frame", {
		Name = "Sunburst",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(size, size),
		BackgroundTransparency = 1,
		ZIndex = zIndex,
		Parent = parent,
	})
	local glow = Kit.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.55, 0.55),
		BackgroundColor3 = color:Lerp(WHITE, 0.4),
		BackgroundTransparency = 0.45,
		ZIndex = zIndex,
		Parent = holder,
	})
	Kit.new("UICorner", { CornerRadius = UDim.new(0.5, 0), Parent = glow })
	Kit.new("UIGradient", {
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(1, 1) }),
		Parent = glow,
	})
	local wheels = {}
	for index, spec in { { Bars = 6, Width = 0.09, Fade = 0.35 }, { Bars = 6, Width = 0.04, Fade = 0.15 } } do
		local wheel = Kit.new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Rotation = (index - 1) * 15,
			ZIndex = zIndex,
			Parent = holder,
		})
		for bar = 0, spec.Bars - 1 do
			local ray = Kit.new("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(1, spec.Width),
				Rotation = bar * 180 / spec.Bars,
				BackgroundColor3 = if index == 1 then color else color:Lerp(WHITE, 0.5),
				BorderSizePixel = 0,
				ZIndex = zIndex,
				Parent = wheel,
			})
			Kit.new("UICorner", { CornerRadius = UDim.new(0.5, 0), Parent = ray })
			Kit.new("UIGradient", {
				Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 1),
					NumberSequenceKeypoint.new(0.5, spec.Fade),
					NumberSequenceKeypoint.new(1, 1),
				}),
				Parent = ray,
			})
		end
		wheels[index] = wheel
	end
	local connection = RunService.RenderStepped:Connect(function(dt)
		wheels[1].Rotation += dt * 22
		wheels[2].Rotation -= dt * 14
	end)
	return function()
		connection:Disconnect()
		holder:Destroy()
	end
end

-- Big news banners (a rare box spawned): they drop in at the top of the screen, stack
-- under each other, pulse while they're up and fly back out.
local BANNER_SIZE = Vector2.new(740, 112)
local BANNER_TOP = 118
local banners: { Frame } = {}

local function stackBanners()
	for index, banner in banners do
		local target = UDim2.new(0.5, 0, 0, BANNER_TOP + (index - 1) * (BANNER_SIZE.Y + 18))
		TweenService:Create(banner, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Position = target }):Play()
	end
end

-- `hype` 0-3 grows the show: 1+ a sunburst behind it, 2+ a screen flash and confetti,
-- 3 a turning rainbow.
function Kit.banner(icon: string, title: string, subtitle: string, color: Color3, hype: number)
	local screen = Kit.getGui()
	local banner = Kit.new("Frame", {
		Name = "Banner",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, -BANNER_SIZE.Y - 40),
		Size = UDim2.fromOffset(BANNER_SIZE.X, BANNER_SIZE.Y),
		BackgroundTransparency = 1,
		ZIndex = 47,
		Parent = screen,
	})
	local stopRays = if hype >= 1 then Kit.rays(banner, color, 460 + hype * 60, 47) else nil
	local card = Kit.new("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = WHITE,
		ZIndex = 48,
		Parent = banner,
	})
	Kit.corner(card, 24)
	Kit.stroke(card, 5)
	local gradient = Kit.gradient(card, { color:Lerp(WHITE, 0.35), color:Lerp(Color3.new(0, 0, 0), 0.25) })
	if hype >= 3 then
		gradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 110, 110)),
			ColorSequenceKeypoint.new(0.25, Color3.fromRGB(255, 220, 80)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(110, 240, 130)),
			ColorSequenceKeypoint.new(0.75, Color3.fromRGB(100, 180, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(220, 120, 255)),
		})
	end
	Kit.shine(card, 18).ZIndex = 48
	local badge = Kit.text({
		Text = icon,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(66, BANNER_SIZE.Y / 2),
		Size = UDim2.fromOffset(84, 84),
		StrokeThickness = 0,
		ZIndex = 49,
		Parent = card,
	})
	Kit.text({
		Text = title,
		Position = UDim2.fromOffset(122, 10),
		Size = UDim2.new(1, -140, 0, 56),
		TextXAlignment = Enum.TextXAlignment.Left,
		StrokeThickness = 4,
		ZIndex = 49,
		Parent = card,
	})
	Kit.text({
		Text = subtitle,
		Position = UDim2.fromOffset(124, 68),
		Size = UDim2.new(1, -144, 0, 32),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Color3.fromRGB(255, 250, 225),
		ZIndex = 49,
		Parent = card,
	})
	-- sparkles twinkling along its edges
	local sparks = {}
	for index = 1, 4 + hype * 2 do
		table.insert(sparks, Kit.text({
			Text = "✦",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(index / (5 + hype * 2), if index % 2 == 0 then 0.02 else 0.98),
			Size = UDim2.fromOffset(26, 26),
			TextColor3 = Color3.fromRGB(255, 252, 220),
			StrokeThickness = 1.5,
			ZIndex = 50,
			Parent = card,
		}))
	end

	table.insert(banners, banner)
	stackBanners()
	if hype >= 2 then
		Kit.flash(screen, color, 46)
		Kit.confetti(screen, { color, color:Lerp(WHITE, 0.5), Color3.fromRGB(255, 220, 80) }, 20 + hype * 10, 46)
	end
	Kit.playSound(if hype >= 1 then Sounds.RevealBig else Sounds.Reveal, 0.5)

	local scale = Kit.new("UIScale", { Parent = banner })
	local born = os.clock()
	local pulse = RunService.RenderStepped:Connect(function(dt)
		local t = os.clock() - born
		scale.Scale = 1 + math.sin(t * 6) * 0.025
		badge.Rotation = math.sin(t * 4) * 12
		for index, spark in sparks do
			spark.TextTransparency = 1 - (math.sin(t * 5 + index * 1.3) + 1) / 2
			spark.Rotation = t * 90 + index * 40
		end
		if hype >= 3 then
			gradient.Rotation = (gradient.Rotation + dt * 90) % 360
		end
	end)
	task.delay(4 + hype, function()
		local out = TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.In)
		TweenService:Create(scale, out, { Scale = 0.2 }):Play()
		task.wait(0.35)
		pulse:Disconnect()
		if stopRays then
			stopRays()
		end
		local index = table.find(banners, banner)
		if index then
			table.remove(banners, index)
		end
		banner:Destroy()
		stackBanners()
	end)
end

-- Slowly orbits a viewport's camera around its model. Returns a stop function.
function Kit.orbit(viewport: ViewportFrame, model: Model): () -> ()
	local camera = viewport.CurrentCamera :: Camera
	local box, size = model:GetBoundingBox()
	local distance = size.Magnitude * 1.5 + 0.5
	local connection = RunService.RenderStepped:Connect(function()
		local angle = os.clock() * 0.8
		camera.CFrame = CFrame.lookAt(box.Position + Vector3.new(math.sin(angle), 0.3, -math.cos(angle)).Unit * distance, box.Position)
	end)
	return function()
		connection:Disconnect()
	end
end

-- A short message at the top of the screen that fades out.
function Kit.toast(text: string, color: Color3?)
	local label = Kit.text({
		Text = text,
		TextColor3 = color or WHITE,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 90),
		Size = UDim2.fromOffset(700, 44),
		StrokeThickness = 3,
		ZIndex = 50,
		Parent = Kit.getGui(),
	})
	Kit.pop(label, 0.2)
	local fade = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 1.5)
	TweenService:Create(label, fade, { TextTransparency = 1 }):Play()
	TweenService:Create(label:FindFirstChildOfClass("UIStroke") :: UIStroke, fade, { Transparency = 1 }):Play()
	task.delay(2.1, function()
		label:Destroy()
	end)
end

return Kit
