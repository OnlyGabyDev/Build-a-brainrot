-- Frigo Camelo: a camel whose body is a fridge. The camel's long neck curves out of
-- the fridge door up to its head, and it stands on camel legs in laced brown boots.

local V = require(script.Parent.Parent.VoxelArt)

local box, paint, mirror = V.box, V.paint, V.mirror

-- Adds shapes and their left/right mirrors.
local function both(shapes: { V.Shape }, list: { V.Shape })
	for _, shape in list do
		table.insert(shapes, shape)
		table.insert(shapes, mirror(shape))
	end
end

local legs = {}
both(legs, {
	box(-4, 3, -1, -1, 9, 2, "Camel"),
	box(-5, 0, -3, -1, 3, 2, "Boot"),
	box(-5, 0, -3, -1, 1, 2, "Sole"),
	box(-4, 2, -3, -2, 3, -2, "Lace"),
})

local body = {
	box(-5, 9, -4, 5, 21, 4, "Fridge"),
	paint(box(-6, 16, -5, 6, 17, 5, "FridgeShade")), -- the gap between the doors
	box(3, 17, -5, 4, 20, -4, "Handle"),
	box(3, 11, -5, 4, 15, -4, "Handle"),
}

local arms = {}
both(arms, {
	box(-7, 12, -1, -5, 18, 1, "Camel"),
	box(-7, 11, -1, -5, 12, 1, "Hoof"),
})

local head = {
	box(-2, 13, -7, 2, 17, -4, "Camel"), -- the neck, out of the fridge...
	box(-2, 16, -9, 2, 23, -6, "Camel"), -- ...and up
	box(-3, 22, -14, 3, 27, -6, "Camel"),
	box(-3, 24, -15, 3, 26, -13, "Muzzle"),
	box(-3, 22, -15, 3, 23, -14, "Camel"),
}
both(head, {
	box(-4, 24, -11, -3, 26, -9, "Dark"), -- eyes
	box(-4, 25, -10, -3, 26, -9, "White"),
	box(-3, 27, -8, -1, 29, -6, "Camel"), -- ears
})

return {
	VoxelSize = 0.25,
	Palette = {
		Fridge = Color3.fromRGB(238, 238, 244),
		FridgeShade = Color3.fromRGB(200, 200, 212),
		Handle = Color3.fromRGB(150, 152, 162),
		Camel = Color3.fromRGB(175, 100, 60),
		Muzzle = Color3.fromRGB(105, 58, 38),
		Hoof = Color3.fromRGB(90, 55, 35),
		Boot = Color3.fromRGB(115, 62, 40),
		Sole = Color3.fromRGB(70, 40, 28),
		Lace = Color3.fromRGB(245, 245, 245),
		Dark = Color3.fromRGB(25, 25, 25),
		White = Color3.fromRGB(255, 255, 255),
	},
	Parts = { Legs = legs, Body = body, Arms = arms, Head = head },
}
