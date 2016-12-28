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
    party = {
      enable = true,
      enableSkillList = {
        --デフォルト設定
        ["10005"] = {enable = true}, --Swordman_PainBarrier
        ["10103"] = {enable = true}, --Peltasta_SwashBuckling
        ["10307"] = {enable = true}, --Hoplite_SpearLunge
        ["10601"] = {enable = true}, --Cataphract_Impaler
        ["10606"] = {enable = true}, --Cataphract_Rush
        ["10704"] = {enable = true}, --Squire_Arrest
        ["11003"] = {enable = true}, --Doppelsoeldner_Double_pay_earn
        ["11005"] = {enable = true}, --Doppelsoeldner_Cyclone
        ["11110"] = {enable = true}, --Fencer_EpeeGarde
        ["11201"] = {enable = true}, --Shinobi_Mijin_no_jutsu
        ["11202"] = {enable = true}, --Shinobi_Bunshin_no_jutsu
        ["11402"] = {enable = true}, --Dragoon_Serpentine
        ["11501"] = {enable = true}, --Templer_SummonGuildMember
        ["11502"] = {enable = true}, --Templer_WarpToGuildMember
        ["11505"] = {enable = true}, --Templer_BattleOrders
        ["11507"] = {enable = true}, --Templer_ShareBuff
        ["11603"] = {enable = true}, --Rancer_Joust
        ["20002"] = {enable = true}, --Wizard_Lethargy
        ["20003"] = {enable = true}, --Wizard_Sleep
        ["20203"] = {enable = true}, --Cryomancer_IceWall
        ["20207"] = {enable = true}, --Cryomancer_SnowRolling
        ["20208"] = {enable = true}, --Cryomancer_FrostPillar
        ["20301"] = {enable = true}, --Psychokino_PsychicPressure
        ["20302"] = {enable = true}, --Psychokino_Telekinesis
        ["20303"] = {enable = true}, --Psychokino_Swap
        ["20304"] = {enable = true}, --Psychokino_Teleportation
        ["20305"] = {enable = true}, --Psychokino_MagneticForce
        ["20306"] = {enable = true}, --Psychokino_Raise
        ["20307"] = {enable = true}, --Psychokino_GravityPole
        ["20401"] = {enable = true}, --Linker_Unbind
        ["20402"] = {enable = true}, --Linker_Physicallink
        ["20403"] = {enable = true}, --Linker_JointPenalty
        ["20404"] = {enable = true}, --Linker_HangmansKnot
        ["20405"] = {enable = true}, --Linker_SpiritualChain
        ["20406"] = {enable = true}, --Linker_UmbilicalCord
        ["20503"] = {enable = true}, --Thaumaturge_SwellBody
        ["20505"] = {enable = true}, --Thaumaturge_Reversi
        ["20608"] = {enable = true}, --Elementalist_FrostCloud
        ["20701"] = {enable = true}, --Sorcerer_Summoning
        ["20708"] = {enable = true}, --Sorcerer_SummonServant
        ["20801"] = {enable = true}, --Chronomancer_Quicken
        ["20802"] = {enable = true}, --Chronomancer_Samsara
        ["20803"] = {enable = true}, --Chronomancer_Stop
        ["20805"] = {enable = true}, --Chronomancer_Haste
        ["20806"] = {enable = true}, --Chronomancer_BackMasking
        ["20807"] = {enable = true}, --Chronomancer_Pass
        ["20907"] = {enable = true}, --Necromancer_DirtyPole
        ["21107"] = {enable = true}, --Featherfoot_Levitation
        ["21108"] = {enable = true}, --Featherfoot_BloodCurse
        ["21201"] = {enable = true}, --Warlock_PoleofAgony
        ["21203"] = {enable = true}, --Warlock_DarkTheurge
        ["21302"] = {enable = true}, --RuneCaster_Isa
        ["21303"] = {enable = true}, --RuneCaster_Thurisaz
        ["21401"] = {enable = true}, --Sage_Portal
        ["21403"] = {enable = true}, --Sage_MicroDimension
        ["21404"] = {enable = true}, --Sage_UltimateDimension
        ["21405"] = {enable = true}, --Sage_Blink
        ["21408"] = {enable = true}, --Sage_MissileHole
        ["21507"] = {enable = true}, --Enchanter_EnchantLightning
        ["21508"] = {enable = true}, --Enchanter_Empowering
        ["30207"] = {enable = true}, --QuarrelShooter_RunningShot
        ["30304"] = {enable = true}, --Sapper_DetonateTraps
        ["30306"] = {enable = true}, --Sapper_BroomTrap
        ["30402"] = {enable = true}, --Hunter_Snatching
        ["30406"] = {enable = true}, --Hunter_Retrieve
        ["30502"] = {enable = true}, --Wugushi_NeedleBlow
        ["30504"] = {enable = true}, --Wugushi_WugongGu
        ["30604"] = {enable = true}, --Scout_Cloaking
        ["30605"] = {enable = true}, --Scout_Undistance
        ["30703"] = {enable = true}, --Rogue_Spoliation
        ["30706"] = {enable = true}, --Rogue_Burrow
        ["30707"] = {enable = true}, --Rogue_Lachrymator
        ["30904"] = {enable = true}, --Schwarzereiter_RetreatShot
        ["30907"] = {enable = true}, --Schwarzereiter_AssaultFire
        ["31003"] = {enable = true}, --Falconer_Circling
        ["31106"] = {enable = true}, --Cannoneer_SmokeGrenade
        ["31203"] = {enable = true}, --Musketeer_Snipe
        ["31301"] = {enable = true}, --Hackapell_Skarphuggning
        ["31402"] = {enable = true}, --Mergen_FocusFire
        ["31405"] = {enable = true}, --Mergen_ArrowRain
        ["40001"] = {enable = true}, --Cleric_Heal
        ["40002"] = {enable = true}, --Cleric_Cure
        ["40003"] = {enable = true}, --Cleric_SafetyZone
        ["40005"] = {enable = true}, --Cleric_DivineMight
        ["40006"] = {enable = true}, --Cleric_Fade
        ["40007"] = {enable = true}, --Cleric_PatronSaint
        ["40103"] = {enable = true}, --Kriwi_Daino
        ["40105"] = {enable = true}, --Kriwi_DivineStigma
        ["40106"] = {enable = true}, --Kriwi_Melstis
        ["40201"] = {enable = true}, --Priest_Aspersion
        ["40203"] = {enable = true}, --Priest_Blessing
        ["40204"] = {enable = true}, --Priest_Resurrection
        ["40205"] = {enable = true}, --Priest_Sacrament
        ["40206"] = {enable = true}, --Priest_Revive
        ["40209"] = {enable = true}, --Priest_MassHeal
        ["40210"] = {enable = true}, --Priest_StoneSkin
        ["40301"] = {enable = true}, --Bokor_Hexing
        ["40305"] = {enable = true}, --Bokor_Mackangdal
        ["40307"] = {enable = true}, --Bokor_Samdiveve
        ["40308"] = {enable = true}, --Bokor_Ogouveve
        ["40401"] = {enable = true}, --Dievdirbys_CarveVakarine
        ["40402"] = {enable = true}, --Dievdirbys_CarveZemina
        ["40403"] = {enable = true}, --Dievdirbys_CarveLaima
        ["40405"] = {enable = true}, --Dievdirbys_CarveOwl
        ["40406"] = {enable = true}, --Dievdirbys_CarveAustrasKoks
        ["40407"] = {enable = true}, --Dievdirbys_CarveAusirine
        ["40501"] = {enable = true}, --Sadhu_OutofBody
        ["40502"] = {enable = true}, --Sadhu_Prakriti
        ["40503"] = {enable = true}, --Sadhu_VashitaSiddhi
        ["40504"] = {enable = true}, --Sadhu_AstralBodyExplosion
        ["40505"] = {enable = true}, --Sadhu_Possession
        ["40506"] = {enable = true}, --Sadhu_TransmitPrana
        ["40602"] = {enable = true}, --Paladin_Restoration
        ["40603"] = {enable = true}, --Paladin_ResistElements
        ["40605"] = {enable = true}, --Paladin_Conversion
        ["40606"] = {enable = true}, --Paladin_Barrier
        ["40607"] = {enable = true}, --Paladin_Conviction
        ["40701"] = {enable = true}, --Monk_IronSkin
        ["40708"] = {enable = true}, --Monk_Golden_Bell_Shield
        ["40802"] = {enable = true}, --Pardoner_Indulgentia
        ["40803"] = {enable = true}, --Pardoner_DiscernEvil
        ["40901"] = {enable = true}, --Druid_Telepath
        ["40903"] = {enable = true}, --Druid_ShapeShifting
        ["40904"] = {enable = true}, --Druid_Transform
        ["40905"] = {enable = true}, --Druid_StereaTrofh
        ["40906"] = {enable = true}, --Druid_Chortasmata
        ["40908"] = {enable = true}, --Druid_Lycanthropy
        ["40909"] = {enable = true}, --Druid_HengeStone
        ["41001"] = {enable = true}, --Oracle_CallOfDeities
        ["41002"] = {enable = true}, --Oracle_ArcaneEnergy
        ["41003"] = {enable = true}, --Oracle_Change
        ["41004"] = {enable = true}, --Oracle_Clairvoyance
        ["41005"] = {enable = true}, --Oracle_CounterSpell
        ["41006"] = {enable = true}, --Oracle_Forecast
        ["41007"] = {enable = true}, --Oracle_Ressetting
        ["41008"] = {enable = true}, --Oracle_DeathVerdict
        ["41009"] = {enable = true}, --Oracle_Prophecy
        ["41010"] = {enable = true}, --Oracle_SwitchGender
        ["41011"] = {enable = true}, --Oracle_Foretell
        ["41012"] = {enable = true}, --Oracle_TwistOfFate
        ["41101"] = {enable = true}, --PlagueDoctor_HealingFactor
        ["41102"] = {enable = true}, --PlagueDoctor_Incineration
        ["41103"] = {enable = true}, --PlagueDoctor_Bloodletting
        ["41104"] = {enable = true}, --PlagueDoctor_Fumigate
        ["41105"] = {enable = true}, --PlagueDoctor_Pandemic
        ["41106"] = {enable = true}, --PlagueDoctor_BeakMask
        ["41107"] = {enable = true}, --PlagueDoctor_PlagueVapours
        ["41108"] = {enable = true}, --PlagueDoctor_Disenchant
        ["41202"] = {enable = true}, --Kabbalist_Nachash
        ["41203"] = {enable = true}, --Kabbalist_Ayin_sof
        ["41207"] = {enable = true}, --Kabbalist_Multiple_Hit_Chance
        ["41208"] = {enable = true}, --Kabbalist_Reduce_Level
        ["41209"] = {enable = true}, --Kabbalist_Clone
        ["41301"] = {enable = true}, --Chaplain_LastRites
        ["41302"] = {enable = true}, --Chaplain_BuildCappella
        ["41303"] = {enable = true}, --Chaplain_MagnusExorcismus
        ["41406"] = {enable = true}, --Inquisitor_BreakingWheel
        ["41408"] = {enable = true}, --Inquisitor_MalleusMaleficarum
        ["41501"] = {enable = true}, --Daoshi_DarkSight
        ["41502"] = {enable = true}, --Daoshi_Entrenchment
        ["41503"] = {enable = true}, --Daoshi_Hurling
        ["41504"] = {enable = true}, --Daoshi_HiddenPotential
        ["41505"] = {enable = true}, --Daoshi_StormCalling
        ["41506"] = {enable = true}, --Daoshi_BegoneDemon
        ["41507"] = {enable = true}, --Daoshi_TriDisaster
        ["41601"] = {enable = true}, --Miko_Gohei
        ["41602"] = {enable = true}, --Miko_HoukiBroom
        ["41603"] = {enable = true}, --Miko_Hamaya
        ["41604"] = {enable = true}, --Miko_Kasiwade
        ["41605"] = {enable = true}, --Miko_KaguraDance
      }
    }
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
  frame:ShowWindow(1);
  frame:Resize(0,0);

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


  frame:RunUpdateScript("SHOWSKILL_WATCH_PARTY");
  local handle = session.GetMyHandle();
  SHOWSKILL_INIT_UI(handle);
