--[[
	https://github.com/awesomeusername69420/miscellaneous-gmod-stuff

	This was originally made for a DarkRP server called Tranquility Networks which is owned by someone who goes by Pixit, hence the naming scheme.
	However, there is support for more than just things on his server, I just don't feel like renaming it :)
]]

hook.Remove("PreRender", "PixitESCAPE") -- Shitty escape screen removal

local Cache = {
	RainbowColor = Color(255, 255, 255, 255),

	FlatMaterial = CreateMaterial("amblefepgoi", "VertexLitGeneric", {
		["$basetexture"] = "models/debug/debugwhite",
		["$model"] = 1
	}),

	ConVars = {
		Stealer = {
			Active = CreateClientConVar("pixit_stealshit", 1, true, false, "", 0, 1),
			MinimumValue = CreateClientConVar("pixit_stealshit_minimum", 1, true, false, "", 1, 100000),
			Interval = CreateClientConVar("pixit_stealshit_interval", 0.3, true, false, "", 0, 5)
		},

		AccessoryChams = CreateClientConVar("pixit_accessorycham", 1, true, false, "", 0, 1)
	},

	Stealer = {
		Range = 6724, -- https://developer.valvesoftware.com/wiki/Dimensions
		LastStealTime = 0,

		Angles = {
			Reset = false,
			Angle = nil
		},

		Trace = {
			mask = MASK_SOLID
		},

		TraceOutput = {},
		Classes = {},
		ClaimCache = {}
	}
}

Cache.Stealer.Trace.output = Cache.Stealer.TraceOutput -- Optimize traces

---------------------- Helpers ----------------------

local function FixAngle(Angle)
	Angle.pitch = math.Clamp(math.NormalizeAngle(Angle.pitch), -89, 89)
	Angle.yaw = math.NormalizeAngle(Angle.yaw)
	Angle.roll = math.NormalizeAngle(Angle.roll)
end

local function ResetAngle(cmd)
	FixAngle(Cache.Stealer.Angles.Angle) -- Don't really need to fix this but just in case
	cmd:SetViewAngles(Cache.Stealer.Angles.Angle)
	Cache.Stealer.Angles.Reset = false
end

---------------------- Setup Stealers ----------------------

-- Base DarkRP items
Cache.Stealer.Classes.spawned_money = function(cmd, Entity, TraceOutput) -- This is used as a base for anything that needs to be used
	Cache.Stealer.Angles.Angle = cmd:GetViewAngles()

	local AimAngle = ((TraceOutput.HitPos + TraceOutput.HitNormal) - LocalPlayer():EyePos()):Angle() -- Look at it
	FixAngle(AimAngle)

	cmd:SetViewAngles(AimAngle) -- You need to interact with these to claim
	cmd:AddKey(IN_USE)

	Cache.Stealer.Angles.Reset = true

	return true -- Return true to break out of the loop for this tick
end

Cache.Stealer.Classes.spawned_ammo = Cache.Stealer.Classes.spawned_money
Cache.Stealer.Classes.spawned_weapon = Cache.Stealer.Classes.spawned_money

Cache.Stealer.Classes.money_printer = function(cmd, Entity, TraceOutput) -- The default printer spawns money, but some custom printers require interaction first
	if Entity.GetCash and Entity.GetCur then -- https://steamcommunity.com/sharedfiles/filedetails/?id=874053982
		if Entity:GetCash() < Cache.ConVars.Stealer.MinimumValue:GetInt() then
			return false
		end

		return Cache.Stealer.Classes.spawned_money(cmd, Entity, TraceOutput)
	end
end

-- Custom ammo crates
Cache.Stealer.Classes.universal_ammunition = Cache.Stealer.Classes.spawned_money
Cache.Stealer.Classes.universal_ammunition_small = Cache.Stealer.Classes.spawned_money
Cache.Stealer.Classes.universal_ammunition_big = Cache.Stealer.Classes.spawned_money
Cache.Stealer.Classes.universal_ammunition_verybig = Cache.Stealer.Classes.spawned_money

-- https://steamcommunity.com/sharedfiles/filedetails/?id=211851974
Cache.Stealer.Classes.adv_moneyprinter = function(cmd, Entity)
	if Entity:GetPrintA() < Cache.ConVars.Stealer.MinimumValue:GetInt() then
		return false
	end

	net.Start("DataSend")
		net.WriteFloat(2)
		net.WriteEntity(Entity)
		net.WriteEntity(LocalPlayer())
	net.SendToServer()

	return false
end

-- https://steamcommunity.com/sharedfiles/filedetails/?id=673289376 (These printers fucking suck)
Cache.Stealer.Classes.sump_base = function(cmd, Entity, TraceOutput)
	if Entity:GetNWInt("printer_storage") < Cache.ConVars.Stealer.MinimumValue:GetInt() then
		return false
	end

	return Cache.Stealer.Classes.spawned_money(cmd, Entity, TraceOutput)
end

