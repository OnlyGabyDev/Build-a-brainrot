-- Brr Brr Patapim: a tall proboscis monkey under a mossy green hood, with a long
-- droopy nose, yellow eyes, a white beard and big bare feet. Its arms wear moss
-- sleeves, and moss hangs around its waist.

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
	box(-4, 2, -2, -1, 8, 2, "Skin"), -- legs
	box(-5, 0, -5, -1, 2, 2, "Skin"), -- big feet
	box(-5, 0, -5, -4, 1, -4, "Nail"), -- toenails
	box(-3, 0, -5, -2, 1, -4, "Nail"),
})
table.insert(legs, box(-4, 5, -2, -2, 7, -1, "Moss")) -- a moss patch on one knee

local body = {
	box(-5, 8, -3, 5, 17, 3, "Skin"), -- torso
	box(-5, 8, 2, 5, 17, 4, "Moss"), -- mossy back
	box(-5, 8, -4, 5, 11, 3, "Moss"), -- moss around the waist
	box(-3, 9, -4, -2, 10, -3, "MossDark"),
	box(2, 8, -4, 3, 9, -3, "MossDark"),
	box(-3, 12, 3, -1, 14, 4, "MossDark"),
	box(2, 15, 3, 4, 16, 4, "MossDark"),
	box(-3, 11, -4, 3, 13, -3, "Fur"), -- the beard, down the chest
	box(-4, 13, -4, 4, 17, -3, "Fur"),
}
both(body, {
	box(-4, 6, -4, -1, 8, -3, "Moss"), -- moss hanging over the thighs
})

local head = {
	box(-4, 17, -4, 4, 25, 3, "Skin"),
	box(-5, 17, -3, 5, 27, 4, "Moss"), -- the hood
	box(-5, 25, -5, 5, 27, -3, "Moss"), -- its brim
	box(-4, 26, -5, -2, 27, -4, "MossDark"),
	box(1, 25, -5, 3, 26, -4, "MossDark"),
	box(4, 20, 0, 5, 22, 2, "MossDark"),
	box(-5, 22, 1, -4, 24, 3, "MossDark"),
	box(-2, 17, -5, 2, 18, -4, "Fur"), -- chin fur
}
both(head, {
	box(-4, 17, -5, -2, 22, -4, "Fur"), -- white cheek fur
	box(-4, 22, -5, -1, 24, -4, "Eye"), -- yellow eyes
	box(-3, 22, -5, -2, 24, -4, "Pupil"), -- slit pupils
})
local face = {
	box(2, 19, -5, 4, 20, -4, "Mouth"), -- a little smirk beside the nose
	box(-1, 19, -6, 1, 24, -4, "Skin"), -- the nose, from between the eyes...
	box(-2, 13, -7, 2, 19, -4, "Skin"), -- ...down to a big droopy tip
	box(-2, 13, -7, 2, 14, -4, "Shade"),
}
table.move(face, 1, #face, #head + 1, head)

local arms = {}
both(arms, {
	box(-8, 11, -2, -5, 18, 2, "Moss"), -- moss sleeves, from the shoulder
	box(-8, 3, -2, -5, 11, 2, "Skin"), -- long bare forearms and hands
	box(-8, 13, -2, -7, 15, -1, "MossDark"),
	box(-6, 15, -2, -5, 16, -1, "MossLight"),
	box(-8, 3, -2, -5, 4, -1, "Nail"), -- fingernails
})

return {
	VoxelSize = 0.25,
	Palette = {
		Skin = Color3.fromRGB(242, 192, 150),
		Shade = Color3.fromRGB(214, 158, 118),
		Nail = Color3.fromRGB(205, 200, 200),
		Moss = Color3.fromRGB(50, 150, 60),
		MossDark = Color3.fromRGB(28, 100, 42),
		MossLight = Color3.fromRGB(100, 190, 75),
		Fur = Color3.fromRGB(232, 230, 228),
		Eye = Color3.fromRGB(255, 214, 30),
		Pupil = Color3.fromRGB(25, 25, 25),
		Mouth = Color3.fromRGB(110, 55, 45),
	},
	-- The droopy nose hangs below the head; the head's socket is the face itself.
	Joints = { Head = Vector3.new(0, 22, -0.5) },
	Parts = { Legs = legs, Body = body, Arms = arms, Head = head },
}
