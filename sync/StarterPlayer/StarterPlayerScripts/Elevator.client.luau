--[[
	Elevator
	Rides the factories' lifts (FactoryBuilder's elevator: one per storey, stacked in the
	front room's lobby). Each lift's call panel (tagged "ElevatorCall") gets a prompt per
	way it goes (its Up / Down attributes: where it arrives, facing out of that lift's
	door). A ride: the doors fold shut, the screen fades, you're taken to the other lift,
	and its doors fold open as the screen clears. Doors move on this client only. A
	1-storey factory's lift has no panel tag: it waits shut until the Clay Studio brings
	the 2nd floor. Client only.
]]

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Sounds = require(Shared:WaitForChild("Config"):WaitForChild("Sounds"))
local Client = ReplicatedStorage:WaitForChild("Client")
local Effects = require(Client:WaitForChild("Effects"))
local Kit = require(Client:WaitForChild("UI"):WaitForChild("Kit"))

local DOOR_TIME = 0.35
local FADE_TIME = 0.25
local LIFT_REACH = 12 -- studs from a call panel to its own doors
local FADE_COLOR = Color3.fromRGB(255, 245, 225)

local player = Players.LocalPlayer
local riding = false

-- The doors in `building` of the lift whose call panel (or arrival spot) is at `near`.
local function doorsNear(building: Instance, near: Vector3): { BasePart }
	local doors = {}
	for _, part in building:GetDescendants() do
		if part.Name == "LiftDoor" and part:IsA("BasePart") and (part.Position - near).Magnitude < LIFT_REACH then
			table.insert(doors, part)
		end
	end
	return doors
end

-- Folds the doors shut (or open), over `time` seconds (at once with 0).
local function setDoors(doors: { BasePart }, shut: boolean, time: number)
	for _, door in doors do
		local size = door:GetAttribute(if shut then "ClosedSize" else "OpenSize")
		local cframe = door:GetAttribute(if shut then "ClosedCFrame" else "OpenCFrame")
		if typeof(size) == "Vector3" and typeof(cframe) == "CFrame" then
			if time > 0 then
				TweenService:Create(door, TweenInfo.new(time, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), { Size = size, CFrame = cframe }):Play()
			else
				door.Size, door.CFrame = size, cframe
			end
		end
	end
end

-- A full-screen fade, in (to opaque) or out.
local function fade(cover: Frame, opaque: boolean)
	TweenService:Create(cover, TweenInfo.new(FADE_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), { BackgroundTransparency = if opaque then 0 else 1 }):Play()
	task.wait(FADE_TIME)
end

local function ride(panel: BasePart, to: CFrame)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if riding or not (character and root) then
		return
	end
	riding = true
	local building = panel:FindFirstAncestor("Building") or workspace
	local here = doorsNear(building, panel.Position)
	Effects.sound(panel.Position, Sounds.Servo, 0.3, 1.2)
	setDoors(here, true, DOOR_TIME)
	task.wait(DOOR_TIME)

	local cover = Kit.new("Frame", {
		Name = "ElevatorFade",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = FADE_COLOR,
		BackgroundTransparency = 1,
		ZIndex = 60,
		Parent = Kit.getGui(),
	})
	Effects.sound2D(Sounds.Whoosh, 0.25, 0.9)
	fade(cover, true)
	-- (held still while the floor there streams in)
	root.Anchored = true
	pcall(player.RequestStreamAroundAsync, player, to.Position, 2)
	character:PivotTo(to)
	local there = doorsNear(building, to.Position)
	setDoors(there, true, 0)
	setDoors(here, false, 0)
	task.wait(0.1)
	root.Anchored = false
	Effects.sound2D(Sounds.Coin, 0.4, 1.6) -- ding!
	task.spawn(fade, cover, false)
	setDoors(there, false, DOOR_TIME)
	task.wait(FADE_TIME)
	cover:Destroy()
	riding = false
end

-- A prompt for one way a lift goes.
local function addPrompt(panel: BasePart, attribute: string, text: string, key: Enum.KeyCode)
	local to = panel:GetAttribute(attribute)
	if typeof(to) ~= "CFrame" then
		return
	end
	local prompt = Kit.new("ProximityPrompt", {
		Name = `Lift{attribute}`,
		ActionText = text,
		ObjectText = "Elevator",
		KeyboardKeyCode = key,
		HoldDuration = 0,
		MaxActivationDistance = 9,
		RequiresLineOfSight = false,
		Parent = panel,
	})
	prompt.Triggered:Connect(function()
		ride(panel, to)
	end)
end

local function watch(panel: Instance)
	if not panel:IsA("BasePart") or panel:FindFirstChildOfClass("ProximityPrompt") then
		return
	end
	local both = panel:GetAttribute("Up") ~= nil and panel:GetAttribute("Down") ~= nil
	addPrompt(panel, "Up", "Go up ⬆️", Enum.KeyCode.E)
	addPrompt(panel, "Down", "Go down ⬇️", if both then Enum.KeyCode.F else Enum.KeyCode.E)
end

for _, panel in CollectionService:GetTagged("ElevatorCall") do
	watch(panel)
end
CollectionService:GetInstanceAddedSignal("ElevatorCall"):Connect(watch)
