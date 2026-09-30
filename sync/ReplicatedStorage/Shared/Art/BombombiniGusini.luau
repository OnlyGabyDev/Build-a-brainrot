-- Bombombini Gusini: a goose that is also a bomber plane. The body is the gray
-- fuselage (white goose chest in front, tail fins behind), the arms are the wings
-- with propellers, the head is the long goose neck and orange beak, and it stands
-- on orange goose feet.

local V = require(script.Parent.Parent.VoxelArt)

local box, ball, carve, paint, mirror = V.box, V.ball, V.carve, V.paint, V.mirror

-- Adds shapes and their left/right mirrors.
local function both(shapes: { V.Shape }, list: { V.Shape })
	for _, shape in list do
		table.insert(shapes, shape)
		table.insert(shapes, mirror(shape))
	end
end

local fuselage = ball(0, 11, 1, 4, 4, 7, "Metal")

local legs = {}
both(legs, {
	box(-3, 2, -1, -1, 11, 1, "Feet"), -- legs, up into the fuselage
	box(-4, 0, -4, -1, 2, 1, "Feet"), -- webbed feet
	carve(box(-3, 1, -4, -2, 2, -3)),
})
table.insert(legs, carve(fuselage))

local body = {
	fuselage,
	paint(box(-5, 6, -7, 5, 16, -4, "Goose")), -- the goose's white chest
	paint(box(-5, 6, 3, 5, 16, 4, "Red")), -- a red band
	box(-1, 12, 6, 1, 18, 9, "Metal"), -- tail fin
	box(-1, 17, 7, 1, 18, 9, "Red"),
	box(-5, 11, 6, 5, 12, 9, "Metal"), -- tail wings
}

local arms = {}
both(arms, {
	box(-11, 10, -2, -4, 12, 3, "Metal"), -- wings
	box(-10, 9, -4, -7, 13, 1, "MetalDark"), -- engines
	box(-11, 10, -5, -6, 11, -4, "Prop"), -- propellers with red tips
	box(-9, 8, -5, -8, 13, -4, "Prop"),
	box(-11, 10, -5, -10, 11, -4, "Red"),
	box(-7, 10, -5, -6, 11, -4, "Red"),
	box(-9, 8, -5, -8, 9, -4, "Red"),
	box(-9, 12, -5, -8, 13, -4, "Red"),
	box(-9, 10, -6, -8, 11, -5, "MetalDark"),
	paint(box(-11, 10, -2, -10, 12, 3, "Red")), -- wing tips
})

local head = {
	box(-2, 12, -10, 2, 15, -5, "Goose"), -- the neck, out of the chest...
	box(-2, 14, -12, 2, 18, -9, "Goose"), -- ...and up
	box(-3, 16, -16, 3, 21, -11, "Goose"),
	box(-2, 16, -19, 2, 19, -16, "Beak"),
	box(-2, 16, -19, 2, 17, -16, "BeakDark"),
	carve(fuselage),
}
both(head, {
	box(-4, 19, -15, -3, 20, -14, "Dark"), -- eyes
})

return {
	VoxelSize = 0.25,
	Palette = {
		Metal = Color3.fromRGB(135, 150, 170),
		MetalDark = Color3.fromRGB(90, 100, 115),
		Prop = Color3.fromRGB(60, 62, 72),
		Red = Color3.fromRGB(230, 85, 100),
		Goose = Color3.fromRGB(250, 250, 250),
		Beak = Color3.fromRGB(255, 165, 40),
		BeakDark = Color3.fromRGB(225, 120, 30),
		Feet = Color3.fromRGB(255, 150, 40),
		Dark = Color3.fromRGB(25, 25, 25),
	},
	-- The neck reaches far forward; other heads go where it leaves the chest.
	Joints = { Head = Vector3.new(0, 15, -9), Legs = Vector3.new(0, 7, 1) },
	Parts = { Legs = legs, Body = body, Arms = arms, Head = head },
}
