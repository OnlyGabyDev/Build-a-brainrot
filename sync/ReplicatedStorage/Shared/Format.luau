-- Number formatting shared by server billboards and client UI.

local SUFFIXES = { "", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc" }

local Format = {}

-- 999 -> "999", 1234 -> "1.2K", 56789 -> "56.7K", 123456789 -> "123M"
function Format.Number(value: number): string
	local tier = 1
	while value >= 1000 and tier < #SUFFIXES do
		value /= 1000
		tier += 1
	end
	if tier == 1 then
		return tostring(math.floor(value))
	end
	-- Truncate instead of rounding so 999.95K never shows as "1000K".
	local text = if value < 100 then string.format("%.1f", math.floor(value * 10) / 10) else tostring(math.floor(value))
	text = string.gsub(text, "%.0$", "")
	return text .. SUFFIXES[tier]
end

-- 450 -> "450 ", 2499 -> "2,499 ": the amount, then Roblox's Robux icon (the
-- private-use character U+E002, which Roblox draws as the icon in any font).
Format.ROBUX = utf8.char(0xE002)
function Format.Robux(amount: number): string
	local digits = tostring(math.floor(amount))
	local grouped = string.gsub(string.reverse(digits), "(%d%d%d)", "%1,")
	grouped = string.gsub(string.reverse(grouped), "^,", "")
	return `{grouped} {Format.ROBUX}`
end

return Format
