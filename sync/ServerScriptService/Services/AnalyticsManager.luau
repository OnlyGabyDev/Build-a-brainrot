--[[
	AnalyticsManager
	Roblox Analytics events (Creator Hub → Analytics): where new players drop off, and
	where Coins and Gems come from and go. Events only leave live servers (Roblox drops
	them in Studio); the last ones sent are kept for `/dev Analytics`.

	* The onboarding funnel: each step once per player, in order (STEPS): joined, each of
	  Tralalero's guide steps, the guide done, each later room opened, rebirths 1-10. The
	  last step sent is saved (Funnel); players from before the funnel aren't counted. A
	  step reached before an earlier one (a rebirth before the Vinyl room) is sent and the
	  earlier one never is (Roblox counts it done).
	* Economy events: every change of Coins and Gems (DataManager.OnCurrencyChanged),
	  summed per kind and sent once a minute (and as the player leaves), since a line
	  ships Coins every few seconds. Two custom fields compare stages: the rebirths and
	  the top room open.

	API limits (2026-10): 120 + 20 × players requests a minute per server (past them
	events are dropped for the day), 10 funnels of 100 steps, 10 currencies, 20
	transaction types and 100 item SKUs (more are grouped as "Other"), 3 custom fields.
	This uses half the request budget, 19 transaction types and ~50 SKUs.
]]

