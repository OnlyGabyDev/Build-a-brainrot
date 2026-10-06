--[[
	LootBoxes
	Draws the shared loot boxes around the hub (GDD §5) and opens one when your
	character walks into it. The server owns the boxes, checks reach and rolls the
	result; this only draws them, asks to open, and plays the wheel. Boxes of a rarity
	you haven't unlocked show a lock instead, and a bought box (a box drop, Config/Loot
	Drops) shows whose it is and how long until it's anyone's: only its buyer opens it
	till then.

	Every rarity has its own look, arrival and opening (GDD §5): the rarer, the bigger and
	louder. Looks: a gift box with a lid, ribbons and a bow; glowing edges (Rare+); a gold
	box under a halo of lights in a beam of light (Legendary); a crystal box with a
	glowing core and stars orbiting it (Mythic); a rainbow box over a black hole (Godly).
	Arrivals (ARRIVALS, for boxes that turn up while you play; the ones there when you
	join just sit there):
	  * Common: drops out of the sky and bounces.
	  * Uncommon: floats down under a striped parachute, swaying, which collapses on it.
	  * Rare: bursts up out of the ground in a spray of dirt, leaving a mound.
	  * Legendary: a meteor: a fireball streaks down at a slant, trailing fire and smoke,
	    and crashes (a boom, a shake, a scorched crater).
	  * Mythic: summoned: a magic circle lights up, a bolt of lightning strikes it, and the
	    box materializes in a burst of stars.
	  * Godly: rises out of its black hole.
	Opening one bursts in sparkles, confetti, a shockwave and a flash, bigger with the
	rarity.

	Performance: a box storm can put ~150 boxes on the map, so only boxes near the
	camera bob and spin (ANIMATE_RANGE), only Rare+ boxes carry a light, and effects
	far from the camera are skipped (EFFECTS_RANGE).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Effects = require(ReplicatedStorage:WaitForChild("Client"):WaitForChild("Effects"))
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local Format = require(Shared:WaitForChild("Format"))
local Gamepasses = require(Config:WaitForChild("Gamepasses"))
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
local REST_LIFT = 1.5 -- a box's middle over the ground (LootManager's BOX_HEIGHT)
local ANIMATE_RANGE = 220 -- studs from the camera: farther boxes hold still
-- Labels only up close (crowded labels cluttered the screen, the user, 2026-10-06): the
-- nearest few within reach, Rare and up from further (their glow and beam say the rest).
local LABEL = { Nearest = 5, Range = 60, RareRank = 3, RareRange = 140 }
local EFFECTS_RANGE = 260 -- arrival and opening effects farther than this are skipped
local SHAKE_RANGE = 60 -- a crash this close shakes your camera
local SPARKLE_TEXTURE = "rbxasset://textures/particles/sparkles_main.dds"
local SMOKE_TEXTURE = "rbxasset://textures/particles/smoke_main.dds"
local WHITE = Color3.new(1, 1, 1)
local RIBBON_COLOR = Color3.fromRGB(250, 250, 255)
local DUST_COLOR = Color3.fromRGB(235, 225, 210)
local DIRT_COLORS = { Color3.fromRGB(125, 84, 52), Color3.fromRGB(98, 64, 40), Color3.fromRGB(86, 168, 72) }
local FIRE_COLORS = { Color3.fromRGB(255, 240, 150), Color3.fromRGB(255, 160, 40), Color3.fromRGB(235, 70, 30), Color3.fromRGB(70, 60, 60) }
local SCORCH_COLOR = Color3.fromRGB(45, 35, 35)
local BOLT_COLOR = Color3.fromRGB(150, 220, 255)
local VOID_COLOR = Color3.fromRGB(190, 120, 255)
local OWNER_COLOR = Color3.fromRGB(255, 225, 90)

type Box = {
	Id: number,
	Position: Vector3,
	Rarity: string,
	PartType: string,
	Bought: boolean?,
	Owner: number?,
	OwnerName: string?,
	ReservedUntil: number?,
}

