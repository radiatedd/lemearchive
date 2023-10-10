--[[
	https://github.com/awesomeusername69420/miscellaneous-gmod-stuff

	Requires https://github.com/Facepunch/garrysmod/pull/1590
]]

include("includes/modules/outline.lua")

local color_red = Color(255, 0, 0)
local color_blue = Color(0, 255, 255)

local pEnts = {}

hook.Add("PreDrawHalos", "rgd_Outline", function()
	outline.Add(pEnts, color_red, OUTLINE_MODE_BOTH)
end)

hook.Add("HUDPaint", "rgd_Skeleton", function()
	for i = #pEnts, 1, -1 do
		if not IsValid(pEnts[i]) then
			table.remove(pEnts, i)
		end
	end

	for i = 1, #pEnts do
		local v = pEnts[i]

		v:SetupBones()

		surface.SetDrawColor(color_blue)

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
	end
end)

hook.Add("CreateClientsideRagdoll", "rgd_Setup", function(_, ragdoll)
	pEnts[#pEnts + 1] = ragdoll
end)
