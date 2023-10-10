--[[
	https://github.com/awesomeusername69420/miscellaneous-gmod-stuff

	leme's sub-par hitscan style aimbot with an FOV triangle

	Requires https://github.com/awesomeusername69420/miscellaneous-gmod-stuff/blob/main/includes/modules/md5.lua	(For no spread)
	Requires Frozen2																								(Engine prediction)
]]

pcall(include, "includes/modules/md5.lua")
pcall(require, "frozen2")

StartPrediction = StartPrediction or function() end
EndPrediction = EndPrediction or function() end

local stuff = {
	Order = { -- Scan in this order
		HITGROUP_HEAD,
		HITGROUP_CHEST,
		HITGROUP_STOMACH
	},

	CalcView = {
		EyePos = EyePos(),
		EyeAngles = EyeAngles(),
		FOV = LocalPlayer():GetFOV(),
		ZNear = 2.6
	},

	NotGuns = { -- Funny classes
		"bomb",
		"c4",
		"climb",
		"fist",
		"gravity gun",
		"grenade",
		"hand",
		"ied",
		"knife",
		"physics gun",
		"slam",
		"sword",
		"tool gun"
	},

	ActuallyGuns = { -- Even funnier classes
		"handgun"
	},

	FOVTri = {
		{x = 0, y = 0},
		{x = 0, y = 0},
		{x = 0, y = 0},
	},

	ConVars = {
		cl_interp = GetConVar("cl_interp"),

		sv_gravity = GetConVar("sv_gravity"),

		m_pitch = GetConVar("m_pitch"),
		m_yaw = GetConVar("m_yaw")
	},

	ExtraChecks = {
		-- These are taken directly from the weapon's base code with minor changes
		-- I couldn't be bothered to clean any of it up

		bobs = function(weapon) -- M9K
			if not IsValid(weapon) then return false end

			if not weapon.Owner:IsPlayer() then return false end
			if weapon.Owner:KeyDown(IN_SPEED) or weapon.Owner:KeyDown(IN_RELOAD) then return false end
			if weapon:GetNWBool("Reloading", false) then return false end
			if weapon:Clip1() < 1 then return false end

			return true
		end,

		cw = function(weapon)
			if not IsValid(weapon) then return false end

			if not weapon:canFireWeapon(1) or not weapon:canFireWeapon(2) or not weapon:canFireWeapon(3) then return false end
			if weapon.Owner:KeyDown(IN_USE) and CustomizableWeaponry.quickGrenade.canThrow(weapon) then return false end
			if weapon.dt.State == CW_AIMING and weapon.dt.M203Active and weapon.M203Chamber then return false end
			if weapon.dt.Safe then return false end
			if weapon:Clip1() == 0 then return false end
			if weapon.BurstAmount and weapon.BurstAmount > 0 then return false end

			return true
		end,

		fas2 = function(weapon)
			if not IsValid(weapon) then return false end

			if weapon.FireMode == "safe" then return false end
			if weapon.BurstAmount > 0 and weapon.dt.Shots >= weapon.BurstAmount then return false end
			if weapon.ReloadState ~= 0 then return false end
			if weapon.dt.Status == FAS_STAT_CUSTOMIZE then return false end
			if weapon.Cooking or weapon.FuseTime then return false end
			if weapon.Owner:KeyDown(IN_USE) and weapon:CanThrowGrenade() then return false end
			if weapon.dt.Status == FAS_STAT_SPRINT or weapon.dt.Status == FAS_STAT_QUICKGRENADE then return false end
			if weapon:Clip1() <= 0 or weapon.Owner:WaterLevel() >= 3 then return false end
			if weapon.CockAfterShot and not weapon.Cocked then return false end

			return true
		end,

		tfa = function(weapon)
			if not IsValid(weapon) then return false end

			local weapon2 = weapon:GetTable()

			local v = hook.Run("TFA_PreCanPrimaryAttack", weapon)
			if v ~= nil then return v end

			local stat = weapon:GetStatus()
			if stat == TFA.Enum.STATUS_RELOADING_WAIT or stat == TFA.Enum.STATUS_RELOADING then return false end

			if weapon:IsSafety() then return false end
			if weapon:GetSprintProgress() >= 0.1 and not weapon:GetStatL("AllowSprintAttack", false) then return false end
			if weapon:GetStatL("Primary.ClipSize") <= 0 and weapon:Ammo1() < weapon:GetStatL("Primary.AmmoConsumption") then return false end
			if weapon:GetPrimaryClipSize(true) > 0 and weapon:Clip1() < weapon:GetStatL("Primary.AmmoConsumption") then return false end
			if weapon2.GetStatL(weapon, "Primary.FiresUnderwater") == false and weapon:GetOwner():WaterLevel() >= 3 then return false end

			v = hook.Run("TFA_CanPrimaryAttack", self)
			if v ~= nil then return v end

			if weapon:CheckJammed() then return false end

			return true
		end,

		arccw = function(weapon)
			if not IsValid(weapon) then return false end

			if IsValid(weapon:GetHolster_Entity()) then return false end
			if weapon:GetHolster_Time() > 0 then return false end
			if weapon:GetReloading() then return false end
			if weapon:GetWeaponOpDelay() > CurTime() then return false end
			if weapon:GetHeatLocked() then return false end
			if weapon:GetState() == ArcCW.STATE_CUSTOMIZE then return false end
			if weapon:BarrelHitWall() > 0 then return false end
			if weapon:GetNWState() == ArcCW.STATE_SPRINT and not (weapon:GetBuff_Override("Override_ShootWhileSprint", weapon.ShootWhileSprint)) then return false end
			if (weapon:GetBurstCount() or 0) >= weapon:GetBurstLength() then return false end
			if weapon:GetNeedCycle() then return false end
			if weapon:GetCurrentFiremode().Mode == 0 then return false end
			if weapon:GetBuff_Override("Override_TriggerDelay", weapon.TriggerDelay) and weapon:GetTriggerDelta() < 1 then return false end
			if weapon:GetBuff_Hook("Hook_ShouldNotFire") then return false end
			if weapon:GetBuff_Hook("Hook_ShouldNotFireFirst") then return false end

			return true
		end
	},

	WeaponCones = {},

	BuildModeNetVars = {
		"BuildMode", -- Libby's
		"buildmode", -- Fun Server
		"_Kyle_Buildmode", -- Workshop addon
		"BuildMode"
	},

	GodModeNetVars = {
		"has_god" -- Fun Server + LBG
	},

	HvHModeNetVars = {
		"HVHER" -- Fun Server + LBG
	},

	og = LocalPlayer():EyeAngles(),

	ServerTime = CurTime(),
	TickInterval = engine.TickInterval(),

	FOV = 16,
	AimKey = MOUSE_5
}

