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
local BrainrotModels = require(Shared:WaitForChild("BrainrotModels"))
local Brainrots = require(Shared:WaitForChild("Config"):WaitForChild("Brainrots"))
local Format = require(Shared:WaitForChild("Format"))
local Gamepasses = require(Shared:WaitForChild("Config"):WaitForChild("Gamepasses"))
local Rarities = require(Shared:WaitForChild("Config"):WaitForChild("Rarities"))
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
local GUIDE_QUIET = 60 -- seconds without ads after Tralalero's guide lets go (its basics, the upgrade, the mascot)

local current: Frame? = nil
local lastShown = -math.huge
local lastByKey: { [string]: number } = {}
local guideEnded = -math.huge
Players.LocalPlayer:GetAttributeChangedSignal("Guide"):Connect(function()
	local step = Players.LocalPlayer:GetAttribute("Guide")
	if step ~= nil and not Guide.Focused(step) then
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
	if Guide.Focused(Players.LocalPlayer:GetAttribute("Guide")) or os.clock() - guideEnded < GUIDE_QUIET then
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
			label.Text = `GET IT!  {Format.Robux(price)}`
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

local function fullBrainrot(brainrotId: string): Model
	local model = Instance.new("Model")
	for _, partType in Brainrots.PartTypes do
		BrainrotModels.CreatePart(brainrotId, partType).Parent = model
	end
	return model
end

-- A big reward card on the offer: `model` turning over a sunburst on its rarity's
-- colors, its name on a ribbon under it. Returns a function that stops it moving.
local CARD_SIZE = Vector2.new(280, 236)
local function rewardCard(parent: Instance, x: number, y: number, title: string, color: Color3, model: Model): () -> ()
	local card = Kit.new("Frame", { Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(CARD_SIZE.X, CARD_SIZE.Y), BackgroundColor3 = Kit.White, ZIndex = 3, Parent = parent })
	Kit.corner(card, 22)
	Kit.stroke(card, 5)
	Kit.gradient(card, { color:Lerp(Kit.White, 0.5), color:Lerp(Color3.new(0, 0, 0), 0.1) })
	Kit.stripes(card, 0.82, 22, 3)
	Kit.neonRim(card, color:Lerp(Kit.White, 0.5), 22, 5)
	local stopRays = Kit.rays(card, color:Lerp(Kit.White, 0.6), 230, 3)
	local holder = Kit.new("Frame", { Position = UDim2.fromOffset(10, 6), Size = UDim2.fromOffset(CARD_SIZE.X - 20, 172), BackgroundTransparency = 1, ZIndex = 4, Parent = card })
	local view = Kit.viewport({ Size = UDim2.fromScale(1, 1), ZIndex = 4, Parent = holder }, model)
	local stopOrbit = Kit.orbit(view, model, nil, Kit.fitDistance(model, (CARD_SIZE.X - 20) / 172, (view.CurrentCamera :: Camera).FieldOfView) * 1.05)
	local ribbon = Kit.new("Frame", { Position = UDim2.fromOffset(12, 182), Size = UDim2.fromOffset(CARD_SIZE.X - 24, 44), BackgroundColor3 = Kit.White, ZIndex = 5, Parent = card })
	Kit.corner(ribbon, 14)
	Kit.stroke(ribbon, 3.5)
	Kit.gradient(ribbon, { color:Lerp(Kit.White, 0.2), color:Lerp(Color3.new(0, 0, 0), 0.25) })
	Kit.shine(ribbon, 10)
	Kit.text({ Text = title, Position = UDim2.fromOffset(8, 6), Size = UDim2.new(1, -16, 1, -12), StrokeThickness = 3, ZIndex = 6, Parent = ribbon })
	return function()
		stopOrbit()
		stopRays()
	end
end

-- The big one: a limited offer (the Starter Pack) in the middle of the screen, its
-- countdown ticking in red, what you get as pictures (its brainrot and its own box
-- turning on big cards, then Coins, boxes and Rolls with their icons) and a huge BUY
-- button. Shown by UIController once a little after joining, while the offer's on.
function Upsell.Featured(key: string)
	local pass = Gamepasses[key]
	if not (pass and Passes.OnSale(key)) or (pass.Id <= 0 and not RunService:IsStudio()) then
		return
	end
	local panel, content = Kit.modal("FeaturedOffer", string.upper(pass.Name), pass.Colors, Vector2.new(640, 600), pass.Icon)
	panel.ZIndex = Z
	local stopRays = Kit.rays(content, pass.Colors[1], 520, 1)
	local stops = {}
	local clock = Kit.text({
		Text = "",
		TextColor3 = Color3.fromRGB(255, 80, 90),
		Position = UDim2.fromOffset(20, 4),
		Size = UDim2.new(1, -40, 0, 44),
		StrokeThickness = 4,
		ZIndex = 3,
		Parent = content,
	})
	Kit.text({ Text = "NEW PLAYERS ONLY!", TextColor3 = Color3.fromRGB(255, 225, 90), Position = UDim2.fromOffset(20, 52), Size = UDim2.new(1, -40, 0, 26), StrokeThickness = 3, ZIndex = 3, Parent = content })
	local reward = pass.Starter
	if reward then
		-- the big cards: each whole brainrot in it, then its own boxes
		local cards: { { Title: string, Color: Color3, Model: Model } } = {}
		local counts: { [string]: number } = {}
		for _, entry in reward.Parts do
			counts[entry[1]] = (counts[entry[1]] or 0) + 1
		end
		for brainrotId, count in counts do
			local brainrot = Brainrots.ById[brainrotId]
			if brainrot and count >= #Brainrots.PartTypes then
				local rarity = Rarities.ById[brainrot.Rarity]
				table.insert(cards, { Title = `{string.upper(rarity.Id)} {string.upper(string.split(brainrot.Name, " ")[1])}`, Color = rarity.Color, Model = fullBrainrot(brainrotId) })
			end
		end
		local ownBoxes: { string } = reward.OwnBoxes or {}
		for _, rarityId in ownBoxes do
			local rarity = Rarities.ById[rarityId]
			if rarity then
				table.insert(cards, { Title = `{string.upper(rarity.Id)} BOX`, Color = rarity.Color, Model = Kit.boxModel(rarity.Color, rarity.Rank) })
			end
		end
		local shown = math.min(#cards, 2)
		local left = (640 - shown * CARD_SIZE.X - (shown - 1) * 24) / 2
		for index = 1, shown do
			local card = cards[index]
			table.insert(stops, rewardCard(content, left + (index - 1) * (CARD_SIZE.X + 24), 86, card.Title, card.Color, card.Model))
		end
		-- and the rest, with their icons
		local chips = Kit.new("Frame", { Position = UDim2.fromOffset(20, 334), Size = UDim2.new(1, -40, 0, 58), BackgroundTransparency = 1, ZIndex = 3, Parent = content })
		Kit.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0, 12), Parent = chips })
		local chipList: { { any } } = {
			{ "Coin", Format.Number(reward.Coins), Kit.Colors.Coins },
			{ "Gift", `{reward.Boxes} BOXES`, { Color3.fromRGB(255, 150, 205), Color3.fromRGB(225, 60, 150) } },
			{ "Roll", `{reward.Rolls} ROLLS`, Kit.Colors.Rolls },
		}
		for _, chip in chipList do
			local box = Kit.new("Frame", { Size = UDim2.fromOffset(182, 58), BackgroundColor3 = Kit.White, ZIndex = 3, Parent = chips })
			Kit.corner(box, 16)
			Kit.stroke(box, 3.5)
			Kit.gradient(box, chip[3])
			Kit.stripes(box, 0.82, 16, 3)
			Kit.shine(box, 12)
			Kit.iconText({ Position = UDim2.fromOffset(6, 9), Size = UDim2.new(1, -12, 0, 38), ZIndex = 4, Parent = box }, chip[1], chip[2])
		end
	else
		for index, perk in pass.Perks do
			local top = 100 + (index - 1) * 50
			Kit.icon("Check", { Position = UDim2.fromOffset(70, top), Size = UDim2.fromOffset(42, 42), ZIndex = 3, Parent = content })
			Kit.text({ Text = perk, Position = UDim2.fromOffset(122, top), Size = UDim2.new(1, -192, 0, 42), TextXAlignment = Enum.TextXAlignment.Left, StrokeThickness = 3, ZIndex = 3, Parent = content })
		end
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
			label.Text = `GET IT NOW!  {Format.Robux(price)}`
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
		for _, stop in stops do
			stop()
		end
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
