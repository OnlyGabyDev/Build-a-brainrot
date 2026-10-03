--[[
	Mover
	A cheaper Model:PivotTo for models that move every frame as one rigid piece (a
	brainrot riding a belt, the conveyor's packages, the toy train's cars). PivotTo walks
	the model's descendants and fires every moved part's Position/Orientation/CFrame
	change events each call; this keeps each model's parts and their offsets from its
	pivot, and moves them all with one workspace:BulkMoveTo that only fires CFrame
	changes.

	The cache is only right while the parts hold still relative to each other, so it is
	rebuilt whenever the model's scale changes (a squish is ScaleTo) or a part is added
	or removed (a sticker stuck on); anything else that moves a part inside the model
	on its own must call Mover.Forget(model) first, or use PivotTo. Client only.
]]

type Cache = {
	Parts: { BasePart },
	Offsets: { CFrame },
	Scale: number,
	Dirty: boolean,
	Connections: { RBXScriptConnection },
}

local caches: { [Model]: Cache } = setmetatable({}, { __mode = "k" }) :: any
local targets: { CFrame } = {}

local Mover = {}

local function forget(model: Model)
	local cache = caches[model]
	if cache then
		for _, connection in cache.Connections do
			connection:Disconnect()
		end
		caches[model] = nil
	end
end

local function build(model: Model): Cache
	forget(model)
	local pivot = model:GetPivot()
	local cache: Cache = { Parts = {}, Offsets = {}, Scale = model:GetScale(), Dirty = false, Connections = {} }
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			table.insert(cache.Parts, descendant)
			table.insert(cache.Offsets, pivot:ToObjectSpace(descendant.CFrame))
		end
	end
	local function dirty(instance: Instance)
		if instance:IsA("BasePart") then
			cache.Dirty = true
		end
	end
	table.insert(cache.Connections, model.DescendantAdded:Connect(dirty))
	table.insert(cache.Connections, model.DescendantRemoving:Connect(dirty))
	table.insert(cache.Connections, model.Destroying:Connect(function()
		forget(model)
	end))
	caches[model] = cache
	return cache
end

-- Puts `model`'s pivot at `cframe`, like model:PivotTo(cframe).
function Mover.PivotTo(model: Model, cframe: CFrame)
	if not model:IsDescendantOf(workspace) then
		model:PivotTo(cframe) -- (BulkMoveTo only moves parts in the world)
		return
	end
	local cache = caches[model]
	if not cache or cache.Dirty or cache.Scale ~= model:GetScale() then
		cache = build(model)
	end
	local count = #cache.Parts
	for index = 1, count do
		targets[index] = cframe * cache.Offsets[index]
	end
	for index = count + 1, #targets do
		targets[index] = nil
	end
	workspace:BulkMoveTo(cache.Parts, targets, Enum.BulkMoveMode.FireCFrameChanged)
	model.WorldPivot = cframe
end

-- Drops what's cached for `model` (call it after moving a part inside it on your own).
function Mover.Forget(model: Model)
	forget(model)
end

return Mover
