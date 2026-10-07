--[[
	GuideManager
	Tralalero's guide (Config/Guide, GDD §2): walks each newcomer through their first
	steps. The step lives in the player's data (DataManager.SetGuideStep, which sets the
	"Guide" attribute the client follows); this module checks each step's goal, pays its
	reward and tells the client where to point: the "GuideTarget" attribute (a world
	position on the ground), "GuideLift" (how high over it the arrow floats) and
	"GuideRing" (the glowing ring round it, across; 0 for none). Short of Coins for a
	button, with enough waiting on the Cash Pad, it points there first ("GuideSay":
	the step or hint whose line Tralalero says meanwhile, "Collect"); and to the line
	("Watch") while the pad waits for its first Coins. A step
	whose goal is already met (done out of order) passes at once, still paid.
	  * Intro: the client flies the camera onto the factory, then says so (remote Guide);
	    the server moves on by itself after INTRO_TIMEOUT in case it never does.
	  * Free, Body, Arms, Legs: that button of the first line bought.
	  * Collect: the Cash Pad banked (TycoonManager.Collected); passes with Auto-Collect.
	  * Box: any loot box opened (LootManager.BoxOpened); a gift box of their own lands in
	    their front yard to point at.
	  * Perfect: any brainrot completed; the first line gets the starter's 4 parts first
	    if it isn't building a full one (Rolls opened before the first dropper).
	At the end: a new Rare+ part (Guide.FinalRank, once: the "GuideGift" claim), which
	the client reveals after the completion banner.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Brainrots = require(Shared.Config.Brainrots)
local Guide = require(Shared.Config.Guide)
local LineLayouts = require(Shared.LineLayouts)
local Remotes = require(Shared.Remotes)
local TycoonItems = require(Shared.Config.TycoonItems)

local DataManager = require(script.Parent.DataManager)
local LootManager = require(script.Parent.LootManager)
local MonetizationManager = require(script.Parent.MonetizationManager)
local ProductionManager = require(script.Parent.ProductionManager)
local TycoonManager = require(script.Parent.TycoonManager)

local TICK = 0.25 -- seconds between goal checks
local INTRO_TIMEOUT = 25 -- seconds
local STEP_GAP = 1.2 -- seconds a finished step's reward shows before the next goal
local GIFT_RETRY = 5 -- seconds between gift boxes, if one goes (someone else opened it)
-- the arrow's height over each kind of goal, and the ring round it (across)
local BUTTON_LIFT, BUTTON_RING = 6.5, 7.4
local PAD_LIFT, PAD_RING = 6, 11
local BOX_LIFT, BOX_RING = 7, 6.5
local BOX_HEIGHT = 1.5 -- a box's middle over the ground (LootManager)
local LINE_LIFT = 16 -- over the chute, where the brainrot comes out

type State = {
	Since: number, -- os.clock() the current step began
	Collected: boolean,
	BoxOpened: boolean,
	GiftBox: number?,
	GiftAt: Vector3?,
	GiftTried: number,
	Waiting: boolean, -- between a step's reward and the next goal
	Ensured: boolean, -- the Perfect step's line checked
}

local states: { [Player]: State } = {}
local guideRemote: RemoteEvent

local GuideManager = {}

local function buttonId(step: Guide.Step): string?
	return if step.Button then `{Guide.LineId}_{step.Button}` else nil
end

local function goalMet(player: Player, data: DataManager.PlayerData, state: State, step: Guide.Step): boolean
	local itemId = buttonId(step)
	if itemId then
		return data.Tycoon.Purchased[itemId] == true
	elseif step.Id == "Collect" then
		return state.Collected or MonetizationManager.HasPerk(player, "AutoCollect")
	elseif step.Id == "Box" then
		return state.BoxOpened
	elseif step.Id == "Perfect" then
		return data.Stats.Perfects > 0
	elseif step.Id == "Intro" then
		return os.clock() - state.Since > INTRO_TIMEOUT
	end
	return false
end

-- The guide's line's chute, where its brainrots come out.
local function lineShip(plot: TycoonManager.Plot): Vector3
	local line = TycoonItems.LinesById[Guide.LineId]
	return (TycoonManager.LineOrigin(plot, Guide.LineId) * LineLayouts.For(line.Zone).Ship).Position
end

-- Where the arrow points for this step (nil: nowhere), how high over it, the ring, and
-- another step's line to say meanwhile.
local function targetOf(player: Player, state: State, step: Guide.Step): (Vector3?, number, number, string?)
	local plot = TycoonManager.GetPlot(player)
	if not plot then
		return nil, 0, 0
	end
	local itemId = buttonId(step)
	if itemId then
		-- short of Coins, with enough on the Cash Pad: grab them first
		local coins = DataManager.GetCurrency(player, "Coins")
		local price = TycoonItems.ById[itemId].Price
		if coins < price and coins + plot.Collected >= price then
			return plot.CashPad.Position, PAD_LIFT, PAD_RING, "Collect"
		end
		local button = plot.Buttons[itemId]
		return if button then button.Position else nil, BUTTON_LIFT, BUTTON_RING
	elseif step.Id == "Collect" and plot.Collected == 0 then
		-- (nothing to grab yet: watch the first brainrot being built)
		return lineShip(plot), LINE_LIFT, 0, "Watch"
	elseif step.Id == "Collect" then
		return plot.CashPad.Position, PAD_LIFT, PAD_RING
	elseif step.Id == "Box" then
		return if state.GiftAt then state.GiftAt - Vector3.new(0, BOX_HEIGHT, 0) else nil, BOX_LIFT, BOX_RING
	elseif step.Id == "Perfect" then
		return lineShip(plot), LINE_LIFT, 0
	end
	return nil, 0, 0
end

local function setTarget(player: Player, target: Vector3?, lift: number, ring: number, say: string?)
	if player:GetAttribute("GuideSay") ~= say then
		player:SetAttribute("GuideSay", say)
	end
	if (player:GetAttribute("GuideTarget") :: Vector3?) ~= target then
		player:SetAttribute("GuideTarget", target)
	end
	if player:GetAttribute("GuideLift") ~= lift then
		player:SetAttribute("GuideLift", lift)
	end
	if player:GetAttribute("GuideRing") ~= ring then
		player:SetAttribute("GuideRing", ring)
	end
end

-- The Box step's gift box: one of their own in the front yard (again if it went).
local function keepGiftBox(player: Player, state: State)
	if state.GiftBox and LootManager.HasBox(state.GiftBox) then
		return
	end
	if os.clock() - state.GiftTried < GIFT_RETRY then
		return
	end
	state.GiftTried = os.clock()
	state.GiftBox, state.GiftAt = LootManager.GiftBox(player)
end

-- The guide's last gift: a new Rare+ part, once.
local function giveGift(player: Player)
	if not DataManager.Claim(player, "GuideGift") then
		return
	end
	local result = LootManager.GrantRarePart(player, Guide.FinalRank, "Gift")
	if result then
		guideRemote:FireClient(player, "Gift", result)
	end
end

local function finish(player: Player, state: State, step: Guide.Step)
	if step.Coins then
		DataManager.AddCurrency(player, "Coins", step.Coins)
	end
	if step.Rolls then
		DataManager.AddRolls(player, step.Rolls)
	end
	if step.Id ~= "Intro" then
		guideRemote:FireClient(player, "Reward", step.Id, step.Coins or 0, step.Rolls or 0)
	end
	-- the reward shows a moment before the next goal (the intro hands straight over)
	state.Waiting = true
	setTarget(player, nil, 0, 0)
	task.delay(if step.Id == "Intro" then 0 else STEP_GAP, function()
		state.Waiting = false
		if states[player] ~= state then
			return
		end
		local nextStep = Guide.Next(step.Id)
		DataManager.SetGuideStep(player, nextStep)
		state.Since = os.clock()
		if nextStep == Guide.Done then
			states[player] = nil
			TycoonManager.RefreshButtons(player) -- every button shows again
			giveGift(player)
		end
	end)
end

local function update(player: Player, state: State)
	local data = DataManager.GetData(player)
	if state.Waiting or not data or not Guide.Running(data.Guide) then
		return
	end
	local step = Guide.ById[data.Guide]
	if not step then
		return
	end
	if goalMet(player, data, state, step) then
		finish(player, state, step)
		return
	end
	if step.Id == "Box" then
		keepGiftBox(player, state)
	elseif step.Id == "Perfect" and not state.Ensured then
		state.Ensured = true
		ProductionManager.EnsureFullMatch(player, Guide.LineId, Brainrots.StarterId)
	end
	setTarget(player, targetOf(player, state, step))
end

local function onLoaded(player: Player)
	local data = DataManager.GetData(player)
	if not (data and Guide.Running(data.Guide)) then
		return
	end
	local state: State = {
		Since = os.clock(),
		Collected = false,
		BoxOpened = false,
		GiftBox = nil,
		GiftAt = nil,
		GiftTried = -math.huge,
		Waiting = false,
		Ensured = false,
	}
	states[player] = state
	-- (the intro's timeout runs from the spawn: the world may still be building)
	player.CharacterAdded:Connect(function()
		state.Since = os.clock()
	end)
end

function GuideManager.Init()
	guideRemote = Remotes.Event("Guide")
	Remotes.Event("Spawned") -- (made now: the client waits for it)

	guideRemote.OnServerEvent:Connect(function(player: Player, action: unknown)
		local data = DataManager.GetData(player)
		local state = states[player]
		if action == "Intro" and data and state and data.Guide == "Intro" and not state.Waiting then
			finish(player, state, Guide.ById.Intro)
		end
	end)
	TycoonManager.Collected.Event:Connect(function(player: Player)
		local state = states[player]
		if state then
			state.Collected = true
		end
	end)
	LootManager.BoxOpened.Event:Connect(function(player: Player)
		local state = states[player]
		if state then
			state.BoxOpened = true
		end
	end)

	DataManager.OnPlayerLoaded(onLoaded)
	Players.PlayerRemoving:Connect(function(player)
		states[player] = nil
	end)
	task.spawn(function()
		while true do
			task.wait(TICK)
			for player, state in states do
				update(player, state)
			end
		end
	end)
end

-- Studio testing (DevTools' Guide): puts the player on a step ("Intro" starts over;
-- the gift can come again).
function GuideManager.DevSetStep(player: Player, step: string): boolean
	if not DataManager.SetGuideStep(player, step) then
		return false
	end
	DataManager.DevUnclaim(player, "GuideGift")
	states[player] = nil
	onLoaded(player)
	TycoonManager.RefreshButtons(player)
	return true
end

return GuideManager
