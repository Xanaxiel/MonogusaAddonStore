--アドオン名（大文字）
local addonName = "SavePrice";
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
  g.settings = {};
  g.hooked = false;
end

--lua読み込み時のメッセージ
CHAT_SYSTEM(string.format("%s.lua is loaded", addonNameLower));

function SAVEPRICE_SAVE_SETTINGS()
  acutil.saveJSON(g.settingsFileLoc, g.settings);
end

--マップ読み込み時処理（1度だけ）
function SAVEPRICE_ON_INIT(addon, frame)
  g.addon = addon;

  frame:ShowWindow(0);
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
  
  if not g.hooked then
    acutil.setupHook(ON_MARKET_MINMAX_INFO_HOOKED, 'ON_MARKET_MINMAX_INFO');
    acutil.setupHook(ON_MARKET_REGISTER_HOOKED, 'ON_MARKET_REGISTER');
  end
  
  --設定ファイル保存処理
  SAVEPRICE_SAVE_SETTINGS();
end

--金額を保存する
function ON_MARKET_REGISTER_HOOKED(frame, msg, argStr, argNum)
  
  local g = _G["ADDONS"]["MONOGUSA"]["SAVEPRICE"];
  local groupbox = frame:GetChild("groupbox");
  local edit_price = GET_CHILD(groupbox, "edit_price", "ui::CEditControl");
	local slot_item = GET_CHILD(groupbox, "slot_item", "ui::CSlot");

	local invItem = GET_SLOT_ITEM(slot_item);
  
  local price = tonumber(edit_price:GetText());
  if invItem and price then
    local itemCls = GetClassByType("Item", invItem.type);
    g.settings[tostring(itemCls.ClassID)] = price;
    SAVEPRICE_SAVE_SETTINGS();
  end
  
  return ON_MARKET_REGISTER_OLD(frame, msg, argStr, argNum);
end

--既存の処理をフックする
function ON_MARKET_MINMAX_INFO_HOOKED(frame, msg, argStr, argNum)
  local g = _G["ADDONS"]["MONOGUSA"]["SAVEPRICE"];
	local itemID = frame:GetUserValue('REQ_ITEMID');
	local invItem = session.GetInvItemByGuid(itemID);
  local itemCls = GetClassByType("Item", invItem.type);
	local groupbox = frame:GetChild("groupbox");
	local silverRate = groupbox:GetChild("silverRate");

	local upValue = silverRate:GetChild("upValue");
	local downValue = silverRate:GetChild("downValue");
	local min = silverRate:GetChild("min");
	local max = silverRate:GetChild("max");

	upValue:SetTextByKey("value", '0');
	downValue:SetTextByKey("value", '0');
	min:SetTextByKey("value", '0');
	max:SetTextByKey("value", '0');

	local edit_price = GET_CHILD(groupbox, "edit_price", "ui::CEditControl");
	edit_price:SetText("0");
	edit_price:SetMaxNumber(2147483647);
  
  local savedPrice = g.settings[tostring(itemCls.ClassID)];
  if savedPrice then
    CHAT_SYSTEM(itemCls.Name..":"..savedPrice);
    edit_price:SetText(savedPrice);
  end
  
	if argNum == 1 then	
		local tokenList = TokenizeByChar(argStr, ";");
		local minStr = tokenList[1];
		local minAllow = tokenList[2];
		local maxStr = tokenList[3];
		local maxAllow = tokenList[4];
		local avg = tokenList[5];

		upValue:SetTextByKey("value", maxAllow);
		downValue:SetTextByKey("value", minAllow);
		min:SetTextByKey("value", minStr);
		max:SetTextByKey("value", maxStr);
    if not savedPrice then
      edit_price:SetText(avg);
    end

		if IGNORE_ITEM_AVG_TABLE_FOR_TOKEN == 1 then
			if false == session.loginInfo.IsPremiumState(ITEM_TOKEN) then
				edit_price:SetMaxNumber(maxAllow);
			else
				edit_price:SetMaxNumber(2147483647);
			end
		else
			edit_price:SetMaxNumber(maxAllow);
		end
		return;
	end

	frame:SetUserValue('REQ_ITEMID', 'None')
	MARKET_SELL_UPDATE_REG_SLOT_ITEM(frame:GetTopParentFrame(), invItem, nil);
end
