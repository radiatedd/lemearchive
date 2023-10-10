--[[
			made by: leme
		archived by 0x59
	https://github.com/awesomeusername69420/miscellaneous-gmod-stuff
]]

local cl_forwardspeed = GetConVar("cl_forwardspeed")

local TickInterval = engine.TickInterval()

local MoveDelay = 120 -- Seconds to wait unti anti afk begins
local CurMoveDelay = 0
local MoveDelaySatisfied = false

local InterMoveDelay = 10 -- Seconds to wait until anti afk moves again
local CurInterMoveDelay = 0
local CurInterMoveDelaySatisfied = false

local MoveDuration = 0
local CurMoveDuration = 0

local MoveDirectionLerp = 0
local MoveDirection = angle_zero * 1

hook.Add("CreateMove", "AntiAFK", function(cmd)
	local IN_MOVE = cmd:KeyDown(IN_FORWARD) or cmd:KeyDown(IN_BACK) or cmd:KeyDown(IN_MOVERIGHT) or cmd:KeyDown(IN_MOVELEFT) or cmd:GetMouseX() ~= 0 or cmd:GetMouseY() ~= 0

	if IN_MOVE then
		CurMoveDelay = 0
		CurInterMoveDelay = 0

		MoveDelaySatisfied = false
		CurInterMoveDelaySatisfied = false

		return
	end

	if not MoveDelaySatisfied then -- Welcome to Egypt!
		CurMoveDelay = CurMoveDelay + TickInterval

		if CurMoveDelay >= MoveDelay then
			MoveDelaySatisfied = true
		end
	else
		if not CurInterMoveDelaySatisfied then
			CurInterMoveDelay = CurInterMoveDelay + TickInterval

			if CurInterMoveDelay >= InterMoveDelay then
				CurInterMoveDelaySatisfied = true

				MoveDuration = math.random(1, 10)
				CurMoveDuration = 0

				MoveDirection = Angle(0, math.random(-180, 180), 0)
				MoveDirectionLerp = SysTime()
			end
		else
			if CurMoveDuration >= MoveDuration then
				CurInterMoveDelaySatisfied = false
				CurInterMoveDelay = 0
			else
				CurMoveDuration = CurMoveDuration + TickInterval

				cmd:SetViewAngles(LerpAngle(0.1, cmd:GetViewAngles(), MoveDirection))

				cmd:AddKey(IN_FORWARD)
				cmd:SetForwardMove(cl_forwardspeed:GetFloat())
			end
		end
	end
end)
