--[[
	https://github.com/awesomeusername69420/miscellaneous-gmod-stuff
]]

local CURRENT_SKY = GetConVar("sv_skyname"):GetString()

if not CURRENT_SKY then
	return error("Failed to get sky name") -- Black magic
end

local SKYBOX_TYPES = {"lf", "ft", "rt", "bk", "dn", "up"} -- Retarded

local CURRENT_SKY_TEXTURES = {}

for i = 1, #SKYBOX_TYPES do
	CURRENT_SKY_TEXTURES[i] = Material("skybox/".. CURRENT_SKY.. SKYBOX_TYPES[i]) -- Get the current sky materials
end

local files, _ = file.Find("materials/skybox/*", "GAME") -- Get list of skyboxes

if #files < 1 then
	return error("No skybox files found") -- Sad times
end

local SKYBOXES = {}
local parsed = {}

for _, v in ipairs(files) do
	local name = v:sub(1, #v - 6) -- Remove file extension and stupid 2 letters at the end
	
	if parsed[name] then continue end
	
	local temp = {}
	local breakouter = false
	
	for i = 1, #SKYBOX_TYPES do
		local mat = Material("skybox/" .. name .. SKYBOX_TYPES[i]) -- This is very laggy the first time the script is loaded
		
		if not mat or mat:IsError() then -- No bueno
			breakouter = true
			break
		end
		
		local texture = mat:GetTexture("$basetexture")
		
		if not texture or texture:IsError() or texture:IsErrorTexture() then -- No bueno
			breakouter = true
			break
		end
		
		temp[#temp + 1] = texture -- Bueno!!
	end
	
	parsed[name] = true
	
	if breakouter then continue end
	
	SKYBOXES[name] = table.Copy(temp)
end

if table.Count(SKYBOXES) < 1 then
	return error("No skyboxes found") -- Sadder times
end

local SELECTED_SKY = CURRENT_SKY -- Debug thingy

local Main = vgui.Create("DFrame")
Main:SetSize(200, 100)
Main:Center()
Main:SetTitle("Skybox Changer")
Main:SetDeleteOnClose(false)

local DropDown = vgui.Create("DComboBox", Main)
DropDown:SetSize(100, 24)
DropDown:Center()

for k, _ in pairs(SKYBOXES) do
	DropDown:AddChoice(k)
end

DropDown.OnSelect = function(self, index, value)
	if not SKYBOXES[value] then return end -- ??????
	
	SELECTED_SKY = value
	
	for i = 1, #CURRENT_SKY_TEXTURES do
		CURRENT_SKY_TEXTURES[i]:SetTexture("$basetexture", SKYBOXES[SELECTED_SKY][i])
	end
end

Main:MakePopup()

concommand.Add("debugcmd", function() -- Funny name
	PrintTable(CURRENT_SKY_TEXTURES)
	print(SELECTED_SKY)
end)

concommand.Add("skybox_menu", function()
	Main:SetVisible(true)
	Main:MakePopup()
end)