--[[
	https://github.com/awesomeusername69420/miscellaneous-gmod-stuff

	ConCommands:
		bfesp_menu	-	Shows the menu
]]

local BONE_USED_BY_HITBOX = BONE_USED_BY_HITBOX
local OBS_MODE_NONE = OBS_MODE_NONE
local TEAM_SPECTATOR = TEAM_SPECTATOR

local angle_zero = angle_zero * 1
local vector_all = Vector(0.3, 0.3, 0.3)

local Color = Color
local IsValid = IsValid
local LocalPlayer = LocalPlayer
local Vector = Vector
local ipairs = ipairs
local pairs = pairs

local ents_GetAll = ents.GetAll

local bit_band = bit.band
local bit_bnot = bit.bnot
local bit_bor = bit.bor
local bit_lshift = bit.lshift

local table_remove = table.remove
local table_sort = table.sort

local surface_DrawLine = surface.DrawLine
local surface_DrawOutlinedRect = surface.DrawOutlinedRect
local surface_DrawRect = surface.DrawRect
local surface_DrawText = surface.DrawText
local surface_GetTextSize = surface.GetTextSize
local surface_SetDrawColor = surface.SetDrawColor
local surface_SetFont = surface.SetFont
local surface_SetTextColor = surface.SetTextColor
local surface_SetTextPos = surface.SetTextPos

local player_GetCount = player.GetCount

local math_Clamp = math.Clamp
local math_Round = math.Round

local vgui_Create = vgui.Create

local language_GetPhrase = language.GetPhrase

local scripted_ents_GetList = scripted_ents.GetList

-- Bitflags

local ESP_ENABLED = 	bit_lshift(1, 0)
local ESP_BOX = 		bit_lshift(1, 1) -- 2D box
local ESP_BOX_TD = 		bit_lshift(1, 2) -- 3D box
local ESP_NAME = 		bit_lshift(1, 3) -- Username / Class
local ESP_WEAPON = 		bit_lshift(1, 4) -- Active weapon
local ESP_SKELETON = 	bit_lshift(1, 5) -- Bones
local ESP_HEALTHBAR = 	bit_lshift(1, 6) -- Health
local ESP_AVATAR =		bit_lshift(1, 7) -- Profile Picture

local Cache = {
	Menu = nil,
	MenuEntityList = nil,

	LocalPlayer = LocalPlayer(),

	HookName = "bfesp",

	EntityList = {},
	PlayerList = {},

	WeaponNameLookup = {},

	Colors = {
		White = Color(255, 255, 255, 255),
		Black = Color(0, 0, 0, 255),
		Gray = Color(45, 45, 45, 255)
	},

	ESP = {
		DoPlayers = true,
		DoEntities = false,

		iEntityClasses = {},

		PlayerFlags = bit_bor(ESP_ENABLED, ESP_BOX, ESP_NAME, ESP_WEAPON, ESP_HEALTHBAR),
		FriendFlags = bit_bor(ESP_ENABLED, ESP_BOX, ESP_NAME, ESP_WEAPON, ESP_HEALTHBAR),
		EntityFlags = bit_bor(ESP_BOX, ESP_NAME),

		PlayerColor = Color(255, 0, 0, 255),
		FriendColor = Color(255, 255, 0, 255),
		EntityColor = Color(200, 0, 255, 255),

		AvatarFrames = {}
	}
}

-- Functions

local function surface_DrawLineScreen(first, second)
	surface.DrawLine(first.x, first.y, second.x, second.y)
end

local function BitflagHasValue(pFlags, pBit)
	return bit_band(pFlags, pBit) ~= 0
end

local function BitflagAddValue(pFlags, pBit)
	return bit_bor(pFlags, pBit)
end

local function BitflagRemoveValue(pFlags, pBit)
	return bit_band(pFlags, bit_bnot(pBit))
end

local function MakeCheckBox(parent, x, y, label, pFlags, pBit)
	local CheckBox = vgui_Create("DCheckBoxLabel", parent)
	CheckBox:SetPos(x, y)
	CheckBox:SetText(label)
	CheckBox:SetChecked(BitflagHasValue(Cache.ESP[pFlags], pBit))
	CheckBox:SetTextColor(Cache.Colors.Black)

	CheckBox._pFlags = pFlags
	CheckBox._pBit = pBit
	
	CheckBox.OnChange = function(self, new)
		local tFlags = Cache.ESP[self._pFlags]

		if new then
			Cache.ESP[self._pFlags] = BitflagAddValue(tFlags, self._pBit)
		else
			Cache.ESP[self._pFlags] = BitflagRemoveValue(tFlags, self._pBit)
		end
	end
