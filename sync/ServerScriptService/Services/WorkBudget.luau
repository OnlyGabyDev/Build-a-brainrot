--[[
	WorkBudget
	Spreads long builds over several frames: the world at startup (6 factories, the
	terrain, the hub) and a factory being furnished when its owner joins. Call Step()
	between pieces of work: once the current frame has spent SLICE seconds building, it
	waits a frame. The server keeps ticking meanwhile (other players' lines, purchases),
	and in Studio's Play Solo (server and client share one process) the window keeps
	drawing instead of freezing. Only call it where yielding is fine.
]]

local WorkBudget = {}

local SLICE = 0.012 -- seconds of building per frame (a 60 Hz frame is ~16.7 ms)

local sliceStart = os.clock()

function WorkBudget.Step()
	if os.clock() - sliceStart >= SLICE then
		task.wait()
		sliceStart = os.clock()
	end
end

return WorkBudget
