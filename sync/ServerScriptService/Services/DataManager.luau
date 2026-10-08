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
local Rebirths = require(Shared.Config.Rebirths)
local Remotes = require(Shared.Remotes)

local IS_STUDIO = RunService:IsStudio()

-- Config ---------------------------------------------------------------------

-- Studio uses its own store so play-testing never touches live player data.
local STORE_NAME = if IS_STUDIO then "PlayerData_Studio" else "PlayerData"
local KEY_PREFIX = "Player_"
local DATA_VERSION = 3

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
	-- [brainrotId] = os.time() it was claimed in the Album (all 4 parts owned, then CLAIM:
	-- its morph, its gadget and its Gems)
	Claimed: { [string]: number },
	-- from before the Album (editions, by full ship): [brainrotId] = { [zoneId] = os.time() };
	-- only read once, to claim what an old save had completed
	Completed: { [string]: { [string]: number } },
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
	Upgrades: { [string]: number }, -- levels bought in the old Rebirth Shop (Config/Rebirths Legacy): they still count
	Mascot: { [string]: string }, -- the mascot's parts: [partType] = brainrotId (Config/Mascot)
	Boosts: { [string]: number }, -- [boostId] = os.time() it expires
	DailyWheel: { FreeSpins: { number }, Spins: number }, -- free spins used (times), bought spins
	DailyLogin: { Day: number, LastDay: number }, -- the login streak: the day last claimed (1-7) and its UTC day number (os.time() // 86400)
	Receipts: { string }, -- recent Robux purchase ids, so none is granted twice
	Claims: { [string]: number }, -- [claim] = os.time() it was last claimed (one-off and daily rewards)
	Stats: { TotalCoinsEarned: number, FirstJoin: number, LastJoin: number, RobuxSpent: number, Playtime: number, Perfects: number, LastSeen: number, LastIncome: number },
	Settings: { LowGraphics: boolean }, -- the player's own (Client/Performance)
	Guide: string, -- the step of Tralalero's guide they're on (Config/Guide), "Done" when finished
	Funnel: number, -- the last onboarding funnel step sent (Services/AnalyticsManager); -1: joined before it
	Achievements: { [string]: number }, -- [achievementId] = tiers claimed (Config/Achievements)
	-- lifetime counts the achievements read (never reset): Built, Boxes, Rolls, Spins,
	-- Upgrades, Days (UTC days played; LastDay the last), Room_<zoneId> (1: opened once)
	Counters: { [string]: number },
	-- today's three daily quests (Services/DailyMissions): the UTC day they were picked,
	-- each one's goal and its source's value then, whether it was claimed, and the bonus
	Missions: { Day: number, List: { DailyMission }, Bonus: boolean },
	-- today's free gifts (Services/FreeGifts): the UTC day, the seconds played that day
	-- before this session, and the gifts opened (their numbers)
	Gifts: { Day: number, Played: number, Claimed: { number } },
}

export type DailyMission = { Id: string, Goal: number, Base: number, Claimed: boolean }

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
		Claimed = {},
		Completed = {},
	},
	Tycoon = {
		Purchased = {}, -- [itemId] = true (reset on rebirth)
		Lines = {}, -- [lineId] = { Head = brainrotId, ... } (kept on rebirth)
	},
	Upgrades = {}, -- [upgradeId] = level
	Mascot = {
		Head = Brainrots.StarterId,
		Body = Brainrots.StarterId,
		Arms = Brainrots.StarterId,
		Legs = Brainrots.StarterId,
	},
	Boosts = {},
	DailyWheel = { FreeSpins = {}, Spins = 0 },
	DailyLogin = { Day = 0, LastDay = 0 },
	Receipts = {},
	Claims = {},
	Stats = {
		TotalCoinsEarned = 0,
		FirstJoin = 0,
		LastJoin = 0,
		RobuxSpent = 0, -- every Robux purchase, for the leaderboards
		Playtime = 0, -- seconds in game
		Perfects = 0, -- full matches shipped (Tralalero's guide waits for the first)
		LastSeen = 0, -- os.time() of the last save, and the income (Coins/s) then: the
		LastIncome = 0, -- offline earnings on the next join (Services/OfflineEarnings)
	},
	Settings = {
		LowGraphics = false,
	},
	Guide = Guide.Steps[1].Id,
	Funnel = 0,
	Achievements = {},
	Counters = {},
	Missions = { Day = 0, List = {}, Bonus = false },
	Gifts = { Day = 0, Played = 0, Claimed = {} },
}

-- What a client may set in its Settings, and the type each takes.
local SETTING_TYPES: { [string]: string } = { LowGraphics = "boolean" }

