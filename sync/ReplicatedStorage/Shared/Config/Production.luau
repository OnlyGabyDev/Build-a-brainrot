-- Production tuning (GDD §6). Placeholders to tune in playtests.

local LineLayouts = require(script.Parent.Parent.LineLayouts)

local Production = {
	BaseCycleTime = 4, -- seconds per brainrot on a line with no Speed upgrades
	FullMatchMultiplier = 2, -- all 4 parts from the same brainrot

	-- The Assembler puts a brainrot together one part at a time, in this order, and
	-- each part has its own animation. Seconds per part at full show speed.
	AssemblyOrder = { "Legs", "Body", "Arms", "Head" },
	AssemblyTimes = { Legs = 0.5, Body = 1.2, Arms = 0.8, Head = 1.2 },
	-- A line that cycles faster than the full show speeds its Assembler up, so one
	-- brainrot is always finished within this share of the cycle, before the next arrives.
	AssemblyShare = 0.9,

	-- Client animation timings, in seconds.
	DropTime = 1.0, -- dropper to belt, the last 0.5 s the fall itself: first a part slides down
	-- a Toy Workshop chute, or a Plushie knitting machine knits it
	SlideTime = 1.2, -- belt ride from the farthest dropper to the Assembler
	ShowTime = 1.2, -- ta-da: the finished brainrot steps off the pad and shows itself off
	ShipTime = 2.4, -- from there to the end of the belt, past the stations (a layout can take longer: RideTime)
	SpecialTime = 1.3, -- the zone's special upgrade at the end of the belt (Toy Packer, Bow Tier)
	FinishTime = 2.0, -- the zone's finishing stage (packed in a toy box, fluffed up...)
}

export type Step = {
	PartType: string,
	Start: number, -- seconds after the ship event; the part reaches the Assembler then
	Duration: number,
}

-- The Assembler's schedule for one brainrot built from `parts` ([partType] = brainrotId)
-- on a line that ships every `cycleTime` seconds. Returns the steps and when the
-- finished brainrot leaves for the chute. Server and client both use it, so payouts
-- land in sync with the animation.
function Production.Schedule(parts: { [string]: string }, cycleTime: number): ({ Step }, number)
	local total = 0
	for _, partType in Production.AssemblyOrder do
		if parts[partType] then
			total += Production.AssemblyTimes[partType]
		end
	end
	local pace = math.max(1, total / (cycleTime * Production.AssemblyShare))

	local steps: { Step } = {}
	local time = Production.DropTime + Production.SlideTime
	for _, partType in Production.AssemblyOrder do
		if parts[partType] then
			local duration = Production.AssemblyTimes[partType] / pace
			table.insert(steps, { PartType = partType, Start = time, Duration = duration })
			time += duration
		end
	end
	return steps, time
end

-- How long the finishing stage takes on a line that ships every `cycleTime` seconds:
-- a fast line hurries it, so one brainrot is packed off before the next arrives.
function Production.FinishDuration(cycleTime: number): number
	return math.min(Production.FinishTime, cycleTime * 0.8)
end

-- How long the zone's special upgrade takes on a line that has it (hurried likewise).
function Production.SpecialDuration(cycleTime: number): number
	return math.min(Production.SpecialTime, cycleTime * 0.8)
end

-- How long the ta-da takes (hurried likewise: the next brainrot steps off the pad one
-- cycle later).
function Production.ShowDuration(cycleTime: number): number
	return math.min(Production.ShowTime, cycleTime * 0.6)
end

-- How long the finished brainrot takes from the show to the special on `zoneId`'s line
-- (its layout's ride; a rail's is slower than a belt's).
function Production.RideTime(zoneId: string): number
	return LineLayouts.For(zoneId).RideTime or Production.ShipTime
end

-- Seconds from a ship event until the brainrot is shipped off (the payout), at the end
-- of its finishing stage. `special`: the line has its zone's special upgrade.
function Production.ShipDelay(parts: { [string]: string }, cycleTime: number, special: boolean?, zoneId: string): number
	local _, finished = Production.Schedule(parts, cycleTime)
	local specialTime = if special then Production.SpecialDuration(cycleTime) else 0
	return finished + Production.ShowDuration(cycleTime) + Production.RideTime(zoneId) + specialTime + Production.FinishDuration(cycleTime)
end

return Production
