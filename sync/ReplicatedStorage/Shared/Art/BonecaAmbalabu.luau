-- Boneca Ambalabu: a frog head on a black tire, walking on skinny human legs.
-- The head is a striped frog face with bulging eyes, the body is the tire (you can
-- see through the hole), and the arms are skinny like the legs.

local V = require(script.Parent.Parent.VoxelArt)

local box, ball, carve, paint, mirror = V.box, V.ball, V.carve, V.paint, V.mirror

-- Adds shapes and their left/right mirrors.
local function both(shapes: { V.Shape }, list: { V.Shape })
	for _, shape in list do
		table.insert(shapes, shape)
		table.insert(shapes, mirror(shape))
	end
end

local tire = ball(0, 16, 0, 6, 6, 2.5, "Tire")

local legs = {}
both(legs, {
	box(-3, 2, -1, -1, 13, 1, "Skin"), -- skinny legs, up into the tire
	box(-4, 0, -4, -1, 2, 1, "Skin"), -- big bare feet
	box(-4, 0, -5, -3, 1, -4, "Nail"),
	box(-2, 0, -5, -1, 1, -4, "Nail"),
})
table.insert(legs, carve(tire))

local body = {
	tire,
	paint(ball(0, 16, 0, 4.5, 4.5, 3, "TireLight")), -- a rim around the hole
	paint(ball(0, 16, 0, 3.5, 3.5, 3, "Tire")),
	carve(ball(0, 16, 0, 2.6, 2.6, 4)), -- the hole
}

local arms = {}
both(arms, {
	box(-8, 11, -1, -6, 19, 1, "Skin"),
	box(-9, 10, -2, -6, 12, 1, "Skin"), -- hands
})

local head = {
	box(-4, 22, -3, 4, 25, 3, "Face"),
	box(-4, 25, -3, 4, 27, 3, "Frog"),
	paint(box(-5, 25, -4, 5, 26, 4, "FrogLight")), -- lips
}
both(head, {
	paint(box(-2, 22, -4, -1, 25, 4, "Stripe")), -- stripes down the face
	paint(box(-4, 22, -4, -3, 25, 4, "Stripe")),
	box(-4, 27, -3, -1, 29, 0, "Frog"), -- bulging eyes
	box(-4, 27, -4, -1, 29, -3, "Eye"),
	box(-3, 27, -4, -2, 29, -3, "Dark"),
})

return {
	VoxelSize = 0.25,
	Palette = {
		Frog = Color3.fromRGB(45, 95, 40),
		FrogLight = Color3.fromRGB(80, 140, 60),
		Eye = Color3.fromRGB(235, 205, 60),
		Dark = Color3.fromRGB(25, 25, 25),
		Face = Color3.fromRGB(228, 206, 170),
		Stripe = Color3.fromRGB(85, 58, 42),
		Tire = Color3.fromRGB(35, 35, 40),
		TireLight = Color3.fromRGB(70, 70, 78),
		Skin = Color3.fromRGB(240, 195, 160),
		Nail = Color3.fromRGB(205, 200, 200),
	},
	-- The legs reach up into the tire; bodies sit at the tire's bottom.
	Joints = { Legs = Vector3.new(0, 10, 0) },
	Parts = { Legs = legs, Body = body, Arms = arms, Head = head },
}
