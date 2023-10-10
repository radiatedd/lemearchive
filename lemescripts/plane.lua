--[[
	https://github.com/awesomeusername69420/miscellaneous-gmod-stuff

	~ Airplane ~

	- Move with arrow keys
	- ConVars:
		plane_speed - Controls how fast it moves
		plane_speed_turn - Controls how fast it turns
		plane_forwardtrace_length - Controls how long the line in front of the plane is (0 to disable)
]]

local Cache = {
	Colors = {
		Red = Color(255, 0, 0, 255),
		Red_A = Color(255, 0, 0, 100),
		Gray = Color(50, 50, 50, 255),
		Gray_A = Color(50, 50, 50, 100),
		Orange = Color(255, 150, 0, 255),
		Orange_A = Color(255, 150, 0, 100)
	},

	Materials = {
		Color = CreateMaterial(tostring({}), "UnlitGeneric", {
			["$alpha"] = 0.4,
			["$basetexture"] = "color/white",
			["$model"] = 1,
			["$translucent"] = 1,
			["$vertexalpha"] = 1,
			["$vertexcolor"] = 1
		})	
	},

	ConVars = {
		m_pitch = GetConVar("m_pitch"),
		m_yaw = GetConVar("m_yaw"),
		fov_desired = GetConVar("fov_desired"),

		plane_speed = CreateClientConVar("plane_speed", 1, false, false, "", 0, 100),
		plane_speed_turn = CreateClientConVar("plane_speed_turn", 1, false, false, "", 0, 100),
		plane_forwardtrace_length = CreateClientConVar("plane_forwardtrace_length", 150, false, false, "", 0, math.huge)
	},

	Bindings = {
		Forward = KEY_UP,
		Backward = KEY_DOWN,
		Left = KEY_LEFT,
		Right = KEY_RIGHT
	},

	Transform = {
		Position = LocalPlayer():LocalToWorld(LocalPlayer():OBBCenter() * 3),
		Rotation = LocalPlayer():EyeAngles()
	},

	Bounds = {
		Base = {
			Mins = Vector(-16, -8, -6),
			Maxs = Vector(16, 8, 6),
			MaxsLength = nil
		},

		Wing = {
			Mins = Vector(-8, -6, -3),
			Maxs = Vector(8, 6, 3),
			MaxsLength = nil
		},

		ForwardTrace = {
			Mins = Vector(-4, -4, -4),
			Maxs = Vector(4, 4, 4)
		}
	},

	View = {
		Rotation = LocalPlayer():EyeAngles(),
		Offset = vector_up * 75
	}
}

Cache.Transform.Rotation.pitch = 0 -- Fix angle

local function AngleOutOfRange(ang)
	ang = ang or angle_zero
	
	return ang.pitch > 90 or ang.pitch < -90 or ang.yaw > 180 or ang.yaw < -180 or ang.roll > 180 or ang.roll < -180
end

local function FixAngle(ang)
	ang = ang or angle_zero

	if not AngleOutOfRange(ang) then return ang end

	return Angle(math.Clamp(math.NormalizeAngle(ang.pitch), -90, 90), math.NormalizeAngle(ang.yaw), math.NormalizeAngle(ang.roll))
end

local function GetDeltaTime()
	return RealFrameTime() * 200
end

hook.Add("InputMouseApply", "plane_InputMouseApply", function(_, dX, dY)
	Cache.View.Rotation.pitch = Cache.View.Rotation.pitch + (dY * Cache.ConVars.m_pitch:GetFloat())
	Cache.View.Rotation.yaw = Cache.View.Rotation.yaw - (dX * Cache.ConVars.m_yaw:GetFloat())

	Cache.View.Rotation = FixAngle(Cache.View.Rotation)
end)

