--[[
	GadgetManager
	Morphs and gadgets (GDD §3, §7). Both unlock when the brainrot is claimed in the
	Album (all 4 of its parts owned, then CLAIM), which also pays its Gems.
	  * Morph: the brainrot is welded onto your character and your avatar is hidden.
	  * Gadgets: a Tool per archetype (Config/Gadgets). Movement boosts your speed while
	    held, Melee knocks other players back (never inside tycoon plots, which are safe
	    zones), and Emote animations are played by the client (GadgetsClient).
	Choices last for the session and come back after respawning. The current ones are
	mirrored to the "Morph" and "Gadget" Player attributes for the UI.
]]

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local BrainrotModels = require(Shared.BrainrotModels)
local Brainrots = require(Shared.Config.Brainrots)
local Gadgets = require(Shared.Config.Gadgets)
local Rarities = require(Shared.Config.Rarities)
local Remotes = require(Shared.Remotes)
local Sounds = require(Shared.Config.Sounds)

local DataManager = require(script.Parent.DataManager)
local TycoonManager = require(script.Parent.TycoonManager)

local PART_TYPES = Brainrots.PartTypes
local MORPH_SCALE = 0.85
local DEFAULT_WALK_SPEED = 16
local DEFAULT_JUMP_HEIGHT = 7.2
local REQUEST_COOLDOWN = 0.5
local KNOCKBACK_TIME = 0.25
local SWING_ARC = 0.3 -- targets must be roughly in front (dot product with your facing)
local ANNOUNCE_RANK = 3 -- claims of this rarity rank and up (Rare+) are announced to everyone

local morphs: { [Player]: string } = {}
local gadgets: { [Player]: string } = {}
local lastRequest: { [Player]: number } = {}
local lastSwing: { [Player]: number } = {}

local GadgetManager = {}

local function allowRequest(player: Player): boolean
	local now = os.clock()
	if (lastRequest[player] or 0) + REQUEST_COOLDOWN > now then
		return false
	end
	lastRequest[player] = now
	return true
end

local function isUnlocked(player: Player, brainrotId: unknown): boolean
	return typeof(brainrotId) == "string"
		and Brainrots.ById[brainrotId] ~= nil
		and DataManager.IsBrainrotClaimed(player, brainrotId)
end

-- Morphs ---------------------------------------------------------------------

local function clearMorph(character: Model)
	local existing = character:FindFirstChild("BrainrotMorph")
	if existing then
		existing:Destroy()
	end
	for _, descendant in character:GetDescendants() do
		local original = descendant:GetAttribute("MorphHidden")
		if original ~= nil and (descendant:IsA("BasePart") or descendant:IsA("Decal")) then
			descendant.Transparency = original
			descendant:SetAttribute("MorphHidden", nil)
		end
	end
end

local function applyMorph(character: Model, brainrotId: string)
	clearMorph(character)
	local root = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not (root and root:IsA("BasePart") and humanoid) then
		return
	end

	for _, descendant in character:GetDescendants() do
		if (descendant:IsA("BasePart") and descendant ~= root) or descendant:IsA("Decal") then
			descendant:SetAttribute("MorphHidden", descendant.Transparency)
			descendant.Transparency = 1
		end
	end

	-- The brainrot's root goes on the ground under the character, facing forward.
	local groundOffset = if humanoid.RigType == Enum.HumanoidRigType.R15 then humanoid.HipHeight + root.Size.Y / 2 else 3
	local rootCFrame = root.CFrame * CFrame.new(0, -groundOffset, 0)
	local morph = Instance.new("Model")
	morph.Name = "BrainrotMorph"
	for _, partType in PART_TYPES do
		local part = BrainrotModels.CreatePart(brainrotId, partType)
		part:ScaleTo(MORPH_SCALE)
		part:PivotTo(rootCFrame)
		for _, descendant in part:GetDescendants() do
			if descendant:IsA("BasePart") then
				descendant.Anchored = false
				descendant.Massless = true
				descendant.CanCollide = false
				descendant.CanQuery = false
				descendant.CanTouch = false
				local weld = Instance.new("WeldConstraint")
				weld.Part0 = root
				weld.Part1 = descendant
				weld.Parent = descendant
			end
		end
		part.Parent = morph
	end
	morph.Parent = character
