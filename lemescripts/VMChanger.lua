--[[
	https://github.com/awesomeusername69420/miscellaneous-gmod-stuff
	
	WIP Viewmodel Changer
	
	TODO:
		Find a way to figure out which viewmodels don't work (They don't bonemerge properly in certain cases)
		Find a way to fix viewmodels that don't work (Bone magic?)
		Maybe make it not lag game on load
]]

local VIEWMODELS = {}
local filters = {"arms", "hands"} -- This is bad but it's a good starting place

-- Weapon scan

for _, data in ipairs(weapons.GetList()) do
	local modelpath = data.ViewModel
	
	if not modelpath or #modelpath < 1 then continue end
	
	local breakouter = true
	
	for _, filter in ipairs(filters) do
		if modelpath:find(filter) then
			breakouter = false
			break
		end
	end
	
	if breakouter then continue end
	
	VIEWMODELS[modelpath] = true -- Dumb but makes life easier for the file scan
end

-- File scan

local function FindViewModelsIn(path, gamepath)
	local files, dirs = file.Find(path, gamepath)
	local subpath = path:sub(1, #path - 1)
	
	for _, dir in ipairs(dirs) do
		FindViewModelsIn(subpath .. dir .. "/*", gamepath)
	end

	for _, mdl in ipairs(files) do
		local modelpath = subpath .. mdl
		
		if VIEWMODELS[modelpath] or mdl:sub(#mdl - 3) ~= ".mdl" then continue end
		
		local breakouter = true
		
		for _, filter in ipairs(filters) do
			if mdl:find(filter) then
				breakouter = false
				break
			end
		end
		
		if breakouter then continue end
	
		VIEWMODELS[modelpath] = true
	end
end

FindViewModelsIn("models/weapons/*", "GAME")

if table.Count(VIEWMODELS) < 1 then
	return error("Failed to find any valid viewmodels") -- Sad
end

local first = nil

for k, _ in pairs(VIEWMODELS) do -- Dumb
	first = k
	break
end

local VM = ClientsideModel(first, RENDERGROUP_BOTH)
VM:UseClientSideAnimation()
VM:SetNoDraw(true)
VM:SetRenderMode(RENDERMODE_TRANSCOLOR)

local function ChangeViewModel(model)
	model = model or first
	
	VM:SetParent(nil)
	
	if VM:IsEffectActive(EF_BONEMERGE) then
		VM:RemoveEffects(EF_BONEMERGE)
		VM:RemoveEffects(EF_BONEMERGE_FASTCULL)
	end
	
	VM:InvalidateBoneCache()
	VM:SetModel(model)
	VM:SetupBones()
end

hook.Add("PreDrawPlayerHands", "vmchange", function(hands, pVM)
	VM:SetParent(pVM)
	VM:SetPos(pVM:GetPos())
	VM:SetAngles(pVM:GetAngles())
	
	if not VM:IsEffectActive(EF_BONEMERGE) then
		VM:AddEffects(EF_BONEMERGE)
		VM:AddEffects(EF_BONEMERGE_FASTCULL)
	end
	
	VM:DrawModel()
	
	return true
end)

local Main = vgui.Create("DFrame")
Main:SetSize(500, 200)
Main:Center()
Main:SetTitle("Viewmodel Changer")
Main:SetDeleteOnClose(false)

Main._OGMakePopup = Main.MakePopup

Main.MakePopup = function(self) -- "Hook" for updating title
	self:SetTitle("Viewmodel Changer - " .. table.Count(VIEWMODELS) .. " found")
	Main._OGMakePopup(self)
end

local DropDown = vgui.Create("DComboBox", Main)
DropDown:SetSize(400, 24)
DropDown:Center()

for k, _ in pairs(VIEWMODELS) do
	DropDown:AddChoice(k)
end

DropDown.OnSelect = function(self, index, value)
	if not VIEWMODELS[value] then return end -- ??????
	
	ChangeViewModel(value)
end

DropDown.DoRightClick = function(self)
	local cur, _ = self:GetSelected()
	
	if not cur then return end
	
	SetClipboardText(cur)
end

Main:MakePopup()

concommand.Add("debugcmd", function()
	print("~~~~~~~~~~~~~~REAL BONES~~~~~~~~~~~~~~~~~")
	
	for i = 0, 2 do
		local pVM = LocalPlayer():GetViewModel(i)
		
		if not IsValid(pVM) then continue end
		
		pVM:SetupBones()
		
		print("VM INDEX: " .. i .. "\n")
		
		for i = 1, pVM:GetBoneCount() - 1 do
			print(pVM:GetBoneName(i))
		end
		
		print("")
	end

	print("~~~~~~~~~~~~~~~~~BONES~~~~~~~~~~~~~~~~~~~")
	
	for i = 1, VM:GetBoneCount() - 1 do
		print(VM:GetBoneName(i))
	end
	
	print("\n~~~~~~~~~~~~~~MATERIALS~~~~~~~~~~~~~~~~")
	
	local mats = VM:GetMaterials()
	
    for i = 1, #mats do
        local cur = mats[i]
		
		if not cur then continue end
	
        local mat = Material(mats[i])
	
        if mat then
            local txt = mat:GetTexture("$basetexture")
	
            if not txt or txt:IsError() or txt:IsErrorTexture() then
                print(cur, "", "Valid = false")
            else
                print(cur, "", "Valid = TRUE")
            end
        else
			print(cur, "", "Valid = false")
        end
	end
	
	print("\n~~~~~~~~~~util.IsValidModel~~~~~~~~~~~~")
	
	print(util.IsValidModel(VM:GetModel()))
	
	print("\n~~~~~~~~~~~IsUselessModel~~~~~~~~~~~~~~")
	
	print(IsUselessModel(VM:GetModel()))
end)

concommand.Add("viewmodel_menu", function()
	Main:SetVisible(true)
	Main:MakePopup()
end)

concommand.Add("viewmodel_forcemodel", function(c, p, a) -- Forces the viewmodel to a model (If it didn't find one)
	if not a[1] then return end

	ChangeViewModel(a[1])
end)

concommand.Add("viewmodel_forceoriginal", function(c, p, a) -- Forces the ACTUAL viewmodel to a model
	if not a[1] then return end

	local pVM = LocalPlayer():GetViewModel(i)
		
	if not IsValid(pVM) then return end

	pVM:InvalidateBoneCache()
	pVM:SetModel(a[1])
	pVM:SetupBones()
end)

concommand.Add("viewmodel_scandirectory", function(c, p, a) -- Forces a viewmodel file scan on a given directory
	if not a[1] then return end
	
	a[2] = a[2] or "GAME"
	
	FindViewModelsIn(a[1], a[2])
end)
