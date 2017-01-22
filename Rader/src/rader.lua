--アドオン名（大文字）
local addonName = "Rader";
local addonNameUpper = string.upper(addonName);
local addonNameLower = string.lower(addonName);
--作者名
local author = "MONOGUSA";
local currentVersion = 1.1;

--アドオン内で使用する領域を作成。以下、ファイル内のスコープではグローバル変数gでアクセス可
_G["ADDONS"] = _G["ADDONS"] or {};
_G["ADDONS"][author] = _G["ADDONS"][author] or {};
_G["ADDONS"][author][addonNameUpper] = _G["ADDONS"][author][addonNameUpper] or {};
local g = _G["ADDONS"][author][addonNameUpper];

--設定ファイル保存先
g.settingsFileLoc = string.format("../addons/%s/settings.json", addonNameLower);

--ライブラリ読み込み
local acutil = require('acutil');

--デフォルト設定
if not g.loaded then
  g.mapWidth = 0;
  g.mapHeight = 0;
  g.mapui = nil;
  g.mapbg = nil;
  g.myself  = nil;
  g.enemyLayer = nil;
  g.mapprop = nil;
  
  g.currentZoomRate = 0;

  --レイヤー重ね順指定
  g.layerNames = {
    "party",
    "enemy",
    "boss",
  };

  g.layers = {};

  g.settings = {
    version = currentVersion,
    --有効/無効
    enable = true,
    minimapMode = false,
    --フレームサイズ
    width = 310,
    height = 230,
    zoomRate = 140,

    alpha = {
      bg = 50,
      myself = 70,
    },

    --フレーム表示場所
    position = {
      x = 400,
      y = 400,
    },
    blackList = {},
  };
end

--lua読み込み時のメッセージ
CHAT_SYSTEM(string.format("%s.lua is loaded", addonNameLower));

function RADER_SAVE_SETTINGS()
  acutil.saveJSON(g.settingsFileLoc, g.settings);
end

--マップ読み込み時処理（1度だけ）
function RADER_ON_INIT(addon, frame)
  g.addon = addon;
  g.frame = frame;
  local mapName = session.GetMapName();
  g.mapprop = geMapTable.GetMapProp(mapName);
  g.mapCls = GetClass("Map", mapName);

  frame:ShowWindow(0);
  acutil.slashCommand("/"..addonNameLower, RADER_PROCESS_COMMAND);
  if not g.loaded then
    local t, err = acutil.loadJSON(g.settingsFileLoc, g.settings);
    if err then
      --設定ファイル読み込み失敗時処理
      CHAT_SYSTEM(string.format("[%s] cannot load setting files", addonName));
    else
      --設定ファイル読み込み成功時処理
      if g.settings.version >= currentVersion then
        --バージョンが異なる場合
        g.settings = t;  
      else
        CHAT_SYSTEM(string.format("[%s] reset old setting files", addonName));
      end
    end
    g.loaded = true;
  end

  --設定ファイル保存処理
  RADER_SAVE_SETTINGS();

  --コンテキストメニュー
  frame:SetEventScript(ui.RBUTTONDOWN, "RADER_CONTEXT_MENU");
  --ドラッグ
  frame:SetEventScript(ui.LBUTTONUP, "RADER_END_DRAG");

  addon:RegisterMsg("GAME_START_3SEC", "RADER_3SEC");

end

function RADER_3SEC()
  local frame = g.frame;
    --再表示処理
  if g.settings.enable then
    frame:ShowWindow(1);
  else
    frame:ShowWindow(0);
  end
  --Moveではうまくいかないので、OffSetを使用する…
  frame:Move(0, 0);
  frame:SetOffset(g.settings.position.x, g.settings.position.y);
  --フレーム初期化処理
  RADER_INIT_FRAME(frame);
  g.addon:RegisterMsg("MON_ENTER_SCENE", "RADER_ON_MON_ENTER_SCENE");
  frame:RunUpdateScript("RADER_UPDATE");
end

function RADER_CHANGE_ZOOM(percentage, save)
  g.currentZoomRate = percentage;
  g.mapWidth = g.mapui:GetImageWidth() * (100 + percentage) / 100;
  g.mapHeight = g.mapui:GetImageHeight() * (100 + percentage) / 100;
  if save then
    g.settings.zoomRate = percentage;
    
    RADER_SAVE_SETTINGS()
  end
end

