--[[
	UpgradePreview
	Shows a line upgrade track's next level in place, for the Line menu's eye button.
	The server builds that level's look with the line's own builders
	(TycoonManager.BuildTrackPreview) into the player's PlayerGui; this clones it into
	the world on this client only, outlined in gold, hides what it replaces (the
	current level's look, and the line parts the new level recolors), flies the camera
	to it with a caption for a few seconds, then puts everything back, the camera too
	(its type and field of view: from the line tablet it goes back onto the tablet).
	Client only.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes"))
local Sounds = require(Shared:WaitForChild("Config"):WaitForChild("Sounds"))
local Effects = require(script.Parent:WaitForChild("Effects"))
local Kit = require(script.Parent:WaitForChild("UI"):WaitForChild("Kit"))

local FLY = 0.8 -- seconds to fly the camera there (and back)
local HOLD = 3.6 -- seconds it shows the new look, the camera drifting round it
local DRIFT = math.rad(14) -- how far the camera drifts round it meanwhile
local PITCH = math.rad(28) -- the camera looks down at it this steeply
local DISTANCE = NumberRange.new(14, 42) -- studs (it stays in the room)
local CEILING = 25 -- studs over the line's floor the camera stays under (rooms are 28 high)
local GOLD = Color3.fromRGB(255, 205, 60)
local FOV = 70 -- (the line tablet narrows it: the shot is framed for this one)

local player = Players.LocalPlayer
local playing = false

local UpgradePreview = {}

local function ease(alpha: number): number
	return TweenService:GetValue(alpha, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
end

-- Runs `update(alpha)` every frame for `duration` seconds.
local function run(duration: number, update: (alpha: number) -> ())
	local start = os.clock()
	while true do
		local alpha = math.min((os.clock() - start) / duration, 1)
		update(alpha)
		if alpha >= 1 then
			return
		end
		RunService.RenderStepped:Wait()
	end
end

-- The player's own plot's Lines folder.
local function ownLines(): Instance?
	local tycoons = workspace:FindFirstChild("Tycoons")
	local plot = tycoons and tycoons:FindFirstChild(`Plot{player:GetAttribute("PlotIndex")}`)
	return plot and plot:FindFirstChild("Lines")
end

-- Hides parts and stops effects for the preview, remembering how to put them back.
type Hidden = { Parts: { [BasePart]: number }, Effects: { [Instance]: boolean } }

local function hide(hidden: Hidden, instance: Instance)
	if instance:IsA("BasePart") then
		if hidden.Parts[instance] == nil then
			hidden.Parts[instance] = instance.LocalTransparencyModifier
			instance.LocalTransparencyModifier = 1
		end
	elseif instance:IsA("ParticleEmitter") or instance:IsA("Light") then
		local effect = instance :: any
		if hidden.Effects[instance] == nil then
			hidden.Effects[instance] = effect.Enabled
			effect.Enabled = false
		end
	end
end

local function restore(hidden: Hidden)
	for part, modifier in hidden.Parts do
		part.LocalTransparencyModifier = modifier
	end
	for effect, enabled in hidden.Effects do
		(effect :: any).Enabled = enabled
	end
end

-- The new look in the world: a copy of the server's preview, outlined in gold, with
-- what it replaces hidden.
local function placeGhost(source: Model, lineId: string, trackKey: string, hidden: Hidden): Model
	local ghost = source:Clone()
	ghost.Name = "UpgradePreview"
	local lines = ownLines()
	local current = lines and lines:FindFirstChild(`{lineId}_Up{trackKey}`)
	if current then
		hide(hidden, current)
		for _, descendant in current:GetDescendants() do
			hide(hidden, descendant)
		end
	end
	local line = lines and lines:FindFirstChild(lineId)
	for _, part in ghost:GetDescendants() do
		if part:IsA("BasePart") then
			part.Anchored = true
			part.CanCollide = false
			part.CanQuery = false
			part.CanTouch = false
			-- a recolored copy of a line part: hide the original (same name and place)
			if part:GetAttribute("Recolored") and line then
				for _, original in line:GetDescendants() do
					if original:IsA("BasePart") and original.Name == part.Name and (original.Position - part.Position).Magnitude < 0.01 then
						hide(hidden, original)
					end
				end
			end
		end
	end
	local outline = Instance.new("Highlight")
	outline.FillTransparency = 1
	outline.OutlineColor = GOLD
	outline.DepthMode = Enum.HighlightDepthMode.Occluded
	outline.Parent = ghost
	ghost.Parent = workspace
	return ghost
end

-- A caption at the bottom of the screen while it plays.
local function showCaption(title: string, subtitle: string): Frame
	local pill = Kit.new("Frame", {
		Name = "UpgradePreviewCaption",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -60),
		Size = UDim2.fromOffset(620, 96),
		BackgroundColor3 = Kit.White,
		ZIndex = 40,
		Parent = Kit.getGui(),
	})
	Kit.corner(pill, 22)
	Kit.stroke(pill, 4)
	Kit.gradient(pill, Kit.Colors.Purple)
	Kit.shine(pill, 18)
	Kit.text({ Text = title, Position = UDim2.fromOffset(20, 8), Size = UDim2.new(1, -40, 0, 46), StrokeThickness = 3.5, ZIndex = 41, Parent = pill })
	Kit.text({ Text = subtitle, Position = UDim2.fromOffset(20, 56), Size = UDim2.new(1, -40, 0, 30), TextColor3 = Color3.fromRGB(255, 240, 160), ZIndex = 41, Parent = pill })
	Kit.pop(pill, 0.2)
	return pill
end

-- Where the camera looks at `center` from: back toward where it was, `turn` round.
local function shotAt(center: Vector3, size: Vector3, toward: Vector3, floorY: number, turn: number): CFrame
	local away = Vector3.new(toward.X - center.X, 0, toward.Z - center.Z)
	away = if away.Magnitude > 0.1 then away.Unit else Vector3.zAxis
	away = CFrame.Angles(0, turn, 0):VectorToWorldSpace(away)
	local distance = math.clamp(math.max(size.X, size.Z) * 0.9 + size.Y + 8, DISTANCE.Min, DISTANCE.Max)
	local eye = center + away * distance * math.cos(PITCH) + Vector3.new(0, distance * math.sin(PITCH), 0)
	eye = Vector3.new(eye.X, math.min(eye.Y, floorY + CEILING), eye.Z)
	return CFrame.lookAt(eye, center)
end

-- Plays the preview of `trackKey`'s next level on line `lineId`, with a caption. Calls
-- `onDone` when it's over. False (at once) if it can't: maxed out, already playing.
function UpgradePreview.Play(lineId: string, trackKey: string, title: string, subtitle: string, onDone: () -> ()): boolean
	if playing then
		return false
	end
	playing = true
	local remote = Remotes.Function("PreviewLineUpgrade")
	local ok, name = pcall(remote.InvokeServer, remote, lineId, trackKey)
	local gui = player:FindFirstChildOfClass("PlayerGui")
	local folder = ok and typeof(name) == "string" and gui and gui:WaitForChild("LinePreviews", 5)
	local source = folder and folder:WaitForChild(name :: string, 5)
	if not (source and source:IsA("Model")) then
		playing = false
		return false
	end

	task.spawn(function()
		local hidden: Hidden = { Parts = {}, Effects = {} }
		local ghost = placeGhost(source, lineId, trackKey, hidden)
		local camera = workspace.CurrentCamera
		local home, homeType, homeFov = camera.CFrame, camera.CameraType, camera.FieldOfView
		local box, size = ghost:GetBoundingBox()
		local lines = ownLines()
		local line = lines and lines:FindFirstChild(lineId)
		local origin = line and line:GetAttribute("Origin")
		local floorY = if typeof(origin) == "CFrame" then origin.Y else box.Position.Y - size.Y / 2
		local function shot(turn: number): CFrame
			return shotAt(box.Position, size, home.Position, floorY, turn)
		end

		camera.CameraType = Enum.CameraType.Scriptable
		Effects.sound2D(Sounds.Whoosh, 0.25, 1.3)
		run(FLY, function(a)
			camera.CFrame = home:Lerp(shot(-DRIFT / 2), ease(a))
			camera.FieldOfView = homeFov + (FOV - homeFov) * ease(a)
		end)
		local caption = showCaption(title, subtitle)
		Effects.sound2D(Sounds.RevealBig, 0.35)
		Effects.sparkle(box.Position, GOLD, 20)
		Effects.flash(box.Position, GOLD, 4, math.max(size.X, size.Z) + 12, 0.6)
		run(HOLD, function(a)
			camera.CFrame = shot(-DRIFT / 2 + DRIFT * a)
		end)
		caption:Destroy()
		ghost:Destroy()
		restore(hidden)
		Effects.sound2D(Sounds.Whoosh, 0.2, 1.1)
		local from = camera.CFrame
		run(FLY, function(a)
			camera.CFrame = from:Lerp(home, ease(a))
			camera.FieldOfView = FOV + (homeFov - FOV) * ease(a)
		end)
		camera.CameraType = homeType
		playing = false
		onDone()
	end)
	return true
end

return UpgradePreview
