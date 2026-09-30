-- Tung Tung Tung Sahur: a wooden log with a big grin, stick legs, and a baseball bat
-- in its right hand. The top of the log (with the face) is its head.

local V = require(script.Parent.Parent.VoxelArt)

local box, ball, cylinder, mirror = V.box, V.ball, V.cylinder, V.mirror

return {
	VoxelSize = 0.25,
	Palette = {
		Wood = Color3.fromRGB(196, 142, 88),
		Bark = Color3.fromRGB(140, 94, 52),
		Rings = Color3.fromRGB(232, 196, 140),
		White = Color3.fromRGB(255, 255, 255),
		Pupil = Color3.fromRGB(30, 25, 25),
		Brow = Color3.fromRGB(70, 42, 25),
		Mouth = Color3.fromRGB(95, 35, 30),
		Bat = Color3.fromRGB(232, 206, 150),
		Grip = Color3.fromRGB(60, 40, 30),
	},
	Parts = {
		Legs = {
			cylinder(-1.8, 0, 0.9, 0.9, 1, 6, "Bark"), -- stick legs
			mirror(cylinder(-1.8, 0, 0.9, 0.9, 1, 6, "Bark")),
			box(-3.2, 0, -2.5, -0.5, 1.5, 1, "Bark"), -- feet
			mirror(box(-3.2, 0, -2.5, -0.5, 1.5, 1, "Bark")),
		},

		Body = {
			cylinder(0, 0, 4.5, 4, 6, 16, "Wood"), -- the lower log
			box(-4.6, 7, -1, -3.8, 15, 1, "Bark"), -- bark stripes
			mirror(box(-4.6, 7, -1, -3.8, 15, 1, "Bark")),
			box(-1, 7, 3.2, 1, 15, 4.1, "Bark"),
			ball(1.8, 9, -3.8, 0.9, 0.9, 0.6, "Bark"), -- a knot
		},

		Head = {
			cylinder(0, 0, 4.5, 4, 16, 25, "Wood"), -- the upper log
			cylinder(0, 0, 4, 3.5, 24, 25, "Rings"), -- tree rings on top
			cylinder(0, 0, 2.5, 2.2, 24, 25, "Bark"),
			cylinder(0, 0, 1.2, 1, 24, 25, "Rings"),
			box(-3, 19, -4.5, -0.5, 22, -3, "White"), -- big eyes
			mirror(box(-3, 19, -4.5, -0.5, 22, -3, "White")),
			box(-2, 19.5, -4.6, -1, 21, -3.2, "Pupil"),
			mirror(box(-2, 19.5, -4.6, -1, 21, -3.2, "Pupil")),
			box(-3.2, 22.5, -4.6, -0.3, 23.5, -3.2, "Brow"), -- eyebrows
			mirror(box(-3.2, 22.5, -4.6, -0.3, 23.5, -3.2, "Brow")),
			box(-2.5, 17, -4.5, 2.5, 18, -3.2, "Mouth"), -- a wide grin
			box(-3.2, 18, -4.3, -2.5, 19, -3.2, "Mouth"),
			mirror(box(-3.2, 18, -4.3, -2.5, 19, -3.2, "Mouth")),
		},

		Arms = {
			box(-6, 10, -1, -4.5, 15, 1, "Bark"), -- left arm hangs down
			box(4.5, 13, -1, 6, 15, 1, "Bark"), -- right arm reaches for the bat
			box(4.5, 9, -2.5, 6.5, 13, 0, "Bark"),
			cylinder(5.5, -1.3, 0.8, 0.8, 8, 11, "Grip"), -- the bat
			cylinder(5.5, -1.3, 0.8, 0.8, 11, 16, "Bat"),
			cylinder(5.5, -1.3, 1.2, 1.2, 16, 23, "Bat"),
		},
	},
}
