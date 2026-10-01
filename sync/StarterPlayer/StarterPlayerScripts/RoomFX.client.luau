--[[
	RoomFX
	Plays the room upgrades that move (RoomUpgradeBuilder, GDD §6), on this client only,
	and only near the camera:
	  * BubbleWrap: the bubbles pop one at a time (they flatten with a pop and a puff,
	    and plump back up a little later); from level 2 the press thumps as they go.
	  * JackInTheBox: the crank turns; every few seconds it whirs faster, the lid flips
	    open and a brainrot head springs out on a coil in a burst of confetti, wobbles,
	    and sinks back in.
	  * BoxConveyor: the boxes ride round the rail near the ceiling.
	  * ToyTrain: the train runs round its track, puffing smoke and whistling now and
	    then.
	  * RoomUpgrade (all of them): every few seconds each sends what it makes flying
	    over to a machine on one of its room's lines (presents and boxes to the toy
	    boxes, bubble wrap to the Toy Packer, yarn to the knitting machines, fluff,
	    buttons, hearts) and it lands with the upgrade's bonus, so you can see why it
	    makes money. The Jack-in-the-Box spills coins onto the Cash Pad when it pops.
]]

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local BrainrotModels = require(Shared:WaitForChild("BrainrotModels"))
local Brainrots = require(Config:WaitForChild("Brainrots"))
local ConveyorPath = require(Shared:WaitForChild("ConveyorPath"))
local Sounds = require(Config:WaitForChild("Sounds"))
local Effects = require(ReplicatedStorage:WaitForChild("Client"):WaitForChild("Effects"))

local NEAR = 180 -- studs from the camera
local WHITE = Color3.new(1, 1, 1)
local BONUS_COLOR = Color3.fromRGB(255, 220, 70)
local FLYER_COLORS = {
	Color3.fromRGB(255, 80, 100),
	Color3.fromRGB(255, 200, 40),
	Color3.fromRGB(50, 150, 255),
	Color3.fromRGB(80, 205, 90),
	Color3.fromRGB(160, 95, 255),
	Color3.fromRGB(255, 110, 180),
}

local function near(position: Vector3): boolean
	return Effects.near(position, NEAR)
end

-- Calls `added` for every Model with `tag`, now and later; `removed` when it goes.
local function watch(tag: string, added: (Model) -> (), removed: (Model) -> ())
	local function onAdded(instance: Instance)
		if instance:IsA("Model") then
			added(instance)
		end
	end
	for _, instance in CollectionService:GetTagged(tag) do
		onAdded(instance)
	end
	CollectionService:GetInstanceAddedSignal(tag):Connect(onAdded)
	CollectionService:GetInstanceRemovedSignal(tag):Connect(function(instance)
		if instance:IsA("Model") then
			removed(instance)
		end
	end)
end

local function numberOf(model: Instance, name: string, default: number): number
	local value = model:GetAttribute(name)
	return if typeof(value) == "number" then value else default
end

-- "+39%" for a room upgrade's bonus (its Bonus attribute: 1.39).
local function bonusText(model: Instance): string
	return `+{math.floor((numberOf(model, "Bonus", 1) - 1) * 100 + 0.5)}% 💰`
end

-- Bubble wrap -----------------------------------------------------------------------

type Wrap = {
	Bubbles: { BasePart },
	Rest: { [BasePart]: Vector3 },
	Popped: { [BasePart]: boolean },
	Stamper: BasePart?,
	StamperRest: CFrame?,
	Level: number,
	Next: number,
}
local wraps: { [Model]: Wrap } = {}

watch("BubbleWrap", function(model)
	local wrap: Wrap = { Bubbles = {}, Rest = {}, Popped = {}, Stamper = nil, StamperRest = nil, Level = numberOf(model, "Level", 1), Next = os.clock() + 1 }
	for _, child in model:GetChildren() do
		if child:IsA("BasePart") and child.Name == "Bubble" then
			table.insert(wrap.Bubbles, child)
			wrap.Rest[child] = child.Size
		elseif child:IsA("BasePart") and child.Name == "Stamper" then
			wrap.Stamper = child
			wrap.StamperRest = child.CFrame
		end
	end
	wraps[model] = wrap
end, function(model)
	wraps[model] = nil
end)

