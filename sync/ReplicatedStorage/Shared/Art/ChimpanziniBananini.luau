-- Chimpanzini Bananini: a green-furred chimp peeking out of a banana. The body is the
-- banana (its bottom curls back into a brown tip, which it stands on), the arms are
-- the peel flaps, and the head is the grumpy chimp.

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
	cylinder(0, 0, 4, 3.5, 4, 8, "Banana"), -- the banana's bottom half...
	box(-3, 1, -2, 3, 4, 4, "Banana"),
	box(-2, 0, 1, 2, 3, 7, "Banana"), -- ...curling back...
	box(-2, 2, 6, 2, 5, 9, "Banana"),
	box(-1, 4, 8, 1, 7, 10, "Stem"), -- ...into the brown tip
}
both(legs, {
	carve(box(-3, 1, -2, -2, 2, 4)), -- rounded bottom edges
	paint(box(-3, 0, -5, -2, 8, 11, "BananaShade")), -- ridges
})

local body = {
	cylinder(0, 0, 4, 3.5, 8, 16, "Banana"),
	paint(box(-4, 15, -4, 4, 16, 4, "BananaLight")), -- the peeled rim
}
both(body, {
	paint(box(-3, 8, -5, -2, 15, 5, "BananaShade")),
})

local arms = {}
both(arms, {
	box(-6, 14, -2, -4, 17, 2, "Banana"), -- peel flaps, folding out and down
	box(-7, 9, -2, -5, 14, 2, "Banana"),
	box(-7, 8, -1, -6, 9, 1, "Banana"),
	paint(box(-5, 14, -3, -4, 17, 3, "BananaLight")), -- the pale inside of the peel
	paint(box(-6, 9, -3, -5, 14, 3, "BananaLight")),
})

local head = {
	box(-4, 16, -4, 4, 26, 3, "Fur"),
	box(-3, 17, -5, 3, 22, -4, "Face"),
	box(-2, 18, -5, 2, 19, -4, "Dark"), -- a grumpy frown
}
both(head, {
	carve(box(-4, 25, -4, -3, 26, 3)), -- rounded top
	box(-6, 19, -2, -4, 22, 0, "Face"), -- ears
	box(-3, 20, -5, -1, 21, -4, "Dark"), -- eyes
	box(-2, 20, -5, -1, 21, -4, "White"),
	box(-3, 17, -5, -2, 18, -4, "Dark"),
})

return {
	VoxelSize = 0.25,
	Palette = {
		Banana = Color3.fromRGB(252, 222, 60),
		BananaShade = Color3.fromRGB(228, 190, 40),
		BananaLight = Color3.fromRGB(255, 242, 160),
		Stem = Color3.fromRGB(110, 75, 40),
		Fur = Color3.fromRGB(60, 160, 60),
		Face = Color3.fromRGB(240, 140, 130),
		Dark = Color3.fromRGB(30, 25, 25),
		White = Color3.fromRGB(255, 255, 255),
	},
	-- The banana's curled bottom reaches back; bodies sit on its center.
	Joints = { Legs = Vector3.new(0, 8, 0) },
	Parts = { Legs = legs, Body = body, Arms = arms, Head = head },
}
