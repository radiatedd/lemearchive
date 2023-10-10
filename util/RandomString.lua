--[[
	https://github.com/awesomeusername69420/miscellaneous-gmod-stuff
]]

local CharRanges = {
	{65, 90}, -- A-Z
	{97, 122}, -- a-z
	{48, 57}, -- 0-9
	{33, 47}, -- ! - /
	{58, 64}, -- : - @
	{91, 96}, -- [ - `
	{123, 126} -- { - ~
}

function RandomString(len, symbols)
	assert(type(len) == "number", "Bad argument #1 to RandomString (number expected, got )" .. type(len))
	assert(len > 0, "Bad argument #1 to RandomString (number must be > 0)")

	if symbols ~= nil then
		assert(type(symbols) == "boolean", "Bad argument #2 to RandomString (boolean expected, got )" .. type(symbols))
	end

	symbols = symbols or false

	local max = symbols and #CharRanges or 3
	local str = ""

	for i = 1, len do
		local set = CharRanges[math.random(1, max)]

		str = str .. string.char(math.random(set[1], set[2]))
	end

	return str
end
