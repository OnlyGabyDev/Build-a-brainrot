--[[
	Atmosphere
	The look and sound of the world (GDD §1, §13): a bright, warm, candy-colored
	afternoon under a dreamy anime skybox (Creator Store), with bloom (so every Neon part
	glows), punchy color grading, a soft pastel haze, and cheerful background music on
	shuffle with a mute button. In the hub (MapBuilder), the statues turn slowly, the
	balloons bob and the water's cartoon texture drifts; on the factories
	(FactoryBuilder), pinwheels, donuts and lollipops spin, balloons bob and marquee
	bulbs chase; windmills, flocks of birds and hot air balloons turn (Spinners too), and
	butterflies flutter over the flowers. Client only.
]]

local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Sounds = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("Sounds"))
local Client = ReplicatedStorage:WaitForChild("Client")
local BulkMover = require(Client:WaitForChild("Mover"))
local Effects = require(Client:WaitForChild("Effects"))
local Kit = require(Client:WaitForChild("UI"):WaitForChild("Kit"))
local Performance = require(Client:WaitForChild("Performance")) -- (Low: the decor holds still)

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

-- What the camera sees ----------------------------------------------------------------

-- Everything below moves only where you'd see it: off-screen things hold still, far
-- ones move less often (their pose follows the clock, so nothing drifts). A box storm
-- of factories can carry thousands of bulbs and spinners: this keeps them cheap.
local view = { Position = Vector3.zero, Inverse = CFrame.identity, TanX = 1, TanY = 1, Frame = 0 }

local function updateView()
	local camera = workspace.CurrentCamera
	local tanY = math.tan(math.rad(camera.FieldOfView) / 2)
	local size = camera.ViewportSize
	view.Position = camera.CFrame.Position
	view.Inverse = camera.CFrame:Inverse()
	view.TanY = tanY
	view.TanX = tanY * (if size.Y > 0 then size.X / size.Y else 1)
	view.Frame += 1
end

-- Whether a ball of `radius` round `position` is (at least partly) on screen.
local function onScreen(position: Vector3, radius: number): boolean
	local p = view.Inverse * position
	local depth = -p.Z
	if depth < -radius then
		return false -- behind the camera
	end
	local slack = radius * 1.5
	return math.abs(p.X) <= depth * view.TanX + slack and math.abs(p.Y) <= depth * view.TanY + slack
end

-- Whether something `distance` away should move this frame: every frame up close,
-- every other frame past NEAR_MOTION, every fourth past MID_MOTION.
local NEAR_MOTION, MID_MOTION = 120, 260
local function dueAt(distance: number, salt: number): boolean
	if distance < NEAR_MOTION then
		return true
	end
	local every = if distance < MID_MOTION then 2 else 4
	return (view.Frame + salt) % every == 0
end

RunService:BindToRenderStep("AtmosphereView", Enum.RenderPriority.Camera.Value + 2, updateView)

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
	if Performance.Low then
		return
	end
	local camera = workspace.CurrentCamera.CFrame.Position
	local turn = CFrame.Angles(0, os.clock() * STATUE_SPIN, 0)
	for statue, rest in spinning do
		if (rest.Position - camera).Magnitude < SPIN_DISTANCE then
			BulkMover.PivotTo(statue, rest * turn)
		end
	end
end)

