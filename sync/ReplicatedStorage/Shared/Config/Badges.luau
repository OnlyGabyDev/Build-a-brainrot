--[[
	Roblox badges. Create each on the Creator Dashboard (the experience's Badges page),
	then paste its id here: an Id of 0 means "not created yet" and is never awarded.
	BadgeManager awards them; the code names the key ("Welcome"), never the id.
]]

export type Badge = {
	Id: number,
	Name: string, -- the dashboard's name (a note for whoever creates it)
	Description: string,
}

local Badges: { [string]: Badge } = {
	Welcome = { Id = 1138160550406212, Name = "Welcome to the Factory!", Description = "Joined Build a Brainrot." },
	-- only boxes picked up on the map count (not Rolls, not the wheel)
	FirstBox = { Id = 2554911339732604, Name = "Finders Keepers", Description = "Opened your first loot box on the map." },
}

return Badges
