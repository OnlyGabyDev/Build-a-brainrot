-- Production tuning (GDD §6). Placeholders to tune in playtests.

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
	DropTime = 0.8, -- dropper to belt: the Toy Workshop's parts slide down a ceiling chute first
	SlideTime = 1.2, -- belt ride from the farthest dropper to the Assembler
	ShipTime = 1.0, -- Assembler to shipping chute
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

-- Seconds from a ship event until the brainrot drops into the chute (the payout).
function Production.ShipDelay(parts: { [string]: string }, cycleTime: number): number
	local _, finished = Production.Schedule(parts, cycleTime)
	return finished + Production.ShipTime
end

return Production
