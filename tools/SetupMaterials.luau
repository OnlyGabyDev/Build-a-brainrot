--[[
	SetupMaterials (Studio, Edit mode)
	Paste into the Studio MCP's execute_luau (Edit) or the command bar. Scripts can't
	create MaterialVariants at runtime (their properties need Plugin security), so these
	live in the place file: run this once, then save the place.

	CartoonGrass: the terrain's Grass wears a cartoon leaf texture (Creator Store decal
	16851006789, "Cartoon_green_texture_grass"; its image id is below). Nothing else in
	the game uses the Grass material.
]]

local MaterialService = game:GetService("MaterialService")

local grass = MaterialService:FindFirstChild("CartoonGrass") or Instance.new("MaterialVariant")
grass.Name = "CartoonGrass"
grass.BaseMaterial = Enum.Material.Grass
grass.ColorMap = "rbxassetid://16851006758"
grass.StudsPerTile = 18
grass.Parent = MaterialService
MaterialService:SetBaseMaterialOverride(Enum.Material.Grass, grass.Name)

return "CartoonGrass ready: save the place to keep it"
