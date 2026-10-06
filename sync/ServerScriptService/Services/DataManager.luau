--[[
	DataManager
	Owns all persistent player data: the 3 currencies (Coins, Gems, RebirthPoints),
	the rebirth count, Rolls, the brainrot parts inventory, completions and the tycoon.

	Saving model:
	  * UpdateAsync only, with a session lock stored next to the data. Two servers can
	    never hold the same profile at once, which prevents item dupes and rollbacks.
	  * Data is never written unless it loaded successfully, so a DataStore outage
	    can't overwrite real progress with a blank profile.
	  * Autosave, save-on-leave and BindToClose, all with retries + exponential backoff.

	Only this module mutates player data. Other services go through the API below.
	Clients see currencies via Player attributes + leaderstats, and their inventory
	via the InventoryUpdated remote.
]]

local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage.Shared
local Brainrots = require(Shared.Config.Brainrots)
local Guide = require(Shared.Config.Guide)
local Remotes = require(Shared.Remotes)

local IS_STUDIO = RunService:IsStudio()

-- Config ---------------------------------------------------------------------

-- Studio uses its own store so play-testing never touches live player data.
local STORE_NAME = if IS_STUDIO then "PlayerData_Studio" else "PlayerData"
local KEY_PREFIX = "Player_"
local DATA_VERSION = 1

local AUTOSAVE_INTERVAL = 60 -- seconds between saves for each player
local LOCK_EXPIRE_SECONDS = 300 -- a lock not refreshed for this long belongs to a dead server
local LOCK_RETRY_ATTEMPTS = 6 -- times to wait on another server's lock before taking it
local LOCK_RETRY_DELAY = 5
local REQUEST_RETRY_ATTEMPTS = 4 -- retries per DataStore request (backoff 1s, 2s, 4s)
local REQUEST_RETRY_BASE_DELAY = 1
local SHUTDOWN_TIMEOUT = 25 -- BindToClose gets 30s max

local STARTER_ROLLS = 3 -- free Rolls for new players (GDD §2)
local MAX_RECEIPTS = 100 -- recent Robux purchase ids kept per player

local LOAD_FAILED_MESSAGE =
	"We couldn't load your data (Roblox DataStores may be down). Please rejoin in a minute. Your progress is safe!"
local SESSION_TAKEN_MESSAGE = "Your data was loaded in another server. Please rejoin."

local CURRENCIES = { "Coins", "Gems", "RebirthPoints" }
local PART_TYPES = Brainrots.PartTypes

-- Mirrored to the client as Player attributes (read by the HUD).
local REPLICATED_STATS = { "Coins", "Gems", "RebirthPoints", "Rebirths", "Rolls" }
-- Shown on the Roblox player list, in this order.
local LEADERSTATS = {
	{ Name = "Coins", ClassName = "NumberValue" },
	{ Name = "Rebirths", ClassName = "IntValue" },
}

export type Inventory = {
	Parts: { [string]: { [string]: boolean } }, -- [brainrotId] = { Head = true, ... } (unlocked parts)
	Completed: { [string]: { [string]: number } }, -- [brainrotId] = { [zoneId] = os.time() of first full ship }
}

export type PlayerData = {
	Coins: number,
	Gems: number,
	RebirthPoints: number,
	Rebirths: number,
	Rolls: number,
	Inventory: Inventory,
	Tycoon: {
		Purchased: { [string]: boolean },
		Lines: { [string]: { [string]: string } },
	},
	Upgrades: { [string]: number }, -- Rebirth Shop levels (Config/Rebirths), kept on rebirth
	Boosts: { [string]: number }, -- [boostId] = os.time() it expires
	DailyWheel: { FreeSpins: { number }, Spins: number }, -- free spins used (times), bought spins
	Receipts: { string }, -- recent Robux purchase ids, so none is granted twice
	Claims: { [string]: number }, -- [claim] = os.time() it was last claimed (one-off and daily rewards)
	Stats: { TotalCoinsEarned: number, FirstJoin: number, LastJoin: number, RobuxSpent: number, Playtime: number },
	Settings: { LowGraphics: boolean }, -- the player's own (Client/Performance)
	Guide: string, -- the step of Tralalero's guide they're on (Config/Guide), "Done" when finished
}

export type AddPartResult = "New" | "Duplicate" | "NotLoaded"

local function allParts(): { [string]: boolean }
	local parts = {}
	for _, partType in PART_TYPES do
		parts[partType] = true
	end
	return parts
end