function RADER_INIT_FRAME(frame)
  --XMLに記載するとデザイン調整時にクライアント再起動が必要になるため、luaに書き込むことをオススメする
  --フレーム初期化処理
  local w = g.settings.width;
  local h = g.settings.height
  frame:Resize(w, h);

  --マップ
  local mapbg = frame:CreateOrGetControl("picture", "mapbg", 0, 0, 4096, 2048);
  local mapui = frame:CreateOrGetControl("picture", "map", 0, 0, 4096, 2048);
  --敵配置レイヤー
  local layers = RADER_INIT_LAYERS(frame);
  local myself = frame:CreateOrGetControl("picture", "my", 0, 0, 84, 84);

  --自分自身
  tolua.cast(mapbg, "ui::CPicture");
  tolua.cast(mapui, "ui::CPicture");
  tolua.cast(myself, "ui::CPicture");

  mapbg:SetEnableStretch(1);
  mapui:SetEnableStretch(1);
  myself:SetEnableStretch(1);
  mapbg:EnableHitTest(0);
  mapui:EnableHitTest(0);
  myself:EnableHitTest(0);

  local mapName = session.GetMapName();
  mapui:SetImage(mapName .. "_fog");
  myself:SetImage("minimap_leader");
  mapbg:SetImage(mapName .. "_fog");

  --自キャラを中央揃え
  myself:SetOffset(frame:GetWidth() / 2 - myself:GetImageWidth() / 2 , frame:GetHeight() / 2 - myself:GetImageHeight() / 2);

  g.myself = myself;
  g.mapbg = mapbg;
  g.mapui = mapui;

  RADER_LOAD_USERDATA();
  if g.settings.minimapMode then
    RADER_ENABLE_RADER_MINIMAP_MODE(true);
  end
  RADER_UPDATE();
end

function RADER_ENABLE_RADER_MINIMAP_MODE(save)
  g.frame:Resize(310, 230 -35);
  g.settings.minimapMode = true;
  local minimap = ui.GetFrame("minimap");
  local x = minimap:GetX();
  local y = minimap:GetY();
  g.frame:Move(0, 0);
  g.frame:SetOffset(x, y);

  RADER_CHANGE_MYSELF_ALPHA(0, false);
  RADER_CHANGE_BG_ALPHA(0, false);
  g.currentZoomRate = GET_MINIMAPSIZE();
  RADER_CHANGE_ZOOM(GET_MINIMAPSIZE(), false);
  if save then
    RADER_SAVE_SETTINGS();
  end
end


--レイヤー一覧を初期化
function RADER_INIT_LAYERS(frame)
  local layers = frame:CreateOrGetControl("groupbox", "layers", 0, 0, 4096, 2048);
  layers:SetSkinName("none");
  layers:EnableHitTest(0);

  for i, layerName in ipairs(g.layerNames) do
    local layer = layers:CreateOrGetControl("groupbox", layerName.."Layer", 0, 0, 4096, 2048);
    layer:SetSkinName("none");
    layer:EnableHitTest(0);
    g.layers[layerName] = layer;
  end

  return layers;
end

function RADER_CHANGE_BG_ALPHA(alpha, save)
  local A = string.format("%02x", math.floor(alpha / 100 * 255));
  g.mapbg:SetColorTone(A.."FF0000");
  g.mapui:SetColorTone(A.."FFFFFF");
  --アルファ値を保存

  if save then
    g.settings.alpha.bg = alpha;
    RADER_SAVE_SETTINGS()
  end
end

function RADER_CHANGE_MYSELF_ALPHA(alpha, save)
  local A = string.format("%02x", math.floor(alpha / 100 * 255));
  g.myself:SetColorTone(A.."FFFFFF");
  
  --アルファ値を保存
  if save then
    g.settings.alpha.myself = alpha;
    RADER_SAVE_SETTINGS();
  end
end

function RADER_LOAD_USERDATA()
  g.frame:Resize(310, 230);
  RADER_CHANGE_BG_ALPHA(g.settings.alpha.bg);
  RADER_CHANGE_MYSELF_ALPHA(g.settings.alpha.myself);
  g.mapWidth = g.mapui:GetImageWidth() * (100 + g.settings.zoomRate) / 100;
  g.mapHeight = g.mapui:GetImageHeight() * (100 + g.settings.zoomRate) / 100;
end

