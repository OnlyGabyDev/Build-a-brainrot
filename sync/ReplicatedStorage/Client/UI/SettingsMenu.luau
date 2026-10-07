--[[
	Settings Menu
	The gear panel (teal): a row per setting, each with an ON/OFF switch (Kit.toggle). Today:
	Lower Graphics (Client/Performance: saved with the player's data, applied by
	StarterPlayerScripts/LowGraphics). New settings are one more entry in SETTINGS.
	Client only.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Performance = require(ReplicatedStorage:WaitForChild("Client"):WaitForChild("Performance"))
local Kit = require(script.Parent:WaitForChild("Kit"))

local SIZE = Vector2.new(620, 300)
local MUTED_COLOR = Color3.fromRGB(110, 105, 130)

type Setting = {
	Icon: string, -- one of ours (Config/Icons)
	Name: string,
	About: string,
	Get: () -> boolean,
	Set: (on: boolean) -> (),
	Changed: RBXScriptSignal?, -- fires when it changes elsewhere
}

local SETTINGS: { Setting } = {
	{
		Icon = "Lightning",
		Name = "Lower Graphics",
		About = "More FPS, fewer effects",
		Get = function()
			return Performance.Low
		end,
		Set = Performance.Set,
		Changed = Performance.Changed,
	},
}

local panel: Frame? = nil

local SettingsMenu = {}

local function build(content: Frame)
	for index, setting in SETTINGS do
		local row = Kit.new("Frame", {
			Position = UDim2.fromOffset(24, 20 + (index - 1) * 96),
			Size = UDim2.new(1, -48, 0, 84),
			BackgroundColor3 = Kit.White,
			Parent = content,
		})
		Kit.corner(row, 18)
		Kit.stroke(row, 3)
		Kit.gradient(row, { Color3.fromRGB(255, 255, 255), Kit.Hues.Teal.Light:Lerp(Kit.White, 0.6) })
		Kit.icon(setting.Icon, { Position = UDim2.fromOffset(10, 10), Size = UDim2.fromOffset(64, 64), Parent = row })
		Kit.text({
			Text = setting.Name,
			Position = UDim2.fromOffset(80, 10),
			Size = UDim2.new(1, -240, 0, 36),
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = row,
		})
		Kit.text({
			Text = setting.About,
			Position = UDim2.fromOffset(82, 48),
			Size = UDim2.new(1, -244, 0, 24),
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = MUTED_COLOR,
			StrokeThickness = 0,
			Parent = row,
		})
		local show = Kit.toggle({
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -16, 0.5, 0),
			Parent = row,
		}, setting.Get(), setting.Set)
		if setting.Changed then
			setting.Changed:Connect(function()
				show(setting.Get())
			end)
		end
	end
end

function SettingsMenu.Open()
	if not panel then
		local newPanel, content = Kit.modal("Settings", "SETTINGS", Kit.Hues.Teal, SIZE, "Gear")
		build(content)
		panel = newPanel
	end
	Kit.open(panel :: Frame)
end

-- The gear button on the HUD (top right, under the music's).
function SettingsMenu.Init()
	Kit.button({
		Name = "SettingsButton",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -24, 0, 156),
		Size = UDim2.fromOffset(64, 64),
		Parent = Kit.getGui(),
	}, Kit.pair(Kit.Hues.Teal), nil, SettingsMenu.Open, "Gear")
end

return SettingsMenu