local TEMPLATE: PlayerData = {
	Coins = 0,
	Gems = 0,
	RebirthPoints = 0,
	Rebirths = 0,
	Rolls = STARTER_ROLLS,
	Inventory = {
		Parts = {
			[Brainrots.StarterId] = allParts(),
		},
		Completed = {},
	},
	Tycoon = {
		Purchased = {}, -- [itemId] = true (reset on rebirth)
		Lines = {}, -- [lineId] = { Head = brainrotId, ... } (kept on rebirth)
	},
	Upgrades = {}, -- [upgradeId] = level
	Boosts = {},
	DailyWheel = { FreeSpins = {}, Spins = 0 },
	Receipts = {},
	Claims = {},
	Stats = {
		TotalCoinsEarned = 0,
		FirstJoin = 0,
		LastJoin = 0,
		RobuxSpent = 0, -- every Robux purchase, for the leaderboards
		Playtime = 0, -- seconds in game
	},
	Settings = {
		LowGraphics = false,
	},
	Guide = Guide.Steps[1].Id,
}

-- What a client may set in its Settings, and the type each takes.
local SETTING_TYPES: { [string]: string } = { LowGraphics = "boolean" }

-- MIGRATIONS[n] upgrades saved data from version n to n + 1.
-- Adding a new field doesn't need one (reconcile fills it in). Renaming or
-- restructuring does: bump DATA_VERSION and add a step here.
local MIGRATIONS: { [number]: (data: any) -> () } = {}

-- State ----------------------------------------------------------------------

type Profile = {
	Player: Player,
	UserId: number,
	Key: string,
	Data: PlayerData,
	Version: number,
	Offline: boolean, -- Studio without API access: nothing is saved
	Saving: boolean,
	LockLost: boolean,
	LastSave: number,
	StatValues: { [string]: any },
	UnsavedReceipts: { [string]: boolean }, -- granted, but no save has gone through since
}

type LoadResult = "Loaded" | "Offline" | "Failed" | "Cancelled"

local JOB_ID = if game.JobId ~= "" then game.JobId else "Studio-" .. HttpService:GenerateGUID(false)

local IS_CURRENCY = {}
for _, name in CURRENCIES do
	IS_CURRENCY[name] = true
end

local IS_PART_TYPE = {}
for _, name in PART_TYPES do
	IS_PART_TYPE[name] = true
end

local profiles: { [Player]: Profile } = {}
-- UserIds with a session in this server (loading, active or releasing).
local activeSessions: { [number]: boolean } = {}
local loadedCallbacks: { (Player) -> () } = {}

local dataStore: DataStore? = nil
local inventoryRemote: RemoteEvent
local initialized = false
local offlineWarned = false

local DataManager = {}

DataManager.Currencies = table.freeze(table.clone(CURRENCIES))

-- Studio: play as a brand-new player. Set workspace's DevFreshStart attribute in Edit
-- (and clear it after, or every playtest starts fresh): everyone gets a newcomer's data,
-- nothing is loaded or saved, no gamepasses are granted (MonetizationManager) and the
-- leaderboards aren't written (IsSaved). Ignored on live servers.
DataManager.FreshStart = IS_STUDIO and workspace:GetAttribute("DevFreshStart") == true

-- Helpers --------------------------------------------------------------------

local function deepCopy(value: any): any
	if type(value) ~= "table" then
		return value
	end
	local copy = {}
	for key, child in value do
		copy[key] = deepCopy(child)
	end
	return copy
end

-- Fills in any fields missing from `data` with defaults from `template`.
local function reconcile(data: any, template: any)
	for key, default in template do
		if data[key] == nil then
			data[key] = deepCopy(default)
		elseif type(default) == "table" and type(data[key]) == "table" then
			reconcile(data[key], default)
		end
	end
end

local function withRetries(label: string, request: () -> ()): (boolean, string?)
	local lastError
	for attempt = 1, REQUEST_RETRY_ATTEMPTS do
		local ok, err = pcall(request)
		if ok then
			return true, nil
		end
		lastError = tostring(err)
		warn(`[DataManager] {label} failed (attempt {attempt}/{REQUEST_RETRY_ATTEMPTS}): {lastError}`)
		-- 403 = Studio API access disabled; retrying won't help.
		if string.find(lastError, "403") then
			break
		end
		if attempt < REQUEST_RETRY_ATTEMPTS then
			task.wait(REQUEST_RETRY_BASE_DELAY * 2 ^ (attempt - 1))
		end
	end
	return false, lastError
