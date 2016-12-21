local addonName = "CLOVERFINDER";
local addonNameLower = string.lower(addonName);

_G['ADDONS'] = _G['ADDONS'] or {};
_G['ADDONS']['MONOGUSA'] = _G['ADDONS']['MONOGUSA'] or {};
_G['ADDONS']['MONOGUSA'][addonName] = _G['ADDONS']['MONOGUSA'][addonName] or {};

local g = _G['ADDONS']['MONOGUSA'][addonName];
g.settingsFileLoc = "../addons/"..addonNameLower.."/settings.json";

if not g.loaded then
  g.check = {};
  g.settings = {
    version = "1.0.0",
    language = "japanese",
    enable = true,
    partyChatEnable = true,
    text = {
      ["japanese"] = "%sの%sを発見！",
      ["english"] = "%s %s spotted!!"
    }
  };
end

CHAT_SYSTEM('CLOVERFINDER is enable');

function CLOVERFINDER_PROCESS_COMMAND(command)
  local g = _G['ADDONS']['MONOGUSA']['CLOVERFINDER'];
  local acutil = require('acutil');

  local cmd = "";

  if #command > 0 then
    cmd = string.lower(table.remove(command, 1));
  else
    local msg = "/clover on/off{nl}";
    msg = msg.. "Clover Finder enable/disable{nl}";
    msg = msg.. "/clover party on/off{nl}"
    msg = msg.. "inform for party on/off{nl}"
    msg = msg.. "/clover lang japanese{nl}"
    msg = msg.. "japanese{nl}"
    msg = msg.. "/clover lang english{nl}"
    msg = msg.. "english"
    return ui.MsgBox(msg,"","Nope")
  end

  if cmd == "on" then
    g.settings.enable = true;
    CHAT_SYSTEM(string.format("[CLOVERFINDER] %s is enable", cmd));
    acutil.saveJSON(g.settingsFileLoc, g.settings);
    return;
  elseif cmd == "off" then
    g.settings.enable = false;
    CHAT_SYSTEM(string.format("[CLOVERFINDER] %s is disable", cmd));
    acutil.saveJSON(g.settingsFileLoc, g.settings);
    return;
  elseif (cmd == "party") and #command > 0 then
    local arg = string.lower(table.remove(command, 1));
    if arg == "on" then
      g.settings.partyChatEnable = true;
      CHAT_SYSTEM(string.format("[CLOVERFINDER] inform for paty", cmd));
      acutil.saveJSON(g.settingsFileLoc, g.settings);
      return;
    elseif arg == "off" then
      g.settings.partyChatEnable = false;
      CHAT_SYSTEM(string.format("[CLOVERFINDER] don't inform for paty", cmd));
      acutil.saveJSON(g.settingsFileLoc, g.settings);
      return;
    end
  elseif (cmd == "language" or cmd == "lang") and #command > 0 then
    local arg = string.lower(table.remove(command, 1));
    local lang = g.settings.text[arg];
    if lang ~= nil then
      g.settings.language = arg;
      CHAT_SYSTEM(string.format("[CLOVERFINDER] set language %s", arg));
      acutil.saveJSON(g.settingsFileLoc, g.settings);
      return;
    end
  end

  CHAT_SYSTEM("[CLOVERFINDER] Invalid Command");
end

function CLOVERFINDER_ON_INIT(addon, frame)
  local g = _G['ADDONS']['MONOGUSA']['CLOVERFINDER'];
  local acutil = require('acutil');

  acutil.slashCommand("/clover", CLOVERFINDER_PROCESS_COMMAND);

  if not g.loaded then
    local t, err = acutil.loadJSON(g.settingsFileLoc, g.settings);
    if err then
      CHAT_SYSTEM('no save file');
    else
      CHAT_SYSTEM('CLOVERFINDER savedata is loaded');
      g.settings = t;
    end
    g.loaded = true;
  end

  acutil.saveJSON(g.settingsFileLoc, g.settings);
  addon:RegisterMsg("MON_ENTER_SCENE", "CLOVER_ON_MON_ENTER_SCENE");
end

function CLOVER_CHECK_TARGET_BUFF(type, handle, checkFn)

  if handle == nil then
    return false;
  end

  local buffCount = info.GetBuffCount(handle);

  for i = 0, buffCount - 1 do
    local buff = info.GetBuffIndexed(handle, i);
    --local cls = GetClassByType('Buff', buff.buffID);

    if buff.buffID == type then
      if checkFn ~= nil then
        return checkFn(buff);
      end
      return true;
    end
  end

  return false;