-- MIGRATIONS[n] upgrades saved data from version n to n + 1.
-- Adding a new field doesn't need one (reconcile fills it in). Renaming or
-- restructuring does: bump DATA_VERSION and add a step here.
local MIGRATIONS: { [number]: (data: any) -> () } = {}

-- 1 -> 2 (v5.6, the economy study, 2026-10-07): Coins went from billions to millions
-- (rooms x3 instead of x15, a rebirth 100M x (n + 1)^3 instead of 60B x 3^n). Every Coin
-- amount saved shrinks by the new rebirth cost over the old one at the player's rebirth
-- count, so they're as far toward their next rebirth as before. Their factory stays
-- bought and simply earns at the new rates.
MIGRATIONS[1] = function(data)
	local rebirths = if type(data.Rebirths) == "number" then data.Rebirths else 0
	local ratio = Rebirths.Cost(rebirths) / (60e9 * 3 ^ rebirths)
	local function scale(holder: any, key: string)
		if type(holder) == "table" and type(holder[key]) == "number" then
			holder[key] = math.floor(holder[key] * ratio)
		end
	end
	scale(data, "Coins")
	scale(data.Stats, "TotalCoinsEarned")
	scale(data.Stats, "LastIncome")
	-- today's "Earn n Coins" quest counts from a TotalCoinsEarned it saved
	local missions = type(data.Missions) == "table" and data.Missions.List
	for _, entry in (if type(missions) == "table" then missions else {}) :: any do
		if type(entry) == "table" and entry.Id == "Coins" then
			scale(entry, "Base")
			entry.Goal = math.max(1, math.floor((tonumber(entry.Goal) or 1) * ratio))
		end
	end
end

-- 2 -> 3 (v5.7, a bigger collection, 2026-10-07): our own Supremo Brainrotto left the
-- roster (real memes only); the new Godly, Dragon Cannelloni, takes its place everywhere a
-- brainrot id is saved (parts, claims, lines, the mascot, morph and gadget choices), so its
-- owners keep a Godly.
MIGRATIONS[2] = function(data)
	local OLD, NEW = "SupremoBrainrotto", "DragonCannelloni"
	local function swap(node: any)
		if type(node) ~= "table" then
			return
		end
		local moved = {}
		for key, value in node do
			if value == OLD then
				node[key] = NEW
			else
				swap(value)
			end
			if key == OLD then
				table.insert(moved, key)
			end
		end
		for _, key in moved do
			if node[NEW] == nil then
				node[NEW] = node[key]
			end
			node[key] = nil
		end
	end
	swap(data)
end

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
local saveCallbacks: { (Player, boolean) -> () } = {}
local currencyCallbacks: { (Player, string, number, number, string?, string?) -> () } = {}

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

-- The old Rebirth Shop's levels, as "Upgrade_<Id>" attributes for the UI (the mascot
-- shows their bonuses).
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
	-- and from before the onboarding funnel: they aren't counted in it
	if saved.Funnel == nil then
		saved.Funnel = -1
	end
	-- saves from before the Album: whatever they completed (in any edition) is claimed,
	-- and their first PERFECT is behind them
	local inventory = saved.Inventory
	if type(inventory) == "table" and inventory.Claimed == nil then
		local claimed = {}
		for brainrotId, editions in (if type(inventory.Completed) == "table" then inventory.Completed else {}) :: any do
			local first = math.huge
			for _, at in (if type(editions) == "table" then editions else {}) :: any do
				first = math.min(first, if type(at) == "number" then at else math.huge)
			end
			claimed[brainrotId] = if first < math.huge then first else os.time()
		end
		inventory.Claimed = claimed
		if next(claimed) ~= nil and type(saved.Stats) == "table" and saved.Stats.Perfects == nil then
			saved.Stats.Perfects = 1
		end
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

-- The OnBeforeSave callbacks: last changes to the data before it's written.
local function beforeSave(profile: Profile, leaving: boolean)
	for _, callback in saveCallbacks do
		local ok, problem = pcall(callback, profile.Player, leaving)
		if not ok then
			warn(`[DataManager] a before-save callback failed for {profile.Key}: {problem}`)
		end
	end
end

local function releaseProfile(profile: Profile)
	if profiles[profile.Player] ~= profile then
		return -- already released
	end
	beforeSave(profile, true)
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
				beforeSave(profile, false)
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

-- Runs `callback(player, leaving)` just before each save of a player's data, while it
-- can still change (through this API): every autosave, and once more as they leave or
-- the server shuts down (`leaving`), whatever order the PlayerRemoving listeners run in.
-- It must not yield.
function DataManager.OnBeforeSave(callback: (Player, boolean) -> ())
	table.insert(saveCallbacks, callback)
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

