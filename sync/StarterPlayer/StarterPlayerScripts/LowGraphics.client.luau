--[[
	LowGraphics
	Applies the Lower Graphics setting (Client/Performance) to this client's world (its
	switch is in the ⚙️ Settings menu: Client/UI/SettingsMenu).
	On: no shadows, bloom or sun rays; the factories' and the hub's particles and lights
	off; the hub's small decor (tagged "Detail" by MapBuilder) hidden, including what
	streams in later. Everything it changes is remembered, so switching it off puts it
	all back. Client only.
]]

local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Client = ReplicatedStorage:WaitForChild("Client")
local Performance = require(Client:WaitForChild("Performance"))

local WORLD_ROOTS = { Tycoons = true, Hub = true } -- (not Effects or the loot boxes: gameplay)
local POST_EFFECTS = { "BloomEffect", "SunRaysEffect", "DepthOfFieldEffect", "BlurEffect" }
local QUIET_CLASSES = { "ParticleEmitter", "Light", "Fire", "Smoke", "Sparkles", "Beam", "Trail" }
local DETAIL = "Detail"

-- Every property changed, with the value it had, to put back when it's switched off.
local saved: { [Instance]: { [string]: any } } = {}

local function set(instance: Instance, property: string, value: any)
	local before = saved[instance]
	if not before then
		before = {}
		saved[instance] = before
	end
	if before[property] == nil then
		before[property] = (instance :: any)[property]
	end
	(instance :: any)[property] = value
end

local function restoreAll()
	for instance, properties in saved do
		for property, value in properties do
			pcall(function() -- (it may have been destroyed since)
				(instance :: any)[property] = value
			end)
		end
	end
	table.clear(saved)
end

local function isQuietClass(instance: Instance): boolean
	for _, class in QUIET_CLASSES do
		if instance:IsA(class) then
			return true
		end
	end
	return false
end

-- Inside something tagged Detail (or tagged itself)?
local function isDetail(instance: Instance): boolean
	local node: Instance? = instance
	while node and node ~= workspace do
		if CollectionService:HasTag(node, DETAIL) then
			return true
		end
		node = node.Parent
	end
	return false
end

-- One instance of the world, as Low Performance wants it.
local function lower(instance: Instance)
	if isQuietClass(instance) then
		set(instance, "Enabled", false)
	elseif (instance:IsA("BasePart") or instance:IsA("Decal")) and isDetail(instance) then
		set(instance, "LocalTransparencyModifier", 1)
	elseif (instance:IsA("SurfaceGui") or instance:IsA("BillboardGui")) and isDetail(instance) then
		set(instance, "Enabled", false)
	end
end

local function lowerLighting()
	set(Lighting, "GlobalShadows", false)
	for _, effect in Lighting:GetChildren() do
		if table.find(POST_EFFECTS, effect.ClassName) then
			set(effect, "Enabled", false)
		end
	end
end

local function lowerAll()
	lowerLighting()
	for _, root in workspace:GetChildren() do
		if WORLD_ROOTS[root.Name] then
			for _, instance in root:GetDescendants() do
				lower(instance)
			end
		end
	end
end

-- What arrives later (built, streamed in, or the lighting Atmosphere sets up).
local function watchRoot(root: Instance)
	if WORLD_ROOTS[root.Name] then
		root.DescendantAdded:Connect(function(instance)
			if Performance.Low then
				lower(instance)
			end
		end)
	end
end
for _, root in workspace:GetChildren() do
	watchRoot(root)
end
workspace.ChildAdded:Connect(function(root)
	watchRoot(root)
	if Performance.Low and WORLD_ROOTS[root.Name] then
		for _, instance in root:GetDescendants() do
			lower(instance)
		end
	end
end)
Lighting.ChildAdded:Connect(function()
	if Performance.Low then
		lowerLighting()
	end
end)

local function apply(low: boolean)
	if low then
		lowerAll()
	else
		restoreAll()
	end
end

Performance.Changed:Connect(apply)
if Performance.Low then
	task.defer(apply, true) -- (after Atmosphere has set the lighting up)
end
