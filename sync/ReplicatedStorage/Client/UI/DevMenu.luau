local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes"))
local Kit = require(script.Parent:WaitForChild("Kit"))

local DevMenu = {}

local panel, content = Kit.modal("DevMenu", "DEV MENU", Kit.Hues.Red, Vector2.new(660, 560), "Wrench")

local targetBox = Kit.new("TextBox", {
	PlaceholderText = "Target Username (blank for self)",
	Position = UDim2.fromOffset(40, 20),
	Size = UDim2.new(1, -80, 0, 50),
	BackgroundColor3 = Kit.White,
	TextScaled = true,
	TextColor3 = Kit.Outline,
	Font = Kit.Font,
	Parent = content,
})
Kit.corner(targetBox, 10)
Kit.stroke(targetBox, 3)

local function getTargetUserId(): number
	local name = string.lower(targetBox.Text)
	if name == "" then return 0 end
	for _, p in Players:GetPlayers() do
		if string.lower(p.Name) == name or string.lower(p.DisplayName) == name then
			return p.UserId
		end
	end
	return -1
end

local actionsFrame = Kit.new("ScrollingFrame", {
	Position = UDim2.fromOffset(40, 90),
	Size = UDim2.new(1, -80, 1, -110),
	BackgroundTransparency = 1,
	ScrollBarThickness = 8,
	Parent = content,
})
Kit.new("UIListLayout", {
	Padding = UDim.new(0, 14),
	SortOrder = Enum.SortOrder.LayoutOrder,
	Parent = actionsFrame,
})

local layoutOrder = 0
local function addAction(label: string, action: string, args: {any}, colors: {Color3})
	layoutOrder += 1
	Kit.button({
		Size = UDim2.new(1, -16, 0, 56),
		LayoutOrder = layoutOrder,
		Parent = actionsFrame,
	}, colors, label, function()
		local targetId = getTargetUserId()
		if targetId == -1 then
			Kit.toast("Player not found!", Kit.Colors.Red[1])
			return
		end
		local ok = Remotes.Function("DevMenu"):InvokeServer(targetId, action, table.unpack(args))
		if ok then
			Kit.toast(`Ran {action}!`, Kit.Colors.Green[1])
		else
			Kit.toast(`Failed to run {action}`, Kit.Colors.Red[1])
		end
	end)
end

addAction("Give 1M Coins", "AddCoins", {1000000}, Kit.Colors.Coins)
addAction("Give 10K Gems", "AddGems", {10000}, Kit.Colors.Gems)
addAction("Give 10 Rolls", "AddRolls", {10}, Kit.Colors.Rolls)
addAction("Give Sprint Pass", "GrantPass", {"Sprint"}, Kit.Colors.Green)
addAction("Give Auto-Collect Pass", "GrantPass", {"AutoCollect"}, Kit.Colors.Green)
addAction("Unlock All Brainrots", "GiveBrainrots", {}, Kit.Colors.Purple)
addAction("Spawn 3 Godly Boxes", "SpawnBox", {"Godly", 3}, Kit.Colors.Purple)
addAction("Spawn 3 Common Boxes", "SpawnBox", {"Common", 3}, Kit.Colors.Grey)
addAction("Loot Rain in 10s", "LootRain", {10}, Kit.Colors.Gems)
addAction("Nuke Server", "Nuke", {}, Kit.Colors.Red)
addAction("Create Thumbnail Stage", "CreateThumb", {}, Kit.Colors.Panel)

-- Automatically update canvas size for scrolling
actionsFrame.ChildAdded:Connect(function()
	task.wait()
	local list = actionsFrame:FindFirstChildOfClass("UIListLayout")
	if list then
		actionsFrame.CanvasSize = UDim2.new(0, 0, 0, list.AbsoluteContentSize.Y + 20)
	end
end)

function DevMenu.Open()
	Kit.open(panel)
end

function DevMenu.IsOpen()
	return panel.Visible
end

return DevMenu
