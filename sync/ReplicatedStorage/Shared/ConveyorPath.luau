--[[
	ConveyorPath
	The Toy Workshop's Box Conveyor loop (a room upgrade, GDD §6): a rectangle with
	rounded corners (a LoopPath) hung near the ceiling, in room space (the room's floor
	center, -Z toward the front). RoomUpgradeBuilder lays the rail and the boxes along
	it; RoomFX moves the boxes round it.
]]

local LoopPath = require(script.Parent.LoopPath)

local ConveyorPath = {
	HalfX = 62, -- the loop's half width (the room's inner walls are at ±68)
	HalfZ = 51, -- and half depth, around CenterZ
	CenterZ = 1,
	Corner = 8, -- the corners' radius
	Height = 25, -- the rail, above the floor (the ceiling is at 28)
}

local loop = LoopPath.new(ConveyorPath.HalfX, ConveyorPath.HalfZ, ConveyorPath.Corner)
local origin = Vector3.new(0, ConveyorPath.Height, ConveyorPath.CenterZ)

ConveyorPath.Perimeter = loop.Perimeter

-- The point `distance` studs round the loop, and the way the loop heads there.
function ConveyorPath.Point(distance: number): (Vector3, Vector3)
	local at, heading = loop:Point(distance)
	return origin + at, heading
end

return ConveyorPath
