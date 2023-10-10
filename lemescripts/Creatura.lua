--[[
	https://github.com/awesomeusername69420/miscellaneous-gmod-stuff

	~ La Creatura ~

	- Move with arrow keys
	- ConVars:
		creatura_speed - Controls how fast it moves
		creatura_speed_turn - Controls how fast it turns
]]

local Cache = {
	TickInterval = engine.TickInterval(),

	Colors = {
		Red = Color(255, 0, 0, 255),

		Gray = Color(35, 35, 35, 255)
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
		sv_gravity = GetConVar("sv_gravity"),

		creatura_speed = CreateClientConVar("creatura_speed", 1, false, false, "", 0, 100),
		creatura_speed_turn = CreateClientConVar("creatura_speed_turn", 2, false, false, "", 0, 100),
	},

	Bindings = {
		Forward = KEY_UP,
		Backward = KEY_DOWN,
		Left = KEY_LEFT,
		Right = KEY_RIGHT
	},

	Transform = {
		Position = vector_origin * 1,
		Rotation = angle_zero * 1
	},

	Bounds = {
		Whole = {
			Position = vector_origin * 1,
			Mins = vector_origin * 1,
			Maxs = vector_origin * 1
		},

		Head = {
			UpSet = vector_up * 8,

			Mins = Vector(-6, -6, -6),
			Maxs = Vector(6, 6, 6)
		},

		Body = {
			Mins = Vector(-16, -8, -8),
			Maxs = Vector(16, 8, 8),

			MaxsLength = 0
		},

		Leg = {
			RightSet = Vector(10, 4, 0),
			ForwardSet = Vector(10, -4, 0),

			PitchSet = 0,

			DesireAngle = Angle(90, 0, 0),

			Mins = Vector(-2, -2, -10),
			Maxs = Vector(2, 2, 10),

			MaxsLength = 0
		}
	},

	View = {
		Rotation = angle_zero * 1,
		Offset = vector_up * 75
	}
}

Cache.Bounds.Body.MaxsLength = Cache.Bounds.Body.Maxs:Length()
Cache.Bounds.Leg.MaxsLength = Cache.Bounds.Leg.Maxs:Length()

Cache.Transform.Position = LocalPlayer():GetPos() + (vector_up * Cache.Bounds.Body.MaxsLength)
Cache.Transform.Rotation = Angle(0, math.NormalizeAngle(LocalPlayer():EyeAngles().yaw), 0)

Cache.Bounds.Whole.Maxs = Cache.Bounds.Body.Maxs + Cache.Bounds.Leg.Maxs
Cache.Bounds.Whole.Maxs.y = Cache.Bounds.Whole.Maxs.x

Cache.Bounds.Whole.Mins = Cache.Bounds.Whole.Maxs * -1

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

local function DrawFilledWireframeBox(pos, ang, mins, maxs, color, z) -- Prevent repeating
	render.DrawWireframeBox(pos, ang, mins, maxs, color, z)
	render.DrawBox(pos, ang, mins, maxs, color)
end

local function IsOnGround()
	local tr = util.TraceHull({
		start = Cache.Transform.Position,
		endpos = Cache.Transform.Position - (vector_up * Cache.Bounds.Leg.MaxsLength),
		mins = Cache.Bounds.Whole.Mins,
		maxs = Cache.Bounds.Whole.Maxs,
		collisonground = COLLISION_GROUP_WORLD
	})

	return tr.Hit
end

hook.Add("InputMouseApply", "creatura_InputMouseApply", function(_, dX, dY)
	Cache.View.Rotation.pitch = Cache.View.Rotation.pitch + (dY * Cache.ConVars.m_pitch:GetFloat())
	Cache.View.Rotation.yaw = Cache.View.Rotation.yaw - (dX * Cache.ConVars.m_yaw:GetFloat())

	Cache.View.Rotation = FixAngle(Cache.View.Rotation)
end)

