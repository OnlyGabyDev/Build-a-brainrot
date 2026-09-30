--[[
	Atmosphere
	The look and sound of the world (GDD §1, §13): a bright, warm, candy-colored
	afternoon with bloom (so every Neon part glows), punchy color grading, a soft
	pastel haze, and cheerful background music on shuffle with a mute button.
	Client only.
]]

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Sounds = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("Sounds"))
local Client = ReplicatedStorage:WaitForChild("Client")
local Effects = require(Client:WaitForChild("Effects"))
local Kit = require(Client:WaitForChild("UI"):WaitForChild("Kit"))

local MUSIC_VOLUME = 0.3

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

Lighting.ClockTime = 14.2
Lighting.Brightness = 2
Lighting.Ambient = Color3.fromRGB(95, 90, 110)
Lighting.OutdoorAmbient = Color3.fromRGB(125, 120, 140)
Lighting.ExposureCompensation = 0
Lighting.EnvironmentDiffuseScale = 0.6
Lighting.EnvironmentSpecularScale = 0.5
Lighting.ShadowSoftness = 0.35
Lighting.GeographicLatitude = 30

effect("BloomEffect", { Intensity = 0.6, Size = 24, Threshold = 1.9 })
effect("ColorCorrectionEffect", {
	Saturation = 0.18,
	Contrast = 0.12,
	Brightness = 0,
	TintColor = Color3.fromRGB(255, 252, 248),
})
effect("SunRaysEffect", { Intensity = 0.06, Spread = 0.7 })
effect("Atmosphere", {
	Density = 0.22,
	Offset = 0.25,
	Color = Color3.fromRGB(215, 205, 255),
	Decay = Color3.fromRGB(255, 190, 225),
	Glare = 0,
	Haze = 0.4,
})
local depth = Lighting:FindFirstChildOfClass("DepthOfFieldEffect")
if depth then
	depth.Enabled = false
end

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
