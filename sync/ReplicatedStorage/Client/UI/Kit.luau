--[[
	UI Kit
	The shared look and building blocks for every menu (GDD §1, §13), in the factory's
	style (UI v3): each menu has its own hue family like each factory building, chunky
	rounded panels with thick dark outlines, a striped header with a big icon breaking
	out of its corner, a neon rim, a slow sheen, bouncy buttons and a click on every
	press. Icons are our own images (`Config/Icons`, `Kit.icon`), never emojis.
	Everything is designed at 1600x900 and scaled to the screen. Client only.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local Config = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")
local Icons = require(Config:WaitForChild("Icons"))
local Sounds = require(Config:WaitForChild("Sounds"))

local DESIGN_SIZE = Vector2.new(1600, 900)
local UI_BOOST = 1.18
local FIT_PANEL = Vector2.new(1060, 770) -- the Album (1000 x 660) with its title bar and a margin
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

-- Hue families, one per menu (like one per factory building): Light for the panel's
-- tint, Main and Dark for its header, Neon for its rim.
export type Hue = { Light: Color3, Main: Color3, Dark: Color3, Neon: Color3 }
Kit.Hues = {
	Purple = { Light = Color3.fromRGB(215, 180, 255), Main = Color3.fromRGB(150, 90, 245), Dark = Color3.fromRGB(85, 40, 185), Neon = Color3.fromRGB(225, 150, 255) },
	Blue = { Light = Color3.fromRGB(165, 225, 255), Main = Color3.fromRGB(60, 150, 255), Dark = Color3.fromRGB(25, 80, 200), Neon = Color3.fromRGB(100, 235, 255) },
	Gold = { Light = Color3.fromRGB(255, 230, 140), Main = Color3.fromRGB(255, 175, 40), Dark = Color3.fromRGB(205, 105, 10), Neon = Color3.fromRGB(255, 230, 80) },
	Pink = { Light = Color3.fromRGB(255, 185, 235), Main = Color3.fromRGB(240, 90, 195), Dark = Color3.fromRGB(170, 35, 140), Neon = Color3.fromRGB(255, 130, 230) },
	Green = { Light = Color3.fromRGB(175, 250, 160), Main = Color3.fromRGB(60, 200, 90), Dark = Color3.fromRGB(25, 130, 55), Neon = Color3.fromRGB(130, 255, 150) },
	Teal = { Light = Color3.fromRGB(160, 240, 235), Main = Color3.fromRGB(35, 185, 200), Dark = Color3.fromRGB(15, 115, 140), Neon = Color3.fromRGB(100, 255, 240) },
	Red = { Light = Color3.fromRGB(255, 170, 170), Main = Color3.fromRGB(235, 70, 85), Dark = Color3.fromRGB(160, 25, 50), Neon = Color3.fromRGB(255, 110, 125) },
	Orange = { Light = Color3.fromRGB(255, 205, 150), Main = Color3.fromRGB(255, 130, 45), Dark = Color3.fromRGB(200, 70, 15), Neon = Color3.fromRGB(255, 180, 80) },
}

-- A hue's gradient pair (top, bottom) for buttons and pills.
function Kit.pair(hue: Hue): { Color3 }
	return { hue.Main:Lerp(WHITE, 0.25), hue.Dark:Lerp(hue.Main, 0.3) }
end

-- A hue family from a gradient pair (top, bottom), for menus colored by data (a
-- gamepass's own colors).
function Kit.hue(colors: { Color3 }): Hue
	local top, bottom = colors[1], colors[2] or colors[1]
	return {
		Light = top:Lerp(WHITE, 0.3),
		Main = top:Lerp(bottom, 0.4),
		Dark = bottom:Lerp(Color3.new(0, 0, 0), 0.2),
		Neon = top:Lerp(WHITE, 0.35),
	}
end

local gui: Frame? = nil
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

-- One of our icons (`Config/Icons`) as an ImageLabel filling its parent unless `props`
-- says otherwise.
function Kit.icon(name: string, props: { [string]: any }?): ImageLabel
	local image = Kit.new("ImageLabel", {
		Name = "Icon",
		BackgroundTransparency = 1,
		Image = (Icons :: any)[name] or "",
		ScaleType = Enum.ScaleType.Fit,
		Size = UDim2.fromScale(1, 1),
	})
	local properties: { [string]: any } = props or {}
	for key, value in properties do
		if key ~= "Parent" then
			(image :: any)[key] = value
		end
	end
	image.Parent = properties.Parent
	return image
end

-- One line of text with one of our icons before it, centered in a frame (`props` sets
-- its Position, Size, AnchorPoint, ZIndex...): where an emoji sat inside a sentence.
-- Returns the frame and its label.
function Kit.iconText(props: { [string]: any }, icon: string, text: string, color: Color3?): (Frame, TextLabel)
	local holder = Kit.new("Frame", { BackgroundTransparency = 1, Size = UDim2.fromOffset(400, 40) })
	for key, value in props do
		if key ~= "Parent" then
			(holder :: any)[key] = value
		end
	end
	local height = holder.Size.Y.Offset
	Kit.new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = holder,
	})
	Kit.icon(icon, { LayoutOrder = 1, Size = UDim2.fromOffset(height * 1.15, height * 1.15), ZIndex = holder.ZIndex, Parent = holder })
	local label = Kit.text({
		Text = text,
		TextColor3 = color or WHITE,
		TextScaled = false,
		TextSize = math.floor(height * 0.85),
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromOffset(0, height),
		LayoutOrder = 2,
		ZIndex = holder.ZIndex,
		Parent = holder,
	})
	holder.Parent = props.Parent
	return holder, label
end

-- A row of `count` gold stars (a rarity's rank), centered in a frame (`props` sets its
-- Position, Size, AnchorPoint, ZIndex...; `align` "Left" or "Right" packs them to a side).
function Kit.stars(props: { [string]: any }, count: number, align: string?): Frame
	local holder = Kit.new("Frame", { Name = "Stars", BackgroundTransparency = 1, Size = UDim2.fromOffset(200, 30) })
	for key, value in props do
		if key ~= "Parent" then
			(holder :: any)[key] = value
		end
	end
	local height = holder.Size.Y.Offset
	Kit.new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = if align == "Left" then Enum.HorizontalAlignment.Left elseif align == "Right" then Enum.HorizontalAlignment.Right else Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, -math.floor(height * 0.12)),
		Parent = holder,
	})
	for _ = 1, count do
		Kit.icon("Star", { Size = UDim2.fromOffset(height, height), ZIndex = holder.ZIndex, Parent = holder })
	end
	holder.Parent = props.Parent
	return holder
