--[[
	LootManager
	Rolls and shared map loot boxes (GDD §5). Every result is rolled here first; the
	client's wheel only animates toward it. Odds live in Config/Loot, so the wheel
	shows exactly what can drop.
	  * Rolls: a loot box you carry. Opening one rolls a rarity (from the player's
	    unlocked tiers) and a part type.
	  * Map loot boxes: shared. Boxes all over the map (half of them round a random
	    player's front yard) show their rarity and part type,
	    and whoever reaches one first gets it: mostly a part of the box's rarity,
	    sometimes a rarer one. Boxes only spawn in rarities someone in the server has
	    unlocked, and players who haven't unlocked a box's rarity can't open it.
	    Rare+ spawns are announced to everyone.
	  * Bought box drops (Config/Products, Kind "BoxDrop"; Config/Loot.Drops): boxes rain
	    onto the map round the buyer, rolled like a Roll with extra luck from the
	    rarities the buyer has unlocked, theirs alone for a while, then anyone's. They
	    sit on top of the map's own boxes and aren't replaced when opened.
	  * Duplicates convert into Coins (plus some income) or Gems, per rarity.
	The first map box a player opens earns the FirstBox badge (Rolls don't count).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Brainrots = require(Shared.Config.Brainrots)
local Loot = require(Shared.Config.Loot)
local Rarities = require(Shared.Config.Rarities)
local Rebirths = require(Shared.Config.Rebirths)
local Remotes = require(Shared.Remotes)

local BadgeManager = require(script.Parent.BadgeManager)
local DataManager = require(script.Parent.DataManager)
local FactoryBuilder = require(script.Parent.FactoryBuilder)
local MapBuilder = require(script.Parent.MapBuilder)
local MonetizationManager = require(script.Parent.MonetizationManager)
local ProductionManager = require(script.Parent.ProductionManager)
local TycoonManager = require(script.Parent.TycoonManager)

local PART_TYPES = Brainrots.PartTypes
local REQUEST_COOLDOWN = 0.25 -- per player, for open requests
local BOX_HEIGHT = 1.5 -- box center above the ground
local LUCK_SYNC_INTERVAL = 2 -- seconds between refreshes of the "Luck" attribute
local BOX_GAP = 7 -- studs kept between boxes (the biggest is ~5 across)

export type Box = {
	Id: number,
	Position: Vector3,
	Rarity: string,
	PartType: string,
	Bought: boolean?, -- a bought drop (not counted toward the map's own boxes)
	Owner: number?, -- a bought drop's buyer (UserId): only they can open it...
	OwnerName: string?,
	ReservedUntil: number?, -- ...until this server time (workspace:GetServerTimeNow)
}

-- a bought drop still to rain down
type Drop = { UserId: number, Name: string, Left: number }

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
local boxCount = 0 -- the map's own boxes (bought drops not included)
local boughtCount = 0
local dropQueue: { Drop } = {}
local dropping = false
local lastRequest: { [Player]: number } = {}
local nextBoxId = 0
local boxesRemote: RemoteEvent

local LootManager = {}

-- Rolling --------------------------------------------------------------------

-- A player's total luck: Rebirth Shop levels, passes and a running Luck boost.
local function luckOf(player: Player, data: DataManager.PlayerData): number
	return Rebirths.Luck(data.Upgrades) + MonetizationManager.Luck(player)
end

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

-- Whether a spot is clear of every box (across the ground).
local function clearOfBoxes(spot: Vector3): boolean
	for _, other in boxes do
		local offset = other.Position - spot
		if offset.X * offset.X + offset.Z * offset.Z < BOX_GAP * BOX_GAP then
			return false
		end
	end
	return true
end

-- Whether a box may land on `spot`: clear of the other boxes and off every factory lot.
local function boxFits(spot: Vector3): boolean
	return clearOfBoxes(spot) and not TycoonManager.IsInPlot(spot)
end

-- The middle of a player's front yard: just past their factory lot, toward the hub.
local function homeOf(player: Player): Vector3?
	local plot = TycoonManager.GetPlot(player)
	return plot and plot.CFrame * Vector3.new(0, 0, FactoryBuilder.Lot.Front - Loot.HomeOffset)
end

-- Where boxes rain round a player: round them, or their front yard while indoors.
local function aroundPlayer(player: Player): Vector3?
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local position = if root and root:IsA("BasePart") then root.Position else nil
	if position and TycoonManager.IsInPlot(position) then
		return homeOf(player) or position
	end
	return position
end

-- A spot for a box: on dry ground (hills included), clear of decor, factory lots and
-- other boxes; within `spread` of `near` if given (falling back to anywhere in the ring).
local function randomBoxPosition(near: Vector3?, spread: number?): Vector3
	local min, max = Loot.SpawnRadius.Min, Loot.SpawnRadius.Max
	local spot = near and MapBuilder.FindSpot(min, max, random, { Near = near, Spread = spread or Loot.Drops.Spread, Accept = boxFits })
	spot = spot or MapBuilder.FindSpot(min, max, random, { Accept = boxFits })
	if spot then
		return spot + Vector3.new(0, BOX_HEIGHT, 0)
	end
	-- Square-root sampling spreads boxes evenly over the ring instead of bunching them.
	local angle = random:NextNumber(0, math.pi * 2)
	local radius = math.sqrt(random:NextNumber(min * min, max * max))
	return Vector3.new(math.cos(angle) * radius, BOX_HEIGHT, math.sin(angle) * radius)
end

-- Where a new map box lands: `HomeShare` of the time round a random player's front
-- yard (so everyone finds some near home), otherwise anywhere on the map.
local function mapBoxPosition(): Vector3
	if random:NextNumber() < Loot.HomeShare then
		local homes = {}
		for _, player in Players:GetPlayers() do
			table.insert(homes, homeOf(player))
		end
		if #homes > 0 then
			return randomBoxPosition(homes[random:NextInteger(1, #homes)], Loot.HomeSpread)
		end
	end
	return randomBoxPosition()
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

local function addBox(box: Box)
	boxes[box.Id] = box
	if box.Bought then
		boughtCount += 1
	else
		boxCount += 1
	end
	boxesRemote:FireAllClients("Add", box)
end

local function spawnBox()
	if boxCount >= targetBoxCount() then
		return
	end
	nextBoxId += 1
	local rarityId = rollRarity(Loot.RollOdds(serverRebirths()), Rarities.List[1].Id)
	local box: Box = {
		Id = nextBoxId,
		Position = mapBoxPosition(),
		Rarity = rarityId,
		PartType = rollPartType(),
	}
	addBox(box)
	if Rarities.ById[rarityId].Rank >= Loot.AnnounceRank then
		boxesRemote:FireAllClients("Announce", box)
	end
end

-- Bought drops ---------------------------------------------------------------

-- One box of `drop`, round its buyer (anywhere if they've left). Its rarity rolls like
-- a Roll with the buyer's luck plus the drop's, from the rarities they've unlocked.
local function spawnDropBox(drop: Drop)
	local buyer = Players:GetPlayerByUserId(drop.UserId)
	local data = buyer and DataManager.GetData(buyer)
	local rebirths, luck = serverRebirths(), Loot.Drops.Luck
	local near: Vector3? = nil
	if buyer and data then
		rebirths = data.Rebirths
		luck += luckOf(buyer, data)
		near = aroundPlayer(buyer)
	end
	nextBoxId += 1
	addBox({
		Id = nextBoxId,
		Position = randomBoxPosition(near),
		Rarity = rollRarity(Loot.RollOdds(rebirths, luck), Rarities.List[1].Id),
		PartType = rollPartType(),
		Bought = true,
		Owner = if buyer then drop.UserId else nil,
		OwnerName = if buyer then drop.Name else nil,
		ReservedUntil = if buyer then workspace:GetServerTimeNow() + Loot.Drops.ReservedSeconds else nil,
	})
end

-- Rains the queued drops down one box at a time, holding back while MaxBought are out.
local function runDrops()
	if dropping then
		return
	end
	dropping = true
	while #dropQueue > 0 do
		if boughtCount >= Loot.Drops.MaxBought then
			task.wait(1)
		else
			local drop = dropQueue[1]
			spawnDropBox(drop)
			drop.Left -= 1
			if drop.Left <= 0 then
				table.remove(dropQueue, 1)
			end
			task.wait(Loot.Drops.Interval)
		end
	end
	dropping = false
end

-- A buyer who leaves frees their boxes for everyone at once (and the rest of their drop
-- still rains down, for everyone: spawnDropBox finds no buyer).
local function releaseBoxesOf(player: Player)
	for _, box in boxes do
		if box.Owner == player.UserId then
			box.Owner, box.OwnerName, box.ReservedUntil = nil, nil, nil
			boxesRemote:FireAllClients("Update", box)
		end
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
	local odds = Loot.RollOdds(data.Rebirths, luckOf(player, data))
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
	if box.Owner and box.Owner ~= player.UserId and workspace:GetServerTimeNow() < (box.ReservedUntil or 0) then
		return nil -- someone's bought box, still theirs
	end

	boxes[box.Id] = nil
	if box.Bought then
		boughtCount -= 1
	else
		boxCount -= 1
		task.delay(random:NextNumber(Loot.RespawnTime.Min, Loot.RespawnTime.Max), spawnBox)
	end
	boxesRemote:FireAllClients("Remove", box.Id, player)
	BadgeManager.Award(player, "FirstBox")
	local odds = Loot.BoxOdds(box.Rarity, data.Rebirths, luckOf(player, data))
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

-- Studio only (DevTools' SpawnBox): `count` boxes of one rarity land round `player`
-- (to watch each rarity's arrival). They're anyone's, like a bought box whose buyer left.
function LootManager.DevSpawnBoxes(player: Player, rarityName: string, count: number?): boolean
	local near = aroundPlayer(player)
	local rarity = nil
	for _, candidate in Rarities.List do
		if string.lower(candidate.Id) == string.lower(tostring(rarityName)) then
			rarity = candidate
		end
	end
	if not (rarity and near) then
		return false
	end
	local first = nil
	for _ = 1, math.clamp(count or 1, 1, 50) do
		nextBoxId += 1
		local box: Box = {
			Id = nextBoxId,
			Position = randomBoxPosition(near),
			Rarity = rarity.Id,
			PartType = rollPartType(),
			Bought = true,
		}
		addBox(box)
		first = first or box
	end
	-- announced like a map spawn (once), to see the banner too
	if first and rarity.Rank >= Loot.AnnounceRank then
		boxesRemote:FireAllClients("Announce", first)
	end
	return true
end

-- Rains `count` boxes onto the map round `player` (a bought drop). Doesn't yield.
function LootManager.Drop(player: Player, count: number)
	table.insert(dropQueue, { UserId = player.UserId, Name = player.DisplayName, Left = count })
	boxesRemote:FireAllClients("Drop", { Name = player.DisplayName, Count = count })
	task.spawn(runDrops)
end

function LootManager.Init()
	boxesRemote = Remotes.Event("LootBoxes")
	Remotes.Function("OpenRoll").OnServerInvoke = onOpenRoll
	Remotes.Function("OpenBox").OnServerInvoke = onOpenBox
	Remotes.Function("GetLootBoxes").OnServerInvoke = onGetBoxes

	DataManager.OnPlayerLoaded(fillBoxes)
	Players.PlayerRemoving:Connect(function(player)
		lastRequest[player] = nil
		releaseBoxesOf(player)
	end)
	MonetizationManager.HandleProduct("BoxDrop", function(player, product)
		LootManager.Drop(player, product.Amount)
		return `🎁 {product.Amount} {if product.Amount == 1 then "box is" else "boxes are"} raining down round you!`
	end)

	-- The loot wheel shows odds with the player's luck, which changes with upgrades,
	-- passes and boosts that run out, so keep the attribute fresh.
	task.spawn(function()
		while true do
			for _, player in Players:GetPlayers() do
				local data = DataManager.GetData(player)
				if data then
					player:SetAttribute("Luck", luckOf(player, data))
				end
			end
			task.wait(LUCK_SYNC_INTERVAL)
		end
	end)
end

return LootManager
