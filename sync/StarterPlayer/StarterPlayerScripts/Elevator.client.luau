--[[
	Elevator
	Rides the factories' lifts (FactoryBuilder's elevator: one per storey, stacked in the
	front room's lobby). Each lift's call panel (tagged "ElevatorCall") gets a prompt per
	way it goes (its Up / Down attributes: where it arrives, facing out of that lift's
	door), shown in the middle of the cabin and only while you stand inside it (its Cabin
	attribute). A ride: you stop where you are (anchored, controls off), the doors fold
	shut, the screen fades, you're taken to the other lift, and its doors fold open as
	the screen clears. Doors move on this client only. A
	1-storey factory's lift has no panel tag: it waits shut until the Clay Studio brings
	the 2nd floor. Client only.
]]

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
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
local INSIDE_CHECK = 0.15 -- seconds between checks of who's inside which cabin
local CABIN_HEIGHT = 9 -- studs over its floor that count as inside

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

-- The player's movement controls (the default PlayerModule's), to switch off for a ride.
-- This place has no PlayerModule in PlayerScripts (waiting for one hung every ride:
-- the lift never moved and its prompts stayed off); the anchored root holds you still.
local function setControls(on: boolean)
	local scripts = player:FindFirstChild("PlayerScripts")
	local playerModule = scripts and scripts:FindFirstChild("PlayerModule")
	if not (playerModule and playerModule:IsA("ModuleScript")) then
		return
	end
	pcall(function()
		local module = require(playerModule :: any)
		local controls = module:GetControls()
		if on then
			controls:Enable()
		else
			controls:Disable()
		end
	end)
end

local function ride(panel: BasePart, to: CFrame)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if riding or not (character and root) then
		return
	end
	riding = true
	-- you stop right where you are for the whole ride
	setControls(false)
	root.AssemblyLinearVelocity = Vector3.zero
	root.Anchored = true
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
	-- (still held while the floor there streams in)
	pcall(player.RequestStreamAroundAsync, player, to.Position, 2)
	character:PivotTo(to)
	local there = doorsNear(building, to.Position)
	setDoors(there, true, 0)
	setDoors(here, false, 0)
	task.wait(0.1)
	Effects.sound2D(Sounds.Coin, 0.4, 1.6) -- ding!
	task.spawn(fade, cover, false)
	setDoors(there, false, DOOR_TIME)
	task.wait(math.max(FADE_TIME, DOOR_TIME))
	cover:Destroy()
	if root.Parent then
		root.Anchored = false
	end
	setControls(true)
	riding = false
end

-- Each lift's prompts, with its cabin, for the inside check.
type Lift = { Cabin: CFrame, Half: number, Prompts: { ProximityPrompt } }
local lifts: { [BasePart]: Lift } = {}

-- A prompt for one way a lift goes (on `spot`: an attachment in the cabin's middle).
local function addPrompt(panel: BasePart, spot: Attachment, attribute: string, text: string, key: Enum.KeyCode): ProximityPrompt?
	local to = panel:GetAttribute(attribute)
	if typeof(to) ~= "CFrame" then
		return nil
	end
	local prompt = Kit.new("ProximityPrompt", {
		Name = `Lift{attribute}`,
		ActionText = text,
		ObjectText = "Elevator",
		KeyboardKeyCode = key,
		HoldDuration = 0,
		MaxActivationDistance = 8,
		RequiresLineOfSight = false,
		Enabled = false, -- (on while you're inside: see below)
		Parent = spot,
	})
	prompt.Triggered:Connect(function()
		ride(panel, to)
	end)
	return prompt
end

local function watch(panel: Instance)
	local cabin, half = panel:GetAttribute("Cabin"), panel:GetAttribute("CabinHalf")
	if not panel:IsA("BasePart") or lifts[panel] or typeof(cabin) ~= "CFrame" or typeof(half) ~= "number" then
		return
	end
	local spot = Instance.new("Attachment")
	spot.Name = "LiftPromptSpot"
	spot.Parent = panel
	spot.WorldPosition = (cabin * CFrame.new(0, 3, 0)).Position
	local both = panel:GetAttribute("Up") ~= nil and panel:GetAttribute("Down") ~= nil
	local prompts = {}
	for _, prompt in {
		addPrompt(panel, spot, "Up", "Go up ⬆️", Enum.KeyCode.E),
		addPrompt(panel, spot, "Down", "Go down ⬇️", if both then Enum.KeyCode.F else Enum.KeyCode.E),
	} do
		table.insert(prompts, prompt)
	end
	lifts[panel] = { Cabin = cabin, Half = half, Prompts = prompts }
end

for _, panel in CollectionService:GetTagged("ElevatorCall") do
	watch(panel)
end
CollectionService:GetInstanceAddedSignal("ElevatorCall"):Connect(watch)
CollectionService:GetInstanceRemovedSignal("ElevatorCall"):Connect(function(panel)
	lifts[panel :: BasePart] = nil
end)

-- A lift's prompts are on only while you stand inside its cabin.
local elapsed = 0
RunService.Heartbeat:Connect(function(dt)
	elapsed += dt
	if elapsed < INSIDE_CHECK then
		return
	end
	elapsed = 0
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	for _, lift in lifts do
		local inside = false
		if root and not riding then
			local at = lift.Cabin:PointToObjectSpace(root.Position)
			inside = math.abs(at.X) <= lift.Half and math.abs(at.Z) <= lift.Half and at.Y > 0 and at.Y < CABIN_HEIGHT
		end
		for _, prompt in lift.Prompts do
			prompt.Enabled = inside
		end
	end
end)
