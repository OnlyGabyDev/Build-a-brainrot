--[[
	ConveyorPath
	The Toy Workshop's Box Conveyor loop (a room upgrade, GDD §6): a rectangle with
	rounded corners hung near the ceiling, in room space (the room's floor center, -Z
	toward the front). RoomUpgradeBuilder lays the rail and the boxes along it; RoomFX
	moves the boxes round it.
]]

local ConveyorPath = {
	HalfX = 62, -- the loop's half width (the room's inner walls are at ±68)
	HalfZ = 51, -- and half depth, around CenterZ
	CenterZ = 1,
	Corner = 8, -- the corners' radius
	Height = 25, -- the rail, above the floor (the ceiling is at 28)
}

local STRAIGHT_X = (ConveyorPath.HalfX - ConveyorPath.Corner) * 2
local STRAIGHT_Z = (ConveyorPath.HalfZ - ConveyorPath.Corner) * 2
local ARC = math.pi / 2 * ConveyorPath.Corner

ConveyorPath.Perimeter = (STRAIGHT_X + STRAIGHT_Z) * 2 + ARC * 4

-- The four sides in order, starting halfway along the +X side heading +Z: where each
-- starts, the way it heads, how long it is, and the center of the corner after it.
type Side = { Start: Vector3, Heading: Vector3, Length: number, Corner: Vector3? }
local SIDES: { Side } = (function()
	local x, z, c = ConveyorPath.HalfX, ConveyorPath.HalfZ, ConveyorPath.Corner
	return {
		{ Start = Vector3.new(x, 0, 0), Heading = Vector3.zAxis, Length = STRAIGHT_Z / 2, Corner = Vector3.new(x - c, 0, z - c) },
		{ Start = Vector3.new(x - c, 0, z), Heading = -Vector3.xAxis, Length = STRAIGHT_X, Corner = Vector3.new(-(x - c), 0, z - c) },
		{ Start = Vector3.new(-x, 0, z - c), Heading = -Vector3.zAxis, Length = STRAIGHT_Z, Corner = Vector3.new(-(x - c), 0, -(z - c)) },
		{ Start = Vector3.new(-(x - c), 0, -z), Heading = Vector3.xAxis, Length = STRAIGHT_X, Corner = Vector3.new(x - c, 0, -(z - c)) },
		{ Start = Vector3.new(x, 0, -(z - c)), Heading = Vector3.zAxis, Length = STRAIGHT_Z / 2, Corner = nil },
	}
end)()

-- The point `distance` studs round the loop, and the way the loop heads there.
function ConveyorPath.Point(distance: number): (Vector3, Vector3)
	local origin = Vector3.new(0, ConveyorPath.Height, ConveyorPath.CenterZ)
	local d = distance % ConveyorPath.Perimeter
	for index, side in SIDES do
		local start, heading, length, corner = side.Start, side.Heading, side.Length, side.Corner
		if d <= length or index == #SIDES then
			return origin + start + heading * d, heading
		end
		d -= length
		if corner then
			if d <= ARC then
				-- turning left round the corner's center
				local angle = d / ConveyorPath.Corner
				local outward = Vector3.new(heading.Z, 0, -heading.X)
				local away = outward * math.cos(angle) + heading * math.sin(angle)
				local turned = heading * math.cos(angle) - outward * math.sin(angle)
				return origin + corner + away * ConveyorPath.Corner, turned
			end
			d -= ARC
		end
	end
	return origin, Vector3.zAxis
end

return ConveyorPath