local AnalyticsService = game:GetService("AnalyticsService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Guide = require(Shared.Config.Guide)
local TycoonItems = require(Shared.Config.TycoonItems)
local Zones = require(Shared.Config.Zones)

local DataManager = require(script.Parent.DataManager)

local FLUSH_INTERVAL = 60 -- seconds between economy sends
local FUNNEL_INTERVAL = 2 -- seconds between funnel checks
local BUDGET_BASE, BUDGET_PER_PLAYER = 60, 10 -- requests a minute: half the API's limit
local CURRENCIES = { Coins = true, Gems = true }
local IGNORED_SOURCES = { Dev = true }
local REBIRTH_STEPS = { 1, 2, 3, 5, 10 }
local RECENT_COUNT = 40

local FIELD_REBIRTHS = Enum.AnalyticsCustomFieldKeys.CustomField01.Name
local FIELD_ROOM = Enum.AnalyticsCustomFieldKeys.CustomField02.Name

type Step = { Name: string, Reached: (data: DataManager.PlayerData) -> boolean }

-- Changes to the order shift the saved step numbers: add new steps at the end.
local STEPS: { Step } = {
	{
		Name = "Joined",
		Reached = function()
			return true
		end,
	},
}
local function guideIndex(data: DataManager.PlayerData): number
	return if data.Guide == Guide.Done then #Guide.Steps + 1 else Guide.IndexOf[data.Guide] or 0
end
for index, step in Guide.Steps do
	table.insert(STEPS, {
		Name = `Guide: {step.Id}`,
		Reached = function(data)
			return guideIndex(data) >= index
		end,
	})
end
table.insert(STEPS, {
	Name = "Guide done",
	Reached = function(data)
		return data.Guide == Guide.Done
	end,
})
local guideRooms = {}
for _, step in Guide.Steps do
	if step.Item then
		guideRooms[step.Item] = true
	end
end
for _, zone in Zones.List do
	local room = `{zone.Id}_Room`
	if zone.Available and TycoonItems.ById[room] and not guideRooms[room] then
		table.insert(STEPS, {
			Name = `Room: {zone.Name}`,
			Reached = function(data)
				return data.Tycoon.Purchased[room] == true or (data.Counters[`Room_{zone.Id}`] or 0) > 0
			end,
		})
	end
end
for _, rebirths in REBIRTH_STEPS do
	table.insert(STEPS, {
		Name = `Rebirth {rebirths}`,
		Reached = function(data)
			return data.Rebirths >= rebirths
		end,
	})
end

type Pending = {
	Flow: Enum.AnalyticsEconomyFlowType,
	Currency: string,
	Kind: string,
	Sku: string?,
	Fields: { [string]: string },
	Amount: number,
	Balance: number,
}

local pending: { [Player]: { [string]: Pending } } = {}
local recent: { string } = {}
local minuteStart, sentThisMinute = os.clock(), 0

local AnalyticsManager = {}

local function remember(line: string)
	table.insert(recent, line)
	if #recent > RECENT_COUNT then
		table.remove(recent, 1)
	end
end

-- Takes one request from this minute's budget; false when it's spent.
local function takeBudget(force: boolean?): boolean
	local now = os.clock()
	if now - minuteStart >= 60 then
		minuteStart, sentThisMinute = now, 0
	end
	if not force and sentThisMinute >= BUDGET_BASE + BUDGET_PER_PLAYER * #Players:GetPlayers() then
		return false
	end
	sentThisMinute += 1
	return true
end

-- Funnel -------------------------------------------------------------------------

-- Sends the funnel steps the player has reached since the last one sent.
local function advance(player: Player)
	local data = DataManager.GetData(player)
	if not data or data.Funnel < 0 then
		return
	end
	for index = data.Funnel + 1, #STEPS do
		local step = STEPS[index]
		if step.Reached(data) then
			if not takeBudget() then
				return -- next check
			end
			local ok, problem = pcall(AnalyticsService.LogOnboardingFunnelStepEvent, AnalyticsService, player, index, step.Name)
			remember(`{player.Name} funnel {index} {step.Name}{if ok then "" else ` FAILED {problem}`}`)
			DataManager.SetFunnelStep(player, index)
		end
	end
end

-- Economy ------------------------------------------------------------------------

-- The transaction type and SKU a change counts under: a tycoon item by its kind (a line
-- upgrade by its track, a room upgrade by its room: "LineUpgrades", "Droppers"), the
-- rest as their source says. Few SKUs: the custom fields say the stage.
local function classify(source: string?, sku: string?): (string, string?)
	if source == "Item" then
		local item = if sku then TycoonItems.ById[sku] else nil
		if not item then
			return "Factory", nil
		elseif item.Kind == "Track" then
			return "LineUpgrades", item.Key
		elseif item.Kind == "Decor" then
			return "RoomUpgrades", item.Zone
		end
		return "Factory", item.Kind
	end
	return source or "Other", sku
end

-- The custom fields: the player's stage when it happened.
local function stageFields(data: DataManager.PlayerData): { [string]: string }
	local rebirths = data.Rebirths
	local band = if rebirths >= 10 then "10+" elseif rebirths >= 5 then "5-9" elseif rebirths >= 2 then "2-4" else tostring(rebirths)
	local top = Zones.List[1].Name
	for _, zone in Zones.List do
		if zone.Available and data.Tycoon.Purchased[`{zone.Id}_Room`] then
			top = zone.Name
		end
	end
	return { [FIELD_REBIRTHS] = `Rebirth {band}`, [FIELD_ROOM] = top }
end

local function onCurrencyChanged(player: Player, currency: string, amount: number, balance: number, source: string?, sku: string?)
	if amount == 0 or not CURRENCIES[currency] or (source and IGNORED_SOURCES[source]) then
		return
	end
	local data = DataManager.GetData(player)
	if not data then
		return
	end
	local kind, detail = classify(source, sku)
	local flow = if amount > 0 then Enum.AnalyticsEconomyFlowType.Source else Enum.AnalyticsEconomyFlowType.Sink
	local fields = stageFields(data)
	local key = `{currency}|{flow.Name}|{kind}|{detail or ""}|{fields[FIELD_REBIRTHS]}|{fields[FIELD_ROOM]}`
	local entries = pending[player]
	if not entries then
		entries = {}
		pending[player] = entries
	end
	local entry = entries[key]
	if not entry then
		entry = { Flow = flow, Currency = currency, Kind = kind, Sku = detail, Fields = fields, Amount = 0, Balance = 0 }
		entries[key] = entry
	end
	entry.Amount += math.abs(amount)
	entry.Balance = balance
end

-- Sends the player's summed changes (as many as the budget allows, or all of them as
-- they leave).
local function flush(player: Player, leaving: boolean)
	local entries = pending[player]
	if not entries then
		return
	end
	for key, entry in entries do
		if not takeBudget(leaving) then
			return
		end
		entries[key] = nil
		local ok, problem = pcall(
			AnalyticsService.LogEconomyEvent,
			AnalyticsService,
			player,
			entry.Flow,
			entry.Currency,
			entry.Amount,
			entry.Balance,
			entry.Kind,
			entry.Sku,
			entry.Fields
		)
		remember(
			`{player.Name} {entry.Flow.Name} {entry.Amount} {entry.Currency} {entry.Kind}`
				.. `{if entry.Sku then ` ({entry.Sku})` else ""} = {entry.Balance} [{entry.Fields[FIELD_REBIRTHS]}, {entry.Fields[FIELD_ROOM]}]`
				.. `{if ok then "" else ` FAILED {problem}`}`
		)
	end
	if next(entries) == nil then
		pending[player] = nil
	end
end

-- Studio testing (DevTools) -----------------------------------------------------

-- The last events sent, oldest first; with `now`, the player's waiting ones go first.
function AnalyticsManager.DevRecent(player: Player, now: boolean?): { string }
	if now then
		flush(player, true)
	end
	return table.clone(recent)
end

function AnalyticsManager.Init()
	DataManager.OnCurrencyChanged(onCurrencyChanged)
	DataManager.OnPlayerLoaded(advance)
	-- (registered last, after the services that bank Coins as a player leaves)
	DataManager.OnBeforeSave(function(player, leaving)
		if leaving then
			flush(player, true)
			pending[player] = nil
		end
	end)
	task.spawn(function()
		while true do
			task.wait(FUNNEL_INTERVAL)
			for _, player in Players:GetPlayers() do
				advance(player)
			end
		end
	end)
	task.spawn(function()
		while true do
			task.wait(FLUSH_INTERVAL)
			for player in pending do
				if player.Parent then
					flush(player, false)
				else
					pending[player] = nil
				end
			end
		end
	end)
end

return AnalyticsManager
