--[[
	SetupMaterials (Studio, Edit mode)
	Paste into the Studio MCP's execute_luau (Edit) or the command bar. Scripts can't
	create MaterialVariants at runtime (their properties need Plugin security), so these
	live in the place file: run this once, then save the place.

	CartoonGrass: the terrain's Grass wears a cartoon leaf texture (Creator Store decal
	16851006789, "Cartoon_green_texture_grass"; its image id is below). Nothing else in
	the game uses the Grass material.

	PlushKnit: the Plushie Sewing Room's brainrots are knitted (Zones Style.MaterialVariant;
	the room's dress forms and plushies too). A chunky knit on Fabric, tinted by each
	part's color: our own image, uploaded as rbxassetid://102486908186849, made from
	Creator Store decal 89432944006199 ("Beige Sweater Texture") turned light gray with
	strong contrast so the stitches read on tiny voxels. The file is
	tools/textures/PlushKnit.png: if the id ever stops loading, upload it again (the MCP's
	upload_image takes an http URL, so serve the folder with `python -m http.server`) and
	put the new id below. Without the variant, those parts just show plain Fabric.
]]

local MaterialService = game:GetService("MaterialService")

local grass = MaterialService:FindFirstChild("CartoonGrass") or Instance.new("MaterialVariant")
grass.Name = "CartoonGrass"
grass.BaseMaterial = Enum.Material.Grass
grass.ColorMap = "rbxassetid://16851006758"
grass.StudsPerTile = 18
grass.Parent = MaterialService
MaterialService:SetBaseMaterialOverride(Enum.Material.Grass, grass.Name)

local knit = MaterialService:FindFirstChild("PlushKnit") or Instance.new("MaterialVariant")
knit.Name = "PlushKnit"
knit.BaseMaterial = Enum.Material.Fabric
knit.ColorMap = "rbxassetid://102486908186849"
knit.StudsPerTile = 4
knit.Parent = MaterialService

return "CartoonGrass and PlushKnit ready: save the place to keep them"