local function GetEyePos() -- Quickerish ways of getting CalcView information from the CalcView hook
	return stuff.CalcView.EyePos
end

local function GetEyeAngles()
	return stuff.CalcView.EyeAngles
end

local function GetFOV()
	return stuff.CalcView.FOV
end

local function GetZNear()
	return stuff.CalcView.ZNear
end

local function FixAngle(ang)
	ang = ang or angle_zero
	
	return Angle(math.Clamp(math.NormalizeAngle(ang.pitch), -89, 89), math.NormalizeAngle(ang.yaw), math.NormalizeAngle(ang.roll)) -- Fixes an angle to (-89, 89), (-180, 180), (-180, 180)
end

local function GetBase(weapon)
	if not IsValid(weapon) or not weapon.Base then
		return nil
	end

	return weapon.Base:lower():Split("_")[1]
end

local function WeaponCanShoot(weapon)
	if not IsValid(weapon) then
		return false
	end

	local name = weapon:GetPrintName():lower()

	for _, v in ipairs(stuff.NotGuns) do -- Some guns are retarded
		if name == v then
			return false
		end

		if name:find(v) then
			local breakouter = false

			for _, t in ipairs(stuff.ActuallyGuns) do -- language.Add is dumb
				if name:find(t) then
					breakouter = true
					break
				end
			end

			if breakouter then
				continue
			end

			return false
		end
	end

	local base = GetBase(weapon) or ""
	local ExtraCheck = true 

	if stuff.ExtraChecks[base] then
		ExtraCheck = stuff.ExtraChecks[base](weapon)
	end

	return stuff.ServerTime >= weapon:GetNextPrimaryFire() and ExtraCheck
