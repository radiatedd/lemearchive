--[[
	https://github.com/awesomeusername69420/miscellaneous-gmod-stuff
	
	Has some cool renderings for M9K specialties
	
	- Frag grendae, sticky grenade, nerve gas timers
	- Nerve gas and proximity mine hitbox range
]]

local Cache = {
	Colors = {
		Red = Color(255, 0, 0, 255),
		RedA = Color(255, 0, 0, 100),
	},
	
	Materials = {
		Quad = CreateMaterial(tostring({}), "UnlitGeneric", { -- Default color material but with alpha
			["$alpha"] = 0.4,
			["$basetexture"] = "color/white",
			["$model"] = 1,
			["$translucent"] = 1,
			["$vertexalpha"] = 1,
			["$vertexcolor"] = 1
		})
	},
	
	Grenades = {}
}

local Classes = { -- Holds the classes and time information
	["m9k_thrown_sticky_grenade"] = 3,
	["m9k_thrown_m61"] = GAMEMODE.Name == "Murderthon 9000" and 1.5 or 3, -- No ConVar check
	["m9k_oribital_cannon"] = 8.25,
	["m9k_released_poison"] = 18, -- self.Big is never true (By default)
	["m9k_proxy"] = -1, -- No timer for this
	
	["m9k_mad_c4"] = function(self)
		return self:GetDTInt(0)
	end
}

local PositionOverrides = { -- Use a position other than OBBCenter for the text
	["m9k_oribital_cannon"] = function(self)
		-- No clientside access to self.Target :(

		Cache.OrbitalCannonDownVector = Cache.OrbitalCannonDownVector or (vector_up * 32767)

		return util.TraceLine({ -- Not 100% accurate but I couldn't find anything to use other than some variables that aren't networked
			start = self:GetPos(),
			endpos = self:GetPos() - Cache.OrbitalCannonDownVector
		}).HitPos
	end
}


local function DrawCircle(pos, rad, seg, color) -- Basically surface.DrawCircle but 3D
    local angle = 2 * math.pi / seg
    local startang = 0
    local endang = angle
	
    for i = 1, seg do
        local startpos = pos + Vector(math.cos(startang), math.sin(startang), 0) * rad
        local endpos = pos + Vector(math.cos(endang), math.sin(endang), 0) * rad
		
        render.DrawLine(startpos, endpos, color, true)
		
        startang = endang
        endang = endang + angle
    end
end

local Render3D = { -- Render custom things for these entities	
	["m9k_thrown_sticky_grenade"] = function(self)
		render.DrawWireframeSphere(self:GetPos(), 180, 10, 10, Cache.Colors.RedA, true)
	end,
	
	["m9k_thrown_m61"] = function(self)
		render.DrawWireframeSphere(self:GetPos(), 320, 10, 10, Cache.Colors.RedA, true)
	end,
	
	["m9k_oribital_cannon"] = function(self)
		render.DrawWireframeSphere(PositionOverrides[self:GetClass()](self), 4250, 10, 10, Cache.Colors.RedA, true)
	end,
	
	["m9k_released_poison"] = function(self)
		local len = 225 -- self.Big is never true
	
		-- These direction names probably aren't proper, I just called them whatever
	
		Cache.ReleasedPoisonMins = Cache.ReleasedPoisonMins or Vector(-len, -len, -len)
		Cache.ReleasedPoisonMaxs = Cache.ReleasedPoisonMaxs or Vector(len, len, len)
	
		render.DrawWireframeBox(self:GetPos(), angle_zero, Cache.ReleasedPoisonMins, Cache.ReleasedPoisonMaxs, Cache.Colors.RedA, true)
	end,
	
	["m9k_proxy"] = function(self)
		-- I don't know how to do 3D circles for the cool filled in shape thinger
		
		DrawCircle(self:GetPos(), 200, 64, Cache.Colors.Red)
	end,
	
	["m9k_mad_c4"] = function(self)
		render.DrawWireframeSphere(self:GetPos(), 500, 10, 10, Cache.Colors.RedA, true)
	end
}

timer.Create("@@@@@@", 0.3, 0, function()
	Cache.Grenades = {}
	
	for k, _ in pairs(Classes) do
		for _, e in ipairs(ents.FindByClass(k)) do
			Cache.Grenades[#Cache.Grenades + 1] = e
		end
	end
end)

hook.Add("PreDrawEffects", "@@@@@@", function()
	for _, v in ipairs(Cache.Grenades) do
		if not IsValid(v) then
			continue
		end
	
		local class = v:GetClass()
		
		if Render3D[class] then
			Render3D[class](v)
		end
	end
end)

hook.Add("HUDPaint", "@@@@@@", function()
	surface.SetFont("BudgetLabel")
	surface.SetTextColor(color_white)

	for _, v in ipairs(Cache.Grenades) do
		if not IsValid(v) then
			continue
		end
		
		local class = v:GetClass()
	
		local etime = Classes[class] or 0
		
		if type(etime) == "function" then
			etime = etime(v)
		end
		
		if etime == -1 then
			continue
		end
		
		local ctime = math.Round(math.Clamp(etime - (CurTime() - v:GetCreationTime()), 0, math.huge), 1)
		local spos
		
		if PositionOverrides[class] then
			spos = PositionOverrides[class](v):ToScreen()
		else
			spos = v:LocalToWorld(v:OBBCenter()):ToScreen()
		end
		
		local tw, th = surface.GetTextSize(ctime)
		
		surface.SetTextPos(spos.x - (tw / 2), spos.y - (th / 2))
		surface.DrawText(ctime)
	end
end)
