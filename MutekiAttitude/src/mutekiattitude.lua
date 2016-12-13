-- adoonの名称
local addonName = "MUTEKI";
local addonNameLower = string.lower(addonName);

-- ゲームに、adoonの情報を指定する ADDONS.MONOGUSA.MUTEKI
_G['ADDONS'] = _G['ADDONS'] or {};
_G['ADDONS']['MONOGUSA'] = _G['ADDONS']['MONOGUSA'] or {}
_G['ADDONS']['MONOGUSA'][addonName] = _G['ADDONS']['MONOGUSA'][addonName] or {};

local g = _G['ADDONS']['MONOGUSA'][addonName];
local acutil = require('acutil');

if not g.loaded then
	--設定配列
	g.settings = {
		enable = true,
	};
end
g.settingsFileLoc = "../addons/"..addonNameLower.."/settings.json";

function MUTEKI_PROCESS_COMMAND(words)
	local g = _G['ADDONS']['MONOGUSA']['MUTEKI'];
	local acutil = require('acutil');
	local cmd = table.remove(words,1);
	local frame = g.frame;

	if not cmd then
	elseif cmd == 'on' then
		g.settings.enable = true;
		frame:ShowWindow(1);
		CHAT_SYSTEM("Muteki Attitude is enable");
	elseif cmd == 'off' then
		g.settings.enable = false;
		frame:ShowWindow(0);
		CHAT_SYSTEM("Muteki Attitude is disable");
	end

	acutil.saveJSON(g.settingsFileLoc, g.settings);
end

function MUTEKI_CHECK_SHOW()
  local g = _G['ADDONS']['MONOGUSA']['MUTEKI'];
  if not g.settings.enable then
		return;
  else
    g.frame:ShowWindow(1);
	end
end


function MUTEKIATTITUDE_ON_INIT(addon, frame)
	local g = _G['ADDONS']['MONOGUSA']['MUTEKI'];
	local acutil = require('acutil');

	g.addon = addon;
	g.frame = frame;

	g.invincible = false;
	g.ausirine = false;

	acutil.slashCommand("/muteki", MUTEKI_PROCESS_COMMAND)

	if not g.loaded then
		local t, err = acutil.loadJSON(g.settingsFileLoc, g.settings);
		if err then
			acutil.saveJSON(g.settingsFileLoc, g.settings);
		else
			g.settings = t;
		end
		CHAT_SYSTEM('MUTEKI is loaded');
		g.loaded = true;
	end
	g.addon:RegisterMsg('BUFF_ADD', 'MUTEKI_UPDATE_BUFF');
	g.addon:RegisterMsg('BUFF_UPDATE', 'MUTEKI_UPDATE_BUFF');
	g.addon:RegisterMsg('BUFF_REMOVE', 'MUTEKI_UPDATE_BUFF');
  g.addon:RegisterMsg("MON_ENTER_SCENE", "MUTEKI_ON_MON_ENTER_SCENE");

	MUTEKI_INIT_UI(frame);
end

function MUTEKI_INIT_UI(frame)
	frame:ShowWindow(1);
end

function MUTEKI_UPDATE_NOTIMEBUFF(msg, argNum)
	local g = _G['ADDONS']['MONOGUSA']['MUTEKI'];
	if not g.settings.enable then
		return;
	end
	local frame = g.frame;
  MUTEKI_CHECK_SHOW();
	local gauge = GET_CHILD(frame, "gauge_"..argNum, "ui::CGauge");

	if msg == "BUFF_ADD" or msg == "BUFF_UPDATE" then
		gauge:SetTotalTime(20);
		gauge:SetPoint(20, 20);
		gauge:StopTimeProcess();
		gauge:ShowWindow(1);
	elseif msg == "BUFF_REMOVE" then
		gauge:ShowWindow(0);
	end
end

function MUTEKI_UPDATE_AUSIRINE(msg, argNum)
	local g = _G['ADDONS']['MONOGUSA']['MUTEKI'];
	local frame = g.frame;
  MUTEKI_CHECK_SHOW();
	local gauge = GET_CHILD(frame, "gauge_"..argNum, "ui::CGauge");
	local handle = session.GetMyHandle();
	local buff = info.GetBuff(tonumber(handle), argNum);

	if msg == "BUFF_ADD" or msg == "BUFF_UPDATE" then
		local time = math.floor(buff.time / 1000);
		gauge:SetTotalTime(time);
		gauge:SetPoint(0, time);
		
		if g.melstis then
			gauge:StopTimeProcess();
		end
		gauge:ShowWindow(1);
		imcSound.PlaySoundEvent("premium_enchantchip");
	elseif msg == "BUFF_REMOVE" then
		gauge:StopTimeProcess();
		gauge:ShowWindow(0);
	end
end

function MUTEKI_UPDATE_MELSTIS(msg, argNum)
	local g = _G['ADDONS']['MONOGUSA']['MUTEKI'];
	local frame = g.frame;
  MUTEKI_CHECK_SHOW();
	local gauge = GET_CHILD(frame, "gauge_229", "ui::CGauge");
	local handle = session.GetMyHandle();

	if msg == "BUFF_ADD" or msg == "BUFF_UPDATE" then
		g.melstis = true;
		gauge:StopTimeProcess();
		gauge:SetColorTone("FFFF0000");
	elseif msg == "BUFF_REMOVE" then
		g.melstis = false;
		local curPoint = gauge:GetCurPoint();
		local maxPoint = gauge:GetMaxPoint();
		gauge:SetColorTone("FFFFFFFF");
		gauge:SetPoint(curPoint, maxPoint);
		gauge:SetPointWithTime(maxPoint, maxPoint - curPoint, 1);
	end
end

function MUTEKI_UPDATE_BUFF(frame, msg, argStr, argNum)

	--SZ
	if argNum == 94 or argNum == 1021 then
		MUTEKI_UPDATE_NOTIMEBUFF(msg, argNum);
	end

	--無敵像
	if argNum == 229 then
		MUTEKI_UPDATE_AUSIRINE(msg, argNum);
	end
	
	--メルスティス
	if argNum == 3022 then
		MUTEKI_UPDATE_MELSTIS(msg, argNum);
	end
end

function MUTEKI_ON_MON_ENTER_SCENE(frame, msg, str, handle)
  local g = _G['ADDONS']['MONOGUSA']['MUTEKI'];

  if not g.settings.enable then
    return;
  end

  local actor = world.GetActor(handle);
  if actor:GetObjType() == GT_MONSTER then
    local monCls = GetClassByType("Monster", actor:GetType());

    if monCls.ClassName == "pcskill_wood_ausrine2" or monCls.ClassName == "pcskill_wood_ausrine" then

      local popup= ui.CreateNewFrame("hair_gacha_popup", "Ausirine_"..handle, 0);
      popup:ShowWindow(1);
      popup:EnableHitTest(0);
      local bonusimg = GET_CHILD_RECURSIVELY(popup, "bonusimg");
      local itembgimg = GET_CHILD_RECURSIVELY(popup, "itembgimg");
      bonusimg:ShowWindow(0);
      itembgimg:ShowWindow(0);
      
      local itemimg = GET_CHILD_RECURSIVELY(popup, "itemimg");
      itemimg:SetImage("icon_cler_craveAusirine");
      itemimg:SetColorTone("EEFFFFFF");

     	FRAME_AUTO_POS_TO_OBJ(popup, handle, - popup:GetWidth() / 2, -50, 3, 1);
    end
  end

end
