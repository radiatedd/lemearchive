--[[
	https://github.com/awesomeusername69420/miscellaneous-gmod-stuff

	Requires https://github.com/awesomeusername69420/miscellaneous-gmod-stuff/blob/main/includes/extensions/Render_Ext.lua
]]

include("includes/util/Render_Ext.lua")

local Cache = {
	Colors = {
		[HITGROUP_HEAD] = Color(255, 120, 120),
		[HITGROUP_CHEST] = Color(120, 255, 120),
		[HITGROUP_STOMACH] = Color(255, 255, 120),
		[HITGROUP_LEFTARM] = Color(120, 120, 255),
		[HITGROUP_RIGHTARM] = Color(255, 120, 255),
		[HITGROUP_LEFTLEG] = Color(120, 255, 255),
		[HITGROUP_RIGHTLEG] = Color(255, 255, 255), -- color_white
		[HITGROUP_GENERIC] = Color(255, 255, 255) -- color_white
	},

	Players = {}
}

local function IsValidPlayer(ply)
	if not IsValid(ply) or not ply:IsPlayer() then return false end

	return ply:Alive() and not ply:IsDormant() and ply:Team() ~= TEAM_SPECTATOR and ply:GetObserverMode() == OBS_MODE_NONE
end

local function GetSortedPlayers()
	local players = {}

	for _, v in ipairs(Cache.Players) do
		if not IsValidPlayer(v) then continue end

		players[#players + 1] = v
	end

	local lpos = LocalPlayer():GetPos()

	table.sort(players, function(a, b)
		return a:GetPos():DistToSqr(lpos) > b:GetPos():DistToSqr(lpos)
	end)

	return players
end

local function DrawEntityBoundingBox(ent, entangles)
	if not IsValid(ent) then return end

	render.DrawWireframeBox(ent:GetPos(), entangles and ent:GetAngles() or angle_zero, ent:OBBMins(), ent:OBBMaxs(), Cache.Colors[HITGROUP_CHEST], true)
end

local function DrawEntityHitboxes(ent)
	if not IsValid(ent) then return end

	ent:SetupBones()

	for set = 0, ent:GetHitboxSetCount() - 1 do
		for hitbox = 0, ent:GetHitBoxCount(set) - 1 do
			local bone = ent:GetHitBoxBone(hitbox, set)
			if not bone then continue end

			local bonematrix = ent:GetBoneMatrix(bone)
			if not bonematrix then continue end

			local pos, ang = bonematrix:GetTranslation(), bonematrix:GetAngles()
			if not pos or not ang or pos == obbpos then continue end

			local mins, maxs = ent:GetHitBoxBounds(hitbox, set)
			if not mins or not maxs then continue end

			local hitgroup = ent:GetHitBoxHitGroup(hitbox, set) or HITGROUP_GENERIC

			render.DrawOutlinedBox(pos, ang, mins, maxs, Cache.Colors[hitgroup], ColorAlpha(Cache.Colors[hitgroup], 30), true)
		end
	end
end

timer.Create("ColoredHitboxes_UpdatePlayers", 0.3, 0, function()
	Cache.Players = player.GetAll()
end)

hook.Add("CreateClientsideRagdoll", "ColoredHitboxes_CreateClientsideRagdoll", function(creator, ragdoll)
	if not creator:IsPlayer() then return end

	ragdoll.RenderOverride = function(self)
		self:DrawModel()
		DrawEntityHitboxes(self)
	end
end)

hook.Add("PreDrawEffects", "ColoredHitboxes_PreDrawEffects", function()
	for _, v in ipairs(GetSortedPlayers()) do
		if v == LocalPlayer() and not LocalPlayer():ShouldDrawLocalPlayer() then continue end

		DrawEntityHitboxes(v)
		DrawEntityHitboxes(v:GetActiveWeapon())

		DrawEntityBoundingBox(v)
	end
end)
