--[[
	https://github.com/awesomeusername69420/miscellaneous-gmod-stuff

	Some global color stuff
]]

-- List of common colors

local Color = Color

color_white = Color(255, 255, 255, 255) -- Already exists (usually) but why not
color_black = Color(0, 0, 0, 255) -- Already exists (usually) but why not

color_gray = Color(100, 100, 100, 255)
color_darkgray = Color(50, 50, 50, 255)

color_red = Color(255, 0, 0, 255)
color_green = Color(0, 255, 0, 255)
color_blue = Color(0, 0, 255, 255)
color_aqua = Color(0, 255, 255, 255)
color_yellow = Color(255, 255, 0, 255)
color_orange = Color(255, 150, 0, 255)
color_purple = Color(150, 0, 255, 255)
color_pink = Color(255, 0, 255, 255)
color_brown = Color(100, 50, 0, 255)

-- Fixes

local IsColor = IsColor

local _Registry = debug.getregistry()

local meta_cl = _Registry.Color
local meta_en = _Registry.Entity
local meta_im = _Registry.IMaterial
local meta_it = _Registry.ITexture
local meta_pt = _Registry.ProjectedTexture

_ColorBackup = _ColorBackup or { -- Holds original functions
	HSVToColor = HSVToColor,
	HSLToColor = HSLToColor,

	meta_im = {
		GetColor = meta_im.GetColor
	},

	meta_it = {
		GetColor = meta_it.GetColor
	},

	meta_pt = {
		GetColor = meta_pt.GetColor
	},
	
	render = {
		SetColorModulation = render.SetColorModulation,
		SetShadowColor = render.SetShadowColor
	},

	surface = {
		GetDrawColor = surface.GetDrawColor,
		GetTextColor = surface.GetTextColor
	}
}

meta_en.GetHealthColor = function(ent) -- Gets a color based off the entity's health; returns Color and a percentage
	local max = ent:GetMaxHealth()
	local health = math.Clamp(ent:Health(), 0, max)
	local percent = health * (health / max)

	if ent._LastHealth ~= health or not ent._LastHealthColor then
		ent._LastHealth = health
		ent._LastHealthColor = Color(255 - (percent * 2.55), percent * 2.55, 0)
	end

	return ent._LastHealthColor, percent / health
end

meta_im.GetColor = function(mat) -- Fix IMaterial:GetColor metatable issue
	local col = _ColorBackup.meta_im.GetColor(mat)

	return setmetatable(col, meta_cl)
end

meta_it.GetColor = function(txt) -- Fix ITexture:GetColor metatable issue
	local col = _ColorBackup.meta_it.GetColor(txt)

	return setmetatable(col, meta_cl)
end

meta_pt.GetColor = function(pt) -- Fix ProjectedTexture:GetColor metatable issue
	local col = _ColorBackup.meta_pt.GetColor(pt)

	return setmetatable(col, meta_cl)
end

render.SetColorModulation = function(r, g, b) -- Allows for a color or vector object to be inserted as well
	if IsColor(r) then
		g = r.g / 255
		b = r.b / 255
		r = r.r / 255
	elseif type(r) == "Vector" then
		g = r.y
		b = r.z
		r = r.x
	end

	assert(type(r) == "number", "Bad argument #1 to SetColorModulation (number expected, got " .. type(r) .. ")")
	assert(type(g) == "number", "Bad argument #2 to SetColorModulation (number expected, got " .. type(g) .. ")")
	assert(type(b) == "number", "Bad argument #3 to SetColorModulation (number expected, got " .. type(b) .. ")")

	return _ColorBackup.render.SetColorModulation(r, g, b)
end

render.SetShadowColor = function(r, g, b) -- Allows for a color or vector object to be inserted as well
	if IsColor(r) then
		g = r.g / 255
		b = r.b / 255
		r = r.r / 255
	elseif type(r) == "Vector" then
		g = r.y
		b = r.z
		r = r.x
	end

	assert(type(r) == "number", "Bad argument #1 to SetShadowColor (number expected, got " .. type(r) .. ")")
	assert(type(g) == "number", "Bad argument #2 to SetShadowColor (number expected, got " .. type(g) .. ")")
	assert(type(b) == "number", "Bad argument #3 to SetShadowColor (number expected, got " .. type(b) .. ")")

	return _ColorBackup.render.SetShadowColor(r, g, b)
end

surface.GetDrawColor = function() -- Fix surface.GetDrawColor metatable issue
	local col = _ColorBackup.surface.GetDrawColor()

	return setmetatable(col, meta_cl)
end

surface.GetTextColor = function() -- Fix surface.GetTextColor metatable issue
	local col = _ColorBackup.surface.GetTextColor()

	return setmetatable(col, meta_cl)
end

HSVToColor = function(hue, saturation, value) -- Fix HSVToColor metatable issue
	local col = _ColorBackup.HSVToColor(hue, saturation, value)

	return setmetatable(col, meta_cl)
end

HSLToColor = function(hue, saturation, value) -- Fix HSLToColor metatable issue
	local col = _ColorBackup.HSLToColor(hue, saturation, value)

	return setmetatable(col, meta_cl)
end

vgui.GetControlTable("DColorMixer").UpdateColor = function(self, color) -- Fix DColorMixer:ValueChanged metatable issue
	color = setmetatable(color, meta_cl)

	self.Alpha:SetBarColor(ColorAlpha(color, 255))
	self.Alpha:SetValue(color.a / 255)

	if color.r != self.txtR:GetValue() then
		self.txtR.notuserchange = true
		self.txtR:SetValue(color.r)
		self.txtR.notuserchange = nil
	end

	if color.g != self.txtG:GetValue() then
		self.txtG.notuserchange = true
		self.txtG:SetValue(color.g)
		self.txtG.notuserchange = nil
	end

	if color.b != self.txtB:GetValue() then
		self.txtB.notuserchange = true
		self.txtB:SetValue(color.b)
		self.txtB.notuserchange = nil
	end

	if color.a != self.txtA:GetValue() then
		self.txtA.notuserchange = true
		self.txtA:SetValue(color.a)
		self.txtA.notuserchange = nil
	end

	self:UpdateConVars(color)
	self:ValueChanged(color)

	self.m_Color = color
end
