--[[
	VoxelArt
	Builds brainrot parts as chunky voxel toys (GDD §3, art plan): each part is a list
	of shapes (boxes, balls, vertical cylinders) in voxel units, painted from a palette.
	The shapes are voxelized, then neighbouring voxels of the same color are merged
	into as few blocks as possible, so a whole brainrot stays cheap to render.

	Coordinates are in voxels, continuous: X is left/right (0 = the center line), Y is
	up (0 = the ground under the feet), -Z is the front. A voxel is filled when its
	center is inside a shape; later shapes paint over earlier ones, carve shapes cut
	holes, and paint shapes only recolor voxels that are already filled. Each part is voxelized on its own, so parts look whole when shown alone
	(keep different parts from overlapping, or the shared faces flicker).

	Art modules live in Shared/Art/<BrainrotId> and use the constructors below:
	  local V = require(ReplicatedStorage.Shared.VoxelArt)
	  return {
	      VoxelSize = 0.3,
	      Palette = { Skin = Color3.fromRGB(...), ... },
	      Parts = {
	          Head = { V.ball(0, 14, -6, 3, 3, 3, "Skin"), V.mirror(V.box(...)) },
	          ...
	      },
	  }
]]

export type Shape = {
	Kind: string, -- "Box" | "Ball" | "Cylinder"
	Color: string, -- a Palette key, or "" for a carve
	Carve: boolean,
	Paint: boolean?, -- recolors filled voxels only (stripes and spots on curved surfaces)
	Min: Vector3, -- Box: corners; Ball/Cylinder: bounds (for the grid)
	Max: Vector3,
	Center: Vector3?, -- Ball/Cylinder (Cylinder ignores Y)
	Radius: Vector3?, -- Ball: radii; Cylinder: X/Z radii
}

export type Art = {
	VoxelSize: number,
	Palette: { [string]: Color3 },
	Material: Enum.Material?, -- defaults to SmoothPlastic
	Materials: { [string]: Enum.Material }?, -- per palette key (e.g. Neon for glowing bits)
	Parts: { [string]: { Shape } },
	-- Where a part attaches, in voxels, for parts whose bounding box would mislead
	-- (antennae, a hanging trunk). Same meaning as BrainrotModels' "Joint".
	Joints: { [string]: Vector3 }?,
}

local VoxelArt = {}

-- Shapes -----------------------------------------------------------------------

-- A box between two corners.
function VoxelArt.box(x0: number, y0: number, z0: number, x1: number, y1: number, z1: number, color: string): Shape
	return {
		Kind = "Box",
		Color = color,
		Carve = false,
		Min = Vector3.new(math.min(x0, x1), math.min(y0, y1), math.min(z0, z1)),
		Max = Vector3.new(math.max(x0, x1), math.max(y0, y1), math.max(z0, z1)),
	}
end

-- An ellipsoid with its center and radii.
function VoxelArt.ball(cx: number, cy: number, cz: number, rx: number, ry: number, rz: number, color: string): Shape
	local center, radius = Vector3.new(cx, cy, cz), Vector3.new(rx, ry, rz)
	return { Kind = "Ball", Color = color, Carve = false, Min = center - radius, Max = center + radius, Center = center, Radius = radius }
end

-- An upright cylinder (or elliptic prism) from y0 to y1.
function VoxelArt.cylinder(cx: number, cz: number, rx: number, rz: number, y0: number, y1: number, color: string): Shape
	local center, radius = Vector3.new(cx, 0, cz), Vector3.new(rx, 0, rz)
	return {
		Kind = "Cylinder",
		Color = color,
		Carve = false,
		Min = Vector3.new(cx - rx, math.min(y0, y1), cz - rz),
		Max = Vector3.new(cx + rx, math.max(y0, y1), cz + rz),
		Center = center,
		Radius = radius,
	}
end

-- The same shape cutting a hole instead of painting.
function VoxelArt.carve(shape: Shape): Shape
	local copy = table.clone(shape)
	copy.Carve = true
	copy.Color = ""
	return copy
end

-- The same shape recoloring only voxels that are already filled.
function VoxelArt.paint(shape: Shape): Shape
	local copy = table.clone(shape)
	copy.Paint = true
	return copy
end

-- The same shape mirrored left/right (for symmetric features).
function VoxelArt.mirror(shape: Shape): Shape
	local copy = table.clone(shape)
	copy.Min = Vector3.new(-shape.Max.X, shape.Min.Y, shape.Min.Z)
	copy.Max = Vector3.new(-shape.Min.X, shape.Max.Y, shape.Max.Z)
	if shape.Center then
		copy.Center = Vector3.new(-shape.Center.X, shape.Center.Y, shape.Center.Z)
	end
	return copy
end