function RADER_UPDATE()
  if not g.settings.enable then
    return;
  end

  local frame = g.frame;

  local mapName = session.GetMapName();
  if ui.IsImageExist(mapName) == 0 then
    return;
  end
  
  if g.settings.minimapMode and g.currentZoomRate ~= GET_MINIMAPSIZE() then
    
    RADER_ENABLE_RADER_MINIMAP_MODE(false);
  end

  local w = g.mapWidth;
  local h = g.mapHeight;

  g.mapui:Resize(w, h);
  g.mapbg:Resize(w, h);

  --自キャラのポジションを取得
  local handle = session.GetMyHandle();
  local pos = info.GetPositionInMap(handle, w, h);

  RADER_UPDATE_PARTY()

  --自キャラの角度を変更
  local angle = info.GetAngle(handle) - g.mapprop.RotateAngle;
  g.myself:SetAngle(angle);

  --移動していない場合何もしない
  local bx = frame:GetUserIValue("MBEFORE_X");
  local by = frame:GetUserIValue("MBEFORE_Y");

  if pos.x == bx and pos.y == by then
    return
  else
    frame:SetUserValue("MBEFORE_X", pos.x);
    frame:SetUserValue("MBEFORE_Y", pos.y);
  end

  --オフセットを計算
  local miniX = pos.x - g.myself:GetOffsetX() - g.myself:GetImageWidth() / 2;
  local miniY = pos.y - g.myself:GetOffsetY() - g.myself:GetImageHeight() / 2;
  miniX = math.floor(miniX);
  miniY = math.floor(miniY);

  --マップ画像の位置を変更
  g.mapui:SetOffset(-miniX, - miniY);

  g.mapbg:SetOffset(-miniX, - miniY);

  for k, layer in pairs(g.layers) do
    layer:SetOffset(-miniX, - miniY);  
    --CHAT_SYSTEM("layer:"..k);
  end
  return 1;
end

--コンテキストメニュー表示処理
function RADER_CONTEXT_MENU(frame, msg, clickedGroupName, argNum)
  local context = ui.CreateContextMenu("RADER_RBTN", addonName, 0, 0, 150, 100);
  ui.AddContextMenuItem(context, "Hide", "RADER_TOGGLE_FRAME()");
  ui.AddContextMenuItem(context, "Draw on minimap", "RADER_ENABLE_RADER_MINIMAP_MODE(true)");

  --zoom
  local subContextZoom = ui.CreateContextMenu("SUBCONTEXT_ZOOM", "", 0, 0, 0, 0);
  for i = -3, 7 do
    local percentage = 100 + i*20
    ui.AddContextMenuItem(subContextZoom, percentage.."%" , string.format("RADER_CHANGE_ZOOM(%d, true)", i*20));
  end
  ui.AddContextMenuItem(context, "Zoom {img white_right_arrow 18 18}", "", nil, 0, 1, subContextZoom);

  --bg alpha
  local subContextBGAlphaNum = ui.CreateContextMenu("SUBCONTEXT_BG_ALPHA", "", 0, 0, 0, 0);
  for i = 0, 10 do
    ui.AddContextMenuItem(subContextBGAlphaNum, (i*10).."%" , string.format("RADER_CHANGE_BG_ALPHA(%d, true)", (i*10)));
  end
  ui.AddContextMenuItem(context, "BG Alpha {img white_right_arrow 18 18}", "", nil, 0, 1, subContextBGAlphaNum);

  --myself alpha
  local subContextMYSELFAlphaNum = ui.CreateContextMenu("SUBCONTEXT_MYSELF_ALPHA", "", 0, 0, 0, 0);
  for i = 0, 10 do
    ui.AddContextMenuItem(subContextMYSELFAlphaNum, (i*10).."%" , string.format("RADER_CHANGE_MYSELF_ALPHA(%d, true)", (i*10)));
  end
  ui.AddContextMenuItem(context, "MYSELF Alpha {img white_right_arrow 18 18}", "", nil, 0, 1, subContextMYSELFAlphaNum);

  context:Resize(150, context:GetHeight());
  ui.OpenContextMenu(context);
end

function RADER_UPDATE_PARTY()
  --パーティメンバーの移動
  --パーティメンバーかどうかをチェックする
  local list = session.party.GetPartyMemberList(PARTY_NORMAL);
  if list ~= nil then
    local myInfo = session.party.GetMyPartyObj();
    local count = list:Count();

    for i = 0 , count - 1 do
      local partyMemberInfo = list:Element(i);

      --同一マップ、同一チャンネルの場合
      if myInfo:GetMapID() == partyMemberInfo:GetMapID() and myInfo:GetChannel() == partyMemberInfo:GetChannel() then
        local handle = partyMemberInfo:GetHandle();
        if handle ~= session.GetMyHandle() then
          local actor = world.GetActor(handle);
          if actor ~= nil then
            RADER_CREATE_PARTYICON(handle, actor, partyMemberInfo);
          end

        end
      end
    end
  end
end