end

-- An icon's image id, to swap an ImageLabel's icon.
function Kit.iconId(name: string): string
	return (Icons :: any)[name] or ""
end

-- White diagonal stripes over a frame (rounded like it), faint unless `transparency`
-- says otherwise.
function Kit.stripes(parent: GuiObject, transparency: number?, radius: number?, zIndex: number?): ImageLabel
	local stripes = Kit.icon("Stripes", {
		Name = "Stripes",
		ScaleType = Enum.ScaleType.Tile,
		TileSize = UDim2.fromOffset(72, 72),
		ImageTransparency = transparency or 0.86,
		ZIndex = zIndex or parent.ZIndex,
		Parent = parent,
	})
	Kit.corner(stripes, radius or 16)
	return stripes
end

-- A band of light sweeping across a frame now and then.
function Kit.sheen(parent: GuiObject, every: number?, zIndex: number?): Frame
	local sheen = Kit.new("Frame", {
		Name = "Sheen",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = WHITE,
		ZIndex = zIndex or parent.ZIndex,
		Parent = parent,
	})
	Kit.corner(sheen, 16)
	local gradient = Kit.new("UIGradient", {
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.42, 1),
			NumberSequenceKeypoint.new(0.5, 0.45),
			NumberSequenceKeypoint.new(0.58, 1),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Rotation = 18,
		Offset = Vector2.new(-1, 0),
		Parent = sheen,
	})
	TweenService:Create(gradient, TweenInfo.new(1.1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, -1, false, every or 3), { Offset = Vector2.new(1, 0) }):Play()
	return sheen