local function contains(shape: Shape, p: Vector3): boolean
	if p.X < shape.Min.X or p.X > shape.Max.X or p.Y < shape.Min.Y or p.Y > shape.Max.Y or p.Z < shape.Min.Z or p.Z > shape.Max.Z then
		return false
	end
	if shape.Kind == "Box" then
		return true
	end
	local center, radius = shape.Center :: Vector3, shape.Radius :: Vector3
	local dx, dz = (p.X - center.X) / radius.X, (p.Z - center.Z) / radius.Z
	if shape.Kind == "Cylinder" then
		return dx * dx + dz * dz <= 1
	end
	local dy = (p.Y - center.Y) / radius.Y
	return dx * dx + dy * dy + dz * dz <= 1
end

-- Building ---------------------------------------------------------------------

-- Voxelizes one part's shapes into a grid of palette keys.
local function voxelize(shapes: { Shape }): (Vector3, Vector3, { [number]: string })
	local low = Vector3.new(math.huge, math.huge, math.huge)
	local high = -low
	for _, shape in shapes do
		if not shape.Carve and not shape.Paint then
			low = low:Min(shape.Min)
			high = high:Max(shape.Max)
		end
	end
	local origin = Vector3.new(math.floor(low.X), math.floor(low.Y), math.floor(low.Z))
	local size = Vector3.new(math.ceil(high.X), math.ceil(high.Y), math.ceil(high.Z)) - origin
	local cells: { [number]: string } = {}
	local nx, nz = size.X, size.Z
	for y = 0, size.Y - 1 do
		for z = 0, size.Z - 1 do
			for x = 0, size.X - 1 do
				local p = origin + Vector3.new(x + 0.5, y + 0.5, z + 0.5)
				local color: string? = nil
				for _, shape in shapes do
					if contains(shape, p) then
						if shape.Carve then
							color = nil
						elseif color or not shape.Paint then
							color = shape.Color
						end
					end
				end
				if color then
					cells[x + nx * (z + nz * y)] = color
				end
			end
		end
	end
	return origin, size, cells
end

-- Merges same-colored neighbours into boxes (greedy: along X, then Z, then Y) and
-- makes one Part per box, in root space.
local function mesh(model: Model, art: Art, origin: Vector3, size: Vector3, cells: { [number]: string })
	local nx, ny, nz = size.X, size.Y, size.Z
	local used: { [number]: boolean } = {}
	local function index(x: number, y: number, z: number): number
		return x + nx * (z + nz * y)
	end
	local function free(x: number, y: number, z: number, color: string): boolean
		local i = index(x, y, z)
		return cells[i] == color and not used[i]
	end

	local voxel = art.VoxelSize
	local material = art.Material or Enum.Material.SmoothPlastic
	for y = 0, ny - 1 do
		for z = 0, nz - 1 do
			for x = 0, nx - 1 do
				local color = cells[index(x, y, z)]
				if not color or used[index(x, y, z)] then
					continue
				end
				-- Grow along X, then Z (whole rows), then Y (whole slabs).
				local x1 = x
				while x1 + 1 < nx and free(x1 + 1, y, z, color) do
					x1 += 1
				end
				local z1 = z
				while z1 + 1 < nz do
					local ok = true
					for xi = x, x1 do
						if not free(xi, y, z1 + 1, color) then
							ok = false
							break
						end
					end
					if not ok then
						break
					end
					z1 += 1
				end
				local y1 = y
				while y1 + 1 < ny do
					local ok = true
					for zi = z, z1 do
						for xi = x, x1 do
							if not free(xi, y1 + 1, zi, color) then
								ok = false
								break
							end
						end
						if not ok then
							break
						end
					end
					if not ok then
						break
					end
					y1 += 1
				end
				for yi = y, y1 do
					for zi = z, z1 do
						for xi = x, x1 do
							used[index(xi, yi, zi)] = true
						end
					end
				end

				local part = Instance.new("Part")
				part.Anchored = true
				part.Size = Vector3.new(x1 - x + 1, y1 - y + 1, z1 - z + 1) * voxel
				part.CFrame = CFrame.new((origin + Vector3.new(x + x1 + 1, y + y1 + 1, z + z1 + 1) / 2) * voxel)
				part.Color = art.Palette[color] or Color3.new(1, 0, 1)
				part.Material = if art.Materials and art.Materials[color] then art.Materials[color] else material
				part.TopSurface = Enum.SurfaceType.Smooth
				part.BottomSurface = Enum.SurfaceType.Smooth
				part.Parent = model
			end
		end
	end
end

-- Builds one part (Head/Body/Arms/Legs) as a Model whose pivot is the brainrot's
-- root. Nil if the art has no such part.
function VoxelArt.Build(art: Art, partType: string): Model?
	local shapes = art.Parts[partType]
	if not shapes or #shapes == 0 then
		return nil
	end
	local model = Instance.new("Model")
	model.Name = partType
	local origin, size, cells = voxelize(shapes)
	mesh(model, art, origin, size, cells)
	model.WorldPivot = CFrame.identity
	local joint = art.Joints and art.Joints[partType]
	local anchor = model:FindFirstChildWhichIsA("BasePart")
	if joint and anchor then
		local attachment = Instance.new("Attachment")
		attachment.Name = "Joint"
		attachment.Parent = anchor
		attachment.WorldPosition = joint * art.VoxelSize
	end
	return model
end

return VoxelArt