end

local function GetCorners(Entity)
	local Mins, Maxs = Entity:GetCollisionBounds()

	local Coords = {
		Entity:LocalToWorld(Mins):ToScreen(),
		Entity:LocalToWorld(Vector(Mins.x, Maxs.y, Mins.z)):ToScreen(),
		Entity:LocalToWorld(Vector(Maxs.x, Maxs.y, Mins.z)):ToScreen(),
		Entity:LocalToWorld(Vector(Maxs.x, Mins.y, Mins.z)):ToScreen(),
		Entity:LocalToWorld(Maxs):ToScreen(),
		Entity:LocalToWorld(Vector(Mins.x, Maxs.y, Maxs.z)):ToScreen(),
		Entity:LocalToWorld(Vector(Mins.x, Mins.y, Maxs.z)):ToScreen(),
		Entity:LocalToWorld(Vector(Maxs.x, Mins.y, Maxs.z)):ToScreen()
	}

	local Left, Right, Top, Bottom = Coords[1].x, Coords[1].x, Coords[1].y, Coords[1].y

	for _, v in ipairs(Coords) do
		if Left > v.x then
			Left = v.x
		end

		if Top > v.y then
			Top = v.y
		end

		if Right < v.x then
			Right = v.x
		end

		if Bottom < v.y then
			Bottom = v.y
		end
	end

	return math_Round(Left), math_Round(Right), math_Round(Top), math_Round(Bottom)
end

local function ESPBoxShouldRotate(Entity)
	return not (Entity:IsPlayer() or Entity:IsNPC() or Entity:IsNextBot())
end

local function GetHealthColor(Entity)
	local max = Entity:GetMaxHealth()
	local health = math_Clamp(Entity:Health(), 0, max)
	local percent = health * (health / max)
	
	if Entity._LastHealth ~= health or not Entity._LastHealthColor then
		Entity._LastHealth = health
		Entity._LastHealthColor = Color(255 - (percent * 2.55), percent * 2.55, 0)
	end
		
	return Entity._LastHealthColor, percent / health
end

local function GetWeaponName(Weapon)
	local Class = Weapon:GetClass()

	if Cache.WeaponNameLookup[Class] then
		return Cache.WeaponNameLookup[Class]
	end

	if Weapon.GetPrintName then
		local PrintName = Weapon:GetPrintName()

		if not PrintName or PrintName == "<MISSING SWEP PRINT NAME>" then
			Cache.WeaponNameLookup[Class] = Class
			return Class
		end

		local Phrase = language_GetPhrase(PrintName)
		Cache.WeaponNameLookup[Class] = Phrase
		return Phrase
	end

	Cache.WeaponNameLookup[Class] = Class
	return Class
end

local function IsFriend(Player)
	if not IsValid(Player) then return false end

	return Player:GetFriendStatus() == "friend"
end

local function GetESPColor(Entity)
	if not Entity:IsPlayer() then
		return Cache.ESP.EntityColor
	end

	return (BitflagHasValue(Cache.ESP.FriendFlags, ESP_ENABLED) and IsFriend(Entity)) and Cache.ESP.FriendColor or Cache.ESP.PlayerColor
end

local function ShouldESP(Entity)
	if not IsValid(Entity) then return false end

	if not Entity:IsPlayer() then
		return Cache.ESP.iEntityClasses[Entity:GetClass()] or false
	end

	return Entity:Alive() and Entity:Team() ~= TEAM_SPECTATOR and Entity:GetObserverMode() == OBS_MODE_NONE and not Entity:IsDormant()
end

