--[[
	LoopPath
	A closed loop on the ground (the XZ plane, around the origin): a rectangle with
	rounded corners. With the corner as wide as the loop it's a stadium (an oval track),
	and with every half equal, a circle. Things ride round it at a distance along it:
	the Box Conveyor's boxes (ConveyorPath) and the Toy Train's cars (RoomFX).
]]

export type LoopPath = {
	HalfX: number,
	HalfZ: number,
	Corner: number,
	Perimeter: number,
	Point: (self: LoopPath, distance: number) -> (Vector3, Vector3),
}

type Side = { Start: Vector3, Heading: Vector3, Length: number, Corner: Vector3? }

local LoopPath = {}

-- The point `distance` along the loop, and the way the loop heads there. It starts
-- halfway along the +X side heading +Z and turns left round the corners.
local function point(self: any, distance: number): (Vector3, Vector3)
	local sides: { Side } = self.Sides
	local corner, arc = self.Corner, self.Arc
	local d = distance % self.Perimeter
	for index, side in sides do
		local start, heading, length = side.Start, side.Heading, side.Length
		if d <= length or index == #sides then
			return start + heading * d, heading
		end
		d -= length
		if side.Corner then
			if d <= arc then
				local angle = d / corner
				local outward = Vector3.new(heading.Z, 0, -heading.X)
				local away = outward * math.cos(angle) + heading * math.sin(angle)
				local turned = heading * math.cos(angle) - outward * math.sin(angle)
				return side.Corner + away * corner, turned
			end
			d -= arc
		end
	end
	return Vector3.zero, Vector3.zAxis
end

function LoopPath.new(halfX: number, halfZ: number, corner: number): LoopPath
	local straightX = (halfX - corner) * 2
	local straightZ = (halfZ - corner) * 2
	local arc = math.pi / 2 * corner
	local x, z, c = halfX, halfZ, corner
	local self = {
		HalfX = halfX,
		HalfZ = halfZ,
		Corner = corner,
		Perimeter = (straightX + straightZ) * 2 + arc * 4,
		Arc = arc,
		Sides = {
			{ Start = Vector3.new(x, 0, 0), Heading = Vector3.zAxis, Length = straightZ / 2, Corner = Vector3.new(x - c, 0, z - c) },
			{ Start = Vector3.new(x - c, 0, z), Heading = -Vector3.xAxis, Length = straightX, Corner = Vector3.new(-(x - c), 0, z - c) },
			{ Start = Vector3.new(-x, 0, z - c), Heading = -Vector3.zAxis, Length = straightZ, Corner = Vector3.new(-(x - c), 0, -(z - c)) },
			{ Start = Vector3.new(-(x - c), 0, -z), Heading = Vector3.xAxis, Length = straightX, Corner = Vector3.new(x - c, 0, -(z - c)) },
			{ Start = Vector3.new(x, 0, -(z - c)), Heading = Vector3.zAxis, Length = straightZ / 2, Corner = nil },
		},
		Point = point,
	}
	return (self :: any) :: LoopPath
end

return LoopPath