hook.Add("Think", "creatura_Think", function()
	local Speed = Cache.ConVars.creatura_speed:GetInt() * GetDeltaTime()
	local TurnSpeed = Cache.ConVars.creatura_speed_turn:GetInt() * GetDeltaTime()

	local Gravity = (vector_up * (Cache.ConVars.sv_gravity:GetFloat() * Cache.TickInterval)) * -1 * (GetDeltaTime() / 10)

	local TAngle = Cache.Transform.Rotation * 1

	local Forward = Cache.Transform.Rotation:Forward()
	local PlayerMove = false
	local Move = IsOnGround() and vector_origin or Gravity

	if input.IsButtonDown(Cache.Bindings.Forward) then
		Move = Move + (Forward * Speed)
		PlayerMove = true
	end

	if input.IsButtonDown(Cache.Bindings.Backward) then
		Move = Move - (Forward * Speed)
		PlayerMove = true
	end

	if input.IsButtonDown(Cache.Bindings.Left) then
		TAngle.yaw = TAngle.yaw + TurnSpeed
	end

	if input.IsButtonDown(Cache.Bindings.Right) then
		TAngle.yaw = TAngle.yaw - TurnSpeed
	end

	Cache.Transform.Rotation = FixAngle(TAngle)

	if PlayerMove then
		Cache.Bounds.Leg.PitchSet = math.sin(engine.TickCount() / 10) * Speed * 10
	else
		Cache.Bounds.Leg.PitchSet = 0
	end

	if Move ~= vector_origin then
		local DesiredPosition = Cache.Transform.Position + Move
		local Direction = DesiredPosition - Cache.Transform.Position
		
		local tr = util.TraceHull({
			start = Cache.Transform.Position,
			endpos = DesiredPosition + Direction,
			filter = LocalPlayer(),
			mins = Cache.Bounds.Whole.Mins,
			maxs = Cache.Bounds.Whole.Maxs
		})

		Cache.Transform.Position = tr.HitPos + tr.HitNormal
	end
end)

hook.Add("PreDrawEffects", "creatura_PreDrawEffects", function()
	render.SetMaterial(Cache.Materials.Color)

	local TAngle = Cache.Transform.Rotation

	local Forward = TAngle:Forward()
	local Right = TAngle:Right()
	local Up = TAngle:Up()

	local TPosition = Cache.Transform.Position + (Up * Cache.Bounds.Leg.MaxsLength * 0.75)

	DrawFilledWireframeBox(TPosition, TAngle, Cache.Bounds.Body.Mins, Cache.Bounds.Body.Maxs, Cache.Colors.Gray, true)

	-- Head

	local Front = TPosition + (Forward * Cache.Bounds.Body.MaxsLength * 1.1)

	DrawFilledWireframeBox(Front + Cache.Bounds.Head.UpSet, TAngle, Cache.Bounds.Head.Mins, Cache.Bounds.Head.Maxs, Cache.Colors.Gray, true)

	-- Legs
	
	local LegTop = TPosition - (Up * Cache.Bounds.Leg.MaxsLength * 1.75)

	local LegAng = Angle(Cache.Bounds.Leg.PitchSet, 0, 0)

	local LegRightSet = Cache.Bounds.Leg.RightSet * 1
	LegRightSet:Rotate(TAngle)

	local LegForwardSet = Cache.Bounds.Leg.ForwardSet * 1
	LegForwardSet:Rotate(TAngle)

	local LegMins = Cache.Bounds.Leg.Mins
	local LegMaxs = Cache.Bounds.Leg.Maxs

	-- Back legs

	DrawFilledWireframeBox(LegTop + LegRightSet, TAngle + LegAng, LegMins, LegMaxs, Cache.Colors.Gray, true)
	DrawFilledWireframeBox(LegTop + LegForwardSet, TAngle - LegAng, LegMins, LegMaxs, Cache.Colors.Gray, true)

	-- Front legs

	DrawFilledWireframeBox(LegTop - LegRightSet, TAngle + LegAng, LegMins, LegMaxs, Cache.Colors.Gray, true)
	DrawFilledWireframeBox(LegTop - LegForwardSet, TAngle - LegAng, LegMins, LegMaxs, Cache.Colors.Gray, true)
end)