local function popBubble(wrap: Wrap)
	local choices = {}
	for _, bubble in wrap.Bubbles do
		if not wrap.Popped[bubble] and bubble.Parent then
			table.insert(choices, bubble)
		end
	end
	if #choices == 0 then
		return
	end
	local bubble = choices[math.random(1, #choices)]
	local rest = wrap.Rest[bubble]
	wrap.Popped[bubble] = true
	local stamper, stamperRest = wrap.Stamper, wrap.StamperRest
	if stamper and stamperRest then
		local down = TweenService:Create(stamper, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, true), { CFrame = stamperRest - Vector3.new(0, 2.4, 0) })
		down:Play()
	end
	TweenService:Create(bubble, TweenInfo.new(0.06), { Size = Vector3.new(rest.X * 1.3, rest.Y * 0.15, rest.Z * 1.3) }):Play()
	Effects.sound(bubble.Position, Sounds.Pop, 0.22, 1.7 + math.random() * 0.6)
	Effects.puff(bubble.Position, WHITE, 3, 0.4)
	if wrap.Level >= 3 then
		Effects.sparkle(bubble.Position, bubble.Color, 5)
	end
	task.delay(2.5 + math.random() * 2, function()
		if bubble.Parent then
			TweenService:Create(bubble, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = rest }):Play()
		end
		wrap.Popped[bubble] = nil
	end)
end

-- Jack-in-the-box ---------------------------------------------------------------------

type Jack = {
	Model: Model,
	Lid: Model?,
	LidRest: CFrame?,
	OpenAngle: number,
	Crank: Model?,
	CrankRest: CFrame?,
	CrankAngle: number,
	CrankSpeed: number,
	Base: CFrame,
	Depth: number,
	Level: number,
	Next: number,
	Busy: boolean,
}
local jacks: { [Model]: Jack } = {}

watch("JackInTheBox", function(model)
	local lid = model:FindFirstChild("JackLid")
	local crank = model:FindFirstChild("JackCrank")
	local base = model:GetAttribute("JackBase")
	jacks[model] = {
		Model = model,
		Lid = if lid and lid:IsA("Model") then lid else nil,
		LidRest = if lid and lid:IsA("Model") then lid:GetPivot() else nil,
		OpenAngle = if lid then numberOf(lid, "OpenAngle", -2) else -2,
		Crank = if crank and crank:IsA("Model") then crank else nil,
		CrankRest = if crank and crank:IsA("Model") then crank:GetPivot() else nil,
		CrankAngle = 0,
		CrankSpeed = 1.5,
		Base = if typeof(base) == "CFrame" then base else model:GetPivot(),
		Depth = numberOf(model, "JackDepth", 7),
		Level = numberOf(model, "Level", 1),
		Next = os.clock() + 3 + math.random() * 3,
		Busy = false,
	}
end, function(model)
	jacks[model] = nil
end)

local function setLid(jack: Jack, open: number)
	if jack.Lid and jack.LidRest then
		jack.Lid:PivotTo(jack.LidRest * CFrame.Angles(jack.OpenAngle * open, 0, 0))
	end
end

