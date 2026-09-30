--[[
	Gamepasses (GDD §12). Create each pass on the Creator Dashboard, then paste its id
	here. An Id of 0 means "not created yet": nobody owns it, and the buy button shows
	a "coming soon" message instead of a purchase prompt.
]]

export type Pass = {
	Id: number,
	Name: string,
	Description: string,
}

local Gamepasses: { [string]: Pass } = {
	AutoCollect = {
		Id = 0,
		Name = "Auto-Collect",
		Description = "Coins bank automatically, and you can configure your lines from anywhere.",
	},
}

return Gamepasses
