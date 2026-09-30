-- Trippi Troppi: a shrimp with a cat's face. The head is a square cat face (big
-- framed eyes, red nose) with shrimp antennae on top, the body is the curled shrimp
-- tail behind it, the arms are little claws, and it walks on bent shrimp legs.

local V = require(script.Parent.Parent.VoxelArt)

local box, carve, paint, mirror = V.box, V.carve, V.paint, V.mirror

-- Adds shapes and their left/right mirrors.
local function both(shapes: { V.Shape }, list: { V.Shape })
	for _, shape in list do
		table.insert(shapes, shape)
		table.insert(shapes, mirror(shape))
	end
end

local legs = {}
for _, z in { -4, -1, 2 } do
	both(legs, {
		box(-3, 4, z - 1, -1, 8, z + 1, "Shell"), -- bent shrimp legs
		box(-4, 0, z - 1, -2, 4, z + 1, "Shell"),
		box(-4, 0, z - 1, -2, 1, z + 1, "ShellLight"),
	})
end

local body = {
	box(-4, 8, -2, 4, 15, 1, "Shell"), -- tail segments, curling up behind the head
	box(-3, 8, 1, 3, 14, 4, "Shell"),
	box(-3, 10, 4, 3, 16, 6, "Shell"),
	box(-2, 13, 6, 2, 18, 8, "Shell"),
	box(-4, 17, 7, 4, 21, 9, "Shell"), -- the tail fan
	carve(box(-1, 19, 7, 1, 21, 9)),
	paint(box(-5, 8, 0, 5, 22, 1, "ShellLight")), -- stripes between segments
	paint(box(-5, 8, 3, 5, 22, 4, "ShellLight")),
	paint(box(-5, 8, 5, 5, 22, 6, "ShellLight")),
	paint(box(-5, 20, 7, 5, 21, 9, "ShellLight")),
}

local arms = {}
both(arms, {
	box(-8, 8, -4, -6, 10, -1, "Shell"), -- little claws beside the muzzle
	box(-9, 7, -8, -6, 11, -4, "Shell"),
	carve(box(-9, 9, -8, -6, 10, -6)),
	paint(box(-9, 7, -8, -6, 11, -7, "ShellLight")),
})

local head = {
	box(-6, 8, -8, 6, 19, -2, "Fur"),
	box(-5, 8, -8, 5, 18, -7, "Face"), -- the face, framed by orange fur
	box(-4, 8, -9, 4, 11, -8, "Muzzle"),
	box(-2, 9, -9, -1, 10, -8, "Dark"), -- a little cat mouth
	box(1, 9, -9, 2, 10, -8, "Dark"),
	box(-1, 10, -10, 1, 12, -8, "Nose"), -- a red nose
	box(-2, 12, -10, 2, 13, -8, "Nose"),
	box(-1, 19, -4, 1, 20, -3, "Shell"), -- the shrimp's own eye, on a stalk
	box(-1, 20, -5, 1, 22, -3, "Dark"),
	box(-1, 21, -5, 0, 22, -4, "White"),
}
both(head, {
	box(-7, 13, -6, -6, 17, -3, "Fur"), -- fluffy cheeks
	box(-6, 13, -9, -1, 18, -8, "Dark"), -- big framed eyes
	box(-5, 14, -9, -2, 17, -8, "Iris"),
	box(-6, 19, -6, -3, 21, -4, "Fur"), -- pointy ears
	box(-6, 21, -6, -4, 22, -4, "Fur"),
	box(-5, 19, -6, -4, 21, -5, "EarInner"),
	box(-3, 19, -3, -1, 22, -1, "Shell"), -- long antennae
	box(-4, 22, -3, -2, 25, -1, "Shell"),
	box(-5, 25, -3, -3, 27, -1, "Shell"),
	box(-6, 27, -3, -4, 29, -1, "Shell"),
})
table.insert(head, box(-3, 14, -9, -2, 16, -8, "Dark")) -- pupils, both looking the same way
table.insert(head, box(4, 14, -9, 5, 16, -8, "Dark"))

return {
	VoxelSize = 0.25,
	Palette = {
		Fur = Color3.fromRGB(240, 120, 50),
		Face = Color3.fromRGB(242, 190, 125),
		Muzzle = Color3.fromRGB(252, 228, 180),
		EarInner = Color3.fromRGB(250, 200, 150),
		Nose = Color3.fromRGB(225, 60, 55),
		Iris = Color3.fromRGB(255, 165, 40),
		Dark = Color3.fromRGB(30, 25, 25),
		White = Color3.fromRGB(255, 255, 255),
		Shell = Color3.fromRGB(235, 100, 45),
		ShellLight = Color3.fromRGB(255, 160, 90),
	},
	-- The antennae stick far up; the head's socket is the cat face.
	Joints = { Head = Vector3.new(0, 13.5, -5) },
	Parts = { Legs = legs, Body = body, Arms = arms, Head = head },
}
