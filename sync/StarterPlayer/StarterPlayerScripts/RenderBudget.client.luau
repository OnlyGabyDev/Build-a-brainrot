--[[
	RenderBudget
	Always-on render savings that change nothing you can see (the Lower Graphics setting
	is the one that trades looks for FPS: LowGraphics). On the world (Tycoons, Hub),
	including what's built or streamed in later:
	  * SurfaceGuis (signs, posters, labels: each one is a texture of its own to draw)
	    stop drawing once they're too far to read: READABLE times the size of their face
	    (a big sign over a door is still drawn from across the map, a sticker on a chute
	    only from its room); and
	  * parts whose shadow nobody would notice stop casting one: glowing Neon, mostly
	    see-through parts and tiny details (bulbs, flowers, rivets). Every caster is drawn
	    again for the shadows, and the factories have tens of thousands of parts.
	Builders can opt a part back in with the attribute KeepShadow = true. A part TycoonFX
	has shrunk to pop it in carries its real size in its PopSize attribute.
	Client only.
]]

local RunService = game:GetService("RunService")

local READABLE = 40 -- a face this many times its size away is too small to read
local GUI_DISTANCE = NumberRange.new(100, 600) -- studs
local TINY = 0.8 -- studs: a part this small in every direction casts no shadow
local SEE_THROUGH = 0.5
local WORLD_ROOTS = { Tycoons = true, Hub = true }
local BATCH = 3000 -- instances per frame in the first pass (no hitch while it runs)

local function sizeOf(part: BasePart): Vector3
	local popping = part:GetAttribute("PopSize")
	return if typeof(popping) == "Vector3" then popping else part.Size
end

-- How far a SurfaceGui can be read from, by the size of the face it's on.
local function readableFrom(gui: SurfaceGui): number?
	local part = gui.Adornee or gui.Parent
	if not (part and part:IsA("BasePart")) then
		return nil
	end
	local size = sizeOf(part)
	local face = gui.Face
	local width, height
	if face == Enum.NormalId.Front or face == Enum.NormalId.Back then
		width, height = size.X, size.Y
	elseif face == Enum.NormalId.Left or face == Enum.NormalId.Right then
		width, height = size.Z, size.Y
	else
		width, height = size.X, size.Z
	end
	return math.clamp(math.max(width, height) * READABLE, GUI_DISTANCE.Min, GUI_DISTANCE.Max)
end

local function trim(instance: Instance)
	if instance:IsA("BasePart") then
		if instance.CastShadow and not instance:GetAttribute("KeepShadow") then
			local size = sizeOf(instance)
			if instance.Material == Enum.Material.Neon or instance.Transparency >= SEE_THROUGH or math.max(size.X, size.Y, size.Z) <= TINY then
				instance.CastShadow = false
			end
		end
	elseif instance:IsA("SurfaceGui") then
		local distance = readableFrom(instance)
		-- (0 means no limit; a builder's own, shorter one stays)
		if distance and (instance.MaxDistance == 0 or instance.MaxDistance > distance) then
			instance.MaxDistance = distance
		end
	end
end

local function watch(root: Instance)
	if not WORLD_ROOTS[root.Name] then
		return
	end
	root.DescendantAdded:Connect(trim)
	task.spawn(function()
		for index, instance in root:GetDescendants() do
			trim(instance)
			if index % BATCH == 0 then
				RunService.Heartbeat:Wait()
			end
		end
	end)
end

for _, root in workspace:GetChildren() do
	watch(root)
end
workspace.ChildAdded:Connect(watch)
