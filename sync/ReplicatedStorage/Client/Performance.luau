--[[
	Performance
	The Low Performance setting, for weaker devices (a button on the HUD; it's saved with
	the player's data: DataManager's Settings.LowGraphics, mirrored to the
	"Setting_LowGraphics" attribute). It changes nothing for anyone else.

	When it's on (StarterPlayerScripts/LowGraphics applies most of it):
	  * no shadows, bloom or sun rays,
	  * the world's decorative particles and lights are off,
	  * the hub's small decor (MapBuilder tags it "Detail": tulip fields, flowers, reeds,
	    rocks...) is hidden,
	  * the world's moving decor holds still (Atmosphere),
	  * effects use fewer particles (Effects) and builds just appear (DropIn).
	Client only.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))

local ATTRIBUTE = "Setting_LowGraphics"

local player = Players.LocalPlayer
local changed = Instance.new("BindableEvent")

local Performance = {
	Low = player:GetAttribute(ATTRIBUTE) == true,
	Changed = changed.Event, -- fires (low: boolean) when it's switched
}

local function apply(low: boolean)
	if Performance.Low ~= low then
		Performance.Low = low
		changed:Fire(low)
	end
end

-- The saved value arrives once the player's data has loaded (or after a change).
player:GetAttributeChangedSignal(ATTRIBUTE):Connect(function()
	apply(player:GetAttribute(ATTRIBUTE) == true)
end)

-- Switches it (at once on this client) and saves it.
function Performance.Set(low: boolean)
	apply(low)
	Remotes.Event("SetSetting"):FireServer("LowGraphics", low)
end

-- How many of `count` particles an effect should emit.
function Performance.Particles(count: number): number
	if Performance.Low then
		return math.max(1, math.floor(count * 0.4))
	end
	return count
end

return Performance