-- The OnCurrencyChanged callbacks: `amount` earned (> 0) or spent (< 0).
local function currencyChanged(profile: Profile, currency: string, amount: number, source: string?, sku: string?)
	for _, callback in currencyCallbacks do
		local ok, problem = pcall(callback, profile.Player, currency, amount, profile.Data[currency], source, sku)
		if not ok then
			warn(`[DataManager] a currency callback failed for {profile.Key}: {problem}`)
		end
	end
end

-- Runs `callback(player, currency, amount, balance, source, sku)` after every change of a
-- currency: `amount` earned (> 0) or spent (< 0), the new balance, and where it came
-- from or went (`source`, e.g. "Production"; `sku` a detail, e.g. a box's rarity). A
-- tycoon purchase's source is "Item" and its sku the item id; a rebirth's is "Rebirth".
-- It must not yield.
function DataManager.OnCurrencyChanged(callback: (Player, string, number, number, string?, string?) -> ())
	table.insert(currencyCallbacks, callback)
end

function DataManager.GetCurrency(player: Player, currency: string): number
	checkCurrency(currency)
	local profile = profiles[player]
	return if profile then profile.Data[currency] else 0
end

-- `source` and `sku` say where it came from (OnCurrencyChanged).
function DataManager.AddCurrency(player: Player, currency: string, amount: number, source: string?, sku: string?): boolean
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
	currencyChanged(profile, currency, amount, source, sku)
	return true
end

-- Returns false and changes nothing if the player can't afford it. `source` and `sku`
-- say where it went (OnCurrencyChanged).
function DataManager.SpendCurrency(player: Player, currency: string, amount: number, source: string?, sku: string?): boolean
	checkCurrency(currency)
	amount = checkAmount(amount)
	local profile = profiles[player]
	if not profile or profile.Data[currency] < amount then
		return false
	end

	profile.Data[currency] -= amount
	replicateStat(profile, currency)
	currencyChanged(profile, currency, -amount, source, sku)
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

-- Stamps the time and the player's income (Coins a second) at a save, for the offline
-- earnings on their next join.
function DataManager.SetLastSeen(player: Player, income: number): boolean
	local profile = profiles[player]
	if not (profile and type(income) == "number" and income == income and income >= 0 and income < math.huge) then
		return false
	end
	profile.Data.Stats.LastSeen = os.time()
	profile.Data.Stats.LastIncome = income
	return true
end

-- Spends `cost` Coins to rebirth: Coins and tycoon purchases reset and the rebirth count
-- (the mascot's level) goes up. Everything else is kept (GDD §10). Returns false
-- (changing nothing) if the player can't afford it.
function DataManager.Rebirth(player: Player, cost: number): boolean
	cost = checkAmount(cost)
	local profile = profiles[player]
	if not profile or profile.Data.Coins < cost then
		return false
	end
	local data = profile.Data
	local spent = data.Coins
	data.Coins = 0
	currencyChanged(profile, "Coins", -spent, "Rebirth") -- (while the data still says the stage it ends)
	data.Tycoon.Purchased = {}
	data.Rebirths += 1
	for _, stat in { "Coins", "Rebirths" } do
		replicateStat(profile, stat)
	end
	return true
end

-- Sets one part of the player's mascot to one they own. Returns whether it changed.
function DataManager.SetMascotPart(player: Player, partType: string, brainrotId: string): boolean
	checkPartType(partType)
	checkId("brainrotId", brainrotId)
	local profile = profiles[player]
	if not (profile and ownsPart(profile, brainrotId, partType)) then
		return false
	end
	profile.Data.Mascot[partType] = brainrotId
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

-- Records the login streak's reward claimed today (DailyLogin: `day` of the 7, on UTC
-- day `utcDay`). Returns false if today's was already claimed.
function DataManager.ClaimDailyLogin(player: Player, day: number, utcDay: number): boolean
	local profile = profiles[player]
	if not profile or profile.Data.DailyLogin.LastDay == utcDay then
		return false
	end
	profile.Data.DailyLogin.Day = day
	profile.Data.DailyLogin.LastDay = utcDay
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
	if kind then
		profile.Data.Counters.Spins = (profile.Data.Counters.Spins or 0) + 1
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
	profile.Data.Counters.Rolls = (profile.Data.Counters.Rolls or 0) + 1
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

-- Claims a brainrot in the Album (GDD §7): every one of its 4 parts must be owned, and
-- it's claimed once. The caller gives the rewards. Returns whether it was claimed now.
function DataManager.ClaimBrainrot(player: Player, brainrotId: string): boolean
	checkId("brainrotId", brainrotId)
	local profile = profiles[player]
	if not profile or profile.Data.Inventory.Claimed[brainrotId] then
		return false
	end
	for _, partType in PART_TYPES do
		if not ownsPart(profile, brainrotId, partType) then
			return false
		end
	end
	profile.Data.Inventory.Claimed[brainrotId] = os.time()
	replicateInventory(profile)
	return true
end

-- Whether it's claimed (its morph and gadget are the player's).
function DataManager.IsBrainrotClaimed(player: Player, brainrotId: string): boolean
	local profile = profiles[player]
	return profile ~= nil and profile.Data.Inventory.Claimed[brainrotId] ~= nil
