--[[
	Rebirths and the Rebirth Shop (GDD §10). Placeholders to tune in playtests.
	Rebirthing resets Coins and the tycoon, and keeps everything else. Each rebirth
	gives Rebirth Points, a permanent income boost and luck, and unlocks zones.
]]

export type Upgrade = {
	Id: string,
	Name: string,
	Icon: string,
	Description: string, -- per level
	PerLevel: number,
	MaxLevel: number,
	BaseCost: number, -- Rebirth Points for level 1; each level costs BaseCost more
}

export type Levels = { [string]: number } -- [upgradeId] = level

local Rebirths = {
	BaseCost = 100000000000, -- Coins needed for the first rebirth (~5 h of play: the economy pass)...
	CostGrowth = 3, -- ...and each next one costs this much more
	IncomeBonus = 0.25, -- +25% ship value per rebirth, forever
	LuckPerRebirth = 0.1, -- +10% luck per rebirth, forever (rarer loot: Config/Loot)

	Upgrades = {
		{
			Id = "Income",
			Name = "Income",
			Icon = "💰",
			Description = "+10% Coins",
			PerLevel = 0.1,
			MaxLevel = 20,
			BaseCost = 1,
		},
		{
			Id = "Speed",
			Name = "Dropper Speed",
			Icon = "⚡",
			Description = "+5% line speed",
			PerLevel = 0.05,
			MaxLevel = 10,
			BaseCost = 1,
		},
		{
			Id = "Luck",
			Name = "Luck",
			Icon = "🍀",
			Description = "+10% Luck (rarer loot)",
			PerLevel = 0.1,
			MaxLevel = 10,
			BaseCost = 2,
		},
	} :: { Upgrade },
}

Rebirths.UpgradesById = {} :: { [string]: Upgrade }
for _, upgrade in Rebirths.Upgrades do
	Rebirths.UpgradesById[upgrade.Id] = upgrade
end

-- Coins needed to rebirth from `rebirths` to `rebirths + 1`.
function Rebirths.Cost(rebirths: number): number
	return math.floor(Rebirths.BaseCost * Rebirths.CostGrowth ^ rebirths)
end

-- Rebirth Points for rebirthing with `coins`: one per full cost's worth, so saving
-- up past the cost pays off.
function Rebirths.Points(coins: number, rebirths: number): number
	return math.max(1, math.floor(coins / Rebirths.Cost(rebirths)))
end

-- Rebirth Points for the next level of an upgrade.
function Rebirths.UpgradeCost(upgrade: Upgrade, level: number): number
	return upgrade.BaseCost * (level + 1)
end

local function bonus(levels: Levels, id: string): number
	return (levels[id] or 0) * Rebirths.UpgradesById[id].PerLevel
end

-- × Coins on every ship: rebirths plus the Income upgrade.
function Rebirths.IncomeMultiplier(rebirths: number, levels: Levels): number
	return (1 + Rebirths.IncomeBonus * rebirths) * (1 + bonus(levels, "Income"))
end

-- × line speed (divides the cycle time).
function Rebirths.SpeedMultiplier(levels: Levels): number
	return 1 + bonus(levels, "Speed")
end

-- Extra luck: rarer loot tiers get this much more weight (see Config/Loot). Rebirths
-- plus the Luck upgrade.
function Rebirths.Luck(rebirths: number, levels: Levels): number
	return Rebirths.LuckPerRebirth * rebirths + bonus(levels, "Luck")
end

return Rebirths
