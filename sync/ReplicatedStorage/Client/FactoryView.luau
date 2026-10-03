--[[
	FactoryView
	Where the local player is in the factories, for code that only animates what they can
	see. A factory building's storeys are measured from its Cutaway models
	(FactoryBuilder: pivoted on the ground floor's middle, with Area and StoreyHeight).
	From inside a building you only see your own storey of it: walls and floors hide the
	others, and the ones above are faded out anyway (TycoonFX's cutaway). From outside,
	everything counts as in view. Client only.
]]

local Players = game:GetService("Players")

local player = Players.LocalPlayer

local FactoryView = {}

local function numberAttribute(model: Instance, name: string): number
	local value = model:GetAttribute(name)
	return if typeof(value) == "number" then value else 0
end

-- Which storey of a cutaway model's building `position` is on (1 = the ground floor),
-- or nil when it's outside the building.
function FactoryView.StoreyAt(cutaway: Model, position: Vector3): number?
	local area = cutaway:GetAttribute("Area")
	local height = numberAttribute(cutaway, "StoreyHeight")
	if typeof(area) ~= "Vector3" or height <= 0 then
		return nil
	end
	local offset = cutaway:GetPivot():PointToObjectSpace(position)
	if math.abs(offset.X) > area.X / 2 or math.abs(offset.Z) > area.Z / 2 or offset.Y < -2 or offset.Y > area.Y then
		return nil
	end
	return math.floor(offset.Y / height) + 1
end

-- The storey of `building` (a plot's Building model) `position` is on, or nil.
local function storeyIn(building: Instance, position: Vector3): number?
	for _, child in building:GetChildren() do
		if child:IsA("Model") and typeof(child:GetAttribute("Area")) == "Vector3" then
			return FactoryView.StoreyAt(child, position)
		end
	end
	return nil
end

-- Where the player is looking from: their character, or the camera without one.
local function viewer(): Vector3
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		return root.Position
	end
	return workspace.CurrentCamera.CFrame.Position
end

-- Whether something at `position` can be in the player's view: it's in no factory, or
-- they're outside its factory, or on its storey.
function FactoryView.Sees(position: Vector3): boolean
	local tycoons = workspace:FindFirstChild("Tycoons")
	if not tycoons then
		return true
	end
	for _, plot in tycoons:GetChildren() do
		local building = plot:FindFirstChild("Building")
		local storey = building and storeyIn(building, position)
		if building and storey then
			local mine = storeyIn(building, viewer())
			return mine == nil or mine == storey
		end
	end
	return true
end

return FactoryView
