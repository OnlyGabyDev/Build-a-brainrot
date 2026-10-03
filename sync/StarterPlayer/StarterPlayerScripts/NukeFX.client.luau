--[[
	NukeFX
	The NUKE's show on every client (Config/Nuke, NukeManager), by the server's clock:
	a flashing warning banner, a chat message and an air-raid siren; a giant Bombardiro
	Crocodilo slowly fading in far out over the valley and droning in over the hub; the
	nuke dropping out of it with a whistle; at the impact every screen goes white (the
	server kills everyone then), the camera shakes, and a fireball, a shockwave and a
	mushroom cloud rise over the hub; the bomber flies on and fades out.
]]

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TextChatService = game:GetService("TextChatService")
local TweenService = game:GetService("TweenService")

local Effects = require(ReplicatedStorage:WaitForChild("Client"):WaitForChild("Effects"))
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local BrainrotModels = require(Shared:WaitForChild("BrainrotModels"))
local Nuke = require(Config:WaitForChild("Nuke"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Sounds = require(Config:WaitForChild("Sounds"))

local player = Players.LocalPlayer
local HUB = Vector3.new(0, 0.4, 0) -- where it lands: the plaza's middle
local WARNING_COLOR = Color3.fromRGB(255, 60, 50)
local NUKE_YELLOW = Color3.fromRGB(255, 205, 40)
local NUKE_BLACK = Color3.fromRGB(30, 28, 32)
local FIRE_COLORS = { Color3.fromRGB(255, 250, 220), Color3.fromRGB(255, 180, 60), Color3.fromRGB(255, 90, 30) }
local SMOKE_COLOR = Color3.fromRGB(120, 105, 100)

-- Helpers ------------------------------------------------------------------------

local function newPart(parent: Instance, name: string, size: Vector3, cframe: CFrame, color: Color3, shape: Enum.PartType?, material: Enum.Material?): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Shape = shape or Enum.PartType.Block
	part.Material = material or Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

-- A sound for everyone, wherever they are (2D), cut short after `seconds`.
local function playFor(id: string, volume: number, seconds: number, speed: number?): Sound
	local sound = Instance.new("Sound")
	sound.SoundId = id
	sound.Volume = volume
	sound.PlaybackSpeed = speed or 1
	sound.Parent = SoundService
	sound:Play()
	task.delay(seconds, function()
		TweenService:Create(sound, TweenInfo.new(0.6), { Volume = 0 }):Play()
		task.wait(0.7)
		sound:Destroy()
	end)
	return sound
end

-- A sound that comes from `part`, heard far away.
local function playFrom(part: BasePart, id: string, volume: number, looped: boolean): Sound
	local sound = Instance.new("Sound")
	sound.SoundId = id
	sound.Volume = volume
	sound.Looped = looped
	sound.RollOffMode = Enum.RollOffMode.Linear
	sound.RollOffMinDistance = 40
	sound.RollOffMaxDistance = 2200
	sound.Parent = part
	sound:Play()
	return sound
end

local function setVisible(model: Model, alpha: number) -- 0 hidden, 1 shown
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			part.LocalTransparencyModifier = 1 - alpha
		end
	end
end

-- Calls `update(alpha)` every frame from `from` to `to` (seconds since `start`).
local function during(start: number, from: number, to: number, update: (alpha: number) -> ())
	while true do
		local t = workspace:GetServerTimeNow() - start
		if t >= to then
			update(1)
			return
		end
		if t >= from then
			update((t - from) / (to - from))
		end
		RunService.Heartbeat:Wait()
	end
end

local function waitUntil(start: number, at: number)
	local remaining = start + at - workspace:GetServerTimeNow()
	if remaining > 0 then
		task.wait(remaining)
	end
end

-- The screen ------------------------------------------------------------------------

local function overlay(): ScreenGui
	local gui = Instance.new("ScreenGui")
	gui.Name = "NukeUI"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 50
	gui.Parent = player:WaitForChild("PlayerGui")
	return gui
end

-- The warning: a red and yellow banner flashing at the top until the impact.
local function banner(gui: ScreenGui, buyer: string): Frame
	local frame = Instance.new("Frame")
	frame.AnchorPoint = Vector2.new(0.5, 0)
	frame.Position = UDim2.new(0.5, 0, 0, 70)
	frame.Size = UDim2.fromScale(0.8, 0.11)
	frame.BackgroundColor3 = WARNING_COLOR
	frame.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 18)
	corner.Parent = frame
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 5
	stroke.Color = NUKE_YELLOW
	stroke.Parent = frame
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(0.94, 0.8)
	label.Position = UDim2.fromScale(0.03, 0.1)
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Text = `⚠️ {string.upper(buyer)} BOUGHT A NUKE! ⚠️`
	label.Parent = frame
	local outline = Instance.new("UIStroke")
	outline.Thickness = 3
	outline.Color = Color3.fromRGB(60, 10, 10)
	outline.Parent = label
	return frame
end

-- The world ------------------------------------------------------------------------

-- The giant bomber: Bombardiro Crocodilo's four parts, blown up.
local function makeBomber(folder: Folder): Model
	local model = Instance.new("Model")
	model.Name = "Bomber"
	for _, partType in { "Legs", "Body", "Arms", "Head" } do
		local part = BrainrotModels.CreatePart(Nuke.BomberId, partType)
		for _, child in part:GetChildren() do
			child.Parent = model
		end
		part:Destroy()
	end
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			part.Anchored = true
			part.CanCollide = false
			part.CanQuery = false
			part.CanTouch = false
			part.CastShadow = false
		end
	end
	model.WorldPivot = CFrame.identity
	model:ScaleTo(Nuke.BomberScale)
	setVisible(model, 0)
	model.Parent = folder
	return model
end

-- The nuke: a yellow bomb with black bands and ☢️ signs, a round nose and tail fins,
-- nose down. Its pivot is its nose.
local function makeNuke(folder: Folder): Model
	local model = Instance.new("Model")
	model.Name = "Nuke"
	local body = newPart(model, "Body", Vector3.new(4.4, 9, 4.4), CFrame.new(0, 6.2, 0), NUKE_YELLOW)
	newPart(model, "Nose", Vector3.one * 4.6, CFrame.new(0, 2.2, 0), NUKE_YELLOW, Enum.PartType.Ball)
	for _, y in { 3.6, 8.4 } do
		newPart(model, "Band", Vector3.new(4.6, 0.9, 4.6), CFrame.new(0, y, 0), NUKE_BLACK)
	end
	newPart(model, "Tail", Vector3.new(2.8, 2.4, 2.8), CFrame.new(0, 11.8, 0), NUKE_BLACK)
	for k = 0, 3 do
		newPart(model, "Fin", Vector3.new(0.4, 3.4, 3.2), CFrame.Angles(0, k * math.pi / 2, 0) * CFrame.new(0, 12.2, 2.4), NUKE_YELLOW)
	end
	for _, face in { Enum.NormalId.Front, Enum.NormalId.Back, Enum.NormalId.Left, Enum.NormalId.Right } do
		local gui = Instance.new("SurfaceGui")
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.Face = face
		gui.LightInfluence = 0
		gui.Parent = body
		local label = Instance.new("TextLabel")
		label.BackgroundTransparency = 1
		label.Size = UDim2.fromScale(1, 0.5)
		label.Position = UDim2.fromScale(0, 0.25)
		label.TextScaled = true
		label.Text = "☢️"
		label.Parent = gui
	end
	model.WorldPivot = CFrame.new(0, 0, 0)
	model.Parent = folder
	return model
end

-- The blast at the hub: a fireball, a shockwave along the ground, a mushroom cloud.
local function blast(folder: Folder)
	local fireball = newPart(folder, "Fireball", Vector3.one * 10, CFrame.new(HUB), FIRE_COLORS[1], Enum.PartType.Ball, Enum.Material.Neon)
	TweenService:Create(fireball, TweenInfo.new(1.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Size = Vector3.one * 240, Color = FIRE_COLORS[3], Transparency = 0.35 }):Play()
	task.delay(1.4, function()
		TweenService:Create(fireball, TweenInfo.new(3), { Transparency = 1 }):Play()
	end)
	local wave = newPart(folder, "Shockwave", Vector3.new(2, 20, 20), CFrame.new(HUB + Vector3.new(0, 1, 0)) * CFrame.Angles(0, 0, math.pi / 2), Color3.new(1, 1, 1), Enum.PartType.Cylinder, Enum.Material.Neon)
	wave.Transparency = 0.2
	TweenService:Create(wave, TweenInfo.new(2.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = Vector3.new(2, 1400, 1400), Transparency = 1 }):Play()
	-- the mushroom cloud, rising and spreading
	local stem = newPart(folder, "CloudStem", Vector3.new(10, 40, 40), CFrame.new(HUB + Vector3.new(0, 5, 0)) * CFrame.Angles(0, 0, math.pi / 2), SMOKE_COLOR, Enum.PartType.Cylinder)
	local cap = newPart(folder, "CloudCap", Vector3.new(60, 30, 60), CFrame.new(HUB + Vector3.new(0, 20, 0)), FIRE_COLORS[2], Enum.PartType.Ball, Enum.Material.Neon)
	local rise = TweenInfo.new(4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(stem, rise, { Size = Vector3.new(160, 44, 44), CFrame = CFrame.new(HUB + Vector3.new(0, 80, 0)) * CFrame.Angles(0, 0, math.pi / 2) }):Play()
	TweenService:Create(cap, rise, { Size = Vector3.new(220, 110, 220), CFrame = CFrame.new(HUB + Vector3.new(0, 175, 0)), Color = SMOKE_COLOR }):Play()
	task.delay(6, function()
		local fade = TweenInfo.new(4)
		TweenService:Create(stem, fade, { Transparency = 1 }):Play()
		TweenService:Create(cap, fade, { Transparency = 1 }):Play()
	end)

	-- a second, slower orange shockwave and a pillar of light
	local wave2 = newPart(folder, "Shockwave2", Vector3.new(4, 30, 30), CFrame.new(HUB + Vector3.new(0, 3, 0)) * CFrame.Angles(0, 0, math.pi / 2), FIRE_COLORS[2], Enum.PartType.Cylinder, Enum.Material.Neon)
	wave2.Transparency = 0.3
	TweenService:Create(wave2, TweenInfo.new(4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = Vector3.new(4, 900, 900), Transparency = 1 }):Play()
	local pillar = newPart(folder, "Pillar", Vector3.new(600, 30, 30), CFrame.new(HUB + Vector3.new(0, 300, 0)) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(255, 250, 220), Enum.PartType.Cylinder, Enum.Material.Neon)
	pillar.Transparency = 0.1
	TweenService:Create(pillar, TweenInfo.new(2.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = Vector3.new(600, 2, 2), Transparency = 1 }):Play()
	-- a scorched crater that fades away slowly
	local scorch = newPart(folder, "Scorch", Vector3.new(0.4, 160, 160), CFrame.new(HUB + Vector3.new(0, 0.6, 0)) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(35, 25, 20), Enum.PartType.Cylinder)
	scorch.Transparency = 0.15
	task.delay(8, function()
		TweenService:Create(scorch, TweenInfo.new(6), { Transparency = 1 }):Play()
	end)
	-- fire and smoke bursting out of the fireball, embers raining down
	local function burst(color: ColorSequence, count: number, speed: NumberRange, size: number, life: NumberRange, texture: string)
		local emitter = Instance.new("ParticleEmitter")
		emitter.Texture = texture
		emitter.Color = color
		emitter.Speed = speed
		emitter.Lifetime = life
		emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, size), NumberSequenceKeypoint.new(1, size * 2.5) })
		emitter.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) })
		emitter.SpreadAngle = Vector2.new(180, 180)
		emitter.LightEmission = 0.6
		emitter.Rate = 0
		emitter.Parent = fireball
		emitter:Emit(count)
	end
	local fire = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 240, 150)), ColorSequenceKeypoint.new(0.4, Color3.fromRGB(255, 120, 30)), ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 30, 20)) })
	burst(fire, 160, NumberRange.new(60, 160), 18, NumberRange.new(1.5, 3), "rbxasset://textures/particles/fire_main.dds")
	burst(ColorSequence.new(SMOKE_COLOR), 120, NumberRange.new(30, 90), 30, NumberRange.new(4, 7), "rbxasset://textures/particles/smoke_main.dds")
	burst(ColorSequence.new(Color3.fromRGB(255, 180, 60)), 220, NumberRange.new(80, 220), 3, NumberRange.new(2, 4), "rbxasset://textures/particles/sparkles_main.dds")
	-- burning debris flung out of the crater
	for _ = 1, 36 do
		local size = math.random(3, 9)
		local chunk = newPart(folder, "Debris", Vector3.new(size, size * 0.7, size), CFrame.new(HUB + Vector3.new(0, 6, 0)) * CFrame.Angles(math.random() * 6, math.random() * 6, math.random() * 6), if math.random() < 0.5 then Color3.fromRGB(70, 55, 45) else FIRE_COLORS[2], nil, if math.random() < 0.4 then Enum.Material.Neon else Enum.Material.Slate)
		chunk.Anchored = false
		chunk.CanCollide = false
		local angle = math.random() * math.pi * 2
		chunk.AssemblyLinearVelocity = Vector3.new(math.cos(angle), 0, math.sin(angle)) * math.random(60, 160) + Vector3.new(0, math.random(80, 180), 0)
		chunk.AssemblyAngularVelocity = Vector3.new(math.random(-8, 8), math.random(-8, 8), math.random(-8, 8))
		task.delay(5, function()
			chunk:Destroy()
		end)
	end
	-- the sky glows orange, then settles
	local tint = Instance.new("ColorCorrectionEffect")
	tint.Name = "NukeTint"
	tint.Parent = Lighting
	TweenService:Create(tint, TweenInfo.new(0.4), { TintColor = Color3.fromRGB(255, 190, 140), Brightness = 0.15, Saturation = 0.3 }):Play()
	task.delay(5, function()
		local settle = TweenService:Create(tint, TweenInfo.new(5), { TintColor = Color3.new(1, 1, 1), Brightness = 0, Saturation = 0 })
		settle:Play()
		settle.Completed:Wait()
		tint:Destroy()
	end)
