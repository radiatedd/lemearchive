--[[
	https://github.com/awesomeusername69420/miscellaneous-gmod-stuff

	Deletes all entities around you
]]

local Blacklist = {
	CLuaEffect = true,
	C_BaseAnimating = true,
	C_BaseEntity = true,
	func_brush = true,
	viewmodel = true,
	worldspawn = true,
}

timer.Create("DeleteEnts", 0.3, 0, function()
	local LocalPlayer = LocalPlayer()

	for _, v in ipairs(ents.GetAll()) do
		if Blacklist[v:GetClass()] then continue end
		if not properties.CanBeTargeted(v, LocalPlayer) then continue end
		if not gamemode.Call("CanProperty", LocalPlayer, "remover", v) then continue end

		print("Writing", v)

		net.Start("properties")
			net.WriteString("remove")
			net.WriteEntity(v)
		net.SendToServer()
	end
end)
