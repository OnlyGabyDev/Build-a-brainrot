-- La Vaca Saturno Saturnita: a cow that is also the planet Saturn. The body is the
-- striped planet, the arms are its ring, the head is a cow in sunglasses poking out
-- of the top, and it walks on two big bare feet.

local V = require(script.Parent.Parent.VoxelArt)

local box, ball, cylinder, carve, paint, mirror = V.box, V.ball, V.cylinder, V.carve, V.paint, V.mirror

-- Adds shapes and their left/right mirrors.
local function both(shapes: { V.Shape }, list: { V.Shape })
	for _, shape in list do
		table.insert(shapes, shape)
		table.insert(shapes, mirror(shape))
	end
end

local planet = ball(0, 15, 0, 8, 8, 8, "Planet")

local legs = {}
both(legs, {
	box(-5, 3, -2, -3, 10, 1, "Foot"), -- ankles, up into the planet
	box(-7, 0, -6, -1, 3, 2, "Foot"), -- big feet
	box(-7, 0, -7, -6, 2, -6, "Nail"),
	box(-5, 0, -7, -4, 2, -6, "Nail"),
	box(-3, 0, -7, -2, 2, -6, "Nail"),
})
table.insert(legs, carve(planet))

local body = { planet }
for _, y in { 9, 13, 17, 21 } do -- stripes
	table.insert(body, paint(box(-9, y, -9, 9, y + 1, 9, "Blue")))
end
for _, y in { 11, 15, 19 } do
	table.insert(body, paint(box(-9, y, -9, 9, y + 1, 9, "PlanetLight")))
end

local arms = {
	cylinder(0, 0, 13, 13, 14, 15, "Ring"), -- the ring, floating around the planet
	carve(cylinder(0, 0, 9, 9, 14, 15, "Ring")),
	paint(cylinder(0, 0, 11.5, 11.5, 14, 15, "RingShade")),
	paint(cylinder(0, 0, 10.5, 10.5, 14, 15, "Ring")),
}

local head = {
	box(-4, 18, -12, 4, 25, -5, "Cow"),
	paint(box(-4, 23, -13, -1, 26, -5, "Spot")), -- black spots
	paint(box(2, 18, -11, 5, 21, -5, "Spot")),
	box(-3, 18, -13, 3, 21, -11, "Muzzle"),
	box(-1, 23, -13, 1, 24, -12, "Glasses"), -- sunglasses
}
both(head, {
	box(-2, 19, -13, -1, 20, -12, "Nostril"),
	box(-4, 22, -13, -1, 24, -12, "Glasses"),
	box(-3, 23, -13, -2, 24, -12, "Glint"),
	box(-6, 21, -9, -4, 23, -7, "Cow"), -- ears
	box(-6, 24, -9, -4, 25, -7, "Horn"), -- horns
	box(-7, 25, -9, -5, 27, -7, "Horn"),
})
table.insert(head, carve(planet))

return {
	VoxelSize = 0.25,
	Palette = {
		Planet = Color3.fromRGB(232, 200, 150),
		PlanetLight = Color3.fromRGB(248, 228, 190),
		Blue = Color3.fromRGB(140, 205, 228),
		Ring = Color3.fromRGB(228, 228, 234),
		RingShade = Color3.fromRGB(190, 190, 204),
		Cow = Color3.fromRGB(250, 250, 250),
		Spot = Color3.fromRGB(30, 30, 30),
		Muzzle = Color3.fromRGB(245, 170, 170),
		Nostril = Color3.fromRGB(200, 110, 115),
		Glasses = Color3.fromRGB(20, 20, 24),
		Glint = Color3.fromRGB(110, 120, 140),
		Horn = Color3.fromRGB(240, 230, 200),
		Foot = Color3.fromRGB(238, 202, 152),
		Nail = Color3.fromRGB(250, 245, 238),
	},
	-- The feet reach up into the planet (bodies sit at its bottom), and the horns
	-- stick up (the head's socket is the cow's face).
	Joints = { Legs = Vector3.new(0, 7, 0), Head = Vector3.new(0, 21.5, -9) },
	Parts = { Legs = legs, Body = body, Arms = arms, Head = head },
}
