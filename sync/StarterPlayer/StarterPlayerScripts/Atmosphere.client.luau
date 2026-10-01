--[[
	Atmosphere
	The look and sound of the world (GDD §1, §13): a bright, warm, candy-colored
	afternoon under a dreamy anime skybox (Creator Store), with bloom (so every Neon part
	glows), punchy color grading, a soft pastel haze, and cheerful background music on
	shuffle with a mute button. In the hub (MapBuilder), the statues turn slowly, the
	balloons bob and the water's cartoon texture drifts; on the factories
	(FactoryBuilder), pinwheels, donuts and lollipops spin, balloons bob and marquee
	bulbs chase. Client only.
]]

local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Sounds = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("Sounds"))
local Client = ReplicatedStorage:WaitForChild("Client")
local Effects = require(Client:WaitForChild("Effects"))
local Kit = require(Client:WaitForChild("UI"):WaitForChild("Kit"))

local MUSIC_VOLUME = 0.3
local STATUE_SPIN = 0.25 -- radians per second
local SPIN_DISTANCE = 300 -- only statues this close to the camera turn
-- "☁️ Cartoon Skybox Clouds Blue Fantasy Dreamy" (Creator Store 77395315546773)
local SKYBOX = {
	SkyboxBk = "rbxassetid://13107325341",
	SkyboxDn = "rbxassetid://13107329809",
	SkyboxFt = "rbxassetid://13107334845",
	SkyboxLf = "rbxassetid://13107337703",
	SkyboxRt = "rbxassetid://13107340396",
	SkyboxUp = "rbxassetid://13107344387",
}

-- Lighting -------------------------------------------------------------------

local function effect(className: string, props: { [string]: any }): Instance
	local instance = Lighting:FindFirstChildOfClass(className)
	if not instance then
		instance = Instance.new(className)
		instance.Parent = Lighting
	end
	for key, value in props do
		(instance :: any)[key] = value
	end
	return instance
end

Lighting.ClockTime = 14.5
Lighting.Brightness = 2.4
Lighting.Ambient = Color3.fromRGB(120, 105, 140)
Lighting.OutdoorAmbient = Color3.fromRGB(150, 135, 170)
Lighting.ColorShift_Top = Color3.fromRGB(255, 235, 215)
Lighting.ExposureCompensation = 0.05
Lighting.EnvironmentDiffuseScale = 0.7
Lighting.EnvironmentSpecularScale = 0.5
Lighting.ShadowSoftness = 0.5
Lighting.GeographicLatitude = 30

effect("BloomEffect", { Intensity = 0.6, Size = 24, Threshold = 1.9 })
effect("ColorCorrectionEffect", {
	Saturation = 0.25,
	Contrast = 0.1,
	Brightness = 0.02,
	TintColor = Color3.fromRGB(255, 250, 252),
})
effect("SunRaysEffect", { Intensity = 0.05, Spread = 0.7 })
effect("Atmosphere", {
	Density = 0.16,
	Offset = 0.2,
	Color = Color3.fromRGB(210, 228, 255), -- the skybox's horizon
	Decay = Color3.fromRGB(255, 210, 235),
	Glare = 0,
	Haze = 0.15,
})
effect("Sky", SKYBOX)
local sky = Lighting:FindFirstChildOfClass("Sky") :: Sky
sky.CelestialBodiesShown = false -- the skybox paints its own light
local depth = Lighting:FindFirstChildOfClass("DepthOfFieldEffect")
if depth then
	depth.Enabled = false
end
local clouds = workspace.Terrain:FindFirstChildOfClass("Clouds")
if clouds then
	clouds.Enabled = false -- the skybox has its own clouds
end

-- The hub: statues, balloons, water -------------------------------------------------

-- The giant statue in the fountain and every showcase statue turn slowly (the ones near
-- the camera, anyway).
local spinning: { [Model]: CFrame } = {} -- statue → its resting pivot
local function spin(statue: Instance)
	if statue:IsA("Model") then
		spinning[statue] = statue:GetPivot()
	end