end

function CLOVER_CHECK_BUFF_LIST()
  local result = {
--    {
--      ["id"] = 8001,
--      ["icon"]="icon_expup_total",
--      ["bg"]="gacha_01",
--      ["color"]={
--        ["japanese"]="テスト色",
--        ["english"]="test"
--      },
--      checkFn=nil
--    },
    {
      ["id"] = 5028,
      ["icon"]="icon_item_jewelrybox",
      ["bg"]="gacha_01",
      ["color"]={
        ["japanese"]="金色",
        ["english"]="Gold"
      },
      checkFn=function(buff) return buff.arg2 == 1 end
    },
    {
      ["id"] = 5028,
      ["icon"]="icon_item_jewelrybox",
      ["bg"]="gacha_02",
      ["color"]={
        ["japanese"]="銀色",
        ["english"]="Silver"
      },
      checkFn=nil
    },
    {
      ["id"] = 5079,
      ["icon"]="icon_expup_total",
      ["bg"]="gacha_01",
      ["color"]={
        ["japanese"]="青色",
        ["english"]="Blue"
      },
      checkFn=nil
    },
    {
      ["id"] = 5086,
      ["icon"]="icon_state_medium",
      ["bg"]="gacha_03",
      ["color"]={
        ["japanese"]="赤色",
        ["english"]="Red"
      },
      checkFn=nil
    },
    {
      ["id"] = 5087,
      ["icon"]="icon_fieldboss",
      ["bg"]="gacha_03",
      ["color"]={
        ["japanese"]="エリート",
        ["english"]="Elite"
      },
      checkFn=nil
    }
  };

  return result;
end

function CLOVER_CHECK_MON(handle)
  local g = _G['ADDONS']['MONOGUSA']['CLOVERFINDER'];
  local actor = world.GetActor(handle);
  if actor == nil then
    g.check[tostring(handle)] = nil;
    return;
  end

  local monCls = GetClassByType("Monster", actor:GetType());
  local buffList = CLOVER_CHECK_BUFF_LIST();

  for i, buff in ipairs(buffList) do
    if CLOVER_CHECK_TARGET_BUFF(buff.id, handle, buff.checkFn) == true then

      if g.settings.partyChatEnable then
        local lang = g.settings.language or "japanese";
        local message = g.settings.text[lang] or "%sの%sを発見！";
        local colorName = buff.color[lang] or "よくわからんけどすごそうな感じ";
        ui.Chat(string.format("/p "..message, colorName, monCls.Name));
      end

      imcSound.PlaySoundEvent("sys_levelup");

      local popup= ui.CreateNewFrame("hair_gacha_popup", "test"..handle, 0);
      popup:ShowWindow(1);
      popup:EnableHitTest(0);
      local bonusimg = GET_CHILD_RECURSIVELY(popup, "bonusimg");
      bonusimg:ShowWindow(0);
      local itembgimg = GET_CHILD_RECURSIVELY(popup, "itembgimg");
      local itemimg = GET_CHILD_RECURSIVELY(popup, "itemimg");
      itemimg:SetImage(buff.icon);
      itembgimg:SetImage(buff.bg);
      itemimg:SetColorTone("CCFFFFFF");
      itembgimg:SetColorTone("CCFFFFFF");
      FRAME_AUTO_POS_TO_OBJ(popup, handle, - popup:GetWidth() / 2, -100, 3, 1);
      break;
    end
  end
  g.check[tostring(handle)] = nil;
end

function CLOVER_ON_MON_ENTER_SCENE(frame, msg, str, handle)
  local g = _G['ADDONS']['MONOGUSA']['CLOVERFINDER'];

  if not g.settings.enable then
    return;
  end

  if g.check == nil then
    g.check = {};
  end

  if g.check[tostring(handle)] ~= nil and os.clock() - g.check[tostring(handle)] < 1 then
    return;
  end

  g.check[tostring(handle)] = os.clock();

  local actor = world.GetActor(handle);

  if actor:GetObjType() == GT_MONSTER then
    --シーン直後に取得してもとれないので、ディレイをかけて実行する
    ReserveScript(string.format("CLOVER_CHECK_MON(%d or 0)", handle), 0.8);
  end

end
