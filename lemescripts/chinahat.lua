--[[
	https://github.com/awesomeusername69420/miscellaneous-gmod-stuff
	
	Rice Mode: Activated
	
	Command(s):
		rice_ang (int)     -  Changes the angle of the hat
		rice_len (int)     -  Changes the length of the hat
		rice_col (string)  -  Changes the color of the hat
]]

local inang = 25
local length = 15
local color = Color(255, 255, 0, 75)
local panic = false

local ismeth = false

if meth_lua_api and meth_lua_api.callbacks then
	ismeth = true
end

local function getHeadPos(ent)
	if not ent:IsValid() then
		return Vector(0, 0, 0)
	end
	
	local entpos = ent:GetPos()
	local headpos = ent:EyePos()
	
	for i = 0, ent:GetBoneCount() - 1 do
		if string.find(string.lower(ent:GetBoneName(i)), "head") then
			headpos = ent:GetBonePosition(i)
			
			if headpos == entpos then
				headpos = ent:GetBoneMatrix(i):GetTranslation()
			end

			break
		end
	end
	
	return headpos
end

local function drawHat()
	if LocalPlayer():ShouldDrawLocalPlayer() then
		local base = getHeadPos(LocalPlayer()) + Vector(0, 0, 10)
		local ang = Angle(inang, 0, 0)
		
		cam.Start3D()
			for i = 1, 360 do
				if panic then
					cam.End3D()
				end
			
				render.DrawLine(base, base + (ang:Forward() * length), color, false)
				ang.y = ang.y + 1
			end
		cam.End3D()
	end
end

if ismeth then
	meth_lua_api.callbacks.Add("OnHUDPaint", tostring({}), function()
		panic = false
		
		drawHat()
	end)
end

hook.Add("HUDPaint", tostring({}), function()
	if ismeth then
		panic = true
	else
		drawHat()
	end
end)

concommand.Add("rice_ang", function(p, c, args)
	args[1] = args[1] or 25
	
	inang = tonumber(args[1])
end)

concommand.Add("rice_len", function(p, c, args)
	args[1] = args[1] or 15
	
	length = tonumber(args[1])
end)

concommand.Add("rice_col", function(p, c, args, argstr)
	argstr = argstr or "255 255 255 75"
	
	color = Color(unpack(string.Split(argstr, " ")))
end)
