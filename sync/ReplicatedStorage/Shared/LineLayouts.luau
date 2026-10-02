--[[
	LineLayouts
	Every room's line has a layout of its own (GDD §6): where its droppers, stations,
	delivery, buttons and tablet stand, and which way the finished brainrot goes. All in
	line space: the origin on the floor at the pad (the middle of the Assembler's glass
	capsule), the pad's top Deck above it, and -Z the way the brainrot leaves. TycoonManager
	builds each line from its zone's layout and stamps the line Model with its Origin (a
	CFrame attribute: line space in the world), so ProductionVisuals animates it along the
	same layout. The server only times things (Config/Production), so payouts don't depend
	on the layout.

	  * Belt (the Toy Workshop, and rooms without a layout of their own yet): the parts
	    drop onto a straight conveyor and ride it into the capsule, and the brainrot rides
	    on past the stations beside it to the delivery at its end.
	  * Rail (the Plushie room): no belt. The knitting machines stand in an arc round the
	    capsule and knit their parts right into it; then a hook comes along a rail winding
	    near the ceiling, takes the brainrot out through the capsule's open front and
	    carries it, swinging, through the stations to the delivery.
]]

export type Halo = { At: CFrame, Radius: number }

export type Layout = {
	Kind: string, -- "Belt" | "Rail"
	Droppers: { [string]: CFrame }, -- each dropper's spot on the floor, under the mouth its part comes out of
	Halos: { [string]: Halo }, -- the Dropper Power track's ring of lights round each dropper
	Stations: { [string]: CFrame }, -- Station1, Station2, Station3 (the zone's special)
	Ship: CFrame, -- the delivery
	ShipRadius: number, -- how far round it the Premium Shipping track's lights go
	Buttons: { [string]: Vector3 }, -- by item key (Line, Speed1, Head, Station1...)
	Tablet: Vector3,
	TabletFacing: Vector3, -- the way its screen faces (toward the button path)
	ShowGap: number, -- how far toward -Z from the pad the brainrot shows itself off
	Rail: { Vector3 }?, -- the rail's control points (y: the rail's middle above the floor)
	Stops: { [string]: number }?, -- Rail: the control point (index) where each thing happens
}

export type Curve = {
	Points: { Vector3 },
	Lengths: { number }, -- distance along the curve at each point
	Length: number,
	Knots: { number }, -- distance along the curve at each control point
}

local LineLayouts = {}

LineLayouts.Deck = 4 -- the pad's top (and a belt's), above the floor

local DECK = LineLayouts.Deck
local BUTTON_X = 13 -- the button path, along each line's +X side

-- The straight conveyor -----------------------------------------------------------

local BELT_DROPPER_Z = { Head = 38, Body = 30, Arms = 22, Legs = 14 }
local BELT_STATION_Z = { Station1 = -15, Station2 = -24, Station3 = -33 } -- Station3: over the belt's end

local function beltLayout(): Layout
	local layout: Layout = {
		Kind = "Belt",
		Droppers = {},
		Halos = {},
		Stations = {},
		Ship = CFrame.new(0, 0, -41.5), -- just past the end of the belt
		ShipRadius = 5.4,
		Buttons = {
			Line = Vector3.new(0, 0, -52),
			Speed1 = Vector3.new(BUTTON_X, 0, 4), -- (a line shows one button at a time: they share a spot)
			Speed2 = Vector3.new(BUTTON_X, 0, 4),
		},
		Tablet = Vector3.new(11.5, 0, -11.5), -- by the button path, off the capsule's front
		TabletFacing = Vector3.new(math.cos(math.rad(25)), 0, -math.sin(math.rad(25))),
		ShowGap = 4,
	}
	for partType, z in BELT_DROPPER_Z do
		layout.Droppers[partType] = CFrame.new(0, 0, z)
		layout.Halos[partType] = { At = CFrame.new(0, DECK + 6.5, z), Radius = 3.5 }
		layout.Buttons[partType] = Vector3.new(BUTTON_X, 0, z)
	end
	for key, z in BELT_STATION_Z do
		layout.Stations[key] = CFrame.new(0, 0, z)
		layout.Buttons[key] = Vector3.new(BUTTON_X, 0, z)
	end
	return layout
end

-- The overhead rail (Plushie room) ------------------------------------------------

LineLayouts.RailY = 22.5 -- the rail's middle, above the floor (the ceiling is at 28)
-- The knitting machines in an arc round the back of the capsule: their heads reach in
-- over the glass (KnitRadius from the pad), their columns stand outside it.
LineLayouts.KnitRadius = 7.2
LineLayouts.KnitColumnRadius = 13.6
LineLayouts.KnitMouth = 15.4 -- the heads' mouths, above the floor
local KNIT_ANGLES = { Legs = 60, Body = 20, Arms = -20, Head = -60 } -- degrees from the back (+Z) toward +X

