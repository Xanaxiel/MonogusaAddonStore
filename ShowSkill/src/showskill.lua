-- adoonの名称
local addonName = "SHOWSKILL";
local addonNameLower = string.lower(addonName);

_G['ADDONS'] = _G['ADDONS'] or {};
_G['ADDONS']['MONOGUSA'] = _G['ADDONS']['MONOGUSA'] or {}
_G['ADDONS']['MONOGUSA'][addonName] = _G['ADDONS']['MONOGUSA'][addonName] or {};

local g = _G['ADDONS']['MONOGUSA'][addonName];
local acutil = require('acutil');
--local inspecter = require('inspect');

--デフォルト設定
if not g.loaded then
  --設定配列
  g.settings = {
    enable = true,
  };

end

g.settingsFileLoc = "../addons/"..addonNameLower.."/settings.json";

function SHOWSKILL_PROCESS_COMMAND(words)
  local cmd = table.remove(words,1);
  local frame = g.frame;

  if not cmd then
    SHOWSKILL_INIT_UI(nil);
  elseif cmd == 'on' then
    g.settings.enable = true;
    CHAT_SYSTEM("[ShowSkill] is enable");
  elseif cmd == 'off' then
    g.settings.enable = false;
    CHAT_SYSTEM("[ShowSkill] is disable");
  end

  acutil.saveJSON(g.settingsFileLoc, g.settings);
end

function SHOWSKILL_ON_INIT(addon, frame)
  g.addon = addon;
  g.frame = frame;

  acutil.slashCommand("/showskill", SHOWSKILL_PROCESS_COMMAND)

  if not g.loaded then
    local t, err = acutil.loadJSON(g.settingsFileLoc, g.settings);
    if err then
      acutil.saveJSON(g.settingsFileLoc, g.settings);
    else
      g.settings = t;
    end
    CHAT_SYSTEM('[ShowSkill] is loaded');
    g.loaded = true;
  end

  addon:RegisterMsg('SHOT_START', 'SHOWSKILL_ON_SHOT_START');
  addon:RegisterMsg('SHOT_END', 'SHOWSKILL_ON_SHOT_END');
  addon:RegisterMsg("GAME_START_3SEC", "SHOWSKILL_INIT_UI");
  SHOWSKILL_INIT_UI(frame);
end

function SHOWSKILL_INIT_UI(frame)
  frame = frame or g.frame;
  local width = 380;
  local height = 130;
  frame:Resize(width, height);
  --frame:ShowWindow(1);

  local background = frame:CreateOrGetControl("picture", "background", 0, 0, 210, 40);
  local gauge = frame:CreateOrGetControl("gauge", "skillGauge", 0, 40, 260, 50);
  local message = frame:CreateOrGetControl("richtext", "skillMessage", 0, 30, 370, 20);
  tolua.cast(background, "ui::CPicture");
  tolua.cast(message, "ui::CRichText");
  tolua.cast(gauge, "ui::CGauge");

  frame:SetSkinName("None");
  background:SetImage("skill-charge_gauge_bg");
  background:ShowWindow(0);
  background:EnableHitTest(0);
  background:SetEnableStretch(1);

  background:SetGravity(ui.CENTER_HORZ, ui.CENTER_VERT);

  gauge:SetGravity(ui.CENTER_HORZ, ui.TOP);
  gauge:SetSkinName("gauge");
  gauge:SetColorTone("EEFFFFFF");

  message:SetGravity(ui.CENTER_HORZ, ui.TOP);
  local handle = session.GetMyHandle();
  FRAME_AUTO_POS_TO_OBJ(frame, handle, - frame:GetWidth() / 2, -60, 3, 1);
end

function SHOWSKILL_ON_SHOT_START(frame, msg, argStr, argNum)
  frame:SetAnimation("openAnim", "None");
  local message = GET_CHILD(frame, "skillMessage", "ui::CRichText");
  local gauge = GET_CHILD(frame, "skillGauge", "ui::CGauge");
  local background = GET_CHILD(frame, "background", "ui::CGauge");

  background:Move(0, 0);
  background:SetOffset(0,100);
  local myActor = GetMyActor();
  local skillID = myActor:GetUseSkill();
  local skillObj = GetSkill(GetMyPCObject(), GetClassByType("Skill", skillID).ClassName);
  local sklLevel = skillObj.Level;
  local text = string.format("{@st41monskl}{#FFFF00}%s{/}{/}", skillObj.Name);
  background:ShowWindow(0);

  local sklProp = geSkillTable.Get(skillObj.ClassName);

  if sklProp.isNormalAttack then
    frame:ShowWindow(0);
    return;
  end

  local time = 0.4;
  if skillObj.ClassName == "Doppelsoeldner_Cyclone" then
    --サイクロン
    time = 2.5 + sklLevel * 0.3;
  elseif string.find(skillObj.ClassName, "Dievdirbys_") ~= nil and skillObj.ClassName ~= "Dievdirbys_Carve" then
    --ルビーの像
    time = skillObj.ShootTime / 1000;
  elseif skillObj.ShootTime >= 50000 then
    --チャンネリング系
    --gauge:ShowWindow(0);
  elseif skillObj.CancelTime == 0 then
    --即キャンセル可
  elseif skillObj.CancelTime ~= 0 then
    --キャンセル可
    time = (skillObj.ShootTime - skillObj.CancelTime) / 1000;
    time = time > 0 and time or 0.4;
  end

  gauge:SetTotalTime(time);
  gauge:SetPoint(0, time);

  message:SetText(text);
  g.frame:ShowWindow(1);

end

function SHOWSKILL_ON_SHOT_END(frame, msg, argStr, argNum)
  g.frame:ShowWindow(0);
end

