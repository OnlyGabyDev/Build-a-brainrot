--[[
	Remotes
	Get RemoteEvents / RemoteFunctions by name. The server creates them on first use and
	clients wait for them, so neither side depends on script load order.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local IS_SERVER = RunService:IsServer()
local FOLDER_NAME = "Remotes"

local Remotes = {}

local function get(className: string, name: string): Instance
	if not IS_SERVER then
		-- (no time limit, and so no "infinite yield" warnings: the server makes some only
		-- once the world is built, a good while after a client starts)
		return (ReplicatedStorage:WaitForChild(FOLDER_NAME, math.huge) :: Instance):WaitForChild(name, math.huge) :: Instance
	end

	local folder = ReplicatedStorage:FindFirstChild(FOLDER_NAME)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = FOLDER_NAME
		folder.Parent = ReplicatedStorage
	end
	local remote = folder:FindFirstChild(name)
	if not remote then
		remote = Instance.new(className)
		remote.Name = name
		remote.Parent = folder
	end
	return remote
end

function Remotes.Event(name: string): RemoteEvent
	return get("RemoteEvent", name) :: RemoteEvent
end

function Remotes.Function(name: string): RemoteFunction
	return get("RemoteFunction", name) :: RemoteFunction
end

return Remotes
