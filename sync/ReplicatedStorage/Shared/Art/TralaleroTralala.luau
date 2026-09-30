-- Tralalero Tralala: a blue shark on three legs in blue sneakers. Its head is the
-- snout in front of the body, and its "arms" are the pectoral fins.

local V = require(script.Parent.Parent.VoxelArt)

local box, ball, cylinder, mirror = V.box, V.ball, V.cylinder, V.mirror

-- A leg in a sneaker, centered at (x, z).
local function leg(x: number, z: number): { V.Shape }
	return {
		cylinder(x, z, 1.3, 1.3, 2.5, 8, "Skin"),
		box(x - 2, 0, z - 3, x + 2, 3, z + 2, "Shoe"),
		box(x - 2, 0, z - 3, x + 2, 1, z + 2, "Sole"),
		box(x - 2, 1, z - 3, x + 2, 2, z - 2, "Sole"), -- toe cap
		box(x - 2, 1.5, z - 2, x - 1, 2.5, z + 1, "Sole"), -- swooshes
		box(x + 1, 1.5, z - 2, x + 2, 2.5, z + 1, "Sole"),
	}
end

local legs = {}
for _, shapes in { leg(-3.5, -3), leg(3.5, -3), leg(0, 5) } do
	table.move(shapes, 1, #shapes, #legs + 1, legs)
end

return {
	VoxelSize = 0.25,
	Palette = {
		Shark = Color3.fromRGB(70, 135, 210),
		Skin = Color3.fromRGB(95, 155, 220),
		Belly = Color3.fromRGB(238, 242, 248),
		Dark = Color3.fromRGB(35, 40, 60),
		White = Color3.fromRGB(255, 255, 255),
		Shoe = Color3.fromRGB(40, 105, 235),
		Sole = Color3.fromRGB(250, 250, 250),
	},
	Parts = {
		Legs = legs,

		Body = {
			ball(0, 13, 2, 5, 5, 8, "Shark"), -- torso
			ball(0, 11.5, 1, 4.2, 3.4, 6.5, "Belly"), -- white underside
			box(-1, 17, 0, 1, 20, 4, "Shark"), -- dorsal fin
			box(-1, 20, 1.5, 1, 22, 4, "Shark"),
			ball(0, 13, 10, 2.5, 2.5, 3, "Shark"), -- tail stalk
			box(-1, 14, 11, 1, 22, 13, "Shark"), -- tail fin, upper
			box(-1, 8, 11, 1, 13, 13, "Shark"), -- tail fin, lower
		},

		Arms = {
			ball(5, 11, -2, 1.5, 1.2, 2.2, "Shark"), -- pectoral fins, stepping out and down
			ball(6.5, 10, -2, 1.5, 1, 2, "Shark"),
			mirror(ball(5, 11, -2, 1.5, 1.2, 2.2, "Shark")),
			mirror(ball(6.5, 10, -2, 1.5, 1, 2, "Shark")),
		},

		Head = {
			ball(0, 13, -9.5, 4.2, 4.2, 4, "Shark"), -- snout
			ball(0, 11.5, -9.5, 3.5, 2.5, 3.6, "Belly"), -- lower jaw
			box(3, 14, -11, 4.3, 16, -9, "Dark"), -- eyes
			mirror(box(3, 14, -11, 4.3, 16, -9, "Dark")),
			box(3.3, 15, -11, 4.3, 16, -10, "White"), -- eye shine
			mirror(box(3.3, 15, -11, 4.3, 16, -10, "White")),
			box(-3, 10, -13, 3, 11, -11.5, "Dark"), -- mouth, on the snout's front surface
			box(-2.5, 11, -13, -1.5, 12, -12, "White"), -- teeth
			box(-0.5, 11, -13, 0.5, 12, -12, "White"),
			box(1.5, 11, -13, 2.5, 12, -12, "White"),
		},
	},
}
