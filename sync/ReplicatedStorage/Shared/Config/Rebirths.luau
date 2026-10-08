--[[
	Rebirths (GDD §10). Placeholders to tune in playtests.
	Rebirthing resets Coins and the tycoon, and keeps everything else. Each rebirth is a
	level of the company mascot (Config/Mascot, Services/MascotManager): more Coins,
	line speed and luck, forever, and it unlocks zones.

	The Rebirth Shop is gone (the user, 2026-10-07: the mascot replaces it), and so are
	Rebirth Points. Levels bought there before still count (data.Upgrades, `Legacy`):
	the mascot shows them as part of its bonuses.
]]

export type Legacy = {
	Id: string,
	PerLevel: number,
}

export type Levels = { [string]: number } -- [upgradeId] = level (the old shop's)

local Rebirths = {
	-- Coins for the next rebirth: BaseCost x (rebirths + 1)^CostPower (100M, 800M, 2.7B,
	-- 6.4B ... 100B for the 10th). v5.6, the economy study: was 60B x3 per rebirth, which
	-- outran the mascot's bonuses (the 10th took ~30 h). A run's buttons are all bought in
	-- ~40 min, then you save at your best income, so each rebirth takes a little longer
	-- than the last (a perfect player in tools/economy_sim.py: 48, 44, 56 ... 74 min).
	BaseCost = 100000000,
	CostPower = 3,
	-- per rebirth (a mascot level), forever:
	IncomeBonus = 0.25, -- +25% ship value
	SpeedBonus = 0.05, -- +5% line speed (the old shop's Dropper Speed, now free)
	LuckPerRebirth = 0.1, -- +10% luck (rarer loot: Config/Loot)

	-- the old Rebirth Shop's upgrades, for the levels bought there
	Legacy = {
		{ Id = "Income", PerLevel = 0.1 },
		{ Id = "Speed", PerLevel = 0.05 },
		{ Id = "Luck", PerLevel = 0.1 },
	} :: { Legacy },
}

Rebirths.LegacyById = {} :: { [string]: Legacy }
for _, upgrade in Rebirths.Legacy do
	Rebirths.LegacyById[upgrade.Id] = upgrade
end

-- Coins needed to rebirth from `rebirths` to `rebirths + 1`.
function Rebirths.Cost(rebirths: number): number
	return math.floor(Rebirths.BaseCost * (rebirths + 1) ^ Rebirths.CostPower)
end

local function legacy(levels: Levels?, id: string): number
	return ((levels and levels[id]) or 0) * Rebirths.LegacyById[id].PerLevel
end

-- × Coins on every ship.
function Rebirths.IncomeMultiplier(rebirths: number, levels: Levels?): number
	return (1 + Rebirths.IncomeBonus * rebirths) * (1 + legacy(levels, "Income"))
end

-- × line speed (divides the cycle time).
function Rebirths.SpeedMultiplier(rebirths: number, levels: Levels?): number
	return 1 + Rebirths.SpeedBonus * rebirths + legacy(levels, "Speed")
end

-- Extra luck: rarer loot tiers get this much more weight (see Config/Loot).
function Rebirths.Luck(rebirths: number, levels: Levels?): number
	return Rebirths.LuckPerRebirth * rebirths + legacy(levels, "Luck")
end

return Rebirths
