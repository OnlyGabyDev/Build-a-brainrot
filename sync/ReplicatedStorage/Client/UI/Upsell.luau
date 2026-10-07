--[[
	Upsell
	A small ad in the top-right corner that offers a gamepass at the moment it would help
	(the user, 2026-10-03): Sprint when you press Shift without it, Lucky / Fast Open
	when loot opens, 2x Coins / Auto-Collect / VIP when you collect the Cash Pad, the
	Starter Pack (with its countdown) after joining. It slides in beside the music and
	settings buttons, says what the pass does, and BUY prompts the purchase; it slides
	away by itself.

	Never pushy: one ad at a time, at most one every GAP seconds, and the same pass at
	most once every SAME_GAP seconds. Owned passes, offers that ended and passes not on
	the dashboard yet (Id 0, outside Studio) are never shown, nor any ad during
	Tralalero's guide (a newcomer's first steps) and for GUIDE_QUIET seconds after.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Gamepasses = require(Shared:WaitForChild("Config"):WaitForChild("Gamepasses"))
local Guide = require(Shared:WaitForChild("Config"):WaitForChild("Guide"))
local Sounds = require(Shared:WaitForChild("Config"):WaitForChild("Sounds"))
local Kit = require(script.Parent:WaitForChild("Kit"))
local Passes = require(script.Parent:WaitForChild("Passes"))

local SIZE = Vector2.new(340, 132)
local SHOWN_AT = UDim2.new(1, -104, 0, 84) -- left of the music and settings buttons
local HIDDEN_AT = UDim2.new(1, SIZE.X + 20, 0, 84)
local HOLD = 9 -- seconds an ad stays up
local GAP = 45 -- seconds between any two ads
local SAME_GAP = 240 -- seconds before the same pass is offered again
local Z = 55 -- over the loot overlay (30), under the completion celebration (60)
local GUIDE_QUIET = 60 -- seconds without ads after Tralalero's guide ends

local current: Frame? = nil
local lastShown = -math.huge
local lastByKey: { [string]: number } = {}
local guideEnded = -math.huge
Players.LocalPlayer:GetAttributeChangedSignal("Guide"):Connect(function()
	if Players.LocalPlayer:GetAttribute("Guide") == Guide.Done then
		guideEnded = os.clock()
	end
end)

local Upsell = {}

local function canShow(key: string): boolean
	local pass = Gamepasses[key]
	if not (pass and Passes.OnSale(key)) then
		return false
	end
	if pass.Id <= 0 and not RunService:IsStudio() then
		return false
	end
	if Guide.Running(Players.LocalPlayer:GetAttribute("Guide")) or os.clock() - guideEnded < GUIDE_QUIET then
		return false
	end
	return os.clock() - (lastByKey[key] or -math.huge) >= SAME_GAP
end

local function hide(card: Frame)
	if current == card then
		current = nil
	end
	local tween = TweenService:Create(card, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.In), { Position = HIDDEN_AT })
	tween:Play()
	tween.Completed:Connect(function()
		card:Destroy()
	end)
end

local function show(key: string, pitch: string?)
	local pass = Gamepasses[key]
	lastShown = os.clock()
	lastByKey[key] = os.clock()

	local card = Kit.new("Frame", {
		Name = "Upsell",
		AnchorPoint = Vector2.new(1, 0),
		Position = HIDDEN_AT,
		Size = UDim2.fromOffset(SIZE.X, SIZE.Y),
		BackgroundColor3 = Kit.White,
		ZIndex = Z,
		Parent = Kit.getGui(),
	})
	current = card
	Kit.corner(card, 20)
	Kit.stroke(card, 4)
	Kit.gradient(card, pass.Colors)
	Kit.stripes(card, 0.84, 20, Z)
	Kit.shine(card, 16).ZIndex = Z
	Kit.neonRim(card, pass.Colors[1]:Lerp(Kit.White, 0.5), 20, 5)

	local bubble = Kit.icon(pass.Icon, {
		Position = UDim2.fromOffset(4, 2),
		Size = UDim2.fromOffset(80, 80),
		ZIndex = Z + 2,
		Parent = card,
	})
	TweenService:Create(bubble, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Rotation = 8 }):Play()

	local left = Passes.OfferLeft(key)
	Kit.text({
		Text = if left then `{pass.Name}: LIMITED!` else pass.Name,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromOffset(86, 10),
		Size = UDim2.new(1, -124, 0, 28),
		StrokeThickness = 3,
		ZIndex = Z + 1,
		Parent = card,
	})
	local line = Kit.text({
		Text = pitch or pass.Perks[1],
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromOffset(86, 40),
		Size = UDim2.new(1, -98, 0, 34),
		TextWrapped = true,
		StrokeThickness = 1.5,
		ZIndex = Z + 1,
		Parent = card,
	})

	Kit.button({
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -8, 0, 8),
		Size = UDim2.fromOffset(30, 30),
		ZIndex = Z + 2,
		Parent = card,
	}, Kit.Colors.Grey, nil, function()
		hide(card)
	end, "Close")
	local buy = Kit.button({
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -10),
		Size = UDim2.new(1, -24, 0, 42),
		ZIndex = Z + 2,
		Parent = card,
	}, Kit.Colors.Green, "GET IT!", function()
		if not Passes.Prompt(key) then
			Kit.toast("Coming soon!", Color3.fromRGB(255, 215, 60), "Clock")
		end
		hide(card)
	end)
	task.spawn(function()
		local price = Passes.PassPrice(key)
		local label = buy:FindFirstChildOfClass("TextLabel")
		if price and label and card.Parent then
			label.Text = `GET IT!  R$ {price}`
		end
	end)

	Kit.playSound(Sounds.Whoosh, 0.25, 1.3)
	TweenService:Create(card, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Position = SHOWN_AT }):Play()

	-- a limited offer counts down on its pitch line
	local deadline = os.clock() + HOLD
	task.spawn(function()
		while card.Parent and current == card and os.clock() < deadline do
			if left then
				line.Text = `Ends in {Passes.Clock(Passes.OfferLeft(key) or 0)}! {pitch or pass.Perks[1]}`
			end
			task.wait(0.5)
		end
		if card.Parent and current == card then
			hide(card)
		end
	end)
