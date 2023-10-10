--[[
	https://github.com/awesomeusername69420/miscellaneous-gmod-stuff

	Requires https://github.com/awesomeusername69420/miscellaneous-gmod-stuff/blob/main/includes/util/RandomString.lua
]]

local RunConsoleCommand = RunConsoleCommand

include("includes/util/RandomString.lua")

timer.Create("ASaySpam", 1, 0, function ()
	if ULX then
		local Start = "ulx asay "
		local x = RandomString(256 - #Start, true)

		RunConsoleCommand("ulx", "asay", x)
	end

	if sam then
		local Start = "sam asay "
		local x = RandomString(256 - #Start, true)

		RunConsoleCommand("sam", "asay", x)
	end
end)
