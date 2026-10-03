--[[
	The lab: runs the game's server builders without Studio and writes down every part
	they make, so geometry can be checked from a terminal (part counts, parts sharing a
	face that would z-fight, things poking through ceilings, overlaps): see analyze.py.

	  lune run tools/lab/lab.luau [scenario] [out.json] [sync folder]

	Scenarios:
	  plots  (default) the 6 factories, and the first one claimed by a lab player who
	         owns everything (every room, line, upgrade and floor; Rebirth 99)
	  world  plots, then the hub (MapBuilder; the ground is flat, there's no terrain)
	  mixes  every brainrot's build, and every body with each other one's legs, arms, head
	  previews  plots with each line's tracks at level 3, 6 or 9, and the Line menu's
	         previews of their next levels (TycoonManager.BuildTrackPreview) in
	         workspace.Previews

	Lune (https://lune-org.github.io) runs Luau; tools/lab/dom.luau stands in for the
	Instance tree. Services the builders don't draw with (data, money, remotes) are
	stubs (STUBS below). What isn't real: physics, terrain (flat ground at Y = 0),
	raycasts and overlap queries beyond that, Random's numbers (a different generator, so
	jittered decor lands a little differently), and anything clients do.
]]

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")
local task = require("@lune/task")

local Dom = require("./dom")
local Types = require("./types")

local scenario = process.args[1] or "plots"
local outPath = process.args[2] or "lab-parts.json"
local syncRoot = process.args[3] or "sync"

local Enum = roblox.Enum
local Vector3 = Types.Vector3
local Methods = Dom.Methods

-- The DataModel ---------------------------------------------------------------------

local game = Dom.new("DataModel")
game.Name = "Game"

local SERVICE_CLASSES = { Workspace = "Workspace" }
function Methods:GetService(name: string)
	local service = self:FindFirstChild(name)
	if not service then
		service = Dom.new(SERVICE_CLASSES[name] or name, self)
		service.Name = name
	end
	return service
end
Methods.FindService = Methods.GetService

local workspace = game:GetService("Workspace")
local terrain = Dom.new("Terrain", workspace)
terrain.Name = "Terrain"

local terrainCalls = 0
for _, name in { "FillBlock", "FillCylinder", "FillBall", "FillWedge", "ReplaceMaterial", "SetMaterialColor", "Clear", "FillRegion", "WriteVoxels" } do
	Methods[name] = function()
		terrainCalls += 1
	end
end

-- Flat ground at Y = 0: rays cast down hit it, nothing else is ever hit.
function Methods:Raycast(origin, direction)
	if direction.Y < 0 and origin.Y > 0 and origin.Y + direction.Y <= 0 then
		return { Position = Vector3.new(origin.X, 0, origin.Z), Normal = Vector3.yAxis, Material = Enum.Material.Grass, Instance = terrain, Distance = origin.Y }
	end
	return nil
end
function Methods:GetPartBoundsInRadius()
	return {}
end
Methods.GetPartBoundsInBox = Methods.GetPartBoundsInRadius
Methods.GetPartsInPart = Methods.GetPartBoundsInRadius
local started = os.clock()
function Methods:GetServerTimeNow()
	return os.clock() - started
end

-- CollectionService (AddTag/RemoveTag/HasTag take the instance first: see dom.luau)
function Methods:GetTagged(tag: string)
	local list = {}
	for _, item in game:GetDescendants() do
		if item:HasTag(tag) then
			table.insert(list, item)
		end
	end
	return list
end
function Methods:GetInstanceAddedSignal()
	return Dom.Signal.new()
end
Methods.GetInstanceRemovedSignal = Methods.GetInstanceAddedSignal

-- RunService
function Methods:IsStudio()
	return true
end
function Methods:IsServer()
	return true
end
function Methods:IsClient()
	return false
end
function Methods:IsRunning()
	return true
end
function Methods:BindToRenderStep() end
function Methods:UnbindFromRenderStep() end

-- Debris, TweenService, HttpService
function Methods:AddItem() end
function Methods:Create()
	return { Play = function() end, Cancel = function() end, Pause = function() end, Completed = Dom.Signal.new() }
end
function Methods:JSONEncode(value)
	return serde.encode("json", value)
end
function Methods:JSONDecode(text)
	return serde.decode("json", text)
end
local guids = 0
function Methods:GenerateGUID()
	guids += 1
	return `lab-guid-{guids}`
end

-- The lab player: owns everything (see `data`).
local players = game:GetService("Players")
local player = Dom.new("Player", players)
player.Name = "LabPlayer"
player.DisplayName = "Lab"
player.UserId = 1
function Methods:GetPlayers()
	return { player }
end
function Methods:GetPlayerByUserId(userId: number)
	return if userId == player.UserId then player else nil
end
function Methods:GetPlayerFromCharacter()
	return nil
end

-- Scripts ---------------------------------------------------------------------------

-- sync/ mirrored into the tree: folders, and scripts that know their file.
local function mirror(directory: string, parent: any)
	for _, name in fs.readDir(directory) do
		local path = `{directory}/{name}`
		if fs.isDir(path) then
			local node = parent:FindFirstChild(name)
			if not node then
				node = Dom.new("Folder", parent)
				node.Name = name
			end
			mirror(path, node)
		elseif string.sub(name, -5) == ".luau" then
			local className, base = "ModuleScript", string.sub(name, 1, -6)
			if string.sub(base, -7) == ".server" then
				className, base = "Script", string.sub(base, 1, -8)
			elseif string.sub(base, -7) == ".client" then
				className, base = "LocalScript", string.sub(base, 1, -8)
			end
			local script = Dom.new(className, parent)
			script.Name = base
			script:SetAttribute("LabPath", path)
		end
	end
end

for _, name in fs.readDir(syncRoot) do
	if fs.isDir(`{syncRoot}/{name}`) then
		mirror(`{syncRoot}/{name}`, game:GetService(name))
	end
end

-- Stubs: what a builder needs from services the lab doesn't run.
local loadedCallbacks = {}
local everything: { [string]: boolean } = {}
local data = {
	Coins = 1e30,
	Gems = 1e9,
	RebirthPoints = 0,
	Rebirths = 99,
	Rolls = 0,
	Inventory = { Parts = {}, Completed = {} },
	Tycoon = { Purchased = everything, Lines = {} },
	Upgrades = {},
	Boosts = {},
	DailyWheel = { FreeSpins = {}, Spins = 0 },
	Receipts = {},
	Stats = { TotalCoinsEarned = 0, FirstJoin = 0, LastJoin = 0, RobuxSpent = 0, Playtime = 0 },
}

local function absorbing(name: string, known: { [string]: any })
	return setmetatable(known, {
		__index = function(_, key)
			return function()
				return nil
			end
		end,
		__tostring = function()
			return name
		end,
	})
end

local remote = function()
	return absorbing("Remote", { OnServerEvent = Dom.Signal.new(), OnServerInvoke = false })
end

local STUBS: { [string]: any } = {
	[`{syncRoot}/ServerScriptService/Services/DataManager.luau`] = absorbing("DataManager", {
		OnPlayerLoaded = function(callback)
			table.insert(loadedCallbacks, callback)
		end,
		GetData = function()
			return data
		end,
		IsLoaded = function()
			return true
		end,
		PurchaseItem = function(_, itemId)
			everything[itemId] = true
			return true
		end,
		GetCurrency = function()
			return 1e30
		end,
		AddCurrency = function()
			return true
		end,
	}),
	[`{syncRoot}/ServerScriptService/Services/MonetizationManager.luau`] = absorbing("MonetizationManager", {
		HasPerk = function()
			return false
		end,
		OwnsPass = function()
			return false
		end,
		IncomeMultiplier = function()
			return 1
		end,
		Luck = function()
			return 0
		end,
	}),
	[`{syncRoot}/ReplicatedStorage/Shared/Remotes.luau`] = absorbing("Remotes", {
		Event = remote,
		Function = remote,
	}),
}

-- Globals the game's code expects
local LabRandom = {}
LabRandom.__index = LabRandom
function LabRandom.new(seed: number?)
	return setmetatable({ State = math.floor((seed or os.clock() * 1e6) % 4294967296) }, LabRandom)
end
function LabRandom:Next(): number
	self.State = (1664525 * self.State + 1013904223) % 4294967296
	return self.State / 4294967296
end
function LabRandom:NextNumber(low: number?, high: number?): number
	local a, b = low or 0, high or 1
	return a + (b - a) * self:Next()
end
function LabRandom:NextInteger(low: number, high: number): number
	return low + math.floor(self:Next() * (high - low + 1))
end
function LabRandom:NextUnitVector()
	local z = self:NextNumber(-1, 1)
	local angle = self:NextNumber(0, math.pi * 2)
	local r = math.sqrt(1 - z * z)
	return Vector3.new(math.cos(angle) * r, math.sin(angle) * r, z)
end
function LabRandom:Shuffle(list)
	for index = #list, 2, -1 do
		local other = self:NextInteger(1, index)
		list[index], list[other] = list[other], list[index]
	end
end
function LabRandom:Clone()
	return setmetatable({ State = self.State }, LabRandom)
end

local function labTypeof(value: any): string
	if Dom.isInstance(value) then
		return "Instance"
	end
	return Types.typeof(value)
end

local plain = function(kind: string)
	return {
		new = function(...)
			return { Kind = kind, ... }
		end,
	}
end

local modules = {}
local LOADING = {}

local labRequire

local function environment(script: any)
	return {
		script = script,
		require = labRequire,
		game = game,
		workspace = workspace,
		Workspace = workspace,
		Instance = { new = Dom.new },
		typeof = labTypeof,
		Random = LabRandom,
		CFrame = Types.CFrame,
		Vector3 = Types.Vector3,
		Vector2 = roblox.Vector2,
		Vector3int16 = roblox.Vector3int16,
		Vector2int16 = roblox.Vector2int16,
		Color3 = roblox.Color3,
		BrickColor = roblox.BrickColor,
		UDim = roblox.UDim,
		UDim2 = roblox.UDim2,
		Rect = roblox.Rect,
		Enum = roblox.Enum,
		Font = roblox.Font,
		Faces = roblox.Faces,
		Axes = roblox.Axes,
		Ray = roblox.Ray,
		Region3 = roblox.Region3,
		PhysicalProperties = roblox.PhysicalProperties,
		NumberRange = roblox.NumberRange,
		NumberSequence = roblox.NumberSequence,
		NumberSequenceKeypoint = roblox.NumberSequenceKeypoint,
		ColorSequence = roblox.ColorSequence,
		ColorSequenceKeypoint = roblox.ColorSequenceKeypoint,
		TweenInfo = plain("TweenInfo"),
		RaycastParams = plain("RaycastParams"),
		OverlapParams = plain("OverlapParams"),
		DateTime = { now = function()
			return { UnixTimestamp = os.time(), UnixTimestampMillis = os.time() * 1000 }
		end },
		task = task,
		wait = task.wait,
		delay = task.delay,
		spawn = task.spawn,
		tick = os.clock,
		shared = {},
	}
end

labRequire = function(target: any)
	assert(Dom.isInstance(target), `the lab only requires scripts (got {labTypeof(target)})`)
	local path = target:GetAttribute("LabPath")
	assert(path, `{target:GetFullName()} isn't a script`)
	if STUBS[path] then
		return STUBS[path]
	end
	local cached = modules[target]
	if cached == LOADING then
		error(`cyclic require: {path}`)
	elseif cached ~= nil then
		return cached
	end
	modules[target] = LOADING
	local chunk = luau.load(fs.readFile(path), { debugName = path, environment = environment(target) })
	local result = chunk()
	modules[target] = result
	return result
end

-- The scenario ------------------------------------------------------------------------

local services = game:GetService("ServerScriptService"):FindFirstChild("Services")
local TycoonItems = labRequire(game:GetService("ReplicatedStorage").Shared.Config.TycoonItems)
for _, item in TycoonItems.List do
	everything[item.Id] = true
end
if scenario == "previews" then
	-- each line's upgrade tracks stop at level 3, 6 or 9 (by line), so the previews
	-- show the levels that start a look tier (4, 7, 10)
	local Lines = TycoonItems.LinesById
	for _, item in TycoonItems.List do
		if item.Kind == "Track" and item.LineId and item.Level > ({ 3, 6, 9 })[Lines[item.LineId].Index] then
			everything[item.Id] = nil
		end
	end
end

local clock = os.clock()
local TycoonManager
if scenario == "mixes" then
	-- every brainrot's own build, then each body with every other brainrot's legs, arms
	-- and head (BrainrotModels.Layout), one model each under workspace.Mixes, named
	-- "<Body>|<PartType>|<Other>" ("<Body>|Own|<Body>" for its own build), 40 studs apart
	local Shared = game:GetService("ReplicatedStorage").Shared
	local BrainrotModels = labRequire(Shared.BrainrotModels)
	local Brainrots = labRequire(Shared.Config.Brainrots)
	local folder = Dom.new("Folder", workspace)
	folder.Name = "Mixes"
	local count = 0
	local function build(name: string, parts: { [string]: string })
		local offsets, spread = BrainrotModels.Layout(parts)
		local model = Dom.new("Model", folder)
		model.Name = name
		for partType, id in parts do
			local piece = BrainrotModels.CreatePart(id, partType, nil, spread)
			piece:PivotTo(Types.CFrame.new(Vector3.new(count * 40, 0, 0) + offsets[partType]))
			piece.Parent = model
		end
		count += 1
	end
	for _, body in Brainrots.List do
		local own = {}
		for _, partType in Brainrots.PartTypes do
			own[partType] = body.Id
		end
		build(`{body.Id}|Own|{body.Id}`, own)
		for _, other in Brainrots.List do
			if other.Id ~= body.Id then
				for _, swapped in { "Legs", "Arms", "Head" } do
					local parts = table.clone(own)
					parts[swapped] = other.Id
					build(`{body.Id}|{swapped}|{other.Id}`, parts)
				end
			end
		end
	end
	print(`[lab] {count} brainrot builds in {math.floor((os.clock() - clock) * 1000)} ms`)
else
	TycoonManager = labRequire(services.TycoonManager)
	TycoonManager.Init()
	print(`[lab] 6 plots built in {math.floor((os.clock() - clock) * 1000)} ms`)
	clock = os.clock()
	for _, callback in loadedCallbacks do
		callback(player)
	end
	print(`[lab] plot 1 furnished (everything bought) in {math.floor((os.clock() - clock) * 1000)} ms`)
end
if scenario == "previews" then
	-- every line's next track levels as the Line menu's 👀 gets them, moved from the
	-- lab player's PlayerGui into workspace.Previews
	local gui = Dom.new("PlayerGui", player)
	gui.Name = "PlayerGui"
	local folder = Dom.new("Folder", workspace)
	folder.Name = "Previews"
	local count = 0
	for lineId in TycoonItems.TracksByLine do
		for track in TycoonItems.TracksByLine[lineId] do
			task.wait(0.55) -- (the server's button cooldown)
			local name = TycoonManager.BuildTrackPreview(player, lineId, track)
			local previews = gui:FindFirstChild("LinePreviews")
			local preview = name and previews and previews:FindFirstChild(name)
			if preview then
				local copy = preview:Clone() -- (the server destroys its own after 15 s)
				copy.Name = `{lineId}_{track}`
				copy.Parent = folder
				count += 1
			end
		end
	end
	print(`[lab] {count} track previews built`)
end
if scenario == "world" then
	clock = os.clock()
	labRequire(services.MapBuilder).Init()
	print(`[lab] the hub built in {math.floor((os.clock() - clock) * 1000)} ms ({terrainCalls} terrain fills skipped)`)
end
task.wait(3) -- delayed swaps (the old building goes 2 s after the new one)

-- The dump ----------------------------------------------------------------------------

local function round(value: number): number
	return math.floor(value * 1000 + 0.5) / 1000
end

local partsOut = {}
local others: { [string]: number } = {}
for _, item in workspace:GetDescendants() do
	if item:IsA("BasePart") and item ~= terrain then
		local cf = item.CFrame
		local components = { cf:GetComponents() }
		for index, value in components do
			components[index] = round(value)
		end
		local size = item.Size
		local color = item.Color
		table.insert(partsOut, {
			Path = item:GetFullName(),
			Class = item.ClassName,
			Shape = if item.ClassName == "Part" then item.Shape.Name else item.ClassName,
			Size = { round(size.X), round(size.Y), round(size.Z) },
			CFrame = components,
			Transparency = item.Transparency,
			Material = item.Material.Name,
			Color = { math.floor(color.R * 255 + 0.5), math.floor(color.G * 255 + 0.5), math.floor(color.B * 255 + 0.5) },
			Mesh = if item:FindFirstChildOfClass("SpecialMesh") then item:FindFirstChildOfClass("SpecialMesh").MeshType.Name else nil,
			Guis = if item:FindFirstChildWhichIsA("SurfaceGui") or item:FindFirstChildWhichIsA("Decal") then true else nil,
		})
	elseif not item:IsA("BasePart") then
		others[item.ClassName] = (others[item.ClassName] or 0) + 1
	end
end
-- tags: how many instances carry each, and how many parts move with them
local tags: { [string]: { Count: number, Parts: number } } = {}
for _, item in workspace:GetDescendants() do
	for _, tag in item:GetTags() do
		local entry = tags[tag] or { Count = 0, Parts = 0 }
		tags[tag] = entry
		entry.Count += 1
		if item:IsA("BasePart") then
			entry.Parts += 1
		else
			for _, inner in item:GetDescendants() do
				if inner:IsA("BasePart") then
					entry.Parts += 1
				end
			end
		end
	end
end
fs.writeFile(outPath, serde.encode("json", { Scenario = scenario, Parts = partsOut, Others = others, Tags = tags }))
print(`[lab] {#partsOut} parts written to {outPath} ({Dom.Created} instances made)`)
