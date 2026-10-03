--[[
	Effects
	World-space juice shared by the client scripts (GDD §13): positional sounds,
	sparkles, puffs, confetti, shockwave rings, light flashes, floating text and flying
	coins. Everything is cosmetic, lives in workspace.Effects (on this client only) and
	cleans itself up. Client only.
]]

local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local SPARKLE_TEXTURE = "rbxasset://textures/particles/sparkles_main.dds"
local PUFF_TEXTURE = "rbxasset://textures/particles/smoke_main.dds"
local SOUND_RANGE = 110 -- studs from the camera; farther sounds aren't played at all
local COIN_COLOR = Color3.fromRGB(255, 205, 40)
local CONFETTI_COLORS = {
	Color3.fromRGB(255, 90, 150),
	Color3.fromRGB(255, 210, 60),
	Color3.fromRGB(90, 220, 255),
	Color3.fromRGB(130, 240, 110),
	Color3.fromRGB(190, 120, 255),
}

local Effects = {}

local folder = workspace:FindFirstChild("Effects") or Instance.new("Folder")
folder.Name = "Effects"
folder.Parent = workspace
Effects.Folder = folder

local function soundGroup(name: string, volume: number): SoundGroup
	local group = SoundService:FindFirstChild(name)
	if not (group and group:IsA("SoundGroup")) then
		group = Instance.new("SoundGroup")
		group.Name = name
		group.Volume = volume
		group.Parent = SoundService
	end
	return group :: SoundGroup
end

Effects.SfxGroup = soundGroup("SFX", 1)
Effects.MusicGroup = soundGroup("Music", 1)

-- Whether a point is close enough to the camera to bother with effects.
function Effects.near(position: Vector3, range: number): boolean
	local camera = workspace.CurrentCamera
	return camera ~= nil and (camera.CFrame.Position - position).Magnitude <= range
end

-- An invisible part for effects to hang off. It cleans itself up after `lifetime`.
function Effects.anchor(position: Vector3, lifetime: number): Part
	local anchor = Instance.new("Part")
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.Transparency = 1
	anchor.Size = Vector3.new(0.2, 0.2, 0.2)
	anchor.Position = position
	anchor.Parent = folder
	Debris:AddItem(anchor, lifetime)
	return anchor
end

-- A 3D sound at `position`, skipped when it's out of earshot. Returns the Sound so a
-- long one can be stopped early.
function Effects.sound(position: Vector3, soundId: string, volume: number, speed: number?): Sound?
	if not Effects.near(position, SOUND_RANGE) then
		return nil
	end
	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Volume = volume
	sound.PlaybackSpeed = speed or 1
	sound.RollOffMode = Enum.RollOffMode.InverseTapered
	sound.RollOffMinDistance = 14
	sound.RollOffMaxDistance = SOUND_RANGE
	sound.SoundGroup = Effects.SfxGroup
	sound.Parent = Effects.anchor(position, 4)
	sound:Play()
	return sound
end

-- A flat (non-3D) sound, for things that happen to you.
function Effects.sound2D(soundId: string, volume: number, speed: number?)
	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Volume = volume
	sound.PlaybackSpeed = speed or 1
	sound.SoundGroup = Effects.SfxGroup
	sound.Parent = SoundService
	SoundService:PlayLocalSound(sound)
	task.delay(6, function()
		sound:Destroy()
	end)
end

local function emitter(props: { [string]: any }): ParticleEmitter
	local particles = Instance.new("ParticleEmitter")
	particles.Enabled = false
	particles.Rotation = NumberRange.new(0, 360)
	for key, value in props do
		(particles :: any)[key] = value
	end
	return particles
end

-- A burst of twinkly sparkles.
function Effects.sparkle(position: Vector3, color: Color3, count: number, speed: number?)
	local fast = speed or 14
	local particles = emitter({
		Texture = SPARKLE_TEXTURE,
		Color = ColorSequence.new(color),
		LightEmission = 0.8,
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(0.2, 1), NumberSequenceKeypoint.new(1, 0) }),
		Lifetime = NumberRange.new(0.4, 0.8),
		Speed = NumberRange.new(fast * 0.7, fast * 1.3),
		SpreadAngle = Vector2.new(180, 180),
		Acceleration = Vector3.new(0, -30, 0),
		Drag = 2,
		RotSpeed = NumberRange.new(-180, 180),
	})
	particles.Parent = Effects.anchor(position, 1.5)
	particles:Emit(count)
