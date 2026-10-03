--[[
	Every tycoon purchase button, generated from the zones (GDD §6).
	Ids: line "ToyWorkshop_1", its unlock "ToyWorkshop_1_Line", its items
	"ToyWorkshop_1_Head", "ToyWorkshop_1_Speed1", ...; room upgrades (Config/RoomUpgrades)
	"ToyWorkshop_Decor_GiftTower_1", one per level; line upgrade tracks (Config/LineUpgrades)
	"ToyWorkshop_1_UpDroppers_1", one per level, bought from the line's tablet (no button);
	floors "Floor_3", one per storey above the first two (a button out front); rooms
	"PlushieRoom_Room", opening a zone's room for its UnlockPrice (a button at its door).
	Buttons appear one after another: each item requires the previous one.
	Prices are placeholders to tune in playtests.
]]

local LineUpgrades = require(script.Parent.LineUpgrades)
local RoomUpgrades = require(script.Parent.RoomUpgrades)
local Zones = require(script.Parent.Zones)

export type Item = {
	Id: string,
	Key: string, -- "Line", "Head", "Speed1", ... (used for layout)
	Name: string,
	Kind: string, -- "Line" | "Dropper" | "Speed" | "Station" | "Decor" (a room upgrade's level) | "Track" (a line upgrade's level) | "Floor" (a storey) | "Room" (opens a zone)
	Price: number,
	Requires: string?, -- item that must be bought first
	Zone: string,
	LineId: string?, -- every kind but Decor
	PartType: string?, -- Dropper only
	Multiplier: number?, -- Speed: cycle speed ×, Station: ship value ×, Decor: the room's ship value ×
	Level: number?, -- Decor and Track; a Floor's storey
	Rebirths: number?, -- Decor and Floor: rebirths needed to buy it
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
	{ Key = "Body", Name = "Body Dropper", Kind = "Dropper", PartType = "Body", Price = 80 },
	{ Key = "Arms", Name = "Arms Dropper", Kind = "Dropper", PartType = "Arms", Price = 240 },
	{ Key = "Legs", Name = "Legs Dropper", Kind = "Dropper", PartType = "Legs", Price = 600 },
	{ Key = "Speed1", Name = "Turbo Belt", Kind = "Speed", Multiplier = 1.5, Price = 1400 },
	{ Key = "Station1", Name = "Paint Booth", Kind = "Station", Multiplier = 1.5, Price = 3000 },
	{ Key = "Speed2", Name = "Mega Turbo", Kind = "Speed", Multiplier = 1.5, Price = 8000 },
	{ Key = "Station2", Name = "Glitter Blaster", Kind = "Station", Multiplier = 2, Price = 18000 },
	-- the zone's own special upgrade, named by the zone (Zones.SpecialStation)
	{ Key = "Station3", Name = "", Kind = "Station", Multiplier = 2, Price = 50000 },
}

-- Per line index within a zone: price to unlock the line, and multiplier on its items.
-- Both are also multiplied by the zone's PriceMultiplier. A zone's first line is free
-- once the zone unlocks.
-- (the economy pass, 2026-10-02: the 2nd and 3rd lines cost 3x and 9x for the same
-- output, so they pay back slower, and the next room stays worth opening)
local LINE_UNLOCK_PRICES = { 0, 5000, 60000 }
local LINE_PRICE_SCALES = { 1, 3, 9 }

local TycoonItems = {}

TycoonItems.List = {} :: { Item }
TycoonItems.ById = {} :: { [string]: Item }
TycoonItems.Lines = {} :: { Line }
TycoonItems.LinesById = {} :: { [string]: Line }
TycoonItems.DecorByZone = {} :: { [string]: { Item } } -- every room upgrade level, per zone
TycoonItems.TracksByLine = {} :: { [string]: { [string]: { Item } } } -- [lineId][track] = its levels, in order
TycoonItems.Floors = {} :: { Item } -- the storeys to buy, in order

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

	-- its room's door, when it opens for Coins (a button at the door: TycoonManager)
	if zone.UnlockPrice then
		register({
			Id = `{zone.Id}_Room`,
			Key = "Room",
			Name = `Open the {zone.Name}`,
			Kind = "Room",
			Price = zone.UnlockPrice,
			Zone = zone.Id,
		})
	end

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

		-- its upgrade tracks, a level at a time (not in line.Items: they have no buttons)
		local tracks = {}
		for _, track in LineUpgrades.Tracks do
			local levels = {}
			local previous = `{lineId}_{track.Gate}`
			for level = 1, track.Levels do
				local item: Item = {
					Id = `{lineId}_Up{track.Key}_{level}`,
					Key = track.Key,
					Name = track.Name,
					Kind = "Track",
					Price = LineUpgrades.BasePrice(track, level) * LINE_PRICE_SCALES[index] * zone.PriceMultiplier,
					Requires = previous,
					Zone = zone.Id,
					LineId = lineId,
					Level = level,
				}
				register(item)
				table.insert(levels, item)
				previous = item.Id
			end
			tracks[track.Key] = levels
		end
		TycoonItems.TracksByLine[lineId] = tracks

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

-- Floors (GDD §10): the factory starts with 2 storeys; each one above is bought from a
-- button out front, in order, and drops in (TycoonManager). Its rooms' zones unlock as
-- usual. Placeholder prices.
local FLOORS = {
	{ Storey = 3, Name = "3rd Floor: Candy Factory", Price = 1000000000, Rebirths = 1 },
}
do
	local previous: string? = nil
	for _, floor in FLOORS do
		local item: Item = {
			Id = `Floor_{floor.Storey}`,
			Key = `Floor{floor.Storey}`,
			Name = floor.Name,
			Kind = "Floor",
			Price = floor.Price,
			Requires = previous,
			Zone = Zones.List[1].Id, -- open from the start: only its rebirths lock it
			Level = floor.Storey,
			Rebirths = floor.Rebirths,
		}
		register(item)
		table.insert(TycoonItems.Floors, item)
		previous = item.Id
	end
end

-- How many storeys a factory has with `purchased`'s floors, starting from `base`.
function TycoonItems.StoreysOf(purchased: { [string]: boolean }, base: number): number
	local storeys = base
	for _, floor in TycoonItems.Floors do
		if not purchased[floor.Id] then
			break
		end
		storeys = floor.Level :: number
	end
	return storeys
end

-- How many levels of a line's upgrade `track` are bought (they're bought in order).
function TycoonItems.TrackLevel(purchased: { [string]: boolean }, lineId: string, track: string): number
	local levels = TycoonItems.TracksByLine[lineId]
	local list = levels and levels[track]
	local level = 0
	if list then
		for _, item in list do
			if not purchased[item.Id] then
				break
			end
			level = item.Level :: number
		end
	end
	return level
end

return TycoonItems