end

local function checkCurrency(currency: string)
	if not IS_CURRENCY[currency] then
		error(`[DataManager] Unknown currency "{tostring(currency)}"`, 3)
	end
end

-- Returns a whole, finite, non-negative amount, or errors. Catching NaN/inf here
-- matters: a single bad value would be saved and corrupt the profile for good.
local function checkAmount(amount: number): number
	if typeof(amount) ~= "number" or amount ~= amount or amount == math.huge or amount < 0 then
		error(`[DataManager] Invalid amount {tostring(amount)}`, 3)
	end
	return math.floor(amount)
end

-- Ids become DataStore keys, so they must be short non-empty strings.
local function checkId(label: string, id: string)
	if type(id) ~= "string" or #id == 0 or #id > 64 then
		error(`[DataManager] Invalid {label} {tostring(id)}`, 3)
	end
end

local function checkPartType(partType: string)
	if not IS_PART_TYPE[partType] then
		error(`[DataManager] Invalid part type "{tostring(partType)}"`, 3)
	end
end

local function ownsPart(profile: Profile, brainrotId: string, partType: string): boolean
	local owned = profile.Data.Inventory.Parts[brainrotId]
	return owned ~= nil and owned[partType] == true
end

-- Replication ----------------------------------------------------------------

local function replicateStat(profile: Profile, stat: string)
	local value = profile.Data[stat]
	profile.Player:SetAttribute(stat, value)
	local statValue = profile.StatValues[stat]
	if statValue then
		statValue.Value = value
	end
end

local function replicateInventory(profile: Profile)
	inventoryRemote:FireClient(profile.Player, profile.Data.Inventory)
end

-- Rebirth Shop levels, as "Upgrade_<Id>" attributes for the UI.
local function replicateUpgrades(profile: Profile)
	local player = profile.Player
	for name in player:GetAttributes() do
		if string.sub(name, 1, 8) == "Upgrade_" and profile.Data.Upgrades[string.sub(name, 9)] == nil then
			player:SetAttribute(name, nil) -- no longer in the data (e.g. a restored snapshot)
		end
	end
	for id, level in profile.Data.Upgrades do
		player:SetAttribute(`Upgrade_{id}`, level)
	end
end

-- The player's settings, as "Setting_<Name>" attributes for the client.
local function replicateSettings(profile: Profile)
	for name, value in profile.Data.Settings do
		profile.Player:SetAttribute(`Setting_{name}`, value)
	end
end

-- Boost expiry times ("Boost_<Id>", os.time()) and bought wheel spins, for the UI.
local function replicateExtras(profile: Profile)
	for id, expires in profile.Data.Boosts do
		profile.Player:SetAttribute(`Boost_{id}`, expires)
	end
	profile.Player:SetAttribute("WheelSpins", profile.Data.DailyWheel.Spins)
	profile.Player:SetAttribute("Guide", profile.Data.Guide)
end

local function setupReplication(profile: Profile)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	for _, stat in LEADERSTATS do
		local value = Instance.new(stat.ClassName)
		value.Name = stat.Name
		value.Parent = leaderstats
		profile.StatValues[stat.Name] = value
	end

	for _, stat in REPLICATED_STATS do
		replicateStat(profile, stat)
	end
	replicateUpgrades(profile)
	replicateExtras(profile)
	replicateSettings(profile)
	leaderstats.Parent = profile.Player
	profile.Player:SetAttribute("DataLoaded", true)
	replicateInventory(profile)
end

-- Loading & saving -----------------------------------------------------------

-- Acquires the session lock and returns the stored record (nil for new players).
local function loadRecord(player: Player): (LoadResult, any)
	if not dataStore then
		return if IS_STUDIO then "Offline" else "Failed", nil
	end

	local store: DataStore = dataStore
	local userId = player.UserId
	local key = KEY_PREFIX .. userId

	for attempt = 1, LOCK_RETRY_ATTEMPTS do
		-- On the last attempt, take the lock anyway: the other server has had plenty
		-- of time to release it. If it's still alive, its next save sees the lock is
		-- gone and stops writing, so nothing is duplicated.
		local forceSteal = attempt == LOCK_RETRY_ATTEMPTS
		local record, lockedBy

		local ok = withRetries(`Load {key}`, function()
			store:UpdateAsync(key, function(current)
				record, lockedBy = current, nil -- the transform can run more than once
				local now = os.time()
				local session = current and current.Session
				if
					session
					and session.JobId ~= JOB_ID
					and now - (session.Time or 0) < LOCK_EXPIRE_SECONDS
					and not forceSteal
				then
					lockedBy = session.JobId
					return nil -- cancel the write and leave the other server's lock alone
				end
				local new = current or {}
				new.Session = { JobId = JOB_ID, Time = now }
				return new, { userId }
			end)
		end)

		if not ok then
			if IS_STUDIO then
				return "Offline", nil
			end
			return "Failed", nil
		end
		if not lockedBy then
			return "Loaded", record
		end

		warn(`[DataManager] {key} is locked by another server, waiting ({attempt}/{LOCK_RETRY_ATTEMPTS})`)
		task.wait(LOCK_RETRY_DELAY)
		if not player:IsDescendantOf(Players) then
			return "Cancelled", nil
		end
	end

	return "Failed", nil
