--[[
	Mascot (GDD §10, "The company mascot"; the user, 2026-10-07)
	Every factory has a mascot out front, beside the path to the hub: a brainrot its
	owner builds part by part (any part they own, mixes allowed; it starts as the
	starter), on a stand that grows with its level. **Its level is the owner's rebirth
	count**: each rebirth levels it up, and each level is more Coins, line speed and luck
	(the numbers live in Config/Rebirths). It replaces the Rebirth Shop.
	It starts small on a crate and grows into a giant statue (v2, the user: like the
	store signs in Retail Tycoon that grow with each upgrade): every level makes the
	brainrot and its stand bigger, and every level or two adds a look, a new stand every
	few levels (a crate, a marble pedestal, a gold stand, a fountain plaza, a monument).
	Services/MascotManager builds it; Client/UI/MascotMenu opens from its prompt.
]]

export type Look = { Key: string, Level: number, Name: string }

local Mascot = {
	Spot = Vector3.new(-30, 0, -86), -- in plot space: the front yard, left of the path to the hub
	Facing = Vector3.new(0.45, 0, -1), -- (plot space) toward the hub, turned a little to the path (a walk of stepping stones comes from there)
	-- the looks its stand gets at these levels (each keeps the ones before)
	Looks = {
		{ Key = "BigCrate", Level = 1, Name = "A BIGGER CRATE" }, -- wrapped in the factory's color
		{ Key = "Pedestal", Level = 2, Name = "A MARBLE PEDESTAL" }, -- with a neon trim
		{ Key = "Spotlights", Level = 3, Name = "SPOTLIGHTS" }, -- two lamps aimed at it
		{ Key = "Banners", Level = 4, Name = "BANNERS" }, -- flags on poles either side
		{ Key = "Gold", Level = 5, Name = "A GOLD STAND" }, -- a wide step, gold trims, sparkles
		{ Key = "Bulbs", Level = 6, Name = "MARQUEE LIGHTS" }, -- chasing bulbs round its trims
		{ Key = "Fountain", Level = 7, Name = "A FOUNTAIN" }, -- a basin round it with jets
		{ Key = "Searchlights", Level = 8, Name = "SKY SEARCHLIGHTS" }, -- two beams sweeping the sky
		{ Key = "Columns", Level = 9, Name = "GOLDEN COLUMNS" }, -- a colonnade behind it
		{ Key = "Monument", Level = 10, Name = "A GIANT MONUMENT" }, -- three steps, its owner's name in neon, fireworks
		{ Key = "Crown", Level = 12, Name = "A GOLDEN CROWN" }, -- floating over its head
		{ Key = "Rings", Level = 15, Name = "GOLDEN RINGS" }, -- orbiting it
		{ Key = "Rainbow", Level = 20, Name = "RAINBOW NEON" }, -- its trims and bulbs cycle the rainbow
	} :: { Look },
	Stages = {} :: { [string]: number }, -- [Key] = Level, from Looks
	-- the brainrot's size: Base, PerLevel up to level Level, then After per level up to Max
	Scale = { Base = 1.3, PerLevel = 0.37, Level = 10, After = 0.15, Max = 20 },
	MaxRadius = 24, -- studs it may reach from its middle while it turns (the yard's room; boxes keep this far off)
}
for _, look in Mascot.Looks do
	Mascot.Stages[look.Key] = look.Level
end

-- How big the mascot brainrot is at `level` (before it's fit into MaxRadius).
function Mascot.ScaleAt(level: number): number
	local scale = Mascot.Scale
	local early = math.min(level, scale.Level)
	local late = math.clamp(level - scale.Level, 0, scale.Max - scale.Level)
	return scale.Base + scale.PerLevel * early + scale.After * late
end

-- The look a mascot of `level` gets next, if any.
function Mascot.NextLook(level: number): Look?
	for _, look in Mascot.Looks do
		if look.Level > level then
			return look
		end
	end
	return nil
end

return Mascot
