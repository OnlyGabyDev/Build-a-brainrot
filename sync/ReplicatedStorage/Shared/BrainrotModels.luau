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
	own head met it (in front of the body for Tralalero, on top for Sahur).

	Joints are measured, not drawn: a part's joint is the middle of where it touches its
	own body (each shoulder for two-sided arms), so every brainrot's joints mean the same
	thing whatever its art. A swapped-in part's joint goes onto the body's, and anything
	still apart (a head smaller than the one it replaces) is pulled in until it touches.
	The art's "Joint" attachments are only a fallback for parts with nothing to measure.
	Check every mix with tools/lab ("mixes", then analyze.py gaps / render.py).
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

-- Where each part meets its own body, in the brainrot's root space (unscaled): the
-- middle of where they touch. Arms whose two sides each touch the body also get a
-- shoulder per side (Left: -X, Right: +X).
type Joints = { Legs: Vector3, Head: Vector3, Arms: Vector3, ArmsLeft: Vector3?, ArmsRight: Vector3? }
-- A part's world-space bounding box (exact for unturned parts; turned ones a bit big).
type Box = { Min: Vector3, Max: Vector3, X: number }

local CONTACT = 0.06 -- boxes this close touch (voxel art packs its parts edge to edge)
local SNAP = 0.02 -- a swapped-in part further than this from the body is pulled in
local SINK = 0.1 -- a part snapped onto a body sinks this far in: a firm joint, no hairline
local SIDE = 0.05 -- arm pieces this far off the middle line are a left or a right one

local jointsCache: { [string]: Joints } = {}
local boxesCache: { [string]: { Box } } = {}
type Fit = { Offsets: { [string]: Vector3 }, Spread: number }
local fitCache: { [string]: Fit } = {}

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

-- Where a part attaches by its art's "Joint" (or its bounding box), in root space: the
-- fallback when a part has nothing to measure its contact with.
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

-- Geometry for fitting parts together ---------------------------------------------

local function boxOf(part: BasePart): Box
	local cframe, size = part.CFrame, part.Size / 2
	local r, u, b = cframe.RightVector, cframe.UpVector, cframe.LookVector
	local half = Vector3.new(
		math.abs(r.X) * size.X + math.abs(u.X) * size.Y + math.abs(b.X) * size.Z,
		math.abs(r.Y) * size.X + math.abs(u.Y) * size.Y + math.abs(b.Y) * size.Z,
		math.abs(r.Z) * size.X + math.abs(u.Z) * size.Y + math.abs(b.Z) * size.Z
	)
	return { Min = cframe.Position - half, Max = cframe.Position + half, X = cframe.Position.X }
end

-- A part's boxes in its brainrot's root space (unscaled, unstyled), built once.
local function boxesOf(brainrotId: string, partType: string): { Box }
	local key = `{brainrotId}/{partType}`
	local cached = boxesCache[key]
	if cached then
		return cached
	end
	local boxes = {}
	local model = buildRaw(brainrotId, partType)
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			table.insert(boxes, boxOf(descendant))
		end
	end
	model:Destroy()
	boxesCache[key] = boxes
	return boxes
end

-- How far apart two boxes are (0 when they touch or overlap), `a` moved by `shift`.
local function gapBetween(a: Box, shift: Vector3, b: Box): number
	local aMin, aMax = a.Min + shift, a.Max + shift
	local dx = math.max(0, aMin.X - b.Max.X, b.Min.X - aMax.X)
	local dy = math.max(0, aMin.Y - b.Max.Y, b.Min.Y - aMax.Y)
	local dz = math.max(0, aMin.Z - b.Max.Z, b.Min.Z - aMax.Z)
	return math.sqrt(dx * dx + dy * dy + dz * dz)
end

