--[[
	Every tycoon purchase button, generated from the zones (GDD §6).
	Ids: line "ToyWorkshop_1", its unlock "ToyWorkshop_1_Line", its items
	"ToyWorkshop_1_Head", "ToyWorkshop_1_Speed1", ...; room upgrades (Config/RoomUpgrades)
	"ToyWorkshop_Decor_GiftTower_1", one per level.
	Buttons appear one after another: each item requires the previous one.
	Prices are placeholders to tune in playtests.
]]

local RoomUpgrades = require(script.Parent.RoomUpgrades)
local Zones = require(script.Parent.Zones)

export type Item = {
	Id: string,
	Key: string, -- "Line", "Head", "Speed1", ... (used for layout)
	Name: string,
	Kind: string, -- "Line" | "Dropper" | "Speed" | "Station" | "Decor" (a room upgrade's level)
	Price: number,
	Requires: string?, -- item that must be bought first
	Zone: string,
	LineId: string?, -- every kind but Decor
	PartType: string?, -- Dropper only
	Multiplier: number?, -- Speed: cycle speed ×, Station: ship value ×, Decor: the room's ship value ×
	Level: number?, -- Decor only
	Rebirths: number?, -- Decor only: rebirths needed to buy it
}

export type Line = {
	Id: string,
	Zone: string,
	Index: number, -- position within its zone
	UnlockItemId: string,
	Items: { Item },
}

-- The button chain on every line, after the line itself. Prices are multiplied per line.
local LINE_ITEMS = {
	{ Key = "Head", Name = "Head Dropper", Kind = "Dropper", PartType = "Head", Price = 0 },
	{ Key = "Body", Name = "Body Dropper", Kind = "Dropper", PartType = "Body", Price = 40 },
	{ Key = "Arms", Name = "Arms Dropper", Kind = "Dropper", PartType = "Arms", Price = 120 },
	{ Key = "Legs", Name = "Legs Dropper", Kind = "Dropper", PartType = "Legs", Price = 300 },
	{ Key = "Speed1", Name = "Turbo Belt", Kind = "Speed", Multiplier = 1.5, Price = 700 },
	{ Key = "Station1", Name = "Paint Booth", Kind = "Station", Multiplier = 1.5, Price = 1500 },
	{ Key = "Speed2", Name = "Mega Turbo", Kind = "Speed", Multiplier = 1.5, Price = 4000 },
	{ Key = "Station2", Name = "Glitter Blaster", Kind = "Station", Multiplier = 2, Price = 9000 },
	-- the zone's own special upgrade, named by the zone (Zones.SpecialStation)
	{ Key = "Station3", Name = "", Kind = "Station", Multiplier = 2, Price = 25000 },
}

-- Per line index within a zone: price to unlock the line, and multiplier on its items.
-- Both are also multiplied by the zone's PriceMultiplier. A zone's first line is free
-- once the zone unlocks.
local LINE_UNLOCK_PRICES = { 0, 2500, 30000 }
local LINE_PRICE_SCALES = { 1, 8, 60 }

local TycoonItems = {}

TycoonItems.List = {} :: { Item }
TycoonItems.ById = {} :: { [string]: Item }
TycoonItems.Lines = {} :: { Line }
TycoonItems.LinesById = {} :: { [string]: Line }
TycoonItems.DecorByZone = {} :: { [string]: { Item } } -- every room upgrade level, per zone

local function register(item: Item)
	assert(not TycoonItems.ById[item.Id], `Duplicate tycoon item {item.Id}`)
	table.insert(TycoonItems.List, item)
	TycoonItems.ById[item.Id] = item
end

local function add(line: Line, item: Item)
	register(item)
	table.insert(line.Items, item)
end

for _, zone in Zones.List do
	if not zone.Available then
		continue
	end
	assert(zone.LineCount <= #LINE_UNLOCK_PRICES, `{zone.Id} has more lines than LINE_UNLOCK_PRICES`)

	for index = 1, zone.LineCount do
		local lineId = `{zone.Id}_{index}`
		local line: Line = {
			Id = lineId,
			Zone = zone.Id,
			Index = index,
			UnlockItemId = `{lineId}_Line`,
			Items = {},
		}

		add(line, {
			Id = line.UnlockItemId,
			Key = "Line",
			Name = `Assembly Line {index}`,
			Kind = "Line",
			Price = LINE_UNLOCK_PRICES[index] * zone.PriceMultiplier,
			-- Each new line opens once the previous one has all 4 droppers.
			Requires = if index > 1 then `{zone.Id}_{index - 1}_Legs` else nil,
			Zone = zone.Id,
			LineId = lineId,
		})

		local requires = line.UnlockItemId
		for _, template in LINE_ITEMS do
			local name = if zone.StationNames then zone.StationNames[template.Key] or template.Name else template.Name
			if template.Key == "Station3" then
				if not zone.SpecialStation then
					continue
				end
				name = zone.SpecialStation
			end
			local id = `{lineId}_{template.Key}`
			add(line, {
				Id = id,
				Key = template.Key,
				Name = name,
				Kind = template.Kind,
				Price = template.Price * LINE_PRICE_SCALES[index] * zone.PriceMultiplier,
				Requires = requires,
				Zone = zone.Id,
				LineId = lineId,
				PartType = template.PartType,
				Multiplier = template.Multiplier,
			})
			requires = id
		end

		table.insert(TycoonItems.Lines, line)
		TycoonItems.LinesById[lineId] = line
	end
end

-- Room upgrades: a button per level, each after the one before.
for _, upgrade in RoomUpgrades.List do
	local zone = Zones.ById[upgrade.Zone]
	if not (zone and zone.Available) then
		continue
	end
	local decor = TycoonItems.DecorByZone[zone.Id] or {}
	TycoonItems.DecorByZone[zone.Id] = decor
	local requires: string? = nil
	for level, info in upgrade.Levels do
		local item: Item = {
			Id = `{zone.Id}_Decor_{upgrade.Key}_{level}`,
			Key = upgrade.Key,
			Name = upgrade.Name,
			Kind = "Decor",
			Price = info.Price * zone.PriceMultiplier,
			Requires = requires,
			Zone = zone.Id,
			Multiplier = info.Multiplier,
			Level = level,
			Rebirths = info.Rebirths,
		}
		register(item)
		table.insert(decor, item)
		requires = item.Id
	end
end

return TycoonItems
