/*
big hacker public (C) razorCODES updated on 9/12/20

ChangeName	=	function: 0x432b4740
FinishPrediction	=	function: 0x3dfdc1c0
FullUpdate	=	function: 0x3e3f37f8
GetChokedPackets	=	function: 0x423d8cf8
GetInSequenceNumber	=	function: 0x4326a438
GetLatency	=	function: 0x423bb760
GetOutSequenceNumber	=	function: 0x3deb1fb0
GetSpreadVector	=	function: 0x3e003e78
HookProp	=	function: 0x3de51840
MD5PseudoRandom	=	function: 0x423b31d0
RandomFloat	=	function: 0x3deb29d0
RandomInt	=	function: 0x3df1bd88
RandomSeed	=	function: 0x422658d8
SetChokedPackets	=	function: 0x422fd4d0
SetInSequenceNumber	=	function: 0x3e018c50
SetInterpolation	=	function: 0x3df3f070
SetOutSequenceNumber	=	function: 0x3db9a890
StartPrediction	=	function: 0x3dc6bdb0
StringCmd	=	function: 0x3e02f6a8
TickCount	=	function: 0x3e3d5700
UnhookProp	=	function: 0x3df1b108
*/

require("big");
bSendPacket = true;

local next = next;
local player = player;
local table = table;
local surface = surface;
local render = render;
local cam = cam;
local me = LocalPlayer();
local game = game;
local Material = Material;
local engine = engine;
local CurTime = CurTime;
local IsFirstTimePredicted = IsFirstTimePredicted;
local math = math;
local string = string;
local input = input;
local util = util;
local GetConVar = GetConVar;
local Vector = Vector;
local Angle = Angle;
local fakeview = Angle();

/* hacker code below */

local namechange = CreateClientConVar("namechange", 0);
local bunnyhop = CreateClientConVar("bunnyhop", 1);
local autostrafer = CreateClientConVar("autostrafer", 1);

local function Bunnyhop(cmd)
	if(!bunnyhop:GetBool()) then return; end
	if(!me:IsOnGround() && cmd:KeyDown(IN_JUMP)) then
		cmd:RemoveKey(IN_JUMP);

		if(autostrafer:GetBool()) then
			if(cmd:GetMouseX() > 1 || cmd:GetMouseX() < -1) then
				cmd:SetSideMove(cmd:GetMouseX() > 1 && 400 || -400);
			else
				cmd:SetForwardMove(5850 / me:GetVelocity():Length2D());
				cmd:SetSideMove((cmd:CommandNumber() % 2 == 0) && -400 || 400);
			end
		end
	elseif(cmd:KeyDown(IN_JUMP) && autostrafer:GetBool()) then
		  cmd:SetForwardMove(450);
	end
end