hook.Add("Think", "plane_Think", function()
	local speed = Cache.ConVars.plane_speed_turn:GetInt() * GetDeltaTime()
	local ang = Cache.Transform.Rotation * 1

	if input.IsButtonDown(Cache.Bindings.Forward) then
		ang = ang - Angle(speed, 0, 0)
	end

	if input.IsButtonDown(Cache.Bindings.Backward) then
		ang = ang + Angle(speed, 0, 0)
	end

	if input.IsButtonDown(Cache.Bindings.Left) then
		ang = ang + Angle(0, speed, 0)
	end

	if input.IsButtonDown(Cache.Bindings.Right) then
		ang = ang - Angle(0, speed, 0)
	end

	Cache.Transform.Rotation = FixAngle(ang)
	Cache.Transform.Position = Cache.Transform.Position + (Cache.Transform.Rotation:Forward() * Cache.ConVars.plane_speed:GetInt() * GetDeltaTime())
end)

hook.Add("PreDrawEffects", "plane_PreDrawEffects", function()
	render.SetMaterial(Cache.Materials.Color)

	local ang = Cache.Transform.Rotation

	local forwardlength = Cache.ConVars.plane_forwardtrace_length:GetInt()

	if forwardlength > 0 then
		Cache.Bounds.Base.MaxsLength = Cache.Bounds.Base.MaxsLength or Cache.Bounds.Base.Maxs:Length()

		local forward = ang:Forward()
		local front = Cache.Transform.Position + (forward * Cache.Bounds.Base.MaxsLength)

		local tr = util.TraceHull({
			start = front,
			endpos = front + (forward * forwardlength),
			mins = Cache.Bounds.ForwardTrace.Mins,
			Cache.Bounds.ForwardTrace.Maxs
		})

		local col = tr.Hit and Cache.Colors.Orange or Cache.Colors.Gray
		local col_a = tr.Hit and Cache.Colors.Orange_A or Cache.Colors.Gray_A

		local frontpos = tr.HitPos + tr.HitNormal

		render.DrawLine(front, frontpos, col, true)

		render.DrawWireframeBox(frontpos, angle_zero, Cache.Bounds.ForwardTrace.Mins, Cache.Bounds.ForwardTrace.Maxs, col, true)
		render.DrawBox(frontpos, angle_zero, Cache.Bounds.ForwardTrace.Mins, Cache.Bounds.ForwardTrace.Maxs, col_a)
	end

	Cache.Bounds.Wing.MaxsLength = Cache.Bounds.Wing.MaxsLength or Cache.Bounds.Wing.Maxs:Length()

	render.DrawWireframeBox(Cache.Transform.Position, ang, Cache.Bounds.Base.Mins, Cache.Bounds.Base.Maxs, Cache.Colors.Red, true)
	render.DrawBox(Cache.Transform.Position, ang, Cache.Bounds.Base.Mins, Cache.Bounds.Base.Maxs, Cache.Colors.Red_A)

	local right = ang:Right()
	local side = right * (Cache.Bounds.Wing.MaxsLength * 1.3333333333333)

	render.DrawWireframeBox(Cache.Transform.Position + side, ang, Cache.Bounds.Wing.Mins, Cache.Bounds.Wing.Maxs, Cache.Colors.Red, true)
	render.DrawBox(Cache.Transform.Position + side, ang, Cache.Bounds.Wing.Mins, Cache.Bounds.Wing.Maxs, Cache.Colors.Red_A)

	render.DrawWireframeBox(Cache.Transform.Position - side, ang, Cache.Bounds.Wing.Mins, Cache.Bounds.Wing.Maxs, Cache.Colors.Red, true)
	render.DrawBox(Cache.Transform.Position - side, ang, Cache.Bounds.Wing.Mins, Cache.Bounds.Wing.Maxs, Cache.Colors.Red_A)
end)

hook.Add("CalcView", "plane_CalcView", function(ply)
	if not IsValid(ply) then return end

	local ang = Cache.View.Rotation * 1

	local pos = Cache.Transform.Position
	local campos = pos - (ang:Forward() * 150) + Cache.View.Offset

	ang.pitch = (pos - campos):Angle().pitch

	local view = {
		origin = campos,
		angles = ang,
		fov = Cache.ConVars.fov_desired:GetInt() + 1,
		drawviewer = true
	}

	return view
end)