end

-- Turns a stored record into up-to-date PlayerData (migrated + reconciled).
local function buildData(record: any): (PlayerData, number)
	local saved = record and record.Data
	if type(saved) ~= "table" then
		return deepCopy(TEMPLATE), DATA_VERSION
	end

	local version = record.Version or 1
	for step = version, DATA_VERSION - 1 do
		local migrate = MIGRATIONS[step]
		if migrate then
			migrate(saved)
		end
	end
	-- players from before Tralalero's guide skip it
	if saved.Guide == nil then
		saved.Guide = Guide.Done
	end
	reconcile(saved, TEMPLATE)
	-- Keep a newer version number if this server runs older code than the one that
	-- last saved, so migrations never run twice on the same data.
	return saved, math.max(version, DATA_VERSION)
end

-- Writes the profile to the DataStore. With `release`, also frees the session lock.
local function saveProfile(profile: Profile, release: boolean): boolean
	while profile.Saving do -- one request at a time per profile
		task.wait()
	end
	if profile.LockLost then
		return false
	end
	if not release and profiles[profile.Player] ~= profile then
		return false -- stale autosave for a profile that's already been released
	end
	if profile.Offline then
		return true
	end

	local store: DataStore = dataStore :: DataStore
	profile.Saving = true
	local lostLock = false
	local ok = withRetries(`Save {profile.Key}`, function()
		store:UpdateAsync(profile.Key, function(current)
			lostLock = false
			local session = current and current.Session
			if not session or session.JobId ~= JOB_ID then
				lostLock = true
				return nil -- another server owns this profile now; never overwrite it
			end
			current.Data = profile.Data
			current.Version = profile.Version
			current.Session = if release then nil else { JobId = JOB_ID, Time = os.time() }
			return current, { profile.UserId }
		end)
	end)
	profile.Saving = false
	profile.LastSave = os.clock()

	if lostLock then
		profile.LockLost = true
		warn(`[DataManager] {profile.Key} lost its session lock; this server will no longer save it`)
		if not release and profile.Player:IsDescendantOf(Players) then
			profile.Player:Kick(SESSION_TAKEN_MESSAGE)
		end
	end
	return ok and not lostLock
end

local function releaseProfile(profile: Profile)
	if profiles[profile.Player] ~= profile then
		return -- already released
	end
	profiles[profile.Player] = nil
	saveProfile(profile, true)
	activeSessions[profile.UserId] = nil
end

local function onPlayerAdded(player: Player)
	local userId = player.UserId
	-- If this user just left this same server, let that final save finish first.
	while activeSessions[userId] do
		task.wait(0.1)
	end
	if not player:IsDescendantOf(Players) then
		return
	end
	activeSessions[userId] = true

	local result, record
	if DataManager.FreshStart then
		result, record = "Offline", nil -- a newcomer's data; the real save isn't touched
	else
		result, record = loadRecord(player)
	end
	if result == "Failed" or result == "Cancelled" then
		activeSessions[userId] = nil
		if result == "Failed" and player:IsDescendantOf(Players) then
			player:Kick(LOAD_FAILED_MESSAGE)
		end
		return
	end

	local data, version = buildData(record)
	local profile: Profile = {
		Player = player,
		UserId = userId,
		Key = KEY_PREFIX .. userId,
		Data = data,
		Version = version,
		Offline = result == "Offline",
		Saving = false,
		LockLost = false,
		LastSave = os.clock(),
		StatValues = {},
		UnsavedReceipts = {},
	}

	if not player:IsDescendantOf(Players) then
		-- They left while we were loading. We hold the lock, so hand it back.
		saveProfile(profile, true)
		activeSessions[userId] = nil
		return
	end

	if profile.Offline and not offlineWarned and DataManager.FreshStart then
		offlineWarned = true
		warn("[DataManager] DevFreshStart is on: playing as a new player, nothing is loaded or saved.")
	elseif profile.Offline and not offlineWarned then
		offlineWarned = true
		warn(
			"[DataManager] Data will NOT be saved in this session. To test saving in Studio, publish the place and enable "
				.. "Game Settings > Security > 'Enable Studio Access to API Services'."
		)
	end

	local now = os.time()
	if data.Stats.FirstJoin == 0 then
		data.Stats.FirstJoin = now
	end
	data.Stats.LastJoin = now

	profiles[player] = profile
	setupReplication(profile)
	for _, callback in loadedCallbacks do
		task.spawn(callback, player)
	end