-- The cartoon texture on the river and streams drifts along with the flow, each layer
-- at its own speed, from where its stretch sits along the flow (MapBuilder.waterSkin).
local WATER_DISTANCE = 400
local flowing: { [Texture]: { Base: number, Drift: number, Position: Vector3, Radius: number } } = {}
local function flow(texture: Instance)
	if texture:IsA("Texture") then
		local base, drift = texture:GetAttribute("Base"), texture:GetAttribute("Drift")
		local part = texture.Parent
		local position, radius = Vector3.zero, math.huge -- (unknown: always on)
		if part and part:IsA("BasePart") then
			position, radius = part.Position, part.Size.Magnitude / 2
		end
		flowing[texture] = {
			Base = if typeof(base) == "number" then base else 0,
			Drift = if typeof(drift) == "number" then drift else 1,
			Position = position,
			Radius = radius,
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
	if Performance.Low then
		return
	end
	local now = os.clock()
	for texture, layer in flowing do
		local distance = (layer.Position - view.Position).Magnitude - layer.Radius
		if distance < WATER_DISTANCE and onScreen(layer.Position, layer.Radius) and dueAt(distance, 0) then
			-- a falling offset slides the texture toward -Z, downstream
			texture.OffsetStudsV = (layer.Base - now * layer.Drift) % texture.StudsPerTileV
		end
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
		if Performance.Low then
			return
		end
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

-- (Center and Radius: a ball round the whole thing as it turns, for the on-screen test)
-- (Rigid: nothing inside moves on its own, so BulkMover can move it: a mover holding
-- another spinner or bobber keeps PivotTo, or it would undo its child's motion)
type Mover = { Rest: CFrame, Speed: number, Phase: number, Center: Vector3, Radius: number, Salt: number, Rigid: boolean }
local spinners: { [Model]: Mover } = {}
local bobbers: { [Model]: Mover } = {}
-- Marquee bulbs are sorted into cells MARQUEE_CELL studs wide (by where they were when
-- they appeared), so a chase step tests each cell against the view once, not each of
-- the thousands of bulbs.
local MARQUEE_CELL = 48
local CELL_RADIUS = MARQUEE_CELL * 0.87 + 4 -- the cell's half-diagonal, plus a spinning donut's slack
type Bulb = { Index: number, Lit: number?, Cell: Vector3 } -- its index along its string; its lit color's slot (0: off)
type Cell = { Center: Vector3, Bulbs: { [BasePart]: Bulb } }
local cells: { [Vector3]: Cell } = {}
local bulbs: { [BasePart]: Bulb } = {}
local movers = 0

local function holdsMovers(model: Model): boolean
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("Model") and (CollectionService:HasTag(descendant, "Spinner") or CollectionService:HasTag(descendant, "Bobbing")) then
			return true
		end
	end
	return false
end

local function mover(model: Model, speed: number, phase: number): Mover
	local rest = model:GetPivot()
	local box, size = model:GetBoundingBox()
	movers += 1
	-- it turns about its pivot: the ball round it must reach its far corner from there
	local reach = (box.Position - rest.Position).Magnitude + size.Magnitude / 2
	return { Rest = rest, Speed = speed, Phase = phase, Center = rest.Position, Radius = reach, Salt = movers, Rigid = not holdsMovers(model) }
end

local function moveTo(model: Model, item: Mover, cframe: CFrame)
	if item.Rigid then
		BulkMover.PivotTo(model, cframe)
	else
		model:PivotTo(cframe)
	end
end

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
		spinners[model] = mover(model, if typeof(speed) == "number" then speed else 1, 0)
	end
end, function(model)
	spinners[model :: Model] = nil
end)
watchTag("Bobbing", function(model)
	if model:IsA("Model") then
		local rest = model:GetPivot()
		bobbers[model] = mover(model, 1.3, (rest.X * 0.37 + rest.Z * 0.61) % (math.pi * 2))
	end
end, function(model)
	bobbers[model :: Model] = nil
end)
watchTag("Marquee", function(bulb)
	if bulb:IsA("BasePart") then
		local index = bulb:GetAttribute("Index")
		local p = bulb.Position
		local key = Vector3.new(p.X // MARQUEE_CELL, p.Y // MARQUEE_CELL, p.Z // MARQUEE_CELL)
		local cell = cells[key]
		if not cell then
			cell = { Center = (key + Vector3.new(0.5, 0.5, 0.5)) * MARQUEE_CELL, Bulbs = {} }
			cells[key] = cell
		end
		local entry = { Index = if typeof(index) == "number" then index else 0, Lit = nil, Cell = key }
		bulbs[bulb] = entry
		cell.Bulbs[bulb] = entry
	end
end, function(bulb)
	local entry = bulbs[bulb :: BasePart]
	if entry then
		bulbs[bulb :: BasePart] = nil
		local cell = cells[entry.Cell]
		if cell then
			cell.Bulbs[bulb :: BasePart] = nil
			if next(cell.Bulbs) == nil then
				cells[entry.Cell] = nil
			end
		end
	end
end)

-- Whether a mover should move this frame (near enough, on screen, and its turn).
local function moves(item: Mover): boolean
	local distance = (item.Center - view.Position).Magnitude - item.Radius
	return distance < DECOR_DISTANCE and onScreen(item.Center, item.Radius) and dueAt(distance, item.Salt)
end

local marqueeStep = -1
RunService.RenderStepped:Connect(function()
	if Performance.Low then
		return
	end
	local now = os.clock()
	for model, item in spinners do
		if moves(item) then
			moveTo(model, item, item.Rest * CFrame.Angles(0, 0, now * item.Speed))
		end
	end
	for model, item in bobbers do
		if moves(item) then
			moveTo(model, item, item.Rest + Vector3.new(0, math.sin(now * item.Speed + item.Phase) * 0.8, 0))
		end
	end
	-- every third bulb lit, each light keeping its color as it runs along the string; a
	-- bulb is only written when its light changes (and only if its cell is on screen:
	-- one that comes back into view catches up on the next step)
	local step = math.floor(now / MARQUEE_STEP)
	if step ~= marqueeStep then
		marqueeStep = step
		for _, cell in cells do
			if (cell.Center - view.Position).Magnitude - CELL_RADIUS < DECOR_DISTANCE and onScreen(cell.Center, CELL_RADIUS) then
				for bulb, entry in cell.Bulbs do
					local offset = entry.Index - step
					local lit = if offset % 3 == 0 then (offset // 3) % #MARQUEE_COLORS + 1 else 0
					if lit ~= entry.Lit then
						entry.Lit = lit
						if lit > 0 then
							bulb.Material = Enum.Material.Neon
							bulb.Color = MARQUEE_COLORS[lit]
						else
							bulb.Material = Enum.Material.SmoothPlastic
							bulb.Color = BULB_OFF
						end
					end
				end
			end
		end
	end
end)

-- Butterflies (MapBuilder) flutter round their Home over the flowers, wings flapping.
-- Only the ones near the camera move.
local BUTTERFLY_DISTANCE = 160
type Butterfly = { Body: BasePart, Left: BasePart, Right: BasePart, Home: Vector3, Phase: number, Reach: number }
local butterflies: { [Model]: Butterfly } = {}

watchTag("Butterfly", function(model)
	if not model:IsA("Model") then
		return
	end
	local body, left, right = model:FindFirstChild("Body"), model:FindFirstChild("WingLeft"), model:FindFirstChild("WingRight")
	local home, phase = model:GetAttribute("Home"), model:GetAttribute("Phase")
	if body and left and right and body:IsA("BasePart") and left:IsA("BasePart") and right:IsA("BasePart") and typeof(home) == "Vector3" then
		butterflies[model] = {
			Body = body,
			Left = left,
			Right = right,
			Home = home,
			Phase = if typeof(phase) == "number" then phase else 0,
			Reach = left.Size.X / 2, -- a wing's middle, out from the body
		}
	end
end, function(model)
	butterflies[model :: Model] = nil
end)

-- Where a butterfly is `t` into its loop: a wobbly figure round its home.
local function flightAt(fly: Butterfly, t: number): Vector3
	return fly.Home + Vector3.new(math.sin(t) * 3.5 + math.sin(t * 2.3) * 1.2, 1.5 + math.sin(t * 1.7) * 0.8, math.cos(t * 0.8) * 3.5)
end

RunService.RenderStepped:Connect(function()
	if Performance.Low then
		return
	end
	local now = os.clock()
	for _, fly in butterflies do
		if (fly.Home - view.Position).Magnitude < BUTTERFLY_DISTANCE and onScreen(fly.Home, 8) then
			local t = now * 0.7 + fly.Phase
			local frame = CFrame.lookAt(flightAt(fly, t), flightAt(fly, t + 0.05))
			local flap = math.sin(now * 22 + fly.Phase) * 1.1
			fly.Body.CFrame = frame
			fly.Left.CFrame = frame * CFrame.Angles(0, 0, -flap) * CFrame.new(-fly.Reach, 0, 0)
			fly.Right.CFrame = frame * CFrame.Angles(0, 0, flap) * CFrame.new(fly.Reach, 0, 0)
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
