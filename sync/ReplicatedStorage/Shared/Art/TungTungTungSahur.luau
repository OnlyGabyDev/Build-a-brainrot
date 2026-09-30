-- Tung Tung Tung Sahur: an orange wooden log with a big grin, long stick legs, and a
-- baseball bat in its right hand. The top of the log (with the face) is its head.

local V = require(script.Parent.Parent.VoxelArt)

local box, ball, cylinder, paint, mirror = V.box, V.ball, V.cylinder, V.paint, V.mirror

return {
	VoxelSize = 0.25,
	Palette = {
		Wood = Color3.fromRGB(222, 146, 80),
		Bark = Color3.fromRGB(160, 96, 50),
		Rings = Color3.fromRGB(242, 200, 140),
		White = Color3.fromRGB(255, 255, 255),
		Pupil = Color3.fromRGB(30, 25, 25),
		Brow = Color3.fromRGB(70, 42, 25),
		Mouth = Color3.fromRGB(95, 35, 30),
		Bat = Color3.fromRGB(232, 206, 150),
		Grip = Color3.fromRGB(60, 40, 30),
	},
	Parts = {
		Legs = {
			cylinder(-1.8, 0, 0.9, 0.9, 1, 8, "Bark"), -- stick legs
			mirror(cylinder(-1.8, 0, 0.9, 0.9, 1, 8, "Bark")),
			box(-3.2, 0, -2.5, -0.5, 1.5, 1, "Bark"), -- feet
			mirror(box(-3.2, 0, -2.5, -0.5, 1.5, 1, "Bark")),
		},

		Body = {
			cylinder(0, 0, 4.5, 4, 8, 17, "Wood"), -- the lower log
			paint(box(-5, 9, -1, -3, 16, 1, "Bark")), -- bark stripes
			mirror(paint(box(-5, 9, -1, -3, 16, 1, "Bark"))),
			box(-1, 9, 3.2, 1, 16, 4.1, "Bark"),
			ball(1.8, 11, -3.8, 0.9, 0.9, 0.6, "Bark"), -- a knot
		},

		Head = {
			cylinder(0, 0, 4.5, 4, 17, 26, "Wood"), -- the upper log
			cylinder(0, 0, 4, 3.5, 25, 26, "Rings"), -- tree rings on top
			cylinder(0, 0, 2.5, 2.2, 25, 26, "Bark"),
			cylinder(0, 0, 1.2, 1, 25, 26, "Rings"),
			box(-3, 20, -4.5, -0.5, 23, -3, "White"), -- big eyes
			mirror(box(-3, 20, -4.5, -0.5, 23, -3, "White")),
			box(-2, 20.5, -4.6, -1, 22, -3.2, "Pupil"),
			mirror(box(-2, 20.5, -4.6, -1, 22, -3.2, "Pupil")),
			box(-3.2, 23.5, -4.6, -0.3, 24.5, -3.2, "Brow"), -- eyebrows
			mirror(box(-3.2, 23.5, -4.6, -0.3, 24.5, -3.2, "Brow")),
			box(-2.5, 18, -4.5, 2.5, 19, -3.2, "Mouth"), -- a wide grin
			box(-3.2, 19, -4.3, -2.5, 20, -3.2, "Mouth"),
			mirror(box(-3.2, 19, -4.3, -2.5, 20, -3.2, "Mouth")),
		},

		Arms = {
			box(-6, 12, -1, -4.5, 17, 1, "Bark"), -- left arm hangs down
			box(4.5, 15, -1, 6, 17, 1, "Bark"), -- right arm reaches for the bat
			box(4.5, 11, -2.5, 6.5, 15, 0, "Bark"),
			cylinder(5.5, -1.3, 0.8, 0.8, 10, 13, "Grip"), -- the bat
			cylinder(5.5, -1.3, 0.8, 0.8, 13, 18, "Bat"),
			cylinder(5.5, -1.3, 1.2, 1.2, 18, 25, "Bat"),
		},
	},
}
