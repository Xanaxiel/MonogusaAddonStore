CHAT_SYSTEM("Easy Search loaded!");

function EASYSEARCH_ON_INIT(addon, frame)
	local acutil = require('acutil');

	acutil.setupHook(EASYSEARCH_TO_MARKET_BUYMODE, 'MARKET_BUYMODE');
	acutil.setupHook(EASYSEARCH_ON_OPEN_MARKET, 'ON_OPEN_MARKET');
	acutil.setupHook(EASYSEARCH_ON_CLOSE_MARKET, 'MARKET_CLOSE');
end

function EASYSEARCH_TO_MARKET_BUYMODE(frame)
	INVENTORY_SET_CUSTOM_RBTNDOWN("EASYSEARCH_INV_RBTN");
	return MARKET_BUYMODE_OLD(frame);
end

function EASYSEARCH_ON_OPEN_MARKET(frame)
	INVENTORY_SET_CUSTOM_RBTNDOWN("EASYSEARCH_INV_RBTN");
	return ON_OPEN_MARKET_OLD(frame);
end

function EASYSEARCH_ON_CLOSE_MARKET(frame)
	INVENTORY_SET_CUSTOM_RBTNDOWN("None");
	return MARKET_CLOSE_OLD(frame);
end

function EASYSEARCH_INV_RBTN(itemObj, slot)
	local frame = ui.GetFrame("market");

	local gBox = GET_CHILD(frame, "detailOption");
	local find_name = GET_CHILD(gBox, "find_edit", "ui::CEditControl");
	local chip = GET_CHILD(gBox, "chip", "ui::CCheckBox");
	chip:SetCheck(1);
	local name = dictionary.ReplaceDicIDInCompStr(itemObj.Name);
	find_name:SetText(name);
	SEARCH_ITEM_MARKET();
end