local function DoESP(Entity, pFlags)
	if not ShouldESP(Entity) then return end
	if not BitflagHasValue(pFlags, ESP_ENABLED) then return end

	if not Entity:WorldSpaceCenter():ToScreen().visible then return end

	surface_SetFont("BudgetLabel")

	local ESPColor = GetESPColor(Entity)

	if BitflagHasValue(pFlags, ESP_SKELETON) then
		surface_SetDrawColor(ESPColor)

		for i = 0, Entity:GetBoneCount() - 1 do
			local parent = Entity:GetBoneParent(i)
			if not parent or parent == -1 then continue end

			local pbhb = Entity:BoneHasFlag(parent, BONE_USED_BY_HITBOX)
			local bhb = Entity:BoneHasFlag(i, BONE_USED_BY_HITBOX)
			if not pbhb or not bhb then continue end

			local pbm = Entity:GetBoneMatrix(parent)
			local bm = Entity:GetBoneMatrix(i)
			if not pbm or not bm then continue end

			local ppos = pbm:GetTranslation()
			local pos = bm:GetTranslation()
			if not ppos or not pos then continue end

			surface_DrawLineScreen(ppos:ToScreen(), pos:ToScreen())
		end
	end

	local Left, Right, Top, Bottom = GetCorners(Entity) -- Suboptimal but other things need it and giant if statements are for losers
	local w, h = Right - Left, Bottom - Top

	if BitflagHasValue(pFlags, ESP_BOX) then
		surface_SetDrawColor(ESPColor)
		surface_DrawOutlinedRect(Left, Top, w - 1, h - 1)

		surface_SetDrawColor(Cache.Colors.Black)
		surface_DrawOutlinedRect(Left - 1, Top - 1, w + 1, h + 1)
		surface_DrawOutlinedRect(Left + 1, Top + 1, w - 3, h - 3)
	end

	if BitflagHasValue(pFlags, ESP_BOX_TD) then
		local EntityPos = Entity:GetPos()
		local Mins, Maxs = Entity:GetCollisionBounds()
		local EntityAngle = ESPBoxShouldRotate(Entity) and Entity:GetAngles() or angle_zero

		cam.Start3D()
			render.DrawWireframeBox(EntityPos, EntityAngle, Mins + vector_all, Maxs - vector_all, Cache.Colors.Black)
				render.DrawWireframeBox(EntityPos, EntityAngle, Mins, Maxs, ESPColor)
			render.DrawWireframeBox(EntityPos, EntityAngle, Mins - vector_all, Maxs + vector_all, Cache.Colors.Black)
		cam.End3D()
	end

	if BitflagHasValue(pFlags, ESP_HEALTHBAR) then
		local hw, s = 4, 2

		local Health = Entity:Health()

		surface_SetDrawColor(Cache.Colors.Black)
		surface_DrawOutlinedRect(Left - s - hw, Top - 1, hw, h + 1)

		surface_SetDrawColor(Cache.Colors.Gray)
		surface_DrawRect((Left - s - hw) + 1, Top, hw - 2, h - 1)

		local HealthColor, HealthPercent = GetHealthColor(Entity)
		local HealthScreen = math_Round((h * HealthPercent) - 1)
		local HealthPos = (Bottom - HealthScreen) - 1

		surface_SetDrawColor(HealthColor)
		surface_DrawRect((Left - s - hw) + 1, HealthPos, hw - 2, HealthScreen)

		if Health ~= Entity:GetMaxHealth() then
			local tw, th = surface_GetTextSize(Health)

			surface_SetTextColor(Cache.Colors.White)
			surface_SetTextPos(Left - s - hw - tw, math_Clamp(HealthPos, HealthPos - (th / 3), Bottom - th))
			surface_DrawText(Health)
		end
	end

	if BitflagHasValue(pFlags, ESP_NAME) then
		local Name = Entity:IsPlayer() and (Entity:GetName() or Entity:Name() or Entity:Nick()) --[[ Too many name functions for players ]] or Entity:GetClass()
		local tw, th = surface_GetTextSize(Name)

		surface_SetTextColor(Cache.Colors.White)
		surface_SetTextPos(Left + (w / 2) - (tw / 2), Top - th)
		surface_DrawText(Name)
	end

	if BitflagHasValue(pFlags, ESP_WEAPON) and Entity.GetActiveWeapon then
		local Weapon = Entity:GetActiveWeapon()

		if IsValid(Weapon) then
			local Name = GetWeaponName(Weapon)
			local tw, th = surface_GetTextSize(Name)
			
			surface_SetTextColor(Cache.Colors.White)
			surface_SetTextPos(Left + (w / 2) - (tw / 2), Bottom)
			surface_DrawText(Name)
		end
	end

	if Entity:IsPlayer() then -- Player only part
		if BitflagHasValue(pFlags, ESP_AVATAR) and IsValid(Cache.ESP.AvatarFrames[Entity:SteamID64() or "BOT"]) then
			local x = Left + (w / 2) - 8
			local y = Top - 24

			if BitflagHasValue(pFlags, ESP_NAME) then
				local tw, th = surface_GetTextSize(Entity:GetName() or Entity:Name() or Entity:Nick())
				y = y - th
			end

			Cache.ESP.AvatarFrames[Entity:SteamID64() or "BOT"]:PaintAt(x, y)
		end
	end