end

local function onPlayerRemoving(player: Player)
	local profile = profiles[player]
	if profile then
		releaseProfile(profile)
	end
	-- Still loading? onPlayerAdded notices they left and releases the lock itself.
end

local function onShutdown()
	for _, profile in table.clone(profiles) do
		task.spawn(releaseProfile, profile)
	end
	local deadline = os.clock() + SHUTDOWN_TIMEOUT
	while next(activeSessions) and os.clock() < deadline do
		task.wait(0.1)
	end
end

local function autosaveLoop()
	while true do
		task.wait(5)
		local now = os.clock()
		for _, profile in profiles do
			if not profile.Saving and now - profile.LastSave >= AUTOSAVE_INTERVAL then
				task.spawn(saveProfile, profile, false)
			end
		end
	end
end

-- Lifecycle ------------------------------------------------------------------

function DataManager.Init()
	assert(not initialized, "DataManager.Init called twice")
	initialized = true

	local ok, result = pcall(DataStoreService.GetDataStore, DataStoreService, STORE_NAME)
	if ok then
		dataStore = result
	else
		warn(`[DataManager] DataStore unavailable: {result}`)
	end

	inventoryRemote = Remotes.Event("InventoryUpdated")
	-- A client changing one of its own settings (only known ones, of the right type).
	Remotes.Event("SetSetting").OnServerEvent:Connect(function(player: Player, name: unknown, value: unknown)
		if typeof(name) == "string" and SETTING_TYPES[name] ~= nil and typeof(value) == SETTING_TYPES[name] then
			DataManager.SetSetting(player, name, value)
		end
	end)
	-- The catalog fetches the inventory when it opens (it may miss the initial push).
	Remotes.Function("GetInventory").OnServerInvoke = function(player: Player)
		local profile = profiles[player]
		return profile and profile.Data.Inventory
	end

	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end

	game:BindToClose(onShutdown)
	task.spawn(autosaveLoop)
end

-- Runs `callback(player)` for every player whose data is loaded, now or later.
function DataManager.OnPlayerLoaded(callback: (Player) -> ())
	table.insert(loadedCallbacks, callback)
	for player in profiles do
		task.spawn(callback, player)
	end
end

-- Sets one of the player's settings (SETTING_TYPES) and mirrors it to their client.
function DataManager.SetSetting(player: Player, name: string, value: any): boolean
	local profile = profiles[player]
	if not (profile and SETTING_TYPES[name] and typeof(value) == SETTING_TYPES[name]) then
		return false
	end
	;(profile.Data.Settings :: any)[name] = value
	player:SetAttribute(`Setting_{name}`, value)
	return true
end

-- Whether this session's data goes to the DataStore (not offline, nor a FreshStart, nor
-- a lost lock): other stores (the leaderboards) follow it.
function DataManager.IsSaved(player: Player): boolean
	local profile = profiles[player]
	return profile ~= nil and not profile.Offline and not profile.LockLost
end

function DataManager.IsLoaded(player: Player): boolean
	return profiles[player] ~= nil
end

-- The live data table, or nil if not loaded. Treat it as READ-ONLY: change data
-- through the functions below so values stay valid and the client stays in sync.
function DataManager.GetData(player: Player): PlayerData?
	local profile = profiles[player]
	return profile and profile.Data
end

-- Currencies -----------------------------------------------------------------

function DataManager.GetCurrency(player: Player, currency: string): number
	checkCurrency(currency)
	local profile = profiles[player]
	return if profile then profile.Data[currency] else 0
end

