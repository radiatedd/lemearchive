--[[
	https://github.com/awesomeusername69420/miscellaneous-gmod-stuff

	ConVars:
		as_mode - Controls the autostrafe mode. 0 = Disabled; 1 = Legit; 2 = Rage.
]]

local Mode = CreateClientConVar("as_mode", 1, false, false, "0 = Disabled; 1 = Legit; 2 = Rage", 0, 2)

local SideMove = GetConVar("cl_sidespeed")
local ForwardMove = GetConVar("cl_forwardspeed")

local AS_MODE_DISABLED = 0
local AS_MODE_LEGIT = 1
local AS_MODE_RAGE = 2

local IN_JUMP = IN_JUMP
local MOVETYPE_WALK = MOVETYPE_WALK

local Strafers = {}

Strafers[AS_MODE_LEGIT] = function(cmd, Grounded, MaxSideMove)
	if Grounded then return end

	if cmd:GetMouseX() > 0 then
		cmd:SetSideMove(MaxSideMove)
	elseif cmd:GetMouseX() < 0 then
		cmd:SetSideMove(MaxSideMove * -1)
	end
end

Strafers[AS_MODE_RAGE] = function(cmd, Grounded, MaxSideMove, MaxForwardMove, Velocity)
	Strafers[AS_MODE_LEGIT](cmd, Grounded, MaxSideMove)

	if not cmd:KeyDown(IN_JUMP) then return end

	if Grounded then
		cmd:SetForwardMove(MaxForwardMove)
	else
		cmd:SetForwardMove((MaxForwardMove * 0.5) / Velocity:Length2D())
		cmd:SetSideMove(cmd:CommandNumber() % 2 == 0 and (MaxSideMove * -1) or MaxSideMove)
	end
end

hook.Add("CreateMove", "as", function(cmd)
	local SetMode = Mode:GetInt()

	if SetMode == AS_MODE_DISABLED then return end
	if LocalPlayer():GetMoveType() ~= MOVETYPE_WALK or IsValid(LocalPlayer():GetVehicle()) or LocalPlayer():WaterLevel() > 1 then return end

	Strafers[SetMode](cmd, LocalPlayer():IsOnGround(), SideMove:GetFloat(), ForwardMove:GetFloat(), LocalPlayer():GetVelocity())
end)
