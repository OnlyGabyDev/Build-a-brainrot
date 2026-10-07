--[[
	Guide (client)
	Tralalero's guide (Config/Guide; Services/GuideManager moves it on):
	  * On every spawn the server sends "Spawned" (with the plot's CFrame): the camera
	    turns to face the way the character does, down the first line (a teleport doesn't
	    turn it). A newcomer's first spawn flies a short intro onto YOUR factory and its
	    sign instead; any click, tap, key or gamepad button skips it.
	  * A speech bubble at the bottom middle: Tralalero (the 3D starter, swaying) says the
	    goal in a few words with a big icon. Nothing in it takes a press, so it works the
	    same on PC, phones and consoles (and never blocks the thumbstick: no Active parts).
	  * A pointer to the goal (the "GuideTarget", "GuideLift" and "GuideRing" attributes;
	    "GuideSay" when it points somewhere else first, like the Cash Pad for Coins):
	    a big 3D arrow bouncing over it (turned to you, seen through walls), a ring round
	    it, and a short trail of moving chevrons on the floor from your feet toward it.
	  * Each step's reward pops out of the bubble; the last gift (a new Rare+ part) is
	    revealed by Loot once the completion banner has gone.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local BrainrotModels = require(Shared:WaitForChild("BrainrotModels"))
local Brainrots = require(Config:WaitForChild("Brainrots"))
local Guide = require(Config:WaitForChild("Guide"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Sounds = require(Config:WaitForChild("Sounds"))
local UI = ReplicatedStorage:WaitForChild("Client"):WaitForChild("UI")
local Kit = require(UI:WaitForChild("Kit"))
local Loot = require(UI:WaitForChild("Loot"))

local ARROW_COLOR = Color3.fromRGB(255, 225, 50)
local RING_COLOR = Color3.fromRGB(255, 215, 0)
local BEAM_COLOR = Color3.fromRGB(255, 170, 0) -- deep enough to read on the light floors
local BEAM_TEXTURE = "rbxassetid://7140341425" -- white chevrons pointing along the beam (the belts' arrows)
local BUBBLE_SIZE = Vector2.new(600, 140)
local BUBBLE_Z = 6 -- under the menus (10) and the loot and completion overlays
local BUBBLE_SHOWN = UDim2.new(0.5, 0, 1, -20)
local BUBBLE_HIDDEN = UDim2.new(0.5, 0, 1, BUBBLE_SIZE.Y + 40)
local TRALALERO_BLUE = { Color3.fromRGB(120, 200, 255), Color3.fromRGB(40, 110, 230) }
local INK = Color3.fromRGB(40, 32, 60)
local NEAR = 7 -- studs: the trail hides this close to the goal
local TRAIL = 16 -- studs: the trail's length at most (a compass at your feet, not a path)
local CELEBRATION_WAIT = 20 -- seconds at most the gift waits for the completion banner
local SKIP_INPUTS = {
	[Enum.UserInputType.MouseButton1] = true,
	[Enum.UserInputType.Touch] = true,
	[Enum.UserInputType.Keyboard] = true,
}

-- The intro's shots, in plot space (-Z faces the hub; the sign hangs over the entrance,
-- ~25 studs up at Z -62): a wide view of the factory front, then the sign up close.
local INTRO_WIDE = { From = Vector3.new(-30, 75, -215), At = Vector3.new(0, 18, -30) }
local INTRO_SIGN = { From = Vector3.new(0, 27, -100), At = Vector3.new(0, 24.5, -62) }
local INTRO_TIMES = { Fly = 2.6, Hold = 1.8, Down = 1.5 }

local player = Players.LocalPlayer
local guideRemote = Remotes.Event("Guide")
local gui = Kit.getGui()

local introPlaying = false
local rewardUntil = 0 -- the bubble shows a reward until then, before the next goal

-- Speech bubble ------------------------------------------------------------------

local bubble = Kit.new("Frame", {
	Name = "GuideBubble",
	AnchorPoint = Vector2.new(0.5, 1),
	Position = BUBBLE_HIDDEN,
	Size = UDim2.fromOffset(BUBBLE_SIZE.X, BUBBLE_SIZE.Y),
	BackgroundTransparency = 1,
	Visible = false,
	ZIndex = BUBBLE_Z,
	Parent = gui,
})

-- the speech panel: glossy cream with a thick outline, pointing at Tralalero
local panel = Kit.new("Frame", {
	Name = "Panel",
	AnchorPoint = Vector2.new(1, 0.5),
	Position = UDim2.new(1, 0, 0.5, 6),
	Size = UDim2.new(1, -BUBBLE_SIZE.Y + 12, 0, 104),
	BackgroundColor3 = Color3.new(1, 1, 1),
	ZIndex = BUBBLE_Z,
	Parent = bubble,
})
Kit.corner(panel, 26)
Kit.stroke(panel, 4)
Kit.gradient(panel, Kit.Colors.Panel)
Kit.stripes(panel, 0.93, 26, BUBBLE_Z)
local tail = Kit.new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(0, 0, 0.5, 0),
	Size = UDim2.fromOffset(26, 26),
	Rotation = 45,
	BackgroundColor3 = Color3.fromRGB(250, 244, 232),
	ZIndex = BUBBLE_Z - 1,
	Parent = panel,
})
Kit.stroke(tail, 4)

local icon = Kit.icon("Star", {
	Name = "Icon",
	AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.new(0, 18, 0.5, 0),
	Size = UDim2.fromOffset(92, 92),
	ZIndex = BUBBLE_Z + 1,
	Parent = panel,
})
local line = Kit.text({
	Name = "Line",
	AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.new(0, 120, 0.5, 0),
	Size = UDim2.new(1, -140, 0, 64),
	Text = "",
	TextColor3 = INK,
	TextXAlignment = Enum.TextXAlignment.Left,
	StrokeThickness = 0,
	ZIndex = BUBBLE_Z + 1,
	Parent = panel,
})
Kit.new("UITextSizeConstraint", { MaxTextSize = 48, Parent = line })

-- Tralalero himself: the starter brainrot in a round blue bubble, swaying as he talks
local portrait = Kit.new("Frame", {
	Name = "Portrait",
	AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.new(0, 0, 0.5, 0),
	Size = UDim2.fromOffset(BUBBLE_SIZE.Y, BUBBLE_SIZE.Y),
	BackgroundColor3 = Color3.new(1, 1, 1),
	ZIndex = BUBBLE_Z + 2,
	Parent = bubble,
})
Kit.corner(portrait, BUBBLE_SIZE.Y / 2)
Kit.stroke(portrait, 4)
Kit.gradient(portrait, TRALALERO_BLUE)
Kit.shine(portrait, BUBBLE_SIZE.Y / 2)
local figure = Instance.new("Model")
for _, partType in Brainrots.PartTypes do
	BrainrotModels.CreatePart(Brainrots.StarterId, partType).Parent = figure
end
local viewport = Kit.viewport({
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromScale(1.1, 1.1),
	ZIndex = BUBBLE_Z + 3,
	Parent = portrait,
}, figure)
Kit.text({ -- his name, on a tag under him
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(0.5, 0, 1, -4),
	Size = UDim2.fromOffset(150, 30),
	Text = "TRALALERO",
	TextColor3 = Color3.fromRGB(255, 240, 120),
	StrokeThickness = 3,
	ZIndex = BUBBLE_Z + 4,
	Parent = portrait,
})
local figureBox, figureSize = figure:GetBoundingBox()
local figureDistance = figureSize.Magnitude * 1.25 + 0.5
RunService.RenderStepped:Connect(function()
	if not bubble.Visible then
		return
	end
	-- three quarters on (head-on he's a blue column), swaying, bobbing with each word
	local now = os.clock()
	local angle = math.rad(35) + math.sin(now * 1.6) * 0.35
	local camera = viewport.CurrentCamera :: Camera
	local focus = figureBox.Position + Vector3.new(0, figureSize.Y * 0.08 + math.abs(math.sin(now * 7)) * 0.08 * figureSize.Y * (if os.clock() < rewardUntil then 1 else 0.3), 0)
	camera.CFrame = CFrame.lookAt(focus + Vector3.new(math.sin(angle), 0.25, -math.cos(angle)).Unit * figureDistance, focus)
end)

local shownText = ""
local function say(text: string, symbol: string) -- (symbol: one of our icons)
	if text == shownText and bubble.Visible then
		return
	end
	shownText = text
	line.Text = text
	icon.Image = Kit.iconId(symbol)
	if not bubble.Visible then
		bubble.Visible = true
		bubble.Position = BUBBLE_HIDDEN
		TweenService:Create(bubble, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Position = BUBBLE_SHOWN }):Play()
	end
	Kit.pop(panel, 0.12)
	Kit.pop(icon, 0.35)
	Kit.playSound(Sounds.Pop, 0.45, 1.25)
end

local function hideBubble()
	if not bubble.Visible then
		return
	end
	shownText = ""
	local tween = TweenService:Create(bubble, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.In), { Position = BUBBLE_HIDDEN })
	tween:Play()
	tween.Completed:Once(function()
		if bubble.Position == BUBBLE_HIDDEN then
			bubble.Visible = false
		end
	end)
end

-- Pointer --------------------------------------------------------------------------

local pointer = Instance.new("Model")
pointer.Name = "GuidePointer"

local function pointerPart(name: string, className: string, size: Vector3): BasePart
	local part = Instance.new(className) :: BasePart
	part.Name = name
	part.Size = size
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Material = Enum.Material.Neon
	part.Color = ARROW_COLOR
	part.Parent = pointer
	return part
end

-- a flat, chunky down arrow (its face in the YZ plane, turned to the camera): a shaft
-- over a two-wedge head; it grows with distance so it still reads from across the room
local ARROW_THICK, HEAD_WIDTH, HEAD_HEIGHT, SHAFT = 1.1, 5, 3.2, Vector2.new(2, 3)
local ARROW_GROW = { From = 40, Max = 2.4 } -- full size up to this far, then bigger up to Max
local shaft = pointerPart("Shaft", "Part", Vector3.one)
local headRight = pointerPart("HeadRight", "WedgePart", Vector3.one)
local headLeft = pointerPart("HeadLeft", "WedgePart", Vector3.one)
-- a glowing disc just under the goal's top: what shows round its edge reads as a ring
local ring = pointerPart("Ring", "Part", Vector3.new(0.15, 7, 7))
ring.Shape = Enum.PartType.Cylinder
ring.Color = RING_COLOR
ring.Transparency = 0.1
local beamEnd = pointerPart("BeamEnd", "Part", Vector3.new(0.2, 0.2, 0.2))
beamEnd.Transparency = 1

local highlight = Instance.new("Highlight")
highlight.FillColor = ARROW_COLOR
highlight.FillTransparency = 0.15
highlight.OutlineColor = INK
highlight.OutlineTransparency = 0
highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
highlight.Parent = pointer

local endAttachment = Instance.new("Attachment")
endAttachment.Parent = beamEnd
local beam = Instance.new("Beam")
beam.Texture = BEAM_TEXTURE
beam.TextureMode = Enum.TextureMode.Static
beam.TextureLength = 3
beam.TextureSpeed = 1.2
beam.Width0 = 3
beam.Width1 = 3
beam.FaceCamera = false
beam.Segments = 8 -- (its transparency is only worked out at the segments' ends)
beam.LightEmission = 0.25
beam.LightInfluence = 0
beam.Color = ColorSequence.new(BEAM_COLOR)
beam.Transparency = NumberSequence.new({ -- fading out toward its end
	NumberSequenceKeypoint.new(0, 0.3),
	NumberSequenceKeypoint.new(0.125, 0),
	NumberSequenceKeypoint.new(0.625, 0),
	NumberSequenceKeypoint.new(1, 1),
})
beam.Attachment1 = endAttachment
beam.Parent = beamEnd

local function feetAttachment(): Attachment?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not (root and root:IsA("BasePart")) then
		return nil
	end
	local attachment = root:FindFirstChild("GuideFeet") :: Attachment?
	if not attachment then
		local made = Instance.new("Attachment")
		made.Name = "GuideFeet"
		made.Position = Vector3.new(0, -2, 0) -- (a little over the floor: over the Cash Pad and buttons too)
		made.Parent = root
		attachment = made
	end
	return attachment
end

RunService.RenderStepped:Connect(function()
	local target = player:GetAttribute("GuideTarget")
	if introPlaying or typeof(target) ~= "Vector3" or not Guide.Running(player:GetAttribute("Guide")) then
		pointer.Parent = nil
		return
	end
	local now = os.clock()
	local lift = (player:GetAttribute("GuideLift") or 6) :: number
	local bounce = math.abs(math.sin(now * 3.2)) * 1.4
	local tip = target + Vector3.new(0, lift + bounce, 0)
	local eye = workspace.CurrentCamera.CFrame.Position
	local grow = math.clamp((eye - tip).Magnitude / ARROW_GROW.From, 1, ARROW_GROW.Max)
	-- its face toward the camera (+X to it), rocking a little
	local flat = Vector3.new(eye.X, tip.Y, eye.Z)
	local facing = if (flat - tip).Magnitude > 0.1 then CFrame.lookAt(tip, flat) else CFrame.new(tip)
	local base = facing * CFrame.Angles(0, math.pi / 2 + math.sin(now * 2) * 0.35, 0)
	-- the head's tip at the base, the shaft above it
	local thick, width, height = ARROW_THICK * grow, HEAD_WIDTH * grow, HEAD_HEIGHT * grow
	headRight.Size = Vector3.new(thick, height, width / 2)
	headLeft.Size = headRight.Size
	shaft.Size = Vector3.new(thick, SHAFT.Y * grow, SHAFT.X * grow)
	local headMiddle = base * CFrame.new(0, height / 2, 0)
	headRight.CFrame = headMiddle * CFrame.new(0, 0, width / 4) * CFrame.Angles(math.pi, 0, 0)
	headLeft.CFrame = headMiddle * CFrame.new(0, 0, -width / 4) * CFrame.Angles(0, math.pi, 0) * CFrame.Angles(math.pi, 0, 0)
	shaft.CFrame = base * CFrame.new(0, height + SHAFT.Y * grow / 2 - 0.05, 0)

	local ringSize = (player:GetAttribute("GuideRing") or 0) :: number
	if ringSize > 0 then
		local pulse = 1 + math.sin(now * 5) * 0.08
		ring.Size = Vector3.new(0.15, ringSize * pulse, ringSize * pulse)
		ring.CFrame = CFrame.new(target + Vector3.new(0, 0.12, 0)) * CFrame.Angles(0, 0, math.pi / 2)
		ring.Transparency = 0.1
	else
		ring.Transparency = 1
	end

	-- the trail: from your feet toward the goal, level with them
	local feet = feetAttachment()
	local from = if feet then feet.WorldPosition else target
	local toward = (target - from) * Vector3.new(1, 0, 1)
	local distance = toward.Magnitude
	if feet and distance > 0.1 then
		-- both ends: X up, Y across the trail (a beam that doesn't face the camera is as
		-- wide as its attachments' Y axes): it lies flat
		local across = Vector3.yAxis:Cross(toward.Unit)
		feet.WorldCFrame = CFrame.fromMatrix(from, Vector3.yAxis, across)
		beamEnd.CFrame = CFrame.fromMatrix(from + toward.Unit * math.min(distance - 2, TRAIL), Vector3.yAxis, across)
	end
	beam.Attachment0 = feet
	beam.Enabled = feet ~= nil and distance > NEAR
	pointer.Parent = workspace
end)

-- Camera -----------------------------------------------------------------------------

-- Behind the character, looking the way it faces (the default camera keeps this look).
local function behind(root: BasePart): CFrame
	local look = root.CFrame.LookVector * Vector3.new(1, 0, 1)
	look = if look.Magnitude > 0.01 then look.Unit else Vector3.new(0, 0, -1)
	return CFrame.lookAt(root.Position - look * 14 + Vector3.new(0, 6, 0), root.Position + look * 6)
end

local function faceForward()
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		RunService.RenderStepped:Wait()
		workspace.CurrentCamera.CFrame = behind(root)
	end
end

-- Flies the camera onto the factory: wide, then the sign with your name, then down
-- behind you. Any press skips it (moving too: the controls stay on, and the last shot
-- follows you wherever you walk).
local function playIntro(plotCFrame: CFrame)
	introPlaying = true
	local playerGui = player:WaitForChild("PlayerGui")
	local waitUntil = os.clock() + 70 -- (the loading screen waits for downloads: 60 s at most)
	while playerGui:FindFirstChild("LoadingScreen") and os.clock() < waitUntil do
		task.wait(0.1)
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not (root and root:IsA("BasePart")) then
		introPlaying = false
		guideRemote:FireServer("Intro")
		return
	end
	pcall(player.RequestStreamAroundAsync, player, (plotCFrame * CFrame.new(0, 0, -80)).Position, 2)

	local camera = workspace.CurrentCamera
	local wide = CFrame.lookAt(plotCFrame * INTRO_WIDE.From, plotCFrame * INTRO_WIDE.At)
	local sign = CFrame.lookAt(plotCFrame * INTRO_SIGN.From, plotCFrame * INTRO_SIGN.At)
	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame = wide

	-- a cinematic: the HUD steps aside for black bars and a big title
	gui.Visible = false
	local screen = Kit.new("ScreenGui", { Name = "GuideIntro", IgnoreGuiInset = true, DisplayOrder = 20, ResetOnSpawn = false, Parent = playerGui })
	local bars = {}
	for index, anchor in { 0, 1 } do
		bars[index] = Kit.new("Frame", {
			AnchorPoint = Vector2.new(0, anchor),
			Position = UDim2.fromScale(0, anchor),
			Size = UDim2.fromScale(1, 0),
			BackgroundColor3 = Color3.new(0, 0, 0),
			BorderSizePixel = 0,
			Parent = screen,
		})
		TweenService:Create(bars[index], TweenInfo.new(0.6, Enum.EasingStyle.Quad), { Size = UDim2.fromScale(1, 0.11) }):Play()
	end
	local title = Kit.text({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.2),
		Size = UDim2.fromScale(0.7, 0.13),
		Text = "YOUR FACTORY!",
		TextColor3 = Color3.fromRGB(255, 225, 60),
		StrokeThickness = 5,
		Visible = false,
		Parent = screen,
	})
	Kit.playSound(Sounds.Whoosh, 0.5, 0.8)

	local skipped = false
	local started = os.clock()
	local inputConnection = UserInputService.InputBegan:Connect(function(input)
		local gamepad = input.UserInputType.Name:sub(1, 7) == "Gamepad" and input.KeyCode ~= Enum.KeyCode.Thumbstick1 and input.KeyCode ~= Enum.KeyCode.Thumbstick2
		if os.clock() - started > 0.6 and (SKIP_INPUTS[input.UserInputType] or gamepad) then
			skipped = true
		end
	end)

	local function move(from: CFrame, to: () -> CFrame, seconds: number): boolean
		local begin = os.clock()
		while os.clock() - begin < seconds do
			if skipped then
				return false
			end
			local alpha = TweenService:GetValue((os.clock() - begin) / seconds, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
			camera.CFrame = from:Lerp(to(), alpha)
			RunService.RenderStepped:Wait()
		end
		camera.CFrame = to()
		return true
	end
	local function hold(seconds: number): boolean
		local begin = os.clock()
		while os.clock() - begin < seconds do
			if skipped then
				return false
			end
			RunService.RenderStepped:Wait()
		end
		return true
	end
	local function behindRoot(): CFrame
		return behind(root :: BasePart)
	end

	if move(wide, function()
		return sign
	end, INTRO_TIMES.Fly) then
		title.Visible = true
		Kit.pop(title, 0.5)
		Kit.playSound(Sounds.Jingle, 0.6)
		if hold(INTRO_TIMES.Hold) then
			move(sign, behindRoot, INTRO_TIMES.Down)
		end
	end

	inputConnection:Disconnect()
	camera.CFrame = behind(root)
	camera.CameraType = Enum.CameraType.Custom
	for _, bar in bars do
		TweenService:Create(bar, TweenInfo.new(0.4, Enum.EasingStyle.Quad), { Size = UDim2.fromScale(1, 0) }):Play()
	end
	title.Visible = false
	task.delay(0.45, function()
		screen:Destroy()
	end)
	gui.Visible = true
	introPlaying = false
	guideRemote:FireServer("Intro")
end

task.spawn(function()
	Remotes.Event("Spawned").OnClientEvent:Connect(function(plotCFrame: CFrame)
		if introPlaying then
			return
		end
		if player:GetAttribute("Guide") == "Intro" then
			playIntro(plotCFrame)
		else
			faceForward()
		end
	end)
end)

-- Steps -----------------------------------------------------------------------------

local function showStep()
	local step = player:GetAttribute("Guide")
	local saying = player:GetAttribute("GuideSay") or step
	local info = if type(saying) == "string" then Guide.ById[saying] or Guide.Hints[saying] else nil
	if os.clock() < rewardUntil then
		return -- (the reward's still up: the timer below shows the goal after)
	end
	if info and info.Say ~= "" then
		say(info.Say, info.Icon)
	elseif step ~= Guide.Done then
		hideBubble()
	end
end

player:GetAttributeChangedSignal("Guide"):Connect(function()
	if player:GetAttribute("Guide") == Guide.Done then
		rewardUntil = os.clock() + 4
		say("You did it!", "Trophy")
		task.delay(4, function()
			if not bubble:GetAttribute("Gifting") then
				hideBubble()
			end
		end)
		return
	end
	showStep()
end)
player:GetAttributeChangedSignal("GuideSay"):Connect(showStep)
showStep()

guideRemote.OnClientEvent:Connect(function(action: string, ...)
	if action == "Reward" then
		local _stepId, coins, rolls = ...
		local parts = {}
		if coins > 0 then
			table.insert(parts, `+{coins} Coins`)
		end
		if rolls > 0 then
			table.insert(parts, `+{rolls} {if rolls == 1 then "Roll" else "Rolls"}`)
		end
		rewardUntil = os.clock() + 1.4
		say(if #parts > 0 then table.concat(parts, "  ") else "Nice!", if rolls > 0 then "Roll" elseif coins > 0 then "Coin" else "Check")
		Kit.confetti(bubble, { ARROW_COLOR, Color3.fromRGB(120, 245, 110), Color3.fromRGB(120, 200, 255), Color3.fromRGB(255, 140, 230) }, 14, BUBBLE_Z + 5)
		Kit.playSound(Sounds.Cash, 0.5)
		task.delay(1.45, showStep)
	elseif action == "Gift" then
		local result = ...
		bubble:SetAttribute("Gifting", true)
		-- after the completion banner (it comes with the PERFECT)
		local waitUntil = os.clock() + CELEBRATION_WAIT
		task.wait(1)
		while gui:FindFirstChild("Celebration") and os.clock() < waitUntil do
			task.wait(0.2)
		end
		rewardUntil = os.clock() + 2
		say("A gift for you!", "Gift")
		task.wait(1.6)
		Loot.Show(result)
		task.wait(1)
		while gui:FindFirstChild("LootOverlay") do
			task.wait(0.2)
		end
		rewardUntil = os.clock() + 3.5
		say("Keep building!", "Rocket")
		task.wait(3.5)
		bubble:SetAttribute("Gifting", nil)
		if Guide.Running(player:GetAttribute("Guide")) then
			showStep() -- (started over: DevTools' Guide)
		else
			hideBubble()
		end
	end
end)
