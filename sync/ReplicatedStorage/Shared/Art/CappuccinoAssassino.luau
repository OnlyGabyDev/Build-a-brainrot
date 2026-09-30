-- Cappuccino Assassino: a ninja cappuccino cup with an angry glare, a black headband
-- (tails fluttering behind), a scarf over its mouth, and a katana in each hand.

local V = require(script.Parent.Parent.VoxelArt)

local box, mirror = V.box, V.mirror

-- Adds shapes and their left/right mirrors.
local function both(shapes: { V.Shape }, list: { V.Shape })
	for _, shape in list do
		table.insert(shapes, shape)
		table.insert(shapes, mirror(shape))
	end
end

local legs = {}
both(legs, {
	box(-3, 1, -1, -1, 8, 1, "Ninja"), -- skinny black legs
	box(-4, 0, -3, -1, 2, 1, "Shoe"),
})

local body = {
	box(-5, 8, -4, 5, 16, 4, "Cup"), -- the bottom of the cup
	box(-6, 13, -5, 6, 16, 5, "Ninja"), -- the scarf over its mouth
}

local arms = {}
both(arms, {
	box(-8, 10, -1, -6, 15, 1, "Ninja"),
	box(-9, 8, -2, -7, 10, 1, "Ninja"), -- hands
	box(-10, 7, -3, -7, 8, 2, "Guard"), -- katanas, pointing down and out
	box(-9, 5, -1, -8, 7, 1, "Blade"),
	box(-10, 3, -1, -9, 5, 1, "Blade"),
	box(-11, 1, -1, -10, 3, 1, "Blade"),
	box(-12, 0, -1, -11, 1, 1, "Blade"),
})

local head = {
	box(-5, 16, -4, 5, 23, 4, "Cup"),
	box(-6, 23, -5, 6, 26, 5, "Ninja"), -- the headband...
	box(-2, 24, -6, 2, 26, -5, "Plate"), -- ...with a metal plate
	box(-1, 25, -6, 0, 26, -5, "Swirl"),
	box(0, 24, -6, 1, 25, -5, "Swirl"),
	box(4, 24, 5, 6, 25, 8, "Ninja"), -- and tails behind
	box(5, 22, 7, 7, 24, 9, "Ninja"),
}
both(head, {
	box(-4, 17, -4, -1, 20, -3, "Ninja"), -- glaring eyes
	box(-4, 19, -4, -3, 20, -3, "White"),
	box(-5, 21, -4, -2, 22, -3, "Ninja"), -- angry brows
	box(-2, 20, -4, -1, 21, -3, "Ninja"),
})

return {
	VoxelSize = 0.25,
	Palette = {
		Cup = Color3.fromRGB(248, 240, 238),
		Ninja = Color3.fromRGB(28, 28, 32),
		White = Color3.fromRGB(255, 255, 255),
		Plate = Color3.fromRGB(195, 198, 205),
		Swirl = Color3.fromRGB(70, 72, 80),
		Shoe = Color3.fromRGB(55, 55, 62),
		Guard = Color3.fromRGB(200, 160, 80),
		Blade = Color3.fromRGB(215, 222, 232),
	},
	-- The headband's tails stick out behind; the head's socket is the cup.
	Joints = { Head = Vector3.new(0, 21, 0) },
	Parts = { Legs = legs, Body = body, Arms = arms, Head = head },
}