end

function SHOWSKILL_WATCH_PARTY()
  --local time = imcTime.GetAppTimeMS();
  if not g.settings.party.enable then
    return 1;
  end

  local list = session.party.GetPartyMemberList(PARTY_NORMAL);
  if list == nil then
    return 1;
  end

  local myInfo = session.party.GetMyPartyObj();
  local count = list:Count();

  for i = 0 , count - 1 do
    local partyMemberInfo = list:Element(i);
    local partymembermapName = GetClassByType("Map", partyMemberInfo:GetMapID()).ClassName;

    --同一マップ、同一チャンネルの場合
    if myInfo:GetMapID() == partyMemberInfo:GetMapID() and myInfo:GetChannel() == partyMemberInfo:GetChannel() then
      local handle = partyMemberInfo:GetHandle();
      if handle ~= session.GetMyHandle() then

        local frame = ui.GetFrame("showskill_"..handle);
        if frame == nil then
          frame = SHOWSKILL_INIT_UI(handle);
        end

        SHOWSKILL_IS_SKILL_USING(frame, handle);
      end
    end
  end
  return 1;
end

function SHOWSKILL_IS_SKILL_USING(frame, handle)
  local actor = world.GetActor(handle);

  if not actor then
    return;
  end
  --使用中のスキルIDを取得
  local skillID = actor:GetUseSkill();
  local usingSkill = frame:GetUserIValue("UsingSkill");

  if skillID ~= 0 then
    --表示中のスキルと違うスキルを使用している安倍
    if usingSkill ~= skillID then
      --スキル使用状態に変更
      frame:SetUserValue("UsingSkill", skillID);
      --スキル表示設定のチェック
      if g.settings.party.enableSkillList[tostring(skillID)] ~= nil and g.settings.party.enableSkillList[tostring(skillID)].enable then
        local skillCls = GetClassByType("Skill", skillID);
        SHOWSKILL_ON_PARTY_MEMBER_USE_SKILL(frame, actor, skillCls);
      end
    end
  else
    frame:SetUserValue("UsingSkill", 0);
    frame:ShowWindow(0)
  end
