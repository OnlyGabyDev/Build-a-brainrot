--[[
	DailyWheelManager
	The Daily Wheel (GDD §12): free spins every 24 hours (rolling; VIP gets one more)
	and spins bought in the shop. The server picks and grants the prize; the client's
	wheel only lands on it. Mirrors "WheelNextFree" (os.time() when the next free spin
	is ready, 0 = ready now) for the HUD; DataManager mirrors "WheelSpins" (bought).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local DailyWheel = require(Shared.Config.DailyWheel)
local Remotes = require(Shared.Remotes)

local DataManager = require(script.Parent.DataManager)
local MonetizationManager = require(script.Parent.MonetizationManager)
local RewardManager = require(script.Parent.RewardManager)

local REQUEST_COOLDOWN = 1
local REFRESH_INTERVAL = 30 -- seconds between "WheelNextFree" refreshes

local random = Random.new()
local lastRequest: { [Player]: number } = {}

local DailyWheelManager = {}

local function allowRequest(player: Player): boolean
	local now = os.clock()
	if (lastRequest[player] or 0) + REQUEST_COOLDOWN > now then
		return false
	end
	lastRequest[player] = now
	return true
end

-- When the player's next free spin is ready (0 = now), given the free spins they
-- used in the last day.
local function updateNextFree(player: Player)
	local data = DataManager.GetData(player)
	if not data then
		return
	end
	local freePerDay = MonetizationManager.FreeSpinsPerDay(player)
	local now = os.time()
	local recent = {}
	for _, usedAt in data.DailyWheel.FreeSpins do
		if now - usedAt < DailyWheel.Cooldown then
			table.insert(recent, usedAt)
		end
	end
	table.sort(recent)
	local nextFree = if #recent < freePerDay then 0 else recent[#recent - freePerDay + 1] + DailyWheel.Cooldown
	player:SetAttribute("WheelNextFree", nextFree)
end

local function rollPrize(): (number, DailyWheel.Prize)
	local total = 0
	for _, prize in DailyWheel.Prizes do
		total += prize.Weight
	end
	local pick = random:NextNumber() * total
	for index, prize in DailyWheel.Prizes do
		pick -= prize.Weight
		if pick <= 0 then
			return index, prize
		end
	end
	return #DailyWheel.Prizes, DailyWheel.Prizes[#DailyWheel.Prizes]
end

-- Returns the prize's index (for the wheel) and its reveal text, or nil when the
-- player has no spin.
local function onSpin(player: Player): (number?, string?)
	if not allowRequest(player) then
		return nil
	end
	local kind = DataManager.UseWheelSpin(player, MonetizationManager.FreeSpinsPerDay(player), DailyWheel.Cooldown)
	updateNextFree(player)
	if not kind then
		return nil
	end
	local index, prize = rollPrize()
	return index, (RewardManager.Grant(player, prize, "Wheel"))
end

function DailyWheelManager.Init()
	Remotes.Function("SpinDailyWheel").OnServerInvoke = onSpin
	DataManager.OnPlayerLoaded(updateNextFree)
	MonetizationManager.OnPassGranted(updateNextFree) -- VIP adds a free spin
	Players.PlayerRemoving:Connect(function(player)
		lastRequest[player] = nil
	end)
	task.spawn(function()
		while true do
			task.wait(REFRESH_INTERVAL)
			for _, player in Players:GetPlayers() do
				updateNextFree(player)
			end
		end
	end)
end

return DailyWheelManager
