--[[
	DropIn
	How a room upgrade arrives when a level is bought (GDD §6): the whole thing
	reassembles falling from above, piece by piece in the order the server built it (a
	track goes down segment by segment round its loop). Each piece drops, lands with a
	squash and stretch, a dust puff and a twinkle; once it's all down, a burst of
	sparkles, a ring, confetti and a flash of light.

	The real parts stay where the server put them (RoomFX and Atmosphere move some and
	remember their rest poses), hidden on this client while look-alike copies fall onto
	them, following them if they move. A piece is one of the upgrade's sub-Models (a
	train car, a lid, the plushie) or a loose part. The copies are made only when the
	drop-in actually plays near the camera: a whole factory being furnished across the
	map would otherwise copy ~15K parts on every client for nothing. Client only.

	TycoonFX calls `hide` on each freshly built part as it arrives, then `play` with the
	whole batch: for a room upgrade's new level, and for everything in a plot when it's
	claimed (each line and upgrade in turn, a lighter finale each).

	In Studio, `workspace:SetAttribute("DevSlowMotion", 5)` plays them 5× slower (to
	look at a fall up close).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Sounds = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("Sounds"))
local Effects = require(script.Parent:WaitForChild("Effects"))

local NEAR = 250 -- studs from the camera; farther builds just appear
local FALL_TIME = 0.4
local SQUASH_TIME = 0.55
local ASSEMBLY_TIME = 2.2 -- seconds for every piece to start falling (they stagger to fit)
local DUST = Color3.fromRGB(245, 235, 220)
local GOLD = Color3.fromRGB(255, 215, 90)
local EXTRAS = { "SurfaceGui", "BillboardGui", "ParticleEmitter", "Light", "Beam", "Trail" }

local DropIn = {}

type Saved = { Clone: BasePart?, Visible: boolean, Extras: { [Instance]: boolean } }
local saved: { [BasePart]: Saved } = {}

local function isExtra(instance: Instance): boolean
	for _, class in EXTRAS do
		if instance:IsA(class) then
			return true
		end
	end
	return false
end

-- A bare look-alike of `part`: no tags (Atmosphere and RoomFX would animate it), no
-- glows, particles or floating labels, just its shape, color and printing. `extras`:
-- what `hide` switched off on the real part (its printing comes back on the copy).
local function lookAlike(part: BasePart, extras: { [Instance]: boolean }): BasePart
	local originals = part:GetDescendants()
	local clone = part:Clone()
	for index, thing in clone:GetDescendants() do
		local original = originals[index]
		local same = original ~= nil and original.ClassName == thing.ClassName and original.Name == thing.Name
		if isExtra(thing) and not thing:IsA("SurfaceGui") then
			thing:Destroy()
		else
			if thing:IsA("SurfaceGui") then
				thing.Enabled = if same and extras[original :: Instance] ~= nil then extras[original :: Instance] else true
			elseif thing:IsA("Decal") then
				thing.LocalTransparencyModifier = 0
			end
			for _, tag in thing:GetTags() do
				thing:RemoveTag(tag)
			end
		end
	end
	for _, tag in clone:GetTags() do
		clone:RemoveTag(tag)
	end
	clone.LocalTransparencyModifier = 0
	clone.Anchored = true
	clone.CanCollide = false
	clone.CanQuery = false
	clone.CanTouch = false
	return clone
end

-- Hides a freshly built part until its piece has landed.
function DropIn.hide(part: BasePart)
	if saved[part] then
		return
	end
	local extras = {}
	for _, child in part:GetDescendants() do
		if isExtra(child) then
			extras[child] = (child :: any).Enabled
			;(child :: any).Enabled = false
		elseif child:IsA("Decal") then -- textures too
			child.LocalTransparencyModifier = 1
		end
	end
	part.LocalTransparencyModifier = 1
	saved[part] = { Clone = nil, Visible = part.Transparency < 1, Extras = extras }
end

local function reveal(part: BasePart)
	local entry = saved[part]
	if not entry then
		return
	end
	saved[part] = nil
	if entry.Clone then
		entry.Clone:Destroy()
	end
	part.LocalTransparencyModifier = 0
	for _, child in part:GetDescendants() do
		if child:IsA("Decal") then
			child.LocalTransparencyModifier = 0
		end
	end
	for extra, enabled in entry.Extras do
		(extra :: any).Enabled = enabled
	end
end

-- How far `cframe`/`size`'s box reaches up and down from its center.
local function halfHeight(cframe: CFrame, size: Vector3): number
	return (math.abs(cframe.RightVector.Y) * size.X + math.abs(cframe.UpVector.Y) * size.Y + math.abs(cframe.LookVector.Y) * size.Z) / 2
end

