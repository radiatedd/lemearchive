--[[
	https://github.com/awesomeusername69420/miscellaneous-gmod-stuff
]]

local MOVETYPE_WALK = MOVETYPE_WALK

local GroundTick = 0

hook.Add("CreateMove", "BHop", function(cmd)
	if LocalPlayer():GetMoveType() ~= MOVETYPE_WALK or IsValid(LocalPlayer():GetVehicle()) or LocalPlayer():WaterLevel() > 1 then return end
	if not cmd:KeyDown(IN_JUMP) then return end

	if LocalPlayer():IsOnGround() then
		GroundTick = GroundTick + 1

		if GroundTick > 4 then
			cmd:RemoveKey(IN_JUMP)
			GroundTick = 0
		end
	else
		cmd:RemoveKey(IN_JUMP)
		GroundTick = 0
	end
end)
