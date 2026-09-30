--[[
	Voxel art preview (Studio MCP, execute_luau in Edit mode). Paste the whole file as
	the code, after editing IDS (and MIXES, for mixed-part builds).

	Builds each brainrot side by side from x = 300 in Workspace.ArtPreview, and
	reports its size, part count, and any voxels where two of its parts overlap
	(overlaps flicker: fix them). It requires a fresh clone of Shared, so edits
	synced by Azul always show (Studio caches a module after its first require).

	Camera for one brainrot at x: screen_capture from (x + 3, 4.5, -7.5) looking at
	(x, 3.2, 0). Delete Workspace.ArtPreview when done (the last line of the output
	reminds you).
]]

local IDS = { "BrrBrrPatapim", "LiriliLarila", "TrippiTroppi" }
-- Optional mixed builds, placed after the brainrots: { Legs = id, Body = id, Arms = id, Head = id }
local MIXES = {}

local SPACING = 9
local shared = game:GetService("ReplicatedStorage").Shared:Clone()
shared.Name = "SharedPreviewTmp"
shared.Parent = game:GetService("ServerStorage")
local VoxelArt = require(shared.VoxelArt) :: any
local BrainrotModels = require(shared.BrainrotModels) :: any

local old = workspace:FindFirstChild("ArtPreview")
if old then
	old:Destroy()
end
local folder = Instance.new("Folder")
folder.Name = "ArtPreview"
folder.Parent = workspace

local function overlap(a: BasePart, b: BasePart): number
	local d = (a.Position + a.Size / 2):Min(b.Position + b.Size / 2) - (a.Position - a.Size / 2):Max(b.Position - b.Size / 2)
	return if d.X > 0.01 and d.Y > 0.01 and d.Z > 0.01 then d.X * d.Y * d.Z else 0
end

local out = {}
for i, id in IDS do
	local ok, art = pcall(require, shared.Art[id])
	if not ok then
		table.insert(out, `{id}: ERROR {art}`)
		continue
	end
	local model = Instance.new("Model")
	model.Name = id
	local parts = {}
	for _, partType in { "Legs", "Body", "Arms", "Head" } do
		local part = VoxelArt.Build(art, partType)
		if part then
			part.Parent = model
			table.insert(parts, part)
		end
	end
	local overlaps = {}
	for a = 1, #parts do
		for b = a + 1, #parts do
			local volume = 0
			for _, pa in parts[a]:GetChildren() do
				for _, pb in parts[b]:GetChildren() do
					if pa:IsA("BasePart") and pb:IsA("BasePart") then
						volume += overlap(pa, pb)
					end
				end
			end
			if volume > 0 then
				table.insert(overlaps, `{parts[a].Name}/{parts[b].Name} {math.round(volume / art.VoxelSize ^ 3)} voxels`)
			end
		end
	end
	model.WorldPivot = CFrame.identity -- the root, not the bounding box (or it sinks)
	model.Parent = folder
	model:PivotTo(CFrame.new(300 + (i - 1) * SPACING, 0, 0))
	local _, size = model:GetBoundingBox()
	local count = 0
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			count += 1
		end
	end
	local overlapText = if #overlaps > 0 then table.concat(overlaps, ", ") else "none"
	table.insert(out, `{id} at x={300 + (i - 1) * SPACING}: {count} parts, size {size}, overlaps: {overlapText}`)
end

for i, build in MIXES do
	local x = 300 + (#IDS + i - 1) * SPACING
	local offsets = BrainrotModels.Layout(build)
	local model = Instance.new("Model")
	model.Name = `Mix{i}`
	for partType, id in build do
		local part = BrainrotModels.CreatePart(id, partType)
		part:PivotTo(CFrame.new(Vector3.new(x, 0, 0) + offsets[partType]))
		part.Parent = model
	end
	model.Parent = folder
	table.insert(out, `Mix{i} at x={x}`)
end

shared:Destroy()
table.insert(out, "Delete Workspace.ArtPreview when done.")
return table.concat(out, "\n")