-- A spot on the arc, its -X pointing out (to the machine's column).
local function arcSpot(degrees: number, radius: number): CFrame
	local angle = math.rad(degrees)
	local s, c = math.sin(angle), math.cos(angle)
	return CFrame.fromMatrix(Vector3.new(s * radius, 0, c * radius), Vector3.new(-s, 0, -c), Vector3.yAxis)
end

local function railLayout(): Layout
	local y = LineLayouts.RailY
	local layout: Layout = {
		Kind = "Rail",
		Droppers = {},
		Halos = {},
		-- each under its stop on the rail
		Stations = {
			Station1 = CFrame.new(-5, 0, -19), -- the Dye Bath's vat: it's dipped in
			Station2 = CFrame.new(4, 0, -26.5), -- the Sequin Shower rains on it
			Station3 = CFrame.new(-2, 0, -33.5), -- the Bow Tier
		},
		Ship = CFrame.new(0, 0, -41.5), -- the fluff jar: it's lowered in
		ShipRadius = 6.9,
		Buttons = {
			Line = Vector3.new(0, 0, -52),
			Speed1 = Vector3.new(BUTTON_X, 0, -4), -- clear of the Legs machine's column
			Speed2 = Vector3.new(BUTTON_X, 0, -4),
			Station1 = Vector3.new(BUTTON_X, 0, -19),
			Station2 = Vector3.new(BUTTON_X, 0, -26.5),
			Station3 = Vector3.new(BUTTON_X, 0, -33.5),
		},
		Tablet = Vector3.new(11.5, 0, -11.5),
		TabletFacing = Vector3.new(math.cos(math.rad(25)), 0, -math.sin(math.rad(25))),
		ShowGap = 5, -- under the hook's pickup, clear of the crossbar
		-- it starts in a hook garage over the capsule's left side, winds out the front,
		-- and ends in another past the delivery
		Rail = {
			Vector3.new(-8.5, y, -5),
			Vector3.new(0, y, -5),
			Vector3.new(0, y, -13),
			Vector3.new(-5, y, -19),
			Vector3.new(4, y, -26.5),
			Vector3.new(-2, y, -33.5),
			Vector3.new(0, y, -41.5),
			Vector3.new(0, y, -47.5),
		},
		Stops = { Start = 1, Pickup = 2, Out = 3, Station1 = 4, Station2 = 5, Station3 = 6, Ship = 7, End = 8 },
	}
	for partType, degrees in KNIT_ANGLES do
		layout.Droppers[partType] = arcSpot(degrees, LineLayouts.KnitRadius)
		-- hugging the knitting head, just under its mouth
		layout.Halos[partType] = { At = arcSpot(degrees, LineLayouts.KnitRadius) + Vector3.new(0, LineLayouts.KnitMouth - 0.4, 0), Radius = 2.4 }
	end
	for partType, z in { Legs = 14, Body = 22, Arms = 30, Head = 38 } do
		layout.Buttons[partType] = Vector3.new(BUTTON_X, 0, z) -- behind the machines, along the path
	end
	return layout
end

local BELT = beltLayout()
local LAYOUTS: { [string]: Layout } = {
	PlushieRoom = railLayout(),
}

-- The layout of `zoneId`'s lines.
function LineLayouts.For(zoneId: string): Layout
	return LAYOUTS[zoneId] or BELT
end

-- Curves --------------------------------------------------------------------------

-- A point between p1 and p2 (`t` from 0 to 1) on a Catmull-Rom curve.
local function catmullRom(p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, t: number): Vector3
	local t2, t3 = t * t, t * t * t
	return 0.5 * ((2 * p1) + (p2 - p0) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t2 + (3 * p1 - p0 - 3 * p2 + p3) * t3)
end

-- A smooth curve through `points`, sampled about every half stud.
function LineLayouts.Curve(points: { Vector3 }): Curve
	local samples: { Vector3 } = {}
	local lengths: { number } = {}
	local knots: { number } = {}
	local total = 0
	local count = #points
	for index = 1, count - 1 do
		knots[index] = total
		local p0 = points[math.max(index - 1, 1)]
		local p1, p2 = points[index], points[index + 1]
		local p3 = points[math.min(index + 2, count)]
		local steps = math.max(4, math.ceil((p2 - p1).Magnitude * 2))
		for k = if index == 1 then 0 else 1, steps do
			local point = catmullRom(p0, p1, p2, p3, k / steps)
			local last = samples[#samples]
			if last then
				total += (point - last).Magnitude
			end
			table.insert(samples, point)
			table.insert(lengths, total)
		end
	end
	knots[count] = total
	return { Points = samples, Lengths = lengths, Length = total, Knots = knots }
end

-- The point `distance` along the curve, and the way it heads there.
function LineLayouts.At(curve: Curve, distance: number): (Vector3, Vector3)
	local points, lengths = curve.Points, curve.Lengths
	local d = math.clamp(distance, 0, curve.Length)
	local low, high = 1, #points
	while high - low > 1 do
		local middle = (low + high) // 2
		if lengths[middle] <= d then
			low = middle
		else
			high = middle
		end
	end
	local a, b = points[low], points[high]
	local span = lengths[high] - lengths[low]
	local heading = b - a
	if heading.Magnitude < 1e-4 then
		heading = Vector3.zAxis
	end
	return a:Lerp(b, if span > 0 then (d - lengths[low]) / span else 0), heading.Unit
end

-- The rail of a Rail layout as a curve (line space), or nil.
local railCurves: { [Layout]: Curve } = {}
function LineLayouts.RailCurve(layout: Layout): Curve?
	local rail = layout.Rail
	if not rail then
		return nil
	end
	local curve = railCurves[layout]
	if not curve then
		curve = LineLayouts.Curve(rail)
		railCurves[layout] = curve
	end
	return curve
end

return LineLayouts
