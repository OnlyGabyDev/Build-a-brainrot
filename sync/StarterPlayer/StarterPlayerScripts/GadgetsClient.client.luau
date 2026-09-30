--[[
	GadgetsClient
	The client half of gadgets (GDD §3). Emote gadgets play their animation on your own
	character, since only the client that owns a character should animate it. Click
	with the gadget out to start or stop dancing. Everything else about gadgets
	(speed, knockback) runs on the server (GadgetManager).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Gadgets = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("Gadgets"))

local player = Players.LocalPlayer
local hooked: { [Tool]: boolean } = setmetatable({}, { __mode = "k" }) :: any
local dancing: AnimationTrack? = nil

local function stopDancing()
	if dancing then
		dancing:Stop()
		dancing = nil
	end
end

local function hookTool(tool: Instance)
	if not tool:IsA("Tool") or hooked[tool] or tool:GetAttribute("Gadget") ~= "Emote" then
		return
	end
	hooked[tool] = true
	local brainrotId = tool:GetAttribute("BrainrotId")
	local gadget = if typeof(brainrotId) == "string" then Gadgets[brainrotId] else nil
	if not (gadget and gadget.AnimationId) then
		return
	end

	tool.Activated:Connect(function()
		if dancing then
			stopDancing()
			return
		end
		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
		if not animator then
			return
		end
		local animation = Instance.new("Animation")
		animation.AnimationId = gadget.AnimationId :: string
		local track = animator:LoadAnimation(animation)
		track.Looped = true
		track.Priority = Enum.AnimationPriority.Action
		track:Play()
		dancing = track
	end)
	tool.Unequipped:Connect(stopDancing)
end

-- Tools are equipped into the character, so watch each new character.
local function watchCharacter(character: Model)
	stopDancing()
	for _, child in character:GetChildren() do
		hookTool(child)
	end
	character.ChildAdded:Connect(hookTool)
end

player.CharacterAdded:Connect(watchCharacter)
if player.Character then
	watchCharacter(player.Character)
end