end

-- A pulsing neon line just inside a frame's outline.
function Kit.neonRim(parent: GuiObject, color: Color3, radius: number?, inset: number?): Frame
	local gap = inset or 6
	local rim = Kit.new("Frame", {
		Name = "NeonRim",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(1, -gap * 2, 1, -gap * 2),
		BackgroundTransparency = 1,
		ZIndex = 1,
		Parent = parent,
	})
	Kit.corner(rim, math.max(4, (radius or 24) - gap))
	local stroke = Kit.new("UIStroke", { Thickness = 3, Color = color, Parent = rim })
	TweenService:Create(stroke, TweenInfo.new(1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Transparency = 0.55 }):Play()
	return rim
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

-- A chunky, bouncy button. `colors` is a gradient pair from Kit.Colors; `icon` (one of
-- ours) goes left of the text, or alone in the middle.
function Kit.button(props: { [string]: any }, colors: { Color3 }, text: string?, onClick: () -> (), icon: string?): TextButton
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
	-- a darker bottom, so it stands up like a key
	local base = Kit.new("Frame", { Name = "Base", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), ZIndex = 0, Parent = button })
	Kit.corner(base, 14)
	Kit.new("UIGradient", {
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.68, 1), NumberSequenceKeypoint.new(1, 0.72) }),
		Rotation = 90,
		Parent = base,
	})
	Kit.shine(button, 10)
	local height = if button.Size.Y.Offset > 0 then button.Size.Y.Offset else 56
	if icon then
		Kit.icon(icon, {
			AnchorPoint = Vector2.new(if text then 0 else 0.5, 0.5),
			Position = if text then UDim2.new(0, 4, 0.5, 0) else UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(if text then 0.92 else 0.8, if text then 0.92 else 0.8),
			SizeConstraint = Enum.SizeConstraint.RelativeYY,
			Parent = button,
		})
	end
	if text then
		local iconWidth = if icon then height * 0.92 + 4 else 0
		Kit.text({
			Text = text,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, iconWidth / 2, 0.5, 0),
			Size = UDim2.new(0.88, -iconWidth, 0.68, 0),
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

-- Where a viewport's camera sits round its model: three quarters on (models face -Z;
-- head-on some are just a column, like Tralalero), a little from above.
local VIEW_ANGLE = math.rad(38)
local VIEW_LIFT = 0.3
local VIEW_SWAY = math.rad(18) -- Kit.orbit sways this far either way

local function viewFrom(angle: number): Vector3
	return Vector3.new(math.sin(angle), VIEW_LIFT, -math.cos(angle)).Unit
end