-- A coil of rings from `bottom` to `top` (world), `count` of them.
local function placeCoil(rings: { BasePart }, bottom: Vector3, top: Vector3)
	for index, ring in rings do
		local at = bottom:Lerp(top, (index - 0.5) / #rings)
		ring.CFrame = CFrame.new(at) * CFrame.Angles(0, 0, math.pi / 2) * CFrame.Angles(index * 0.4, 0, 0)
	end
end

local function popJack(jack: Jack)
	jack.Busy = true
	local model = jack.Model
	local s = if jack.Level >= 2 then 1.25 else 1
	-- the crank whirs faster and faster...
	jack.CrankSpeed = 9
	local whir = Effects.sound(jack.Base.Position, Sounds.Ratchet, 0.3, 1.3)
	task.wait(1.1)
	if whir then
		whir:Stop()
	end
	if not model.Parent then
		return
	end
	-- ...the lid flips open and a brainrot head springs out on its coil
	local id = Brainrots.List[math.random(1, #Brainrots.List)].Id
	local head, center, size = BrainrotModels.CreatePart(id, "Head", "ToyWorkshop")
	head:ScaleTo(head:GetScale() * 2.4 * s)
	local scale = 2.4 * s / 1
	local headSize = size * scale
	local headCenter = center * scale
	local rings: { BasePart } = {}
	for index = 1, 9 do
		local ring = Instance.new("Part")
		ring.Name = "Coil"
		ring.Anchored = true
		ring.CanCollide = false
		ring.CanQuery = false
		ring.CanTouch = false
		ring.Shape = Enum.PartType.Cylinder
		ring.Size = Vector3.new(0.35 * s, 2.6 * s, 2.6 * s)
		ring.Color = if index % 2 == 0 then Color3.fromRGB(215, 220, 235) else Color3.fromRGB(255, 205, 60)
		ring.Material = Enum.Material.Metal
		ring.Parent = Effects.Folder
		rings[index] = ring
	end
	local bottom = jack.Base.Position
	local function pose(rise: number, sway: number)
		local top = bottom + Vector3.new(0, rise, 0)
		placeCoil(rings, bottom, top)
		-- the head sits on the coil's top, its bottom there
		local pivot = (jack.Base.Rotation + top) * CFrame.Angles(0, 0, sway) * CFrame.new(-headCenter + Vector3.new(0, headSize.Y / 2, 0))
		head:PivotTo(pivot)
	end
	pose(0.5, 0)
	head.Parent = Effects.Folder
	Effects.sound(bottom, Sounds.Clunk, 0.3, 1.2)
	local start = os.clock()
	local height = jack.Depth + 3 * s
	while true do
		local a = math.min((os.clock() - start) / 0.25, 1)
		setLid(jack, TweenService:GetValue(a, Enum.EasingStyle.Back, Enum.EasingDirection.Out))
		pose(0.5 + height * TweenService:GetValue(a, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), 0)
		if a >= 1 then
			break
		end
		RunService.Heartbeat:Wait()
	end
	local top = bottom + Vector3.new(0, height + headSize.Y, 0)
	Effects.sound(top, Sounds.Boing, 0.45, 0.9)
	Effects.sound(top, Sounds.Jingle, 0.3, 1.1)
	if near(top) then
		Effects.confetti(top, if jack.Level >= 2 then 50 else 30)
		Effects.sparkle(top, Color3.fromRGB(255, 220, 90), 20)
		Effects.popup(top + Vector3.new(0, 2, 0), "SURPRISE!", Color3.fromRGB(255, 90, 120), 2, 1)
		Effects.popup(top + Vector3.new(0, 4.5, 0), bonusText(model), BONUS_COLOR, 1.4, 1)
		-- the surprise is coins: they spill over to the Cash Pad
		local plot = model.Parent and model.Parent.Parent
		local pad = plot and plot:FindFirstChild("CashPad")
		if pad and pad:IsA("BasePart") then
			Effects.sound(top, Sounds.Coins, 0.3, 1)
			Effects.coins(top, pad.Position + Vector3.new(0, pad.Size.Y / 2 + 0.3, 0), if jack.Level >= 2 then 8 else 5)
		end
	end
	-- it wobbles on its coil a while...
	start = os.clock()
	while os.clock() - start < 1.6 and model.Parent do
		local t = os.clock() - start
		pose(0.5 + height + math.sin(t * 14) * 0.4 * (1.6 - t), math.sin(t * 9) * 0.25 * (1.6 - t))
		RunService.Heartbeat:Wait()
	end
	-- ...and sinks back in, the lid shutting on it
	start = os.clock()
	while model.Parent do
		local a = math.min((os.clock() - start) / 0.35, 1)
		pose(0.5 + height * (1 - TweenService:GetValue(a, Enum.EasingStyle.Quad, Enum.EasingDirection.In)), 0)
		setLid(jack, 1 - TweenService:GetValue(math.clamp((a - 0.5) * 2, 0, 1), Enum.EasingStyle.Quad, Enum.EasingDirection.In))
		if a >= 1 then
			break
		end
		RunService.Heartbeat:Wait()
	end
	setLid(jack, 0)
	Effects.sound(bottom, Sounds.Clunk, 0.35, 0.9)
	head:Destroy()
	for _, ring in rings do
		ring:Destroy()
	end
	jack.CrankSpeed = 1.5
	jack.Next = os.clock() + 6 + math.random() * 4
	jack.Busy = false
end

-- Box conveyor ----------------------------------------------------------------------

type Conveyor = { Origin: CFrame, Speed: number, Boxes: { { Model: Model, Phase: number } } }
local conveyors: { [Model]: Conveyor } = {}

watch("BoxConveyor", function(model)
	local origin = model:GetAttribute("Origin")
	local conveyor: Conveyor = { Origin = if typeof(origin) == "CFrame" then origin else model:GetPivot(), Speed = numberOf(model, "Speed", 5), Boxes = {} }
	for _, child in model:GetChildren() do
		if child:IsA("Model") and child.Name == "ConveyorBox" then
			table.insert(conveyor.Boxes, { Model = child, Phase = numberOf(child, "Phase", 0) })
		end
	end
	conveyors[model] = conveyor
end, function(model)
	conveyors[model] = nil
end)

-- Toy train -------------------------------------------------------------------------

type Train = {
	Center: CFrame,
	Radius: number,
	Speed: number,
	Cars: { { Model: Model, Offset: number } },
	Chimney: BasePart?,
	NextPuff: number,
	NextWhistle: number,
}
local trains: { [Model]: Train } = {}

watch("ToyTrain", function(model)
	local center = model:GetAttribute("Center")
	local train: Train = {
		Center = if typeof(center) == "CFrame" then center else model:GetPivot(),
		Radius = numberOf(model, "Radius", 5),
		Speed = numberOf(model, "Speed", 0.6),
		Cars = {},
		Chimney = nil,
		NextPuff = 0,
		NextWhistle = os.clock() + 4,
	}
	for _, child in model:GetChildren() do
		if child:IsA("Model") and child.Name == "TrainCar" then
			table.insert(train.Cars, { Model = child, Offset = numberOf(child, "Offset", 0) })
			local chimney = child:FindFirstChild("Chimney")
			if chimney and chimney:IsA("BasePart") then
				train.Chimney = chimney
			end
		end
	end
	trains[model] = train
end, function(model)
	trains[model] = nil
end)

-- Deliveries ---------------------------------------------------------------------------

type Upgrade = { Model: Model, Next: number }
local upgrades: { [Model]: Upgrade } = {}

watch("RoomUpgrade", function(model)
	upgrades[model] = { Model = model, Next = os.clock() + 1 + math.random() * numberOf(model, "Every", 4) }
end, function(model)
	upgrades[model] = nil
end)

-- The lines in the upgrade's room (siblings in its plot's Lines folder).
local function roomLines(model: Model): { Model }
	local found = {}
	local zone = model:GetAttribute("Zone")
	local lines = model.Parent
	if not (lines and typeof(zone) == "string") then
		return found
	end
	for _, line in lines:GetChildren() do
		if line:IsA("Model") and string.sub(line.Name, 1, #zone + 1) == zone .. "_" and not string.find(line.Name, "_Decor_", 1, true) then
			table.insert(found, line)
		end
	end
	return found
end

-- Where on `line` a delivery lands: the part named `target` (any whose name ends with
-- it, for the knitting machines' yarn balls), else the line's Ship.
local function findTarget(line: Model, target: string): BasePart?
	local matches = {}
	for _, part in line:GetDescendants() do
		if part:IsA("BasePart") and (part.Name == target or (target == "KnitYarnBall" and string.sub(part.Name, -#target) == target)) then
			table.insert(matches, part)
		end
	end
	if #matches > 0 then
		return matches[math.random(1, #matches)]
	end
	local ship = line:FindFirstChild("Ship")
	return if ship and ship:IsA("BasePart") then ship else nil
end

local function flyerPart(model: Model, size: Vector3, offset: CFrame, color: Color3, shape: Enum.PartType?, material: Enum.Material?): Part
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Size = size
	part.CFrame = offset
	part.Color = color
	part.Shape = shape or Enum.PartType.Block
	part.Material = material or Enum.Material.SmoothPlastic
	part.Parent = model
	return part
end

-- What a delivery looks like, built round the origin, and its main color.
local function makeFlyer(kind: string): (Model, Color3)
	local model = Instance.new("Model")
	model.Name = "Delivery"
	local color = FLYER_COLORS[math.random(1, #FLYER_COLORS)]
	local core: Part
	if kind == "Gift" then
		core = flyerPart(model, Vector3.one * 1.4, CFrame.identity, color)
		flyerPart(model, Vector3.new(1.45, 1.45, 0.3), CFrame.identity, WHITE)
		flyerPart(model, Vector3.new(0.3, 1.45, 1.45), CFrame.identity, WHITE)
	elseif kind == "Box" then
		color = Color3.fromRGB(210, 160, 105)
		core = flyerPart(model, Vector3.one * 1.6, CFrame.identity, color)
		flyerPart(model, Vector3.new(1.65, 0.3, 0.5), CFrame.new(0, 0.7, 0), Color3.fromRGB(240, 205, 130))
	elseif kind == "Wrap" then
		color = Color3.fromRGB(190, 230, 255)
		core = flyerPart(model, Vector3.new(2.2, 0.15, 2.2), CFrame.identity, color)
		core.Transparency = 0.3
		for x = -1, 1, 2 do
			for z = -1, 1, 2 do
				flyerPart(model, Vector3.one * 0.6, CFrame.new(x * 0.5, 0.1, z * 0.5), WHITE, Enum.PartType.Ball).Transparency = 0.3
			end
		end
	elseif kind == "Yarn" then
		core = flyerPart(model, Vector3.one * 1.4, CFrame.identity, color, Enum.PartType.Ball, Enum.Material.Fabric)
		flyerPart(model, Vector3.new(0.3, 1.5, 1.5), CFrame.Angles(0, 0.5, math.rad(70)), color:Lerp(WHITE, 0.3), Enum.PartType.Cylinder, Enum.Material.Fabric)
	elseif kind == "Fluff" then
		color = WHITE
		core = flyerPart(model, Vector3.one * 1.4, CFrame.identity, color, Enum.PartType.Ball, Enum.Material.Fabric)
		flyerPart(model, Vector3.one * 1, CFrame.new(0.7, -0.2, 0.2), color, Enum.PartType.Ball, Enum.Material.Fabric)
		flyerPart(model, Vector3.one * 1, CFrame.new(-0.6, -0.1, -0.3), color, Enum.PartType.Ball, Enum.Material.Fabric)
	elseif kind == "Button" then
		core = flyerPart(model, Vector3.new(0.35, 1.5, 1.5), CFrame.identity, color, Enum.PartType.Cylinder)
	else -- a glowing heart
		color = Color3.fromRGB(255, 90, 170)
		core = flyerPart(model, Vector3.new(1, 1, 0.8), CFrame.new(0, -0.3, 0) * CFrame.Angles(0, 0, math.rad(45)), color, nil, Enum.Material.Neon)
		for _, x in { -0.38, 0.38 } do
			flyerPart(model, Vector3.one * 1, CFrame.new(x, 0.15, 0), color, Enum.PartType.Ball, Enum.Material.Neon)
		end
	end
	model.PrimaryPart = core
	-- a sparkly trail behind it
	local top, bottom = Instance.new("Attachment"), Instance.new("Attachment")
	top.Position = Vector3.new(0, 0.35, 0)
	bottom.Position = Vector3.new(0, -0.35, 0)
	top.Parent = core
	bottom.Parent = core
	local trail = Instance.new("Trail")
	trail.Attachment0 = top
	trail.Attachment1 = bottom
	trail.Lifetime = 0.35
	trail.LightEmission = 1
	trail.Color = ColorSequence.new(WHITE, color)
	trail.Transparency = NumberSequence.new(0.2, 1)
	trail.Parent = core
	return model, color
end

-- Flies `kind` from `from` over to `part` in an arc, spinning, and pops the bonus there.
local function deliver(model: Model, kind: string, from: Vector3, part: BasePart)
	local flyer, color = makeFlyer(kind)
	local to = part.Position + Vector3.new(0, part.Size.Y / 2 + 0.5, 0)
	local distance = (to - from).Magnitude
	local duration = math.clamp(distance / 28, 0.7, 1.8)
	local height = 3 + distance * 0.12
	flyer:PivotTo(CFrame.new(from))
	flyer.Parent = Effects.Folder
	Effects.sound(from, Sounds.Whoosh, 0.15, 1.6 + math.random() * 0.3)
	local start = os.clock()
	local spin = Vector3.new(math.random() * 6 - 3, 6, math.random() * 6 - 3)
	while true do
		local a = math.min((os.clock() - start) / duration, 1)
		local at = from:Lerp(to, a) + Vector3.new(0, height * 4 * a * (1 - a), 0)
		flyer:PivotTo(CFrame.new(at) * CFrame.Angles(spin.X * a, spin.Y * a, spin.Z * a))
		if a >= 1 then
			break
		end
		RunService.Heartbeat:Wait()
	end
	flyer:Destroy()
	Effects.sparkle(to, color, 8)
	Effects.sound(to, Sounds.Pop, 0.2, 1.5 + math.random() * 0.3)
	Effects.popup(to + Vector3.new(0, 2.5, 0), bonusText(model), BONUS_COLOR, 0.9, 0.6)
end

local function sendDelivery(upgrade: Upgrade)
	local model = upgrade.Model
	local kind = model:GetAttribute("Delivery")
	local target = model:GetAttribute("Target")
	if typeof(kind) ~= "string" or typeof(target) ~= "string" then
		return
	end
	local from: Vector3? = nil
	local source = model:GetAttribute("Source")
	local child = model:GetAttribute("FromChild")
	if typeof(source) == "Vector3" then
		from = source
	elseif typeof(child) == "string" then
		local candidates = {}
		for _, thing in model:GetChildren() do
			if thing.Name == child and thing:IsA("Model") then
				table.insert(candidates, thing)
			end
		end
		if #candidates > 0 then
			local picked = candidates[math.random(1, #candidates)]
			local box, size = picked:GetBoundingBox()
			from = box.Position - Vector3.new(0, size.Y * 0.2, 0)
		end
	end
	local lines = roomLines(model)
	if not from or #lines == 0 or not near(from) then
		return
	end
	local part = findTarget(lines[math.random(1, #lines)], target)
	if part then
		task.spawn(deliver, model, kind, from, part)
	end
end

-- The loop ----------------------------------------------------------------------------

RunService.Heartbeat:Connect(function(dt)
	local now = os.clock()
	for _, upgrade in upgrades do
		if now >= upgrade.Next then
			local every = numberOf(upgrade.Model, "Every", 4)
			upgrade.Next = now + every * (0.75 + math.random() * 0.5)
			sendDelivery(upgrade)
		end
	end
	for _, wrap in wraps do
		local bubble = wrap.Bubbles[1]
		if now >= wrap.Next and bubble and near(bubble.Position) then
			wrap.Next = now + 0.5 + math.random() * 0.7
			popBubble(wrap)
		end
	end
	for _, jack in jacks do
		if near(jack.Base.Position) then
			jack.CrankAngle += dt * jack.CrankSpeed
			if jack.Crank and jack.CrankRest then
				jack.Crank:PivotTo(jack.CrankRest * CFrame.Angles(0, 0, jack.CrankAngle))
			end
			if not jack.Busy and now >= jack.Next then
				task.spawn(popJack, jack)
			end
		end
	end
	for _, conveyor in conveyors do
		if near(conveyor.Origin.Position + Vector3.new(0, ConveyorPath.Height, 0)) then
			for _, box in conveyor.Boxes do
				local point, heading = ConveyorPath.Point(box.Phase * ConveyorPath.Perimeter + now * conveyor.Speed)
				box.Model:PivotTo(conveyor.Origin * CFrame.lookAt(point, point + heading))
			end
		end
	end
	for _, train in trains do
		if near(train.Center.Position) then
			local angle = now * train.Speed
			for _, car in train.Cars do
				car.Model:PivotTo(train.Center * CFrame.Angles(0, angle - car.Offset, 0) * CFrame.new(train.Radius, 0, 0))
			end
			local chimney = train.Chimney
			if chimney and now >= train.NextPuff then
				train.NextPuff = now + 0.45
				Effects.puff(chimney.Position + Vector3.new(0, 0.7, 0), Color3.fromRGB(235, 235, 240), 2, 0.5)
			end
			if chimney and now >= train.NextWhistle then
				train.NextWhistle = now + 9 + math.random() * 6
				Effects.sound(chimney.Position, Sounds.Whistle, 0.25, 1.3)
			end
		end
	end
end)
