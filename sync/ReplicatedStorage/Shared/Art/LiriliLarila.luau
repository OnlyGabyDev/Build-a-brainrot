-- Lirilì Larilà: an elephant with a cactus for a body, standing in brown sandals.
-- Its head (trunk, tusks, floppy ears) sits in front of the cactus, and its arms
-- are little cactus branches with a pink flower on top.

local V = require(script.Parent.Parent.VoxelArt)

local box, ball, cylinder, carve, paint, mirror = V.box, V.ball, V.cylinder, V.carve, V.paint, V.mirror

-- Adds shapes and their left/right mirrors.
local function both(shapes: { V.Shape }, list: { V.Shape })
	for _, shape in list do
		table.insert(shapes, shape)
		table.insert(shapes, mirror(shape))
	end
end

local legs = {}
both(legs, {
	box(-6, 0, -6, -1, 1, 2, "Sole"), -- the sandal
	cylinder(-3.5, -1, 2.2, 2.2, 1, 7, "Cactus"), -- stubby legs
	box(-5, 1, -5, -2, 2, -3, "Cactus"), -- toes
	box(-6, 2, -5, -1, 3, -3, "Strap"), -- a strap over the toes...
	box(-6, 1, -5, -5, 2, -3, "Strap"),
	box(-2, 1, -5, -1, 2, -3, "Strap"),
	box(-4, 2, -6, -3, 3, -5, "Buckle"), -- ...with a buckle
	box(-6, 1, 1, -1, 3, 2, "Strap"), -- and one around the heel
})

local body = {
	cylinder(0, 1, 5.5, 5, 7, 19, "Cactus"),
	ball(0, 19, 1, 5.5, 3.5, 5, "Cactus"), -- rounded top
	paint(box(-3, 7, -6, -2, 20, 7, "CactusDark")), -- ribs, front and back
	paint(box(2, 7, -6, 3, 20, 7, "CactusDark")),
	paint(box(-7, 7, 0, 7, 20, 1, "CactusDark")), -- and on the sides
	box(-2, 22, 0, 2, 23, 2, "Flower"), -- a flower on top
	box(-1, 22, -1, 1, 23, 3, "Flower"),
	box(-1, 22, 0, 1, 23, 2, "FlowerCenter"),
}
for y = 9, 17, 4 do -- spines along the ribs
	table.insert(body, paint(box(-3, y, -6, -2, y + 1, 7, "Spine")))
	table.insert(body, paint(box(2, y, -6, 3, y + 1, 7, "Spine")))
	table.insert(body, paint(box(-7, y + 2, 0, 7, y + 3, 1, "Spine")))
end

local arms = {}
both(arms, {
	box(-7, 10, -1, -5, 12, 2, "Cactus"), -- out from the body...
	box(-9, 10, -1, -7, 17, 2, "Cactus"), -- ...and up
	carve(box(-9, 16, -1, -8, 17, 2)), -- a rounded tip
	box(-8, 14, -2, -7, 15, -1, "Spine"),
	box(-10, 12, 0, -9, 13, 1, "Spine"),
})

local head = {
	box(-4, 14, -10, 4, 21, -4, "Elephant"),
	box(-2, 12, -12, 2, 17, -10, "Elephant"), -- the trunk hangs down...
	box(-1, 9, -13, 1, 13, -11, "Elephant"),
	box(-1, 8, -15, 1, 10, -12, "Elephant"), -- ...and curls forward
	box(-1, 8, -15, 1, 10, -14, "ElephantDark"),
}
both(head, {
	carve(box(-4, 20, -10, -3, 21, -4)), -- rounded corners
	carve(box(-4, 14, -10, -3, 15, -4)),
	box(-7, 13, -7, -4, 20, -5, "Elephant"), -- floppy ears
	carve(box(-7, 19, -7, -6, 20, -5)),
	carve(box(-7, 13, -7, -6, 14, -5)),
	box(-6, 14, -7, -5, 19, -6, "EarInner"),
	box(-3, 17, -11, -1, 19, -10, "Pupil"), -- eyes
	box(-2, 18, -11, -1, 19, -10, "White"),
	box(-4, 12, -13, -2, 14, -10, "Tusk"), -- tusks
	box(-4, 11, -15, -2, 13, -13, "Tusk"),
})

return {
	VoxelSize = 0.25,
	Palette = {
		Cactus = Color3.fromRGB(140, 210, 90),
		CactusDark = Color3.fromRGB(95, 170, 65),
		Spine = Color3.fromRGB(250, 245, 215),
		Flower = Color3.fromRGB(255, 120, 175),
		FlowerCenter = Color3.fromRGB(255, 215, 70),
		Elephant = Color3.fromRGB(165, 138, 108),
		ElephantDark = Color3.fromRGB(120, 98, 76),
		EarInner = Color3.fromRGB(205, 150, 135),
		Tusk = Color3.fromRGB(252, 250, 245),
		Pupil = Color3.fromRGB(25, 25, 25),
		White = Color3.fromRGB(255, 255, 255),
		Sole = Color3.fromRGB(195, 95, 60),
		Strap = Color3.fromRGB(145, 70, 45),
		Buckle = Color3.fromRGB(55, 42, 35),
	},
	-- The trunk and tusks hang low; the head's socket is its face.
	Joints = { Head = Vector3.new(0, 17.5, -7) },
	Parts = { Legs = legs, Body = body, Arms = arms, Head = head },
}