end

-- Soft clouds (dust, stuffing, paint mist).
function Effects.puff(position: Vector3, color: Color3, count: number, size: number?)
	local scale = size or 1
	local particles = emitter({
		Texture = PUFF_TEXTURE,
		Color = ColorSequence.new(color),
		Size = NumberSequence.new(1.2 * scale, 2.8 * scale),
		Transparency = NumberSequence.new(0.1, 1),
		Lifetime = NumberRange.new(0.5, 0.8),
		Speed = NumberRange.new(4 * scale, 8 * scale),
		SpreadAngle = Vector2.new(180, 180),
		Drag = 4,
	})
	particles.Parent = Effects.anchor(position, 1.5)
	particles:Emit(count)
end

-- A jet shot from `from` at `to` over a quarter second: paint, dye, glaze (soft
-- clouds), or glitter and gold (`sparkly`).
function Effects.spray(from: Vector3, to: Vector3, color: Color3, count: number, size: number?, sparkly: boolean?)
	local scale = size or 1
	local lifetime = 0.3
	local distance = (to - from).Magnitude
	local particles = emitter({
		Texture = if sparkly then SPARKLE_TEXTURE else PUFF_TEXTURE,
		Color = ColorSequence.new(color),
		LightEmission = if sparkly then 0.8 else 0.15,
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35 * scale), NumberSequenceKeypoint.new(1, 1.5 * scale) }),
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.05), NumberSequenceKeypoint.new(0.75, 0.25), NumberSequenceKeypoint.new(1, 1) }),
		Lifetime = NumberRange.new(lifetime * 0.9, lifetime * 1.1),
		Speed = NumberRange.new(distance / lifetime * 0.85, distance / lifetime * 1.05),
		SpreadAngle = Vector2.new(8, 8),
		EmissionDirection = Enum.NormalId.Front,
		Rate = count * 4,
	})
	local anchor = Effects.anchor(from, 1.2)
	anchor.CFrame = CFrame.lookAt(from, to) -- Front (-Z) toward `to`
	particles.Parent = anchor
	particles.Enabled = true
	task.delay(0.25, function()
		particles.Enabled = false
	end)
end

