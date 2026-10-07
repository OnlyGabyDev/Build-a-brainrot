--[[
	Guide
	Tralalero's guide (GDD §2): a newcomer's first steps, one at a time. Tralalero says
	each goal in a speech bubble (a few words and a big icon: many players are young), an
	arrow and a beam lead to it, and each step pays a small reward; the last one gives a
	new Rare+ part. Every goal is something you walk to (no clicks), so it plays the same
	on PC, phones and consoles.

	The player's data keeps the step they're on (`Guide`, "Done" when finished; players
	from before the guide start at "Done"). Services/GuideManager moves it on;
	Guide.client shows it.
]]

export type Step = {
	Id: string,
	Say: string, -- Tralalero's line: a few words
	Icon: string, -- big, beside it
	Button: string?, -- the first line's button it's about ("Head", "Body"...)
	Coins: number?, -- the reward for finishing it
	Rolls: number?,
}

local Guide = {}

Guide.Done = "Done"
Guide.LineId = "ToyWorkshop_1" -- the line the guide builds
Guide.FinalRank = 3 -- the last gift: a new part of this rarity rank or better (Rare+)

Guide.Steps = {
	{ Id = "Intro", Say = "", Icon = "" }, -- the camera flies onto your factory (no bubble)
	{ Id = "Free", Say = "Step on FREE!", Icon = "Shoe", Button = "Head", Coins = 20 },
	{ Id = "Collect", Say = "Grab your cash!", Icon = "Coin", Coins = 20 },
	{ Id = "Box", Say = "Open your gift box!", Icon = "Gift", Rolls = 1 },
	{ Id = "Body", Say = "Buy the BODY!", Icon = "Puzzle", Button = "Body", Coins = 60 },
	{ Id = "Arms", Say = "Buy the ARMS!", Icon = "Puzzle", Button = "Arms", Coins = 150 },
	{ Id = "Legs", Say = "Buy the LEGS!", Icon = "Puzzle", Button = "Legs", Rolls = 1 },
	{ Id = "Perfect", Say = "Watch: a PERFECT build!", Icon = "Star" },
} :: { Step }

-- What Tralalero says while the arrow points somewhere else first (GuideManager's
-- "GuideSay"): the line, while the Cash Pad waits for its first Coins.
Guide.Hints = {
	Watch = { Id = "Watch", Say = "Watch it build!", Icon = "Eye" },
} :: { [string]: Step }

Guide.ById = {} :: { [string]: Step }
Guide.IndexOf = {} :: { [string]: number }
for index, step in Guide.Steps do
	Guide.ById[step.Id] = step
	Guide.IndexOf[step.Id] = index
end

-- The step after `id` ("Done" after the last).
function Guide.Next(id: string): string
	local index = Guide.IndexOf[id]
	local step = index and Guide.Steps[index + 1]
	return if step then step.Id else Guide.Done
end

-- Whether the player is somewhere in the guide (nil: their data hasn't loaded).
function Guide.Running(step: string?): boolean
	return step ~= nil and step ~= Guide.Done
end

-- While the guide runs, only the first line's own buttons show (its next dropper or
-- upgrade): new rooms, floors, room upgrades and more lines wait until it's done.
function Guide.HidesButton(step: string?, kind: string, lineId: string?): boolean
	return Guide.Running(step) and (lineId ~= Guide.LineId or kind == "Line")
end

return Guide
