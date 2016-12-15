local addonName = "BOSSSPOTTER";
local addonNameLower = string.lower(addonName);

_G['ADDONS'] = _G['ADDONS'] or {};
_G['ADDONS']['MONOGUSA'] = _G['ADDONS']['MONOGUSA'] or {};
_G['ADDONS']['MONOGUSA'][addonName] = _G['ADDONS']['MONOGUSA'][addonName] or {};

local g = _G['ADDONS']['MONOGUSA'][addonName];
g.settingsFileLoc = "../addons/"..addonNameLower.."/settings.json";



if not g.loaded then
  g.check = {};
  g.chatCommand = {
    ["party"] = "/p ",
    ["guild"] = "/g "
  };
  g.settings = {
    language = 1,
    enable = true,

    type = {
      ["party"] = {enable = true},
      ["guild"] = {enable = false},
    },

    text = {
      {name = "japanese", message="%s ch%dでLv%d %sを発見"},
      {name = "english", message="%s　ch%d Lv%d %s spotted!!"}
    }

  };

end

CHAT_SYSTEM('BOSSSPOTTER is enable');

function BOSSSPOTTER_PROCESS_COMMAND(command)
  local cmd = "";

  if #command > 0 then
    cmd = table.remove(command, 1);
  else
    local msg = "This add-on will automatically report for party or guild where it was when you found the boss.{nl}{nl}";
    msg = msg.. "/bss on/off{nl}";
    msg = msg.. "Boss Spotter enable or disable{nl}";
    msg = msg.. "/bss party on/off{nl}";
    msg = msg.. "inform for party on/off{nl}";
    msg = msg.. "/bss guild on/off{nl}";
    msg = msg.. "inform for guild on/off{nl}";
    msg = msg.. "/bss lang japanese{nl}";
    msg = msg.. "inform by japanese{nl}";
    msg = msg.. "/bss lang english{nl}";
    msg = msg.. "inform by english{nl}";
    return ui.MsgBox(msg,"","Nope")
  end

  if cmd == "on" then
    g.settings.enable = true;
    CHAT_SYSTEM("[BossSpotter] is enable");
    acutil.saveJSON(g.settingsFileLoc, g.settings);
    return;
  elseif cmd == "off" then
    g.settings.enable = false;
    CHAT_SYSTEM("[BossSpotter] is disable");
    acutil.saveJSON(g.settingsFileLoc, g.settings);
    return;
  elseif (cmd == "language" or cmd == "lang") and #command > 0 then
    local arg = tonumber(table.remove(command, 1));

    if arg ~= nil and arg <= #g.settings.text then
      local lang = g.settings.text[arg].name;
      g.settings.language = arg;
      CHAT_SYSTEM(string.format("[BossSpotter] language is %s", lang));
      acutil.saveJSON(g.settingsFileLoc, g.settings);
      return;
    end
  elseif g.settings.type[cmd] ~= nil and #command > 0 then
    --チャット種別の選択
    local arg = table.remove(command, 1);
    --オンオフ
    if arg == "on" then
      g.settings.type[cmd].enable = true;
      CHAT_SYSTEM(string.format("[BossSpotter] %s is enable", cmd));
      acutil.saveJSON(g.settingsFileLoc, g.settings);
      return;
    elseif arg == "off" then
      g.settings.type[cmd].enable = false;
      CHAT_SYSTEM(string.format("[BossSpotter] %s is disable", cmd));
      acutil.saveJSON(g.settingsFileLoc, g.settings);
      return;
    end
  end
  CHAT_SYSTEM("[BossSpotter] Invalid Command");
end

function BOSSSPOTTER_ON_INIT(addon, frame)
  local g = _G['ADDONS']['MONOGUSA']['BOSSSPOTTER'];
  local acutil = require('acutil');

  g.addon = addon;
  g.frame = frame;

  acutil.slashCommand("/bss", BOSSSPOTTER_PROCESS_COMMAND);

  if not g.loaded then
    local t, err = acutil.loadJSON(g.settingsFileLoc, g.settings);
    if err then
      CHAT_SYSTEM('no save file');
    else
      CHAT_SYSTEM('BossSpotter savedata is loaded');
      g.settings = t;
    end
    g.loaded = true;
  end

  acutil.saveJSON(g.settingsFileLoc, g.settings);
  g.addon:RegisterMsg("MON_ENTER_SCENE", "BOSSSPOTTER_ON_MON_ENTER_SCENE");
end

function BOSSSPOTTER_ON_MON_ENTER_SCENE(frame, msg, str, handle)
  local g = _G['ADDONS']['MONOGUSA']['BOSSSPOTTER'];

  if not g.settings.enable then
    return;
  end

  if g.check[tostring(handle)] ~= nil and os.clock() - g.check[tostring(handle)] < 300 then
    --5分未満の重複報告を避ける
    return;
  end

  --モンスター以外はチェックしない
  local actor = world.GetActor(handle);
  if actor:GetObjType() ~= GT_MONSTER then
    return;
  end

  local monCls = GetClassByType("Monster", actor:GetType());

  --if string.find(monCls.ClassName, "Onion") then --テスト用のけっぴー発見コード
  if string.find(monCls.ClassName, "F_boss") or string.find(monCls.ClassName, "FD_boss") then
    g.check[tostring(handle)] = os.clock();
    ReserveScript("BOSSSPOTTER_ONSPOT("..handle..")", 0.5);
  end
end

function BOSSSPOTTER_ONSPOT(handle)
  local g = _G['ADDONS']['MONOGUSA']['BOSSSPOTTER'];
  
  local actor = world.GetActor(handle);
  if actor:GetObjType() ~= GT_MONSTER then
    return;
  end

  local monCls = GetClassByType("Monster", actor:GetType());

  local channel = session.loginInfo.GetChannel();
  local mapCls = GetClass("Map", session.GetMapName());
  local actorPos = actor:GetPos();
  local level = info.GetLevel(handle);
  local place = MAKE_LINK_MAP_TEXT(session.GetMapName(), actorPos.x, actorPos.z);
  local message = g.settings.text[g.settings.language].message;

  for key, type in pairs(g.settings.type) do
    if type.enable then
      local command = g.chatCommand[key];
      if command ~= nil then
        local chat = string.format(command..message, place, channel+1, level, monCls.Name);
        ui.Chat(chat);
      end
    end
  end
end

