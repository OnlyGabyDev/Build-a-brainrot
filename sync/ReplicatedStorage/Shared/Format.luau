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

return Format
