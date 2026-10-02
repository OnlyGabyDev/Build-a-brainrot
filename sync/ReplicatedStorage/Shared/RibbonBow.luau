--[[
	RibbonBow
	A glossy satin ribbon bow (GDD §6: the Plushie room's Bow Tier ties one on every
	brainrot, and a giant one decorates the machine). Two puffy loops tipped up, each
	with a shadowed fold where the ribbon turns back into the knot and a sheen along its
	top; a gold knot; two tails hanging down and out, forked at the ends. Ellipsoids are
	parts with a Sphere mesh. The same on the server and the client.
]]

local RibbonBow = {}

local GOLD = Color3.fromRGB(255, 190, 40) -- solid gold: Metal, no reflectance
local WHITE = Color3.new(1, 1, 1)

local function piece(parent: Instance, name: string, size: Vector3, cframe: CFrame, color: Color3, material: Enum.Material?, round: boolean?): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	if round then
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Sphere
		mesh.Parent = part
	end
	part.Parent = parent
	return part
end

-- A bow `size` studs across in a Model in `parent`, its knot at `at` and its front
-- facing `at`'s -Z.
function RibbonBow.Build(parent: Instance, at: CFrame, size: number, color: Color3): Model
	local s = size / 4.6
	local model = Instance.new("Model")
	model.Name = "RibbonBow"
	local fold = color:Lerp(Color3.fromRGB(70, 10, 50), 0.45)
	local sheen = color:Lerp(WHITE, 0.6)
	for _, side in { -1, 1 } do
		-- the loop: puffy, longer than it's tall, tipped up toward its outer end
		local loop = at * CFrame.new(side * 1.2 * s, 0.2 * s, 0.1 * s) * CFrame.Angles(0, -side * math.rad(12), side * math.rad(20))
		local body = piece(model, "BowLoop", Vector3.new(2.5, 1.7, 1.15) * s, loop, color, nil, true)
		body.Reflectance = 0.08
		-- the fold where it turns back into the knot, a shadowed dent on its front
		piece(model, "BowFold", Vector3.new(1.05, 0.8, 0.35) * s, loop * CFrame.new(-side * 0.4 * s, -0.05 * s, -0.48 * s), fold, nil, true)
		-- a satin sheen along its top
		piece(model, "BowSheen", Vector3.new(1.4, 0.3, 0.55) * s, loop * CFrame.new(side * 0.2 * s, 0.55 * s, -0.3 * s), sheen, nil, true)
		-- the tail, hanging down and out, forked at the end
		local tail = at * CFrame.new(side * 0.4 * s, -0.55 * s, 0.05 * s) * CFrame.Angles(0, 0, side * math.rad(24))
		piece(model, "BowTail", Vector3.new(0.6, 1.5, 0.16) * s, tail * CFrame.new(0, -0.75 * s, 0), color)
		for _, fork in { -1, 1 } do
			piece(model, "BowTailTip", Vector3.new(0.3, 0.5, 0.16) * s, tail * CFrame.new(fork * 0.16 * s, -1.6 * s, 0) * CFrame.Angles(0, 0, fork * math.rad(28)), color)
		end
	end
	-- the knot, in gold
	piece(model, "BowKnot", Vector3.new(0.95, 1.1, 1) * s, at * CFrame.new(0, 0, -0.1 * s), GOLD, Enum.Material.Metal, true)
	model.WorldPivot = at
	model.Parent = parent
	return model
end

return RibbonBow