-- Colorful confetti that pops up and flutters down.
function Effects.confetti(position: Vector3, count: number)
	local anchor = Effects.anchor(position, 3)
	for _, color in CONFETTI_COLORS do
		local particles = emitter({
			Texture = SPARKLE_TEXTURE,
			Color = ColorSequence.new(color),
			LightEmission = 0.4,
			Size = NumberSequence.new(0.6, 0.4),
			Lifetime = NumberRange.new(1.2, 2),
			Speed = NumberRange.new(18, 30),
			SpreadAngle = Vector2.new(40, 40),
			EmissionDirection = Enum.NormalId.Top,
			Acceleration = Vector3.new(0, -28, 0),
			Drag = 1.5,
			RotSpeed = NumberRange.new(-360, 360),
		})
		particles.Parent = anchor
		particles:Emit(math.ceil(count / #CONFETTI_COLORS))
	end
end

-- A flat glowing ring that grows and fades, like a shockwave on the floor.
function Effects.ring(position: Vector3, color: Color3, radius: number, duration: number?)
	local time = duration or 0.45
	local ring = Instance.new("Part")
	ring.Shape = Enum.PartType.Cylinder
	ring.Anchored = true
	ring.CanCollide = false
	ring.CanQuery = false
	ring.CanTouch = false
	ring.Material = Enum.Material.Neon
	ring.Color = color
	ring.Transparency = 0.25
	ring.Size = Vector3.new(0.15, radius * 0.4, radius * 0.4)
	ring.CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.pi / 2)
	ring.Parent = folder
	local info = TweenInfo.new(time, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(ring, info, { Size = Vector3.new(0.15, radius * 2, radius * 2), Transparency = 1 }):Play()
	Debris:AddItem(ring, time + 0.05)
end

-- A quick point light that fades out.
function Effects.flash(position: Vector3, color: Color3, brightness: number, range: number, duration: number?)
	local time = duration or 0.35
	local light = Instance.new("PointLight")
	light.Color = color
	light.Brightness = brightness
	light.Range = range
	light.Shadows = false
	light.Parent = Effects.anchor(position, time + 0.1)
	TweenService:Create(light, TweenInfo.new(time, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Brightness = 0 }):Play()
end

-- Tints a whole model for a moment (a paint splash, a glitter shine).
function Effects.tint(model: Instance, color: Color3, duration: number?)
	local time = duration or 0.5
	local highlight = Instance.new("Highlight")
	highlight.FillColor = color
	highlight.FillTransparency = 0.15
	highlight.OutlineColor = Color3.new(1, 1, 1)
	highlight.OutlineTransparency = 0.3
	highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	highlight.Parent = model
	local info = TweenInfo.new(time, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	TweenService:Create(highlight, info, { FillTransparency = 1, OutlineTransparency = 1 }):Play()
	Debris:AddItem(highlight, time + 0.05)
end

-- Floating text that pops in, rises and fades. `height` is in studs.
function Effects.popup(position: Vector3, text: string, color: Color3, height: number, duration: number?)
	local lifetime = duration or 1.2
	local anchor = Effects.anchor(position, lifetime + 0.1)

	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromScale(height * 5, height)
	gui.AlwaysOnTop = true
	gui.LightInfluence = 0
	gui.MaxDistance = 150
	gui.Parent = anchor

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = color
	label.Text = text
	label.Parent = gui

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 3
	stroke.Color = Color3.fromRGB(30, 25, 45)
	stroke.Parent = label

	local scale = Instance.new("UIScale")
	scale.Scale = 0.3
	scale.Parent = label
	TweenService:Create(scale, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()

	local rise = TweenInfo.new(lifetime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local fade = TweenInfo.new(lifetime * 0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, lifetime * 0.6)
	TweenService:Create(anchor, rise, { Position = position + Vector3.new(0, 5, 0) }):Play()
	TweenService:Create(label, fade, { TextTransparency = 1 }):Play()
	TweenService:Create(stroke, fade, { Transparency = 1 }):Play()
end

-- The camera shakes for `seconds`, `strength` studs at first, dying down. Shakes can
-- overlap (each has its own render step).
local shakes = 0
function Effects.shake(seconds: number, strength: number)
	local camera = workspace.CurrentCamera
	local started = os.clock()
	shakes += 1
	local name = `EffectsShake{shakes}`
	RunService:BindToRenderStep(name, Enum.RenderPriority.Camera.Value + 1, function()
		local t = os.clock() - started
		if t > seconds then
			RunService:UnbindFromRenderStep(name)
			return
		end
		local power = strength * (1 - t / seconds)
		camera.CFrame *= CFrame.new(math.random(-100, 100) / 100 * power, math.random(-100, 100) / 100 * power, 0)
	end)
end

-- A spinning gold coin, for flying and piling up.
function Effects.makeCoin(size: number?): Part
	local diameter = size or 1
	local coin = Instance.new("Part")
	coin.Name = "Coin"
	coin.Shape = Enum.PartType.Cylinder
	coin.Anchored = true
	coin.CanCollide = false
	coin.CanQuery = false
	coin.CanTouch = false
	coin.Material = Enum.Material.Neon
	coin.Color = COIN_COLOR
	coin.Size = Vector3.new(diameter * 0.22, diameter, diameter)
	return coin
end

-- Coins that hop out of `from` and arc over to `to`, one after another. Calls
-- `onLand` (if given) as each one arrives.
function Effects.coins(from: Vector3, to: Vector3, count: number, onLand: (() -> ())?)
	for index = 1, count do
		task.delay((index - 1) * 0.06, function()
			local coin = Effects.makeCoin(0.9)
			coin.Parent = folder
			local spread = Vector3.new(math.random() - 0.5, 0, math.random() - 0.5) * 2.5
			local target = to + spread
			local height = 6 + math.random() * 4
			local duration = 0.55 + math.random() * 0.2
			local spin = math.random() * math.pi * 2
			local start = os.clock()
			local connection: RBXScriptConnection
			connection = RunService.Heartbeat:Connect(function()
				local alpha = math.min((os.clock() - start) / duration, 1)
				local position = from:Lerp(target, alpha) + Vector3.new(0, height * 4 * alpha * (1 - alpha), 0)
				coin.CFrame = CFrame.new(position) * CFrame.Angles(0, spin + alpha * 12, math.pi / 2 + alpha * 3)
				if alpha >= 1 then
					connection:Disconnect()
					coin:Destroy()
					if onLand then
						onLand()
					end
				end
			end)
		end)
	end
end

return Effects