-- https://github.com/In-memory-of-CODE-BLUE/Bitminers-1
Cache.Stealer.Classes.bit_miner_light = function(cmd, Entity, TraceOutput)
	if Entity:GetMinedCoins(0) < Cache.ConVars.Stealer.MinimumValue:GetInt() then
		return false
	end

	return Cache.Stealer.Classes.spawned_money(cmd, Entity, TraceOutput)
end

Cache.Stealer.Classes.bit_miner_medium = Cache.Stealer.Classes.bit_miner_light
Cache.Stealer.Classes.bit_miner_heavy = Cache.Stealer.Classes.bit_miner_light

-- https://www.gmodstore.com/market/view/tier-printers-the-1-money-printer-system
Cache.Stealer.Classes.tierp_printer = function(_, Entity)
	if Entity:GetMoney() < Cache.ConVars.Stealer.MinimumValue:GetInt() then
		return false
	end

	net.Start("opr_withdraw")
		net.WriteEntity(Entity)
	net.SendToServer()

	if gProtect.GetOwner(Entity) == LocalPlayer() then -- Recharge only our printers
		if Entity:GetBattery() <= 25 then
			net.Start("opr_recharge")
				net.WriteEntity(Entity)
			net.SendToServer()
		end
	end

	return false
end

-- https://www.gmodstore.com/market/view/xenin-care-package-the-superior-airdrop-system
Cache.Stealer.Classes.care_package = function(_, Entity)
	if Cache.Stealer.ClaimCache[Entity] then return false end -- I'd like a better way to do this but oh well

	for i = 1, CarePackage.Config.ItemsPerDrop do
		net.Start("CarePackage.Menu.Loot")
			net.WriteEntity(Entity)
			net.WriteUInt(i, 8)
			net.WriteUInt(CAREPACKAGE_INVENTORY, 1)
		net.SendToServer()
	end

	Cache.Stealer.ClaimCache[Entity] = true

	return false
end

---------------------- Hooks ----------------------

hook.Add("CreateMove", "PixitStealMoney", function(cmd) -- My money now bitches!
	if cmd:CommandNumber() == 0 then return end -- Amazing video game

	if Cache.Stealer.Angles.Reset then
		ResetAngle(cmd)
		return
	end

	if not Cache.ConVars.Stealer.Active:GetBool() or not LocalPlayer():Alive() then return end

	local CurTime = SysTime()

	if CurTime - Cache.Stealer.LastStealTime >= Cache.ConVars.Stealer.Interval:GetFloat() then
		if table.Count(Cache.Stealer.ClaimCache) > 0 do
			local Removals = {}

			for k, _ pairs(Cache.Stealer.ClaimCache) do
				if not IsValid(k) then
					Removals[#Removals + 1] = k
				end
			end

			for i = 1, #Removals do
				Cache.Stealer.ClaimCache[Removals[i]] = nil
			end
		end

		local Entities = ents.GetAll() -- Bleh, find in sphere is jank with the distance
		local LocalCenter = LocalPlayer():WorldSpaceCenter()
		local MaxDistance = Cache.Stealer.Range
		local Classes = Cache.Stealer.Classes

		local Trace = Cache.Stealer.Trace
		Trace.start = LocalPlayer():EyePos()
		Trace.filter = LocalPlayer()

		local TraceOutput = Cache.Stealer.TraceOutput

		for i = 1, #Entities do
			local Entity = Entities[i]

			Trace.endpos = Entity:WorldSpaceCenter()
			util.TraceLine(Trace)

			if Entity:GetModel() ~= nil and util.IsValidModel(Entity:GetModel()) and (TraceOutput.Entity ~= Entity or (TraceOutput.HitPos + TraceOutput.HitNormal):DistToSqr(LocalCenter) > MaxDistance) then
				continue
			end

			local Class = Entity:GetClass()

			if Classes[Class] and Classes[Class](cmd, Entity, TraceOutput) then
				break
			end
		end

		Cache.Stealer.LastStealTime = CurTime
	end
end)

hook.Add("Think", "PixitUpdateRainbowColor", function()
	local NewRainbow = HSVToColor((SysTime() % 6) * 60, 1, 1)

	Cache.RainbowColor.r = NewRainbow.r
	Cache.RainbowColor.g = NewRainbow.g
	Cache.RainbowColor.b = NewRainbow.b
end)

hook.Add("PreDrawEffects", "PixitAccessoryRGB", function()
	local Accessories = LocalPlayer().SH_Accessories
	if not Accessories then return end

	if not Cache.ConVars.AccessoryChams:GetBool() then return end
	if not LocalPlayer():ShouldDrawLocalPlayer() then return end

	render.MaterialOverride(Cache.FlatMaterial)
	render.SetColorModulation(Cache.RainbowColor.r / 255, Cache.RainbowColor.g / 255, Cache.RainbowColor.b / 255)

	for _, v in pairs(Accessories) do
		if not IsValid(v) then continue end -- Dumbshit addon
		v:DrawModel()
	end

	render.MaterialOverride(nil)
	render.SetColorModulation(1, 1, 1)
end)