end


function SHOWSKILL_INIT_UI(handle)
  local frame = ui.CreateNewFrame("showskill", "showskill_"..handle);
  frame:ShowWindow(0);
  local width = 380;
  local height = 130;
  frame:Resize(width, height);
  frame:SetAnimation("openAnim", "None");

  local background = frame:CreateOrGetControl("picture", "skill_charge_gauge_bg", 0, 0, 210, 40);
  local gauge = frame:CreateOrGetControl("gauge", "gauge", 0, 40, 260, 50);
  local message = frame:CreateOrGetControl("richtext", "text", 0, 30, 370, 20);
  tolua.cast(background, "ui::CPicture");
  tolua.cast(message, "ui::CRichText");
  tolua.cast(gauge, "ui::CGauge");

  frame:SetSkinName("None");
  frame:SetUserValue("handle", handle);
  frame:SetUserValue("UsingSkill", 0);

  background:SetImage("skill-charge_gauge_bg");
  background:ShowWindow(0);
  background:EnableHitTest(0);
  background:SetEnableStretch(1);
  background:SetGravity(ui.CENTER_HORZ, ui.CENTER_VERT);

  gauge:SetGravity(ui.CENTER_HORZ, ui.TOP);
  gauge:SetSkinName("gauge");
  gauge:SetColorTone("EEFFFFFF");

  message:SetGravity(ui.CENTER_HORZ, ui.TOP);
  FRAME_AUTO_POS_TO_OBJ(frame, handle, - frame:GetWidth() / 2, -60, 3, 1);
  return frame;