--表示非表示切り替え処理
function RADER_TOGGLE_FRAME()
  if g.frame:IsVisible() == 0 then
    --非表示->表示
    g.frame:ShowWindow(1);
    g.settings.enable = true;
  else
    --表示->非表示
    g.frame:ShowWindow(0);
    g.settings.enable = false;
  end

  RADER_SAVE_SETTINGS();
end

--フレーム場所保存処理
function RADER_END_DRAG()
  g.settings.position.x = g.frame:GetX();
  g.settings.position.y = g.frame:GetY();
  RADER_LOAD_USERDATA();
  RADER_SAVE_SETTINGS();
end

--チャットコマンド処理（acutil使用時）
function RADER_PROCESS_COMMAND(command)
  local cmd = "";

  if #command > 0 then
    cmd = string.lower(table.remove(command, 1));
  else
    local msg = ""
    msg = msg.."使い方{nl}";
    msg = msg.."/rader on/off{nl}";
    msg = msg.."表示/非表示切り替え{nl}";
    msg = msg.."{nl}";
    msg = msg.."/rader zoom 数字n{nl}";
    msg = msg.."n%の縮尺でミニマップを表示{nl}";
    msg = msg.."/rader zoom up{nl}";
    msg = msg.."10%拡大{nl}";
    msg = msg.."/rader zoom down{nl}";
    msg = msg.."10%縮小{nl}";
    msg = msg.."{nl}";
    msg = msg.."/rader filter{nl}";
    msg = msg.."ターゲット中の敵をフィルター切り替え{nl}";
    msg = msg.."※すでに表示中の敵は表示されっぱなし";
    return ui.MsgBox(msg,"","Nope")
  end

  if cmd == "minimap" then
    RADER_ENABLE_RADER_MINIMAP_MODE(true)
    return
  elseif cmd == "on" then
    --有効
    g.settings.enable = true;
    g.frame:ShowWindow(1);
    CHAT_SYSTEM(string.format("[%s] is enable", addonName));
    RADER_SAVE_SETTINGS();
    return;
  elseif cmd == "off" then
    --無効
    g.settings.enable = false;
    g.frame:ShowWindow(0);
    CHAT_SYSTEM(string.format("[%s] is disable", addonName));
    RADER_SAVE_SETTINGS();
    return;
  elseif cmd == "init" then
    RADER_INIT_SIZE();
    return;
  elseif cmd == "zoom" then
    local arg1 = string.lower(table.remove(command, 1));

    if arg1 == "up" then
      local zoom = g.settings.zoomRate + 10;
      RADER_CHANGE_ZOOM(zoom, true);
      return;
    elseif arg1 == "down" then
      local zoom = g.settings.zoomRate - 10;
      RADER_CHANGE_ZOOM(zoom, true);
      return;
    elseif tonumber(arg1) ~= nil then
      RADER_CHANGE_ZOOM(tonumber(arg1), true);
      return;
    end
  elseif cmd == "filter" then
    RADER_TOGGLE_TARGET_IN_FILTER();
    return;
  end
  CHAT_SYSTEM(string.format("[%s] Invalid Command", addonName));
end

function RADER_ON_MON_ENTER_SCENE(frame, msg, str, handle)
  if not g.settings.enable then
    return;
  end

  --モンスター以外はチェックしない
  RADER_CREATE_ICON(handle);

end

function RADER_CREATE_ICON(handle)
  local actor = world.GetActor(handle);
  if actor == nil then
    return;
  end

  local objType = actor:GetObjType();

  if objType == GT_MONSTER then
    --モンスター
    RADER_CREATE_MONSTERICON(handle, actor);
  end
end

function RADER_CREATE_MONSTERICON(handle, actor)
  local layerName = "enemy";
  local monCls = GetClassByType("Monster", actor:GetType());
  local color = "FF0000";

  local targetInfo = info.GetTargetInfo(handle);

  if info.IsNegativeRelation(handle) == 0 then
    color = "FFFFFF";
  end
  --ターゲット不可オブジェクト、NPCは非表示
  if targetInfo.TargetWindow == 0 then
    return;
  elseif monCls.MonRank == "Boss" then
    layerName = "boss";
  end

  --フィルターチェック
  if g.settings.blackList[monCls.ClassName] then
    return;
  end

  local layer = g.layers[layerName];
  --ハンドル毎にアイコンを生成
  local monIcon = layer:GetChild("monster_"..handle);

  if monIcon == nil then
    if monCls.MonRank == "Boss" then
      monIcon = layer:CreateOrGetControl("picture", "monster_"..handle, 0, 0, 48, 48);
    else
      monIcon = layer:CreateOrGetControl("picture", "monster_"..handle, 0, 0, 16, 16);
    end
    tolua.cast(monIcon, "ui::CPicture");  
    monIcon:SetImage("sugoidot");
    monIcon:SetColorTone("FF"..color);
    monIcon:SetEnableStretch(1);
    monIcon:SetUserValue("HANDLE", handle);
  else
    tolua.cast(monIcon, "ui::CPicture");
  end
  monIcon:ShowWindow(1);
  monIcon:RunUpdateScript("RADER_UPDATE_POSITION")
