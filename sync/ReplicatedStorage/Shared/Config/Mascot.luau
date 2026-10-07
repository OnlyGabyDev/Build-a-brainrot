--[[
	Mascot (GDD §10, "The company mascot"; the user, 2026-10-07)
	Every factory has a mascot out front, beside the path to the hub: a brainrot its
	owner builds part by part (any part they own, mixes allowed; it starts as the
	starter), on a stand that grows with its level. **Its level is the owner's rebirth
	count**: each rebirth levels it up, and each level is more Coins, line speed and luck
	(the numbers live in Config/Rebirths). It replaces the Rebirth Shop.
	Services/MascotManager builds it; Client/UI/MascotMenu opens from its prompt.
]]

local Mascot = {
	Spot = Vector3.new(-30, 0, -86), -- in plot space: the front yard, left of the path to the hub
	-- the stand adds these at these levels (each keeps the ones before):
	Stages = {
		BigCrate = 1, -- a bigger crate wrapped in the factory's color
		Pedestal = 2, -- a marble pedestal with a neon trim
		Spotlights = 3, -- two spotlights on it
		Banners = 4, -- flags on poles either side
		Gold = 5, -- the pedestal's trims turn gold, sparkles
		Fountain = 7, -- a fountain round it
		Fireworks = 10, -- fireworks over it now and then
	},
	Scale = { Base = 1.4, PerLevel = 0.1, MaxLevel = 15 }, -- the brainrot's size: Base + PerLevel × level (up to MaxLevel)
}

-- How big the mascot brainrot is at `level`.
function Mascot.ScaleAt(level: number): number
	return Mascot.Scale.Base + Mascot.Scale.PerLevel * math.min(level, Mascot.Scale.MaxLevel)
end

return Mascot