end
for _, statue in CollectionService:GetTagged("SpinningStatue") do
	spin(statue)
end
CollectionService:GetInstanceAddedSignal("SpinningStatue"):Connect(spin)
CollectionService:GetInstanceRemovedSignal("SpinningStatue"):Connect(function(statue)
	spinning[statue :: Model] = nil
end)
task.spawn(function()
	spin(workspace:WaitForChild("Hub"):WaitForChild("Statue"))
end)
RunService.RenderStepped:Connect(function()
	local camera = workspace.CurrentCamera.CFrame.Position
	local turn = CFrame.Angles(0, os.clock() * STATUE_SPIN, 0)
	for statue, rest in spinning do
		if (rest.Position - camera).Magnitude < SPIN_DISTANCE then
			statue:PivotTo(rest * turn)
		end
	end
end)

-- The cartoon texture on the river and streams drifts along with the flow, each layer
-- at its own speed, from where its stretch sits along the flow (MapBuilder.waterSkin).
local flowing: { [Texture]: { Base: number, Drift: number } } = {}
local function flow(texture: Instance)
	if texture:IsA("Texture") then
		local base, drift = texture:GetAttribute("Base"), texture:GetAttribute("Drift")
		flowing[texture] = {
			Base = if typeof(base) == "number" then base else 0,
			Drift = if typeof(drift) == "number" then drift else 1,
		}
	end
end
for _, texture in CollectionService:GetTagged("FlowingWater") do
	flow(texture)
end
CollectionService:GetInstanceAddedSignal("FlowingWater"):Connect(flow)
CollectionService:GetInstanceRemovedSignal("FlowingWater"):Connect(function(texture)
	flowing[texture :: Texture] = nil
end)
RunService.RenderStepped:Connect(function()
	local now = os.clock()
	for texture, layer in flowing do
		-- a falling offset slides the texture toward -Z, downstream
		texture.OffsetStudsV = (layer.Base - now * layer.Drift) % texture.StudsPerTileV
	end
end)

-- Each balloon (and its string) bobs gently on its own rhythm.
task.spawn(function()
	local folder = workspace:WaitForChild("Hub"):WaitForChild("Balloons")
	local parts: { BasePart } = {}
	local rests: { CFrame } = {}
	local phases: { number } = {}
	local function track(part: Instance)
		if part:IsA("BasePart") then
			table.insert(parts, part)
			table.insert(rests, part.CFrame)
			-- a balloon and its string share a phase (they sit at the same X/Z)
			table.insert(phases, (part.Position.X * 0.37 + part.Position.Z * 0.61) % (math.pi * 2))
		end
	end
	for _, part in folder:GetChildren() do
		track(part)
	end
	folder.ChildAdded:Connect(track)
	RunService.RenderStepped:Connect(function()
		local now = os.clock()
		for index, part in parts do
			local phase = phases[index]
			part.CFrame = rests[index] + Vector3.new(0, math.sin(now * 1.3 + phase) * 1.2, 0)
		end
	end)
end)

-- The factories' moving bits (FactoryBuilder) ------------------------------------------

-- Pinwheels, donuts and lollipops (Models tagged "Spinner") turn about their pivot's Z
-- axis at their Speed, balloon bunches ("Bobbing") bob, and marquee bulbs ("Marquee")
-- chase candy-colored lights along their Index. Only the ones near the camera move.
local DECOR_DISTANCE = 450
local MARQUEE_STEP = 0.16 -- seconds per chase step
local MARQUEE_COLORS = {
	Color3.fromRGB(255, 120, 190),
	Color3.fromRGB(255, 225, 90),
	Color3.fromRGB(110, 235, 170),
	Color3.fromRGB(110, 200, 255),
	Color3.fromRGB(200, 150, 255),
}
local BULB_OFF = Color3.fromRGB(255, 215, 130)

type Mover = { Rest: CFrame, Speed: number, Phase: number }
local spinners: { [Model]: Mover } = {}
local bobbers: { [Model]: Mover } = {}
local bulbs: { [BasePart]: number } = {} -- bulb → its index along its string

