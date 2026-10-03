--[[
	A small stand-in for Roblox's Instance tree, so the game's builders run outside
	Studio (under Lune: https://lune-org.github.io). Only what the builders use: names,
	parents and children, properties (anything can be set; common ones read back their
	Roblox defaults), attributes, tags, IsA, Clone, pivots (PivotTo, GetPivot,
	WorldPivot), ScaleTo, GetBoundingBox, and events that never fire unless the lab
	fires them. The math types (CFrame, Vector3, Color3...) are Lune's, so geometry is
	exact (tools/lab/types.luau wraps them). See tools/lab/lab.luau.
]]

local roblox = require("@lune/roblox")

local Types = require("./types")

local CFrame = Types.CFrame
local Vector3 = Types.Vector3
local Color3 = roblox.Color3
local Enum = roblox.Enum

local Dom = {}

-- Signals -----------------------------------------------------------------------------

local Signal = {}
Signal.__index = Signal

function Signal.new()
	return setmetatable({ Handlers = {} }, Signal)
end

function Signal:Connect(handler)
	local handlers = self.Handlers
	table.insert(handlers, handler)
	local connection = { Connected = true }
	function connection:Disconnect()
		self.Connected = false
		local index = table.find(handlers, handler)
		if index then
			table.remove(handlers, index)
		end
	end
	return connection
end
Signal.Once = Signal.Connect
Signal.ConnectParallel = Signal.Connect

function Signal:Fire(...)
	for _, handler in table.clone(self.Handlers) do
		handler(...)
	end
end

function Signal:Wait()
	return nil
end

Dom.Signal = Signal

-- Every event name the code connects to: reading one gives the instance's own signal.
local EVENTS = {
	Touched = true, TouchEnded = true, Triggered = true, TriggerEnded = true, PromptButtonHoldBegan = true,
	PromptButtonHoldEnded = true, Changed = true, ChildAdded = true, ChildRemoved = true,
	DescendantAdded = true, DescendantRemoving = true, AncestryChanged = true, Destroying = true,
	Activated = true, Equipped = true, Unequipped = true, CharacterAdded = true, CharacterRemoving = true,
	CharacterAppearanceLoaded = true, PlayerAdded = true, PlayerRemoving = true, Heartbeat = true,
	Stepped = true, RenderStepped = true, PostSimulation = true, PreSimulation = true, OnServerEvent = true,
	OnClientEvent = true, Event = true, MouseClick = true, Died = true, PromptGamePassPurchaseFinished = true,
	PromptProductPurchaseFinished = true, Completed = true, Ended = true, Played = true,
}

-- Classes -----------------------------------------------------------------------------

local SUPER: { [string]: string } = {
	Instance = "",
	PVInstance = "Instance", BasePart = "PVInstance", Model = "PVInstance", WorldRoot = "Model",
	Workspace = "WorldRoot", Part = "FormFactorPart", FormFactorPart = "BasePart", WedgePart = "FormFactorPart",
	CornerWedgePart = "BasePart", TrussPart = "BasePart", MeshPart = "TriangleMeshPart",
	TriangleMeshPart = "BasePart", UnionOperation = "PartOperation", PartOperation = "TriangleMeshPart",
	SpawnLocation = "Part", Seat = "Part", Terrain = "BasePart",
	Folder = "Instance", Configuration = "Instance", Attachment = "Instance", Tool = "BackpackItem", BackpackItem = "Model",
	Light = "Instance", PointLight = "Light", SpotLight = "Light", SurfaceLight = "Light",
	GuiBase = "Instance", GuiBase2d = "GuiBase", LayerCollector = "GuiBase2d", SurfaceGuiBase = "LayerCollector",
	SurfaceGui = "SurfaceGuiBase", BillboardGui = "LayerCollector", ScreenGui = "LayerCollector",
	GuiObject = "GuiBase2d", Frame = "GuiObject", TextLabel = "GuiObject", TextButton = "GuiButton",
	GuiButton = "GuiObject", ImageLabel = "GuiObject", ImageButton = "GuiButton", ViewportFrame = "GuiObject",
	ScrollingFrame = "GuiObject", CanvasGroup = "GuiObject",
	UIComponent = "Instance", UIStroke = "UIComponent", UICorner = "UIComponent", UIGradient = "UIComponent",
	UIListLayout = "UIComponent", UIGridLayout = "UIComponent", UIScale = "UIComponent", UIPadding = "UIComponent",
	UIAspectRatioConstraint = "UIComponent",
	DataModelMesh = "Instance", SpecialMesh = "FileMesh", FileMesh = "DataModelMesh", BlockMesh = "BevelMesh",
	BevelMesh = "DataModelMesh", CylinderMesh = "BevelMesh",
	FaceInstance = "Instance", Decal = "FaceInstance", Texture = "Decal",
	ParticleEmitter = "Instance", Beam = "Instance", Trail = "Instance", Fire = "Instance", Smoke = "Instance",
	Sparkles = "Instance", Highlight = "Instance", Sound = "Instance", SoundGroup = "Instance",
	ProximityPrompt = "Instance", ClickDetector = "Instance", Humanoid = "Instance", HumanoidDescription = "Instance",
	Animator = "Instance", Animation = "Instance", Player = "Instance",
	LuaSourceContainer = "Instance", BaseScript = "LuaSourceContainer", Script = "BaseScript",
	LocalScript = "Script", ModuleScript = "LuaSourceContainer",
	ValueBase = "Instance", StringValue = "ValueBase", NumberValue = "ValueBase", IntValue = "ValueBase",
	BoolValue = "ValueBase", ObjectValue = "ValueBase", CFrameValue = "ValueBase", Vector3Value = "ValueBase",
	RemoteEvent = "Instance", RemoteFunction = "Instance", BindableEvent = "Instance", BindableFunction = "Instance",
	Constraint = "Instance", WeldConstraint = "Instance", Weld = "JointInstance", Motor6D = "JointInstance",
	JointInstance = "Instance", MaterialVariant = "Instance",
	DataModel = "ServiceProvider", ServiceProvider = "Instance",
}

local function isA(className: string, other: string): boolean
	local current = className
	while current and current ~= "" do
		if current == other then
			return true
		end
		current = SUPER[current]
	end
	return other == "Instance"
end

-- What a property reads as before anything sets it (by class, inherited).
local GRAY = Color3.fromRGB(163, 162, 165)
local DEFAULTS: { [string]: { [string]: any } } = {
	Instance = { Archivable = true },
	BasePart = {
		Size = Vector3.new(4, 1, 2), CFrame = CFrame.identity, Transparency = 0, Reflectance = 0,
		Anchored = false, CanCollide = true, CanQuery = true, CanTouch = true, CastShadow = true,
		Color = GRAY, Material = Enum.Material.Plastic, MaterialVariant = "", Locked = false,
		Massless = false, LocalTransparencyModifier = 0, PivotOffset = CFrame.identity,
		TopSurface = Enum.SurfaceType.Smooth, BottomSurface = Enum.SurfaceType.Smooth,
	},
	Part = { Shape = Enum.PartType.Block },
	SpawnLocation = { Enabled = true, Duration = 10 },
	Light = { Brightness = 1, Range = 8, Enabled = true, Shadows = false, Color = Color3.new(1, 1, 1) },
	SpotLight = { Angle = 90, Face = Enum.NormalId.Front },
	ParticleEmitter = { Enabled = true, Rate = 5 },
	SpecialMesh = { Scale = Vector3.one, Offset = Vector3.zero },
	LayerCollector = { Enabled = true },
	BillboardGui = { StudsOffset = Vector3.zero, AlwaysOnTop = false, MaxDistance = math.huge },
	GuiObject = { Visible = true, BackgroundTransparency = 0, Rotation = 0 },
	Sound = { Volume = 0.5, PlaybackSpeed = 1, Playing = false },
	Humanoid = { WalkSpeed = 16, Health = 100, MaxHealth = 100 },
	Player = { UserId = 0 },
}

local function defaultOf(className: string, key: string): any
	local current = className
	while current and current ~= "" do
		local defaults = DEFAULTS[current]
		if defaults and defaults[key] ~= nil then
			return defaults[key]
		end
		current = SUPER[current]
	end
	local base = DEFAULTS.Instance[key]
	return base
end

-- Instances ---------------------------------------------------------------------------

export type Instance = any

local Methods = {}
Dom.Methods = Methods -- the lab adds the services' own methods
local registry = setmetatable({}, { __mode = "k" }) -- every instance -> its state
Dom.Created = 0

local function state(instance: Instance)
	return registry[instance]
end

local InstanceMeta = {}

function InstanceMeta.__index(self, key)
	local method = Methods[key]
	if method then
		return method
	end
	local data = registry[self]
	if key == "ClassName" then
		return data.ClassName
	elseif key == "Parent" then
		return data.Parent
	elseif key == "Name" then
		return data.Props.Name or data.ClassName
	elseif key == "Position" and isA(data.ClassName, "BasePart") then
		return self.CFrame.Position
	elseif key == "Orientation" and isA(data.ClassName, "BasePart") then
		local x, y, z = self.CFrame:ToOrientation()
		return Vector3.new(math.deg(x), math.deg(y), math.deg(z))
	elseif key == "WorldPivot" and isA(data.ClassName, "Model") then
		return self:GetPivot()
	end
	local value = data.Props[key]
	if value ~= nil then
		return value
	end
	for _, child in data.Children do
		if child.Name == key then
			return child
		end
	end
	local default = defaultOf(data.ClassName, key)
	if default ~= nil then
		return default
	end
	if EVENTS[key] then
		data.Events[key] = data.Events[key] or Signal.new()
		return data.Events[key]
	end
	return nil
end

function InstanceMeta.__newindex(self, key, value)
	local data = registry[self]
	if key == "Parent" then
		local old = data.Parent
		if old == value then
			return
		end
		if old then
			local siblings = registry[old].Children
			local index = table.find(siblings, self)
			if index then
				table.remove(siblings, index)
			end
		end
		data.Parent = value
		if value then
			table.insert(registry[value].Children, self)
		end
	elseif key == "Position" and isA(data.ClassName, "BasePart") then
		data.Props.CFrame = self.CFrame.Rotation + value
	elseif key == "Orientation" and isA(data.ClassName, "BasePart") then
		data.Props.CFrame = CFrame.new(self.CFrame.Position) * CFrame.fromOrientation(math.rad(value.X), math.rad(value.Y), math.rad(value.Z))
	elseif key == "WorldPivot" and isA(data.ClassName, "Model") then
		data.Pivot = value
	elseif key == "ClassName" then
		error("ClassName is read-only")
	else
		data.Props[key] = value
	end
end

function InstanceMeta.__tostring(self)
	return self.Name
end

function Dom.new(className: string, parent: Instance?): Instance
	assert(type(className) == "string", "Instance.new needs a class name")
	local instance = setmetatable({}, InstanceMeta)
	registry[instance] = {
		ClassName = className,
		Props = {},
		Children = {},
		Attributes = {},
		Tags = {},
		Events = {},
		Parent = nil,
		Pivot = nil, -- Model: its WorldPivot once set
		Scale = 1, -- Model: ScaleTo's
	}
	Dom.Created += 1
	if parent then
		instance.Parent = parent
	end
	return instance
end

function Dom.isInstance(value: any): boolean
	return type(value) == "table" and registry[value] ~= nil
end

-- Tree --------------------------------------------------------------------------------

function Methods:GetChildren()
	return table.clone(state(self).Children)
end

function Methods:GetDescendants()
	local list = {}
	local function walk(node)
		for _, child in state(node).Children do
			table.insert(list, child)
			walk(child)
		end
	end
	walk(self)
	return list
end

function Methods:FindFirstChild(name: string, recursive: boolean?)
	for _, child in state(self).Children do
		if child.Name == name then
			return child
		end
	end
	if recursive then
		for _, child in state(self).Children do
			local found = child:FindFirstChild(name, true)
			if found then
				return found
			end
		end
	end
	return nil
end

function Methods:WaitForChild(name: string)
	return self:FindFirstChild(name)
end

function Methods:FindFirstChildOfClass(className: string)
	for _, child in state(self).Children do
		if child.ClassName == className then
			return child
		end
	end
	return nil
end

function Methods:FindFirstChildWhichIsA(className: string, recursive: boolean?)
	for _, child in (if recursive then self:GetDescendants() else state(self).Children) do
		if child:IsA(className) then
			return child
		end
	end
	return nil
end

function Methods:FindFirstAncestor(name: string)
	local node = self.Parent
	while node do
		if node.Name == name then
			return node
		end
		node = node.Parent
	end
	return nil
end

function Methods:FindFirstAncestorOfClass(className: string)
	local node = self.Parent
	while node do
		if node.ClassName == className then
			return node
		end
		node = node.Parent
	end
	return nil
end

function Methods:FindFirstAncestorWhichIsA(className: string)
	local node = self.Parent
	while node do
		if node:IsA(className) then
			return node
		end
		node = node.Parent
	end
	return nil
end

function Methods:IsA(className: string): boolean
	return isA(state(self).ClassName, className)
end

function Methods:IsDescendantOf(ancestor: Instance): boolean
	local node = self.Parent
	while node do
		if node == ancestor then
			return true
		end
		node = node.Parent
	end
	return false
end

function Methods:IsAncestorOf(descendant: Instance): boolean
	return descendant:IsDescendantOf(self)
end

function Methods:GetFullName(): string
	local names = {}
	local node = self
	while node and node.ClassName ~= "DataModel" do
		table.insert(names, 1, node.Name)
		node = node.Parent
	end
	return table.concat(names, ".")
end

function Methods:Destroy()
	self.Parent = nil
	for _, child in self:GetChildren() do
		child:Destroy()
	end
	local data = state(self)
	if data.Events.Destroying then
		data.Events.Destroying:Fire()
	end
end
Methods.Remove = Methods.Destroy

function Methods:ClearAllChildren()
	for _, child in self:GetChildren() do
		child:Destroy()
	end
end

function Methods:Clone()
	local copies = {}
	local function copy(node)
		local data = state(node)
		local clone = Dom.new(data.ClassName)
		local cloneData = state(clone)
		cloneData.Props = table.clone(data.Props)
		cloneData.Attributes = table.clone(data.Attributes)
		cloneData.Tags = table.clone(data.Tags)
		cloneData.Pivot = data.Pivot
		cloneData.Scale = data.Scale
		copies[node] = clone
		for _, child in data.Children do
			copy(child).Parent = clone
		end
		return clone
	end
	local root = copy(self)
	-- references inside the copy point at the copies (PrimaryPart)
	for original, clone in copies do
		local primary = state(original).Props.PrimaryPart
		if primary and copies[primary] then
			state(clone).Props.PrimaryPart = copies[primary]
		end
	end
	return root
end

-- Attributes and tags -----------------------------------------------------------------

function Methods:SetAttribute(name: string, value: any)
	state(self).Attributes[name] = value
end

function Methods:GetAttribute(name: string)
	return state(self).Attributes[name]
end

function Methods:GetAttributes()
	return table.clone(state(self).Attributes)
end

function Methods:GetAttributeChangedSignal(_name: string)
	return Signal.new()
end

function Methods:GetPropertyChangedSignal(_name: string)
	return Signal.new()
end

-- (instance:AddTag(tag), or CollectionService:AddTag(instance, tag))
local function tagTarget(self, a, b)
	if b ~= nil and Dom.isInstance(a) then
		return a, b
	end
	return self, a
end

function Methods:AddTag(a, b)
	local target, tag = tagTarget(self, a, b)
	state(target).Tags[tag] = true
end

function Methods:RemoveTag(a, b)
	local target, tag = tagTarget(self, a, b)
	state(target).Tags[tag] = nil
end

function Methods:HasTag(a, b): boolean
	local target, tag = tagTarget(self, a, b)
	return state(target).Tags[tag] == true
end

function Methods:GetTags()
	local list = {}
	for tag in state(self).Tags do
		table.insert(list, tag)
	end
	return list
end

-- Pivots and geometry ---------------------------------------------------------------

local function parts(self): { Instance }
	local list = {}
	for _, item in self:GetDescendants() do
		if item:IsA("BasePart") then
			table.insert(list, item)
		end
	end
	return list
end

-- The box round `list` in `frame`'s axes: its middle (world) and size.
local function boxAround(list: { Instance }, frame: any): (any, any)
	local rotation = frame.Rotation
	local inverse = rotation:Inverse()
	local low = Vector3.new(math.huge, math.huge, math.huge)
	local high = -low
	for _, part in list do
		local cf, size = part.CFrame, part.Size
		local half = size / 2
		for _, sx in { -1, 1 } do
			for _, sy in { -1, 1 } do
				for _, sz in { -1, 1 } do
					local corner = inverse * cf:PointToWorldSpace(Vector3.new(half.X * sx, half.Y * sy, half.Z * sz))
					low = low:Min(corner)
					high = high:Max(corner)
				end
			end
		end
	end
	if #list == 0 then
		return CFrame.new(frame.Position) * rotation, Vector3.zero
	end
	local middle = rotation * ((low + high) / 2)
	return CFrame.new(middle) * rotation, high - low
end

function Methods:GetPivot()
	local data = state(self)
	if isA(data.ClassName, "BasePart") then
		return self.CFrame * self.PivotOffset
	end
	local primary = data.Props.PrimaryPart
	if primary and primary:IsDescendantOf(self) then
		return primary:GetPivot()
	end
	if data.Pivot then
		return data.Pivot
	end
	-- never set: the middle of its parts (Roblox's default for a built model)
	local middle = boxAround(parts(self), CFrame.identity)
	return CFrame.new(middle.Position)
end

function Methods:PivotTo(target)
	local data = state(self)
	if isA(data.ClassName, "BasePart") then
		self.CFrame = target * self.PivotOffset:Inverse()
		return
	end
	local delta = target * self:GetPivot():Inverse()
	for _, item in self:GetDescendants() do
		if item:IsA("BasePart") then
			item.CFrame = delta * item.CFrame
		elseif item:IsA("Model") and state(item).Pivot then
			state(item).Pivot = delta * state(item).Pivot
		end
	end
	if not (data.Props.PrimaryPart and data.Props.PrimaryPart:IsDescendantOf(self)) then
		data.Pivot = target
	end
end

function Methods:MoveTo(position)
	self:PivotTo(self:GetPivot().Rotation + position)
end

function Methods:TranslateBy(offset)
	self:PivotTo(self:GetPivot() + offset)
end

function Methods:SetPrimaryPartCFrame(target)
	self:PivotTo(target)
end

function Methods:GetBoundingBox()
	return boxAround(parts(self), self:GetPivot())
end

function Methods:GetExtentsSize()
	local _, size = self:GetBoundingBox()
	return size
end

function Methods:GetScale(): number
	return state(self).Scale
end

-- Grows every part (size and distance from the pivot) and the pivots of models inside.
function Methods:ScaleTo(scale: number)
	local data = state(self)
	local factor = scale / data.Scale
	local pivot = self:GetPivot().Position
	for _, item in self:GetDescendants() do
		if item:IsA("BasePart") then
			local cf = item.CFrame
			item.Size = item.Size * factor
			item.CFrame = cf.Rotation + (pivot + (cf.Position - pivot) * factor)
		elseif item:IsA("Model") and state(item).Pivot then
			local cf = state(item).Pivot
			state(item).Pivot = cf.Rotation + (pivot + (cf.Position - pivot) * factor)
		elseif item:IsA("SpecialMesh") then
			item.Scale = item.Scale * factor
		end
	end
	data.Scale = scale
end

-- Anything else a builder might call on an instance does nothing (sounds, prompts...).
for _, name in { "Play", "Stop", "Pause", "Resume", "Emit", "Kick", "LoadCharacter", "InputHoldBegin", "InputHoldEnd" } do
	Methods[name] = function() end
end

return Dom