-- How a box turns up: `Pose` places it at `a` (0 to 1 through `Duration`): its offset
-- from its resting spot, its turn (nil: `spin`, the usual one, which it should end on
-- so it doesn't snap when it lands) and its scale (nil: 1). `Step`
-- moves the arrival's own parts (`entry.Props`), given where the box is. `Land` hands
-- the props over to whatever happens to them next (fading, collapsing); without it
-- they're removed.
type Arrival = {
	Duration: number,
	Start: ((entry: Entry) -> ())?,
	Pose: (entry: Entry, a: number, spin: CFrame) -> (Vector3, CFrame?, number?),
	Step: ((entry: Entry, a: number, dt: number, pivot: CFrame) -> ())?,
	Land: ((entry: Entry, props: Model?) -> ())?,
}

type Entry = {
	Box: Box,
	Model: Model,
	Label: BillboardGui?,
	OwnerText: TextLabel?,
	Opening: boolean,
	RetryAt: number,
	Born: number?, -- when its arrival started; nil once it has landed
	Arrival: Arrival?,
	Props: Model?, -- the arrival's own parts: a parachute, flying dirt, a fireball...
	State: { [string]: any }, -- the arrival's working values
	Scale: number,
	Stars: { BasePart }, -- Mythic: orbiting stars
	Rainbow: { BasePart }, -- Godly: parts that cycle through the rainbow
	Portal: Model?, -- Godly: the black hole under it
}

local loaded = false -- (boxes there when you join just sit there)

local player = Players.LocalPlayer
local entries: { [number]: Entry } = {}
local openBox = Remotes.Function("OpenBox")

local folder = Instance.new("Folder")
folder.Name = "LootBoxes"
folder.Parent = workspace

-- Seconds left of a bought box's reservation (0: anyone can open it).
local function reservedFor(box: Box): number
	if not box.Owner then
		return 0
	end
	return math.max((box.ReservedUntil or 0) - workspace:GetServerTimeNow(), 0)
end

local function groundOf(box: Box): Vector3
	return box.Position - Vector3.new(0, REST_LIFT, 0)
end

local function makePart(parent: Instance, size: Vector3, offset: Vector3, color: Color3, material: Enum.Material?): Part
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
	part.Parent = parent
	return part
end

local function makeBall(parent: Instance, size: number, offset: Vector3, color: Color3, material: Enum.Material?): Part
	local part = makePart(parent, Vector3.one * size, offset, color, material)
	part.Shape = Enum.PartType.Ball
	return part
end

-- A flat disc lying on the ground, `diameter` across, its middle at `center`.
local function makeDisc(parent: Instance, diameter: number, thickness: number, center: Vector3, color: Color3, material: Enum.Material?): Part
	local part = makePart(parent, Vector3.new(thickness, diameter, diameter), center, color, material)
	part.Shape = Enum.PartType.Cylinder
	part.CFrame = CFrame.new(center) * CFrame.Angles(0, 0, math.pi / 2)
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

local function easeOutBack(t: number): number
	local c = 1.7
	return 1 + (c + 1) * (t - 1) ^ 3 + c * (t - 1) ^ 2
end

-- Fades every part in `holder` out over `seconds` (sinking `sink` studs), then removes it.
local function fadeAway(holder: Instance, seconds: number, sink: number?)
	local parts = {}
	for _, item in holder:GetDescendants() do
		if item:IsA("BasePart") then
			table.insert(parts, { Part = item, From = item.Transparency, CFrame = item.CFrame })
		elseif item:IsA("ParticleEmitter") then
			item.Enabled = false
		elseif item:IsA("Light") then
			item.Enabled = false
		end
	end
	task.spawn(function()
		local started = os.clock()
		while holder.Parent do
			local t = math.min((os.clock() - started) / seconds, 1)
			for _, entry in parts do
				entry.Part.Transparency = entry.From + (1 - entry.From) * t
				if sink then
					entry.Part.CFrame = entry.CFrame - Vector3.new(0, sink * t * t, 0)
				end
			end
			if t >= 1 then
				break
			end
			RunService.Heartbeat:Wait()
		end
		holder:Destroy()
	end)
end

-- Shakes the camera if `at` is close enough to feel it.
local function rumble(at: Vector3, seconds: number, strength: number)
	if Effects.near(at, SHAKE_RANGE) then
		Effects.shake(seconds, strength)
	end
end

-- Dust, a ring and a pop where a box hits the ground (`size` 1: a small one).
local function thud(entry: Entry, size: number, sound: string?)
	local ground = groundOf(entry.Box)
	if not Effects.near(ground, EFFECTS_RANGE) then
		return
	end
	local rarity = Rarities.ById[entry.Box.Rarity]
	Effects.puff(ground, DUST_COLOR, math.floor(6 * size), size)
	Effects.ring(ground + Vector3.new(0, 0.1, 0), rarity.Color, 3 + 2 * size, 0.5)
	Effects.sound(ground, sound or Sounds.Pop, 0.5)
end

-- A jagged bolt of lightning from `from` down to `to`, flickering, then gone.
local function lightning(from: Vector3, to: Vector3)
	local bolt = Instance.new("Model")
	bolt.Name = "Lightning"
	local segments = 9
	local last = from
	for k = 1, segments do
		local point = from:Lerp(to, k / segments)
		if k < segments then
			point += Vector3.new(math.random(-30, 30) / 10, 0, math.random(-30, 30) / 10)
		end
		local length = (point - last).Magnitude + 0.3
		local along = CFrame.lookAt((last + point) / 2, point)
		local core = makePart(bolt, Vector3.new(0.45, 0.45, length), Vector3.zero, WHITE, Enum.Material.Neon)
		core.CFrame = along
		core.CastShadow = false
		local halo = makePart(bolt, Vector3.new(1.4, 1.4, length), Vector3.zero, BOLT_COLOR, Enum.Material.Neon)
		halo.CFrame = along
		halo.Transparency = 0.6
		halo.CastShadow = false
		last = point
	end
	bolt.Parent = folder
	task.spawn(function()
		for flicker = 1, 5 do
			for _, part in bolt:GetChildren() do
				(part :: BasePart).LocalTransparencyModifier = if flicker % 2 == 0 then 0.85 else 0
			end
			task.wait(0.05)
		end
		fadeAway(bolt, 0.2)
	end)
end

-- Arrivals -------------------------------------------------------------------------

-- Common: drops out of the sky under gravity, hits the ground, bounces once.
local DROP_HEIGHT = 28
local DROP_HIT = 0.65 -- of the arrival: when it first hits the ground

local function dropPose(_: Entry, a: number): (Vector3, CFrame?, number?)
	if a < DROP_HIT then
		local t = a / DROP_HIT
		return Vector3.new(0, DROP_HEIGHT * (1 - t * t), 0), nil, nil
	end
	local t = (a - DROP_HIT) / (1 - DROP_HIT)
	return Vector3.new(0, 2.6 * math.sin(t * math.pi), 0), nil, nil
end

-- Uncommon: a parachute, a stepped dome in the rarity's color and white (the game's
-- blocky style), on four lines to the lid's corners.
local CHUTE_HEIGHT = 40