-- A loot box like the map's (LootBoxes), for a ViewportFrame: its rarity's color and rank
-- (1 Common .. 6 Godly), a white ribbon and bow, a neon band under the lid, glowing edges
-- from Rare up and a halo of lights from Legendary up (no beam: it would spoil the framing).
function Kit.boxModel(color: Color3, rank: number): Model
	local model = Instance.new("Model")
	local light = color:Lerp(WHITE, 0.35)
	local function block(size: Vector3, at: Vector3, tint: Color3, material: Enum.Material?, ball: boolean?): Part
		local part = Instance.new("Part")
		part.Anchored = true
		part.Size = size
		part.CFrame = CFrame.new(at)
		part.Color = tint
		part.Material = material or Enum.Material.SmoothPlastic
		if ball then
			part.Shape = Enum.PartType.Ball
		end
		part.Parent = model
		return part
	end
	local metal = if rank == 4 then Enum.Material.Metal else nil
	block(Vector3.new(3, 2.4, 3), Vector3.zero, color, metal)
	block(Vector3.new(3.3, 0.7, 3.3), Vector3.new(0, 1.5, 0), light, metal)
	block(Vector3.new(3.1, 3.2, 0.35), Vector3.new(0, 0.2, 0), Color3.fromRGB(250, 250, 255))
	block(Vector3.new(0.35, 3.2, 3.1), Vector3.new(0, 0.2, 0), Color3.fromRGB(250, 250, 255))
	for _, side in { -1, 1 } do
		local loop = block(Vector3.new(1, 0.65, 0.35), Vector3.new(side * 0.5, 2.1, 0), Color3.fromRGB(250, 250, 255))
		loop.CFrame *= CFrame.Angles(0, 0, side * math.rad(-30))
	end
	block(Vector3.one * 0.5, Vector3.new(0, 2, 0), Color3.fromRGB(250, 250, 255), nil, true)
	block(Vector3.new(3.2, 0.3, 3.2), Vector3.new(0, 1, 0), color, Enum.Material.Neon)
	if rank >= 3 then
		for _, x in { -1.5, 1.5 } do
			for _, z in { -1.5, 1.5 } do
				block(Vector3.new(0.25, 2.5, 0.25), Vector3.new(x, 0, z), light, Enum.Material.Neon)
			end
		end
	end
	if rank >= 4 then
		for index = 0, 9 do
			local a = index / 10 * math.pi * 2
			block(Vector3.one * 0.45, Vector3.new(math.cos(a) * 1.8, 3.3, math.sin(a) * 1.8), light, Enum.Material.Neon, true)
		end
	end
	return model
end

-- A ViewportFrame showing `model` at three quarters.
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
	camera.CFrame = CFrame.lookAt(box.Position + viewFrom(VIEW_ANGLE) * distance, box.Position)
	frame.Parent = props.Parent
	return frame
end

-- The canvas every menu lives in: a frame in the BrainrotUI ScreenGui, sized in design
-- units (screen / scale) with the UIScale inside it, so it always covers the screen
-- exactly. (A UIScale straight on a ScreenGui scales its children from the screen's
-- top-left corner: full-screen frames ran off the right and bottom edges and centered
-- ones drifted, on any screen bigger than the 1600x900 design.)
function Kit.getGui(): Frame
	if gui and gui.Parent and gui.Parent.Parent then
		return gui
	end
	local screen = Kit.new("ScreenGui", {
		Name = "BrainrotUI",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = Players.LocalPlayer:WaitForChild("PlayerGui"),
	})
	local canvas = Kit.new("Frame", {
		Name = "Canvas",
		BackgroundTransparency = 1,
		Parent = screen,
	})
	local scale = Kit.new("UIScale", { Parent = canvas })
	local function rescale()
		local camera = workspace.CurrentCamera
		local size = if camera then camera.ViewportSize else DESIGN_SIZE
		-- UI_BOOST bigger than the plain fit (the user: menus were small and fiddly to
		-- tap), but never so big that the largest panel (FIT_PANEL) runs off the screen
		local fit = math.min(size.X / DESIGN_SIZE.X, size.Y / DESIGN_SIZE.Y) * UI_BOOST
		local factor = math.clamp(math.min(fit, size.X / FIT_PANEL.X, size.Y / FIT_PANEL.Y), 0.45, 1.6)
		scale.Scale = factor
		canvas.Size = UDim2.fromOffset(size.X / factor, size.Y / factor)
	end
	rescale()
	if workspace.CurrentCamera then
		workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(rescale)
	end
	gui = canvas
	return canvas
end

