-- Glorbo Fruttodrillo: a crocodile inside a watermelon. The body is the striped
-- melon, the head is the toothy croc snout poking out the front, and stubby croc
-- arms and legs with pale claws stick out of the rind.

local V = require(script.Parent.Parent.VoxelArt)

local box, ball, carve, paint, mirror = V.box, V.ball, V.carve, V.paint, V.mirror

-- Adds shapes and their left/right mirrors.
local function both(shapes: { V.Shape }, list: { V.Shape })
	for _, shape in list do
		table.insert(shapes, shape)
		table.insert(shapes, mirror(shape))
	end
end

local melon = ball(0, 12, 0, 7, 7, 7, "Melon")

local legs = {}
for _, z in { -4, 3 } do
	both(legs, {
		box(-5, 0, z, -2, 8, z + 3, "Croc"), -- stubby legs, up into the melon
		box(-5, 0, z - 1, -4, 1, z, "Claw"),
		box(-3, 0, z - 1, -2, 1, z, "Claw"),
	})
end
table.insert(legs, carve(melon))

local body = { melon }
for _, d in { 1, 4 } do -- stripes from pole to pole
	both(body, { paint(box(-d - 1, 4, -8, -d, 20, 8, "MelonLight")) })
	table.insert(body, paint(box(-8, 4, -d - 1, 8, 20, -d, "MelonLight")))
	table.insert(body, paint(box(-8, 4, d, 8, 20, d + 1, "MelonLight")))
end

local arms = {}
both(arms, {
	box(-9, 8, -4, -5, 11, -1, "Croc"),
	box(-9, 8, -5, -8, 9, -4, "Claw"),
	box(-7, 8, -5, -6, 9, -4, "Claw"),
})
table.insert(arms, carve(melon))

local head = {
	box(-4, 12, -16, 4, 16, -6, "Croc"), -- upper jaw
	box(-4, 9, -16, 4, 12, -6, "CrocLight"), -- lower jaw
}
both(head, {
	box(-3, 11, -17, -2, 12, -16, "White"), -- teeth
	box(-1, 11, -17, 0, 12, -16, "White"),
	box(-4, 16, -9, -1, 18, -7, "Croc"), -- eye bumps
	box(-4, 16, -10, -1, 18, -9, "Eye"),
	box(-3, 17, -10, -2, 18, -9, "Dark"),
	box(-3, 15, -17, -2, 16, -16, "CrocDark"), -- nostrils
})
for _, z in { -15, -13, -11, -9 } do
	both(head, { box(-5, 11, z, -4, 12, z + 1, "White") })
end
table.insert(head, carve(melon))

return {
	VoxelSize = 0.25,
	Palette = {
		Melon = Color3.fromRGB(45, 140, 55),
		MelonLight = Color3.fromRGB(150, 210, 90),
		Croc = Color3.fromRGB(70, 150, 70),
		CrocDark = Color3.fromRGB(40, 100, 45),
		CrocLight = Color3.fromRGB(200, 222, 150),
		Claw = Color3.fromRGB(245, 205, 205),
		White = Color3.fromRGB(255, 255, 255),
		Eye = Color3.fromRGB(230, 60, 50),
		Dark = Color3.fromRGB(25, 25, 25),
	},
	-- The legs reach up into the melon; bodies sit at its bottom.
	Joints = { Legs = Vector3.new(0, 5, 0) },
	Parts = { Legs = legs, Body = body, Arms = arms, Head = head },
}
