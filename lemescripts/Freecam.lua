--[[
	https://github.com/awesomeusername69420/miscellaneous-gmod-stuff

	ConVars:
		freecam_speed			-	Controls camera movement speed							(Default: 150)
		freecam_speed_sprint	-	Controls camera movement speed when holding sprint key	(Default: 300)
		freecam_speed_walk		-	Controls camera movement speed when holding walk key	(Default: 25)

	ConCommands:
		freecam_toggle			-	Toggles freecam
]]

local DoFreecam = false

local CamPos = vector_origin * 1
local CamAng = angle_zero * 1
local PreCamAng = CamAng

-- ConVars

local freecam_speed = CreateClientConVar("freecam_speed", 150, true, false, "", 0, math.huge)
local freecam_speed_sprint = CreateClientConVar("freecam_speed_sprint", 250, true, false, "", 0, math.huge)
local freecam_speed_walk = CreateClientConVar("freecam_speed_walk", 75, true, false, "", 0, math.huge)

local m_pitch = GetConVar("m_pitch")
local m_yaw = GetConVar("m_yaw")

-- Localization

local IsValid = IsValid
local Angle = Angle
local RealFrameTime = RealFrameTime

local math_Clamp = math.Clamp
local math_NormalizeAngle = math.NormalizeAngle

local IN_BACK = IN_BACK
local IN_FORWARD = IN_FORWARD
local IN_MOVELEFT = IN_MOVELEFT
local IN_MOVERIGHT = IN_MOVERIGHT
local IN_SPEED = IN_SPEED
local IN_WALK = IN_WALK

-- Helpfulness

local function AngleOutOfRange(ang)
	ang = ang or angle_zero
	
	return ang.pitch > 89 or ang.pitch < -89 or ang.yaw > 180 or ang.yaw < -180 or ang.roll > 180 or ang.roll < -180
end

local function FixAngle(ang)
	ang = ang or angle_zero

	if not AngleOutOfRange(ang) then return ang end

	return Angle(math_Clamp(math_NormalizeAngle(ang.pitch), -89, 89), math_NormalizeAngle(ang.yaw),math_NormalizeAngle(ang.roll))
end

local function GetDeltaTime()
	return RealFrameTime() * 5
end

-- Hooks

hook.Add("CalcView", "Freecam", function(ply, pos, ang, fov, zn, zf)
	if not IsValid(ply) then return end

	if not DoFreecam then
		CamPos = pos
		CamAng = ang

		return
	end

	local view = {
		origin = CamPos,
		angles = CamAng,
		fov = fov,
		znear = zn,
		zfar = zf,
		drawviewer = true
	}

	return view
end)

hook.Add("CreateMove", "Freecam", function(cmd)
	if not DoFreecam then
		PreCamAng = FixAngle(cmd:GetViewAngles())

		return
	end

	-- Movement

	local Forward = CamAng:Forward()
	local Right = CamAng:Right()

	local Speed = 0

	if cmd:KeyDown(IN_WALK) then
		Speed = freecam_speed_walk:GetFloat()
	elseif cmd:KeyDown(IN_SPEED) then
		Speed = freecam_speed_sprint:GetFloat()
	else
		Speed = freecam_speed:GetFloat()
	end

	Speed = Speed * GetDeltaTime()

	if cmd:KeyDown(IN_FORWARD) then
		CamPos = CamPos + (Forward * Speed)
	end

	if cmd:KeyDown(IN_BACK) then
		CamPos = CamPos - (Forward * Speed)
	end

	if cmd:KeyDown(IN_MOVERIGHT) then
		CamPos = CamPos + (Right * Speed)
	end

	if cmd:KeyDown(IN_MOVELEFT) then
		CamPos = CamPos - (Right * Speed)
	end

	-- Camera

	local MouseX = cmd:GetMouseX()
	local MouseY = cmd:GetMouseY()

	if MouseX ~= 0 or MouseY ~= 0 then
		CamAng.pitch = CamAng.pitch + (MouseY * m_pitch:GetFloat())
		CamAng.yaw = CamAng.yaw - (MouseX * m_yaw:GetFloat())

		CamAng = FixAngle(CamAng)

		cmd:SetMouseX(0)
		cmd:SetMouseY(0)
	end

	cmd:ClearButtons()
	cmd:ClearMovement()

	cmd:SetViewAngles(PreCamAng)
end)

-- ConCommands

concommand.Add("freecam_toggle", function()
	DoFreecam = not DoFreecam
end)
