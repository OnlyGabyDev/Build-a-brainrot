-- Supremo Brainrotto (Godly, our own design): the Risotto King. A crowned pink brain
-- with googly eyes and an Italian mustache pops out of a golden pot of risotto
-- (brainrotto!) that steams in rainbow colors. It holds a giant wooden spoon and a
-- fork, and waddles on little chef boots. The gems and the steam glow (Neon).

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
	box(-4, 3, -1, -2, 7, 1, "PotDark"), -- stubby golden legs
	box(-5, 0, -3, -1, 3, 2, "Sleeve"), -- chef boots
	box(-5, 0, -3, -1, 1, 2, "Sole"),
})

local body = {
	cylinder(0, 0, 7, 6, 7, 15, "Pot"),
	paint(box(-8, 10, -7, 8, 11, 7, "PotDark")), -- a band around the pot
	cylinder(0, 0, 7.5, 6.5, 15, 17, "PotDark"), -- the rim
	cylinder(0, 0, 6, 5, 15, 16, "Risotto"),
	carve(cylinder(0, 0, 6, 5, 16, 17)),
	-- Rainbow steam curling up at the back of the rim.
	box(-6, 16, 2, -5, 18, 3, "SteamRed"),
	box(-7, 18, 3, -6, 20, 4, "SteamOrange"),
	box(-6, 20, 4, -5, 21, 5, "SteamYellow"),
	box(5, 16, 2, 6, 18, 3, "SteamGreen"),
	box(6, 18, 3, 7, 20, 4, "SteamBlue"),
	box(5, 20, 4, 6, 21, 5, "SteamPurple"),
	box(-7, 16, -3, -6, 18, -2, "SteamPurple"), -- and a puff at each front corner
	box(-8, 18, -4, -7, 19, -3, "SteamBlue"),
	box(6, 16, -3, 7, 18, -2, "SteamRed"),
	box(7, 18, -4, 8, 19, -3, "SteamOrange"),
}
for _, spot in { { -5, 0 }, { 4, -1 }, { -3, -4 }, { 2, 3 } } do -- rice grains
	local x, z = spot[1], spot[2]
	table.insert(body, paint(box(x, 15, z, x + 1, 16, z + 1, "Rice")))
end
table.insert(body, paint(box(3, 15, -4, 4, 16, -3, "Herb"))) -- and herbs
table.insert(body, paint(box(-4, 15, 2, -3, 16, 3, "Herb")))

local arms = {
	box(-12, 5, -1, -10, 20, 1, "Spoon"), -- a giant wooden spoon...
	ball(-11, 22, 0, 2, 3, 1.2, "Spoon"),
	box(10, 5, -1, 11, 19, 1, "Fork"), -- ...and a fork
	box(8, 19, -1, 13, 20, 1, "Fork"),
	box(8, 20, -1, 9, 24, 1, "Fork"),
	box(10, 20, -1, 11, 24, 1, "Fork"),
	box(12, 20, -1, 13, 24, 1, "Fork"),
}
both(arms, {
	box(-9, 11, -1, -7, 13, 1, "Sleeve"), -- chef sleeves
	box(-13, 10, -2, -9, 13, 2, "Brain"), -- hands gripping the handles
})

local head = {
	ball(0, 21.5, 0, 6.5, 5.5, 6, "Brain"),
	box(-5, 17, -6, 5, 25, 0, "Brain"), -- a flatter front for the face
	cylinder(0, 0, 4, 4, 26, 28, "Crown"), -- the crown, around the top of the brain
	cylinder(0, 0, 3, 3, 26, 28, "Brain"),
	box(-1, 28, -5, 1, 30, -3, "Crown"),
	box(-1, 28, 3, 1, 30, 5, "Crown"),
	box(-1, 26, -5, 1, 28, -4, "GemRed"),
	box(-1, 26, 4, 1, 28, 5, "GemGreen"),
	paint(box(-1, 23, -7, 1, 28, 7, "BrainDark")), -- the middle fold
	paint(box(-8, 21, 2, 8, 22, 5, "BrainDark")), -- folds on the back
	box(-5, 18, -7, 5, 19, -6, "Mustache"), -- a big Italian mustache
	box(-2, 17, -7, 2, 18, -6, "Mouth"),
}
both(head, {
	paint(box(-8, 23, -4, -4, 24, 0, "BrainDark")), -- squiggly folds on the sides
	paint(box(-8, 19, -1, -4, 20, 3, "BrainDark")),
	box(-5, 20, -7, -1, 24, -6, "White"), -- googly eyes
	box(-3, 20, -7, -1, 22, -6, "Pupil"),
	box(-2, 21, -7, -1, 22, -6, "White"),
	box(-5, 19, -7, -4, 20, -6, "Mustache"), -- curled ends
	box(-5, 28, -1, -3, 30, 1, "Crown"),
	box(-5, 26, -1, -4, 28, 1, "GemBlue"),
})

local glow = Enum.Material.Neon

return {
	VoxelSize = 0.25,
	Palette = {
		Brain = Color3.fromRGB(255, 150, 185),
		BrainDark = Color3.fromRGB(225, 100, 150),
		White = Color3.fromRGB(255, 255, 255),
		Pupil = Color3.fromRGB(25, 25, 30),
		Mustache = Color3.fromRGB(75, 45, 30),
		Mouth = Color3.fromRGB(170, 40, 60),
		Crown = Color3.fromRGB(255, 200, 40),
		GemRed = Color3.fromRGB(255, 60, 90),
		GemGreen = Color3.fromRGB(60, 230, 120),
		GemBlue = Color3.fromRGB(60, 170, 255),
		Pot = Color3.fromRGB(255, 190, 50),
		PotDark = Color3.fromRGB(215, 145, 30),
		Risotto = Color3.fromRGB(250, 232, 180),
		Rice = Color3.fromRGB(255, 252, 235),
		Herb = Color3.fromRGB(90, 175, 60),
		SteamRed = Color3.fromRGB(255, 80, 90),
		SteamOrange = Color3.fromRGB(255, 160, 60),
		SteamYellow = Color3.fromRGB(255, 230, 70),
		SteamGreen = Color3.fromRGB(90, 230, 110),
		SteamBlue = Color3.fromRGB(80, 170, 255),
		SteamPurple = Color3.fromRGB(190, 110, 255),
		Spoon = Color3.fromRGB(205, 145, 85),
		Fork = Color3.fromRGB(215, 222, 232),
		Sleeve = Color3.fromRGB(248, 248, 248),
		Sole = Color3.fromRGB(60, 60, 68),
	},
	Materials = {
		GemRed = glow,
		GemGreen = glow,
		GemBlue = glow,
		SteamRed = glow,
		SteamOrange = glow,
		SteamYellow = glow,
		SteamGreen = glow,
		SteamBlue = glow,
		SteamPurple = glow,
	},
	-- The crown and mustache stick out; the head's socket is the brain itself.
	Joints = { Head = Vector3.new(0, 21.5, 0) },
	Parts = { Legs = legs, Body = body, Arms = arms, Head = head },
}
