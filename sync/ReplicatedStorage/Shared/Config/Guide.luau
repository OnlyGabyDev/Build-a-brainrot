--[[
	Guide
	Tralalero's guide (GDD §2): a newcomer's first steps, one at a time. Tralalero says
	each goal in a speech bubble (a few words and a big icon: many players are young), an
	arrow and a beam lead to it, and each step pays a small reward. The basics end on the
	first PERFECT and a gift (a new Rare+ part); then it teaches upgrading the line, shows
	the company mascot and sets a longer goal: opening the Plushie room. Every goal is
	something you walk to, or a button the guide points at, so it plays the same on PC,
	phones and consoles.

	The player's data keeps the step they're on (`Guide`, "Done" when finished; players
	from before the guide start at "Done"). Services/GuideManager moves it on;
	Guide.client shows it.
]]

export type Line = {
	Say: string, -- a few words
	Icon: string, -- big, beside it
}

export type Step = {
	Id: string,
	Say: string, -- Tralalero's line: a few words
	Icon: string, -- big, beside it
	Button: string?, -- the first line's button it's about ("Head", "Body"...)
	Track: string?, -- or a level of one of its upgrade tracks (any track's first level passes)
	Item: string?, -- or any other tycoon item, by its id (a room)
	Coins: number?, -- the reward for finishing it
	Rolls: number?,
	Then: Line?, -- what Tralalero adds after the reward, before the next goal
	Gift: boolean?, -- the basics end here: the gift (a new Rare+ part) and the favorite prompt
	Open: boolean?, -- a long goal: every button, ad and join popup comes back meanwhile
}

local Guide = {}

Guide.Done = "Done"
Guide.LineId = "ToyWorkshop_1" -- the line the guide builds
Guide.FinalRank = 3 -- the gift: a new part of this rarity rank or better (Rare+)
Guide.ThenTime = 3.5 -- seconds a step's Then line shows

Guide.Steps = {
	{ Id = "Intro", Say = "", Icon = "" }, -- the camera flies onto your factory (no bubble)
	{ Id = "Free", Say = "Step on FREE!", Icon = "Shoe", Button = "Head", Coins = 20 },
	{ Id = "Collect", Say = "Grab your cash!", Icon = "Coin", Coins = 20 },
	{ Id = "Box", Say = "Open your gift box!", Icon = "Gift", Rolls = 1 },
	{ Id = "Body", Say = "Buy the BODY!", Icon = "Puzzle", Button = "Body", Coins = 60 },
	{ Id = "Arms", Say = "Buy the ARMS!", Icon = "Puzzle", Button = "Arms", Coins = 150 },
	{ Id = "Legs", Say = "Buy the LEGS!", Icon = "Puzzle", Button = "Legs", Rolls = 1 },
	{ Id = "Perfect", Say = "Watch: a PERFECT build!", Icon = "Star", Gift = true },
	{ Id = "Upgrade", Say = "Upgrade your line!", Icon = "ArrowUp", Track = "Droppers", Rolls = 1 },
	{
		Id = "Mascot",
		Say = "Meet your MASCOT!",
		Icon = "Crown",
		Coins = 1000,
		Then = { Say = "REBIRTH to make it grow!", Icon = "Rebirth" },
	},
	{ Id = "Plushie", Say = "Open the PLUSHIE ROOM!", Icon = "Unlock", Item = "PlushieRoom_Room", Rolls = 2, Open = true },
} :: { Step }

-- What Tralalero says while the arrow points somewhere else first (GuideManager's
-- "GuideSay"): the line, while the Cash Pad waits for its first Coins.
Guide.Hints = {
	Watch = { Id = "Watch", Say = "Watch it build!", Icon = "Hammer" },
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

-- Whether the guide has the player's attention: a step that isn't an Open one. Meanwhile
-- no ads or join popups show, and other buttons' arrows hide.
function Guide.Focused(step: string?): boolean
	local info = if step then Guide.ById[step] else nil
	return Guide.Running(step) and not (info and info.Open)
end

-- The tycoon item a step's price comes from (its button, its track's first level, its
-- item), or nil.
function Guide.ItemOf(step: Step): string?
	if step.Button then
		return `{Guide.LineId}_{step.Button}`
	elseif step.Track then
		return `{Guide.LineId}_Up{step.Track}_1`
	end
	return step.Item
end

-- While the guide has the player's attention, only the first line's own buttons show
-- (its next dropper or upgrade): new rooms, floors, room upgrades and more lines wait.
function Guide.HidesButton(step: string?, kind: string, lineId: string?): boolean
	return Guide.Focused(step) and (lineId ~= Guide.LineId or kind == "Line")
end

return Guide
