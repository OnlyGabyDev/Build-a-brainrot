--[[
	Voxel art preview (Studio MCP, execute_luau in Edit mode). Paste the whole file as
	the code, after editing IDS (and MIXES, for mixed-part builds).

	Builds each brainrot side by side from x = 300 in Workspace.ArtPreview, and
	reports its size, part count, and where two of its parts flicker: faces of
	different parts in the same plane, facing the same way, in different colors
	(fix them). Blocks of one part reaching into another are fine (legs up into a
	body), and so are faces 0.02 studs apart (Tralalero's run in game without
	flicker). Rotated blocks aren't checked. It requires a fresh clone of Shared, so
	edits synced by Azul always show (Studio caches a module after its first require).

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

local PLANE = 0.01 -- studs: faces closer than this share a plane
local AXES = { { "X", "Y", "Z" }, { "Y", "Z", "X" }, { "Z", "X", "Y" } } -- (the normal, then the face's two sides)

local function aligned(part: BasePart): boolean
	return part:IsA("Part") and part.Shape == Enum.PartType.Block and part.CFrame.Rotation:FuzzyEq(CFrame.identity, 1e-4)
end

-- The area (studs²) where faces of two unrotated blocks share a plane and face the same way.
local function sharedFaces(a: BasePart, b: BasePart): number
	local ca, ha, cb, hb = a.Position :: any, (a.Size / 2) :: any, b.Position :: any, (b.Size / 2) :: any
	local area = 0
	for _, axes in AXES do
		local n, u, v = axes[1], axes[2], axes[3]
		local du = math.min(ca[u] + ha[u], cb[u] + hb[u]) - math.max(ca[u] - ha[u], cb[u] - hb[u])
		local dv = math.min(ca[v] + ha[v], cb[v] + hb[v]) - math.max(ca[v] - ha[v], cb[v] - hb[v])
		if du > PLANE and dv > PLANE then
			for _, sign in { 1, -1 } do
				if math.abs((ca[n] + sign * ha[n]) - (cb[n] + sign * hb[n])) < PLANE then
					area += du * dv
				end
			end
		end
	end
	return area
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
	local flickers = {}
	for a = 1, #parts do
		for b = a + 1, #parts do
			local area = 0
			for _, pa in parts[a]:GetChildren() do
				for _, pb in parts[b]:GetChildren() do
					if pa:IsA("BasePart") and pb:IsA("BasePart") and aligned(pa) and aligned(pb) and (pa.Color ~= pb.Color or pa.Material ~= pb.Material) then
						area += sharedFaces(pa, pb)
					end
				end
			end
			if area > 0 then
				table.insert(flickers, `{parts[a].Name}/{parts[b].Name} {string.format("%.2f", area)} studs²`)
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
	local flickerText = if #flickers > 0 then table.concat(flickers, ", ") else "none"
	table.insert(out, `{id} at x={300 + (i - 1) * SPACING}: {count} parts, size {size}, flicker: {flickerText}`)
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
