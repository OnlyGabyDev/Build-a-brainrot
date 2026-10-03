--[[
	LootBoxes
	Draws the shared loot boxes around the hub (GDD §5) and opens one when your
	character walks into it. The server owns the boxes, checks reach and rolls the
	result; this only draws them, asks to open, and plays the wheel. Boxes of a rarity
	you haven't unlocked show a lock instead.

	Every rarity has its own look, arrival and opening (GDD §5): the rarer, the bigger and
	louder. Common to Rare: a gift box that drops out of the sky and bounces (Rare with
	glowing edges); Legendary: a gold box under a halo of lights in a beam of light;
	Mythic: a crystal box with a glowing core and stars orbiting it, crashing down like a
	meteor; Godly: a rainbow box floating over a black hole, rising out of it. Opening one
	bursts in sparkles, confetti, a shockwave and a flash, bigger with the rarity.
]]

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Effects = require(ReplicatedStorage:WaitForChild("Client"):WaitForChild("Effects"))
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
type Entry = {
	Box: Box,
	Model: Model,
	Opening: boolean,
	RetryAt: number,
	Born: number?, -- when it arrived (it plays its arrival), nil if it was already there
	Landed: boolean,
	Stars: { BasePart }, -- Mythic: orbiting stars
	Rainbow: { BasePart }, -- Godly: parts that cycle through the rainbow
	Portal: Model?, -- Godly: the black hole under it
}

local INTRO = { 1.1, 1.1, 1.1, 1.2, 0.8, 1.8 } -- seconds, by rank
local DROP = { 30, 30, 34, 40, 90, 0 } -- studs it falls from, by rank (Godly rises)
local loaded = false -- (boxes there when you join just sit there)

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

local function makeBall(model: Model, size: number, offset: Vector3, color: Color3, material: Enum.Material?): Part
	local part = makePart(model, Vector3.one * size, offset, color, material)
	part.Shape = Enum.PartType.Ball
	return part
end

local function emitter(parent: BasePart, color: ColorSequence, rate: number, size: number, speed: number)
	local sparkles = Instance.new("ParticleEmitter")
	sparkles.Texture = SPARKLE_TEXTURE
	sparkles.Color = color
	sparkles.LightEmission = 1
	sparkles.Size = NumberSequence.new(size, 0)
	sparkles.Lifetime = NumberRange.new(1, 1.6)
	sparkles.Speed = NumberRange.new(speed * 0.5, speed)
	sparkles.SpreadAngle = Vector2.new(180, 180)
	sparkles.Rate = rate
	sparkles.Parent = parent
end

local RAINBOW = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 90, 90)),
	ColorSequenceKeypoint.new(0.33, Color3.fromRGB(255, 230, 80)),
	ColorSequenceKeypoint.new(0.66, Color3.fromRGB(90, 220, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(220, 110, 255)),
})

