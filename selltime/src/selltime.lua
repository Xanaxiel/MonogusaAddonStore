--アドオン名（大文字）
local addonName = "SellTime";
local addonNameUpper = string.upper(addonName);
local addonNameLower = string.lower(addonName);
--作者名
local author = "MONOGUSA";

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
  g.hooked = false;
  g.settings = {
    defaultTime = 1
  };
end

--lua読み込み時のメッセージ
CHAT_SYSTEM(string.format("%s.lua is loaded", addonNameLower));

function SELLTIME_SAVE_SETTINGS()
  acutil.saveJSON(g.settingsFileLoc, g.settings);
end


--マップ読み込み時処理（1度だけ）
function SELLTIME_ON_INIT(addon, frame)
  g.addon = addon;
  g.frame = frame;

  frame:ShowWindow(0);
  acutil.slashCommand("/selltime", SELLTIME_PROCESS_COMMAND);
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
  SELLTIME_SAVE_SETTINGS();

  --フック処理
  if not g.hooked then
    acutil.setupHook(MARKET_SELL_OPEN_HOOKED, "MARKET_SELL_OPEN");
  end

end

--チャットコマンド処理（acutil使用時）
function SELLTIME_PROCESS_COMMAND(command)
  local cmd = "";

  if #command > 0 then
    cmd = table.remove(command, 1);
  else
    local msg = "/selltime 数字{nl}1日,3日,5日,7日"
    return ui.MsgBox(msg,"","Nope")
  end

  local defaultTime = nil

  if cmd == "1" then
    defaultTime = 1;
  elseif cmd == "3" then
    defaultTime = 3;
  elseif cmd == "5" then
    defaultTime = 5;
  elseif cmd == "7" then
    defaultTime = 7;
  end

  if defaultTime then
    g.settings.defaultTime = defaultTime;
    CHAT_SYSTEM(string.format("[%s] Default Sell Time %d", addonName, cmd));
    SELLTIME_SAVE_SETTINGS()
    return;
  end

  CHAT_SYSTEM(string.format("[%s] Invalid Command", addonName));
end

function MARKET_SELL_OPEN_HOOKED(frame)
	MARKET_SELL_UPDATE_SLOT_ITEM(frame);
	market.ReqMySellList(0);
	packet.RequestItemList(IT_WAREHOUSE);

	local groupbox = frame:GetChild("groupbox");
	local droplist = GET_CHILD(groupbox, "sellTimeList", "ui::CDropList");	
	droplist:ClearItems();

	local defaultTime = g.settings.defaultTime;
  CHAT_SYSTEM(defaultTime);
	local cnt = GetMarketTimeCount();
	for i = 0 , cnt - 1 do
		local time, free = GetMarketTimeAndTP(i);
		local day = 0;
		local listType = ScpArgMsg("MarketTime{Time}{FREE}","Time", time, "FREE", free);
		droplist:AddItem(time, "{s16}{b}{ol}"..listType);
	end
	droplist:SelectItem(cnt - 1);
	droplist:SelectItemByKey(defaultTime);

	MARKET_SELL_ITEM_POP_BY_SLOT(frame, nil);
end