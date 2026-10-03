--[[
	NukeManager
	The NUKE (Config/Nuke, GDD §12): bought as a developer product (MonetizationManager
	calls Launch once the receipt is granted). Every client gets the launch (who bought it
	and when, by the server's clock) and plays the warning, the bomber and the drop
	(NukeFX); at the impact this kills every Humanoid in the workspace (players, and any
	future bosses or NPCs) except models tagged NukeProof. Launches queue up, one at a
	time.
]]

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Nuke = require(ReplicatedStorage.Shared.Config.Nuke)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local NukeManager = {}

local remote: RemoteEvent
local queue: { string } = {} -- the buyers' names, in order
local running = false

-- Whether `humanoid` belongs to something that's spared (NukeProof, e.g. a statue).
local function isSpared(humanoid: Humanoid): boolean
	local node: Instance? = humanoid.Parent
	while node and node ~= workspace do
		if CollectionService:HasTag(node, "NukeProof") then
			return true
		end
		node = node.Parent
	end
	return false
end

local function killEveryone()
	for _, descendant in workspace:GetDescendants() do
		if descendant:IsA("Humanoid") and descendant.Health > 0 and not isSpared(descendant) then
			descendant.Health = 0
		end
	end
end

local function run()
	if running then
		return
	end
	running = true
	while #queue > 0 do
		local buyer = table.remove(queue, 1) :: string
		remote:FireAllClients("Launch", buyer, workspace:GetServerTimeNow())
		task.wait(Nuke.Impact)
		killEveryone()
		task.wait(Nuke.Cooldown)
	end
	running = false
end

function NukeManager.Init()
	remote = Remotes.Event("Nuke")
end

-- Queues a nuke bought by `player`.
function NukeManager.Launch(player: Player)
	table.insert(queue, player.DisplayName)
	task.spawn(run)
end

-- (for anyone asking whether one's on its way)
function NukeManager.IsRunning(): boolean
	return running
end

return NukeManager