-- A gift box in the rarity's color: a lid, ribbons and a bow, a glow and sparkles, its
-- part type and rarity over it; the rarer, the bigger and the more it has (see the top).
local function buildBox(entry: Entry)
	local box = entry.Box
	local rarity = Rarities.ById[box.Rarity]
	local rank = rarity.Rank
	local k = 1 + (rank - 1) * 0.12 -- its size
	local godly = rarity.Id == "Godly"
	local model = Instance.new("Model")
	model.Name = `LootBox{box.Id}`
	local light = rarity.Color:Lerp(Color3.new(1, 1, 1), 0.35)

	local material = if rank == 4 then Enum.Material.Metal elseif rank == 5 then Enum.Material.Glass else nil
	local base = makePart(model, Vector3.new(3, 2.4, 3) * k, Vector3.zero, rarity.Color, material)
	local lid = makePart(model, Vector3.new(3.3, 0.7, 3.3) * k, Vector3.new(0, 1.5 * k, 0), light, if rank == 4 then Enum.Material.Metal else nil)
	makePart(model, Vector3.new(3.1, 3.2, 0.5) * k, Vector3.new(0, 0.2 * k, 0), RIBBON_COLOR, Enum.Material.Neon)
	makePart(model, Vector3.new(0.5, 3.2, 3.1) * k, Vector3.new(0, 0.2 * k, 0), RIBBON_COLOR, Enum.Material.Neon)
	-- a bow on top
	for _, side in { -1, 1 } do
		local loop = makePart(model, Vector3.new(1.4, 0.9, 0.5) * k, Vector3.new(side * 0.7 * k, 2.25 * k, 0), RIBBON_COLOR, Enum.Material.Neon)
		loop.CFrame *= CFrame.Angles(0, 0, side * math.rad(-30))
	end
	makeBall(model, 0.7 * k, Vector3.new(0, 2.1 * k, 0), RIBBON_COLOR, Enum.Material.Neon)
	model.PrimaryPart = base
	model.WorldPivot = CFrame.identity
	if godly then
		table.insert(entry.Rainbow, base)
		table.insert(entry.Rainbow, lid)
	end

	-- Rare and up: glowing edges
	if rank >= 3 then
		for _, x in { -1.5, 1.5 } do
			for _, z in { -1.5, 1.5 } do
				local edge = makePart(model, Vector3.new(0.25, 2.5, 0.25) * k, Vector3.new(x, 0, z) * k, light, Enum.Material.Neon)
				edge.CastShadow = false
				if godly then
					table.insert(entry.Rainbow, edge)
				end
			end
		end
	end
	-- Legendary and up: a beam of light and a halo of lights over it
	if rank >= 4 then
		local beam = makePart(model, Vector3.new(60, 2.6 * k, 2.6 * k), Vector3.new(0, 30, 0), light, Enum.Material.Neon)
		beam.Shape = Enum.PartType.Cylinder
		beam.CFrame = CFrame.new(0, 30, 0) * CFrame.Angles(0, 0, math.pi / 2)
		beam.Transparency = 0.8
		beam.CastShadow = false
		for index = 0, 9 do
			local a = index / 10 * math.pi * 2
			makeBall(model, 0.45 * k, Vector3.new(math.cos(a) * 1.8 * k, 3.3 * k, math.sin(a) * 1.8 * k), RIBBON_COLOR, Enum.Material.Neon).CastShadow = false
		end
	end
	-- Mythic and up: a glowing core in the crystal, stars orbiting it
	if rank >= 5 then
		base.Transparency = 0.35
		makePart(model, Vector3.new(1.8, 1.4, 1.8) * k, Vector3.zero, light, Enum.Material.Neon)
		for _ = 1, 4 do
			local star = makeBall(model, 0.6 * k, Vector3.zero, Color3.new(1, 1, 1), Enum.Material.Neon)
			star.CastShadow = false
			table.insert(entry.Stars, star)
		end
	end

	local glow = Instance.new("PointLight")
	glow.Color = rarity.Color
	glow.Range = 10 + rank * 3
	glow.Brightness = 1 + rank * 0.4
	glow.Parent = base
	emitter(base, if godly then RAINBOW else ColorSequence.new(rarity.Color), 4 + rank * 4, 0.4 + rank * 0.1, 1 + rank * 0.4)

	local label = Instance.new("BillboardGui")
	label.Size = UDim2.fromScale(6, 2.4)
	label.StudsOffset = Vector3.new(0, 3.6 * k + 0.6, 0)
	label.MaxDistance = 150 + rank * 30
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
	entry.Model = model

	-- Godly: a black hole under it, its swirl turning
	if godly and not entry.Portal then
		local portal = Instance.new("Model")
		portal.Name = `BlackHole{box.Id}`
		local disc = makePart(portal, Vector3.new(0.3, 9, 9), Vector3.zero, Color3.fromRGB(15, 5, 30))
		disc.Shape = Enum.PartType.Cylinder
		disc.CFrame = CFrame.Angles(0, 0, math.pi / 2)
		for index = 0, 15 do
			local a = index / 16 * math.pi * 2
			local bit = makePart(portal, Vector3.new(1.6, 0.25, 0.6), Vector3.new(math.cos(a) * 4.7, 0.1, math.sin(a) * 4.7), if index % 2 == 0 then Color3.fromRGB(170, 60, 255) else Color3.fromRGB(255, 120, 230), Enum.Material.Neon)
			bit.CFrame = CFrame.new(bit.Position) * CFrame.Angles(0, -a + 0.6, 0)
		end
		portal.WorldPivot = CFrame.identity
		portal.Parent = folder
		emitter(disc, ColorSequence.new(Color3.fromRGB(190, 120, 255)), 18, 0.6, 3)
		entry.Portal = portal
	end
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
	local entry: Entry = { Box = box, Model = nil :: any, Opening = false, RetryAt = 0, Born = if loaded then os.clock() else nil, Landed = not loaded, Stars = {}, Rainbow = {} }
	buildBox(entry)
	entries[box.Id] = entry
	if loaded then
		local rarity = Rarities.ById[box.Rarity]
		if rarity.Id == "Godly" then
			Effects.sound(box.Position, Sounds.RevealBig, 0.6, 0.8) -- the black hole opens
			Effects.flash(box.Position, Color3.fromRGB(190, 120, 255), 6, 40, 1.2)
		else
			Effects.sound(box.Position + Vector3.new(0, DROP[rarity.Rank], 0), Sounds.Whoosh, 0.35, 0.8)
		end
	end
