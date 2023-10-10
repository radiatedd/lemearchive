--[[
	https://github.com/awesomeusername69420/miscellaneous-gmod-stuff

	Projectile prediction for m9k rpg7, m202, m79gl, ex41, matador, milkormgl, nitro glycerine, nerve gas, sticky grenades, frag grenades, ieds, harpoons and machetes
]]

local lp = LocalPlayer()

local pred = {
	data = {
		m9k_rpg7 = {
			starts = {6, -5}, -- Start position multipliers
			fvm = (115 * 52.5) / 66, -- How the velocity works
			dvm = (147 * 39.37) / 66, -- How much to remove from velocity each tick
			rad = 180, -- Explosion radius to show,
			startm = 2, -- What to multiply startfwd by
			sub = Vector(0, 0, 0.111) -- Falls by this much extra every tick
		},

		m9k_m202 = {
			starts = {5, 0.5},
			fvm = (115 * 52.5) / 66,
			dvm = 500,
			rad = 180,
			startm = 2,
			sub = Vector(0, 0, 0.111)
		},

		m9k_m79gl = {
			starts = {6, -5},
			fvm = (75 * 52.5) / 66,
			dvm = 350,
			rad = 105,
			startm = 1,
			sub = Vector(0, 0, 0.111)
		},

		m9k_ex41 = {
			starts = {6, -5},
			fvm = (80 * 52.5) / 66,
			dvm = 350,
			rad = 105,
			startm = 1,
			sub = Vector(0, 0, 0.111)
		},

		m9k_matador = {
			starts = {0, 0},
			fvm = (250 * 52.5) / 66,
			dvm = 200,
			rad = 135,
			startm = 1.5,
			sub = Vector(0, 0, 0.111)
		},

		m9k_milkormgl = {
			starts = {4.5, -6},
			fvm = (75 * 52.5) / 66,
			dvm = 350,
			rad = 52.5,
			startm = 3,
			sub = Vector(0, 0, 0.035)
		},

		-- The numbers below are mostly made up things because these weapons work weird and idk how to predict these properly

		m9k_nitro = {
			starts = {35, 0},
			fvm = 100,
			dvm = 550,
			rad = 60,
			startm = 0,
			sub = Vector(0, 0, 0.111)
		},

		m9k_nerve_gas = {
			starts = {0, 0},
			fvm = 125,
			dvm = 350,
			rad = 0,
			startm = 0,
			sub = Vector(0, 0, 0.111)
		},

		m9k_ied_detonator = { -- These are fucky because bounces and bounding boxes and other shit I'm not gonna bother to predict
			starts = {0, 0},
			fvm = 25,
			dvm = 350,
			rad = 150,
			startm = 0,
			sub = Vector(0, 0, 0.111)
		}
	}
}

-- These numbers are close enough that they can just be copied with minimal changes

pred.data.m9k_sticky_grenade = table.Copy(pred.data.m9k_nerve_gas)
pred.data.m9k_sticky_grenade.rad = 66

pred.data.m9k_m61_frag = table.Copy(pred.data.m9k_nerve_gas)
pred.data.m9k_m61_frag.rad = 105

pred.data.m9k_harpoon = table.Copy(pred.data.m9k_nerve_gas)
pred.data.m9k_harpoon.fvm = 190

pred.data.m9k_machete = table.Copy(pred.data.m9k_nitro)
pred.data.m9k_machete.starts = {0, 0}
pred.data.m9k_machete.rad = 0
pred.data.m9k_machete.fvm = 130

local gravity = Vector(0, 0, 6)

local color_red = Color(255, 0, 0, 255)
local color_orange = Color(255, 150, 0, 255)

local hitpos = nil
local hitcol = color_white
local hitposhit = false
local lines = {}

local servertime = 0

local function isInWorld(pos) -- util.IsInWorld but clientside
	pos = pos or vector_origin

	local tr = util.TraceLine({
		start = pos,
		endpos = pos
	})

	return tr.HitWorld
end

hook.Add("Move", "", function()
	if not IsFirstTimePredicted() then return end

	servertime = CurTime()
end)

hook.Add("CreateMove", "", function(cmd)
	lp = IsValid(lp) and lp or LocalPlayer()

	lines = {}

	local wep = lp:GetActiveWeapon()

	if not IsValid(wep) then
		hitpos = nil

		return
	end

	local class = wep:GetClass()

	if not pred.data[class] or wep:GetNextPrimaryFire() > servertime then
		hitpos = nil

		return
	end

	local wepdata = pred.data[class]

	local fvm = wepdata.fvm
	local dvm = wepdata.dvm

	local aimvector = lp:GetAimVector()
	local side = aimvector:Cross(vector_up)
	local up = side:Cross(aimvector)

	local starts = wepdata.starts

	local startpos = lp:GetShootPos() + (side * starts[1]) + (up * starts[2]) -- The weapon spawns the rocket here
	local startfwd = lp:EyeAngles():Forward() * fvm

	local curfwd = Vector(startfwd.x, startfwd.y, startfwd.z) -- Copy vector
	local curfvm = fvm
	local curpos = startpos

	local sm = wepdata.startm
	local sub = wepdata.sub

	lines[1] = startpos

	hitposhit = false

	while not isInWorld(curpos) do
		local tr = util.TraceLine({
			start = curpos,
			endpos = curpos + curfwd,
			filter = lp
		})

		if tr.Hit then -- Pevent going through walls
			curpos = tr.HitPos
			hitposhit = true

			break
		end

		curpos = curpos + curfwd
		curfwd = (curfwd - (curfwd / dvm) + (startfwd * sm) - sub) - gravity -- Doesn't include the randomness for obvious reasons

		lines[#lines + 1] = curpos
	end

	hitpos = curpos
	hitcol = color_white

	local tr = util.TraceLine({ -- Test for entity and sky hit
		start = hitpos,
		endpos = hitpos + startfwd,
		filter = lp
	})

	if tr.Hit then
		hitposhit = not tr.HitSky

		if IsValid(tr.Entity) and tr.Entity:IsPlayer() then
			hitcol = color_red
		end
	end

	lines[#lines + 1] = curpos
end)

hook.Add("PostDrawTranslucentRenderables", "", function(depth, skybox) -- Data said to use this so I'm using this
	if depth or skybox or not hitpos then return end

	local wep = lp:GetActiveWeapon()

	if not IsValid(wep) then
		return
	end

	local class = wep:GetClass()

	if not pred.data[class] then
		return
	end

	render.DrawWireframeSphere(hitpos, 5, 15, 15, hitcol, true)

	for i = 1, #lines - 1 do
		render.DrawLine(lines[i], lines[i + 1], hitcol, true)
	end

	if hitposhit then -- Explosion kill radius
		render.DrawWireframeSphere(hitpos, pred.data[class].rad, 15, 15, color_orange, true)
	end
end)
