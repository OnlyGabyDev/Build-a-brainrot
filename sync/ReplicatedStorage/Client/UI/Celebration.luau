--[[
	Celebration
	The big moment when a brainrot is claimed in the Album (GDD §7): a full-screen show
	with the brainrot over a sunburst in its rarity's color, the Gems won, and its morph
	and gadget ready to use right away. Queued, so back-to-back claims both play.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local BrainrotModels = require(Shared:WaitForChild("BrainrotModels"))
local Brainrots = require(Config:WaitForChild("Brainrots"))
local Format = require(Shared:WaitForChild("Format"))
local Gadgets = require(Config:WaitForChild("Gadgets"))
local Rarities = require(Config:WaitForChild("Rarities"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Sounds = require(Config:WaitForChild("Sounds"))
local Kit = require(script.Parent:WaitForChild("Kit"))

local AUTO_CLOSE = 10
local TITLE_COLOR = Color3.fromRGB(255, 215, 60)
local GEM_COLOR = Color3.fromRGB(120, 225, 255)
local GOOD_COLOR = Color3.fromRGB(120, 245, 110)
local BAD_COLOR = Color3.fromRGB(255, 90, 90)

type Claim = { BrainrotId: string, Gems: number }

local queue: { Claim } = {}
local playing = false

local Celebration = {}

local function buildFigure(brainrotId: string): Model
	local figure = Instance.new("Model")
	for _, partType in Brainrots.PartTypes do
		BrainrotModels.CreatePart(brainrotId, partType).Parent = figure
	end
	return figure
end

local function request(remoteName: string, brainrotId: string, success: string)
	local remote = Remotes.Function(remoteName)
	local ok, done = pcall(remote.InvokeServer, remote, brainrotId)
	Kit.toast(if ok and done then success else "Try again!", if ok and done then GOOD_COLOR else BAD_COLOR, if ok and done then "Check" else "Warning")
end

local function play(claim: Claim)
	local brainrot = Brainrots.ById[claim.BrainrotId]
	local rarity = Rarities.ById[brainrot.Rarity]
	local gadget = Gadgets[claim.BrainrotId]
	local closed = false

	local screen = Kit.new("Frame", {
		Name = "Celebration",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.35,
		Active = true,
		ZIndex = 60,
		Parent = Kit.getGui(),
	})
	local titleLabel = Kit.text({
		Text = "NEW BRAINROT!",
		TextColor3 = TITLE_COLOR,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 40),
		Size = UDim2.fromOffset(1000, 90),
		StrokeThickness = 5,
		ZIndex = 64,
		Parent = screen,
	})
	Kit.pop(titleLabel, 0.5)

	local stopRays = Kit.rays(screen, rarity.Color, 560, 61)
	local figure = buildFigure(claim.BrainrotId)
	local viewport = Kit.viewport({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, -30),
		Size = UDim2.fromOffset(420, 420),
		ZIndex = 62,
		Parent = screen,
	}, figure)
	local stopOrbit = Kit.orbit(viewport, figure)

	Kit.text({
		Text = brainrot.Name,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0.5, 180),
		Size = UDim2.fromOffset(800, 50),
		StrokeThickness = 4,
		ZIndex = 64,
		Parent = screen,
	})
	Kit.iconText({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0.5, 232),
		Size = UDim2.fromOffset(800, 34),
		ZIndex = 64,
		Parent = screen,
	}, "Gem", `+{Format.Number(claim.Gems)}`, GEM_COLOR)
	Kit.iconText({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0.5, 270),
		Size = UDim2.fromOffset(800, 32),
		ZIndex = 64,
		Parent = screen,
	}, "Mask", "Morph" .. (if gadget then ` + {gadget.Name}` else "") .. " unlocked!", GOOD_COLOR)

	-- use them right away
	local buttons = Kit.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0.5, 310),
		Size = UDim2.fromOffset(660, 60),
		BackgroundTransparency = 1,
		ZIndex = 64,
		Parent = screen,
	})
	Kit.new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		Padding = UDim.new(0, 16),
		Parent = buttons,
	})
	Kit.button({ Size = UDim2.fromOffset(200, 56), ZIndex = 65, Parent = buttons }, Kit.Colors.Purple, "MORPH", function()
		closed = true
		request("SetMorph", claim.BrainrotId, `You're {brainrot.Name} now!`)
	end, "Mask")
	if gadget then
		Kit.button({ Size = UDim2.fromOffset(220, 56), ZIndex = 65, Parent = buttons }, Kit.Colors.Gems, "GADGET", function()
			closed = true
			request("EquipGadget", claim.BrainrotId, `{gadget.Name} equipped!`)
		end, gadget.Icon)
	end
	Kit.button({ Size = UDim2.fromOffset(200, 56), ZIndex = 65, Parent = buttons }, Kit.Colors.Green, "AWESOME!", function()
		closed = true
	end, "Check")

	Kit.flash(screen, rarity.Color, 66)
	Kit.playSound(Sounds.RevealBig, 0.6)
	local colors = { rarity.Color, TITLE_COLOR, GEM_COLOR, Color3.fromRGB(255, 120, 220), GOOD_COLOR }
	Kit.confetti(screen, colors, 60 + rarity.Rank * 15, 63)

	local deadline = os.clock() + AUTO_CLOSE
	while not closed and os.clock() < deadline do
		task.wait(0.05)
	end
	stopOrbit()
	stopRays()
	screen:Destroy()
end

local function processQueue()
	if playing then
		return
	end
	playing = true
	while #queue > 0 do
		local claim = table.remove(queue, 1) :: Claim
		local ok, err = pcall(play, claim)
		if not ok then
			warn(`[Celebration] {err}`)
			local leftover = Kit.getGui():FindFirstChild("Celebration")
			if leftover then
				leftover:Destroy()
			end
		end
	end
	playing = false
end

-- Queues the show for a brainrot just claimed, with the Gems it paid.
function Celebration.Show(brainrotId: string, gems: number)
	if not Brainrots.ById[brainrotId] then
		return
	end
	table.insert(queue, { BrainrotId = brainrotId, Gems = gems })
	task.spawn(processQueue)
end

return Celebration
