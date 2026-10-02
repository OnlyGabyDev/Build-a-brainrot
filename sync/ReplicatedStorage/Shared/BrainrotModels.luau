--[[
	BrainrotModels
	Builds one part of a brainrot (Head/Body/Arms/Legs) as a Model, styled for a zone's
	edition. In order: the split model in ReplicatedStorage/Assets/Brainrots/<Id> if
	one exists, its voxel art in Shared/Art/<Id> (VoxelArt), or colored placeholder
	blocks (GDD §3).

	Every returned model's pivot is the brainrot's root (on the ground between the feet,
	facing -Z), so model:PivotTo(rootCFrame) puts the part exactly where it belongs in
	its own brainrot. For brainrots built from mixed parts, Layout says where each part
	goes instead: the body anchors the build, so a head always lands where that body's
	own head would be (in front of the body for Tralalero, on top for Sahur).

	Joints: a part can mark where it attaches with an Attachment named "Joint" (Legs:
	the hip the body sits on; Head and Arms: the point that meets the body). Without
	one, the joint comes from the part's bounding box.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Brainrots = require(script.Parent.Config.Brainrots)
local VoxelArt = require(script.Parent.VoxelArt)
local Zones = require(script.Parent.Config.Zones)

-- Voxel art is built once per part and cloned after that (false = no art).
local artTemplates: { [string]: Model | false } = {}

local FACE_TEXTURE = "rbxasset://textures/face.png"

-- Placeholder shapes in root space (unscaled studs): { shape, size, position }.
local PLACEHOLDERS = {
	Head = {
		{ Enum.PartType.Ball, Vector3.new(2.6, 2.6, 2.6), Vector3.new(0, 5.5, 0) },
	},
	Body = {
		{ Enum.PartType.Block, Vector3.new(2.6, 2.4, 1.6), Vector3.new(0, 3, 0) },
	},
	Arms = {
		{ Enum.PartType.Block, Vector3.new(0.8, 2.2, 0.8), Vector3.new(-1.75, 3, 0) },
		{ Enum.PartType.Block, Vector3.new(0.8, 2.2, 0.8), Vector3.new(1.75, 3, 0) },
	},
	Legs = {
		{ Enum.PartType.Block, Vector3.new(0.9, 1.8, 0.9), Vector3.new(-0.6, 0.9, 0) },
		{ Enum.PartType.Block, Vector3.new(0.9, 1.8, 0.9), Vector3.new(0.6, 0.9, 0) },
	},
}

-- Joint positions in a brainrot's own root space (unscaled).
type Joints = { Hip: Vector3, Head: Vector3, Arms: Vector3 }

local jointsCache: { [string]: Joints } = {}

local BrainrotModels = {}

local function buildPlaceholder(brainrotId: string, partType: string): Model
	local brainrot = Brainrots.ById[brainrotId]
	local model = Instance.new("Model")
	model.Name = partType

	for _, shape in PLACEHOLDERS[partType] do
		local part = Instance.new("Part")
		part.Shape = shape[1]
		part.Size = shape[2]
		part.CFrame = CFrame.new(shape[3])
		part.Color = if brainrot then brainrot.Color else Color3.new(1, 1, 1)
		part.Material = Enum.Material.SmoothPlastic
		part.TopSurface = Enum.SurfaceType.Smooth
		part.BottomSurface = Enum.SurfaceType.Smooth
		part.Parent = model

		if partType == "Head" then
			local face = Instance.new("Decal")
			face.Face = Enum.NormalId.Front
			face.Texture = FACE_TEXTURE
			face.Parent = part
		end
	end

	model.WorldPivot = CFrame.identity
	return model
end

local function cloneFromAsset(brainrotId: string, partType: string): Model?
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	local folder = assets and assets:FindFirstChild("Brainrots")
	local source = folder and folder:FindFirstChild(brainrotId)
	local piece = source and source:FindFirstChild(partType)
	if not (source and source:IsA("Model") and piece and piece:IsA("PVInstance")) then
		return nil
	end

	local pieceWorld = piece:GetPivot()
	local clone = piece:Clone()
	local model: Model
	if clone:IsA("Model") then
		model = clone
	else
		model = Instance.new("Model")
		clone.Parent = model
	end
	model.Name = partType
	-- Re-express the piece relative to the brainrot's root, then make the root the pivot.
	model.WorldPivot = pieceWorld
	model:PivotTo(source:GetPivot():Inverse() * pieceWorld)
	model.WorldPivot = CFrame.identity
	return model
end

local function applyStyle(model: Model, zoneId: string?)
	local zone = zoneId and Zones.ById[zoneId]
	local style = zone and zone.Style

	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = false
			descendant.CanQuery = false
			descendant.CanTouch = false
			if style and style.Material then
				descendant.Material = style.Material
			end
			if style and style.MaterialVariant then
				descendant.MaterialVariant = style.MaterialVariant
			end
			if style and style.Reflectance then
				descendant.Reflectance = style.Reflectance
			end
			if style and style.Transparency then
				descendant.Transparency = style.Transparency
			end
		end
	end

	if style and style.Scale ~= 1 then
		model:ScaleTo(style.Scale)
	end
end

local function buildFromArt(brainrotId: string, partType: string): Model?
	local key = `{brainrotId}/{partType}`
	local template = artTemplates[key]
	if template == nil then
		template = false
		local folder = script.Parent:FindFirstChild("Art")
		local module = folder and folder:FindFirstChild(brainrotId)
		if module and module:IsA("ModuleScript") then
			local ok, art = pcall(require, module)
			if ok then
				template = VoxelArt.Build(art, partType) or false
			else
				warn(`[BrainrotModels] Art for {brainrotId} failed to load: {art}`)
			end
		end
		artTemplates[key] = template
	end
	return if template then template:Clone() else nil
end

local function buildRaw(brainrotId: string, partType: string): Model
	return cloneFromAsset(brainrotId, partType)
		or buildFromArt(brainrotId, partType)
		or buildPlaceholder(brainrotId, partType)
end

-- Where a part attaches, in root space. The model's pivot is the root at the origin.
local function jointOf(model: Model, partType: string): Vector3
	local joint = model:FindFirstChild("Joint", true)
	if joint and joint:IsA("Attachment") then
		return joint.WorldPosition
	end
	local box, size = model:GetBoundingBox()
	if partType == "Legs" then
		return box.Position + Vector3.new(0, size.Y / 2, 0) -- the hip, on top of the legs
	end
	return box.Position
end

local function getJoints(brainrotId: string): Joints
	local cached = jointsCache[brainrotId]
	if cached then
		return cached
	end
	local joints = {} :: any
	for partType, key in { Legs = "Hip", Head = "Head", Arms = "Arms" } do
		local model = buildRaw(brainrotId, partType)
		joints[key] = jointOf(model, partType)
		model:Destroy()
	end
	jointsCache[brainrotId] = joints
	return joints
end

-- Returns the part model (pivot = brainrot root) plus the part's center and size in
-- root space, for moving it on its own (e.g. dropping it onto a belt).
function BrainrotModels.CreatePart(brainrotId: string, partType: string, zoneId: string?): (Model, Vector3, Vector3)
	local model = buildRaw(brainrotId, partType)
	applyStyle(model, zoneId)
	local center, size = model:GetBoundingBox()
	return model, center.Position, size
end

-- Offsets from the brainrot root (root space, scaled for the zone's edition) that
-- place each part of a build ([partType] = brainrotId). The legs stand on the root,
-- the body sits on their hip, and the head and arms go where the body's own head and
-- arms would be. Parts from the body's own brainrot get a zero offset.
function BrainrotModels.Layout(parts: { [string]: string }, zoneId: string?): { [string]: Vector3 }
	local offsets = { Legs = Vector3.zero, Body = Vector3.zero, Arms = Vector3.zero, Head = Vector3.zero }
	local bodyId = parts.Body
	if bodyId then
		local body = getJoints(bodyId)
		if parts.Legs then
			offsets.Body = getJoints(parts.Legs).Hip - body.Hip
		end
		for _, partType in { "Head", "Arms" } do
			local id = parts[partType]
			if id then
				local own = getJoints(id) :: any
				offsets[partType] = offsets.Body + (body :: any)[partType] - own[partType]
			end
		end
	end

	local zone = zoneId and Zones.ById[zoneId]
	local scale = if zone then zone.Style.Scale else 1
	for partType, offset in offsets do
		offsets[partType] = offset * scale
	end
	return offsets
end

return BrainrotModels