function DataManager.AddCurrency(player: Player, currency: string, amount: number): boolean
	checkCurrency(currency)
	amount = checkAmount(amount)
	local profile = profiles[player]
	if not profile then
		return false
	end

	profile.Data[currency] += amount
	if currency == "Coins" then
		profile.Data.Stats.TotalCoinsEarned += amount
	end
	replicateStat(profile, currency)
	return true
end

-- Returns false and changes nothing if the player can't afford it.
function DataManager.SpendCurrency(player: Player, currency: string, amount: number): boolean
	checkCurrency(currency)
	amount = checkAmount(amount)
	local profile = profiles[player]
	if not profile or profile.Data[currency] < amount then
		return false
	end

	profile.Data[currency] -= amount
	replicateStat(profile, currency)
	return true
end

-- Studio test helpers (DevTools) ------------------------------------------------

-- A deep copy of the player's data, to restore after a destructive test.
function DataManager.DevSnapshot(player: Player): PlayerData?
	local profile = profiles[player]
	return profile and deepCopy(profile.Data)
end

-- Puts a snapshot back and re-replicates everything. The caller rebuilds the tycoon.
-- Marks a tycoon item bought or not, for free (Studio tests; DevTools SetPurchased).
function DataManager.DevSetPurchased(player: Player, itemId: string, purchased: boolean): boolean
	local profile = profiles[player]
	if not profile then
		return false
	end
	profile.Data.Tycoon.Purchased[itemId] = if purchased then true else nil
	return true
end

function DataManager.DevRestore(player: Player, snapshot: PlayerData): boolean
	local profile = profiles[player]
	if not profile then
		return false
	end
	for key in profile.Data :: any do
		(profile.Data :: any)[key] = nil
	end
	for key, value in deepCopy(snapshot) :: any do
		(profile.Data :: any)[key] = value
	end
	for _, stat in REPLICATED_STATS do
		replicateStat(profile, stat)
	end
	replicateUpgrades(profile)
	replicateExtras(profile)
	replicateInventory(profile)
	return true
end

function DataManager.DevAddRebirths(player: Player, amount: number): boolean
	local profile = profiles[player]
	if not profile then
		return false
	end
	profile.Data.Rebirths += checkAmount(amount)
	replicateStat(profile, "Rebirths")
	return true
end

-- Rebirths -------------------------------------------------------------------

-- Adds to one of the player's lifetime stats (Stats.RobuxSpent, Stats.Playtime), which
-- the leaderboards read. Never reset.
function DataManager.AddStat(player: Player, stat: string, amount: number): boolean
	local profile = profiles[player]
	local stats = profile and (profile.Data.Stats :: any)
	if not (stats and type(stats[stat]) == "number" and type(amount) == "number" and amount > 0) then
		return false
	end
	stats[stat] += amount
	return true
end

-- Spends `cost` Coins to rebirth: Coins and tycoon purchases reset, the rebirth count
-- goes up and `points` Rebirth Points are added. Everything else is kept (GDD §10).
-- Returns false (changing nothing) if the player can't afford it.
function DataManager.Rebirth(player: Player, cost: number, points: number): boolean
	cost = checkAmount(cost)
	points = checkAmount(points)
	local profile = profiles[player]
	if not profile or profile.Data.Coins < cost then
		return false
	end
	local data = profile.Data
	data.Coins = 0
	data.Tycoon.Purchased = {}
	data.Rebirths += 1
	data.RebirthPoints += points
	for _, stat in { "Coins", "Rebirths", "RebirthPoints" } do
		replicateStat(profile, stat)
	end
	return true
end

-- Buys the next level of a Rebirth Shop upgrade for `cost` Rebirth Points. The caller
-- checks the upgrade exists; this checks the level cap and the price.
function DataManager.BuyUpgrade(player: Player, upgradeId: string, cost: number, maxLevel: number): boolean
	checkId("upgradeId", upgradeId)
	cost = checkAmount(cost)
	local profile = profiles[player]
	if not profile then
		return false
	end
	local data = profile.Data
	local level = data.Upgrades[upgradeId] or 0
	if level >= maxLevel or data.RebirthPoints < cost then
		return false
	end
	data.RebirthPoints -= cost
	data.Upgrades[upgradeId] = level + 1
	replicateStat(profile, "RebirthPoints")
	replicateUpgrades(profile)
	return true
end

-- Purchases, boosts and the Daily Wheel ------------------------------------------

