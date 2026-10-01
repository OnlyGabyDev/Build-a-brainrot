--[[
	Every tycoon purchase button, generated from the zones (GDD §6).
	Ids: line "ToyWorkshop_1", its unlock "ToyWorkshop_1_Line", its items
	"ToyWorkshop_1_Head", "ToyWorkshop_1_Speed1", ...
	Buttons appear one after another: each item requires the previous one.
	Prices are placeholders to tune in playtests.
]]

local Zones = require(script.Parent.Zones)

export type Item = {
	Id: string,
	Key: string, -- "Line", "Head", "Speed1", ... (used for layout)
	Name: string,
	Kind: string, -- "Line" | "Dropper" | "Speed" | "Station"
	Price: number,
	Requires: string?, -- item that must be bought first
	Zone: string,
	LineId: string,
	PartType: string?, -- Dropper only
	Multiplier: number?, -- Speed: cycle speed ×, Station: ship value ×
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

local function add(line: Line, item: Item)
	assert(not TycoonItems.ById[item.Id], `Duplicate tycoon item {item.Id}`)
	table.insert(TycoonItems.List, item)
	table.insert(line.Items, item)
	TycoonItems.ById[item.Id] = item
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
			local name = template.Name
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

return TycoonItems