local function Namechanger(cmd)
	if(!namechange:GetBool()) then return; end
	local player = player;
		local math = math;
		local randply = player.GetAll()[math.random(#player.GetAll())]

	if(!randply:IsValid() || randply == me) then return; end
		big.ChangeName(randply:Name() .. " public hvh 1.1");    
end


/* curtime */

local servertime = 0;

hook.Add("Move", "", function()
	if(!IsFirstTimePredicted()) then return; end
	servertime = CurTime() + engine.TickInterval();
end);

local badSequences = {
    [ACT_VM_DEPLOY] = true;
    [ACT_VM_DEPLOY_1] = true;
    [ACT_VM_DEPLOY_2] = true;
    [ACT_VM_DEPLOY_3] = true;
    [ACT_VM_DEPLOY_4] = true;
    [ACT_VM_DEPLOY_5] = true;
    [ACT_VM_DEPLOY_6] = true;
    [ACT_VM_DEPLOY_7] = true;
    [ACT_VM_DEPLOY_8] = true;
    [ACT_VM_DEPLOY_EMPTY] = true;
    [ACT_VM_ATTACH_SILENCER] = true;
    [ACT_VM_DETACH_SILENCER] = true;
    [ACT_VM_DRAW] = true;
    [ACT_VM_DRAW_DEPLOYED] = true;
    [ACT_VM_DRAW_EMPTY] = true;
    [ACT_VM_DRAW_SILENCED] = true;
    [ACT_VM_RELOAD] = true;
    [ACT_VM_RELOAD_DEPLOYED] = true;
    [ACT_VM_RELOAD_EMPTY] = true;
}

local function canFire()
    local wep = me:GetActiveWeapon();
    if(!wep || !wep:IsValid()) then
        return false;
    end
    local sequence = wep:GetSequence();
    if(badSequences[sequence]) then return false; end
    if(wep:GetNextPrimaryFire() <= servertime) then
        return true;
    end
    return false;
end

/* aimbot */

local function FixMovement(cmd, old, aaaaa)
	local move = Vector(cmd:GetForwardMove(), cmd:GetSideMove(), 0);
	local speed = math.sqrt(move.x * move.x + move.y * move.y);
	local ang = move:Angle();
	local yaw = math.rad(cmd:GetViewAngles().y - old.y + ang.y);
	cmd:SetForwardMove((math.cos(yaw) * speed) * ( aaaaa && -1 || 1 ));
	cmd:SetSideMove(math.sin(yaw) * speed);
end


local trace_walls = bit.bor(CONTENTS_TESTFOGVOLUME, CONTENTS_EMPTY, CONTENTS_MONSTER, CONTENTS_HITBOX);
local NoPenetration = {[MAT_SLOSH] = true};
local PenMod = {[MAT_SAND] = 0.5, [MAT_DIRT] = 0.8, [MAT_METAL] = 1.1, [MAT_TILE] = 0.9, [MAT_WOOD] = 1.2};
local trace_normal = bit.bor(CONTENTS_SOLID, CONTENTS_OPAQUE, CONTENTS_MOVEABLE, CONTENTS_DEBRIS, CONTENTS_MONSTER, CONTENTS_HITBOX, 402653442, CONTENTS_WATER);

local autowall = CreateClientConVar("autowall", 1);

local function fasAutowall(wep, startPos, aimPos, ply)
	if(!autowall:GetBool()) then return false; end
    local traces = {};
    local me = me;
    local traceResults = {};
    local dir = (aimPos - startPos):GetNormalized();
    traces[1] = { start = startPos, filter = me, mask = trace_normal, endpos = aimPos, };
    traceResults[1] = util.TraceLine(traces[1]);
    if(NoPenetration[traceResults[1].MatType]) then return false; end
    if((-dir):DotProduct(traceResults[1].HitNormal) <= .26) then return false; end
    traces[2] = { start = traceResults[1].HitPos, endpos = traceResults[1].HitPos + dir * wep.PenStr * (PenMod[traceResults[1].MatType] || 1) * wep.PenMod, filter = me, mask = trace_walls, };
    traceResults[2] = util.TraceLine(traces[2]);
    traces[3] = { start = traceResults[2].HitPos, endpos = traceResults[2].HitPos + dir * .1, filter = me, mask = trace_normal, };
    traceResults [3] = util.TraceLine(traces[3]);
    traces[4] = { start = traceResults[2].HitPos, endpos = aimPos, filter = me, mask = MASK_SHOT, };
    traceResults[4] = util.TraceLine(traces[4]);
    if(traceResults[4].Entity != ply) then return false; end
    return(!traceResults[3].Hit);
end

local function IsVisible(ply, pos)
	local trace = {
		start = me:EyePos(),
		endpos = pos,
		filter = {ply, me},
		mask = MASK_SHOT,
	};

	if (util.TraceLine(trace).Fraction == 1 ) then
		return true;
	else
		local wep = me:GetActiveWeapon();
		if(wep && wep:IsValid() && wep.PenStr) then
			return fasAutowall(wep, trace.start, trace.endpos, ply);
		end
	end

	return false;
end

local function GetOBBCenter(ply)
	return ply:LocalToWorld(ply:OBBCenter());
end

local function GetCenter(v)
	local bonepos = v:GetBonePosition(0);
	if(!bonepos) then return GetOBBCenter(v); end
	return bonepos;
end

local pitcharray = {};

local function GetPos(v)
	local wep = me:GetActiveWeapon();
	if(wep && wep:IsValid() && wep:GetClass() == "hvh_awp") then return GetCenter(v); end
	local head = v:GetHitBoxBone(0, 0);
	if(!head) then return GetCenter(v); end
	local min, max = v:GetHitBoxBounds(0, 0);
	local bonepos, boneang = v:GetBonePosition(head);
	local result = (min + max) / 2;
	local pitch = pitcharray[v:EntIndex()] || v:EyeAngles().x;
	if(pitch > 45 && pitch < 90) then
		result.x = min.x * .75;
		result.y = max.y * .75;
		result.z = (max.z) - 1;
	elseif(pitch >= -90 && pitch <= -70) then
		result.x = min.x * .5;
		result.y = max.y * .5;
		result.z = (max.z + min.z) * .5;
	else
		min:Rotate(boneang);
		max:Rotate(boneang);
		result = (min + max) / 2;
	end

	return bonepos + result;
end

local next_shot = -1;

local ignoreteam = CreateClientConVar("aimbot_ignoreteam", 1);

local aaaTable = {};

local function GetTarget()
	local nextshottable = {};
	local next_shot_is_valid = nil;
	for k,v in next, player.GetAll() do
		if(v == me || v:Health() < 1 || v:IsDormant()) then continue; end
		if((v:Team() == me:Team()) && ignoreteam:GetBool()) then continue; end
		if(aaaTable[v:SteamID()] && aaaTable[v:SteamID()]["friend"]) then continue; end
		if(IsVisible(v, GetPos(v))) then
			if(v:EntIndex() == next_shot) then
				next_shot_is_valid = v;
			else
				nextshottable[#nextshottable + 1] = v;
			end
		end
	end

	if(next_shot_is_valid && #nextshottable == 0) then
		return next_shot_is_valid;
	end

	return nextshottable[math.random(1, #nextshottable)];
end

local tickcount = 0;

local function Aimbot(cmd)
	if(!canFire()) then return; end
	local target = GetTarget();

	if(!target) then return; end

	next_shot = target:EntIndex();

	local pos = GetPos(target);

	local angle = (pos - me:EyePos()):Angle();
	angle:Normalize();

	cmd:SetViewAngles(angle);
	cmd:SetButtons(bit.bor(cmd:GetButtons(), IN_ATTACK));

	tickcount = -1;
end

local antiaim_pitch = CreateClientConVar("antiaim_pitch", 0);
local antiaim_yaw = CreateClientConVar("antiaim_yaw", 0);
local antiaim_enabled = CreateClientConVar("antiaim_enabled", 1);

local function AtTargets(cmd)
	local dist = 999999999;
	local eyepos = me:EyePos();
	for k,v in next, player.GetAll() do
		if(v == me || v:Health() < 1 || v:IsDormant()) then continue; end
		if((v:Team() == me:Team()) && ignoreteam:GetBool()) then continue; end
		local cureye = v:EyePos();
		if(cureye:Distance(eyepos) < dist) then
			dist = cureye:Distance(eyepos);
			local ang = (cureye - eyepos):Angle();
			ang:Normalize();
			cmd:SetViewAngles(ang);
		end
	end
end

local wdlen = 27.3;

local function WallDtc(cmd, angle)
	local eyepos = me:EyePos();
	local tmp = Angle(3.5, 0, 0);
	local lowestFraction = 1;
	for y = 0, 360, 3.5 do
		tmp.y = y;
		local tr = {
			start = eyepos,
			endpos = eyepos + tmp:Forward() * wdlen,
			mask = MASK_SOLID,
			filter = me,
		};

		local trace = util.TraceLine(tr);

		if(trace.Fraction < lowestFraction) then
			lowestFraction = trace.Fraction;
			if(lowestFraction != 1) then
				cmd:SetViewAngles(Angle(89, y - angle, 0));
			end
		end
	end
	return lowestFraction != 1;
end

local antiaim_walldtc = CreateClientConVar("antiaim_walldtc", 0);
local antiaim_walldtc_yaw = CreateClientConVar("antiaim_walldtc_yaw", 0);

local function AntiAim(cmd)
	if(!antiaim_enabled:GetBool()) then return; end
	AtTargets(cmd);
	local pitch = cmd:GetViewAngles().x;
	local yaw = cmd:GetViewAngles().y;

	if(antiaim_pitch:GetInt() == 0) then //fakedown
		pitch = -180.000005;
	elseif(antiaim_pitch:GetInt() == 1) then //lagdown
		if(bSendPacket) then
			pitch = -89;
		else
			pitch = 89;
		end
	elseif(antiaim_pitch:GetInt() == 2) then //lagup
		if(bSendPacket) then
			pitch = 89;
		else
			pitch = -89;
		end
	elseif(antiaim_pitch:GetInt() == 3) then //normal
		pitch = 180;
	end

	local walldtc = false;
	if(me:GetVelocity():Length2D() < 300) then
		walldtc = (antiaim_walldtc:GetBool() && WallDtc(cmd, 0)) || false;
	end

	if(walldtc) then
		pitch = 89;
		yaw = cmd:GetViewAngles().y;

		if(antiaim_walldtc_yaw:GetInt() == 1) then //fake
			if(!bSendPacket) then
				yaw = yaw - 90;
			end
		elseif(antiaim_walldtc_yaw:GetInt() == 2) then //jitter
			yaw = yaw + (((cmd:CommandNumber() % 2) == 0) && 0 || 180);
		end
	else
		if(antiaim_yaw:GetInt() == 0) then //sideways
			if(bSendPacket) then
				yaw = yaw - 90;
			else
				yaw = yaw + 90;
			end
		elseif(antiaim_yaw:GetInt() == 1) then //backwards
			if(bSendPacket) then
				yaw = yaw - 180;
			else
				yaw = yaw + 90;
			end
		elseif(antiaim_yaw:GetInt() == 2) then //jitter
			yaw = yaw + (((cmd:CommandNumber() % 2) == 0) && 180 || 0);
		elseif(antiaim_yaw:GetInt() == 3) then // spin
			yaw = yaw + (cmd:CommandNumber() % 45) * 8;
		elseif(antiaim_yaw:GetInt() == 4) then //reverse spin
			yaw = yaw - (cmd:CommandNumber() % 45) * 8;
		elseif(antiaim_yaw:GetInt() == 5) then //half sideways
			if(bSendPacket) then
				yaw = yaw + 45;
			else
				yaw = yaw - 45;
			end
		end
	end

	cmd:SetViewAngles(Angle(pitch, math.NormalizeAngle(yaw), 0));
end

local aimbot_enabled = CreateClientConVar("aimbot_enabled", 1);
local fakelag_factor = CreateClientConVar("fakelag_factor", 10);
local fakelag = CreateClientConVar("fakelag", 1);

hook.Add("CreateMove", "", function(cmd)
	fakeview = fakeview + Angle(cmd:GetMouseY() * .022, cmd:GetMouseX() * -.022, 0);
	fakeview:Normalize();
	fakeview.x = math.Clamp(fakeview.x, -89, 89);
	cmd:SetViewAngles(fakeview);
	if(cmd:CommandNumber() == 0) then
		return;
	end

	RunConsoleCommand("cl_interp", 0);
	RunConsoleCommand("cl_updaterate", 100000);
	RunConsoleCommand("cl_interp_ratio", 1);

	tickcount = tickcount + 1;

	if(fakelag:GetBool()) then
		bSendPacket = (tickcount % (fakelag_factor:GetInt() + 1)) == 0;
	else
		bSendPacket = true;
	end

	local oview = cmd:GetViewAngles();


	Bunnyhop(cmd);
    Namechanger(cmd);

	big.StartPrediction(cmd, cmd:CommandNumber());

	AntiAim(cmd);

	if(/*!bSendPacket && why?*/  aimbot_enabled:GetBool()) then
		Aimbot(cmd);
	end

	big.FinishPrediction()

	local x = cmd:GetViewAngles().x;
	FixMovement(cmd, oview, x > 89 && true || x < -89 && true || false);
end);

/* AAA */
local function DoAAA()
	for k,v in next, player.GetAll() do
		if(v == me) then continue; end
		local correctedpitch = v:EyeAngles().x;
		local correctedyaw = v:EyeAngles().y;

		local sid = v:SteamID();
		if(!aaaTable[sid]) then
			aaaTable[sid] = {["friend"] = false, ["pitch"] = 0, ["yaw"] = 0};
		end

		local tab = aaaTable[sid];

		if(tab["pitch"] == 0) then //auto
			if(correctedpitch >= 89 && correctedpitch < 180) then
				correctedpitch = 89;
			elseif(correctedpitch >= 180 && correctedpitch < 290) then
				correctedpitch = -89;
			end
		elseif(tab["pitch"] == 1) then //down
			correctedpitch = 89;
		elseif(tab["pitch"] == 2) then // up
			correctedpitch = -89;
		end

		if(tab["yaw"] == 0) then //auto
		elseif(tab["yaw"] == 1) then
			correctedyaw = correctedyaw - 90;
		elseif(tab["yaw"] == 2) then
			correctedyaw = correctedyaw + 90;
		else
			correctedyaw = correctedyaw - 180;
		end

		pitcharray[v:EntIndex()] = correctedpitch;

		v:SetPoseParameter("aim_pitch", correctedpitch);
		v:SetPoseParameter("body_yaw", 0);
		v:SetPoseParameter("aim_yaw", 0);
		v:InvalidateBoneCache();
		v:SetRenderAngles(Angle(0, math.NormalizeAngle(correctedyaw), 0));
	end
end

/* visuals */

hook.Add("CalcView", "", function()
	return{fov = 110};
end);

local asus = CreateClientConVar("asus", 1);

hook.Add("PostDraw2DSkyBox", "", function()
	if(!asus:GetBool()) then return; end
	render.Clear(0, 0, 0, 0, true, true);
end);

local mattable = {};

hook.Add("RenderScene", "", function()
	if(#mattable == 0) then
		for k,v in next, game.GetWorld():GetMaterials() do
			mattable[#mattable + 1] = Material(v);
		end
	end

	for k,v in next, mattable do
		v:SetFloat("$alpha", asus:GetBool() && 0.75 || 1);
	end

	DoAAA();
end);

matd = matd || 0;
matd = matd + 1;

local vmchamsmat1 = CreateMaterial("ViewModel_1", "VertexLitGeneric", {
	["$basetexture"] = "models/debug/debugwhite",
	["$model"] = 1,
	["$ignorez"] = 0,
	["vertexcolor"] = 1,
	["$color2"] = "{46 234 236}"
});

local vmchamsmat2 = CreateMaterial("ViewModel_2", "VertexLitGeneric", {
	["$basetexture"] = "models/debug/debugwhite",
	["$model"] = 1,
	["$ignorez"] = 1,
	["vertexcolor"] = 1,
	["$color2"] = "{255 0 0}"
});

local chamsmat = CreateMaterial("chamsmat", "VertexLitGeneric", {
	["$ignorez"] = 0,
	["$model"] = 1,
	["$basetexture"] = "models/debug/debugwhite",
});

local chams = CreateClientConVar("chams", 1);

hook.Add("RenderScreenspaceEffects", "", function()
	if(!chams:GetBool()) then return; end
	cam.Start3D();
	render.MaterialOverride(chamsmat);
	for k,v in next, player.GetAll() do
		if(v:Health() < 1 || v:IsDormant()) then continue; end
		if(v:Team() == 1) then
			render.SetColorModulation(1, 0, 0);
		else
			render.SetColorModulation(20 / 255, 100 / 255, 1);
		end

		v:DrawModel();

		local wep = v:GetActiveWeapon();

		if(wep && wep:IsValid()) then
			render.SetColorModulation(1, 1, 1);
			wep:DrawModel();
		end
	end
	cam.End3D();
end);

local name = CreateClientConVar("esp_name", 1);

hook.Add("PostDrawHUD", "", function()
	surface.SetFont("DermaLarge");
	surface.SetTextColor(65, 255, 65);
	surface.SetTextPos(5, 5);
	surface.DrawText("public hvh v1");
	if(!name:GetBool()) then return; end
	for k,v in next, player.GetAll() do
		if(v == me || v:Health() < 1 || v:IsDormant()) then continue; end
		local bottom = v:GetPos() - Vector(0, 0, 4);
		bottom = bottom:ToScreen();
		if(!bottom.visible) then continue; end
		surface.SetFont("BudgetLabel");
		local tw, th = surface.GetTextSize(v:Name());
		surface.SetTextPos(bottom.x - tw / 2, bottom.y);
		surface.SetTextColor(220, 220, 220);
		surface.DrawText(v:Name());
	end
end);

local viewmodelchams = CreateClientConVar("viewmodelchams", 1);

hook.Add("PreDrawViewModel", "", function(vm)
	if(!viewmodelchams:GetBool()) then return; end
	if(!vm) then return; end
	render.SetLightingMode(2);
	for k,v in next, vm:GetMaterials() do
		if(v:find("v_hands")) then
			render.MaterialOverrideByIndex(k - 1, vmchamsmat2);
		else
			render.MaterialOverrideByIndex(k - 1, vmchamsmat1);
		end
	end
end);

hook.Add("PostDrawViewModel", "", function(vm)
	if(!vm) then return; end
	render.SetLightingMode(0);
	for k,v in next, vm:GetMaterials() do
		render.MaterialOverrideByIndex(k - 1, nil);
	end
end);

/* detours */

oldSurfacePlaysound = oldSurfacePlaysound || surface.PlaySound;

surface.PlaySound = function(str)
	if(str == "items/ammopickup.wav") then
		RunConsoleCommand("say", "public hvh v1");
	end
	oldSurfacePlaysound(str);
end


/* menu */

local drawmenu = false;
local insertdown = false;
local menuframe = nil;
local mousedown = false;

surface.CreateFont("MenuOptions", {
	font = "Console",
	size = 13,
	weight = 900,
	shadow = true,
	antialias = false,
});

surface.CreateFont("PlayerList", {
	font = "Console",
	size = 12,
	weight = 600,
	shadow = true,
	antialias = false,
});

local function DrawBox(x, y, w, h, text)
	surface.SetDrawColor(100, 100, 100);
	surface.DrawLine(x, y, x, y + h);
	surface.DrawLine(x, y + h, x + w, y + h);
	surface.DrawLine(x + w, y, x + w, y + h);
	surface.DrawLine(x, y, x + 5, y);

	surface.SetFont("MenuOptions");

	local tw, th = surface.GetTextSize(text);

	surface.SetTextColor(220, 220, 220);

	surface.SetTextPos(x + 10, y - th / 2);
	surface.DrawText(text);

	surface.DrawLine(x + 10 + tw + 5, y, x + w, y);
end

local function IsInBox(minx, miny, w, h)
	local menux, menuy = menuframe:GetPos();
	minx = minx + menux;
	miny = miny + menuy;
	local mousex, mousey = input.GetCursorPos();
	return(mousex < (minx + w) && mousex > minx && mousey < (miny + h) && mousey > miny);
end

local function DrawIncreaseDecrease(x, y, w, h, optionname, min, max, convar)
	local cvar = GetConVar(convar);

	local inbox_dec = IsInBox(x, y, h, h);
	local inbox_inc = IsInBox(x + w - h, y, h, h);

	surface.SetDrawColor(160, 160, 160);
	surface.DrawRect(x, y, w, h);

	if(inbox_dec) then
		surface.SetDrawColor(110, 110, 110);
	else
		surface.SetDrawColor(90, 90, 90);
	end
	surface.DrawRect(x, y, h, h);
	if(inbox_inc) then
		surface.SetDrawColor(110, 110, 110);
	else
		surface.SetDrawColor(90, 90, 90);
	end
	surface.DrawRect(x + w - h, y, h, h);

	surface.SetDrawColor(0, 0, 0);
	surface.DrawOutlinedRect(x, y, h, h);
	surface.DrawOutlinedRect(x + w - h, y, h, h);

	surface.SetDrawColor(0, 0, 0);
	surface.DrawOutlinedRect(x, y, w, h);

	surface.SetTextColor(220, 220, 220);
	surface.SetFont("MenuOptions");
	local tw, th = surface.GetTextSize("+");
	surface.SetTextPos(x + w - h / 2 - tw / 2, y + h / 2 - th / 2);
	surface.DrawText("+");

	local tw, th = surface.GetTextSize("-");

	surface.SetTextPos(x + h / 2 - tw / 2, y + h / 2 - th / 2);
	surface.DrawText("-");

	local textinside = string.format("%s: %d", optionname, cvar:GetInt());

	local tw, th = surface.GetTextSize(textinside);

	surface.SetTextPos(x + w / 2 - tw / 2, y + h / 2 - th / 2);
	surface.DrawText(textinside);

	if(inbox_dec && input.IsMouseDown(MOUSE_LEFT) && !mousedown) then
		cvar:SetInt(cvar:GetInt() - 1);
		if(cvar:GetInt() < min) then
			cvar:SetInt(max);
		end
	end

	if(inbox_inc && input.IsMouseDown(MOUSE_LEFT) && !mousedown) then
		cvar:SetInt(cvar:GetInt() + 1);
		if(cvar:GetInt() > max) then
			cvar:SetInt(min);
		end
	end
end

local function DrawButton(x, y, w, h, optionname, textarray, convar)
	local cvar = GetConVar(convar);

	local inbox = IsInBox(x, y, w, h);

	if(inbox) then
		surface.SetDrawColor(90, 90, 90);
	else
		surface.SetDrawColor(70, 70, 70);
	end

	surface.DrawRect(x, y, w, h);
	surface.SetDrawColor(0, 0, 0);
	surface.DrawOutlinedRect(x, y, w, h);

	local cur = string.format("%s: %s", optionname, textarray[cvar:GetInt() + 1]);

	surface.SetFont("MenuOptions");
	surface.SetTextColor(220, 220, 220);
	local tw, th = surface.GetTextSize(cur);
	surface.SetTextPos(x + w / 2 - tw / 2, y + h / 2 - th / 2);
	surface.DrawText(cur);

	if(inbox && input.IsMouseDown(MOUSE_LEFT) && !mousedown) then
		cvar:SetInt(cvar:GetInt() + 1);
		if(cvar:GetInt() == #textarray) then
			cvar:SetInt(0);
		end
	end
end

local function DrawCheckbox(x, y, convar, text)
	surface.SetDrawColor(0, 0, 0);
	surface.DrawOutlinedRect(x, y, 12, 12);

	local cvar = GetConVar(convar);

	local inbox = IsInBox(x, y, 12, 12);

	if(cvar:GetBool()) then
		surface.SetDrawColor(255, 93, 0);
		surface.DrawRect(x + 1, y + 1, 10, 10);
	elseif(inbox) then
		surface.SetDrawColor(255, 93, 0, 100);
		surface.DrawRect(x + 1, y + 1, 10, 10);
	end

	surface.SetFont("MenuOptions");
	local tw, th = surface.GetTextSize(text);
	surface.SetTextColor(220, 220, 220);
	surface.SetTextPos(x+12+5, y + 6 - th / 2);
	surface.DrawText(text);

	if(inbox && input.IsMouseDown(MOUSE_LEFT) && !mousedown) then
		cvar:SetBool(!cvar:GetBool());
	end
end

local yawcorrection = {"Auto", "H-Left", "H-Right", "Inverse"};
local pitchcorrection = {"Auto", "Down", "Up"};

local function DrawPlayerlist(x, y)
	y = y - 5;
	local count = 1;
	for k,v in next, player.GetAll() do
		if(v == me) then continue; end
		count = count + 1;
		local sid = v:SteamID();
		if(!aaaTable[sid]) then
			aaaTable[sid] = {["friend"] = false, ["pitch"] = 0, ["yaw"] = 0};
		end

		local tab = aaaTable[sid];

		local y = y + ((count - 1) * 17);

		local inbox = IsInBox(x + 5, y, 150, 12);

		if(inbox) then
			surface.SetDrawColor(130, 130, 130);
		else
			surface.SetDrawColor(110, 110, 110);
		end
		if(inbox && input.IsMouseDown(MOUSE_LEFT) && !mousedown) then
			tab["friend"] = !tab["friend"];
		end
		surface.DrawRect(x + 5, y, 150, 12);
		surface.SetDrawColor(0, 0, 0);
		surface.DrawOutlinedRect(x + 5, y, 150, 12);
		surface.SetFont("PlayerList");
		local tw, th = surface.GetTextSize(v:Name());
		surface.SetTextPos(x + 5 + 150 / 2 - tw / 2, y + 6 - th / 2);
		if(tab["friend"]) then
			surface.SetTextColor(0, 255, 0);
		else
			surface.SetTextColor(220, 220, 220);
		end
		surface.DrawText(v:Name());

		surface.SetTextColor(220, 220, 220);

		local inbox = IsInBox(x + 5 + 150 + 5, y, 70, 12);

		if(inbox) then
			surface.SetDrawColor(130, 130, 130);
		else
			surface.SetDrawColor(110, 110, 110);
		end

		if(inbox && input.IsMouseDown(MOUSE_LEFT) && !mousedown) then
			tab["pitch"] = tab["pitch"] + 1;
			if(tab["pitch"] == #pitchcorrection) then
				tab["pitch"] = 0;
			end
		end

		surface.DrawRect(x + 5 + 150 + 5, y, 70, 12);
		surface.SetDrawColor(0, 0, 0);
		surface.DrawOutlinedRect(x + 5 + 150 + 5, y, 70, 12);

		local cur = string.format("X: %s", pitchcorrection[tab["pitch"] + 1]);

		local tw, th = surface.GetTextSize(cur);

		surface.SetTextPos(x + 5 + 150 + 5 + 70 / 2 - tw / 2, y + 6 - th / 2);

		surface.DrawText(cur);

		local inbox = IsInBox(x + 5 + 150 + 5 + 75 + 5, y, 70, 12);

		if(inbox) then
			surface.SetDrawColor(130, 130, 130);
		else
			surface.SetDrawColor(110, 110, 110);
		end

		if(inbox && input.IsMouseDown(MOUSE_LEFT) && !mousedown) then
			tab["yaw"] = tab["yaw"] + 1;
			if(tab["yaw"] == #yawcorrection) then
				tab["yaw"] = 0;
			end
		end

		surface.DrawRect(x + 5 + 150 + 75 + 5, y, 70, 12);
		surface.SetDrawColor(0, 0, 0);
		surface.DrawOutlinedRect(x + 5 + 150 + 75 + 5, y, 70, 12);

		local cur = string.format("Y: %s", yawcorrection[tab["yaw"] + 1]);
		local tw, th = surface.GetTextSize(cur);

		surface.SetTextPos(x + 10 + 150 + 5 + 70 + 70 / 2 - tw / 2, y + 6 - th / 2);
		surface.DrawText(cur);
	end
end

local function CreateMenu()
	local new_Frame = vgui.Create("DFrame");
	new_Frame:SetTitle("");
	new_Frame:SetSize(500 + 75, 300);
	new_Frame:Center();
	new_Frame:ShowCloseButton(false);
	new_Frame:MakePopup();

	function new_Frame:Paint( w, h )
		surface.SetDrawColor(50, 50, 50);
		surface.DrawRect(0, 0, w, h);

		surface.SetDrawColor(255, 93, 0);
		surface.DrawRect(0, 0, w, 20);
		surface.SetDrawColor(0, 0, 0);
		surface.DrawOutlinedRect(0, 0, w, 20);

		surface.SetDrawColor(0, 0, 0);
		surface.DrawOutlinedRect(0, 0, w, h);

		surface.SetFont("TargetIDSmall");
		local tw, th = surface.GetTextSize("public hvh v1.1");
		surface.SetTextPos(w / 2 - tw / 2, 10 - th / 2);
		surface.SetTextColor(255, 255, 255);
		surface.DrawText("public hvh v1.1");

		DrawBox(5, 25, 115, 60, "Aimbot");
		DrawCheckbox(10, 35, "aimbot_enabled", "Enabled");
		DrawCheckbox(10, 50, "aimbot_ignoreteam", "Ignore Team");
		DrawCheckbox(10, 65, "autowall", "Autowall");
		DrawBox(5, 25 + 60 + 10, 115, 45, "Misc");
		DrawCheckbox(10, 105, "bunnyhop", "Bunnyhop");
		DrawCheckbox(10, 120, "autostrafer", "Autostrafer");
		DrawCheckbox(10, 140, "namechange", "Namechanger");
		DrawBox(5, 25 + 60 + 45 + 20, 115, 60 + 15, "Visuals");
		DrawCheckbox(10, 160, "chams", "Chams");
		DrawCheckbox(10, 175, "viewmodelchams", "VM Chams");
		DrawCheckbox(10, 190, "esp_name", "Names");
		DrawCheckbox(10, 205, "asus", "ASUS");

		DrawBox(5 + 125, 25, 115, 160, "HvH");
		DrawCheckbox(135, 35, "antiaim_enabled", "Enabled");
		DrawButton(135, 50, 105, 20, "Pitch", {"Fakedown", "Lag Down", "Lag Up", "Normal"}, "antiaim_pitch")
		DrawButton(135, 75, 105, 20, "Yaw", {"Sideways", "Backwards", "Jitter", "Spin", "R-Spin", "H-Sideways"}, "antiaim_yaw");
		DrawCheckbox(135, 100, "antiaim_walldtc", "Wall Detection");
		DrawButton(135, 115, 105, 20, "Wall Yaw", {"Normal", "Fake", "Jitter"}, "antiaim_walldtc_yaw");
		DrawCheckbox(135, 140, "fakelag", "Fakelag");
		

		DrawIncreaseDecrease(135, 155, 105, 20, "Factor", 0, 14, "fakelag_factor");

		DrawBox(5 + 125 + 115 + 10, 25, 235 + 75, 265, "Playerlist");
		DrawPlayerlist(5 + 125 + 115 + 10, 25);
		mousedown = input.IsMouseDown(MOUSE_LEFT);
	end
	return new_Frame;
end

local oldx, oldy;

hook.Add("Think", "menu", function()
	if(input.IsKeyDown(KEY_INSERT) && !insertdown) then
		if(menuframe) then
			oldx, oldy = menuframe:GetPos();
			menuframe:Close();
			menuframe = nil;
		else
			menuframe = CreateMenu();
			if(oldx) then
				menuframe:SetPos(oldx, oldy);
			end
		end
	end

	insertdown = input.IsKeyDown(KEY_INSERT);
end);

/* extra */

local Entity = Entity;

gameevent.Listen("entity_killed");

hook.Add("entity_killed", "", function(data)
	local att_index = data.entindex_attacker;
	local vic_index = data.entindex_killed;

	if(vic_index != att_index && att_index == me:EntIndex()) then
		RunConsoleCommand("say", "owned by pub");
	end
end);

print("public hvh v1.1");

/*
3:03 AM - bang bang glo gang that 300 shit: wat name to use
3:04 AM - [^a-z0-9]+([^>]*?)(?:\s?/?>|$): for wat
3:04 AM - bang bang glo gang that 300 shit: cheat
3:04 AM - [^a-z0-9]+([^>]*?)(?:\s?/?>|$): razors edick
3:04 AM - [^a-z0-9]+([^>]*?)(?:\s?/?>|$): idk
3:04 AM - [^a-z0-9]+([^>]*?)(?:\s?/?>|$): something cocky
3:04 AM - [^a-z0-9]+([^>]*?)(?:\s?/?>|$): xdresser
3:04 AM - [^a-z0-9]+([^>]*?)(?:\s?/?>|$): idk
3:04 AM - [^a-z0-9]+([^>]*?)(?:\s?/?>|$): lol
*/