type Piece = {
	Parts: { BasePart },
	Clones: { BasePart },
	Order: number,
	Reference: BasePart, -- the piece's base point follows this part
	BaseLocal: Vector3, -- the bottom middle of the piece, in Reference's space
	Footprint: number, -- studs², for the dust
	Height: number, -- how high it falls from
	Start: number,
	Landed: boolean,
	Done: boolean,
}

local function newPiece(parts: { BasePart }, order: number): Piece
	local low, high = Vector3.one * math.huge, -Vector3.one * math.huge
	for _, part in parts do
		local cframe, size = part.CFrame, part.Size
		local extent = Vector3.new(
			math.abs(cframe.RightVector.X) * size.X + math.abs(cframe.UpVector.X) * size.Y + math.abs(cframe.LookVector.X) * size.Z,
			halfHeight(cframe, size) * 2,
			math.abs(cframe.RightVector.Z) * size.X + math.abs(cframe.UpVector.Z) * size.Y + math.abs(cframe.LookVector.Z) * size.Z
		) / 2
		low = low:Min(cframe.Position - extent)
		high = high:Max(cframe.Position + extent)
	end
	local base = Vector3.new((low.X + high.X) / 2, low.Y, (low.Z + high.Z) / 2)
	local clones = {}
	for index, part in parts do
		clones[index] = (saved[part] :: Saved).Clone :: BasePart
	end
	return {
		Parts = parts,
		Clones = clones,
		Order = order,
		Reference = parts[1],
		BaseLocal = parts[1].CFrame:PointToObjectSpace(base),
		Footprint = (high.X - low.X) * (high.Z - low.Z),
		Height = 7 + math.random() * 3,
		Start = 0,
		Landed = false,
		Done = false,
	}
end

-- Puts a piece's copies over its parts, `lift` studs up and squashed to `squash` of
-- its height about its bottom middle (wider as it squashes, narrower as it stretches).
local function pose(piece: Piece, lift: number, squash: number)
	local across = 1 / math.sqrt(squash)
	local base = piece.Reference.CFrame * piece.BaseLocal
	local function stretched(v: Vector3): number
		return Vector3.new(v.X * across, v.Y * squash, v.Z * across).Magnitude
	end
	for index, part in piece.Parts do
		local clone = piece.Clones[index]
		local cframe, size = part.CFrame, part.Size
		local offset = cframe.Position - base
		clone.CFrame = cframe.Rotation + base + Vector3.new(offset.X * across, offset.Y * squash + lift, offset.Z * across)
		clone.Size = Vector3.new(size.X * stretched(cframe.RightVector), size.Y * stretched(cframe.UpVector), size.Z * stretched(cframe.LookVector))
	end
end

local function finish(piece: Piece)
	piece.Done = true
	for _, part in piece.Parts do
		reveal(part)
	end
end

export type Options = {
	Title: string?, -- pops up once it's all down
	Delay: number?, -- seconds before the first piece falls
	Light: boolean?, -- one of many (a claim): no cha-ching, a smaller finale
}

