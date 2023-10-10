--[[
	https://github.com/awesomeusername69420/miscellaneous-gmod-stuff
]]

surface.CreateFont("Wowza", {
	font = "Verdana",
	size = 12,
	antialias = false,
	outline = true
})

local Cache = {
	Players = {}
}

local function ValidEntity(entity)
	if not IsValid(entity) then
		return false
	end

	if not entity:IsPlayer() then
		return true
	end

	return entity ~= LocalPlayer() and entity:Alive() and entity:Team() ~= TEAM_SPECTATOR and entity:GetObserverMode() == 0 and not entity:IsDormant()
end

local function GetSortedPlayers()
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

local function GetCorners(entity)
	if not IsValid(entity) then
		return 0, 0, 0, 0
	end

	local mins, maxs = entity:OBBMins(), entity:OBBMaxs()

	local coords = {
		entity:LocalToWorld(mins):ToScreen(),
    	entity:LocalToWorld(Vector(mins.x, maxs.y, mins.z)):ToScreen(),
    	entity:LocalToWorld(Vector(maxs.x, maxs.y, mins.z)):ToScreen(),
    	entity:LocalToWorld(Vector(maxs.x, mins.y, mins.z)):ToScreen(),
    	entity:LocalToWorld(maxs):ToScreen(),
    	entity:LocalToWorld(Vector(mins.x, maxs.y, maxs.z)):ToScreen(),
    	entity:LocalToWorld(Vector(mins.x, mins.y, maxs.z)):ToScreen(),
    	entity:LocalToWorld(Vector(maxs.x, mins.y, maxs.z)):ToScreen()
	}

	local left, right, top, bottom = coords[1].x, coords[1].x, coords[1].y, coords[1].y

	for _, v in ipairs(coords) do
		if left > v.x then
			left = v.x
		end

		if top > v.y then
			top = v.y
		end

		if right < v.x then
			right = v.x
		end

		if bottom < v.y then
			bottom = v.y
		end
	end

	return math.Round(left), math.Round(right), math.Round(top), math.Round(bottom)
end

local function GetHealthColor(entity)
	if not IsValid(entity) then
		return color_white
	end

	local max = entity:GetMaxHealth()
	local health = math.Clamp(entity:Health(), 0, max)
	local percent = health * (health / max)

	if entity._LastHealth ~= health or not entity._LastHealthColor then
		entity._LastHealth = health
		entity._LastHealthColor = Color(255 - (percent * 2.55), percent * 2.55, 0)
	end
		
	return entity._LastHealthColor, percent / health
end

local function GetWeaponName(weapon)
	if not IsValid(weapon) then
		return ""
	end

	local name = weapon:GetClass()

	if weapon.GetPrintName then
		local printname = weapon:GetPrintName()

		if printname == "<MISSING SWEP PRINT NAME>" then
			return name
		end

		return language.GetPhrase(printname)
	end

	return name
end

-- Hooks n stuff

timer.Create("@@@@@@@@@@@@@@@@@@@", 0.3, 0, function()
	Cache.Players = {}

	for _, v in ipairs(GetSortedPlayers()) do
		Cache.Players[#Cache.Players + 1] = v
		v:SetupBones()
	end
end)

hook.Add("DrawOverlay", "@@@@@@@@@@@", function()
	surface.SetFont("Wowza")
	surface.SetTextColor(255, 255, 255, 255)

	for _, v in ipairs(Cache.Players) do
		if not ValidEntity(v) then continue end

		if not v:LocalToWorld(v:OBBCenter()):ToScreen().visible then continue end

		surface.SetDrawColor(255, 0, 0, 255)

		-- Skeleton

		for i = 0, v:GetBoneCount() - 1 do
			local parent = v:GetBoneParent(i)

			if not parent or parent == -1 then continue end

			local pbhb = v:BoneHasFlag(parent, BONE_USED_BY_HITBOX)
			local bhb = v:BoneHasFlag(i, BONE_USED_BY_HITBOX)

			if not pbhb or not bhb then continue end

			local pbm = v:GetBoneMatrix(parent)
			local bm = v:GetBoneMatrix(i)

			if not pbm or not bm then continue end

			local ppos = pbm:GetTranslation()
			local pos = bm:GetTranslation()

			if not ppos or not pos then continue end

			ppos = ppos:ToScreen()
			pos = pos:ToScreen()

			surface.DrawLine(ppos.x, ppos.y, pos.x, pos.y)
		end

		-- Box

		local left, right, top, bottom = GetCorners(v)
		local w, h = right - left, bottom - top

		surface.DrawOutlinedRect(left, top, w - 1, h - 1)

		surface.SetDrawColor(0, 0, 0, 255)
		surface.DrawOutlinedRect(left - 1, top - 1, w + 1, h + 1)
		surface.DrawOutlinedRect(left + 1, top + 1, w - 3, h - 3)

		-- Health

		local hw, s = 4, 2

		local health = v:Health()
		local tw, th = surface.GetTextSize(health)

		surface.DrawOutlinedRect(left - s - hw, top - 1, hw, h + 1)

		surface.SetDrawColor(44, 44, 44, 255)
		surface.DrawRect((left - s - hw) + 1, top, hw - 2, h - 1)

		local color, percent = GetHealthColor(v)
		local healthScreen = math.Round((h * percent) - 1)
		local healthPos = (bottom - healthScreen) - 1

		surface.SetDrawColor(color)
		surface.DrawRect((left - s - hw) + 1, healthPos, hw - 2, healthScreen)

		if health ~= v:GetMaxHealth() then
			surface.SetTextPos(left - s - hw - tw, math.Clamp(healthPos, healthPos - (th / 3), bottom - th))
			surface.DrawText(health)
		end

		-- Name

		local name = v:GetName()
		tw, th = surface.GetTextSize(name)

		surface.SetTextPos(left + (w / 2) - (tw / 2), top - th)
		surface.DrawText(name)

		-- Weapon

		name = GetWeaponName(v:GetActiveWeapon())
		tw, th = surface.GetTextSize(name)

		surface.SetTextPos(left + (w / 2) - (tw / 2), bottom)
		surface.DrawText(name)
	end
end)
