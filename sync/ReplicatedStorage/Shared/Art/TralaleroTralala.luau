-- Tralalero Tralala: a blue shark on three long legs in blue sneakers. Its head is
-- the snout in front of the body, and its "arms" are the pectoral fins.

local V = require(script.Parent.Parent.VoxelArt)

local box, ball, cylinder, carve, paint, mirror = V.box, V.ball, V.cylinder, V.carve, V.paint, V.mirror

local torso = ball(0, 16, 2, 5, 5, 8, "Shark")
local belly = ball(0, 14.5, 1, 4.2, 3.4, 6.5, "Belly") -- white underside

-- A leg in a sneaker, centered at (x, z). It reaches up into the torso, and the
-- torso is carved out of it, so each leg ends exactly on the shark's curved belly.
local function leg(x: number, z: number): { V.Shape }
	return {
		cylinder(x, z, 1.3, 1.3, 2.5, 16, "Skin"),
		box(x - 2, 0, z - 3, x + 2, 3, z + 2, "Shoe"),
		box(x - 2, 0, z - 3, x + 2, 1, z + 2, "Sole"),
		box(x - 2, 1, z - 3, x + 2, 2, z - 2, "Sole"), -- toe cap
		box(x - 2, 1.5, z - 2, x - 1, 2.5, z + 1, "Dark"), -- swooshes
		box(x + 1, 1.5, z - 2, x + 2, 2.5, z + 1, "Dark"),
	}
end

local legs = {}
for _, shapes in { leg(-2.5, -3), leg(2.5, -3), leg(0, 5), { carve(torso), carve(belly) } } do
	table.move(shapes, 1, #shapes, #legs + 1, legs)
end

local body = {
	torso,
	belly,
	box(-1, 20, 0, 1, 23, 4, "Shark"), -- dorsal fin
	box(-1, 23, 1.5, 1, 25, 4, "Shark"),
	ball(0, 16, 10, 2.5, 2.5, 3, "Shark"), -- tail stalk
	box(-1, 17, 11, 1, 25, 13, "Shark"), -- tail fin, upper
	box(-1, 11, 11, 1, 16, 13, "Shark"), -- tail fin, lower
}
for _, z in { -3, -1, 1 } do -- gills
	table.insert(body, paint(box(2, 14, z, 6, 18, z + 1, "Dark")))
	table.insert(body, paint(box(-6, 14, z, -2, 18, z + 1, "Dark")))
end

return {
	VoxelSize = 0.25,
	Palette = {
		Shark = Color3.fromRGB(70, 135, 210),
		Skin = Color3.fromRGB(95, 155, 220),
		Belly = Color3.fromRGB(238, 242, 248),
		Dark = Color3.fromRGB(35, 40, 60),
		White = Color3.fromRGB(255, 255, 255),
		Mouth = Color3.fromRGB(215, 120, 215),
		Shoe = Color3.fromRGB(40, 105, 235),
		Sole = Color3.fromRGB(250, 250, 250),
	},
	-- The legs reach up into the torso; bodies sit where the torso's bottom is.
	Joints = { Legs = Vector3.new(0, 11, 0.5) },
	Parts = {
		Legs = legs,

		Body = body,

		Arms = {
			ball(5, 14, -2.5, 1.5, 1.2, 2.2, "Shark"), -- pectoral fins, stepping out and down
			ball(6.5, 13, -2.5, 1.5, 1, 2, "Shark"),
			mirror(ball(5, 14, -2.5, 1.5, 1.2, 2.2, "Shark")),
			mirror(ball(6.5, 13, -2.5, 1.5, 1, 2, "Shark")),
		},

		Head = {
			ball(0, 16, -9.5, 4.2, 4.2, 4, "Shark"), -- snout
			ball(0, 14.5, -9.5, 3.5, 2.5, 3.6, "Belly"), -- lower jaw
			paint(box(-5, 13, -14, 5, 14, -8, "Mouth")), -- a pink smile around the snout
			box(3, 17, -11, 4.3, 19, -9, "Dark"), -- eyes
			mirror(box(3, 17, -11, 4.3, 19, -9, "Dark")),
			box(3.3, 18, -11, 4.3, 19, -10, "White"), -- eye shine
			mirror(box(3.3, 18, -11, 4.3, 19, -10, "White")),
		},
	},
}