end

-- Gadgets --------------------------------------------------------------------

local function knockback(root: BasePart, velocity: Vector3)
	local attachment = Instance.new("Attachment")
	attachment.Parent = root
	local push = Instance.new("LinearVelocity")
	push.Attachment0 = attachment
	push.MaxForce = math.huge
	push.VectorVelocity = velocity
	push.Parent = root
	Debris:AddItem(push, KNOCKBACK_TIME)
	Debris:AddItem(attachment, KNOCKBACK_TIME)

	local sound = Instance.new("Sound")
	sound.SoundId = Sounds.Stamp
	sound.Volume = 0.8
	sound.Parent = root
	sound:Play()
	Debris:AddItem(sound, 2)
end

local function swing(player: Player, tool: Tool, gadget: Gadgets.Gadget)
	local now = os.clock()
	if (lastSwing[player] or 0) + (gadget.Cooldown or 1) > now then
		return
	end
	lastSwing[player] = now

	-- The default Animate script plays a slash when it sees this value in a tool.
	local slash = Instance.new("StringValue")
	slash.Name = "toolanim"
	slash.Value = "Slash"
	slash.Parent = tool
	Debris:AddItem(slash, 1)

	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not (root and root:IsA("BasePart")) or TycoonManager.IsInPlot(root.Position) then
		return
	end
	for _, other in Players:GetPlayers() do
		local otherRoot = other ~= player and other.Character and other.Character:FindFirstChild("HumanoidRootPart")
		if otherRoot and otherRoot:IsA("BasePart") and not TycoonManager.IsInPlot(otherRoot.Position) then
			local offset = otherRoot.Position - root.Position
			local flat = Vector3.new(offset.X, 0, offset.Z)
			local range = gadget.Range or 8
			if flat.Magnitude > 0 and flat.Magnitude <= range and flat.Unit:Dot(root.CFrame.LookVector) > SWING_ARC then
				local power = gadget.Knockback or 80
				knockback(otherRoot, flat.Unit * power + Vector3.new(0, power * 0.5, 0))
			end
		end
	end
end

-- A Launch gadget: throws you Forward (the way you face) and Up, every Cooldown s.
local lastLaunch: { [Player]: number } = {}
local function launch(player: Player, gadget: Gadgets.Gadget)
	local now = os.clock()
	if (lastLaunch[player] or 0) + (gadget.Cooldown or 2) > now then
		return
	end
	lastLaunch[player] = now
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		local look = root.CFrame.LookVector
		knockback(root, Vector3.new(look.X, 0, look.Z).Unit * (gadget.Forward or 0) + Vector3.new(0, gadget.Up or 0, 0))
	end
end

local function buildTool(brainrotId: string, gadget: Gadgets.Gadget): Tool
	local brainrot = Brainrots.ById[brainrotId]
	local tool = Instance.new("Tool")
	tool.Name = gadget.Name
	tool.CanBeDropped = false
	tool:SetAttribute("Gadget", gadget.Archetype)
	tool:SetAttribute("BrainrotId", brainrotId)

	if gadget.Archetype == "Emote" then
		tool.RequiresHandle = false
		return tool
	end

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.CanCollide = false
	handle.Color = brainrot.Color
	handle.TopSurface = Enum.SurfaceType.Smooth
	handle.BottomSurface = Enum.SurfaceType.Smooth
	if gadget.Archetype == "Melee" then
		handle.Size = Vector3.new(0.7, 0.7, 4.5)
		handle.Material = Enum.Material.Wood
		tool.Grip = CFrame.new(0, 0, -1.7) -- held near one end, like the classic sword
	else
		handle.Size = Vector3.new(1, 0.6, 1.6)
	end
	handle.Parent = tool
	return tool
end

local function removeGadgetTools(player: Player)
	local containers = { player:FindFirstChild("Backpack"), player.Character }
	for _, container in containers do
		for _, child in (container :: Instance):GetChildren() do
			if child:IsA("Tool") and child:GetAttribute("Gadget") ~= nil then
				child:Destroy()
			end
		end
	end
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = DEFAULT_WALK_SPEED
		humanoid.JumpHeight = DEFAULT_JUMP_HEIGHT
	end
end