-- The middle of where `boxes` touch `body` (within `reach`), weighted by the size of
-- each touch, or nil if nothing is that close.
local function contactWithin(boxes: { Box }, body: { Box }, reach: number): Vector3?
	local sum, weight = Vector3.zero, 0
	local pad = Vector3.one * reach / 2
	for _, a in boxes do
		for _, b in body do
			if gapBetween(a, Vector3.zero, b) <= reach then
				-- the overlap of the two boxes, each grown by half the reach
				local low = (a.Min - pad):Max(b.Min - pad)
				local high = (a.Max + pad):Min(b.Max + pad)
				local size = (high - low):Max(Vector3.one * 0.01)
				local w = size.X * size.Y * size.Z
				sum += (low + high) / 2 * w
				weight += w
			end
		end
	end
	return if weight > 0 then sum / weight else nil
end

-- Where `boxes` meet `body`: their contact, or (art that floats a little) the contact
-- at the nearest distance they come to.
local function contact(boxes: { Box }, body: { Box }): Vector3?
	local found = contactWithin(boxes, body, CONTACT)
	if found or #boxes == 0 or #body == 0 then
		return found
	end
	local nearest = math.huge
	for _, a in boxes do
		for _, b in body do
			nearest = math.min(nearest, gapBetween(a, Vector3.zero, b))
		end
	end
	return contactWithin(boxes, body, nearest + CONTACT)
end

local function side(boxes: { Box }, sign: number): { Box }
	local list = {}
	for _, box in boxes do
		if box.X * sign > SIDE then
			table.insert(list, box)
		end
	end
	return list
end

local function getJoints(brainrotId: string): Joints
	local cached = jointsCache[brainrotId]
	if cached then
		return cached
	end
	local body = boxesOf(brainrotId, "Body")
	local joints = {} :: any
	for _, partType in { "Legs", "Head", "Arms" } do
		local boxes = boxesOf(brainrotId, partType)
		local point = contact(boxes, body)
		if not point then
			local model = buildRaw(brainrotId, partType)
			point = jointOf(model, partType)
			model:Destroy()
		end
		joints[partType] = point
	end
	-- arms that hold on to the body on both sides fit by each shoulder
	local left = contactWithin(side(boxesOf(brainrotId, "Arms"), -1), body, CONTACT)
	local right = contactWithin(side(boxesOf(brainrotId, "Arms"), 1), body, CONTACT)
	if left and right then
		joints.ArmsLeft, joints.ArmsRight = left, right
	end
	jointsCache[brainrotId] = joints
	return joints
end

-- The smallest move that makes `boxes` (moved by `shift`) touch `body` (moved by
-- `bodyShift`), sinking SINK into it; zero if they already touch.
local function closeGap(boxes: { Box }, shift: Vector3, body: { Box }, bodyShift: Vector3): Vector3
	local best, nearest, target = math.huge, nil :: Box?, nil :: Box?
	for _, a in boxes do
		for _, b in body do
			local gap = gapBetween(a, shift - bodyShift, b)
			if gap < best then
				best, nearest, target = gap, a, b
			end
		end
	end
	if best <= SNAP or not (nearest and target) then
		return Vector3.zero
	end
	local aMin, aMax = nearest.Min + shift, nearest.Max + shift
	local bMin, bMax = target.Min + bodyShift, target.Max + bodyShift
	local function axis(lowA: number, highA: number, lowB: number, highB: number): number
		if highA < lowB then
			return lowB - highA
		elseif lowA > highB then
			return highB - lowA
		end
		return 0
	end
	local move = Vector3.new(axis(aMin.X, aMax.X, bMin.X, bMax.X), axis(aMin.Y, aMax.Y, bMin.Y, bMax.Y), axis(aMin.Z, aMax.Z, bMin.Z, bMax.Z))
	return move + move.Unit * SINK
end

-- Moves an Arms model's two sides apart (`spread` > 0) or together, in root space.
local function spreadArms(model: Model, spread: number)
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			local x = descendant.Position.X
			if math.abs(x) > SIDE then
				descendant.CFrame += Vector3.new(if x > 0 then spread else -spread, 0, 0)
			end
		end
	end
end