end

local function IsVisible(pos, entity, hitgroup)
	pos = pos or vector_origin
	
	local tr = util.TraceLine({
		start = GetEyePos(),
		endpos = pos,
		filter = LocalPlayer(),
		mask = MASK_SHOT,
		ignoreworld = false
	})
	
	if entity then
		if hitgroup then
			return tr.Entity == entity and tr.HitGroup == hitgroup -- Tracer hit the entity we wanted it to and the hitgroup we asked for
		else
			return tr.Entity == entity -- Tracer hit the entity we wanted it to
		end
	else
		return tr.Fraction == 1 -- Trace didn't hit anything
	end
end

local function InGodMode(player)
	if not IsValid(player) then return false end

	if player:HasGodMode() then return true end -- This doesn't work by default

	for _, v in ipairs(stuff.GodModeNetVars) do
		if player:GetNWBool(v, false) then
			return true
		end
	end

	return false
end

local function InBuildMode(player)
	if not IsValid(player) then return false end

	for _, v in ipairs(stuff.BuildModeNetVars) do
		if player:GetNWBool(v, false) then
			return true
		end
	end

	return false
end

local function InOpposingHVHMode(player)
	if not IsValid(player) then return false end

	local localhvh = false
	local plyhvh = false

	for _, v in ipairs(stuff.HvHModeNetVars) do
		if localhvh and plyhvh then break end

		localhvh = LocalPlayer():GetNWBool(v, false)
		plyhvh = player:GetNWBool(v, false)
	end

	return localhvh ~= plyhvh
end

local function ValidEntity(entity) -- Don't try to aim at dumb shit
	if not IsValid(entity) then
		return false
	end

	if not entity:IsPlayer() then -- Some checks below are player only checks
		return true
	end

	return entity ~= LocalPlayer() and entity:Alive() and entity:Team() ~= TEAM_SPECTATOR and entity:GetObserverMode() == 0 and not entity:IsDormant()
end

