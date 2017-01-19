--アドオン名（大文字）
local addonName = "TimePlus";
local addonNameUpper = string.upper(addonName);
local addonNameLower = string.lower(addonName);
--作者名
local author = "AUTHOR";

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
  g.settings = {
    --有効/無効
    enable = true,
    alpha = 100,
    --フレーム表示場所
    position = {
      x = 0,
      y = 0
    }
  };
end

--lua読み込み時のメッセージ
CHAT_SYSTEM(string.format("%s.lua is loaded", addonNameLower));

function TIMEPLUS_SAVE_SETTINGS()
  acutil.saveJSON(g.settingsFileLoc, g.settings);
end


--マップ読み込み時処理（1度だけ）
function TIMEPLUS_ON_INIT(addon, frame)
  g.addon = addon;
  g.frame = frame;

  frame:ShowWindow(0);
  acutil.slashCommand("/"..addonNameLower, TIMEPLUS_PROCESS_COMMAND);
  if not g.loaded then
    local t, err = acutil.loadJSON(g.settingsFileLoc, g.settings);
    if err then
      --設定ファイル読み込み失敗時処理
      CHAT_SYSTEM(string.format("[%s] cannot load setting files", addonName));
    else
      --設定ファイル読み込み成功時処理
      g.settings = t;
    end
    g.loaded = true;
  end

  --設定ファイル保存処理
  TIMEPLUS_SAVE_SETTINGS();

  --コンテキストメニュー
  frame:SetEventScript(ui.RBUTTONDOWN, "TIMEPLUS_CONTEXT_MENU");
  --ドラッグ
  frame:SetEventScript(ui.LBUTTONUP, "TIMEPLUS_END_DRAG");

  --フレーム初期化処理
  TIMEPLUS_INIT_FRAME(frame);

  --再表示処理
  if g.settings.enable then
    frame:ShowWindow(1);
  else
    frame:ShowWindow(0);
  end
  --Moveではうまくいかないので、OffSetを使用する…
  frame:Move(0, 0);
  frame:SetOffset(g.settings.position.x, g.settings.position.y);
  addon:RegisterMsg("FPS_UPDATE", "TIMEPLUS_UPDATE_TIME");
end

function TIMEPLUS_GET_SERVERTIME()
  local serverTime = geTime.GetServerSystemTime();

  local gameTime = os.time({
      year = serverTime.wYear,
      month = serverTime.wMonth,
      day = serverTime.wDay,
      hour = serverTime.wHour,
      min = serverTime.wMinute,
      sec = serverTime.wSecond
    });

  return gameTime;
end

function TIMEPLUS_INIT_FRAME(frame)
  --XMLに記載するとデザイン調整時にクライアント再起動が必要になるため、luaに書き込むことをオススメする
  --フレーム初期化処理
  frame:Resize(180,30);
  local ampmText = frame:CreateOrGetControl("richtext", "ampmText", 0, 0, 0, 0);
  ampmText:EnableHitTest(0);
  local timeText = frame:CreateOrGetControl("richtext", "timeText", 30, 0, 0, 0);
  timeText:EnableHitTest(0);
  TIMEPLUS_SET_ALPHA(g.settings.alpha);
end

function TIMEPLUS_UPDATE_TIME()
  local frame = g.frame;

  local timeText = GET_CHILD(frame, "timeText", "ui::CRichText");
  local ampmText = GET_CHILD(frame, "ampmText", "ui::CRichText");

  --時刻を取得する
  local time = geTime.GetServerSystemTime();

  local hour = time.wHour;
  local min = time.wMinute;
  local sec = time.wSecond;
  local ampm = "am";

  if hour >= 12 then
    --午後の場合
    hour = hour == 12 and 0 or hour - 12
    ampm = "pm"
  else
    --午前の場合
    hour = hour == 0 and 12 or hour;
    ampm = "am"
  end

  timeText:SetText(string.format("{s30}{ol}%02d:%02d:%02d{/}{/}", hour, min, sec));
  ampmText:SetText(string.format("{s18}{ol}%s{/}{/}", ampm));

  return 1;
end

--コンテキストメニュー表示処理
function TIMEPLUS_CONTEXT_MENU(frame, msg, clickedGroupName, argNum)
  local context = ui.CreateContextMenu("TIMEPLUS_RBTN", addonName, 0, 0, 300, 100);
  ui.AddContextMenuItem(context, "Hide", "TIMEPLUS_TOGGLE_FRAME()");

  local subContextAlphaNum = ui.CreateContextMenu("SUBCONTEXT_ALPHA", "", 0, 0, 0, 0);
  for i = 1, 10 do
    ui.AddContextMenuItem(subContextAlphaNum, (i*10).."%" , string.format("TIMEPLUS_SET_ALPHA(%d)", (i*10)));
  end
  ui.AddContextMenuItem(context, "Alpha {img white_right_arrow 18 18}", "", nil, 0, 1, subContextAlphaNum);

  context:Resize(300, context:GetHeight());
  ui.OpenContextMenu(context);
end

--表示非表示切り替え処理
function TIMEPLUS_TOGGLE_FRAME()
  if g.frame:IsVisible() == 0 then
    --非表示->表示
    g.frame:ShowWindow(1);
    g.settings.enable = true;
  else
    --表示->非表示
    g.frame:ShowWindow(0);
    g.settings.enable = false;
  end

  TIMEPLUS_SAVE_SETTINGS();
end

--アルファ値処理
function TIMEPLUS_SET_ALPHA(alpha)
  --不正な値が入力された場合は100にする
  local frame = g.frame;
  if alpha == nil then alpha = 100 end
  if alpha < 0 or alpha > 100 then alpha = 100 end

  local timeText = GET_CHILD(frame, "timeText", "ui::CRichText");
  local ampmText = GET_CHILD(frame, "ampmText", "ui::CRichText");

  local ARGB = string.format("%02xFFFFFF", math.floor(alpha / 100 * 255));
  --frame:SetColorTone(ARGB);
  --CHAT_SYSTEM("ARGB:"..ARGB);
  frame:SetAlpha(alpha);
  timeText:SetAlpha(alpha);
  ampmText:SetAlpha(alpha);
  g.settings.alpha = alpha;
  TIMEPLUS_SAVE_SETTINGS();
end


--フレーム場所保存処理
function TIMEPLUS_END_DRAG()
  g.settings.position.x = g.frame:GetX();
  g.settings.position.y = g.frame:GetY();
  TIMEPLUS_SAVE_SETTINGS();
end

--チャットコマンド処理（acutil使用時）
function TIMEPLUS_PROCESS_COMMAND(command)
  local cmd = "";

  if #command > 0 then
    cmd = table.remove(command, 1);
  else
    TIMEPLUS_TOGGLE_FRAME();
    return;
  end

  if cmd == "alpha" then
    local arg = table.remove(command, 1);
    arg = tonumber(arg);
    if arg ~= nil then
      TIMEPLUS_SET_ALPHA(arg);
      return
    end
  end

  CHAT_SYSTEM(string.format("[%s] Invalid Command", addonName));
end