end

-- The show -----------------------------------------------------------------------------

local function play(buyer: string, start: number)
	local gui = overlay()
	local folder = Instance.new("Folder")
	folder.Name = "NukeFX"
	folder.Parent = workspace

	-- the warning
	local warning = banner(gui, buyer)
	pcall(function()
		local general = TextChatService:FindFirstChild("TextChannels") and TextChatService.TextChannels:FindFirstChild("RBXGeneral")
		if general then
			(general :: TextChannel):DisplaySystemMessage(`<font color="#FF4040">⚠️ {buyer} bought a NUKE! ⚠️</font>`)
		end
	end)
	playFor(Sounds.Siren, 0.6, Nuke.Impact - 1)
	task.spawn(function()
		while warning.Parent do
			warning.BackgroundColor3 = if math.floor(os.clock() * 4) % 2 == 0 then WARNING_COLOR else Color3.fromRGB(120, 10, 10)
			task.wait(0.05)
		end
	end)

	-- the bomber: far out and high, fading in, droning in over the hub and on
	local bomber = makeBomber(folder)
	local from = Vector3.new(-Nuke.ApproachFrom, Nuke.Altitude + 60, Nuke.ApproachFrom * 0.35)
	local over = Vector3.new(0, Nuke.Altitude, 0)
	local away = over * 2 - from
	local heading = (over - from).Unit
	local function bomberAt(position: Vector3)
		bomber:PivotTo(CFrame.lookAt(position, position + heading))
	end
	bomberAt(from)
	local anchor = bomber:FindFirstChildWhichIsA("BasePart")
	local drone = if anchor then playFrom(anchor, Sounds.Bomber, 2.5, true) else nil
	task.spawn(function()
		during(start, Nuke.Arrive, Nuke.Over, function(a)
			setVisible(bomber, math.min(a * 2.5, 1))
			bomberAt(from:Lerp(over, a))
		end)
		during(start, Nuke.Over, Nuke.Leave, function(a)
			bomberAt(over:Lerp(away, a))
			setVisible(bomber, 1 - math.max(a - 0.6, 0) / 0.4)
		end)
		if drone then
			drone:Stop()
		end
		bomber:Destroy()
	end)

	-- the drop
	waitUntil(start, Nuke.Over)
	local nuke = makeNuke(folder)
	local top = over - Vector3.new(0, 8, 0)
	nuke:PivotTo(CFrame.new(top))
	local body = nuke:FindFirstChild("Body") :: BasePart?
	if body then
		playFrom(body, Sounds.BombFall, 3, false)
	end
	during(start, Nuke.Over, Nuke.Impact, function(a)
		local fall = a * a -- faster and faster
		nuke:PivotTo(CFrame.new(top:Lerp(HUB, fall)) * CFrame.Angles(0, a * 6, math.sin(a * 20) * 0.05))
	end)
	nuke:Destroy()
	warning:Destroy()

	-- the impact: a white screen for everyone
	local white = Instance.new("Frame")
	white.Size = UDim2.fromScale(1, 1)
	white.BackgroundColor3 = Color3.new(1, 1, 1)
	white.BackgroundTransparency = 1
	white.BorderSizePixel = 0
	white.Parent = gui
	TweenService:Create(white, TweenInfo.new(0.12), { BackgroundTransparency = 0 }):Play()
	playFor(Sounds.Boom, 1, 6, 0.75)
	playFor(Sounds.Boom, 0.8, 6, 0.5)
	Effects.shake(2, 2.5)
	blast(folder)
	-- the rumble rolls on: a second boom and shake as the shockwave passes
	task.delay(0.7, function()
		playFor(Sounds.Boom, 0.9, 6, 0.4)
		Effects.shake(1.4, 2)
	end)
	task.wait(0.12 + Nuke.WhiteHold)
	TweenService:Create(white, TweenInfo.new(Nuke.WhiteFade, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { BackgroundTransparency = 1 }):Play()
	task.wait(Nuke.WhiteFade)
	gui:Destroy()
	task.wait(8)
	folder:Destroy()
end

Remotes.Event("Nuke").OnClientEvent:Connect(function(action: string, buyer: string, start: number)
	if action == "Launch" then
		task.spawn(play, buyer, start)
	end
end)