local function GetSortedPlayers() -- Sorts players by distance (Should be used for rendering ESP but I didn't include ESP here so it's not super useful)
	local ret = {}
	
	for _, v in ipairs(player.GetAll()) do
		if not ValidEntity(v) then
			continue
		end
		
		ret[#ret + 1] = v
	end
	
	local lpos = LocalPlayer():GetPos()
	
	table.sort(ret, function(a, b)
		return a:GetPos():DistToSqr(lpos) > b:GetPos():DistToSqr(lpos)
	end)
	
	return ret
end

local function Sign(p1, p2, p3) -- https://en.wikipedia.org/wiki/Barycentric_coordinate_system
	if not p1 or not p2 or not p3 then return 0 end

	return (p1.x - p3.x) * (p2.y - p3.y) - (p2.x - p3.x) * (p1.y - p3.y)
end

local function IsPointInTriangle(pt, tri)
	if not pt or not tri then return false end

	local v1, v2, v3 = tri[1], tri[2], tri[3]
	local n, p

	local test1 = Sign(pt, v1, v2)
	local test2 = Sign(pt, v2, v3)
	local test3 = Sign(pt, v3, v1)

	n = test1 < 0 or test2 < 0 or test3 < 0
	p = test1 > 0 or test2 > 0 or test3 > 0

	return not (n and p)
end

local function GetHitBoxPositions(entity) -- Scans hitboxes for aim points
	if not IsValid(entity) then
		return nil
	end

	local null = true

	local data = {
		[HITGROUP_HEAD] = {},
		[HITGROUP_CHEST] = {},
		[HITGROUP_STOMACH] = {}
	}

	for hitset = 0, entity:GetHitboxSetCount() - 1 do
		for hitbox = 0, entity:GetHitBoxCount(hitset) - 1 do
			local hitgroup = entity:GetHitBoxHitGroup(hitbox, hitset)

			if not hitgroup or not data[hitgroup] then continue end -- Should be impossible but just in case

			local bone = entity:GetHitBoxBone(hitbox, hitset)
			local mins, maxs = entity:GetHitBoxBounds(hitbox, hitset)

			if not bone or not mins or not maxs then continue end

			local bmatrix = entity:GetBoneMatrix(bone)

			if not bmatrix then continue end

			local pos, ang = bmatrix:GetTranslation(), bmatrix:GetAngles()

			if not pos or not ang then continue end

			mins:Rotate(ang)
			maxs:Rotate(ang)

			table.insert(data[hitgroup], pos + ((mins + maxs) * 0.5))

			null = false
		end
	end

	if null then
		return nil -- No hitboxes found
	end

	return data
end

local function GetBoneDataPosition(bonename) -- Turns bone names into hitgroups so I don't have to do some dumb if-else shit
	if not bonename then
		return nil
	end

	bonename = bonename:lower()

	if bonename:find("head") then
		return HITGROUP_HEAD
	end

	if bonename:find("spine") then -- Due to the nature of this, bone scanning will have more points than hitbox scanning, but bones aren't centered to the hitbox
		return HITGROUP_CHEST
	end

	if bonename:find("pelvis") then
		return HITGROUP_STOMACH
	end

	return nil
end

local function GetBonePositions(entity) -- Scans bones
	if not IsValid(entity) then
		return nil
	end

	entity:InvalidateBoneCache() -- Prevent some matrix issues
	entity:SetupBones()

	local null = true

	local data = {
		[HITGROUP_HEAD] = {},
		[HITGROUP_CHEST] = {},
		[HITGROUP_STOMACH] = {}
	}

	for bone = 0, entity:GetBoneCount() - 1 do
		local name = entity:GetBoneName(bone)

		if not name or name == "__INVALIDBONE__" then continue end -- Fuck you and your retarded models

		name = name:lower()

		local boneloc = GetBoneDataPosition(name)

		if not boneloc then continue end

		local bonematrix = entity:GetBoneMatrix(bone)

		if not bonematrix then continue end

		local pos = bonematrix:GetTranslation()

		if not pos then continue end

		table.insert(data[boneloc], pos)

		null = false
	end

	if null then
		return nil -- No bones found
	end

	return data
end

local function GetAimPositions(entity)
	if not IsValid(entity) then
		return nil
	end

	local data = GetHitBoxPositions(entity) or GetBonePositions(entity) or { -- OBBCenter fallback (For error models and whatnot)
		[HITGROUP_HEAD] = {
			entity:LocalToWorld(entity:OBBCenter())
		}
	}

	return data
end

local function GetAimPosition(entity)
	if not IsValid(entity) then
		return nil
	end

	local data = GetAimPositions(entity)

	for _, set in ipairs(stuff.Order) do -- Scans through the positions to find visible ones
		if not data[set] then continue end

		for _, v in ipairs(data[set]) do
			if IsVisible(v, entity) then
				return v
			end
		end
	end

	return nil
end

local function GetTarget(quick) -- Gets the player whose aimbot points are closest to the center of the screen
	local x, y = ScrW() * 0.5, ScrH() * 0.5

	local best = math.huge
	local entity = nil

	for _, v in ipairs(GetSortedPlayers()) do
		if InGodMode(v) or InBuildMode(v) or InOpposingHVHMode(v) then continue end

		local obbpos = v:LocalToWorld(v:OBBCenter())
		local pos = obbpos:ToScreen() -- Quick checks OBB only
	
		local cur = math.Dist(pos.x, pos.y, x, y)
	
		if IsVisible(obbpos, v) and cur < best and IsPointInTriangle(pos, stuff.FOVTri) then -- Closest player inside the FOV triangle
			best = cur
			entity = v
		end

		if quick then continue end

		local data = GetAimPositions(v)

		for _, set in ipairs(stuff.Order) do
			if not data[set] then continue end
	
			for _, d in ipairs(data[set]) do
				if not IsVisible(d, v) then continue end

				pos = d:ToScreen()
				cur = math.Dist(pos.x, pos.y, x, y)

				if cur < best and IsPointInTriangle(pos, stuff.FOVTri) then
					best = cur
					entity = v
				end
			end
		end
	end

	return entity
end

local function UpdateCalcViewData(data) -- Gets CalcView information because EyePos() and EyeAngles() are only reliable in certain situations
	if not data then return end

	stuff.CalcView.EyePos = data.origin
	stuff.CalcView.EyeAngles = data.angles
	stuff.CalcView.FOV = data.fov
	stuff.CalcView.ZNear = data.znear
end

local function FixMovement(cmd)
	if not cmd then return end

	local MovementVector = Vector(cmd:GetForwardMove(), cmd:GetSideMove(), 0)

	local CMDAngle = cmd:GetViewAngles()
	local Yaw = CMDAngle.yaw - stuff.og.yaw + MovementVector:Angle().yaw
	
	if (CMDAngle.pitch + 90) % 360 > 180 then
		Yaw = 180 - Yaw
	end
	
	Yaw = ((Yaw + 180) % 360) - 180
	
	local Speed = math.sqrt((MovementVector.x * MovementVector.x) + (MovementVector.y * MovementVector.y))
	Yaw = math.rad(Yaw)
	
	cmd:SetForwardMove(math.cos(Yaw) * Speed)
	cmd:SetSideMove(math.sin(Yaw) * Speed)
end

local function CalculateAimAngle(pos, target)
	if not IsValid(target) then return angle_zero end

	pos = pos or vector_origin

	local weapon = LocalPlayer():GetActiveWeapon()

	if IsValid(weapon) then
		if weapon:GetClass() == "weapon_vj_flaregun" then
			local distance = pos:Distance(LocalPlayer():GetPos())

			pos = target:LocalToWorld(target:OBBCenter()) + (vector_up * (distance * 0.04))

        	local velocity = target:GetAbsVelocity()
        	
        	velocity.z = not target:IsOnGround() and velocity.z - (stuff.ConVars.sv_gravity:GetFloat()  * stuff.TickInterval) or velocity.z

        	local comptime = (distance / 3500) + stuff.ConVars.cl_interp:GetFloat()

        	pos = pos + (velocity * comptime)
		end
	end

	return (pos - LocalPlayer():EyePos()):Angle()
end

local function CalculateNoSpread(weapon, cmdnbr, ang)
	ang = ang or stuff.og
	local weaponcone = stuff.WeaponCones[weapon:GetClass()]

	if not md5 or not weaponcone then
		return ang
	end

	local seed = md5.PseudoRandom(cmdnbr)

	local x = md5.EngineSpread[seed][1]
	local y = md5.EngineSpread[seed][2]

	local forward = ang:Forward()
	local right = ang:Right()
	local up = ang:Up()

	local spreadvector = forward + (x * weaponcone.x * right * -1) + (y * weaponcone.y * up * -1)
	local spreadangle = spreadvector:Angle()
	spreadangle:Normalize()

	return spreadangle
end

local function CalculateViewPunch(weapon) -- Stupid ass HL2 guns
	if not weapon:IsScripted() then return LocalPlayer():GetViewPunchAngles() end
	return angle_zero
end

hook.Add("EntityFireBullets", "", function(entity, data)
	if entity ~= LocalPlayer() then return end

	local weapon = entity:GetActiveWeapon()
	if not IsValid(weapon) then return end

	stuff.WeaponCones[weapon:GetClass()] = data.Spread
end)

hook.Add("Move", "", function()
	if not IsFirstTimePredicted() then return end

	stuff.ServerTime = CurTime() + stuff.TickInterval
end)

hook.Add("DrawOverlay", "", function()
	local w = ScrW()
	local x, y = w * 0.5, ScrH() * 0.5
	local fovrad = (math.tan(math.rad(stuff.FOV)) / math.tan(math.rad(GetFOV() * 0.5)) * w) / GetZNear() -- Converts FOV into radius that could be used to draw an FOV circle

	-- I don't understand this either, I just threw some shit together and it happened to work

	local t = fovrad * 2.3333333333333
	local s = x - (t / 2)
	local m = fovrad
	local offset_y = 0 - (fovrad / 3)

	stuff.FOVTri = {
		{x = s, y = (y + m) + offset_y},
		{x = s + t, y = (y + m) + offset_y},
		{x = x, y = (y - m) + offset_y}
	}

	local v1, v2, v3 = stuff.FOVTri[1], stuff.FOVTri[2], stuff.FOVTri[3]

	surface.SetDrawColor(color_white)
	surface.DrawLine(v1.x, v1.y, v2.x, v2.y)
	surface.DrawLine(v2.x, v2.y, v3.x, v3.y)
	surface.DrawLine(v3.x, v3.y, v1.x, v1.y)
end)

hook.Add("CreateMove", "", function(cmd)
	stuff.og = stuff.og or cmd:GetViewAngles()

	stuff.og.pitch = stuff.og.pitch + (cmd:GetMouseY() * stuff.ConVars.m_pitch:GetFloat())
	stuff.og.yaw = stuff.og.yaw - (cmd:GetMouseX() * stuff.ConVars.m_yaw:GetFloat())

	stuff.og = FixAngle(stuff.og)

	if cmd:CommandNumber() == 0 then
		if cmd:KeyDown(IN_USE) then
			stuff.og = FixAngle(cmd:GetViewAngles())
		else
			cmd:SetViewAngles(stuff.og)
		end

		return
	end

	local Weapon = LocalPlayer():GetActiveWeapon()

	if input.IsButtonDown(stuff.AimKey) and WeaponCanShoot(Weapon) then
		local target = GetTarget()
		if not IsValid(target) then return end

		local pos = GetAimPosition(target)
		if not pos then return end

		StartPrediction(cmd)
			local punchang = CalculateViewPunch(Weapon)
			local aimang = CalculateAimAngle(pos, target)
			local spreadang = CalculateNoSpread(Weapon, cmd:CommandNumber(), aimang)

			cmd:SetViewAngles(FixAngle(spreadang - punchang))
			FixMovement(cmd)

			cmd:AddKey(IN_ATTACK)
		EndPrediction(cmd)
	else
		if cmd:KeyDown(IN_ATTACK) and IsValid(Weapon) then
			local punchang = CalculateViewPunch(Weapon)
			local spreadang = CalculateNoSpread(Weapon, cmd:CommandNumber())

			cmd:SetViewAngles(FixAngle(spreadang - punchang))
			FixMovement(cmd)
		end
	end
end)

hook.Add("CalcView", "", function(ply, pos, ang, fov, zn, zf)
	if not IsValid(ply) then return end

	local CalcAng = stuff.og * 1

	local view = {
		origin = pos,
		angles = CalcAng,
		fov = fov,
		znear = zn,
		zfar = zf
	}

	local vehicle = ply:GetVehicle()

	if IsValid(vehicle) then
		UpdateCalcViewData(view)

		return hook.Run("CalcVehicleView", vehicle, ply, view)
	end

	local weapon = ply:GetActiveWeapon()

	if IsValid(weapon) then
		local wCalcView = weapon.CalcView

		if wCalcView then
			local WeaponAngle = angle_zero

			view.origin, WeaponAngle, view.fov = wCalcView(weapon, ply, view.origin * 1, CalcAng * 1, view.fov)

			if GetBase(weapon) ~= "arccw" then
				view.angles = WeaponAngle
			end
		end
	end

	UpdateCalcViewData(view)

	return view
end)
