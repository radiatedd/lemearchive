--[[
	https://github.com/awesomeusername69420/miscellaneous-gmod-stuff
]]

local HSVToColor = HSVToColor
local LocalPlayer = LocalPlayer
local UnPredictedCurTime = UnPredictedCurTime
local setmetatable = setmetatable

local meta_cl = debug.getregistry().Color

local rColor = Vector(1, 1, 1)

hook.Add("Think", "RGB", function()
	rColor = setmetatable(HSVToColor((UnPredictedCurTime() % 6) * 60, 1, 1), meta_cl):ToVector()

	LocalPlayer():SetWeaponColor(rColor)
	LocalPlayer():SetPlayerColor(rColor)
end)