end

-- Hooks

timer.Create(Cache.HookName, 0.3, 0, function()
	-- Update entities

	Cache.EntityList = ents_GetAll()

	table_sort(Cache.EntityList, function(a, b)
		return a:EntIndex() < b:EntIndex()
	end)

	for i = #Cache.EntityList, 1, -1 do
		if Cache.EntityList[i]:EntIndex() < 0 then -- Stupid ass entities
			table_remove(Cache.EntityList, i) -- Wop wop wop wop wop
		end
	end

	-- Update players

	Cache.PlayerList = {}
	
	for i = 2, player_GetCount() + 1 do -- Faster than player.GetAll
		Cache.PlayerList[#Cache.PlayerList + 1] = Cache.EntityList[i] or NULL
	end

	for i = 1, #Cache.PlayerList do
		if BitflagHasValue(Cache.ESP.PlayerFlags, ESP_AVATAR) or BitflagHasValue(Cache.ESP.FriendFlags, ESP_AVATAR) then
			if not IsValid(Cache.ESP.AvatarFrames[Cache.PlayerList[i]:SteamID64() or "BOT"]) then
				local pAvatar = vgui_Create("AvatarImage")

				pAvatar:SetSize(16, 16)
				pAvatar:SetVisible(false)
				pAvatar:SetPaintedManually(true)
				pAvatar:SetPlayer(Cache.PlayerList[i], 16)

				Cache.ESP.AvatarFrames[Cache.PlayerList[i]:SteamID64() or "BOT"] = pAvatar
			end
		end
	end
end)

hook.Add("DrawOverlay", Cache.HookName, function()
	Cache.LocalPlayer = Cache.LocalPlayer or LocalPlayer()

	local PlayerFlags = Cache.ESP.PlayerFlags
	local FriendFlags = Cache.ESP.FriendFlags
	local EntityFlags = Cache.ESP.EntityFlags

	local EntsThisFrame = {}
	local DoFriend = BitflagHasValue(FriendFlags, ESP_ENABLED)

	if BitflagHasValue(PlayerFlags, ESP_ENABLED) or DoFriend then
		for i = 1, #Cache.PlayerList do
			if Cache.PlayerList[i] == Cache.LocalPlayer or not IsValid(Cache.PlayerList[i]) then continue end

			if DoFriend and IsFriend(Cache.PlayerList[i]) then
				EntsThisFrame[#EntsThisFrame + 1] = {Cache.PlayerList[i], FriendFlags}
			else
				EntsThisFrame[#EntsThisFrame + 1] = {Cache.PlayerList[i], PlayerFlags}
			end
		end
	end

	if BitflagHasValue(Cache.ESP.EntityFlags, ESP_ENABLED) then
		for i = 1, #Cache.EntityList do
			if not IsValid(Cache.EntityList[i]) or Cache.EntityList[i]:IsPlayer() then continue end
			EntsThisFrame[#EntsThisFrame + 1] = {Cache.EntityList[i], EntityFlags}
		end
	end

	local lpos = Cache.LocalPlayer:GetPos()

	table_sort(EntsThisFrame, function(a, b)
		return a[1]:GetPos():DistToSqr(lpos) > b[1]:GetPos():DistToSqr(lpos)
	end)

	for i = 1, #EntsThisFrame do
		DoESP(EntsThisFrame[i][1], EntsThisFrame[i][2])
	end
end)

-- ConCommands

concommand.Add("bfesp_menu", function()
	if not IsValid(Cache.Menu) then return end

	Cache.Menu:SetVisible(true)
	Cache.Menu:MakePopup()

	if IsValid(Cache.MenuEntityList) then
		Cache.MenuEntityList:CacheUpdate()
	end
end)

-- Menu Creation

do
	local Main = vgui_Create("DFrame")
	Main:SetSize(400, 300)
	Main:Center()
	Main:SetTitle("Bitflag ESP")
	Main:SetVisible(false)
	Main:SetDeleteOnClose(false)
	
	local MainTabs = vgui_Create("DPropertySheet", Main)
	MainTabs:Dock(FILL)

	local PlayerPanel = vgui_Create("DPanel", MainTabs)
	MainTabs:AddSheet("Players", PlayerPanel)

	-- Players

	MakeCheckBox(PlayerPanel, 25, 25, "Enabled", "PlayerFlags", ESP_ENABLED)
	MakeCheckBox(PlayerPanel, 50, 50, "Box", "PlayerFlags", ESP_BOX)
	MakeCheckBox(PlayerPanel, 50, 75, "3D Box", "PlayerFlags", ESP_BOX_TD)
	MakeCheckBox(PlayerPanel, 50, 100, "Name", "PlayerFlags", ESP_NAME)
	MakeCheckBox(PlayerPanel, 50, 125, "Weapon", "PlayerFlags", ESP_WEAPON)
	MakeCheckBox(PlayerPanel, 50, 150, "Skeleton", "PlayerFlags", ESP_SKELETON)
	MakeCheckBox(PlayerPanel, 50, 175, "Healthbar", "PlayerFlags", ESP_HEALTHBAR)
	MakeCheckBox(PlayerPanel, 50, 200, "Avatar", "PlayerFlags", ESP_AVATAR)

	local FriendPanel = vgui_Create("DPanel", MainTabs)
	MainTabs:AddSheet("Friends", FriendPanel)

	-- Friends

	MakeCheckBox(FriendPanel, 25, 25, "Enabled", "FriendFlags", ESP_ENABLED)
	MakeCheckBox(FriendPanel, 50, 50, "Box", "FriendFlags", ESP_BOX)
	MakeCheckBox(FriendPanel, 50, 75, "3D Box", "FriendFlags", ESP_BOX_TD)
	MakeCheckBox(FriendPanel, 50, 100, "Name", "FriendFlags", ESP_NAME)
	MakeCheckBox(FriendPanel, 50, 125, "Weapon", "FriendFlags", ESP_WEAPON)
	MakeCheckBox(FriendPanel, 50, 150, "Skeleton", "FriendFlags", ESP_SKELETON)
	MakeCheckBox(FriendPanel, 50, 175, "Healthbar", "FriendFlags", ESP_HEALTHBAR)
	MakeCheckBox(FriendPanel, 50, 200, "Avatar", "FriendFlags", ESP_AVATAR)

	local EntityPanel = vgui_Create("DPanel", MainTabs)
	MainTabs:AddSheet("Entities", EntityPanel)

	-- Entities

	MakeCheckBox(EntityPanel, 25, 25, "Enabled", "EntityFlags", ESP_ENABLED)
	MakeCheckBox(EntityPanel, 50, 50, "Box", "EntityFlags", ESP_BOX)
	MakeCheckBox(EntityPanel, 50, 75, "3D Box", "EntityFlags", ESP_BOX_TD)
	MakeCheckBox(EntityPanel, 50, 100, "Name", "EntityFlags", ESP_NAME)
	MakeCheckBox(EntityPanel, 50, 125, "Weapon", "EntityFlags", ESP_WEAPON)
	MakeCheckBox(EntityPanel, 50, 150, "Skeleton", "EntityFlags", ESP_SKELETON)
	MakeCheckBox(EntityPanel, 50, 175, "Healthbar", "EntityFlags", ESP_HEALTHBAR)

	local EntityListPanel = vgui_Create("DPanel", MainTabs)
	MainTabs:AddSheet("Entity List", EntityListPanel)

	local EntityList = vgui_Create("DListView", EntityListPanel)
	EntityList:Dock(FILL)
	EntityList:AddColumn("Class")
	EntityList:AddColumn("Show on ESP")

	EntityList.CacheUpdate = function(self)
		self:Clear()

		local Added = {}

		for i = 1, #Cache.EntityList do
			if not IsValid(Cache.EntityList[i]) then continue end

			local Class = Cache.EntityList[i]:GetClass()

			if not Added[Class] then
				self:AddLine(Class, Cache.ESP.iEntityClasses[Class] and "True" or "False")
				Added[Class] = true
			end
		end

		for k, _ in pairs(scripted_ents_GetList()) do
			if not Added[k] then
				self:AddLine(k, Cache.ESP.iEntityClasses[k] and "True" or "False")
				Added[k] = true
			end
		end
	end

	EntityList.OnRowSelected = function(self, _, row)
		Cache.ESP.iEntityClasses[row:GetValue(1)] = not Cache.ESP.iEntityClasses[row:GetValue(1)]
		self:CacheUpdate()
	end

	Cache.Menu = Main
	Cache.MenuEntityList = EntityList
end
