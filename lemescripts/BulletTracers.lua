--[[
	https://github.com/awesomeusername69420/miscellaneous-gmod-stuff
]]

local color_red = Color(255, 0, 0, 255)

hook.Add("EntityFireBullets", "", function(entity, data)
	if not entity or entity ~= LocalPlayer() or not data then return end

	local hull = Vector(data.HullSize, data.HullSize, data.HullSize)

	local tr = util.TraceHull({
		start = data.Src,
		endpos = data.Src + (data.Dir * data.Distance),
		mins = hull * -1,
		maxs = hull,
		mask = MASK_SHOT,
		filter = {entity, data.IgnoreEntity}
	})

	debugoverlay.Line(data.Src, tr.HitPos, 5, color_red, false)
end)