local function buildParachute(entry: Entry): Model
	local rarity = Rarities.ById[entry.Box.Rarity]
	local k = 1 + (rarity.Rank - 1) * 0.12
	local chute = Instance.new("Model")
	chute.Name = "Parachute"
	-- tiers bottom to top: (radius, height of its middle over the box's middle)
	local tiers = { { 4.8, 6.4 }, { 4.1, 6.95 }, { 3.1, 7.45 }, { 1.8, 7.85 } }
	for index, tier in tiers do
		local color = if index % 2 == 1 then rarity.Color else WHITE
		makeDisc(chute, tier[1] * 2 * k, 0.6 * k, Vector3.new(0, tier[2] * k, 0), color)
	end
	makeBall(chute, 0.9 * k, Vector3.new(0, 8.25 * k, 0), WHITE)
	for _, corner in { Vector2.new(1, 1), Vector2.new(1, -1), Vector2.new(-1, 1), Vector2.new(-1, -1) } do
		local rim = Vector3.new(corner.X * 3.2, 6.1, corner.Y * 3.2) * k
		local lid = Vector3.new(corner.X * 1.4, 1.85, corner.Y * 1.4) * k
		local line = makePart(chute, Vector3.new(0.08, 0.08, (rim - lid).Magnitude), Vector3.zero, WHITE)
		line.CFrame = CFrame.lookAt((rim + lid) / 2, rim)
		line.CastShadow = false
	end
	chute.WorldPivot = CFrame.identity
	return chute
end

-- Rare: dirt flying out of the hole it bursts up from.
local function launchDirt(entry: Entry, props: Model)
	local ground = groundOf(entry.Box)
	local chunks = {}
	for k = 1, 12 do
		local size = 0.5 + math.random() * 0.6
		local chunk = makePart(props, Vector3.one * size, ground + Vector3.new(0, 0.5, 0), DIRT_COLORS[k % #DIRT_COLORS + 1], Enum.Material.Ground)
		local angle = math.random() * math.pi * 2
		local push = 7 + math.random() * 7
		table.insert(chunks, {
			Part = chunk,
			Velocity = Vector3.new(math.cos(angle) * push, 16 + math.random() * 10, math.sin(angle) * push),
			Spin = Vector3.new(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5) * 12,
			Size = size,
		})
	end
	entry.State.Chunks = chunks
end

local function stepDirt(entry: Entry, dt: number)
	local chunks = entry.State.Chunks
	if not chunks then
		return
	end
	local floorY = groundOf(entry.Box).Y
	for _, chunk in chunks do
		if chunk.Velocity then
			local part = chunk.Part :: BasePart
			local position = part.Position + chunk.Velocity * dt
			chunk.Velocity -= Vector3.new(0, 55 * dt, 0)
			if position.Y <= floorY + chunk.Size / 2 then
				position = Vector3.new(position.X, floorY + chunk.Size / 2, position.Z)
				chunk.Velocity = nil -- landed
			end
			local spin = chunk.Spin * dt
			part.CFrame = CFrame.new(position) * part.CFrame.Rotation * CFrame.Angles(spin.X, spin.Y, spin.Z)
		end
	end
end

-- Legendary: the meteor's fireball and its trail of fire and smoke.
local TRAIL = 7

local function buildFireball(entry: Entry, props: Model)
	local rarity = Rarities.ById[entry.Box.Rarity]
	local k = 1 + (rarity.Rank - 1) * 0.12
	local fire = Instance.new("Model")
	fire.Name = "Fireball"
	local shell = makeBall(fire, 6.4 * k, Vector3.zero, FIRE_COLORS[2], Enum.Material.Neon)
	shell.Transparency = 0.45
	shell.CastShadow = false
	local core = makeBall(fire, 4.4 * k, Vector3.zero, FIRE_COLORS[1], Enum.Material.Neon)
	core.Transparency = 0.55
	core.CastShadow = false
	local light = Instance.new("PointLight")
	light.Color = FIRE_COLORS[2]
	light.Range = 32
	light.Brightness = 3
	light.Shadows = false
	light.Parent = core
	local sparks = Instance.new("ParticleEmitter")
	sparks.Texture = SPARKLE_TEXTURE
	sparks.Color = ColorSequence.new(FIRE_COLORS[1], FIRE_COLORS[3])
	sparks.LightEmission = 1
	sparks.Size = NumberSequence.new(1.6, 0)
	sparks.Lifetime = NumberRange.new(0.3, 0.6)
	sparks.Speed = NumberRange.new(2, 6)
	sparks.SpreadAngle = Vector2.new(180, 180)
	sparks.Rate = 70
	sparks.Parent = shell
	local smoke = Instance.new("ParticleEmitter")
	smoke.Texture = SMOKE_TEXTURE
	smoke.Color = ColorSequence.new(FIRE_COLORS[4])
	smoke.Size = NumberSequence.new(3, 7)
	smoke.Transparency = NumberSequence.new(0.3, 1)
	smoke.Lifetime = NumberRange.new(0.8, 1.3)
	smoke.Speed = NumberRange.new(1, 3)
	smoke.Rate = 30
	smoke.Parent = shell
	fire.WorldPivot = CFrame.identity
	fire.Parent = props
	entry.State.Fireball = fire
	-- the trail: balls behind it, smaller, fainter and darker the farther back
	local trail = {}
	for index = 1, TRAIL do
		local t = index / TRAIL
		local color = FIRE_COLORS[math.min(1 + math.floor(t * #FIRE_COLORS), #FIRE_COLORS)]
		local puff = makeBall(props, (5.2 - 3.6 * t) * k, Vector3.zero, color, if t < 0.8 then Enum.Material.Neon else nil)
		puff.Transparency = 0.35 + 0.5 * t
		puff.CastShadow = false
		table.insert(trail, puff)
	end
	entry.State.Trail = trail
end

-- A scorched crater with a glowing rim and rocks round it; it cools and fades.
local function crater(ground: Vector3, size: number)
	local pit = Instance.new("Model")
	pit.Name = "Crater"
	-- the rim is a wider disc just under the scorch, so only its edge shows
	makeDisc(pit, 10.4 * size, 0.2, ground + Vector3.new(0, 0.06, 0), FIRE_COLORS[2], Enum.Material.Neon).CastShadow = false
	makeDisc(pit, 9.4 * size, 0.2, ground + Vector3.new(0, 0.12, 0), SCORCH_COLOR, Enum.Material.Slate)
	for k = 1, 7 do
		local angle = k / 7 * math.pi * 2 + math.random() * 0.4
		local rock = makePart(pit, Vector3.new(1.4, 0.9, 1.1) * (0.7 + math.random() * 0.6) * size, Vector3.zero, Color3.fromRGB(80, 70, 70), Enum.Material.Slate)
		rock.CFrame = CFrame.new(ground + Vector3.new(math.cos(angle) * 5.6 * size, 0.35, math.sin(angle) * 5.6 * size)) * CFrame.Angles(math.random(), math.random() * 6, math.random())
	end
	pit.Parent = folder
	task.delay(3, function()
		fadeAway(pit, 1.5)
	end)
end

-- Mythic: a magic circle on the ground, two rings of glowing segments and a star.
local function magicCircle(parent: Instance, center: Vector3, color: Color3): Model
	local circle = Instance.new("Model")
	circle.Name = "MagicCircle"
	for _, ring in { { Radius = 5.4, Count = 28, Width = 0.4 }, { Radius = 3.6, Count = 18, Width = 0.28 } } do
		for k = 1, ring.Count do
			local angle = k / ring.Count * math.pi * 2
			local part = makePart(circle, Vector3.new(ring.Width, 0.12, 2 * math.pi * ring.Radius / ring.Count + 0.06), Vector3.zero, color, Enum.Material.Neon)
			part.CFrame = CFrame.new(center + Vector3.new(math.cos(angle) * ring.Radius, 0, math.sin(angle) * ring.Radius)) * CFrame.Angles(0, -angle, 0)
			part.CastShadow = false
		end
	end
	local light = color:Lerp(WHITE, 0.45)
	for k = 1, 5 do
		local a1, a2 = k / 5 * math.pi * 2, (k + 2) / 5 * math.pi * 2
		local p1 = center + Vector3.new(math.cos(a1) * 3.6, 0.02, math.sin(a1) * 3.6)
		local p2 = center + Vector3.new(math.cos(a2) * 3.6, 0.02, math.sin(a2) * 3.6)
		local line = makePart(circle, Vector3.new(0.22, 0.12, (p2 - p1).Magnitude), Vector3.zero, light, Enum.Material.Neon)
		line.CFrame = CFrame.lookAt((p1 + p2) / 2, p2)
		line.CastShadow = false
	end
	circle.WorldPivot = CFrame.new(center)
	circle.Parent = parent
	return circle
end

local MYTHIC_STRIKE = 0.5 -- of the arrival: the lightning strikes and it appears

local ARRIVALS: { [string]: Arrival } = {
	Common = {
		Duration = 1.1,
		Start = function(entry)
			Effects.sound(entry.Box.Position + Vector3.new(0, 12, 0), Sounds.Whoosh, 0.3, 1.2)
		end,
		Pose = dropPose,
		Step = function(entry, a)
			if a >= DROP_HIT and not entry.State.Hit then
				entry.State.Hit = true
				thud(entry, 1)
			end
		end,
	},

	Uncommon = {
		Duration = 3,
		Start = function(entry)
			local props = Instance.new("Model")
			props.Name = "Arrival"
			buildParachute(entry).Parent = props
			props.WorldPivot = CFrame.identity
			props.Parent = folder
			entry.Props = props
			Effects.sound(entry.Box.Position + Vector3.new(0, 15, 0), Sounds.Whoosh, 0.25, 0.7)
		end,
		Pose = function(_, a, spin)
			-- down at a steady pace, swaying less and less, easing in at the end
			local height = CHUTE_HEIGHT * (1 - a) ^ 1.15
			local sway = (1 - a) * math.sin(a * math.pi * 4)
			local drift = Vector3.new(sway * 2.4, height, math.cos(a * math.pi * 3) * (1 - a) * 1.6)
			return drift, CFrame.Angles(sway * 0.18, 0, -sway * 0.25) * spin, nil
		end,
		Step = function(entry, _, _, pivot)
			if entry.Props then
				entry.Props:PivotTo(pivot)
			end
		end,
		Land = function(entry, props)
			thud(entry, 1.2, Sounds.Boing)
			if props then
				fadeAway(props, 0.8, 4) -- the canopy sinks onto the box and fades
			end
		end,
	},

	Rare = {
		Duration = 1.5,
		Start = function(entry)
			local ground = groundOf(entry.Box)
			local props = Instance.new("Model")
			props.Name = "Arrival"
			-- the mound it pushes up: a dirt disc ringed with clods
			makeDisc(props, 6.6, 0.5, ground + Vector3.new(0, 0.05, 0), DIRT_COLORS[1], Enum.Material.Ground)
			for k = 1, 8 do
				local angle = k / 8 * math.pi * 2
				makeBall(props, 1.2 + (k % 3) * 0.3, ground + Vector3.new(math.cos(angle) * 3.3, 0.2, math.sin(angle) * 3.3), DIRT_COLORS[k % 2 + 1], Enum.Material.Ground)
			end
			props.Parent = folder
			entry.Props = props
			if Effects.near(ground, EFFECTS_RANGE) then
				Effects.puff(ground, DIRT_COLORS[1], 10, 1.4)
				Effects.sound(ground, Sounds.Clunk, 0.5, 0.55)
			end
			rumble(ground, 0.35, 0.25)
		end,
		Pose = function(_, a)
			-- up out of the ground (it starts buried), overshooting a little; it shakes
			-- as it pushes through
			local rise = easeOutBack(math.min(a / 0.8, 1))
			local jitter = if a < 0.35 then math.sin(a * 140) * 0.25 * (1 - a / 0.35) else 0
			return Vector3.new(jitter, -5.5 * (1 - rise), 0), nil, nil
		end,
		Step = function(entry, a, dt)
			if a >= 0.18 and not entry.State.Burst and entry.Props then
				entry.State.Burst = true
				launchDirt(entry, entry.Props)
				local ground = groundOf(entry.Box)
				if Effects.near(ground, EFFECTS_RANGE) then
					Effects.puff(ground, DIRT_COLORS[2], 14, 1.8)
					Effects.sound(ground, Sounds.Stamp, 0.55, 0.8)
				end
			end
			stepDirt(entry, dt)
		end,
		Land = function(entry, props)
			local rarity = Rarities.ById[entry.Box.Rarity]
			local ground = groundOf(entry.Box)
			if Effects.near(ground, EFFECTS_RANGE) then
				Effects.ring(ground + Vector3.new(0, 0.3, 0), rarity.Color, 7, 0.6)
				Effects.sparkle(entry.Box.Position, rarity.Color, 25)
				Effects.sound(ground, Sounds.Pop, 0.5)
			end
			if props then
				task.delay(1.4, function()
					fadeAway(props, 1, 0.6)
				end)
			end
		end,
	},

	Legendary = {
		Duration = 1.3,
		Start = function(entry)
			local props = Instance.new("Model")
			props.Name = "Arrival"
			props.Parent = folder
			entry.Props = props
			buildFireball(entry, props)
			local angle = math.random() * math.pi * 2
			entry.State.From = Vector3.new(math.cos(angle) * 75, 120, math.sin(angle) * 75)
			Effects.sound(entry.Box.Position, Sounds.Whoosh, 0.6, 0.55)
		end,
		Pose = function(entry, a, spin)
			-- a straight line from high up at a slant, faster and faster, tumbling
			local from = entry.State.From :: Vector3
			local tumble = 1 - a
			return from * (1 - a * a), spin * CFrame.Angles(tumble * 14, tumble * 9, tumble * 5), nil
		end,
		Step = function(entry, a, _, pivot)
			local fire = entry.State.Fireball :: Model?
			if fire then
				fire:PivotTo(CFrame.new(pivot.Position))
			end
			local from = entry.State.From :: Vector3
			for index, puff in entry.State.Trail do
				local t = math.max(a - index * 0.045, 0)
				puff.CFrame = CFrame.new(entry.Box.Position + from * (1 - t * t))
			end
		end,
		Land = function(entry, props)
			if props then
				props:Destroy()
			end
			local ground = groundOf(entry.Box)
			if not Effects.near(ground, EFFECTS_RANGE) then
				return
			end
			Effects.flash(ground + Vector3.new(0, 3, 0), FIRE_COLORS[2], 6, 50, 0.8)
			Effects.ring(ground + Vector3.new(0, 0.3, 0), FIRE_COLORS[2], 15, 0.7)
			Effects.ring(ground + Vector3.new(0, 0.4, 0), Rarities.ById[entry.Box.Rarity].Color, 9, 0.5)
			Effects.puff(ground, FIRE_COLORS[4], 22, 2.2)
			Effects.sparkle(ground + Vector3.new(0, 2, 0), FIRE_COLORS[2], 40, 28)
			Effects.sound(ground, Sounds.Boom, 0.7, 1.25)
			Effects.sound(ground, Sounds.Clunk, 0.6, 0.7)
			rumble(ground, 0.5, 0.7)
			crater(ground, 1)
		end,
	},

	Mythic = {
		Duration = 2.2,
		Start = function(entry)
			local rarity = Rarities.ById[entry.Box.Rarity]
			local props = Instance.new("Model")
			props.Name = "Arrival"
			props.Parent = folder
			entry.Props = props
			local circle = magicCircle(props, groundOf(entry.Box) + Vector3.new(0, 0.12, 0), rarity.Color)
			for _, part in circle:GetChildren() do
				(part :: BasePart).Transparency = 1
			end
			entry.State.Circle = circle
			Effects.sound(entry.Box.Position, Sounds.Reveal, 0.4, 0.6)
		end,
		Pose = function(_, a, spin)
			if a < MYTHIC_STRIKE then
				return Vector3.new(0, -20, 0), nil, 0.05 -- not here yet (hidden underground)
			end
			-- it materializes: grows in with a spin that slows down to its usual one
			local t = (a - MYTHIC_STRIKE) / (1 - MYTHIC_STRIKE)
			return Vector3.new(0, (1 - t) * 2, 0), spin * CFrame.Angles(0, (1 - t) ^ 2 * 12, 0), math.max(easeOutBack(t), 0.05)
		end,
		Step = function(entry, a)
			local circle = entry.State.Circle :: Model?
			local ground = groundOf(entry.Box)
			if circle then
				circle:PivotTo(CFrame.new(ground + Vector3.new(0, 0.12, 0)) * CFrame.Angles(0, a * 5, 0))
				if a < 0.3 then
					for _, part in circle:GetChildren() do
						(part :: BasePart).Transparency = 1 - a / 0.3
					end
				elseif not entry.State.Lit then
					entry.State.Lit = true
					for _, part in circle:GetChildren() do
						(part :: BasePart).Transparency = 0
					end
				end
			end
			if a >= MYTHIC_STRIKE and not entry.State.Struck then
				entry.State.Struck = true
				if Effects.near(ground, EFFECTS_RANGE) then
					lightning(ground + Vector3.new(math.random(-6, 6), 90, math.random(-6, 6)), ground)
					Effects.flash(ground + Vector3.new(0, 4, 0), BOLT_COLOR, 9, 70, 0.6)
					Effects.sound(ground, Sounds.Boom, 0.6, 1.7)
					Effects.sparkle(entry.Box.Position, Rarities.ById[entry.Box.Rarity].Color, 30, 20)
					rumble(ground, 0.3, 0.4)
				end
			end
		end,
		Land = function(entry, props)
			local rarity = Rarities.ById[entry.Box.Rarity]
			local ground = groundOf(entry.Box)
			if Effects.near(ground, EFFECTS_RANGE) then
				Effects.ring(ground + Vector3.new(0, 0.3, 0), rarity.Color, 12, 0.7)
				Effects.sparkle(entry.Box.Position + Vector3.new(0, 2, 0), WHITE, 30)
				Effects.sound(ground, Sounds.RevealBig, 0.45, 1.2)
			end
			if props then
				fadeAway(props, 0.9)
			end
		end,
	},

	Godly = {
		Duration = 1.8,
		Start = function(entry)
			Effects.sound(entry.Box.Position, Sounds.RevealBig, 0.6, 0.8) -- the black hole opens
			Effects.flash(entry.Box.Position, VOID_COLOR, 6, 40, 1.2)
		end,
		Pose = function(_, a)
			return Vector3.new(0, -7 * (1 - a) * (1 - a), 0), nil, nil -- up out of the hole
		end,
		Step = function(entry, a)
			if entry.Portal then
				entry.Portal:ScaleTo(math.max(math.min(a * 2.5, 1), 0.05))
			end
		end,
		Land = function(entry)
			local ground = groundOf(entry.Box)
			if Effects.near(ground, EFFECTS_RANGE) then
				Effects.flash(ground, VOID_COLOR, 4, 30, 0.6)
				Effects.ring(ground + Vector3.new(0, 0.3, 0), VOID_COLOR, 14, 0.6)
				Effects.sound(ground, Sounds.Clunk, 0.5, 0.7)
			end
		end,
	},
}

-- Building ---------------------------------------------------------------------------

local function refreshOwner(entry: Entry)
	local text = entry.OwnerText
	if not text then
		return
	end
	local left = reservedFor(entry.Box)
	text.Visible = left > 0
	if left > 0 then
		local clock = string.format("%d:%02d", math.floor(left / 60), math.floor(left % 60))
		text.Text = if entry.Box.Owner == player.UserId then `🎁 YOURS · {clock}` else `🔒 {string.upper(entry.Box.OwnerName or "SOMEONE")}'S · {clock}`
	end
end

-- Its part type and rarity over it, and whose it is while it's someone's bought box. Hidden while it's arriving.
local function buildLabel(entry: Entry, base: BasePart, k: number)
	local box = entry.Box
	local rarity = Rarities.ById[box.Rarity]
	local label = Instance.new("BillboardGui")
	label.Size = UDim2.fromScale(6, 3.3)
	label.StudsOffset = Vector3.new(0, 3.6 * k + 1, 0)
	label.MaxDistance = 150 + rarity.Rank * 30
	label.LightInfluence = 0
	label.Enabled = entry.Born == nil
	label.Parent = base
	Kit.text({ Text = string.upper(box.PartType), Size = UDim2.fromScale(1, 0.4), Parent = label })
	Kit.text({
		Text = string.upper(rarity.Id),
		TextColor3 = rarity.Color,
		Position = UDim2.fromScale(0, 0.4),
		Size = UDim2.fromScale(1, 0.33),
		Parent = label,
	})
	entry.OwnerText = Kit.text({
		Text = "",
		TextColor3 = OWNER_COLOR,
		Position = UDim2.fromScale(0, 0.73),
		Size = UDim2.fromScale(1, 0.27),
		Visible = false,
		Parent = label,
	})
	entry.Label = label
	refreshOwner(entry)
end

-- A gift box in the rarity's color: a lid, ribbons and a bow, a glow and sparkles, its
-- label over it; the rarer, the bigger and the more it has (see the top).
local function buildBox(entry: Entry)
	local box = entry.Box
	local rarity = Rarities.ById[box.Rarity]
	local rank = rarity.Rank
	local k = 1 + (rank - 1) * 0.12 -- its size
	local godly = rarity.Id == "Godly"
	local model = Instance.new("Model")
	model.Name = `LootBox{box.Id}`
	local light = rarity.Color:Lerp(WHITE, 0.35)

	local material = if rank == 4 then Enum.Material.Metal elseif rank == 5 then Enum.Material.Glass else nil
	local base = makePart(model, Vector3.new(3, 2.4, 3) * k, Vector3.zero, rarity.Color, material)
	local lid = makePart(model, Vector3.new(3.3, 0.7, 3.3) * k, Vector3.new(0, 1.5 * k, 0), light, if rank == 4 then Enum.Material.Metal else nil)
	-- a plain white ribbon and a small bow: the rarity's color is what you see from afar
	-- (a neon gold ribbon outshone it, the user, 2026-10-06), lit by a neon band of it
	-- under the lid
	makePart(model, Vector3.new(3.1, 3.2, 0.35) * k, Vector3.new(0, 0.2 * k, 0), RIBBON_COLOR)
	makePart(model, Vector3.new(0.35, 3.2, 3.1) * k, Vector3.new(0, 0.2 * k, 0), RIBBON_COLOR)
	for _, side in { -1, 1 } do
		local loop = makePart(model, Vector3.new(1, 0.65, 0.35) * k, Vector3.new(side * 0.5 * k, 2.1 * k, 0), RIBBON_COLOR)
		loop.CFrame *= CFrame.Angles(0, 0, side * math.rad(-30))
	end
	makeBall(model, 0.5 * k, Vector3.new(0, 2 * k, 0), RIBBON_COLOR)
	local band = makePart(model, Vector3.new(3.2, 0.3, 3.2) * k, Vector3.new(0, 1 * k, 0), rarity.Color, Enum.Material.Neon)
	band.CastShadow = false
	model.PrimaryPart = base
	model.WorldPivot = CFrame.identity
	if godly then
		table.insert(entry.Rainbow, base)
		table.insert(entry.Rainbow, lid)
		table.insert(entry.Rainbow, band)
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
			makeBall(model, 0.45 * k, Vector3.new(math.cos(a) * 1.8 * k, 3.3 * k, math.sin(a) * 1.8 * k), light, Enum.Material.Neon).CastShadow = false
		end
	end
	-- Mythic and up: a glowing core in the crystal, stars orbiting it
	if rank >= 5 then
		base.Transparency = 0.35
		makePart(model, Vector3.new(1.8, 1.4, 1.8) * k, Vector3.zero, light, Enum.Material.Neon)
		for _ = 1, 4 do
			local star = makeBall(model, 0.6 * k, Vector3.zero, WHITE, Enum.Material.Neon)
			star.CastShadow = false
			table.insert(entry.Stars, star)
		end
	end

	-- a light only from Rare up (a storm of lit commons costs too much), sparkles on all
	if rank >= 3 then
		local glow = Instance.new("PointLight")
		glow.Color = rarity.Color
		glow.Range = 10 + rank * 3
		glow.Brightness = 1 + rank * 0.4
		glow.Shadows = false
		glow.Parent = base
	end
	emitter(base, if godly then RAINBOW else ColorSequence.new(rarity.Color), 1 + rank * rank, 0.4 + rank * 0.1, 1 + rank * 0.4)

	buildLabel(entry, base, k)
	model.Parent = folder
	entry.Model = model
	entry.Scale = 1

	-- Godly: a black hole under it, its swirl turning
	if godly and not entry.Portal then
		local portal = Instance.new("Model")
		portal.Name = `BlackHole{box.Id}`
		local disc = makeDisc(portal, 9, 0.3, Vector3.zero, Color3.fromRGB(15, 5, 30))
		for index = 0, 15 do
			local a = index / 16 * math.pi * 2
			local bit = makePart(portal, Vector3.new(1.6, 0.25, 0.6), Vector3.new(math.cos(a) * 4.7, 0.1, math.sin(a) * 4.7), if index % 2 == 0 then Color3.fromRGB(170, 60, 255) else Color3.fromRGB(255, 120, 230), Enum.Material.Neon)
			bit.CFrame = CFrame.new(bit.Position) * CFrame.Angles(0, -a + 0.6, 0)
		end
		portal.WorldPivot = CFrame.identity
		portal.Parent = folder
		emitter(disc, ColorSequence.new(VOID_COLOR), 18, 0.6, 3)
		entry.Portal = portal
	end
end

-- Arriving and leaving ----------------------------------------------------------------

local function addBox(box: Box)
	if entries[box.Id] then
		return
	end
	-- it arrives only if it turned up while you're here and in sight (a box storm across
	-- the map isn't worth animating)
	local arriving = loaded and Effects.near(box.Position, EFFECTS_RANGE)
	local entry: Entry = {
		Box = box,
		Model = nil :: any,
		Opening = false,
		RetryAt = 0,
		Born = if arriving then os.clock() else nil,
		State = {},
		Scale = 1,
		Stars = {},
		Rainbow = {},
	}
	if arriving then
		entry.Arrival = ARRIVALS[box.Rarity] or ARRIVALS.Common
	end
	buildBox(entry)
	entries[box.Id] = entry
	local arrival = entry.Arrival
	if arrival and arrival.Start then
		arrival.Start(entry)
	end
end

-- Which landed boxes show their labels: the nearest few to the camera within reach
-- (LABEL), further for Rare and up.
local function refreshLabels()
	local camera = workspace.CurrentCamera
	local eye = if camera then camera.CFrame.Position else Vector3.zero
	local near: { { Entry: Entry, Distance: number } } = {}
	for _, entry in entries do
		local label = entry.Label
		if label and entry.Born == nil then
			local distance = (entry.Box.Position - eye).Magnitude
			local reach = if Rarities.ById[entry.Box.Rarity].Rank >= LABEL.RareRank then LABEL.RareRange else LABEL.Range
			label.Enabled = false
			if distance <= reach then
				table.insert(near, { Entry = entry, Distance = distance })
			end
		end
	end
	table.sort(near, function(a, b)
		return a.Distance < b.Distance
	end)
	for index = 1, math.min(#near, LABEL.Nearest) do
		(near[index].Entry.Label :: BillboardGui).Enabled = true
	end
end

-- It has arrived: back to its full size, its label on, and its props handed over.
local function land(entry: Entry)
	local arrival = entry.Arrival :: Arrival
	entry.Arrival = nil
	entry.Born = nil
	if entry.Scale ~= 1 then
		entry.Model:ScaleTo(1)
		entry.Scale = 1
	end
	refreshLabels()
	local props = entry.Props
	entry.Props = nil
	if arrival.Land then
		arrival.Land(entry, props)
	elseif props then
		props:Destroy()
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
	local rank = rarity.Rank
	if Effects.near(at, EFFECTS_RANGE) then
		Effects.sparkle(at, rarity.Color, 35, 19)
		Effects.sound(at, Sounds.Pop, 0.6)
		Effects.confetti(at, 8 + rank * 8)
		Effects.ring(at - Vector3.new(0, 1, 0), rarity.Color, 4 + rank * 2, 0.6)
		Effects.flash(at, rarity.Color, 2 + rank, 14 + rank * 4, 0.5)
		if rank >= 4 then
			Effects.sparkle(at + Vector3.new(0, 3, 0), Color3.fromRGB(255, 235, 150), 10 + rank * 5)
			Effects.sound(at, Sounds.Jingle, 0.5, 1)
		end
	end
	entry.Model:Destroy()
	if entry.Props then
		entry.Props:Destroy()
		entry.Props = nil
	end
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
	-- (someone grabbing a bought box isn't news: it would flood a box storm with toasts)
	if opener and opener ~= player and not entry.Box.Bought and rarity.Rank >= LootConfig.AnnounceRank then
		Kit.toast(`{opener.DisplayName} grabbed the {string.upper(rarity.Id)} box!`, rarity.Color)
	end
end

-- Someone's bought box became anyone's (its buyer left).
local function updateBox(box: Box)
	local entry = entries[box.Id]
	if entry then
		entry.Box = box
		refreshOwner(entry)
	end
end

local function canOpen(entry: Entry): boolean
	local box = entry.Box
	if entry.Opening or entry.Born then
		return false
	end
	return box.Owner == nil or box.Owner == player.UserId or reservedFor(box) <= 0
end

local function tryOpen(entry: Entry)
	entry.Opening = true
	task.spawn(function()
		local ok, result = pcall(openBox.InvokeServer, openBox, entry.Box.Id)
		if ok and result then
			-- the Coins it paid by its rarity spray out of it toward you
			local coins = result.Coins
			if typeof(coins) == "number" and coins > 0 then
				local at = entry.Box.Position + Vector3.new(0, 3, 0)
				local rarity = Rarities.ById[entry.Box.Rarity]
				Effects.popup(at + Vector3.new(0, 2, 0), `+{Format.Number(coins)}`, Color3.fromRGB(255, 215, 60), 2 + (if rarity then rarity.Rank * 0.3 else 0), 1.4)
				Effects.sound(at, Sounds.Coins, 0.35, 1)
				local character = player.Character
				local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
				if root then
					Effects.coins(at, root.Position, 4 + 2 * (if rarity then rarity.Rank else 1))
				end
			end
			Loot.Show(result)
		else
			entry.Opening = false
			entry.RetryAt = os.clock() + RETRY_DELAY
		end
	end)
end

-- A rare box spawned on the map: a banner for everyone, bigger the rarer it is, with
-- how far away it landed.
local function announce(box: any)
	local rarity = Rarities.ById[box.Rarity]
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local where = if root then `📍 {math.floor((box.Position - root.Position).Magnitude)} studs away` else "📍 somewhere on the map"
	local article = if string.find(box.PartType, "^[AEIOU]") then "An" else "A" -- (An ARMS box)
	Kit.banner("🎁", `{string.upper(rarity.Id)} BOX!`, `{article} {string.upper(box.PartType)} box spawned · {where} · go grab it!`, rarity.Color, rarity.Rank - LootConfig.AnnounceRank)
end

Remotes.Event("LootBoxes").OnClientEvent:Connect(function(action: string, payload: any, opener: Player?)
	if action == "Add" then
		addBox(payload)
	elseif action == "Remove" then
		removeBox(payload, opener)
	elseif action == "Update" then
		updateBox(payload)
	elseif action == "Announce" then
		announce(payload)
	elseif action == "Drop" then
		local count = payload.Count :: number
		local text = if count >= 100
			then `🌪️ {payload.Name} started a BOX STORM! 🌪️`
			elseif count == 1 then `🎁 {payload.Name} dropped a loot box!`
			else `🎁 {payload.Name} dropped {count} loot boxes!`
		Kit.toast(text, OWNER_COLOR)
		Effects.sound2D(Sounds.Jingle, 0.4)
	end
end)

-- The reservation clocks on bought boxes tick (and which labels show is checked) twice
-- a second.
task.spawn(function()
	while true do
		for _, entry in entries do
			if entry.Box.Owner then
				refreshOwner(entry)
			end
		end
		refreshLabels()
		task.wait(0.5)
	end
end)

-- Arrive, bob, spin, and open when the character walks in.
RunService.RenderStepped:Connect(function(dt)
	local now = os.clock()
	local camera = workspace.CurrentCamera
	local eye = if camera then camera.CFrame.Position else Vector3.zero
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	for id, entry in entries do
		local box = entry.Box
		local arrival = entry.Arrival
		local born = entry.Born
		if not (arrival and born) and (eye - box.Position).Magnitude > ANIMATE_RANGE then
			continue -- far away and settled: it holds still (and is out of reach)
		end
		local rarity = Rarities.ById[box.Rarity]
		local spin = CFrame.Angles(0, now * (0.8 + rarity.Rank * 0.15) + id, 0)
		local offset, turn, scale = Vector3.zero, nil :: CFrame?, 1
		local a = 1
		if arrival and born then
			a = math.clamp((now - born) / arrival.Duration, 0, 1)
			local poseOffset, poseTurn, poseScale = arrival.Pose(entry, a, spin)
			offset, turn, scale = poseOffset, poseTurn, poseScale or 1
		else
			offset = Vector3.new(0, math.sin(now * 2 + id) * BOB_HEIGHT, 0)
		end
		local pivot = CFrame.new(box.Position + offset) * (turn or spin)
		if scale ~= entry.Scale then
			entry.Model:ScaleTo(math.max(scale, 0.05))
			entry.Scale = scale
		end
		entry.Model:PivotTo(pivot)
		if arrival and born then
			if arrival.Step then
				arrival.Step(entry, a, dt, pivot)
			end
			if a >= 1 then
				land(entry)
			end
		end
		-- Mythic stars orbit; Godly cycles through the rainbow over its black hole
		for index, star in entry.Stars do
			local angle = now * 2 + index * math.pi / 2
			star.CFrame = CFrame.new(box.Position + offset + Vector3.new(math.cos(angle) * 3.6, 1 + math.sin(angle * 1.5) * 1.2, math.sin(angle) * 3.6))
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

		if root and now >= entry.RetryAt and canOpen(entry) and (root.Position - box.Position).Magnitude <= OPEN_DISTANCE then
			tryOpen(entry)
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

-- Box Radar (the gamepass) ----------------------------------------------------------
-- An arrow floats over your head pointing at the nearest box of RadarRank or rarer that
-- you could open (your rebirths allow its rarity, and it isn't held for someone else),
-- in the box's color, with its rarity and distance under it.
local Radar = { Rank = Gamepasses.BoxRadar.RadarRank or 3, Plate = nil :: Part?, Glyph = nil :: TextLabel?, Tag = nil :: TextLabel? }

function Radar.build(): Part
	local plate = Instance.new("Part")
	plate.Name = "BoxRadar"
	plate.Size = Vector3.new(4, 0.05, 4)
	plate.Transparency = 1
	plate.Anchored, plate.CanCollide, plate.CanQuery, plate.CanTouch, plate.CastShadow = true, false, false, false, false
	local surface = Instance.new("SurfaceGui")
	surface.Face = Enum.NormalId.Top
	surface.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	surface.PixelsPerStud = 50
	surface.LightInfluence = 0
	surface.AlwaysOnTop = true
	surface.Parent = plate
	local glyph = Instance.new("TextLabel")
	glyph.Size = UDim2.fromScale(1, 1)
	glyph.BackgroundTransparency = 1
	glyph.Font = Enum.Font.FredokaOne
	glyph.TextScaled = true
	glyph.Text = "➤"
	glyph.Parent = surface
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 4
	stroke.Parent = glyph
	local board = Instance.new("BillboardGui")
	board.Size = UDim2.fromOffset(220, 34)
	board.StudsOffset = Vector3.new(0, 1.4, 0)
	board.AlwaysOnTop = true
	board.LightInfluence = 0
	board.Parent = plate
	local tag = Instance.new("TextLabel")
	tag.Size = UDim2.fromScale(1, 1)
	tag.BackgroundTransparency = 1
	tag.Font = Enum.Font.FredokaOne
	tag.TextScaled = true
	tag.Parent = board
	local tagStroke = Instance.new("UIStroke")
	tagStroke.Thickness = 2.5
	tagStroke.Parent = tag
	Radar.Plate, Radar.Glyph, Radar.Tag = plate, glyph, tag
	return plate
end

RunService.RenderStepped:Connect(function()
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local target: Entry? = nil
	local best = math.huge
	if player:GetAttribute("Pass_BoxRadar") and root and root:IsA("BasePart") then
		local now = workspace:GetServerTimeNow()
		for _, entry in entries do
			local box = entry.Box
			local rarity = Rarities.ById[box.Rarity]
			local heldForOther = box.Owner ~= nil and box.Owner ~= player.UserId and (box.ReservedUntil or 0) > now
			if rarity and rarity.Rank >= Radar.Rank and not entry.Opening and not heldForOther then
				local distance = (box.Position - root.Position).Magnitude
				if distance < best then
					best, target = distance, entry
				end
			end
		end
	end
	if not (target and root and root:IsA("BasePart")) then
		if Radar.Plate then
			Radar.Plate.Parent = nil
		end
		return
	end
	local plate = Radar.Plate or Radar.build()
	local rarity = Rarities.ById[target.Box.Rarity]
	local flat = Vector3.new(target.Box.Position.X - root.Position.X, 0, target.Box.Position.Z - root.Position.Z)
	local at = root.Position + Vector3.new(0, 5 + math.sin(os.clock() * 3) * 0.25, 0)
	-- the glyph points along the plate's +X: turn the plate so +X faces the box
	if flat.Magnitude > 0.1 then
		plate.CFrame = CFrame.lookAt(at, at + flat.Unit) * CFrame.Angles(0, math.pi / 2, 0)
	else
		plate.CFrame = CFrame.new(at)
	end
	;(Radar.Glyph :: TextLabel).TextColor3 = rarity.Color
	local tag = Radar.Tag :: TextLabel
	tag.TextColor3 = rarity.Color:Lerp(Color3.new(1, 1, 1), 0.3)
	tag.Text = `📡 {string.upper(rarity.Id)} · {math.floor(best)}m`
	plate.Parent = workspace.CurrentCamera
end)
