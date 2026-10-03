--[[
	Vector3 and CFrame for the lab: thin wrappers round Lune's (which do all the math),
	because Lune's types can't be multiplied with the number first (`2 * vector`), and
	their metatables are locked. Every result that's a Vector3 or CFrame comes back
	wrapped; arguments are unwrapped on the way in. Lune's own types and the wrapped
	ones must not mix outside these functions, so the lab and dom.luau use only these.
]]

local roblox = require("@lune/roblox")

local RawVector3 = roblox.Vector3
local RawCFrame = roblox.CFrame

local Types = {}

local VectorMeta = {}
local CFrameMeta = {}

local wrap: (value: any) -> any

local function isWrapped(value: any): boolean
	if type(value) ~= "table" then
		return false
	end
	local meta = getmetatable(value)
	return meta == VectorMeta or meta == CFrameMeta
end

local function unwrap(value: any): any
	if isWrapped(value) then
		return rawget(value, "Raw")
	end
	return value
end

local function unwrapAll(...: any): ...any
	local args = table.pack(...)
	for index = 1, args.n do
		args[index] = unwrap(args[index])
	end
	return table.unpack(args, 1, args.n)
end

local function wrapAll(...: any): ...any
	local results = table.pack(...)
	for index = 1, results.n do
		results[index] = wrap(results[index])
	end
	return table.unpack(results, 1, results.n)
end

wrap = function(value: any): any
	local kind = typeof(value)
	if kind == "Vector3" then
		return setmetatable({ Raw = value }, VectorMeta)
	elseif kind == "CFrame" then
		return setmetatable({ Raw = value }, CFrameMeta)
	end
	return value
end

Types.wrap = wrap
Types.unwrap = unwrap

-- Both: reading a property or calling a method goes to the raw value.
local function index(self, key)
	local raw = rawget(self, "Raw")
	local member = raw[key]
	if type(member) == "function" then
		return function(_, ...)
			return wrapAll(member(raw, unwrapAll(...)))
		end
	end
	return wrap(member)
end

local function arithmetic(operator: string)
	return function(a, b)
		local x, y = unwrap(a), unwrap(b)
		if operator == "mul" then
			-- the number may come first (Lune only takes it second)
			if type(x) == "number" then
				return wrap(y * x)
			end
			return wrap(x * y)
		elseif operator == "add" then
			return wrap(x + y)
		elseif operator == "sub" then
			return wrap(x - y)
		elseif operator == "div" then
			if type(x) == "number" then
				return wrap(RawVector3.new(x, x, x) / y)
			end
			return wrap(x / y)
		elseif operator == "idiv" then
			return wrap(x // y)
		end
		error(operator)
	end
end

for _, meta in { VectorMeta, CFrameMeta } do
	meta.__index = index
	meta.__add = arithmetic("add")
	meta.__sub = arithmetic("sub")
	meta.__mul = arithmetic("mul")
	meta.__div = arithmetic("div")
	meta.__idiv = arithmetic("idiv")
	meta.__eq = function(a, b)
		return unwrap(a) == unwrap(b)
	end
	meta.__tostring = function(self)
		return tostring(rawget(self, "Raw"))
	end
	meta.__newindex = function()
		error("Vector3 and CFrame are read-only")
	end
end
VectorMeta.__unm = function(a)
	return wrap(-unwrap(a))
end
VectorMeta.__type = "Vector3"
CFrameMeta.__type = "CFrame"

-- `typeof` for the lab's values (wrapped ones read as Roblox's names).
function Types.typeof(value: any): string
	if type(value) == "table" then
		local meta = getmetatable(value)
		if meta == VectorMeta then
			return "Vector3"
		elseif meta == CFrameMeta then
			return "CFrame"
		end
	end
	return typeof(value)
end

-- The globals: every function of Lune's, wrapped; constants wrapped once.
local function library(raw: any, extra: { [string]: any }): any
	return setmetatable(extra, {
		__index = function(_, key)
			local member = raw[key]
			if type(member) == "function" then
				return function(...)
					return wrapAll(member(unwrapAll(...)))
				end
			end
			return wrap(member)
		end,
	})
end

-- CFrame.lookAt built from its axes, as Roblox does it: Lune's (0.10) gets the look
-- direction's Y and Z backwards, and gives NaNs looking straight along the up vector
-- (Roblox picks another up vector then).
local function lookAt(at: any, target: any, up: any?): any
	local from, to = unwrap(at), unwrap(target)
	local upward = unwrap(up) or RawVector3.yAxis
	local direction = to - from
	if direction.Magnitude < 1e-9 then
		return wrap(RawCFrame.new(from))
	end
	local look = direction.Unit
	if math.abs(look:Dot(upward.Unit)) > 0.9999 then
		upward = if math.abs(look:Dot(RawVector3.zAxis)) > 0.9 then RawVector3.xAxis else RawVector3.zAxis
	end
	local right = look:Cross(upward).Unit
	local top = right:Cross(look).Unit
	return wrap(RawCFrame.fromMatrix(from, right, top, -look))
end

Types.Vector3 = library(RawVector3, {})
Types.CFrame = library(RawCFrame, {
	lookAt = lookAt,
	new = function(...)
		-- (the old two-point form: at `a`, looking at `b`)
		if select("#", ...) == 2 then
			return lookAt(...)
		end
		return wrap(RawCFrame.new(unwrapAll(...)))
	end,
})

return Types