end

local function removeBox(boxId: number, opener: Player?)
	local entry = entries[boxId]
	if not entry then
		return
	end
	entries[boxId] = nil
	local rarity = Rarities.ById[entry.Box.Rarity]
	local at = entry.Model:GetPivot().Position
	burst(at, rarity.Color)
	local rank = rarity.Rank
	Effects.confetti(at, 8 + rank * 8)
	Effects.ring(at - Vector3.new(0, 1, 0), rarity.Color, 4 + rank * 2, 0.6)
	Effects.flash(at, rarity.Color, 2 + rank, 14 + rank * 4, 0.5)
	if rank >= 4 then
		Effects.sparkle(at + Vector3.new(0, 3, 0), Color3.fromRGB(255, 235, 150), 10 + rank * 5)
		Effects.sound(at, Sounds.Jingle, 0.5, 1)
	end
	entry.Model:Destroy()
	if entry.Portal then
		local portal = entry.Portal
		entry.Portal = nil
		task.spawn(function()
			for step = 1, 12 do -- the black hole closes
				portal:ScaleTo(math.max(1 - step / 12, 0.05))
				task.wait(0.03)
			end
			portal:Destroy()
		end)
	end
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
		table.clear(entry.Stars)
		table.clear(entry.Rainbow)
		buildBox(entry)
	end
end)

-- Bob, spin, and open when the character walks in.
RunService.RenderStepped:Connect(function()
	local now = os.clock()
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	for id, entry in entries do
		local box = entry.Box
		local rarity = Rarities.ById[box.Rarity]
		local bob = math.sin(now * 2 + id) * BOB_HEIGHT
		-- its arrival: dropping out of the sky (a meteor for a Mythic), or rising out of
		-- its black hole (Godly); a bump and a puff when it lands
		local offset = 0
		if entry.Born then
			local a = math.clamp((now - entry.Born) / INTRO[rarity.Rank], 0, 1)
			if rarity.Id == "Godly" then
				offset = -7 * (1 - a) * (1 - a)
				if entry.Portal then
					entry.Portal:ScaleTo(math.max(math.min(a * 2.5, 1), 0.05))
				end
			elseif rarity.Rank == 5 then
				offset = DROP[5] * (1 - a * a) -- faster and faster
			else
				local t = 1 - a
				offset = DROP[rarity.Rank] * t * t * (1 + math.sin(a * math.pi * 3) * 0.1)
			end
			if a >= 1 and not entry.Landed then
				entry.Landed = true
				entry.Born = nil
				local ground = box.Position - Vector3.new(0, 1.2, 0)
				Effects.puff(ground, Color3.fromRGB(235, 225, 210), 6 + rarity.Rank * 2, 1)
				Effects.ring(ground, rarity.Color, 3 + rarity.Rank * (if rarity.Rank == 5 then 4 else 1.5), 0.6)
				Effects.sound(ground, if rarity.Rank >= 5 then Sounds.Clunk else Sounds.Pop, 0.5, if rarity.Rank >= 5 then 0.7 else 1)
				if rarity.Rank >= 4 then
					Effects.flash(ground, rarity.Color, 4, 30, 0.6)
				end
			end
		end
		local spin = now * (0.8 + rarity.Rank * 0.15) + id
		local pivot = CFrame.new(box.Position + Vector3.new(0, bob + offset, 0)) * CFrame.Angles(0, spin, 0)
		entry.Model:PivotTo(pivot)
		-- Mythic stars orbit; Godly cycles through the rainbow over its black hole
		for index, star in entry.Stars do
			local a = now * 2 + index * math.pi / 2
			star.CFrame = CFrame.new(box.Position + Vector3.new(math.cos(a) * 3.6, bob + offset + 1 + math.sin(a * 1.5) * 1.2, math.sin(a) * 3.6))
		end
		if #entry.Rainbow > 0 then
			local color = Color3.fromHSV((now * 0.25 + id * 0.1) % 1, 0.65, 1)
			for _, part in entry.Rainbow do
				part.Color = color
			end
		end
		if entry.Portal then
			entry.Portal:PivotTo(CFrame.new(box.Position - Vector3.new(0, 1.6, 0)) * CFrame.Angles(0, -now * 1.6, 0))
		end

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
loaded = true