-- Plays the drop-in for `parts` (all hidden with `hide`), the new contents of `model`.
function DropIn.play(model: Model, parts: { BasePart }, options: Options?)
	local title = options and options.Title
	local delay = options and options.Delay or 0
	local light = options ~= nil and options.Light == true
	local slow = if RunService:IsStudio() then workspace:GetAttribute("DevSlowMotion") else nil
	local timeScale = if typeof(slow) == "number" and slow > 0 then slow else 1
	local live = {}
	for _, part in parts do
		if part.Parent then
			table.insert(live, part)
		else
			saved[part] = nil
		end
	end
	if #live == 0 then
		return
	end
	local low, high = Vector3.one * math.huge, -Vector3.one * math.huge
	for _, part in live do
		local half = Vector3.new(part.Size.Magnitude, halfHeight(part.CFrame, part.Size) * 2, part.Size.Magnitude) / 2
		low = low:Min(part.Position - half)
		high = high:Max(part.Position + half)
	end
	local center = (low + high) / 2
	if not Effects.near(center, NEAR) then
		for _, part in live do
			reveal(part)
		end
		return
	end

	-- the pieces: each sub-Model of the upgrade, or a loose part; invisible parts (light
	-- and sparkle anchors, the bonus tag) just come back at the end
	local byKey: { [Instance]: { BasePart } } = {}
	local orderOf: { [Instance]: number } = {}
	local keys = {}
	local hidden = {}
	for index, part in live do
		local entry = saved[part]
		if entry and entry.Visible and not entry.Clone then
			entry.Clone = lookAlike(part, entry.Extras) -- (now that it's sure to play)
		end
		if entry and entry.Clone then
			local node: Instance = part
			while node.Parent and node.Parent ~= model do
				node = node.Parent
			end
			local key: Instance = if node:IsA("Model") and node.Parent == model then node else part
			if not byKey[key] then
				byKey[key] = {}
				table.insert(keys, key)
			end
			table.insert(byKey[key], part)
			local order = part:GetAttribute("BuildIndex")
			orderOf[key] = math.min(orderOf[key] or math.huge, if typeof(order) == "number" then order else index)
		else
			table.insert(hidden, part)
		end
	end
	local pieces: { Piece } = {}
	for _, key in keys do
		table.insert(pieces, newPiece(byKey[key], orderOf[key]))
	end
	table.sort(pieces, function(a, b)
		return a.Order < b.Order
	end)

	local start = os.clock()
	local stagger = math.clamp(ASSEMBLY_TIME / math.max(#pieces, 1), 0.012, 0.15)
	for index, piece in pieces do
		piece.Start = start + delay + 0.15 + (index - 1) * stagger
	end
	local total = delay + 0.15 + #pieces * stagger + FALL_TIME + SQUASH_TIME
	-- RoomFX and ProductionVisuals hold their tricks meanwhile
	model:SetAttribute("BuildingUntil", start + total * timeScale + 0.1)
	task.delay(delay * timeScale, function()
		if not light then
			Effects.sound(center, Sounds.Cash, 0.4)
		end
		Effects.sound(center, Sounds.Whoosh, 0.25, 0.8)
	end)

	local nextDust, nextSound, nextTwinkle = 0, 0, 0
	local function land(piece: Piece, index: number)
		local now = os.clock()
		local base = piece.Reference.CFrame * piece.BaseLocal
		if piece.Footprint >= 4 and now >= nextDust then
			nextDust = now + 0.05
			local size = math.clamp(math.sqrt(piece.Footprint) / 4, 0.5, 1.6)
			Effects.puff(base + Vector3.new(0, 0.3, 0), DUST, math.clamp(math.floor(piece.Footprint / 4), 3, 10), size)
		end
		if now >= nextSound then
			nextSound = now + 0.07
			local pitch = 0.8 + 0.7 * index / #pieces
			if piece.Footprint >= 9 then
				Effects.sound(base, Sounds.Boing, 0.22, pitch)
			else
				Effects.sound(base, Sounds.Pop, 0.2, pitch + 0.3)
			end
		end
		if now >= nextTwinkle then
			nextTwinkle = now + 0.04
			Effects.sparkle(base + Vector3.new(0, 0.6, 0), GOLD, 3, 8)
		end
	end

	local function finale()
		for _, part in hidden do
			reveal(part)
		end
		if not model.Parent then
			return
		end
		local floor = Vector3.new(center.X, low.Y + 0.3, center.Z)
		local radius = math.max(high.X - low.X, high.Z - low.Z) / 2
		Effects.sparkle(center, GOLD, if light then 16 else 30, 18)
		Effects.ring(floor, GOLD, radius + 4, 0.6)
		Effects.flash(center, GOLD, if light then 2.5 else 4, radius * 2 + 12, 0.9)
		if light then
			Effects.sound(center, Sounds.Coin, 0.3, 1.2)
		else
			Effects.sound(center, Sounds.Jingle, 0.45)
			Effects.confetti(Vector3.new(center.X, high.Y, center.Z), 45)
		end
		if title then
			Effects.popup(Vector3.new(center.X, high.Y + 2, center.Z), title, GOLD, 2.5, 1.8)
		end
	end

	local connection: RBXScriptConnection
	connection = RunService.RenderStepped:Connect(function()
		local now = start + (os.clock() - start) / timeScale
		local busy = false
		for index, piece in pieces do
			if piece.Done then
				continue
			end
			if not piece.Reference.Parent then
				-- it was rebuilt or cleared (another level, a rebirth) mid-drop
				finish(piece)
				continue
			end
			busy = true
			local t = now - piece.Start
			if t < 0 then
				continue
			end
			if not piece.Clones[1].Parent then
				for _, clone in piece.Clones do
					clone.Parent = Effects.Folder
				end
			end
			if t < FALL_TIME then
				local a = t / FALL_TIME
				pose(piece, piece.Height * (1 - a * a), 1 + 0.18 * a) -- falling faster, stretching
			elseif t < FALL_TIME + SQUASH_TIME then
				if not piece.Landed then
					piece.Landed = true
					land(piece, index)
				end
				local u = (t - FALL_TIME) / SQUASH_TIME
				pose(piece, 0, 1 - 0.32 * math.exp(-4 * u) * math.cos(u * 3 * math.pi))
			else
				finish(piece)
			end
		end
		if not busy then
			connection:Disconnect()
			finale()
		end
	end)
end

return DropIn
