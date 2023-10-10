--[[
	https://github.com/awesomeusername69420/miscellaneous-gmod-stuff
]]

local IsValid = IsValid

local debug_getinfo = debug.getinfo
local string_find = string.find

---------------------------

local _Player_Backup = {}
local _Player = debug.getregistry().Player

_Player_Backup.ConCommand = _Player.ConCommand
_Player.ConCommand = function(...)
	if string_find(debug_getinfo(2).source, "gmod_camera") then return end

	return _Player_Backup.ConCommand(...)
end

---------------------------

local bFlip = false

hook.Add("CreateMove", "CamSpam", function(cmd)
	if cmd:CommandNumber() == 0 then return end

	local Weapon = LocalPlayer():GetActiveWeapon()

	if IsValid(Weapon) and Weapon:GetClass() == "gmod_camera" and bFlip then
		cmd:AddKey(IN_ATTACK)
	end

	bFlip = not bFlip
end)