-- Where each part of a build goes (unscaled) and how far its arms spread. The legs
-- stand on the root; the body sits where its own legs meet it on the new legs; the
-- head and arms meet the body where its own did (by shoulder, for two-sided arms);
-- then anything still apart is pulled in until it touches.
local function fit(parts: { [string]: string }): Fit
	local key = `{parts.Legs}|{parts.Body}|{parts.Arms}|{parts.Head}`
	local cached = fitCache[key]
	if cached then
		return cached
	end
	local offsets = { Legs = Vector3.zero, Body = Vector3.zero, Arms = Vector3.zero, Head = Vector3.zero }
	local spread = 0
	local bodyId = parts.Body
	if bodyId then
		local body = getJoints(bodyId)
		local bodyBoxes = boxesOf(bodyId, "Body")
		local legsId = parts.Legs
		if legsId and legsId ~= bodyId then
			offsets.Body = getJoints(legsId).Legs - body.Legs
			-- the body moves onto the legs (the legs stay on the ground)
			offsets.Body -= closeGap(boxesOf(legsId, "Legs"), Vector3.zero, bodyBoxes, offsets.Body)
		end
		offsets.Head, offsets.Arms = offsets.Body, offsets.Body
		local headId = parts.Head
		if headId and headId ~= bodyId then
			local shift = offsets.Body + body.Head - getJoints(headId).Head
			offsets.Head = shift + closeGap(boxesOf(headId, "Head"), shift, bodyBoxes, offsets.Body)
		end
		local armsId = parts.Arms
		if armsId and armsId ~= bodyId then
			local own = getJoints(armsId)
			local boxes = boxesOf(armsId, "Arms")
			if body.ArmsLeft and body.ArmsRight and own.ArmsLeft and own.ArmsRight then
				-- each shoulder onto the body's: one move for both, plus the spread
				local toLeft = offsets.Body + body.ArmsLeft - own.ArmsLeft
				local toRight = offsets.Body + body.ArmsRight - own.ArmsRight
				local shift = (toLeft + toRight) / 2
				spread = (toRight.X - toLeft.X) / 2
				local moveLeft = closeGap(side(boxes, -1), shift - Vector3.new(spread, 0, 0), bodyBoxes, offsets.Body)
				local moveRight = closeGap(side(boxes, 1), shift + Vector3.new(spread, 0, 0), bodyBoxes, offsets.Body)
				offsets.Arms = shift + (moveLeft + moveRight) / 2
				spread += (moveRight.X - moveLeft.X) / 2
			else
				local shift = offsets.Body + body.Arms - own.Arms
				offsets.Arms = shift + closeGap(boxes, shift, bodyBoxes, offsets.Body)
			end
		end
	end
	local result = { Offsets = offsets, Spread = spread }
	fitCache[key] = result
	return result
end

-- Returns the part model (pivot = brainrot root) plus the part's center and size in
-- root space, for moving it on its own (e.g. dropping it onto a belt). `spread` (Arms,
-- from Layout) moves its two sides apart to reach another brainrot's shoulders.
function BrainrotModels.CreatePart(brainrotId: string, partType: string, zoneId: string?, spread: number?): (Model, Vector3, Vector3)
	local model = buildRaw(brainrotId, partType)
	if spread and spread ~= 0 and partType == "Arms" then
		spreadArms(model, spread)
	end
	applyStyle(model, zoneId)
	local center, size = model:GetBoundingBox()
	return model, center.Position, size
end

-- Where each part of a build ([partType] = brainrotId) goes: offsets from the brainrot
-- root (root space, scaled for the zone's edition), and the arms' spread to pass to
-- CreatePart (unscaled: CreatePart scales it with the part). Parts from the body's own
-- brainrot keep their places (zero offsets, no spread).
function BrainrotModels.Layout(parts: { [string]: string }, zoneId: string?): ({ [string]: Vector3 }, number)
	local result = fit(parts)
	local zone = zoneId and Zones.ById[zoneId]
	local scale = if zone then zone.Style.Scale else 1
	local offsets = {}
	for partType, offset in result.Offsets do
		offsets[partType] = offset * scale
	end
	return offsets, result.Spread
end

return BrainrotModels
