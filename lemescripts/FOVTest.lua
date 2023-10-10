--[[
	https://github.com/awesomeusername69420/miscellaneous-gmod-stuff

	Tests if the LocalPlayer is within the FOV of another player
]]

local function HasLOS(Pos, Origin, Entity, Filter)
	return util.TraceLine({
		start = Origin,
		endpos = Pos,
		filter = Filter,
		mask = MASK_SOLID
	}).Entity == Entity
end

local function IsVisibleToEntity(Entity)
	local Pos = LocalPlayer():WorldSpaceCenter()
	local Origin = Entity:EyePos()

	if not HasLOS(Pos, Origin, LocalPlayer(), Entity) then return end

	local eFOV = Entity:GetFOV() + 1

	local Normal = Pos - Origin
	local NormalLength = Normal:Length()
	local LRad = LocalPlayer():BoundingRadius()
	local Max = math.abs(math.cos(math.acos(NormalLength / math.sqrt((NormalLength * NormalLength) + (LRad * LRad))) + (eFOV + 15) * (math.pi /180)))
		
	Normal:Normalize()

	local Dot = Normal:Dot(Entity:EyeAngles():Forward())

	return Dot > Max, Dot
end

hook.Add("Tick", "", function()
	for _, v in ipairs(player.GetAll()) do
		if v == LocalPlayer() then continue end

		local Visible, Distance = IsVisibleToEntity(v)

		if Visible then
			print(tostring(v) .. " can see you! FOV: " .. (100 - (Distance * 100)))
		end
	end
end)
