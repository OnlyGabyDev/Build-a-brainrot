--[[
	LootManager
	Rolls and shared map loot boxes (GDD §5). Every result is rolled here first; the
	client's wheel only animates toward it. Odds live in Config/Loot, so the wheel
	shows exactly what can drop.
	  * Rolls: a loot box you carry. Opening one rolls a rarity (from the player's
	    unlocked tiers) and a part type.
	  * Map loot boxes: shared. Boxes around the hub show their rarity and part type,
	    and whoever reaches one first gets it: mostly a part of the box's rarity,
	    sometimes a rarer one. Boxes only spawn in rarities someone in the server has
	    unlocked, and players who haven't unlocked a box's rarity can't open it.
	    Rare+ spawns are announced to everyone.
	  * Duplicates convert into Coins (plus some income) or Gems, per rarity.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Brainrots = require(Shared.Config.Brainrots)
local Loot = require(Shared.Config.Loot)
local Rarities = require(Shared.Config.Rarities)
local Rebirths = require(Shared.Config.Rebirths)
local Remotes = require(Shared.Remotes)

local DataManager = require(script.Parent.DataManager)
local ProductionManager = require(script.Parent.ProductionManager)

local PART_TYPES = Brainrots.PartTypes
local REQUEST_COOLDOWN = 0.25 -- per player, for open requests
local BOX_HEIGHT = 1.5 -- box center above the ground (the baseplate's top is Y = 0)

export type Box = {
	Id: number,
	Position: Vector3,
	Rarity: string,
	PartType: string,
}

export type Result = {
	Source: string, -- "Roll" | "Box"
	BoxRarity: string?, -- boxes only: the rarity the box showed
	BrainrotId: string,
	PartType: string,
	Rarity: string,
	New: boolean,
	Currency: string?, -- duplicates only: what it converted into
	Amount: number?,
}

local random = Random.new()
local boxes: { [number]: Box } = {}
local boxCount = 0
local lastRequest: { [Player]: number } = {}
local nextBoxId = 0
local boxesRemote: RemoteEvent

local LootManager = {}

-- Rolling --------------------------------------------------------------------

-- Picks a rarity id from weighted odds (see Config/Loot).
local function rollRarity(odds: Loot.Odds, fallback: string): string
	local total = 0
	for _, weight in odds do
		total += weight
	end
	local pick = random:NextNumber() * total
	for _, rarity in Rarities.List do -- a fixed order, so the roll is fair
		local weight = odds[rarity.Id]
		if weight then
			pick -= weight
			if pick <= 0 then
				return rarity.Id
			end
		end
	end
	return fallback
end

local function rollPartType(): string
	return PART_TYPES[random:NextInteger(1, #PART_TYPES)]
end

local function rollBrainrot(rarityId: string): string
	local pool = Brainrots.ByRarity[rarityId]
	return pool[random:NextInteger(1, #pool)].Id
end

-- Unlocks the part, or converts a duplicate into currency.
local function grant(player: Player, source: string, brainrotId: string, partType: string): Result?
	local rarity = Rarities.ById[Brainrots.ById[brainrotId].Rarity]
	local status = DataManager.AddPart(player, brainrotId, partType)
	if status == "NotLoaded" then
		return nil
	end

	local result: Result = {
		Source = source,
		BoxRarity = nil,
		BrainrotId = brainrotId,
		PartType = partType,
		Rarity = rarity.Id,
		New = status == "New",
		Currency = nil,
		Amount = nil,
	}
	if status == "Duplicate" then
		local amount = rarity.DuplicateValue
		if rarity.DuplicateCurrency == "Coins" then
			amount += ProductionManager.GetIncome(player) * Loot.DuplicateIncomeSeconds
		end
		amount = math.floor(amount)
		DataManager.AddCurrency(player, rarity.DuplicateCurrency, amount)
		result.Currency = rarity.DuplicateCurrency
		result.Amount = amount
	end
	return result
end

local function allowRequest(player: Player): boolean
	local now = os.clock()
	if (lastRequest[player] or 0) + REQUEST_COOLDOWN > now then
		return false
	end
	lastRequest[player] = now
	return true
end

-- Map loot boxes -------------------------------------------------------------

local function randomBoxPosition(): Vector3
	local angle = random:NextNumber(0, math.pi * 2)
	local min, max = Loot.SpawnRadius.Min, Loot.SpawnRadius.Max
	-- Square-root sampling spreads boxes evenly over the ring instead of bunching them.
	local radius = math.sqrt(random:NextNumber(min * min, max * max))
	return Vector3.new(math.cos(angle) * radius, BOX_HEIGHT, math.sin(angle) * radius)
end

-- More players, more boxes.
local function targetBoxCount(): number
	local loaded = 0
	for _, player in Players:GetPlayers() do
		if DataManager.IsLoaded(player) then
			loaded += 1
		end
	end
	if loaded == 0 then
		return 0
	end
	return math.min(Loot.BaseBoxes + (loaded - 1) * Loot.BoxesPerPlayer, Loot.MaxBoxes)
end

-- Boxes roll from the best rarities anyone here has unlocked.
local function serverRebirths(): number
	local best = 0
	for _, player in Players:GetPlayers() do
		local data = DataManager.GetData(player)
		if data then
			best = math.max(best, data.Rebirths)
		end
	end
	return best
end

local function spawnBox()
	if boxCount >= targetBoxCount() then
		return
	end
	nextBoxId += 1
	local rarityId = rollRarity(Loot.RollOdds(serverRebirths()), Rarities.List[1].Id)
	local box: Box = {
		Id = nextBoxId,
		Position = randomBoxPosition(),
		Rarity = rarityId,
		PartType = rollPartType(),
	}
	boxes[box.Id] = box
	boxCount += 1
	boxesRemote:FireAllClients("Add", box)
	if Rarities.ById[rarityId].Rank >= Loot.AnnounceRank then
		boxesRemote:FireAllClients("Announce", box)
	end
end

local function fillBoxes()
	for _ = boxCount + 1, targetBoxCount() do
		spawnBox()
	end
end

-- Remotes --------------------------------------------------------------------

local function onOpenRoll(player: Player): Result?
	if not allowRequest(player) then
		return nil
	end
	local data = DataManager.GetData(player)
	if not data or not DataManager.UseRoll(player) then
		return nil
	end
	local odds = Loot.RollOdds(data.Rebirths, Rebirths.Luck(data.Upgrades))
	local rarityId = rollRarity(odds, Rarities.List[1].Id)
	return grant(player, "Roll", rollBrainrot(rarityId), rollPartType())
end

local function onOpenBox(player: Player, boxId: unknown): Result?
	if typeof(boxId) ~= "number" or not allowRequest(player) then
		return nil
	end
	local box = boxes[boxId]
	local data = DataManager.GetData(player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not (box and data and root and root:IsA("BasePart")) then
		return nil
	end
	if (root.Position - box.Position).Magnitude > Loot.OpenDistance then
		return nil
	end
	if data.Rebirths < Rarities.ById[box.Rarity].UnlockRebirths then
		return nil -- this rarity is still locked for them
	end

	boxes[box.Id] = nil
	boxCount -= 1
	boxesRemote:FireAllClients("Remove", box.Id, player)
	task.delay(random:NextNumber(Loot.RespawnTime.Min, Loot.RespawnTime.Max), spawnBox)
	local odds = Loot.BoxOdds(box.Rarity, data.Rebirths, Rebirths.Luck(data.Upgrades))
	local rarityId = rollRarity(odds, box.Rarity)
	local result = grant(player, "Box", rollBrainrot(rarityId), box.PartType)
	if result then
		result.BoxRarity = box.Rarity
	end
	return result
end

local function onGetBoxes(): { Box }
	local list = {}
	for _, box in boxes do
		table.insert(list, box)
	end
	return list
end

-- Public API -----------------------------------------------------------------

function LootManager.Init()
	boxesRemote = Remotes.Event("LootBoxes")
	Remotes.Function("OpenRoll").OnServerInvoke = onOpenRoll
	Remotes.Function("OpenBox").OnServerInvoke = onOpenBox
	Remotes.Function("GetLootBoxes").OnServerInvoke = onGetBoxes

	DataManager.OnPlayerLoaded(fillBoxes)
	Players.PlayerRemoving:Connect(function(player)
		lastRequest[player] = nil
	end)
end

return LootManager