end

-- Achievements -------------------------------------------------------------------

-- Adds to one of the player's lifetime counters (Data.Counters: "Built", "Boxes"...).
function DataManager.AddCounter(player: Player, name: string, amount: number): boolean
	checkId("counter", name)
	local profile = profiles[player]
	if not (profile and type(amount) == "number" and amount == amount and amount > 0 and amount < math.huge) then
		return false
	end
	local counters = profile.Data.Counters
	counters[name] = (counters[name] or 0) + amount
	return true
end

-- Raises a counter to `value` if it's lower. Returns whether it rose.
function DataManager.SetCounterMax(player: Player, name: string, value: number): boolean
	checkId("counter", name)
	local profile = profiles[player]
	if not (profile and type(value) == "number" and value == value and value < math.huge) then
		return false
	end
	local counters = profile.Data.Counters
	if (counters[name] or 0) >= value then
		return false
	end
	counters[name] = value
	return true
end

-- Records tier `tier` of an achievement as claimed, if it's the next one. The caller
-- checks the goal and gives the reward. Returns whether it was claimed now.
function DataManager.ClaimAchievementTier(player: Player, achievementId: string, tier: number): boolean
	checkId("achievementId", achievementId)
	local profile = profiles[player]
	if not profile or (profile.Data.Achievements[achievementId] or 0) ~= tier - 1 then
		return false
	end
	profile.Data.Achievements[achievementId] = tier
	return true
end

-- Sets the day's daily quests (Services/DailyMissions picks them).
function DataManager.SetDailyMissions(player: Player, day: number, list: { DailyMission })
	local profile = profiles[player]
	if profile then
		profile.Data.Missions = { Day = day, List = list, Bonus = false }
	end
end

-- Marks today's quest `index` claimed. The caller checks it's done and pays it.
-- Returns whether it was claimed now.
function DataManager.ClaimDailyMission(player: Player, index: number): boolean
	local profile = profiles[player]
	local mission = profile and profile.Data.Missions.List[index]
	if not mission or mission.Claimed then
		return false
	end
	mission.Claimed = true
	return true
end

-- Marks the bonus for all of today's quests claimed. Returns whether it was claimed now.
function DataManager.ClaimDailyMissionBonus(player: Player): boolean
	local profile = profiles[player]
	if not profile or profile.Data.Missions.Bonus or #profile.Data.Missions.List == 0 then
		return false
	end
	for _, mission in profile.Data.Missions.List do
		if not mission.Claimed then
			return false
		end
	end
	profile.Data.Missions.Bonus = true
	return true
end

-- Starts a new day's free gifts: none played or opened.
function DataManager.ResetGifts(player: Player, day: number)
	local profile = profiles[player]
	if profile then
		profile.Data.Gifts = { Day = day, Played = 0, Claimed = {} }
	end
end

-- Adds a session's seconds to today's time played for the free gifts.
function DataManager.AddGiftTime(player: Player, seconds: number)
	local profile = profiles[player]
	if profile and type(seconds) == "number" and seconds == seconds and seconds > 0 and seconds < math.huge then
		profile.Data.Gifts.Played += seconds
	end
end

-- Marks today's free gift `index` opened. The caller checks the time and pays it.
-- Returns whether it was opened now.
function DataManager.ClaimGift(player: Player, index: number): boolean
	local profile = profiles[player]
	if not profile or table.find(profile.Data.Gifts.Claimed, index) then
		return false
	end
	table.insert(profile.Data.Gifts.Claimed, index)
	return true
end

-- Studio testing: forgets every achievement tier claimed (and, with `counters`, the
-- counters too).
function DataManager.DevResetAchievements(player: Player, counters: boolean?)
	local profile = profiles[player]
	if profile then
		profile.Data.Achievements = {}
		if counters then
			profile.Data.Counters = {}
		end
	end
end

-- Counts a full match shipped (a PERFECT).
function DataManager.RecordPerfect(player: Player)
	local profile = profiles[player]
	if profile then
		profile.Data.Stats.Perfects += 1
	end
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
	if price > 0 then
		currencyChanged(profile, "Coins", -price, "Item", itemId)
	end
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

-- Records the last onboarding funnel step sent (Services/AnalyticsManager).
function DataManager.SetFunnelStep(player: Player, step: number): boolean
	local profile = profiles[player]
	if not profile then
		return false
	end
	profile.Data.Funnel = step
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