local function watchTag(tag: string, added: (Instance) -> (), removed: (Instance) -> ())
	for _, instance in CollectionService:GetTagged(tag) do
		added(instance)
	end
	CollectionService:GetInstanceAddedSignal(tag):Connect(added)
	CollectionService:GetInstanceRemovedSignal(tag):Connect(removed)
end

watchTag("Spinner", function(model)
	if model:IsA("Model") then
		local speed = model:GetAttribute("Speed")
		spinners[model] = { Rest = model:GetPivot(), Speed = if typeof(speed) == "number" then speed else 1, Phase = 0 }
	end
end, function(model)
	spinners[model :: Model] = nil
end)
watchTag("Bobbing", function(model)
	if model:IsA("Model") then
		local rest = model:GetPivot()
		bobbers[model] = { Rest = rest, Speed = 1.3, Phase = (rest.X * 0.37 + rest.Z * 0.61) % (math.pi * 2) }
	end
end, function(model)
	bobbers[model :: Model] = nil
end)
watchTag("Marquee", function(bulb)
	if bulb:IsA("BasePart") then
		local index = bulb:GetAttribute("Index")
		bulbs[bulb] = if typeof(index) == "number" then index else 0
	end
end, function(bulb)
	bulbs[bulb :: BasePart] = nil
end)

local marqueeStep = -1
RunService.RenderStepped:Connect(function()
	local now = os.clock()
	local camera = workspace.CurrentCamera.CFrame.Position
	for model, mover in spinners do
		if (mover.Rest.Position - camera).Magnitude < DECOR_DISTANCE then
			model:PivotTo(mover.Rest * CFrame.Angles(0, 0, now * mover.Speed))
		end
	end
	for model, mover in bobbers do
		if (mover.Rest.Position - camera).Magnitude < DECOR_DISTANCE then
			model:PivotTo(mover.Rest + Vector3.new(0, math.sin(now * mover.Speed + mover.Phase) * 0.8, 0))
		end
	end
	-- every third bulb lit, each light keeping its color as it runs along the string
	local step = math.floor(now / MARQUEE_STEP)
	if step ~= marqueeStep then
		marqueeStep = step
		for bulb, index in bulbs do
			if (bulb.Position - camera).Magnitude < DECOR_DISTANCE then
				local offset = index - step
				if offset % 3 == 0 then
					bulb.Material = Enum.Material.Neon
					bulb.Color = MARQUEE_COLORS[(offset // 3) % #MARQUEE_COLORS + 1]
				else
					bulb.Material = Enum.Material.SmoothPlastic
					bulb.Color = BULB_OFF
				end
			end
		end
	end
end)

-- Music ----------------------------------------------------------------------

local music = Instance.new("Sound")
music.Name = "Music"
music.SoundGroup = Effects.MusicGroup
music.Parent = Effects.MusicGroup

local muted = false
local order: { string } = {}

local function nextTrack(): string
	if #order == 0 then
		order = table.clone(Sounds.Music)
		for index = #order, 2, -1 do
			local swap = math.random(1, index)
			order[index], order[swap] = order[swap], order[index]
		end
	end
	return table.remove(order) :: string
end

local function play()
	music.SoundId = nextTrack()
	music.TimePosition = 0
	music.Volume = MUSIC_VOLUME
	music:Play()
end

music.Ended:Connect(play)
task.spawn(play)

-- The mute button, top right.
local gui = Kit.getGui()
local icon: TextLabel
local button = Kit.button({
	Name = "MusicToggle",
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -24, 0, 84),
	Size = UDim2.fromOffset(64, 64),
	Parent = gui,
}, Kit.Colors.Purple, nil, function()
	muted = not muted
	Effects.MusicGroup.Volume = if muted then 0 else 1
	icon.Text = if muted then "🔇" else "🎵"
end)
icon = Kit.text({
	Text = "🎵",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromScale(0.7, 0.7),
	StrokeThickness = 0,
	Parent = button,
})
