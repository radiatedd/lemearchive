--[[
	https://github.com/awesomeusername69420/miscellaneous-gmod-stuff
]]

local DataSize = 4294967295 -- UINT32_MAX; Length of data to send for each part

local SizeString = ("a"):rep(DataSize)
DataSize = SizeString:len()

local EncodedString = util.Base64Encode(SizeString)
local CompressedString = util.Compress(EncodedString)

local function NoOp() return end

local function StopGrabber(Name, Function)
	if net.Receivers[Name:lower()] ~= nil then
		net.Receive(Name, Function)
	end
end

-- https://steamcommunity.com/sharedfiles/filedetails/?id=1342030824
StopGrabber("StartScreengrab", function()
	net.Start("ScreengrabInitCallback")
		net.WriteEntity(LocalPlayer())
		net.WriteUInt(DataSize, 32)
		net.WriteUInt(DataSize, 32)
		net.WriteFloat(CurTime())
	net.SendToServer()

	local PartCount = 0
	timer.Create("ScreengrabSendPart", 1, DataSize, function()
		net.Start("ScreengrabSendPart")
			net.WriteUInt(DataSize, 32)
			net.WriteData(CompressedString, DataSize)
		net.SendToServer()

		net.Start("Progress")
			net.WriteEntity(LocalPlayer())
			net.WriteFloat((PartCount / DataSize) / 2)
		net.SendToServer()

		PartCount = PartCount + 1

		if PartCount == DataSize then
			net.Start("ScreengrabFinished")
			net.SendToServer()
		end
	end)
end)

StopGrabber("ScreengrabInterrupted", function()
	timer.Remove("ScreengrabSendPart")
end)

--[[
	https://steamcommunity.com/sharedfiles/filedetails/?id=2114254167

	Just don't do anything and it'll load infinitely
	GTS has an "Authed" check and if the screengrab wasn't authorized it won't screengrab
	Doing nothing in here is the same as saying "That screengrab isn't authorized"
]]
StopGrabber("GimmeThatScreen_Request", NoOp)

-- https://www.gmodstore.com/market/view/leyscreencap-web-interface-screenshot-livestream
StopGrabber("LeyScreenCap", NoOp) -- Don't do anything and the admin will get no event

-- https://www.gmodstore.com/market/view/eprotect-keep-exploiters-cheaters-at-bay
StopGrabber("eP:Handeler", function()
	net.Start("eP:Handeler")
		net.WriteBit(0)
		net.WriteUInt(1, 2)
		net.WriteUInt(1, 2)
		net.WriteString(SizeString)
	net.SendToServer()
end)

-- Some Discord Integration thing I don't know the name of
StopGrabber("Discord_Screenshot_Upload", function()
	local URL = net.ReadString()
	local Key = net.ReadString()

	http.Post(URL, {
		["picdata"] = BaseStr
	}, function(Body)
		Body = util.JSONToTable(Body)

		if Body and Body.status == "success" then
			net_Start("Discord_Screenshot_Upload")
    		net_SendToServer()
		end
	end, function() end,
	{
		["Authorization"] = "Bearer " .. Key
	})
end)

StopGrabber("Discord_Screenshot_Cache", NoOp) -- Don't cache

-- G-Room's screengrab
StopGrabber("gcap_victim", NoOP)
StopGrabber("gcap_entity", NoOP)
StopGrabber("gcap_caller", NoOp)
