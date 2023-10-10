--[[
	https://github.com/awesomeusername69420/miscellaneous-gmod-stuff

	Some more utilities
]]

local meta_cl = debug.getregistry().Color
meta_cl.__type = "Color"

local assert = assert
local type = type

function util.GetObjectType(object) -- Similar to type() but supports __type metafield
	local objectmeta = getmetatable(object)

	if objectmeta and objectmeta.__type then
		if type(objectmeta.__type) == "function" then
			return objectmeta.__type(object)
		else
			return objectmeta.__type
		end
	end

	return type(object)
end

function util.TypeAssert(index, value, desired) -- Cleans up code a lot, checks if the given value is of the required type
	assert(type(index) == "number", "Bad argument #1 to 'TypeAssert' (number expected, got " .. type(index) .. ")")

	local dtype = util.GetObjectType(desired)

	assert(dtype == "string", "Bad argument #3 to 'TypeAssert' (string expected, got " .. dtype .. ")")

	local dbg = debug.getinfo(2) or {}
	
	local dbgname = dbg.name or dbg.short_src or dbg.source or "UNKNOWN"

	local base = type(value)
	local real = util.GetObjectType(value)

	if base ~= desired and real ~= desired then
		error(string.format("Bad argument #%d to '%s' (%s expected, got %s)", index, dbgname, desired, real))
	end
end

-- Base HU conversion

function util.HUToFeet(units) -- Convert Hammer Units into Feet
	util.TypeAssert(1, units, "number")

	return units / 16
end

-- Unit conversions

function util.InchesToFeet(units)
	util.TypeAssert(1, units, "number")

	return units / 12
end

function util.FeetToInches(units) -- Convert Feet into Inches
	util.TypeAssert(1, units, "number")

	return units * 12
end

function util.FeetToMeters(units) -- Convert Feet into Meters
	util.TypeAssert(1, units, "number")

	return units / 3.280839895
end

function util.MetersToFeet(units) -- Convert Meters into Feet
	util.TypeAssert(1, units, "number")

	return units * 3.280839895
end

function util.MetersToCentimeters(units) -- Convert Meters into Centimeters
	util.TypeAssert(1, units, "number")

	return units * 100
end

function util.InchesToMeters(units) -- Convert Inches into Meters
	util.TypeAssert(1, units, "number")

	return util.FeetToMeters(util.InchesToFeet(units))
end

function util.MetersToInches(units)
	util.TypeAssert(1, units, "number")

	return util.FeetToInches(util.MetersToFeet(units))
end

-- Other HU conversions

function util.HUToInches(units) -- Convert Hammer Units into Inches
	util.TypeAssert(1, units, "number")

	return util.FeetToInches(util.HUToFeet(units))
end

function util.HUToMeters(units) -- Convert Hammer Units into Meters
	util.TypeAssert(1, units, "number")

	return util.FeetToMeters(util.HUToFeet(units))
end

function util.HUToCentimeters(units) -- Convert Hammer Units into Centimeters
	util.TypeAssert(1, units, "number")

	return util.MetersToCentimeters(util.HUToMeters(units))
end

-- Number stuff

function util.GetDecimals(number) -- Returns how many decimal places a number has
	util.TypeAssert(1, number, "number")

	local decimals = tostring(number):Split(".")

	return decimals[2] and #decimals[2] or 0
end

-- Color stuff

function util.FixColor(color) -- Fixes a color's R, G, B and A values
	util.TypeAssert(1, color, "Color")

	color.r = math.min(tonumber(color.r) or 0, 255)
	color.g = math.min(tonumber(color.g) or 0, 255)
	color.b = math.min(tonumber(color.b) or 0, 255)
	color.a = math.min(tonumber(color.a) or 0, 255)
end

function util.CopyColor(color) -- Returns a copy of the provided color
	util.TypeAssert(1, color, "Color")

	local newColor = Color(color:Unpack())

	util.FixColor(newColor)

	return newColor
end

function util.TableToColor(color) -- Fixes a table to be of the color metatable
	if IsColor(color) then return end -- Already a color, do nothing

	util.TypeAssert(1, color, "table")

	setmetatable(color, meta_cl)
end

-- Table stuff

function util.GetTableDifferenceKeys(one, two) -- Compares table one to table two
	util.TypeAssert(1, one, "table")
	util.TypeAssert(2, two, "table")

	local differences = {}

	for _, v in ipairs(table.GetKeys(one)) do
		if two[v] == nil then
			differences[#differences + 1] = v
		end
	end

	return differences
end

-- Material stuff

function util.MaterialIsValid(material)
	return material ~= nil and type(material) == "IMaterial" and not material:IsError()
end

-- Client only stuff

if not CLIENT then return end

function util.IsInWorld(position) -- Clientside version
	util.TypeAssert(1, position, "Vector")

	return not util.TraceLine({
		start = position,
		endpos = position,
		collisiongroup = COLLISION_GROUP_WORLD
	}).HitWorld
end
