-- Ballerina Cappuccina: a ballerina whose head is a cappuccino cup (lashes, a big
-- smile, a handle on the side). Pink tutu, arms spread wide, one leg lifted.

local V = require(script.Parent.Parent.VoxelArt)

local box, cylinder, carve, paint, mirror = V.box, V.cylinder, V.carve, V.paint, V.mirror

-- Adds shapes and their left/right mirrors.
local function both(shapes: { V.Shape }, list: { V.Shape })
	for _, shape in list do
		table.insert(shapes, shape)
		table.insert(shapes, mirror(shape))
	end
end

local legs = {
	box(-3, 1, -1, -1, 9, 1, "Tights"), -- the standing leg, on pointe
	box(-3, 0, -2, -1, 2, 1, "Slipper"),
	paint(box(-4, 2, -2, 0, 3, 2, "Slipper")), -- ribbon
	box(1, 7, -1, 5, 9, 1, "Tights"), -- the lifted leg, bent at the knee
	box(3, 3, -1, 5, 7, 1, "Tights"),
	box(3, 2, -2, 5, 3, 1, "Slipper"),
	paint(box(2, 3, -2, 6, 4, 2, "Slipper")),
}

local body = {
	cylinder(0, 0, 5, 5, 9, 11, "Tutu"),
	paint(cylinder(0, 0, 5, 5, 9, 10, "TutuDark")), -- a trim around the tutu's edge
	paint(cylinder(0, 0, 4, 4, 9, 10, "Tutu")),
	box(-2, 11, -2, 2, 15, 2, "Tutu"), -- leotard
	box(-3, 11, -3, 3, 12, 3, "TutuDark"), -- waistband
}

local arms = {}
both(arms, {
	box(-7, 13, -1, -2, 15, 1, "Skin"), -- spread wide, a little raised at the hands
	box(-12, 14, -1, -7, 16, 1, "Skin"),
})

local head = {
	box(-5, 15, -4, 5, 27, 4, "Cup"),
	carve(box(-4, 26, -3, 4, 27, 3)), -- coffee inside the rim
	box(-4, 25, -3, 4, 26, 3, "Foam"),
	box(-3, 25, -2, 3, 26, 2, "Coffee"),
	box(5, 18, -1, 8, 25, 1, "Cup"), -- the handle
	carve(box(5, 19, -1, 7, 24, 1)),
	box(-1, 18, -5, 1, 19, -4, "Nose"),
	box(-3, 16, -4, 3, 18, -3, "Mouth"), -- a big smile
	box(-2, 17, -4, 2, 18, -3, "White"),
}
both(head, {
	box(-4, 18, -4, -3, 19, -3, "Mouth"), -- smile corners
	box(-5, 20, -4, -1, 23, -3, "Lash"), -- eyes with lashes
	box(-4, 20, -4, -2, 22, -3, "Iris"),
	box(-3, 21, -4, -2, 22, -3, "White"),
	box(-6, 22, -4, -5, 23, -3, "Lash"),
	box(-4, 24, -4, -1, 25, -3, "Brow"),
})

return {
	VoxelSize = 0.25,
	Palette = {
		Cup = Color3.fromRGB(250, 250, 250),
		Coffee = Color3.fromRGB(120, 75, 45),
		Foam = Color3.fromRGB(225, 190, 150),
		Brow = Color3.fromRGB(140, 90, 50),
		Lash = Color3.fromRGB(25, 25, 25),
		Iris = Color3.fromRGB(130, 80, 45),
		White = Color3.fromRGB(255, 255, 255),
		Nose = Color3.fromRGB(245, 160, 150),
		Mouth = Color3.fromRGB(240, 130, 140),
		Skin = Color3.fromRGB(250, 205, 185),
		Tutu = Color3.fromRGB(255, 180, 205),
		TutuDark = Color3.fromRGB(240, 110, 150),
		Tights = Color3.fromRGB(252, 235, 235),
		Slipper = Color3.fromRGB(255, 145, 180),
	},
	-- The lifted leg and the cup's handle stick out to one side; keep the sockets centered.
	Joints = { Legs = Vector3.new(0, 9, 0), Head = Vector3.new(0, 21, 0) },
	Parts = { Legs = legs, Body = body, Arms = arms, Head = head },
}
