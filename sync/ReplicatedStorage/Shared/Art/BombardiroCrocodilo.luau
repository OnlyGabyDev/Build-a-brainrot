-- Bombardiro Crocodilo: a dark bomber plane with a crocodile's head for a nose.
-- The body is the fuselage (cockpit, tail fin, yellow markings), the arms are the
-- wings with propellers and bombs, the legs are the landing gear, and the head is
-- the toothy croc snout.

local V = require(script.Parent.Parent.VoxelArt)

local box, ball, carve, paint, mirror = V.box, V.ball, V.carve, V.paint, V.mirror

-- Adds shapes and their left/right mirrors.
local function both(shapes: { V.Shape }, list: { V.Shape })
	for _, shape in list do
		table.insert(shapes, shape)
		table.insert(shapes, mirror(shape))
	end
end

local fuselage = ball(0, 10, 1, 4, 3.5, 9, "Hull")

local legs = {
	box(-1, 0, 6, 1, 2, 8, "Wheel"), -- tail wheel
	box(-1, 2, 6, 1, 10, 7, "Strut"),
}
both(legs, {
	box(-4, 0, -4, -2, 3, -1, "Wheel"), -- main wheels
	box(-3, 3, -3, -2, 10, -2, "Strut"),
})
table.insert(legs, carve(fuselage))

local body = {
	fuselage,
	paint(box(-5, 5, 4, 5, 15, 5, "Yellow")), -- a yellow band
	box(-2, 13, -5, 2, 15, 1, "Glass"), -- cockpit
	box(-2, 13, -2, 2, 15, -1, "HullDark"),
	box(-1, 12, 6, 1, 19, 10, "Hull"), -- tail fin
	carve(box(-1, 16, 6, 1, 19, 8)),
	paint(box(-1, 18, 8, 1, 19, 10, "Yellow")),
	box(-6, 10, 7, 6, 11, 10, "Hull"), -- tail wings
}

local arms = {}
both(arms, {
	box(-13, 9, -2, -4, 11, 4, "Hull"), -- wings
	paint(box(-13, 9, -2, -12, 11, 4, "Yellow")),
	box(-10, 8, -5, -7, 12, 1, "HullDark"), -- engines
	box(-11, 10, -6, -6, 11, -5, "Prop"), -- propellers
	box(-9, 7, -6, -8, 14, -5, "Prop"),
	box(-11, 10, -6, -10, 11, -5, "Yellow"),
	box(-7, 10, -6, -6, 11, -5, "Yellow"),
	box(-9, 10, -7, -8, 11, -6, "HullDark"),
	box(-7, 8, 0, -5, 9, 2, "HullDark"), -- a bomb under each wing
	ball(-6, 7, 1, 1.2, 1.2, 2.5, "Bomb"),
	box(-7, 6, 3, -5, 8, 4, "Yellow"),
})

local head = {
	box(-4, 10, -17, 4, 13, -7, "Croc"), -- upper jaw
	box(-4, 7, -17, 4, 10, -7, "CrocLight"), -- lower jaw
}
both(head, {
	box(-3, 9, -18, -2, 10, -17, "White"), -- teeth
	box(-1, 9, -18, 0, 10, -17, "White"),
	box(-4, 13, -12, -1, 15, -9, "Croc"), -- eye bumps
	box(-4, 13, -13, -1, 15, -12, "White"),
	box(-3, 13, -13, -2, 14, -12, "Dark"),
	box(-3, 13, -17, -2, 14, -16, "CrocDark"), -- nostrils
})
for _, z in { -16, -14, -12, -10 } do
	both(head, { box(-5, 9, z, -4, 10, z + 1, "White") })
end
table.insert(head, carve(fuselage))

return {
	VoxelSize = 0.25,
	Palette = {
		Hull = Color3.fromRGB(58, 64, 62),
		HullDark = Color3.fromRGB(35, 38, 40),
		Prop = Color3.fromRGB(28, 30, 32),
		Yellow = Color3.fromRGB(245, 210, 40),
		Glass = Color3.fromRGB(150, 210, 240),
		Bomb = Color3.fromRGB(80, 86, 92),
		Wheel = Color3.fromRGB(30, 30, 30),
		Strut = Color3.fromRGB(150, 150, 155),
		Croc = Color3.fromRGB(135, 185, 90),
		CrocDark = Color3.fromRGB(85, 130, 60),
		CrocLight = Color3.fromRGB(232, 226, 165),
		White = Color3.fromRGB(255, 255, 255),
		Dark = Color3.fromRGB(25, 25, 25),
	},
	-- The landing gear reaches up into the fuselage; bodies sit at its bottom.
	Joints = { Legs = Vector3.new(0, 7, 1) },
	Parts = { Legs = legs, Body = body, Arms = arms, Head = head },
}
