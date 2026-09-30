--[[
	LootBoxes
	Draws the shared loot boxes around the hub (GDD §5) and opens one when your
	character walks into it. The server owns the boxes, checks reach and rolls the
	result; this only draws them, asks to open, and plays the wheel. Boxes of a rarity
	you haven't unlocked show a lock instead.

	Per-rarity spawn/open effects (e.g. Godly boxes arriving through a black hole) are
	planned polish (GDD §5).
]]

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local LootConfig = require(Config:WaitForChild("Loot"))
local Rarities = require(Config:WaitForChild("Rarities"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Sounds = require(Config:WaitForChild("Sounds"))
local UI = ReplicatedStorage:WaitForChild("Client"):WaitForChild("UI")
local Kit = require(UI:WaitForChild("Kit"))
local Loot = require(UI:WaitForChild("Loot"))

local OPEN_DISTANCE = 6 -- walk this close to open (the server allows a bit more)
local RETRY_DELAY = 1
local BOB_HEIGHT = 0.4
local SPARKLE_TEXTURE = "rbxasset://textures/particles/sparkles_main.dds"
local RIBBON_COLOR = Color3.fromRGB(255, 215, 60)

type Box = { Id: number, Position: Vector3, Rarity: string, PartType: string }
type Entry = { Box: Box, Model: Model, Opening: boolean, RetryAt: number }

local player = Players.LocalPlayer
local entries: { [number]: Entry } = {}
local openBox = Remotes.Function("OpenBox")

local folder = Instance.new("Folder")
folder.Name = "LootBoxes"
folder.Parent = workspace

local function isLocked(rarity: Rarities.Rarity): boolean
	return (player:GetAttribute("Rebirths") or 0) < rarity.UnlockRebirths
end

local function makePart(model: Model, size: Vector3, offset: Vector3, color: Color3, material: Enum.Material?): Part
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Size = size
	part.CFrame = CFrame.new(offset)
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = model
	return part
end

-- A gift box in the rarity's color, with a glowing ribbon and a label.
local function buildBox(box: Box): Model
	local rarity = Rarities.ById[box.Rarity]
	local model = Instance.new("Model")
	model.Name = `LootBox{box.Id}`

	local base = makePart(model, Vector3.new(3, 2.4, 3), Vector3.zero, rarity.Color)
	makePart(model, Vector3.new(3.3, 0.7, 3.3), Vector3.new(0, 1.5, 0), rarity.Color:Lerp(Color3.new(1, 1, 1), 0.35))
	makePart(model, Vector3.new(3.1, 3.2, 0.5), Vector3.new(0, 0.2, 0), RIBBON_COLOR, Enum.Material.Neon)
	makePart(model, Vector3.new(0.5, 3.2, 3.1), Vector3.new(0, 0.2, 0), RIBBON_COLOR, Enum.Material.Neon)
	model.PrimaryPart = base
	model.WorldPivot = CFrame.identity

	local light = Instance.new("PointLight")
	light.Color = rarity.Color
	light.Range = 12
	light.Brightness = 1.5
	light.Parent = base

	local sparkles = Instance.new("ParticleEmitter")
	sparkles.Texture = SPARKLE_TEXTURE
	sparkles.Color = ColorSequence.new(rarity.Color)
	sparkles.LightEmission = 1
	sparkles.Size = NumberSequence.new(0.5, 0)
	sparkles.Lifetime = NumberRange.new(1, 1.5)
	sparkles.Speed = NumberRange.new(1, 2)
	sparkles.SpreadAngle = Vector2.new(180, 180)
	sparkles.Rate = 4 + rarity.Rank * 3
	sparkles.Parent = base

	local label = Instance.new("BillboardGui")
	label.Size = UDim2.fromScale(6, 2.4)
	label.StudsOffset = Vector3.new(0, 3.6, 0)
	label.MaxDistance = 150
	label.LightInfluence = 0
	label.Parent = base
	Kit.text({ Text = string.upper(box.PartType), Size = UDim2.fromScale(1, 0.55), Parent = label })
	Kit.text({
		Text = if isLocked(rarity) then `🔒 REBIRTH {rarity.UnlockRebirths}` else string.upper(rarity.Id),
		TextColor3 = rarity.Color,
		Position = UDim2.fromScale(0, 0.55),
		Size = UDim2.fromScale(1, 0.45),
		Parent = label,
	})

	model.Parent = folder
	return model
end

local function burst(position: Vector3, color: Color3)
	local anchor = Instance.new("Part")
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.Transparency = 1
	anchor.Size = Vector3.new(2, 2, 2)
	anchor.Position = position
	anchor.Parent = folder

	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture = SPARKLE_TEXTURE
	emitter.Color = ColorSequence.new(color)
	emitter.LightEmission = 0.8
	emitter.Size = NumberSequence.new(1.2, 0)
	emitter.Lifetime = NumberRange.new(0.5, 0.9)
	emitter.Speed = NumberRange.new(14, 24)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Acceleration = Vector3.new(0, -30, 0)
	emitter.Enabled = false
	emitter.Parent = anchor
	emitter:Emit(35)

	local sound = Instance.new("Sound")
	sound.SoundId = Sounds.Pop
	sound.Volume = 0.6
	sound.RollOffMaxDistance = 120
	sound.Parent = anchor
	sound:Play()
	Debris:AddItem(anchor, 2)
end

local function addBox(box: Box)
	if entries[box.Id] then
		return
	end
	entries[box.Id] = { Box = box, Model = buildBox(box), Opening = false, RetryAt = 0 }
end

local function removeBox(boxId: number, opener: Player?)
	local entry = entries[boxId]
	if not entry then
		return
	end
	entries[boxId] = nil
	local rarity = Rarities.ById[entry.Box.Rarity]
	burst(entry.Model:GetPivot().Position, rarity.Color)
	entry.Model:Destroy()
	if opener and opener ~= player and rarity.Rank >= LootConfig.AnnounceRank then
		Kit.toast(`{opener.DisplayName} grabbed the {string.upper(rarity.Id)} box!`, rarity.Color)
	end
end

local function tryOpen(entry: Entry)
	entry.Opening = true
	task.spawn(function()
		local ok, result = pcall(openBox.InvokeServer, openBox, entry.Box.Id)
		if ok and result then
			Loot.Show(result)
		else
			entry.Opening = false
			entry.RetryAt = os.clock() + RETRY_DELAY
		end
	end)
end

Remotes.Event("LootBoxes").OnClientEvent:Connect(function(action: string, payload: any, opener: Player?)
	if action == "Add" then
		addBox(payload)
	elseif action == "Remove" then
		removeBox(payload, opener)
	elseif action == "Announce" then
		local rarity = Rarities.ById[payload.Rarity]
		Kit.toast(`✨ A {string.upper(rarity.Id)} {string.upper(payload.PartType)} box spawned! ✨`, rarity.Color)
	end
end)

-- Relabel locked boxes after a rebirth.
player:GetAttributeChangedSignal("Rebirths"):Connect(function()
	for _, entry in entries do
		entry.Model:Destroy()
		entry.Model = buildBox(entry.Box)
	end
end)

-- Bob, spin, and open when the character walks in.
RunService.RenderStepped:Connect(function()
	local now = os.clock()
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	for id, entry in entries do
		local box = entry.Box
		local bob = math.sin(now * 2 + id) * BOB_HEIGHT
		entry.Model:PivotTo(CFrame.new(box.Position + Vector3.new(0, bob, 0)) * CFrame.Angles(0, now * 0.8 + id, 0))

		if root and not entry.Opening and now >= entry.RetryAt and not isLocked(Rarities.ById[box.Rarity]) then
			if (root.Position - box.Position).Magnitude <= OPEN_DISTANCE then
				tryOpen(entry)
			end
		end
	end
end)

local ok, boxes = pcall(function()
	return Remotes.Function("GetLootBoxes"):InvokeServer()
end)
if ok and typeof(boxes) == "table" then
	for _, box in boxes do
		addBox(box)
	end
end