end

function SHOWSKILL_ON_SHOT_START(frame, msg, argStr, argNum)
  local handle = session.GetMyHandle();
  local skillFrame = ui.GetFrame("showskill_"..handle);
  SHOWSKILL_ON_SKILLUSE(skillFrame);
end

function SHOWSKILL_ON_SKILLUSE(frame)
  local message = GET_CHILD(frame, "text", "ui::CRichText");
  local gauge = GET_CHILD(frame, "gauge", "ui::CGauge");
  local background = GET_CHILD(frame, "skill_charge_gauge_bg", "ui::CGauge");

  local handle = frame:GetUserIValue("handle");
  local actor = world.GetActor(handle);

  if not actor then
    return;
  end

  local skillID = actor:GetUseSkill();
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
    time = skillObj.ShootTime / 1000 - 0.4;
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
  frame:ShowWindow(1);

  return 1;
end

function SHOWSKILL_ON_PARTY_MEMBER_USE_SKILL(frame, actor, skillCls)
  local message = GET_CHILD(frame, "text", "ui::CRichText");
  local gauge = GET_CHILD(frame, "gauge", "ui::CGauge");
  local background = GET_CHILD(frame, "skill_charge_gauge_bg", "ui::CGauge");

  local text = string.format("{@st41monskl}{#FFFF00}%s{/}{/}", skillCls.Name);
  background:ShowWindow(0);

  local time = 0.4;
  if skillCls.ClassName == "Doppelsoeldner_Cyclone" then
    time = 0.4;
  elseif string.find(skillCls.ClassName, "Dievdirbys_") ~= nil and skillCls.ClassName ~= "Dievdirbys_Carve" then
    --ルビーの像
    time = skillCls.ShootTime / 1000 - 0.4;
  elseif skillCls.ShootTime >= 50000 then
    --チャンネリング系
    --gauge:ShowWindow(0);
  elseif skillCls.CancelTime == 0 then
    --即キャンセル可
  elseif skillCls.CancelTime ~= 0 then
    --キャンセル可
    time = (skillCls.ShootTime - skillCls.CancelTime) / 1000;
    time = time > 0 and time or 0.4;
  end

  gauge:SetTotalTime(time);
  gauge:SetPoint(0, time);
  message:SetText(text);
  frame:ShowWindow(1);

  return 1;
end


function SHOWSKILL_ON_SHOT_END(frame, msg, argStr, argNum)
  local handle = session.GetMyHandle();
  local skillFrame = ui.GetFrame("showskill_"..handle);
  skillFrame:ShowWindow(0);
end

