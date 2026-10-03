--[[
	Sprint
	The Sprint gamepass (GDD §12): hold Shift to run faster (Config/Gamepasses' Sprint ×
	walk speed). On touch screens a 🏃 button toggles it instead. Your own character's
	walk speed is yours to set, so this is client-side; whatever the server sets (a
	gadget's speed) is the speed it runs from.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local UI = ReplicatedStorage:WaitForChild("Client"):WaitForChild("UI")
local Gamepasses = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("Gamepasses"))
local Kit = require(UI:WaitForChild("Kit"))
local Upsell = require(UI:WaitForChild("Upsell"))

local player = Players.LocalPlayer
local running = false
local base: number? = nil -- the walk speed before the sprint
local boosted: number? = nil

local function humanoid(): Humanoid?
	local character = player.Character
	return character and character:FindFirstChildOfClass("Humanoid")
end

local function owns(): boolean
	return player:GetAttribute("Pass_Sprint") == true
end

local function setRunning(on: boolean)
	local body = humanoid()
	if not body or running == on then
		return
	end
	running = on
	if on then
		base = body.WalkSpeed
		boosted = body.WalkSpeed * (Gamepasses.Sprint.Sprint or 1.5)
		body.WalkSpeed = boosted :: number
	else
		-- (unless the server changed it meanwhile: then that's the speed now)
		if boosted and math.abs(body.WalkSpeed - boosted) < 0.01 and base then
			body.WalkSpeed = base
		end
		base, boosted = nil, nil
	end
end

-- (not `processed`: Roblox's shift lock binds Shift too, which marks it processed and
-- would block the sprint; only typing in a text box should)
UserInputService.InputBegan:Connect(function(input)
	if UserInputService:GetFocusedTextBox() or not (input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift) then
		return
	end
	if owns() then
		setRunning(true)
	else
		Upsell.Offer("Sprint", "Hold Shift to run 60% faster!")
	end
end)
UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
		setRunning(false)
	end
end)
player.CharacterAdded:Connect(function()
	running, base, boosted = false, nil, nil
end)

-- On touch screens: a toggle button above the jump button, once you own the pass.
local button: TextButton? = nil
local function showButton()
	if button or not (owns() and UserInputService.TouchEnabled) then
		return
	end
	button = Kit.button({
		Name = "SprintButton",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -40, 1, -260),
		Size = UDim2.fromOffset(110, 110),
		Parent = Kit.getGui(),
	}, Kit.Colors.Red, nil, function()
		setRunning(not running)
		if button then
			local label = button:FindFirstChild("Label") :: TextLabel?
			if label then
				label.Text = if running then "RUNNING!" else "SPRINT"
			end
		end
	end)
	Kit.text({ Text = "🏃", Position = UDim2.fromScale(0.15, 0.06), Size = UDim2.fromScale(0.7, 0.56), StrokeThickness = 0, Parent = button })
	Kit.text({ Name = "Label", Text = "SPRINT", Position = UDim2.fromScale(0.06, 0.64), Size = UDim2.fromScale(0.88, 0.28), Parent = button })
end
player:GetAttributeChangedSignal("Pass_Sprint"):Connect(showButton)
showButton()
