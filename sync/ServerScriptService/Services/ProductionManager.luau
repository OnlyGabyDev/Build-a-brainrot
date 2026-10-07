--[[
	ProductionManager
	Runs the assembly lines (GDD §6, §7). Production is simulated here on timers and
	clients only animate it (ProductionVisuals), so exploiters can't fake shipments.
	Each cycle, a line ships one brainrot built from its purchased droppers' parts.

	Line rules: a part can be equipped on only one line at a time. When every unlocked
	part of a type is already in use, a Common part may be reused, so no line sits idle.

	A full match (all 4 parts from one brainrot) ships for FullMatchMultiplier x the
	Coins (a PERFECT). Brainrots are claimed in the Album, not by shipping (GadgetManager).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Brainrots = require(Shared.Config.Brainrots)
local LineUpgrades = require(Shared.Config.LineUpgrades)
local Production = require(Shared.Config.Production)
local Rarities = require(Shared.Config.Rarities)
local Rebirths = require(Shared.Config.Rebirths)
local TycoonItems = require(Shared.Config.TycoonItems)
local Zones = require(Shared.Config.Zones)
local Format = require(Shared.Format)
local Remotes = require(Shared.Remotes)

local DataManager = require(script.Parent.DataManager)
local MonetizationManager = require(script.Parent.MonetizationManager)
local TycoonManager = require(script.Parent.TycoonManager)

local TICK = 0.1
local REQUEST_COOLDOWN = 0.1 -- per player, for line menu requests
local LINE_REACH = 30 -- studs from a line's Assembler to configure it without the pass
local PART_TYPES = Brainrots.PartTypes

type LineConfig = { [string]: string } -- [partType] = brainrotId
type Usage = { [string]: { [string]: boolean } } -- [partType][brainrotId] = equipped on another line
type LineStats = {
	Droppers: { [string]: boolean },
	CycleTime: number,
	ValueMultiplier: number,
	FlatBonus: number, -- base Coins added to every brainrot (the Upgraders track)
	Special: boolean, -- has its zone's special upgrade (Station3)
}

local productionRemote: RemoteEvent

-- [player][lineId] = seconds into the line's current cycle
local lineTimers: { [Player]: { [string]: number } } = {}
local lastRequest: { [Player]: number } = {}

local ProductionManager = {}

local function rarityOf(brainrotId: string): Rarities.Rarity?
	local brainrot = Brainrots.ById[brainrotId]
	return brainrot and Rarities.ById[brainrot.Rarity]
end

local function partValue(brainrotId: string): number
	local rarity = rarityOf(brainrotId)
	return if rarity then rarity.PartValue else 0
end

-- The brainrot id if all 4 slots hold parts of the same brainrot, else nil.
local function fullMatchId(parts: LineConfig): string?
	local first = parts[PART_TYPES[1]]
	if not first then
		return nil
	end
	for _, partType in PART_TYPES do
		if parts[partType] ~= first then
			return nil
		end
	end
	return first
end

-- A line's droppers, speed and value multiplier, from its upgrades plus the player's
-- rebirths, Rebirth Shop levels and gamepasses. Nil if the line isn't bought.
local function getLineStats(player: Player, data: DataManager.PlayerData, line: TycoonItems.Line): LineStats?
	local purchased = data.Tycoon.Purchased
	if not purchased[line.UnlockItemId] then
		return nil
	end
	local stats: LineStats = {
		Droppers = {},
		CycleTime = Production.BaseCycleTime / Rebirths.SpeedMultiplier(data.Rebirths, data.Upgrades),
		ValueMultiplier = Rebirths.IncomeMultiplier(data.Rebirths, data.Upgrades) * MonetizationManager.IncomeMultiplier(player),
		FlatBonus = 0,
		Special = false,
	}
	for _, item in line.Items do
		if purchased[item.Id] then
			if item.Kind == "Dropper" then
				stats.Droppers[item.PartType :: string] = true
			elseif item.Kind == "Speed" then
				stats.CycleTime /= item.Multiplier :: number
			elseif item.Kind == "Station" then
				stats.ValueMultiplier *= item.Multiplier :: number
				stats.Special = stats.Special or item.Key == "Station3"
			end
		end
	end
	-- the room's upgrades boost every line in it
	for _, item in TycoonItems.DecorByZone[line.Zone] or {} do
		if purchased[item.Id] then
			stats.ValueMultiplier *= item.Multiplier :: number
		end
	end
	-- the line's own upgrade tracks (each level includes the ones before)
	for _, track in LineUpgrades.Tracks do
		local level = TycoonItems.TrackLevel(purchased, line.Id, track.Key)
		if level == 0 then
			continue
		end
		if track.Effect == "Speed" then
			stats.CycleTime /= 1 + track.Step * level
		elseif track.Effect == "Percent" then
			stats.ValueMultiplier *= 1 + track.Step * level
		elseif track.Effect == "Flat" then
			stats.FlatBonus += track.Step * level
		end
	end
	return stats
end

-- Line rules -----------------------------------------------------------------

-- Which parts other lines are using. Only lines the player owns right now count:
-- setups of lines not bought back since a rebirth are remembered but don't hold parts.
local function getUsage(data: DataManager.PlayerData, exceptLineId: string): Usage
	local usage: Usage = {}
	for _, partType in PART_TYPES do
		usage[partType] = {}
	end
	for lineId, config in data.Tycoon.Lines do
		local line = TycoonItems.LinesById[lineId]
		if lineId ~= exceptLineId and line and data.Tycoon.Purchased[line.UnlockItemId] then
			for partType, brainrotId in config do
				if usage[partType] then
					usage[partType][brainrotId] = true
				end
			end
		end
	end
	return usage
end

local function hasFreePart(data: DataManager.PlayerData, usage: Usage, partType: string): boolean
	for brainrotId, owned in data.Inventory.Parts do
		if owned[partType] and Brainrots.ById[brainrotId] and not usage[partType][brainrotId] then
			return true
		end
	end
	return false
end

-- One part, one line. Exception: a Common part may be reused once every part of
-- that type is already in use (GDD §6).
local function canEquip(data: DataManager.PlayerData, usage: Usage, partType: string, brainrotId: string): boolean
	local owned = data.Inventory.Parts[brainrotId]
	local rarity = rarityOf(brainrotId)
	if not (owned and owned[partType] and rarity) then
		return false
	end
	if not usage[partType][brainrotId] then
		return true
	end
	return rarity.Id == "Common" and not hasFreePart(data, usage, partType)
end

-- The most valuable legal setup for a line: the best part per slot, or one full
-- brainrot (×2 and a completion), whichever ships for more.
local function pickBest(data: DataManager.PlayerData, lineId: string): LineConfig
	local usage = getUsage(data, lineId)

	local mixed: LineConfig = {}
	local mixedValue = 0
	for _, partType in PART_TYPES do
		local best: string? = nil
		for brainrotId in data.Inventory.Parts do
			if canEquip(data, usage, partType, brainrotId) and (best == nil or partValue(brainrotId) > partValue(best)) then
				best = brainrotId
			end
		end
		if best then
			mixed[partType] = best
			mixedValue += partValue(best)
		end
	end
	if fullMatchId(mixed) then
		return mixed
	end

	local fullId: string? = nil
	for brainrotId in data.Inventory.Parts do
		local legal = true
		for _, partType in PART_TYPES do
			if not canEquip(data, usage, partType, brainrotId) then
				legal = false
				break
			end
		end
		if legal and (fullId == nil or partValue(brainrotId) > partValue(fullId)) then
			fullId = brainrotId
		end
	end
	if fullId and partValue(fullId) * #PART_TYPES * Production.FullMatchMultiplier >= mixedValue then
		local full: LineConfig = {}
		for _, partType in PART_TYPES do
			full[partType] = fullId
		end
		return full
	end
	return mixed
end

local function equipBest(player: Player, lineId: string): boolean
	local data = DataManager.GetData(player)
	if not data then
		return false
	end
	local config = pickBest(data, lineId)
	for _, partType in PART_TYPES do
		DataManager.SetLinePart(player, lineId, partType, config[partType])
	end
	return true
end

-- Shipping -------------------------------------------------------------------

-- What a line ships right now: the parts its droppers build, the Coins each brainrot
-- is worth, and the brainrot id when all 4 parts match.
local function evaluate(line: TycoonItems.Line, stats: LineStats, config: LineConfig): (LineConfig, number, string?)
	local zone = Zones.ById[line.Zone]
	local parts: LineConfig = {}
	local value = 0
	for _, partType in PART_TYPES do
		local brainrotId = config[partType]
		if stats.Droppers[partType] and brainrotId and rarityOf(brainrotId) then
			parts[partType] = brainrotId
			value += partValue(brainrotId)
		end
	end
	if value > 0 then
		value += stats.FlatBonus
	end
	local matchId = fullMatchId(parts)
	if matchId then
		value *= Production.FullMatchMultiplier
	end
	value = math.floor(value * (if zone then zone.ValueMultiplier else 1) * stats.ValueMultiplier)
	return parts, value, matchId
end

local function ship(player: Player, plot: TycoonManager.Plot, line: TycoonItems.Line, stats: LineStats, data: DataManager.PlayerData)
	local config = data.Tycoon.Lines[line.Id]
	local zone = Zones.ById[line.Zone]
	if not (config and zone) then
		return
	end
	local parts, value, matchId = evaluate(line, stats, config)
	if value == 0 then
		return
	end

	productionRemote:FireAllClients(plot.Model, line.Id, parts, zone.Id, value, matchId ~= nil, stats.CycleTime, stats.Special)

	-- Pay out when the client animation drops the brainrot into the chute.
	local generation = plot.Generation
	task.delay(Production.ShipDelay(parts, stats.CycleTime, stats.Special, zone.Id), function()
		if TycoonManager.GetPlot(player) ~= plot or plot.Generation ~= generation then
			return -- left, or the plot was reset (rebirth, dev Restore) mid-animation
		end
		TycoonManager.AddToCollector(player, value)
		if matchId then
			DataManager.RecordPerfect(player)
		end
	end)
end

local function productionLoop()
	while true do
		local dt = task.wait(TICK)
		for _, player in Players:GetPlayers() do
			local plot = TycoonManager.GetPlot(player)
			local data = DataManager.GetData(player)
			if not (plot and data) then
				continue
			end

			local timers = lineTimers[player]
			if not timers then
				timers = {}
				lineTimers[player] = timers
			end

			for _, line in TycoonItems.Lines do
				local stats = getLineStats(player, data, line)
				if not (stats and next(stats.Droppers)) then
					continue
				end
				if not data.Tycoon.Lines[line.Id] then
					equipBest(player, line.Id) -- a line's first dropper auto-equips the best parts
				end

				local elapsed = (timers[line.Id] or 0) + dt
				if elapsed >= stats.CycleTime then
					-- Ship at most once per tick; don't bank a backlog after a lag spike.
					elapsed = math.min(elapsed - stats.CycleTime, stats.CycleTime)
					ship(player, plot, line, stats, data)
				end
				timers[line.Id] = elapsed
			end
		end
	end
end

-- Line menu requests ---------------------------------------------------------

local function allowRequest(player: Player): boolean
	local now = os.clock()
	if (lastRequest[player] or 0) + REQUEST_COOLDOWN > now then
		return false
	end
	lastRequest[player] = now
	return true
end

local function getOwnedLine(player: Player, lineId: string): (DataManager.PlayerData?, TycoonItems.Line?)
	local data = DataManager.GetData(player)
	local line = TycoonItems.LinesById[lineId]
	if data and line and data.Tycoon.Purchased[line.UnlockItemId] then
		return data, line
	end
	return nil, nil
end

-- Lines are configured by walking up to them, or from anywhere with a pass that has
-- the RemoteLines perk (Auto-Collect, GDD §12).
local function canReach(player: Player, lineId: string): boolean
	if MonetizationManager.HasPerk(player, "RemoteLines") then
		return true
	end
	local plot = TycoonManager.GetPlot(player)
	local line = plot and plot.LinesFolder:FindFirstChild(lineId)
	local assembler = line and line:FindFirstChild("Assembler")
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not (assembler and assembler:IsA("BasePart") and root and root:IsA("BasePart")) then
		return false
	end
	return (root.Position - assembler.Position).Magnitude <= LINE_REACH
end

-- Equips a part in one slot (brainrotId = nil empties it), following the line rules.
-- Returns false and "TooFar" when the player needs to walk to the line.
local function onSetLinePart(player: Player, lineId: unknown, partType: unknown, brainrotId: unknown): (boolean, string?)
	if typeof(lineId) ~= "string" or typeof(partType) ~= "string" or not table.find(PART_TYPES, partType) then
		return false
	end
	if brainrotId ~= nil and typeof(brainrotId) ~= "string" then
		return false
	end
	local equipId = brainrotId :: string?
	if not allowRequest(player) then
		return false
	end
	local data = getOwnedLine(player, lineId)
	if not data then
		return false
	end
	if not canReach(player, lineId) then
		return false, "TooFar"
	end
	if equipId and not canEquip(data, getUsage(data, lineId), partType, equipId) then
		return false
	end
	return DataManager.SetLinePart(player, lineId, partType, equipId)
end

local function onEquipBest(player: Player, lineId: unknown): (boolean, string?)
	if typeof(lineId) ~= "string" or not allowRequest(player) then
		return false
	end
	if not getOwnedLine(player, lineId) then
		return false
	end
	if not canReach(player, lineId) then
		return false, "TooFar"
	end
	return equipBest(player, lineId)
end

-- Puts all 4 parts of one brainrot on a line (the catalog's "put it on a line").
local function onEquipBrainrot(player: Player, lineId: unknown, brainrotId: unknown): (boolean, string?)
	if typeof(lineId) ~= "string" or typeof(brainrotId) ~= "string" or not allowRequest(player) then
		return false
	end
	local data = getOwnedLine(player, lineId)
	if not data then
		return false
	end
	if not canReach(player, lineId) then
		return false, "TooFar"
	end
	local usage = getUsage(data, lineId)
	for _, partType in PART_TYPES do
		if not canEquip(data, usage, partType, brainrotId) then
			return false, "Busy"
		end
	end
	for _, partType in PART_TYPES do
		DataManager.SetLinePart(player, lineId, partType, brainrotId)
	end
	return true
end

-- The Line menu's view of a player's owned lines. Built here so the client never has
-- to know the line rules: every slot lists the unlocked parts of its type, whether
-- this line may use each one, and which other line holds it.
local function onGetLines(player: Player): { any }
	local data = DataManager.GetData(player)
	if not data then
		return {}
	end

	local view = {}
	for _, line in TycoonItems.Lines do
		local stats = getLineStats(player, data, line)
		if not stats then
			continue
		end
		local config = data.Tycoon.Lines[line.Id] or {}
		local usage = getUsage(data, line.Id)

		local options = {}
		for _, partType in PART_TYPES do
			local list = {}
			for brainrotId, owned in data.Inventory.Parts do
				if not (owned[partType] and Brainrots.ById[brainrotId]) then
					continue
				end
				local usedOn: string? = nil
				for otherId, otherConfig in data.Tycoon.Lines do
					local other = TycoonItems.LinesById[otherId]
					local otherOwned = other ~= nil and data.Tycoon.Purchased[other.UnlockItemId] == true
					if otherId ~= line.Id and otherOwned and otherConfig[partType] == brainrotId then
						usedOn = otherId
						break
					end
				end
				table.insert(list, {
					Id = brainrotId,
					Usable = config[partType] == brainrotId or canEquip(data, usage, partType, brainrotId),
					UsedOn = usedOn,
				})
			end
			-- Rarest first, then by name.
			table.sort(list, function(a, b)
				local rankA, rankB = (rarityOf(a.Id) :: Rarities.Rarity).Rank, (rarityOf(b.Id) :: Rarities.Rarity).Rank
				if rankA ~= rankB then
					return rankA > rankB
				end
				return a.Id < b.Id
			end)
			options[partType] = list
		end

		-- its upgrade tracks: the level reached, the price of each level left (for buying
		-- x5 or MAX at once) or what to buy first
		local upgrades = {}
		for _, track in LineUpgrades.Tracks do
			local level = TycoonItems.TrackLevel(data.Tycoon.Purchased, line.Id, track.Key)
			local levels = (TycoonItems.TracksByLine[line.Id] or {})[track.Key]
			local prices = {}
			for index = level + 1, #levels do
				table.insert(prices, levels[index].Price)
			end
			local gate = TycoonItems.ById[`{line.Id}_{track.Gate}`]
			table.insert(upgrades, {
				Key = track.Key,
				Level = level,
				Max = track.Levels,
				Price = prices[1],
				Prices = prices,
				Needs = if gate and not data.Tycoon.Purchased[gate.Id] then gate.Name else nil,
			})
		end

		local _, value, matchId = evaluate(line, stats, config)
		table.insert(view, {
			Id = line.Id,
			Zone = line.Zone,
			Index = line.Index,
			Droppers = stats.Droppers,
			Parts = config,
			Options = options,
			Value = value,
			CycleTime = stats.CycleTime,
			FullMatch = matchId ~= nil,
			Upgrades = upgrades,
		})
	end
	return view
end

-- Public API -----------------------------------------------------------------

-- Coins per second across all of a player's lines (before the Cash Pad).
function ProductionManager.GetIncome(player: Player): number
	local data = DataManager.GetData(player)
	if not data then
		return 0
	end
	local income = 0
	for _, line in TycoonItems.Lines do
		local stats = getLineStats(player, data, line)
		local config = data.Tycoon.Lines[line.Id]
		if stats and config then
			local _, value = evaluate(line, stats, config)
			income += value / stats.CycleTime
		end
	end
	return income
end

-- Tralalero's guide: makes sure a line builds a full brainrot (its PERFECT step): if
-- its 4 slots don't match, it gets all 4 parts of `brainrotId` (the starter), when the
-- line rules allow it. Returns whether the line builds a full one now.
function ProductionManager.EnsureFullMatch(player: Player, lineId: string, brainrotId: string): boolean
	local data = DataManager.GetData(player)
	if not data then
		return false
	end
	local config = data.Tycoon.Lines[lineId]
	if config and fullMatchId(config) then
		return true
	end
	local usage = getUsage(data, lineId)
	for _, partType in PART_TYPES do
		if not canEquip(data, usage, partType, brainrotId) then
			return false
		end
	end
	for _, partType in PART_TYPES do
		DataManager.SetLinePart(player, lineId, partType, brainrotId)
	end
	return true
end

function ProductionManager.Init()
	productionRemote = Remotes.Event("Production")
	Remotes.Function("SetLinePart").OnServerInvoke = onSetLinePart
	Remotes.Function("EquipBestLine").OnServerInvoke = onEquipBest
	Remotes.Function("GetLines").OnServerInvoke = onGetLines
	Remotes.Function("EquipBrainrot").OnServerInvoke = onEquipBrainrot

	-- Coin packs (Config/Products): minutes of the buyer's own income, so they stay
	-- worth buying as the factory grows
	MonetizationManager.HandleProduct("Coins", function(player, product)
		local amount = math.floor(math.max(ProductionManager.GetIncome(player) * product.Amount, product.MinCoins or 0))
		DataManager.AddCurrency(player, "Coins", amount)
		return `+{Format.Number(amount)} COINS!`
	end)

	Players.PlayerRemoving:Connect(function(player)
		lineTimers[player] = nil
		lastRequest[player] = nil
	end)
	task.spawn(productionLoop)
end

return ProductionManager