-- A centered menu panel in a hue family (Kit.Hues; a gradient pair works too): a tinted
-- panel with faint stripes and a neon rim, a striped header with a sheen, `icon` big
-- and tilted over its top-left corner, a red close button on its top-right corner.
-- Returns the panel (hidden) and its content area (below the header).
function Kit.modal(name: string, title: string, colors: any, size: Vector2, icon: string?): (Frame, Frame)
	local hue: Hue = if colors.Main then colors else Kit.hue(colors)
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
	Kit.corner(panel, 26)
	Kit.stroke(panel, 6)
	Kit.gradient(panel, { hue.Light:Lerp(WHITE, 0.8), hue.Light:Lerp(WHITE, 0.5) })
	Kit.stripes(panel, 0.9, 26, 1)
	Kit.neonRim(panel, hue.Neon, 26)
	Kit.new("UIScale", { Name = "OpenScale", Parent = panel })

	local header = Kit.new("Frame", {
		Name = "Header",
		Position = UDim2.fromOffset(10, 8),
		Size = UDim2.new(1, -20, 0, 58),
		BackgroundColor3 = WHITE,
		ZIndex = 2,
		Parent = panel,
	})
	Kit.corner(header, 18)
	Kit.stroke(header, 4)
	Kit.gradient(header, { hue.Main, hue.Dark })
	Kit.stripes(header, 0.78, 18)
	Kit.shine(header, 14)
	Kit.sheen(header, 3.5)
	local left = 22
	if icon then
		-- the menu's icon, big, tilted and bobbing over the panel's corner
		local badge = Kit.icon(icon, {
			Name = "TitleIcon",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromOffset(30, 26),
			Size = UDim2.fromOffset(108, 108),
			Rotation = -12,
			ZIndex = 6,
			Parent = panel,
		})
		local bob = TweenInfo.new(1.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
		TweenService:Create(badge, bob, { Rotation = -4, Position = UDim2.fromOffset(30, 20) }):Play()
		left = 96
	end
	Kit.text({
		Name = "Title",
		Text = title,
		Position = UDim2.fromOffset(left, 7),
		Size = UDim2.new(1, -left - 70, 0, 44),
		TextXAlignment = Enum.TextXAlignment.Left,
		StrokeThickness = 3.5,
		ZIndex = 3,
		Parent = header,
	})
	Kit.button({
		Name = "Close",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(1, -10, 0, 10),
		Size = UDim2.fromOffset(62, 62),
		ZIndex = 6,
		Parent = panel,
	}, Kit.Colors.Red, nil, function()
		Kit.close(panel)
	end, "Close")

	local content = Kit.new("Frame", {
		Name = "Content",
		Position = UDim2.fromOffset(0, 72),
		Size = UDim2.new(1, 0, 1, -72),
		BackgroundTransparency = 1,
		ZIndex = 2,
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

-- Whether a menu is open (the join popups wait until it's closed).
function Kit.menuOpen(): boolean
	return openModal ~= nil and openModal.Visible
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

-- `icon` is one of ours (`Config/Icons`). `hype` 0-3 grows the show: 1+ a sunburst behind it, 2+ a screen flash and confetti,
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
	Kit.stripes(card, 0.8, 24, 48)
	local badge = Kit.icon(icon, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(66, BANNER_SIZE.Y / 2),
		Size = UDim2.fromOffset(96, 96),
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
		table.insert(sparks, Kit.icon("Sparkle", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(index / (5 + hype * 2), if index % 2 == 0 then 0.02 else 0.98),
			Size = UDim2.fromOffset(30, 30),
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
			spark.ImageTransparency = 1 - (math.sin(t * 5 + index * 1.3) + 1) / 2
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

-- How far from its model's middle a viewport's camera must be for all of it to fit in
-- a frame `aspect` wide per 1 tall, at any point of Kit.orbit's sway: every corner of
-- every part, projected onto the camera, stays inside the field of view (the parts'
-- corners, not the model's box: a long arm or a staff out to one side leaves the box's
-- other corners empty).
function Kit.fitDistance(model: Model, aspect: number, fov: number?): number
	local box = model:GetBoundingBox()
	local center = box.Position
	local corners: { Vector3 } = {}
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") and part.Transparency < 0.99 then
			local half = part.Size / 2
			for x = -1, 1, 2 do
				for y = -1, 1, 2 do
					for z = -1, 1, 2 do
						table.insert(corners, part.CFrame:PointToWorldSpace(Vector3.new(x * half.X, y * half.Y, z * half.Z)) - center)
					end
				end
			end
		end
	end
	local tanUp = math.tan(math.rad((fov or 35) / 2))
	local tanSide = tanUp * aspect
	local distance = 0
	for _, sway in { -VIEW_SWAY, -VIEW_SWAY / 2, 0, VIEW_SWAY / 2, VIEW_SWAY } do
		local toCamera = viewFrom(VIEW_ANGLE + sway)
		local right = toCamera:Cross(Vector3.yAxis).Unit
		local up = right:Cross(toCamera).Unit
		for _, corner in corners do
			local toward = corner:Dot(toCamera) -- (a corner nearer the camera needs it farther back)
			distance = math.max(distance, toward + math.abs(corner:Dot(right)) / tanSide, toward + math.abs(corner:Dot(up)) / tanUp)
		end
	end
	return distance
end

-- Sways a viewport's camera to and fro round its model's three-quarter view (a full
-- orbit showed it head-on and from behind half the time), looking at `focus` from
-- `distance` if given (else the whole model). Returns a stop function.
function Kit.orbit(viewport: ViewportFrame, model: Model, focus: Vector3?, distance: number?): () -> ()
	local camera = viewport.CurrentCamera :: Camera
	local box, size = model:GetBoundingBox()
	local center = focus or box.Position
	local reach = distance or size.Magnitude * 1.5 + 0.5
	local start = os.clock()
	local connection = RunService.RenderStepped:Connect(function()
		local angle = VIEW_ANGLE + math.sin((os.clock() - start) * 0.9) * VIEW_SWAY
		camera.CFrame = CFrame.lookAt(center + viewFrom(angle) * reach, center)
	end)
	return function()
		connection:Disconnect()
	end
end

-- A short message at the top of the screen that fades out: a dark pill with `icon`
-- (one of ours) at its left and the text in `color`.
function Kit.toast(text: string, color: Color3?, icon: string?)
	local tint = color or WHITE
	local pill = Kit.new("Frame", {
		Name = "Toast",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 10), -- (up in the top bar's middle, clear of the menus' titles)
		Size = UDim2.fromOffset(0, 54),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = Kit.Outline,
		BackgroundTransparency = 0.2,
		ZIndex = 50,
		Parent = Kit.getGui(),
	})
	Kit.new("UICorner", { CornerRadius = UDim.new(0.5, 0), Parent = pill })
	local rim = Kit.new("UIStroke", { Thickness = 3, Color = tint, Parent = pill })
	Kit.new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = pill,
	})
	Kit.new("UIPadding", { PaddingLeft = UDim.new(0, if icon then 8 else 24), PaddingRight = UDim.new(0, 24), Parent = pill })
	local image = if icon then Kit.icon(icon, { LayoutOrder = 1, Size = UDim2.fromOffset(48, 48), ZIndex = 51, Parent = pill }) else nil
	local label = Kit.text({
		Text = text,
		TextColor3 = tint,
		TextScaled = false,
		TextSize = 30,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromOffset(0, 40),
		LayoutOrder = 2,
		StrokeThickness = 2.5,
		ZIndex = 51,
		Parent = pill,
	})
	Kit.pop(pill, 0.2)
	local fade = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 1.8)
	TweenService:Create(pill, fade, { BackgroundTransparency = 1 }):Play()
	TweenService:Create(rim, fade, { Transparency = 1 }):Play()
	TweenService:Create(label, fade, { TextTransparency = 1 }):Play()
	TweenService:Create(label:FindFirstChildOfClass("UIStroke") :: UIStroke, fade, { Transparency = 1 }):Play()
	if image then
		TweenService:Create(image, fade, { ImageTransparency = 1 }):Play()
	end
	task.delay(2.4, function()
		pill:Destroy()
	end)
end

return Kit
