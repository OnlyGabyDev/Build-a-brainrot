--[[
	MascotMenu
	The company mascot's menu (GDD §10, Config/Mascot), opened from the mascot's prompt
	out front (Services/MascotManager sends "Open"): the brainrot turning on a card, its
	level, "Levels up every time you REBIRTH!", what it gives now and at the next rebirth
	(Coins, line speed, luck) and the look the next level adds. Its owner builds it part
	by part (any part they own, mixes allowed) and has a REBIRTH button; anyone else just
	looks. Also plays the fanfare when a mascot levels up and the fireworks over the big
	ones (tag "MascotFireworks"). Client only.
]]

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Client = ReplicatedStorage:WaitForChild("Client")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local BrainrotModels = require(Shared:WaitForChild("BrainrotModels"))
local Brainrots = require(Config:WaitForChild("Brainrots"))
local Effects = require(Client:WaitForChild("Effects"))
local MascotConfig = require(Config:WaitForChild("Mascot"))
local Rebirths = require(Config:WaitForChild("Rebirths"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Sounds = require(Config:WaitForChild("Sounds"))
local Kit = require(script.Parent:WaitForChild("Kit"))
local RebirthMenu = require(script.Parent:WaitForChild("RebirthMenu"))

local SIZE = Vector2.new(900, 560)
local GOLD = Color3.fromRGB(255, 215, 60)
local GOOD_COLOR = Color3.fromRGB(120, 245, 110)
local BAD_COLOR = Color3.fromRGB(255, 90, 90)
local MUTED = Color3.fromRGB(255, 235, 250)
local HUE = Kit.Hues.Pink
local STAGE_NAMES = {
	BigCrate = "A BIGGER CRATE",
	Pedestal = "A MARBLE PEDESTAL",
	Spotlights = "SPOTLIGHTS",
	Banners = "BANNERS",
	Gold = "GOLD TRIMS",
	Fountain = "A FOUNTAIN",
	Fireworks = "FIREWORKS",
}
local FIREWORKS = { Every = 4.5, Range = 170, Colors = { Color3.fromRGB(255, 90, 120), Color3.fromRGB(255, 215, 60), Color3.fromRGB(110, 220, 255), Color3.fromRGB(150, 255, 140), Color3.fromRGB(220, 130, 255) } }

type Info = {
	OwnerId: number,
	OwnerName: string,
	Level: number,
	Parts: { [string]: string },
	Upgrades: Rebirths.Levels,
	Mine: boolean,
}

local panel: Frame? = nil
local content: Frame? = nil
local body: Frame? = nil
local shown: Info? = nil
local inventory: any = nil
local stops: { () -> () } = {}

local MascotMenu = {}

local function percent(value: number): string
	return `+{math.floor(value * 100 + 0.5)}%`
end

-- What a mascot of `level` gives: { icon, name, value } rows.
local function bonuses(level: number, upgrades: Rebirths.Levels): { { string } }
	return {
		{ "Coin", "COINS", percent(Rebirths.IncomeMultiplier(level, upgrades) - 1) },
		{ "Lightning", "SPEED", percent(Rebirths.SpeedMultiplier(level, upgrades) - 1) },
		{ "Clover", "LUCK", percent(Rebirths.Luck(level, upgrades)) },
	}
end

-- The look the next level adds, if any: "LV 3: SPOTLIGHTS".
local function nextLook(level: number): string?
	local best: number?, name: string? = nil, nil
	for key, at in MascotConfig.Stages do
		if at > level and (best == nil or at < best) then
			best, name = at, STAGE_NAMES[key]
		end
	end
	return if best and name then `LV {best}: {name}` else nil
end

-- The brainrot ids whose `partType` you own, in roster order.
local function owned(partType: string): { string }
	local list = {}
	local parts = inventory and inventory.Parts or {}
	for _, brainrot in Brainrots.List do
		local have = parts[brainrot.Id]
		if have and have[partType] then
			table.insert(list, brainrot.Id)
		end
	end
	return list
end

local render: () -> ()

-- Swaps one part for the next (or previous) one you own; the server rebuilds the
-- mascot out front.
local function cycle(partType: string, step: number)
	local info = shown
	if not (info and info.Mine) then
		return
	end
	local list = owned(partType)
	if #list < 2 then
		Kit.toast("Get more parts to mix it!", BAD_COLOR, "Puzzle")
		return
	end
	local index = table.find(list, info.Parts[partType]) or 1
	local pick = list[(index - 1 + step) % #list + 1]
	local before = info.Parts[partType]
	info.Parts[partType] = pick
	render()
	Kit.playSound(Sounds.Pop, 0.4, 1.2)
	local remote = Remotes.Function("SetMascotPart")
	local ok, done = pcall(remote.InvokeServer, remote, partType, pick)
	if not (ok and done) and shown == info then
		info.Parts[partType] = before
		render()
		Kit.toast("Try again!", BAD_COLOR, "Warning")
	end
end

local function renderBrainrot(parent: Frame, info: Info)
	local card = Kit.new("Frame", {
		Position = UDim2.fromOffset(20, 8),
		Size = UDim2.fromOffset(400, 300),
		BackgroundColor3 = Kit.White,
		ZIndex = 3,
		Parent = parent,
	})
	Kit.corner(card, 22)
	Kit.stroke(card, 4)
	Kit.gradient(card, { HUE.Light, HUE.Main })
	Kit.stripes(card, 0.82, 22, 3)
	table.insert(stops, Kit.rays(card, Color3.fromRGB(255, 240, 250), 420, 3))
	local model = BrainrotModels.Build(info.Parts)
	local viewport = Kit.viewport({ Size = UDim2.fromScale(1, 1), ZIndex = 4, Parent = card }, model)
	table.insert(stops, Kit.orbit(viewport, model))

	for index, partType in Brainrots.PartTypes do
		local y = 318 + (index - 1) * 42
		local row = Kit.new("Frame", {
			Position = UDim2.fromOffset(20, y),
			Size = UDim2.fromOffset(400, 38),
			BackgroundColor3 = Kit.Outline,
			BackgroundTransparency = 0.6,
			ZIndex = 3,
			Parent = parent,
		})
		Kit.corner(row, 12)
		Kit.text({ Text = string.upper(partType), Position = UDim2.fromOffset(10, 4), Size = UDim2.fromOffset(80, 30), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = GOLD, ZIndex = 4, Parent = row })
		local brainrot = Brainrots.ById[info.Parts[partType]]
		Kit.text({ Text = if brainrot then brainrot.Name else "?", Position = UDim2.fromOffset(140, 5), Size = UDim2.fromOffset(200, 28), ZIndex = 4, Parent = row })
		if info.Mine then
			for _, spec in { { -1, 100 }, { 1, 350 } } do
				Kit.button({
					Position = UDim2.fromOffset(spec[2], 1),
					Size = UDim2.fromOffset(40, 36),
					ZIndex = 5,
					Parent = row,
				}, Kit.pair(HUE), if spec[1] < 0 then "<" else ">", function()
					task.spawn(cycle, partType, spec[1])
				end)
			end
		end
	end
end

local function renderLevel(parent: Frame, info: Info)
	local x = 440
	Kit.text({
		Text = `LEVEL {info.Level}`,
		TextColor3 = GOLD,
		Position = UDim2.fromOffset(x, 4),
		Size = UDim2.fromOffset(440, 52),
		StrokeThickness = 3.5,
		ZIndex = 3,
		Parent = parent,
	})
	Kit.iconText({
		Position = UDim2.fromOffset(x, 60),
		Size = UDim2.fromOffset(440, 30),
		ZIndex = 3,
		Parent = parent,
	}, "Rebirth", "Levels up every time you REBIRTH!")
	for _, spec in { { "NOW", 584 }, { "NEXT REBIRTH", 734 } } do
		Kit.text({ Text = spec[1], TextColor3 = MUTED, Position = UDim2.fromOffset(spec[2] - 20, 100), Size = UDim2.fromOffset(150, 24), ZIndex = 3, Parent = parent })
	end
	local now, nextUp = bonuses(info.Level, info.Upgrades), bonuses(info.Level + 1, info.Upgrades)
	for index, row in now do
		local card = Kit.new("Frame", {
			Position = UDim2.fromOffset(x, 128 + (index - 1) * 66),
			Size = UDim2.fromOffset(440, 58),
			BackgroundColor3 = Kit.White,
			ZIndex = 3,
			Parent = parent,
		})
		Kit.corner(card, 16)
		Kit.stroke(card, 3.5)
		Kit.gradient(card, Kit.pair(HUE))
		Kit.stripes(card, 0.85, 16, 3)
		Kit.icon(row[1], { Position = UDim2.fromOffset(6, 4), Size = UDim2.fromOffset(50, 50), ZIndex = 4, Parent = card })
		Kit.text({ Text = row[2], Position = UDim2.fromOffset(60, 12), Size = UDim2.fromOffset(100, 34), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 4, Parent = card })
		Kit.text({ Text = row[3], Position = UDim2.fromOffset(164, 10), Size = UDim2.fromOffset(110, 38), ZIndex = 4, Parent = card })
		Kit.icon("Arrow", { Position = UDim2.fromOffset(276, 14), Size = UDim2.fromOffset(30, 30), ZIndex = 4, Parent = card })
		Kit.text({ Text = nextUp[index][3], TextColor3 = GOOD_COLOR, Position = UDim2.fromOffset(310, 10), Size = UDim2.fromOffset(120, 38), ZIndex = 4, Parent = card })
	end
	local look = nextLook(info.Level)
	if look then
		Kit.iconText({
			Position = UDim2.fromOffset(x, 334),
			Size = UDim2.fromOffset(440, 30),
			ZIndex = 3,
			Parent = parent,
		}, "Sparkle", `Next look: {look}`, GOLD)
	end
	if info.Mine then
		Kit.button({
			Position = UDim2.fromOffset(x + 40, 390),
			Size = UDim2.fromOffset(360, 74),
			ZIndex = 4,
			Parent = parent,
		}, Kit.pair(Kit.Hues.Gold), "REBIRTH", function()
			if panel then
				Kit.close(panel)
			end
			RebirthMenu.Open()
		end, "Rebirth")
	else
		Kit.text({
			Text = `{string.upper(info.OwnerName)}'S MASCOT`,
			Position = UDim2.fromOffset(x, 400),
			Size = UDim2.fromOffset(440, 40),
			ZIndex = 3,
			Parent = parent,
		})
	end
end

render = function()
	for _, stop in stops do
		stop()
	end
	table.clear(stops)
	if body then
		body:Destroy()
		body = nil
	end
	local info = shown
	if not (info and content) then
		return
	end
	local frame = Kit.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 2, Parent = content })
	body = frame
	renderBrainrot(frame, info)
	renderLevel(frame, info)
end

function MascotMenu.Open(info: Info)
	if not panel then
		local newPanel, newContent = Kit.modal("Mascot", "MASCOT", HUE, SIZE, "Crown")
		panel, content = newPanel, newContent
		newPanel:GetPropertyChangedSignal("Visible"):Connect(function()
			if not newPanel.Visible then
				for _, stop in stops do
					stop()
				end
				table.clear(stops)
			end
		end)
	end
	shown = info
	local title = (panel :: Frame):FindFirstChild("Title", true)
	if title and title:IsA("TextLabel") then
		title.Text = if info.Mine then "YOUR MASCOT" else `{string.upper(info.OwnerName)}'S MASCOT`
	end
	Kit.open(panel :: Frame)
	render()
	if info.Mine then
		task.spawn(function()
			local ok, result = pcall(function()
				return Remotes.Function("GetInventory"):InvokeServer()
			end)
			if ok and result then
				inventory = result
			end
		end)
	end
end

function MascotMenu.Init()
	Remotes.Event("Mascot").OnClientEvent:Connect(function(action: string, payload: any, level: number?)
		if action == "Open" then
			MascotMenu.Open(payload)
		elseif action == "LevelUp" and typeof(payload) == "Vector3" and Effects.near(payload, 200) then
			-- a fanfare round a mascot that just leveled up
			Effects.confetti(payload, 50)
			Effects.sparkle(payload, GOLD, 50, 26)
			Effects.flash(payload, GOLD, 6, 40, 0.8)
			Effects.ring(payload - Vector3.new(0, 2, 0), GOLD, 12, 0.7)
			Effects.sound(payload, Sounds.RevealBig, 0.6)
			if level then
				Effects.popup(payload + Vector3.new(0, 3, 0), `LEVEL {level}!`, GOLD, 4, 2)
			end
		end
	end)
	Remotes.Event("InventoryUpdated").OnClientEvent:Connect(function(newInventory)
		inventory = newInventory
	end)
	-- fireworks over the big mascots near you, now and then
	task.spawn(function()
		while true do
			task.wait(FIREWORKS.Every)
			for _, stand in CollectionService:GetTagged("MascotFireworks") do
				if stand:IsA("Model") and stand.Parent then
					local top = stand:GetAttribute("Top")
					local at = stand:GetPivot().Position + Vector3.new(math.random(-6, 6), (if typeof(top) == "number" then top else 10) + math.random(10, 18), math.random(-6, 6))
					if Effects.near(at, FIREWORKS.Range) then
						local color = FIREWORKS.Colors[math.random(1, #FIREWORKS.Colors)]
						Effects.sparkle(at, color, 45, 32)
						Effects.flash(at, color, 5, 50, 0.5)
						Effects.sound(at, Sounds.Boom, 0.25, 1.8)
					end
				end
			end
		end
	end)
end

return MascotMenu