local function giveGadget(player: Player, brainrotId: string)
	local gadget = Gadgets[brainrotId]
	local backpack = player:FindFirstChild("Backpack")
	if not (gadget and backpack) then
		return
	end
	local tool = buildTool(brainrotId, gadget)
	if gadget.Archetype == "Movement" then
		tool.Equipped:Connect(function()
			local humanoid = tool.Parent and tool.Parent:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid.WalkSpeed = gadget.WalkSpeed or DEFAULT_WALK_SPEED
				humanoid.UseJumpPower = false -- (JumpHeight only counts then)
				humanoid.JumpHeight = gadget.JumpHeight or DEFAULT_JUMP_HEIGHT
			end
		end)
		tool.Unequipped:Connect(function()
			local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid.WalkSpeed = DEFAULT_WALK_SPEED
				humanoid.JumpHeight = DEFAULT_JUMP_HEIGHT
			end
		end)
	elseif gadget.Archetype == "Melee" then
		tool.Activated:Connect(function()
			swing(player, tool, gadget)
		end)
	elseif gadget.Archetype == "Launch" then
		tool.Activated:Connect(function()
			launch(player, gadget)
		end)
	end
	tool.Parent = backpack
end

-- Remotes --------------------------------------------------------------------

-- Claims a brainrot whose 4 parts you own: its morph, its gadget and its Gems (the
-- rarity's CompletionGems). Returns the Gems paid, or nil.
local function onClaim(player: Player, brainrotId: unknown): number?
	if not allowRequest(player) or typeof(brainrotId) ~= "string" then
		return nil
	end
	local brainrot = Brainrots.ById[brainrotId]
	local rarity = brainrot and Rarities.ById[brainrot.Rarity]
	if not (brainrot and rarity) or not DataManager.ClaimBrainrot(player, brainrotId) then
		return nil
	end
	local gems = rarity.CompletionGems
	DataManager.AddCurrency(player, "Gems", gems)
	if rarity.Rank >= ANNOUNCE_RANK then
		Remotes.Event("Announce"):FireAllClients(`{player.DisplayName} unlocked {brainrot.Name}!`, rarity.Color, player)
	end
	return gems
end

-- Morphs into a claimed brainrot, or back to your avatar with nil.
local function onSetMorph(player: Player, brainrotId: unknown): boolean
	if not allowRequest(player) then
		return false
	end
	if brainrotId == nil then
		morphs[player] = nil
		player:SetAttribute("Morph", nil)
		if player.Character then
			clearMorph(player.Character)
		end
		return true
	end
	if not isUnlocked(player, brainrotId) then
		return false
	end
	local id = brainrotId :: string
	morphs[player] = id
	player:SetAttribute("Morph", id)
	if player.Character then
		applyMorph(player.Character, id)
	end
	return true
end

-- Equips a claimed brainrot's gadget, or none with nil.
local function onEquipGadget(player: Player, brainrotId: unknown): boolean
	if not allowRequest(player) then
		return false
	end
	if brainrotId ~= nil and not (isUnlocked(player, brainrotId) and Gadgets[brainrotId :: string]) then
		return false
	end
	removeGadgetTools(player)
	local id = brainrotId :: string?
	gadgets[player] = id
	player:SetAttribute("Gadget", id)
	if id then
		giveGadget(player, id)
	end
	return true
end

-- Public API -----------------------------------------------------------------

function GadgetManager.Init()
	Remotes.Function("ClaimBrainrot").OnServerInvoke = onClaim
	Remotes.Function("SetMorph").OnServerInvoke = onSetMorph
	Remotes.Function("EquipGadget").OnServerInvoke = onEquipGadget

	local function onPlayerAdded(player: Player)
		player.CharacterAppearanceLoaded:Connect(function(character)
			local morph = morphs[player]
			if morph then
				applyMorph(character, morph)
			end
		end)
		player.CharacterAdded:Connect(function()
			local gadget = gadgets[player]
			if gadget then
				player:WaitForChild("Backpack")
				giveGadget(player, gadget)
			end
		end)
	end
	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		morphs[player] = nil
		gadgets[player] = nil
		lastRequest[player] = nil
		lastSwing[player] = nil
		lastLaunch[player] = nil
	end)
end

return GadgetManager