end


function RADER_CREATE_PARTYICON(handle, actor, partyMemberInfo)
  local layerName = "party";

  local layer = g.layers[layerName];
  --ハンドル毎にアイコンを生成
  local monIcon = layer:GetChild("party_"..handle);

  if monIcon == nil then
    monIcon = layer:CreateOrGetControl("picture", "party_"..handle, 0, 0, 48, 48);
    tolua.cast(monIcon, "ui::CPicture");
    local icon = GET_JOB_ICON(partyMemberInfo:GetIconInfo().job)
    monIcon:SetImage(icon);
    monIcon:SetEnableStretch(1);
    monIcon:SetColorTone("FFFFFFFF");
    monIcon:SetUserValue("HANDLE", handle);
  else
    tolua.cast(monIcon, "ui::CPicture");
  end
  monIcon:ShowWindow(1);
  monIcon:RunUpdateScript("RADER_UPDATE_POSITION")
end


function RADER_GET_MAPSIZE()
  local g = _G["ADDONS"]["MONOGUSA"]["RADER"];
  return {w=g.mapWidth, h=g.mapHeight}
end

--位置の更新
function RADER_UPDATE_POSITION(frame)
  local handle = frame:GetUserIValue("HANDLE");

  local actor = world.GetActor(handle);
  if actor == nil then
    frame:ShowWindow(0);
    return 0;
  end

  local stat = info.GetStat(handle);
  if stat.HP <= 0 then
    frame:ShowWindow(0);
    return 0;
  end

  local worldPos= actor:GetPos();
  local mapSize = RADER_GET_MAPSIZE();
  local pos = g.mapprop:WorldPosToMinimapPos(worldPos.x, worldPos.z, mapSize.w, mapSize.h);

  local miniX = pos.x - frame:GetWidth()/2;
  local miniY = pos.y - frame:GetHeight()/2;
  miniX = math.floor(miniX);
  miniY = math.floor(miniY);
  frame:SetOffset(miniX, miniY);
  return 1;
end

function RADER_ADD_TARGET_IN_FILTER()
  local handle = session.GetTargetHandle();
  local actor = world.GetActor(handle);

  if actor == nil then
    return;
  end

  local monCls = GetClassByType("Monster", actor:GetType());
  RADER_ADD_FILTER(monCls.ClassName);
  RADER_SAVE_SETTINGS();
  CHAT_SYSTEM(string.format("[%s] add %s in filter", addonName, monCls.Name));
end


function RADER_REMOVE_TARGET_FROM_FILTER()
  local handle = session.GetTargetHandle();
  local actor = world.GetActor(handle);

  if actor == nil then
    return;
  end

  local monCls = GetClassByType("Monster", actor:GetType());
  RADER_REMOVE_FILTER(monCls.ClassName);
  RADER_SAVE_SETTINGS();
  CHAT_SYSTEM(string.format("[%s] remove %s in filter", addonName, monCls.Name));
end


function RADER_TOGGLE_TARGET_IN_FILTER()
  local handle = session.GetTargetHandle();
  local actor = world.GetActor(handle);

  if actor == nil then
    return;
  end

  local monCls = GetClassByType("Monster", actor:GetType());
  local className = monCls.ClassName;

  if not g.settings.blackList[className] then
    RADER_ADD_FILTER(monCls.ClassName);
    RADER_SAVE_SETTINGS();
    CHAT_SYSTEM(string.format("[%s] add %s in filter", addonName, monCls.Name));
  else
    RADER_REMOVE_FILTER(monCls.ClassName);
    RADER_SAVE_SETTINGS();
    CHAT_SYSTEM(string.format("[%s] remove %s in filter", addonName, monCls.Name));
  end
end


function RADER_ADD_FILTER(className)
  if not g.settings.blackList[className] then
    g.settings.blackList[className] = true;
  end
end

function RADER_REMOVE_FILTER(className)
  if g.settings.blackList[className] then
    g.settings.blackList[className] = false;
  end
end
