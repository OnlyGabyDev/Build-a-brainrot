--[[
	Elevator
	Runs the factories' lifts (FactoryBuilder: a glass tower beside each factory's
	entrance, its cabin, counterweight, pulley and cables in the "Lift" model).
	Everything moves on this client only, from the rig's attributes:
	  * the cabin is always waiting on the floor you're on (you never wait for it): it
	    hurries there whenever you change floors in the building or by the tower, and
	    back to the ground floor while you're out;
	  * standing in it, you get "Up" and "Down" (one floor each; stacked so they don't
	    overlap: E / X for the top one, F / Y for the other); a ride holds
	    you in place (anchored), slides the doors shut, glides the cabin straight there
	    with you in it (the pulley turning, the counterweight going the other way, the
	    cables paying out, a motor hum), then a ding and the doors slide open;
	  * each storey's doors (tagged "LiftDoor") are open only while the cabin waits there;
	  * while TycoonFX's cutaway fades the storeys above yours, the rig's parts up there
	    (the pulley, the counterweight, the cables) fade with them.
	A 1-storey factory's lift stays shut (the Clay Studio brings the 2nd floor).
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

local DOOR_TIME = 0.35
local RIDE_TIME = { 1, 0.8 } -- seconds for a ride: a start, plus this per storey
local CALL_TIME = 0.9 -- seconds per storey when it comes to you, empty
local CHECK_EVERY = 0.15 -- seconds between looks at where you are
local NEAR_TOWER = 22 -- studs (across) from the tower that count as being at the lift
local HUM_RANGE = 140
local PROMPT_GAP = 80 -- pixels between the stacked prompts (a prompt is 72 tall)

local player = Players.LocalPlayer
local riding = false

type Cable = { Part: BasePart, X: number, Z: number, Weight: boolean }
type Motion = { From: number, To: number, Start: number, Time: number, Rider: BasePart?, Offset: CFrame? }
type Lift = {
	Rig: Model,
	Building: Instance, -- (the plot's model: its doors are in it)
	Base: CFrame, -- the tower, on the ground floor's floor (-Z toward the building)
	Storeys: number,
	Rise: number,
	Cabin: Model?,
	Weight: Model?,
	Pulley: Model?,
	PulleyRest: CFrame,
	PulleyRadius: number,
	PulleyY: number,
	CabinTop: number,
	WeightTop: number,
	CabinZ: number,
	CabinHalf: number,
	CabinHeight: number,
	DoorZ: number,
	Area: CFrame,
	AreaSize: Vector3,
	Cables: { Cable },
	Parts: { BasePart }, -- all of the rig's, for the cutaway's fade
	Fade: number, -- the fade they're at
	Layers: { [number]: BasePart }, -- a part of each cutaway layer (by Level), to read its fade
	At: number, -- where the cabin is, in storeys (1 = ground); between two while moving
	Busy: boolean,
	Motion: Motion?,
	Prompts: { [number]: ProximityPrompt }, -- Up (1) and Down (-1): by how many floors
}
local lifts: { [Model]: Lift } = {}

local function numberOf(rig: Instance, name: string, default: number): number
	local value = rig:GetAttribute(name)
	return if typeof(value) == "number" then value else default
end

-- Where the cabin's floor is at `at` (storeys).
local function cabinFrame(lift: Lift, at: number): CFrame
	return lift.Base * CFrame.new(0, (at - 1) * lift.Rise, 0)
end

-- Puts the cabin, counterweight, pulley and cables where lift.At says.
local function pose(lift: Lift)
	local y = (lift.At - 1) * lift.Rise
	if lift.Cabin then
		lift.Cabin:PivotTo(lift.Base * CFrame.new(0, y, 0))
	end
	if lift.Weight then
		lift.Weight:PivotTo(lift.Base * CFrame.new(0, -y, 0))
	end
	if lift.Pulley then
		-- (its rim on the cabin's side, -Z, rises with the cabin)
		lift.Pulley:PivotTo(lift.PulleyRest * CFrame.Angles(y / lift.PulleyRadius, 0, 0))
	end
	for _, cable in lift.Cables do
		local bottom = if cable.Weight then lift.WeightTop - y else lift.CabinTop + y
		local length = math.max(lift.PulleyY - bottom, 0.1)
		local part = cable.Part
		part.Size = Vector3.new(part.Size.X, length, part.Size.Z)
		part.CFrame = lift.Base * CFrame.new(cable.X, bottom + length / 2, cable.Z)
	end
end

-- A storey's doors (and their neon edges), or every storey's.
local function doorsOf(lift: Lift, storey: number?): { BasePart }
	local doors = {}
	for _, door in CollectionService:GetTagged("LiftDoor") do
		if door:IsA("BasePart") and door:IsDescendantOf(lift.Building) and (storey == nil or door:GetAttribute("Storey") == storey) then
			table.insert(doors, door)
		end
	end
	return doors
end

local function waitsAt(lift: Lift, storey: number): boolean
	return lift.Storeys > 1 and not lift.Busy and lift.At == storey
end

-- Slides doors open or shut over `time` seconds (at once with 0).
local function setDoor(door: BasePart, open: boolean, time: number)
	local cframe = door:GetAttribute(if open then "OpenCFrame" else "ClosedCFrame")
	if typeof(cframe) ~= "CFrame" then
		return
	end
	if time > 0 then
		TweenService:Create(door, TweenInfo.new(time, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), { CFrame = cframe }):Play()
	else
		door.CFrame = cframe
	end
end

local function setDoors(lift: Lift, storey: number, open: boolean, time: number)
	for _, door in doorsOf(lift, storey) do
		setDoor(door, open, time)
	end
	if time > 0 then
		local at = (cabinFrame(lift, storey) * CFrame.new(0, 6, lift.DoorZ)).Position
		local sound = Effects.sound(at, Sounds.LiftDoors, 0.35, 1.2)
		if sound then
			task.delay(time + 0.35, function()
				sound:Stop()
			end)
		end
	end
end

-- The motor's hum, riding along in the cabin's floor.
local function hum(lift: Lift): Sound?
	local floor = lift.Cabin and lift.Cabin:FindFirstChild("CabinFloor")
	if not (floor and floor:IsA("BasePart") and Effects.near(floor.Position, HUM_RANGE)) then
		return nil
	end
	local sound = Instance.new("Sound")
	sound.SoundId = Sounds.LiftRun
	sound.Volume = 0.3
	sound.Looped = true
	sound.RollOffMode = Enum.RollOffMode.InverseTapered
	sound.RollOffMinDistance = 12
	sound.RollOffMaxDistance = HUM_RANGE
	sound.SoundGroup = Effects.SfxGroup
	sound.Parent = floor
	sound:Play()
	return sound
end

local function fadeOut(sound: Sound?)
	if sound then
		TweenService:Create(sound, TweenInfo.new(0.4), { Volume = 0 }):Play()
		task.delay(0.45, function()
			sound:Destroy()
		end)
	end
end

-- The player's movement controls (the default PlayerModule's), to switch off for a ride.
-- This place has no PlayerModule in PlayerScripts (waiting for one hung every ride);
-- the anchored root holds you still.
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

-- Takes the cabin to `target`: doors shut, the glide (the frame loop below moves it, and
-- `rider` with it; quicker when it comes to you empty), a ding, doors open. Yields.
local function travel(lift: Lift, target: number, rider: BasePart?)
	lift.Busy = true
	local from = lift.At
	setDoors(lift, from, false, DOOR_TIME)
	task.wait(DOOR_TIME)
	local motion: Motion = {
		From = from,
		To = target,
		Start = os.clock(),
		Time = if rider then RIDE_TIME[1] + RIDE_TIME[2] * math.abs(target - from) else CALL_TIME * math.abs(target - from),
		Rider = rider,
		Offset = if rider then cabinFrame(lift, from):ToObjectSpace(rider.CFrame) else nil,
	}
	local motor = hum(lift)
	lift.Motion = motion
	while lift.Motion == motion and lifts[lift.Rig] == lift do
		task.wait()
	end
	fadeOut(motor)
	local arrival = (cabinFrame(lift, target) * CFrame.new(0, 8, lift.CabinZ)).Position
	Effects.sound(arrival, Sounds.LiftDing, 0.5)
	setDoors(lift, target, true, DOOR_TIME)
	task.wait(DOOR_TIME)
	lift.Busy = false
end

-- A ride with you in it, from where it waits to `target`.
local function ride(lift: Lift, target: number)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if riding or lift.Busy or not (character and root) then
		return
	end
	riding = true
	for _, prompt in lift.Prompts do
		prompt.Enabled = false
	end
	setControls(false)
	root.AssemblyLinearVelocity = Vector3.zero
	root.Anchored = true
	-- (the floor there streams in meanwhile)
	task.spawn(pcall, player.RequestStreamAroundAsync, player, cabinFrame(lift, target).Position, 2)
	travel(lift, target, root)
	if root.Parent then
		root.Anchored = false
	end
	setControls(true)
	riding = false
end

-- How far the cutaway (TycoonFX) has faded the building's layer at `level` (0..1).
local function layerFade(lift: Lift, level: number): number
	local sample = lift.Layers[level]
	if not (sample and sample:IsDescendantOf(lift.Building)) then
		sample = nil
		for _, layer in lift.Building:GetChildren() do
			if layer:IsA("Model") and layer:GetAttribute("Level") == level then
				sample = layer:FindFirstChildWhichIsA("BasePart", true)
				break
			end
		end
		if not sample then
			return 0
		end
		lift.Layers[level] = sample
	end
	return sample.LocalTransparencyModifier
end

-- Fades the rig's parts over your storey's ceiling (and every cable) as the layers above
-- you fade: while you're inside the building and the camera is up above your ceiling.
local function cutaway(lift: Lift, root: BasePart?)
	local fade, ceiling = 0, math.huge
	if root then
		local at = lift.Area:PointToObjectSpace(root.Position)
		local size = lift.AreaSize
		if math.abs(at.X) <= size.X / 2 and math.abs(at.Z) <= size.Z / 2 and at.Y > -2 and at.Y < size.Y then
			local storey = math.floor(at.Y / lift.Rise) + 1
			fade = layerFade(lift, storey + 1)
			ceiling = storey * lift.Rise - 2
		end
	end
	if fade == lift.Fade and not (fade > 0 and lift.Motion) then
		return
	end
	lift.Fade = fade
	for _, part in lift.Parts do
		local cable = part.Name == "CabinCable" or part.Name == "WeightCable"
		part.LocalTransparencyModifier = if cable or lift.Base:PointToObjectSpace(part.Position).Y > ceiling then fade else 0
	end
end

-- Whether a world point is inside the cabin where it is now.
local function inCabin(lift: Lift, position: Vector3): boolean
	local at = cabinFrame(lift, lift.At):PointToObjectSpace(position)
	return math.abs(at.X) <= lift.CabinHalf and math.abs(at.Z - lift.CabinZ) <= lift.CabinHalf and at.Y > 0 and at.Y < lift.CabinHeight
end

local function watch(rig: Instance)
	if not rig:IsA("Model") or lifts[rig] then
		return
	end
	local base, storeys, building = rig:GetAttribute("Base"), rig:GetAttribute("Storeys"), rig.Parent
	local area, areaSize = rig:GetAttribute("Area"), rig:GetAttribute("AreaSize")
	if typeof(base) ~= "CFrame" or typeof(storeys) ~= "number" or typeof(area) ~= "CFrame" or typeof(areaSize) ~= "Vector3" or not building then
		return
	end
	local cabin, weight, pulley = rig:FindFirstChild("Cabin"), rig:FindFirstChild("Weight"), rig:FindFirstChild("Pulley")
	local lift: Lift = {
		Rig = rig,
		Building = building,
		Base = base,
		Storeys = storeys,
		Rise = numberOf(rig, "Rise", 30),
		Cabin = if cabin and cabin:IsA("Model") then cabin else nil,
		Weight = if weight and weight:IsA("Model") then weight else nil,
		Pulley = if pulley and pulley:IsA("Model") then pulley else nil,
		PulleyRest = if pulley and pulley:IsA("Model") then pulley:GetPivot() else base,
		PulleyRadius = numberOf(rig, "PulleyRadius", 3),
		PulleyY = numberOf(rig, "PulleyY", 0),
		CabinTop = numberOf(rig, "CabinTop", 12),
		WeightTop = numberOf(rig, "WeightTop", 12),
		CabinZ = numberOf(rig, "CabinZ", 0),
		CabinHalf = numberOf(rig, "CabinHalf", 4.5),
		CabinHeight = numberOf(rig, "CabinHeight", 11),
		DoorZ = numberOf(rig, "DoorZ", -6),
		Area = area,
		AreaSize = areaSize,
		Cables = {},
		Parts = {},
		Fade = 0,
		Layers = {},
		At = 1, -- (the server leaves it on the ground floor)
		Busy = false,
		Motion = nil,
		Prompts = {},
	}
	for _, part in rig:GetDescendants() do
		if part:IsA("BasePart") then
			table.insert(lift.Parts, part)
		end
	end
	for _, part in rig:GetChildren() do
		if part:IsA("BasePart") and (part.Name == "CabinCable" or part.Name == "WeightCable") then
			local at = base:PointToObjectSpace(part.Position)
			table.insert(lift.Cables, { Part = part, X = at.X, Z = at.Z, Weight = part.Name == "WeightCable" })
		end
	end
	-- the prompts, Up and Down a floor, in the cabin's middle (they ride along)
	local floor = lift.Cabin and lift.Cabin:FindFirstChild("CabinFloor")
	if storeys > 1 and floor and floor:IsA("BasePart") then
		local spot = Instance.new("Attachment")
		spot.Name = "LiftPromptSpot"
		spot.Position = Vector3.new(0, 3.3, 0)
		spot.Parent = floor
		for _, step in { 1, -1 } do
			local prompt = Instance.new("ProximityPrompt")
			prompt.Name = if step > 0 then "LiftUp" else "LiftDown"
			prompt.ActionText = if step > 0 then "Up" else "Down"
			prompt.HoldDuration = 0
			prompt.MaxActivationDistance = 8
			prompt.RequiresLineOfSight = false
			prompt.Enabled = false -- (on while you're inside and it waits: see below)
			prompt.Parent = spot
			prompt.Triggered:Connect(function()
				local target = lift.At + step
				if lift.At == math.floor(lift.At) and target >= 1 and target <= lift.Storeys then
					ride(lift, target)
				end
			end)
			lift.Prompts[step] = prompt
		end
	end
	lifts[rig] = lift
	for _, door in doorsOf(lift) do
		setDoor(door, waitsAt(lift, door:GetAttribute("Storey") :: number), 0)
	end
end

local function watchLater(rig: Instance)
	-- (an atomic model arrives whole, but give its children a moment anyway)
	task.spawn(function()
		rig:WaitForChild("Cabin", 5)
		watch(rig)
	end)
end

for _, rig in CollectionService:GetTagged("Lift") do
	watchLater(rig)
end
CollectionService:GetInstanceAddedSignal("Lift"):Connect(watchLater)
CollectionService:GetInstanceRemovedSignal("Lift"):Connect(function(rig)
	lifts[rig :: Model] = nil
end)

-- A door that streams in takes its place: open only where the cabin waits.
CollectionService:GetInstanceAddedSignal("LiftDoor"):Connect(function(door)
	if not door:IsA("BasePart") then
		return
	end
	for _, lift in lifts do
		if door:IsDescendantOf(lift.Building) then
			setDoor(door, waitsAt(lift, door:GetAttribute("Storey") :: number), 0)
		end
	end
end)

-- Every frame (before the camera), the moving cabins, and you in yours; and the cutaway.
RunService:BindToRenderStep("Elevator", Enum.RenderPriority.Camera.Value - 1, function()
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	for _, lift in lifts do
		local motion = lift.Motion
		if motion then
			local a = math.min((os.clock() - motion.Start) / motion.Time, 1)
			lift.At = motion.From + (motion.To - motion.From) * TweenService:GetValue(a, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
			if a >= 1 then
				lift.At = motion.To
				lift.Motion = nil
			end
			pose(lift)
			if motion.Rider and motion.Offset and motion.Rider.Parent then
				motion.Rider.CFrame = cabinFrame(lift, lift.At) * motion.Offset
			end
		end
		cutaway(lift, root)
	end
end)

-- A few times a second: the prompts (on while you stand in a waiting cabin: Up on top,
-- Down under it, each only where there's a floor to go to), and the cabin hurrying to
-- the floor you're on (the ground floor while you're out).
local elapsed = 0
RunService.Heartbeat:Connect(function(dt)
	elapsed += dt
	if elapsed < CHECK_EVERY then
		return
	end
	elapsed = 0
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	for _, lift in lifts do
		local idle = not lift.Busy and not riding and lift.Storeys > 1
		local inside = root ~= nil and idle and inCabin(lift, root.Position)
		local shown = 0
		for _, step in { 1, -1 } do
			local prompt = lift.Prompts[step]
			if prompt then
				local target = lift.At + step
				local on = inside and target >= 1 and target <= lift.Storeys
				prompt.Enabled = on
				if on then
					shown += 1
					prompt.KeyboardKeyCode = if shown == 1 then Enum.KeyCode.E else Enum.KeyCode.F
					prompt.GamepadKeyCode = if shown == 1 then Enum.KeyCode.ButtonX else Enum.KeyCode.ButtonY
				end
			end
		end
		-- (stacked round the middle: the first above, the next under it; a positive
		-- UIOffset.Y lifts a prompt)
		local count = shown
		shown = 0
		for _, step in { 1, -1 } do
			local prompt = lift.Prompts[step]
			if prompt and prompt.Enabled then
				shown += 1
				prompt.UIOffset = Vector2.new(0, ((count + 1) / 2 - shown) * PROMPT_GAP)
			end
		end
		if not idle or inside then
			continue
		end
		local storey = 1
		if root then
			local tower = lift.Base:PointToObjectSpace(root.Position)
			local inArea = lift.Area:PointToObjectSpace(root.Position)
			local near = Vector2.new(tower.X, tower.Z).Magnitude < NEAR_TOWER
				or (math.abs(inArea.X) <= lift.AreaSize.X / 2 and math.abs(inArea.Z) <= lift.AreaSize.Z / 2 and inArea.Y < lift.AreaSize.Y + 5)
			if near then
				storey = math.clamp(math.floor(tower.Y / lift.Rise) + 1, 1, lift.Storeys)
			end
		end
		if lift.At ~= storey then
			task.spawn(travel, lift, storey)
		end
	end
end)
