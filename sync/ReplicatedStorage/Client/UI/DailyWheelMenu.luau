--[[
	Daily Wheel menu (GDD §12): when the next free spin is ready, how many bought spins
	you have, and every prize with its odds. SPIN asks the server for a prize, then
	opens straight onto it (no spinning reel).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local DailyWheel = require(Shared:WaitForChild("Config"):WaitForChild("DailyWheel"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Sounds = require(Shared:WaitForChild("Config"):WaitForChild("Sounds"))
local Kit = require(script.Parent:WaitForChild("Kit"))
local Loot = require(script.Parent:WaitForChild("Loot"))
local Shop = require(script.Parent:WaitForChild("Shop"))

local SIZE = Vector2.new(640, 600)
local GOLD_COLOR = Color3.fromRGB(255, 215, 60)
local GOOD_COLOR = Color3.fromRGB(120, 245, 110)
local BAD_COLOR = Color3.fromRGB(255, 90, 90)
local KIND_COLORS = {
	Coins = Color3.fromRGB(255, 200, 50),
	Gems = Color3.fromRGB(80, 200, 255),
	Rolls = Color3.fromRGB(255, 120, 220),
	LuckBoost = Color3.fromRGB(110, 230, 110),
}
local JACKPOT_COLOR = Color3.fromRGB(170, 90, 255)

local player = Players.LocalPlayer
local panel: Frame? = nil
local content: Frame? = nil
local statusLabel: TextLabel? = nil
local spinning = false

local DailyWheelMenu = {}

-- Seconds until the next free spin (0 = ready now). Server time, so clocks agree.
local function secondsToFree(): number
	local nextFree = player:GetAttribute("WheelNextFree") or 0
	return math.max(0, nextFree - workspace:GetServerTimeNow())
end

function DailyWheelMenu.CanSpin(): boolean
	return secondsToFree() <= 0 or (player:GetAttribute("WheelSpins") or 0) > 0
end

local function statusText(): string
	local wait = secondsToFree()
	local spins = player:GetAttribute("WheelSpins") or 0
	local free = if wait <= 0
		then "🎁 FREE SPIN READY!"
		else `Next free spin in {math.floor(wait / 3600)}h {math.floor(wait % 3600 / 60)}m {math.floor(wait % 60)}s`
	return `{free}   ·   🎡 {spins} bought`
end

local function spin()
	if spinning then
		return
	end
	if not DailyWheelMenu.CanSpin() then
		Kit.toast("No spins left! Come back later or grab more in the shop.", BAD_COLOR)
		return
	end
	spinning = true
	local remote = Remotes.Function("SpinDailyWheel")
	local ok, index, text = pcall(remote.InvokeServer, remote)
	if not (ok and index) then
		spinning = false
		Kit.toast("Couldn't spin. Try again!", BAD_COLOR)
		return
	end
	if panel then
		Kit.close(panel)
	end

	local prize = DailyWheel.Prizes[index]
	local color = if prize.Id == "Jackpot" then JACKPOT_COLOR else KIND_COLORS[prize.Kind] or GOLD_COLOR
	local screen = Loot.Overlay(color)
	local stopRays = Kit.rays(screen, color, 560, 31)
	local icon = Kit.text({
		Text = prize.Icon,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.4),
		Size = UDim2.fromOffset(200, 200),
		StrokeThickness = 0,
		ZIndex = 50,
		Parent = screen,
	})
	local label = Kit.text({
		Text = text or prize.Label,
		TextColor3 = GOLD_COLOR,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.62),
		Size = UDim2.fromOffset(800, 110),
		StrokeThickness = 5,
		ZIndex = 50,
		Parent = screen,
	})
	Kit.pop(icon, 0.6)
	Kit.pop(label, 0.6)
	Kit.playSound(if prize.Id == "Jackpot" then Sounds.RevealBig else Sounds.Reveal, 0.5)
	Kit.confetti(screen, { GOLD_COLOR, GOOD_COLOR, Color3.fromRGB(120, 220, 255), Color3.fromRGB(255, 120, 220) }, if prize.Id == "Jackpot" then 140 else 60, 49)
	task.wait(2.5)
	stopRays()
	screen:Destroy()
	spinning = false
end

local function render(parent: Frame)
	parent:ClearAllChildren()
	statusLabel = Kit.text({
		Text = statusText(),
		Position = UDim2.fromOffset(24, 14),
		Size = UDim2.new(1, -48, 0, 34),
		Parent = parent,
	})

	Kit.text({ Text = "PRIZES", TextColor3 = GOLD_COLOR, Position = UDim2.fromOffset(24, 58), Size = UDim2.fromOffset(300, 30), TextXAlignment = Enum.TextXAlignment.Left, Parent = parent })
	local total = 0
	for _, prize in DailyWheel.Prizes do
		total += prize.Weight
	end
	for index, prize in DailyWheel.Prizes do
		local row = Kit.new("Frame", {
			Position = UDim2.fromOffset(24, 94 + (index - 1) * 44),
			Size = UDim2.new(1, -48, 0, 38),
			BackgroundColor3 = if prize.Id == "Jackpot" then JACKPOT_COLOR else KIND_COLORS[prize.Kind] or Kit.White,
			Parent = parent,
		})
		Kit.corner(row, 12)
		Kit.stroke(row, 3)
		Kit.text({ Text = `{prize.Icon}  {prize.Label}`, Position = UDim2.fromOffset(14, 5), Size = UDim2.new(0.7, -14, 1, -10), TextXAlignment = Enum.TextXAlignment.Left, Parent = row })
		Kit.text({
			Text = string.format("%.0f%%", prize.Weight / total * 100),
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -14, 0, 5),
			Size = UDim2.new(0.3, -14, 1, -10),
			TextXAlignment = Enum.TextXAlignment.Right,
			Parent = row,
		})
	end

	Kit.button({ Position = UDim2.fromOffset(24, 418), Size = UDim2.fromOffset(280, 64), Parent = parent }, Kit.Colors.Green, "🎡 SPIN!", function()
		task.spawn(spin)
	end)
	Kit.button({ Position = UDim2.fromOffset(328, 418), Size = UDim2.fromOffset(288, 64), Parent = parent }, Kit.Colors.Coins, "🛒 MORE SPINS", function()
		Shop.Open("SPINS")
	end)
end

function DailyWheelMenu.Open()
	if not panel then
		local newPanel, newContent = Kit.modal("DailyWheel", "🎡 DAILY WHEEL", Kit.Colors.Rolls, SIZE)
		panel, content = newPanel, newContent
		-- Keep the countdown ticking while the menu is open.
		task.spawn(function()
			while true do
				task.wait(1)
				if panel and panel.Visible and statusLabel then
					statusLabel.Text = statusText()
				end
			end
		end)
	end
	render(content :: Frame)
	Kit.open(panel :: Frame)
end

return DailyWheelMenu
