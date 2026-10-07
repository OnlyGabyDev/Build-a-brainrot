--[[
	FreeGifts
	Nine free gifts a UTC day (GDD §5 "Free gifts", Config/FreeGifts), each opening after
	so many minutes played that day. Time played today = what earlier sessions saved
	(Data.Gifts.Played) + this session so far; each save folds the session in. Mirrored
	for the client as "GiftsStart" (server time when today's play would have begun had
	it been one stretch: the client counts from it), "GiftsClaimed" ("1,2,4": the gifts
	opened) and "GiftsNext" (when tomorrow's start). Client/UI/GiftsMenu opens them
	(ClaimGift).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Config = require(Shared.Config.FreeGifts)
local Remotes = require(Shared.Remotes)

local DataManager = require(script.Parent.DataManager)
local RewardManager = require(script.Parent.RewardManager)

local REFRESH_INTERVAL = 1
local REQUEST_COOLDOWN = 0.3

local sessionStart: { [Player]: number } = {} -- os.clock() this session's time counts from
local lastRequest: { [Player]: number } = {}

local FreeGifts = {}

local function today(): number
	return os.time() // Config.SecondsPerDay
end

-- Seconds played today, this session included.
local function played(player: Player, data: DataManager.PlayerData): number
	local start = sessionStart[player]
	return data.Gifts.Played + (if start then os.clock() - start else 0)
end

local function update(player: Player)
	local data = DataManager.GetData(player)
	if not data then
		return
	end
	if not sessionStart[player] then
		sessionStart[player] = os.clock()
	end
	if data.Gifts.Day ~= today() then
		DataManager.ResetGifts(player, today())
		sessionStart[player] = os.clock()
	end
	-- (moves only when the time played is folded or the day turns: a second's drift is noise)
	local origin = workspace:GetServerTimeNow() - played(player, data)
	local shown = player:GetAttribute("GiftsStart")
	if typeof(shown) ~= "number" or math.abs(shown - origin) > 1.5 then
		player:SetAttribute("GiftsStart", origin)
	end
	local claimed = {}
	for _, index in data.Gifts.Claimed do
		table.insert(claimed, tostring(index))
	end
	table.sort(claimed)
	local text = table.concat(claimed, ",")
	if player:GetAttribute("GiftsClaimed") ~= text then
		player:SetAttribute("GiftsClaimed", text)
	end
	local nextDay = (data.Gifts.Day + 1) * Config.SecondsPerDay
	if player:GetAttribute("GiftsNext") ~= nextDay then
		player:SetAttribute("GiftsNext", nextDay)
	end
end

-- Opens free gift `index`: { Index, Text, Result? } or nil.
local function onClaim(player: Player, index: unknown): any
	if typeof(index) ~= "number" then
		return nil
	end
	local now = os.clock()
	if (lastRequest[player] or 0) + REQUEST_COOLDOWN > now then
		return nil
	end
	lastRequest[player] = now
	local gift = Config.List[index]
	local data = DataManager.GetData(player)
	if not (gift and data and data.Gifts.Day == today()) or played(player, data) < gift.Minutes * 60 then
		return nil
	end
	if not DataManager.ClaimGift(player, index) then
		return nil
	end
	local text, result = RewardManager.Grant(player, gift.Reward, "FreeGift")
	update(player)
	return { Index = index, Text = text, Result = result }
end

-- Studio testing: today's gifts as if `minutes` were played (none opened).
function FreeGifts.DevSetPlayed(player: Player, minutes: number): boolean
	local data = DataManager.GetData(player)
	if not data then
		return false
	end
	DataManager.ResetGifts(player, today())
	DataManager.AddGiftTime(player, minutes * 60)
	sessionStart[player] = os.clock()
	update(player)
	return true
end

function FreeGifts.Init()
	Remotes.Function("ClaimGift").OnServerInvoke = onClaim
	DataManager.OnPlayerLoaded(function(player)
		sessionStart[player] = os.clock()
		update(player)
	end)
	-- each save folds this session's time in (and a leaving one ends it)
	DataManager.OnBeforeSave(function(player, leaving)
		local start = sessionStart[player]
		if start then
			DataManager.AddGiftTime(player, os.clock() - start)
			if leaving then
				sessionStart[player] = nil
			else
				sessionStart[player] = os.clock()
			end
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		lastRequest[player] = nil
		task.delay(60, function() -- (the leaving save has folded it by then)
			if not player.Parent then
				sessionStart[player] = nil
			end
		end)
	end)
	task.spawn(function()
		while true do
			task.wait(REFRESH_INTERVAL)
			for _, player in Players:GetPlayers() do
				update(player)
			end
		end
	end)
end

return FreeGifts
