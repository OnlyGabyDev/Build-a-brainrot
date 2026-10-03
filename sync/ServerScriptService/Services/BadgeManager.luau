--[[
	BadgeManager
	Awards the Roblox badges in Config/Badges. Award(player, key) can be called as often
	as you like (on every box opened, say): each badge is checked against Roblox once
	per session and then remembered, so the badge API (rate-limited) is hit once at most.
	Badges whose Id is still 0 are skipped.
]]

local BadgeService = game:GetService("BadgeService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Badges = require(ReplicatedStorage.Shared.Config.Badges)

local BadgeManager = {}

-- per player: the badges they have (or are being awarded right now)
local done: { [Player]: { [string]: boolean } } = {}

function BadgeManager.Award(player: Player, key: string)
	local badge = Badges[key]
	assert(badge, `unknown badge {key}`)
	local mine = done[player]
	if badge.Id <= 0 or not mine or mine[key] then
		return
	end
	mine[key] = true -- claimed before yielding, so two calls can't both award it
	task.spawn(function()
		local ok, has = pcall(BadgeService.UserHasBadgeAsync, BadgeService, player.UserId, badge.Id)
		if ok and has then
			return
		end
		local awarded, err = pcall(BadgeService.AwardBadgeAsync, BadgeService, player.UserId, badge.Id)
		if not awarded then
			warn(`[BadgeManager] {key} for {player.Name} failed: {err}`)
			if done[player] then
				done[player][key] = nil -- try again on the next Award
			end
		end
	end)
end

function BadgeManager.Init()
	local function onPlayerAdded(player: Player)
		done[player] = {}
		BadgeManager.Award(player, "Welcome")
	end
	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		done[player] = nil
	end)
end

return BadgeManager
