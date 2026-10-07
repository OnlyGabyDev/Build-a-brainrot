--[[
	UIController
	The HUD (GDD §13): Coins, Gems and Rolls counters (Player attributes set by
	DataManager), the menu buttons, and a "Configure line" prompt on the tablet beside
	each of your own assembly lines: it flies the camera onto the tablet's screen and
	opens the Line menu there. The menus live in ReplicatedStorage/Client/UI.
]]

local GuiService = game:GetService("GuiService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local TextChatService = game:GetService("TextChatService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local UI = ReplicatedStorage:WaitForChild("Client"):WaitForChild("UI")
local Format = require(Shared:WaitForChild("Format"))
local Gamepasses = require(Shared:WaitForChild("Config"):WaitForChild("Gamepasses"))
local Guide = require(Shared:WaitForChild("Config"):WaitForChild("Guide"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local AchievementsMenu = require(UI:WaitForChild("AchievementsMenu"))
local Catalog = require(UI:WaitForChild("Catalog"))
local DailyLoginMenu = require(UI:WaitForChild("DailyLoginMenu"))
local WelcomeBackMenu = require(UI:WaitForChild("WelcomeBackMenu"))
local DailyWheelMenu = require(UI:WaitForChild("DailyWheelMenu"))
local Kit = require(UI:WaitForChild("Kit"))
local LineMenu = require(UI:WaitForChild("LineMenu"))
local Loot = require(UI:WaitForChild("Loot"))
local RebirthMenu = require(UI:WaitForChild("RebirthMenu"))
local MascotMenu = require(UI:WaitForChild("MascotMenu"))
local SettingsMenu = require(UI:WaitForChild("SettingsMenu"))
local Shop = require(UI:WaitForChild("Shop"))
local Upsell = require(UI:WaitForChild("Upsell"))

local COUNTERS = {
	{ Stat = "Coins", Icon = "Coin", Colors = Kit.Colors.Coins, Float = Color3.fromRGB(255, 235, 110), Gap = 70 },
	{ Stat = "Gems", Icon = "Gem", Colors = Kit.Colors.Gems, Float = Color3.fromRGB(140, 235, 255), Gap = 110 },
	{ Stat = "Rolls", Icon = "Roll", Colors = Kit.Colors.Rolls, Float = Color3.fromRGB(255, 160, 240), Gap = 160 },
}
local COIN_BATCH = 0.7 -- Coins come in all the time: their "+N" shows at most this often
local LINE_REACH = 28 -- a bit under the server's reach, so an open here always works
local TABLET_DISTANCE = 3.4 -- studs from the tablet's screen to the camera, flown in
local TABLET_FOV = 50
local FLY_IN = TweenInfo.new(0.55, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local FLY_OUT = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
local VIP_TAG = '<font color="#FFD23C">[VIP]</font> '

local player = Players.LocalPlayer
local gui = Kit.getGui()

-- The left column (the counters over the menu buttons) ------------------------
-- Top left, Pet Simulator style. The Roblox chat window sits there too (40% x 25% of
-- the screen, 475 x 275 px at most, plus its input bar): while it's open the column
-- moves down under it, shrinking to fit if it must; with the chat closed (how phones
-- start) it goes back up to the top.

local HUD_TOP = 84 -- canvas units
local HUD_HEIGHT = 560 -- the counters (212), a gap and three rows of menu buttons
local HUD_MARGIN = 20 -- kept clear under the chat and above the screen's bottom
local HUD_MIN_SCALE = 0.6

local leftHud = Kit.new("Frame", {
	Name = "LeftHud",
	Position = UDim2.fromOffset(0, HUD_TOP),
	Size = UDim2.fromOffset(420, HUD_HEIGHT),
	BackgroundTransparency = 1,
	Parent = gui,
})
local leftScale = Kit.new("UIScale", { Parent = leftHud })

-- The bottom of the open chat, in canvas units, or nil. Until the first message only its
-- input bar shows (the window reports no size). Phones and consoles keep the column up
-- top: their chat starts closed, and a column squeezed under it would be too small to tap.
local function chatBottom(): number?
	if (UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled) or GuiService:IsTenFootInterface() then
		return nil
	end
	local ok, active = pcall(StarterGui.GetCore, StarterGui, "ChatActive")
	if ok and active == false then
		return nil
	end
	local bottom: number? = nil
	for _, config in { TextChatService:FindFirstChildOfClass("ChatWindowConfiguration"), TextChatService:FindFirstChildOfClass("ChatInputBarConfiguration") } do
		local shown = config :: any -- (both have Enabled, AbsolutePosition and AbsoluteSize)
		if shown and shown.Enabled and shown.AbsoluteSize.Y > 0 then
			bottom = math.max(bottom or 0, shown.AbsolutePosition.Y + shown.AbsoluteSize.Y)
		end
	end
	if not bottom then
		return nil
	end
	local canvasScale = gui:FindFirstChildOfClass("UIScale")
	return (bottom - gui.AbsolutePosition.Y) / (if canvasScale then canvasScale.Scale else 1)
end

local hudPlace = Vector2.new(HUD_TOP, 1) -- (top, scale) last set
local function placeLeftHud()
	local below = chatBottom()
	local top = if below then math.max(HUD_TOP, below + HUD_MARGIN) else HUD_TOP
	local scale = math.clamp((gui.Size.Y.Offset - HUD_MARGIN - top) / HUD_HEIGHT, HUD_MIN_SCALE, 1)
	if math.abs(top - hudPlace.X) < 1 and math.abs(scale - hudPlace.Y) < 0.01 then
		return
	end
	hudPlace = Vector2.new(top, scale)
	local slide = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(leftHud, slide, { Position = UDim2.fromOffset(0, top) }):Play()
	TweenService:Create(leftScale, slide, { Scale = scale }):Play()
end
task.spawn(function()
	while true do -- (the chat says nothing when it's opened or closed: poll)
		placeLeftHud()
		task.wait(0.5)
	end
end)

-- Counters -------------------------------------------------------------------
-- A glossy striped pill per currency with its icon big over its left end; it counts up
-- smoothly, pops, and floats a "+N" off its right end when it goes up.

local counters = Kit.new("Frame", {
	Name = "Counters",
	Position = UDim2.fromOffset(34, 0),
	Size = UDim2.fromOffset(360, 212),
	BackgroundTransparency = 1,
	Parent = leftHud,
})
Kit.new("UIListLayout", { Padding = UDim.new(0, 16), SortOrder = Enum.SortOrder.LayoutOrder, Parent = counters })

-- A pill that shows a Player attribute, counting up smoothly with a pop.
local function makeCounter(order: number, counter: typeof(COUNTERS[1])): Frame
	local stat = counter.Stat
	local pill = Kit.new("Frame", {
		Name = stat,
		LayoutOrder = order,
		Size = UDim2.fromOffset(236, 60),
		BackgroundColor3 = Kit.White,
		Parent = counters,
	})
	Kit.new("UICorner", { CornerRadius = UDim.new(0.5, 0), Parent = pill })
	Kit.stroke(pill, 4)
	Kit.gradient(pill, counter.Colors)
	Kit.stripes(pill, 0.8, 30)
	Kit.shine(pill, 18)
	-- the icon, big, over the pill's left end
	local bubble = Kit.icon(counter.Icon, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, 12, 0.5, 0),
		Size = UDim2.fromOffset(84, 84),
		ZIndex = 3,
		Parent = pill,
	})
	local label = Kit.text({
		Text = "0",
		Position = UDim2.fromOffset(60, 9),
		Size = UDim2.new(1, -78, 1, -18),
		TextXAlignment = Enum.TextXAlignment.Left,
		StrokeThickness = 3,
		Parent = pill,
	})

	local shown = Instance.new("NumberValue")
	shown.Changed:Connect(function(value)
		label.Text = Format.Number(math.floor(value + 0.5))
	end)
	local last = player:GetAttribute(stat) or 0
	local pending, flushing = 0, false
	local function float(amount: number)
		Kit.floatText(pill, `+{Format.Number(amount)}`, counter.Float, UDim2.new(1, counter.Gap, 0.5, 0))
		Kit.pop(bubble, 0.2)
	end
	local function update()
		local target = player:GetAttribute(stat) or 0
		if target > shown.Value then
			Kit.pop(pill, 0.08)
		end
		local gain = target - last
		last = target
		if gain > 0 and stat == "Coins" then
			-- batched, so a busy factory doesn't flood the screen
			pending += gain
			if not flushing then
				flushing = true
				task.delay(COIN_BATCH, function()
					flushing = false
					float(pending)
					pending = 0
				end)
			end
		elseif gain > 0 then
			float(gain)
		end
		TweenService:Create(shown, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Value = target }):Play()
	end
	player:GetAttributeChangedSignal(stat):Connect(update)
	shown.Value = last
	label.Text = Format.Number(last)
	return pill
end

local pills = {}
for order, counter in COUNTERS do
	pills[counter.Stat] = makeCounter(order, counter)
end

Kit.button({
	AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.new(1, 12, 0.5, 0),
	Size = UDim2.fromOffset(96, 50),
	Parent = pills.Rolls,
}, Kit.Colors.Green, "OPEN", Loot.OpenRoll)
Kit.button({
	AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.new(1, 12, 0.5, 0),
	Size = UDim2.fromOffset(50, 50),
	Parent = pills.Gems,
}, Kit.Colors.Green, nil, function()
	Shop.Open("GEMS")
end, "Plus")

-- Menu buttons ---------------------------------------------------------------

-- Under the counters, two to a row: big glossy squares, each in its menu's hue with
-- faint stripes, their icons bobbing gently.
local buttons = Kit.new("Frame", {
	Name = "MenuButtons",
	Position = UDim2.fromOffset(28, 232),
	Size = UDim2.fromOffset(216, 328),
	BackgroundTransparency = 1,
	Parent = leftHud,
})
Kit.new("UIGridLayout", {
	CellSize = UDim2.fromOffset(100, 100),
	CellPadding = UDim2.fromOffset(14, 14),
	SortOrder = Enum.SortOrder.LayoutOrder,
	Parent = buttons,
})

local bobbing: { GuiObject } = {}
local function menuButton(order: number, icon: string, label: string, hue: Kit.Hue, onClick: () -> ()): TextButton
	local button = Kit.button({ LayoutOrder = order, Parent = buttons }, Kit.pair(hue), nil, onClick)
	Kit.stripes(button, 0.82, 14, 0)
	local glyph = Kit.icon(icon, { Position = UDim2.fromScale(0.12, 0.04), Size = UDim2.fromScale(0.76, 0.62), Parent = button })
	Kit.text({ Text = label, Position = UDim2.fromScale(0.06, 0.66), Size = UDim2.fromScale(0.88, 0.27), Parent = button })
	table.insert(bobbing, glyph)
	return button
end

RunService.RenderStepped:Connect(function()
	local t = os.clock()
	for index, glyph in bobbing do
		glyph.Position = UDim2.new(0.12, 0, 0.04, math.sin(t * 2.2 + index * 0.9) * 3)
		glyph.Rotation = math.sin(t * 1.6 + index) * 4
	end
end)

-- The line you're standing at, if any.
local function nearbyLine(): string?
	local index = player:GetAttribute("PlotIndex")
	local tycoons = workspace:FindFirstChild("Tycoons")
	local plot = index and tycoons and tycoons:FindFirstChild(`Plot{index}`)
	local lines = plot and plot:FindFirstChild("Lines")
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not (lines and root) then
		return nil
	end
	for _, line in lines:GetChildren() do
		local assembler = line:FindFirstChild("Assembler") :: BasePart?
		if assembler and (assembler.Position - root.Position).Magnitude <= LINE_REACH then
			return line.Name
		end
	end
	return nil
end

-- Configuring lines from anywhere is a gamepass perk (RemoteLines); at a line it's free.
local function openLines()
	if player:GetAttribute("Perk_RemoteLines") then
		LineMenu.Open()
		return
	end
	local lineId = nearbyLine()
	if lineId then
		LineMenu.Open(lineId)
		return
	end
	for _, pass in Gamepasses do
		if pass.RemoteLines and pass.Id > 0 then
			MarketplaceService:PromptGamePassPurchase(player, pass.Id)
			return
		end
	end
	Kit.toast("Walk up to a line!", Color3.fromRGB(255, 220, 80), "Factory")
end

menuButton(1, "Factory", "LINES", Kit.Hues.Purple, openLines)
-- (the Album's badge: CLAIM! while a brainrot can be claimed, else NEW! after a new
-- part until it's opened)
local updateAlbumBadge: (seen: boolean?) -> ()
local indexButton = menuButton(2, "Album", "ALBUM", Kit.Hues.Blue, function()
	updateAlbumBadge(true)
	Catalog.Open()
end)
menuButton(3, "Rebirth", "REBIRTH", Kit.Hues.Gold, RebirthMenu.Open)
local wheelButton = menuButton(4, "Wheel", "WHEEL", Kit.Hues.Pink, DailyWheelMenu.Open)
menuButton(5, "Cart", "SHOP", Kit.Hues.Green, function()
	Shop.Open()
end)
-- the achievements (a gold CLAIM! while a tier waits)
AchievementsMenu.Init(menuButton(6, "Trophy", "QUESTS", Kit.Hues.Teal, AchievementsMenu.Open))

task.spawn(function()
	local dev = false
	if RunService:IsStudio() or player.UserId == 114553410 then
		dev = true
	elseif game.CreatorType == Enum.CreatorType.Group then
		-- (GroupService:GetRolesInGroupAsync, its replacement, lists no roles for this
		-- group's owner, so this keeps the older call)
		local ok, rank = pcall((player :: any).GetRankInGroupAsync, player, game.CreatorId)
		dev = ok and rank >= 250
	else
		dev = player.UserId == game.CreatorId
	end
	if dev then
		local DevMenu = require(UI:WaitForChild("DevMenu"))
		menuButton(7, "Wrench", "DEV", Kit.Hues.Red, DevMenu.Open)
	end
end)

SettingsMenu.Init() -- the gear button, top right
DailyLoginMenu.Init() -- the calendar button, under it
WelcomeBackMenu.Init()
MascotMenu.Init() -- opened from the mascot out front

-- A red "!" on the wheel button while a spin is waiting.
local wheelBadge = Kit.text({
	Text = "!",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(1, -8, 0, 8),
	Size = UDim2.fromOffset(36, 36),
	BackgroundTransparency = 0,
	BackgroundColor3 = Color3.fromRGB(235, 60, 60),
	ZIndex = 5,
	Visible = false,
	Parent = wheelButton,
})
Kit.new("UICorner", { CornerRadius = UDim.new(0.5, 0), Parent = wheelBadge })
task.spawn(function()
	while true do
		wheelBadge.Visible = DailyWheelMenu.CanSpin()
		if wheelBadge.Visible then
			Kit.pop(wheelBadge, 0.3) -- (a little pulse, so you notice it)
		end
		task.wait(1)
	end
end)

-- Line prompts ---------------------------------------------------------------

-- Your character stands still while you're at a tablet (anchored on this client only:
-- you own your character's physics, so it just stays put).
local function setFrozen(frozen: boolean)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		root.Anchored = frozen
	end
end

-- Flies the camera onto a line's tablet screen and opens the Line menu right there, as
-- if on the tablet, then flies back once the menu closes.
local atTablet = false
local function useTablet(screen: BasePart, lineId: string)
	if atTablet then
		return
	end
	atTablet = true
	local camera = workspace.CurrentCamera
	local home, homeFov = camera.CFrame, camera.FieldOfView
	local spot = (screen.CFrame * CFrame.new(0, 0, -TABLET_DISTANCE)).Position -- out in front of its screen
	local target = CFrame.lookAt(spot, screen.Position, screen.CFrame.UpVector)
	setFrozen(true)
	camera.CameraType = Enum.CameraType.Scriptable
	Kit.click()
	TweenService:Create(camera, FLY_IN, { CFrame = target, FieldOfView = TABLET_FOV }):Play()
	task.wait(FLY_IN.Time * 0.75)
	LineMenu.Open(lineId)
	-- the menu stays open until you close it (or open another one)
	repeat
		task.wait(0.1)
	until not LineMenu.IsOpen()
	TweenService:Create(camera, FLY_OUT, { CFrame = home, FieldOfView = homeFov }):Play()
	task.wait(FLY_OUT.Time)
	camera.CameraType = Enum.CameraType.Custom
	setFrozen(false)
	atTablet = false
end

-- The part that carries a line's prompt (TycoonManager tags one per zone's machines).
local function findPromptAnchor(line: Instance): BasePart?
	local deadline = os.clock() + 10
	while line.Parent and os.clock() < deadline do
		for _, descendant in line:GetDescendants() do
			if descendant:IsA("BasePart") and descendant:GetAttribute("PromptAnchor") then
				return descendant
			end
		end
		task.wait(0.25)
	end
	return nil
end

local function addLinePrompt(line: Instance)
	local head = findPromptAnchor(line)
	if not head or head:FindFirstChild("ConfigurePrompt") then
		return
	end
	local prompt = Kit.new("ProximityPrompt", {
		Name = "ConfigurePrompt",
		ActionText = "Configure line",
		ObjectText = "Line tablet",
		HoldDuration = 0,
		MaxActivationDistance = 12,
		RequiresLineOfSight = false,
		Parent = head,
	})
	prompt.Triggered:Connect(function()
		task.spawn(useTablet, head, line.Name)
	end)
end

local function watchPlot()
	local index = player:GetAttribute("PlotIndex")
	if not index then
		return
	end
	local plot = workspace:WaitForChild("Tycoons"):WaitForChild(`Plot{index}`)
	local lines = plot:WaitForChild("Lines")
	for _, line in lines:GetChildren() do
		task.spawn(addLinePrompt, line)
	end
	lines.ChildAdded:Connect(function(line)
		task.spawn(addLinePrompt, line)
	end)
end

player:GetAttributeChangedSignal("PlotIndex"):Connect(watchPlot)
task.spawn(watchPlot)

-- A badge on the Album button, pulsing so you notice it: a gold CLAIM! while a brainrot
-- has all 4 parts and waits to be claimed (its morph, gadget and Gems), a red NEW!
-- after a new part until the Album is opened.
local indexBadge = Kit.text({
	Text = "NEW!",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(1, -10, 0, 6),
	Size = UDim2.fromOffset(76, 30),
	BackgroundTransparency = 0,
	BackgroundColor3 = Color3.fromRGB(255, 70, 90),
	StrokeThickness = 2,
	Rotation = 12,
	ZIndex = 5,
	Visible = false,
	Parent = indexButton,
})
Kit.new("UICorner", { CornerRadius = UDim.new(0.5, 0), Parent = indexBadge })
Kit.stroke(indexBadge, 3)
task.spawn(function()
	while true do
		if indexBadge.Visible then
			Kit.pop(indexBadge, 0.35)
			Kit.pop(indexButton, 0.12)
		end
		task.wait(1.2)
	end
end)

local claimable, partsKnown, newParts = 0, -1, false -- (partsKnown -1: the data hasn't loaded yet)
updateAlbumBadge = function(seen: boolean?)
	if seen then
		newParts = false
	end
	indexBadge.Visible = claimable > 0 or newParts
	indexBadge.Text = if claimable > 0 then "CLAIM!" else "NEW!"
	indexBadge.BackgroundColor3 = if claimable > 0 then Color3.fromRGB(255, 185, 30) else Color3.fromRGB(255, 70, 90)
	player:SetAttribute("AlbumClaimable", claimable) -- (this client only: Tralalero's last line reads it)
end

-- New parts and claims show up in open menus right away; a set just finished says so.
Remotes.Event("InventoryUpdated").OnClientEvent:Connect(function(inventory: any)
	LineMenu.Refresh()
	Catalog.Refresh()
	local parts = 0
	for _, owned in (if typeof(inventory) == "table" and typeof(inventory.Parts) == "table" then inventory.Parts else {}) :: any do
		for _ in owned do
			parts += 1
		end
	end
	local ready = Catalog.ClaimableCount(inventory)
	if partsKnown >= 0 then
		newParts = newParts or parts > partsKnown
		if ready > claimable then
			Kit.toast("All 4 parts! CLAIM it in the ALBUM", Color3.fromRGB(255, 220, 80), "Gift")
		end
	end
	partsKnown, claimable = parts, ready
	updateAlbumBadge()
end)

-- Studio: /dev CreateThumb sets workspace's ThumbCamera to the icon shot; the camera
-- holds it (Shift+P for the free camera, which also hides the UI).
workspace:GetAttributeChangedSignal("ThumbCamera"):Connect(function()
	local shot = workspace:GetAttribute("ThumbCamera")
	local camera = workspace.CurrentCamera
	if typeof(shot) == "CFrame" then
		camera.CameraType = Enum.CameraType.Scriptable
		camera.FieldOfView = 70
		camera.CFrame = shot
	else
		camera.CameraType = Enum.CameraType.Custom
	end
end)

-- Big moments from other players (your own get the full banner instead).
Remotes.Event("Announce").OnClientEvent:Connect(function(text: string, color: Color3, from: Player?)
	if from ~= player then
		Kit.toast(text, color, "Sparkle")
	end
end)

-- Purchases & chat -------------------------------------------------------------

-- The server thanks you once a Robux purchase is granted.
Remotes.Event("Purchased").OnClientEvent:Connect(function(text: string)
	Shop.Thanks(text)
end)

-- The join popups, one after the other: what the factory made while you were away, the
-- login streak's calendar (the first join of each day), then a newcomer's Starter Pack
-- offer, which also comes back now and then in the corner while it lasts (Upsell keeps
-- it from nagging). During Tralalero's guide they all wait: they come after the first
-- PERFECT, the guide's gift and its favorite prompt ("GuideTalking"), the line upgrade
-- and the mascot (once it's on a long goal: the Plushie room).
local POPUPS_FIRST, AFTER_GUIDE, AFTER_OFFLINE, AFTER_DAILY, STARTER_EVERY = 6, 6, 2, 20, 300
local function waitForQuiet() -- (no loot reveal or celebration on screen)
	local deadline = os.clock() + 30
	while (gui:FindFirstChild("LootOverlay") or gui:FindFirstChild("Celebration")) and os.clock() < deadline do
		task.wait(0.5)
	end
end
task.spawn(function()
	task.wait(POPUPS_FIRST)
	local function guiding(): boolean -- (nil: the data hasn't loaded yet)
		local step = player:GetAttribute("Guide")
		return step == nil or Guide.Focused(step)
	end
	if guiding() then
		repeat
			player:GetAttributeChangedSignal("Guide"):Wait()
		until not guiding()
		task.wait(AFTER_GUIDE)
		repeat -- (the guide's gift: its line, its reveal, its last line; the favorite prompt)
			waitForQuiet()
			task.wait(4)
		until not (gui:FindFirstChild("LootOverlay") or gui:FindFirstChild("Celebration") or player:GetAttribute("GuideTalking"))
	end
	local deadline = os.clock() + 15 -- (the streak's attributes come with the data)
	while player:GetAttribute("DailyDay") == nil and os.clock() < deadline do
		task.wait(0.5)
	end
	waitForQuiet()
	if WelcomeBackMenu.ShowIfWaiting() then
		task.wait(AFTER_OFFLINE)
		waitForQuiet()
	end
	if DailyLoginMenu.ShowIfReady() then
		task.wait(AFTER_DAILY)
		waitForQuiet()
	end
	Upsell.Featured("StarterPack") -- the big popup, once a session
	task.wait(STARTER_EVERY)
	while true do
		Upsell.Offer("StarterPack", "A Mythic Bombardiro, a Legendary box + 250K Coins!")
		task.wait(STARTER_EVERY)
	end
end)

-- VIPs get a gold tag in chat.
TextChatService.OnIncomingMessage = function(message: TextChatMessage)
	local source = message.TextSource
	local sender = source and Players:GetPlayerByUserId(source.UserId)
	if sender and sender:GetAttribute("Pass_VIP") then
		local properties = Instance.new("TextChatMessageProperties")
		properties.PrefixText = VIP_TAG .. message.PrefixText
		return properties
	end
	return nil
end
