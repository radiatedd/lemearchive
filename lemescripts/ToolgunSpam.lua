--[[
	https://github.com/awesomeusername69420/miscellaneous-gmod-stuff
]]

hook.Add("CreateMove", "tgs", function(cmd)
	if not cmd:KeyDown(IN_ATTACK) then return end

	local weapon = LocalPlayer():GetActiveWeapon()
	if not IsValid(weapon) or weapon:GetClass() ~= "gmod_tool" then return end

	if cmd:TickCount() % 2 == 0 then
		cmd:RemoveKey(IN_ATTACK)
	end
end)