end

-- The big one: a limited offer (the Starter Pack) in the middle of the screen, its
-- countdown ticking in red, what you get in big lines over a sunburst, and a huge BUY
-- button. Shown by UIController once a little after joining, while the offer's on.
function Upsell.Featured(key: string)
	local pass = Gamepasses[key]
	if not (pass and Passes.OnSale(key)) or (pass.Id <= 0 and not RunService:IsStudio()) then
		return
	end
	local panel, content = Kit.modal("FeaturedOffer", string.upper(pass.Name), pass.Colors, Vector2.new(640, 520), pass.Icon)
	panel.ZIndex = Z
	local stopRays = Kit.rays(content, pass.Colors[1], 520, 1)
	local clock = Kit.text({
		Text = "",
		TextColor3 = Color3.fromRGB(255, 80, 90),
		Position = UDim2.fromOffset(20, 12),
		Size = UDim2.new(1, -40, 0, 48),
		StrokeThickness = 4,
		ZIndex = 3,
		Parent = content,
	})
	Kit.text({ Text = "NEW PLAYERS ONLY!", TextColor3 = Color3.fromRGB(255, 225, 90), Position = UDim2.fromOffset(20, 62), Size = UDim2.new(1, -40, 0, 28), StrokeThickness = 3, ZIndex = 3, Parent = content })
	for index, perk in pass.Perks do
		local top = 100 + (index - 1) * 50
		Kit.icon("Check", { Position = UDim2.fromOffset(70, top), Size = UDim2.fromOffset(42, 42), ZIndex = 3, Parent = content })
		Kit.text({ Text = perk, Position = UDim2.fromOffset(122, top), Size = UDim2.new(1, -192, 0, 42), TextXAlignment = Enum.TextXAlignment.Left, StrokeThickness = 3, ZIndex = 3, Parent = content })
	end
	local buy = Kit.button({
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -18),
		Size = UDim2.fromOffset(420, 78),
		ZIndex = 4,
		Parent = content,
	}, Kit.Colors.Green, "GET IT NOW!", function()
		if not Passes.Prompt(key) then
			Kit.toast("Coming soon!", Color3.fromRGB(255, 215, 60), "Clock")
		end
	end)
	task.spawn(function()
		local price = Passes.PassPrice(key)
		local label = buy:FindFirstChildOfClass("TextLabel")
		if price and label and buy.Parent then
			label.Text = `GET IT NOW!  R$ {price}`
		end
	end)
	Kit.open(panel)
	Kit.playSound(Sounds.RevealBig, 0.5)
	task.spawn(function()
		while panel.Parent and panel.Visible do
			local left = Passes.OfferLeft(key) or 0
			if left <= 0 or Passes.Owns(key) then
				break
			end
			clock.Text = `ENDS IN {Passes.Clock(left)}`
			Kit.pop(clock, 0.04)
			task.wait(1)
		end
		stopRays()
		if panel.Parent and panel.Visible then
			Kit.close(panel)
		end
	end)
end

-- Offers a pass (or the first of several that can be offered, in order), with an
-- optional pitch line (else the pass's first perk). Does nothing if an ad is up or one
-- was shown lately. Doesn't yield.
function Upsell.Offer(keys: string | { string }, pitch: string?)
	if current or os.clock() - lastShown < GAP then
		return
	end
	local list = if type(keys) == "string" then { keys } else keys
	for _, key in list do
		if canShow(key) then
			show(key, pitch)
			return
		end
	end
end

return Upsell
