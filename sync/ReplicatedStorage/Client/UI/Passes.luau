--[[
	Passes
	What the shop and the corner ads (Upsell) share about gamepasses: prices, whether the
	player owns one, whether a limited offer (a pass with OfferHours, e.g. the Starter Pack) is
	still on and for how long, and the purchase prompt. Ownership comes from the server's
	"Pass_<Key>" attributes; the offer's end from "StarterOfferEnds".
]]

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Gamepasses = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("Gamepasses"))

local player = Players.LocalPlayer
local prices: { [string]: number | false } = {}

local Passes = {}

-- Robux price of a pass ("Pass") or a developer product ("Product"), fetched once (it
-- yields the first time). Nil if unknown or not on the dashboard yet.
function Passes.PriceOf(kind: string, id: number): number?
	if id <= 0 then
		return nil
	end
	local key = kind .. id
	if prices[key] == nil then
		local infoType = if kind == "Pass" then Enum.InfoType.GamePass else Enum.InfoType.Product
		local ok, info = pcall(MarketplaceService.GetProductInfo, MarketplaceService, id, infoType)
		prices[key] = if ok and info and info.PriceInRobux then info.PriceInRobux else false
	end
	return prices[key] or nil
end

function Passes.Owns(key: string): boolean
	return player:GetAttribute(`Pass_{key}`) == true
end

-- Seconds left on a limited pass's offer (0 once it's over), or nil for a pass that's
-- always on sale.
function Passes.OfferLeft(key: string): number?
	local pass = Gamepasses[key]
	if not (pass and pass.OfferHours) then
		return nil
	end
	local ends = player:GetAttribute("StarterOfferEnds")
	if typeof(ends) ~= "number" then
		return 0 -- not loaded yet: don't show it
	end
	return math.max(0, ends - workspace:GetServerTimeNow())
end

-- Whether the pass can be offered to this player right now: not owned, and its offer
-- (if it has one) still on.
function Passes.OnSale(key: string): boolean
	local left = Passes.OfferLeft(key)
	return Gamepasses[key] ~= nil and not Passes.Owns(key) and (left == nil or left > 0)
end

-- "23:59:07"
function Passes.Clock(seconds: number): string
	seconds = math.max(0, math.floor(seconds))
	return string.format("%02d:%02d:%02d", seconds // 3600, seconds % 3600 // 60, seconds % 60)
end

-- Prompts the purchase. False if the pass isn't on the dashboard yet (Id 0).
function Passes.Prompt(key: string): boolean
	local pass = Gamepasses[key]
	if not pass or pass.Id <= 0 or Passes.Owns(key) then
		return false
	end
	MarketplaceService:PromptGamePassPurchase(player, pass.Id)
	return true
end

return Passes