-- Grants a Robux purchase exactly once (GDD §12). `grant` runs only for a new
-- receipt, using the other DataManager functions; the receipt is then recorded and
-- the profile saved straight away. Returns true once the purchase is safely granted
-- (now or before), false to have Roblox retry later.
function DataManager.ProcessReceipt(player: Player, receiptId: string, grant: () -> ()): boolean
	checkId("receiptId", receiptId)
	local profile = profiles[player]
	if not profile then
		return false
	end
	local receipts = profile.Data.Receipts
	if table.find(receipts, receiptId) then
		-- granted before: done once a save holding it went through (Roblox only retries
		-- when we said NotProcessedYet, so save again rather than claim it's safe)
		if not profile.UnsavedReceipts[receiptId] then
			return true
		end
	else
		grant()
		table.insert(receipts, receiptId)
		while #receipts > MAX_RECEIPTS do
			table.remove(receipts, 1)
		end
		profile.UnsavedReceipts[receiptId] = true
	end
	if saveProfile(profile, false) then
		profile.UnsavedReceipts[receiptId] = nil
		return true
	end
	return false
end

-- Claims a reward named `claim` (e.g. "StarterPack"): true, and it's stamped with the
-- time, if it was never claimed, or (with `cooldown` seconds) not for that long. The
-- caller grants the reward only on true, so a one-off is never given twice.
function DataManager.Claim(player: Player, claim: string, cooldown: number?): boolean
	checkId("claim", claim)
	local profile = profiles[player]
	if not profile then
		return false
	end
	local now = os.time()
	local last = profile.Data.Claims[claim]
	if last and (cooldown == nil or now - last < cooldown) then
		return false
	end
	profile.Data.Claims[claim] = now
	return true
end

-- Studio testing: forgets a claim, so it can be claimed again.
function DataManager.DevUnclaim(player: Player, claim: string)
	local profile = profiles[player]
	if profile then
		profile.Data.Claims[claim] = nil
	end
end

-- Starts or extends a timed boost (e.g. "Luck") by `seconds`.
function DataManager.AddBoost(player: Player, boostId: string, seconds: number): boolean
	checkId("boostId", boostId)
	seconds = checkAmount(seconds)
	local profile = profiles[player]
	if not profile then
		return false
	end
	local now = os.time()
	profile.Data.Boosts[boostId] = math.max(profile.Data.Boosts[boostId] or 0, now) + seconds
	replicateExtras(profile)
	return true
end

-- Whether a timed boost is running right now.
function DataManager.HasBoost(player: Player, boostId: string): boolean
	local profile = profiles[player]
	return profile ~= nil and (profile.Data.Boosts[boostId] or 0) > os.time()
end

-- Uses a Daily Wheel spin: a free one if fewer than `freePerDay` were used in the
-- last `cooldown` seconds, else a bought one. Returns "Free", "Paid", or nil when
-- the player has no spin left.
function DataManager.UseWheelSpin(player: Player, freePerDay: number, cooldown: number): string?
	local profile = profiles[player]
	if not profile then
		return nil
	end
	local wheel = profile.Data.DailyWheel
	local now = os.time()
	local recent = {}
	for _, usedAt in wheel.FreeSpins do
		if now - usedAt < cooldown then
			table.insert(recent, usedAt)
		end
	end
	wheel.FreeSpins = recent
	local kind: string? = nil
	if #recent < freePerDay then
		table.insert(recent, now)
		kind = "Free"
	elseif wheel.Spins > 0 then
		wheel.Spins -= 1
		kind = "Paid"
	end
	replicateExtras(profile)
	return kind
end

function DataManager.AddWheelSpins(player: Player, amount: number): boolean
	amount = checkAmount(amount)
	local profile = profiles[player]
	if not profile then
		return false
	end
	profile.Data.DailyWheel.Spins += amount
	replicateExtras(profile)
	return true
end

-- Rolls ----------------------------------------------------------------------

-- Spends one Roll. Returns false (changing nothing) if the player has none.
function DataManager.UseRoll(player: Player): boolean
	local profile = profiles[player]
	if not profile or profile.Data.Rolls < 1 then
		return false
	end
	profile.Data.Rolls -= 1
	replicateStat(profile, "Rolls")
	return true
end

function DataManager.AddRolls(player: Player, amount: number): boolean
	amount = checkAmount(amount)
	local profile = profiles[player]
	if not profile then
		return false
	end
	profile.Data.Rolls += amount
	replicateStat(profile, "Rolls")
	return true
end

-- Parts & completions --------------------------------------------------------

-- Unlocks a brainrot part so it can be equipped on a line.
-- Returns "New", "Duplicate" (the caller converts it into Coins/Gems) or "NotLoaded".
function DataManager.AddPart(player: Player, brainrotId: string, partType: string): AddPartResult
	checkId("brainrotId", brainrotId)
	checkPartType(partType)
	assert(Brainrots.ById[brainrotId], `[DataManager] Unknown brainrot {brainrotId}`)
	local profile = profiles[player]
	if not profile then
		return "NotLoaded"
	end

	local parts = profile.Data.Inventory.Parts
	local owned = parts[brainrotId]
	if not owned then
		owned = {}
		parts[brainrotId] = owned
	end
	if owned[partType] then
		return "Duplicate"
	end
	owned[partType] = true

	replicateInventory(profile)
	return "New"
end

function DataManager.HasPart(player: Player, brainrotId: string, partType: string): boolean
	local profile = profiles[player]
	return profile ~= nil and ownsPart(profile, brainrotId, partType)
end

-- Records that a full, matching brainrot shipped from `zoneId` (its edition). Returns:
--   isNewEdition: true the first time it completes in this edition (grant edition rewards)
--   isFirstEver: true if it had never been completed in any edition (grant gadget + morph)
-- For the edition jackpot, the caller records each earlier zone too.
function DataManager.RecordCompletion(player: Player, brainrotId: string, zoneId: string): (boolean, boolean)
	checkId("brainrotId", brainrotId)
	checkId("zoneId", zoneId)
	local profile = profiles[player]
	if not profile then
		return false, false
	end

	-- Completion requires every part unlocked. Guards against a production bug granting rewards.
	for _, partType in PART_TYPES do
		if not ownsPart(profile, brainrotId, partType) then
			warn(`[DataManager] {player.Name} can't complete {brainrotId}: missing {partType}`)
			return false, false
		end
	end

	local completed = profile.Data.Inventory.Completed
	local editions = completed[brainrotId]
	local isFirstEver = editions == nil
	if not editions then
		editions = {}
		completed[brainrotId] = editions
	end
	if editions[zoneId] then
		return false, false
	end
	editions[zoneId] = os.time()

	replicateInventory(profile)
	return true, isFirstEver
end

-- With `zoneId`, checks that edition only. Without it, checks for any edition.
function DataManager.IsBrainrotComplete(player: Player, brainrotId: string, zoneId: string?): boolean
	local profile = profiles[player]
	local editions = profile and profile.Data.Inventory.Completed[brainrotId]
	if not editions then
		return false
	end
	return if zoneId then editions[zoneId] ~= nil else next(editions) ~= nil
end

-- Tycoon ---------------------------------------------------------------------

-- Spends Coins and marks the item purchased in one step. Returns false (changing
-- nothing) if it's already owned or unaffordable.
function DataManager.PurchaseItem(player: Player, itemId: string, price: number): boolean
	checkId("itemId", itemId)
	price = checkAmount(price)
	local profile = profiles[player]
	if not profile then
		return false
	end

	local data = profile.Data
	if data.Tycoon.Purchased[itemId] or data.Coins < price then
		return false
	end
	data.Coins -= price
	data.Tycoon.Purchased[itemId] = true
	replicateStat(profile, "Coins")
	return true
end

-- Moves the player to a step of Tralalero's guide (GuideManager), or "Done".
function DataManager.SetGuideStep(player: Player, step: string): boolean
	local profile = profiles[player]
	if not profile or not (step == Guide.Done or Guide.ById[step]) then
		return false
	end
	profile.Data.Guide = step
	player:SetAttribute("Guide", step)
	return true
end

function DataManager.HasPurchased(player: Player, itemId: string): boolean
	local profile = profiles[player]
	return profile ~= nil and profile.Data.Tycoon.Purchased[itemId] == true
end

-- Sets which part a line's dropper slot builds (nil clears it). Only checks that the
-- part is unlocked; line rules (one part, one line) are enforced by ProductionManager.
function DataManager.SetLinePart(player: Player, lineId: string, partType: string, brainrotId: string?): boolean
	checkId("lineId", lineId)
	checkPartType(partType)
	if brainrotId ~= nil then
		checkId("brainrotId", brainrotId)
	end
	local profile = profiles[player]
	if not profile or (brainrotId and not ownsPart(profile, brainrotId, partType)) then
		return false
	end

	local lines = profile.Data.Tycoon.Lines
	local line = lines[lineId]
	if not line then
		line = {}
		lines[lineId] = line
	end
	line[partType] = brainrotId
	return true
end

return DataManager
