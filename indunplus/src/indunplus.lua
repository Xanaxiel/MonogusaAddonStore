local addonName = "INDUNPLUS";
local addonNameLower = string.lower(addonName);

_G['ADDONS'] = _G['ADDONS'] or {};
_G['ADDONS']['MONOGUSA'] = _G['ADDONS']['MONOGUSA'] or {};
_G['ADDONS']['MONOGUSA'][addonName] = _G['ADDONS']['MONOGUSA'][addonName] or {};

local g = _G['ADDONS']['MONOGUSA'][addonName];
local acutil = require('acutil');

g.settingsFileLoc = "../addons/indunplus/settings.json";

if not g.loaded then
	g.isDragging = false;
	g.color = {
		normal = "FFFFFFFF",
		nearComplete = "FF00FFFF",
		complete = "FF00FF00",
	};
	g.settings = {
		--表示非表示
		show = false;
		--X座標、Y座標
		xPosition = 500,
		yPosition = 500,
		--リセット時刻
		resetHour = 6,
		--フォントのサイズ
		fontSize = 16,
		--1列に表示するキャラ数
		rowMax = 5,
		records = {},
	};

	g.bossDebuffId = 80001;

	g.types = {
		["100"] = {
			id = "Indun_startower",
			label = "ID",
			level = 50,
		},
		["200"] = {
			id = "Request_Mission1",
			label = "傭兵依頼",
			level = 100,
		},
		["300"] = {
			id = "Request_Mission7",
			label = "サルラス",
			level = 240,
		},
		["400"] = {
			id = "M_GTOWER_1",
			label = "大地",
			level = 260,
		},
		["500"] = {
			id = "Request_Mission10",
			label = "防衛",
			level = 120,
		},
	};

end

function g.processCommand(words)
	INDUNPLUS_SHOW_PLAYCOUNT();
	INDUNPLUS_TOGGLE_FRAME();
end

function g.getPlayCount(type)
	local etcObj = GetMyEtcObject();
	local etcType = "InDunCountType_"..type;
	local count = etcObj[etcType];

	return count;
end

function g.getMaxPlayCount(mission)
	local pCls = GetClass("Indun", mission);
	local maxPlayCnt = pCls.PlayPerReset;
	if true == session.loginInfo.IsPremiumState(ITEM_TOKEN) then 
		maxPlayCnt = maxPlayCnt + pCls.PlayPerReset_Token;
	end

	return maxPlayCnt;
end

function g.getResetTime()
	local currentDate = os.date("*t");

	local resetDate = os.date("*t");
	resetDate.hour = g.settings.resetHour;
	resetDate.min = 0;
	resetDate.sec = 0;
	
	local resetTime = os.time(resetDate);
	
	if currentDate.hour < g.settings.resetHour then
		resetTime = resetTime - 24*3600;
	end

	return resetTime;
end


function g.getBossDebuff()
	local g = _G['ADDONS']['MONOGUSA']['INDUNPLUS'];
	local result = false;
	
end

function g.createCharaNameText(frame, cid, record, fontSize, x, y, width, height)
	local charaText = frame:CreateOrGetControl("richtext", "record"..cid, x, y, width, height)
	tolua.cast(charaText, "ui::CRichText");
	
	local text = string.format("{s%d}%s{/}", fontSize, record.name);
	charaText:SetText(text);
	charaText:ShowWindow(1);
end

function g.createFBTimeText(frame, cid, record, fontSize, x, y, width, height)
	local g = _G['ADDONS']['MONOGUSA']['INDUNPLUS'];

	local color = "FFFFFF";
	if record.fbDebuffTime - 600 < os.time()  then
		color = "00FF00";
	elseif record.fbDebuffTime - 3600 < os.time() then
		color = "FFFF00";
	end

	local fbLabelText = frame:CreateOrGetControl("richtext", "fbLabel"..cid, x, y, width, height)
	local text = string.format("{#%s}{s%d}%s{/}{/}", color, fontSize, "FBデバフ");
	tolua.cast(fbLabelText, "ui::CRichText");
	fbLabelText:SetText(text);
	fbLabelText:ShowWindow(1);

	local fbText = frame:CreateOrGetControl("richtext", "fbDebuff"..cid, x, y, width, height)
	local fbDate = os.date("*t", record.fbDebuffTime);
	tolua.cast(fbText, "ui::CRichText");
	fbText:SetText(string.format("{#%s}{s%d}%02d:%02d:%02d{/}{/}",color, fontSize, fbDate.hour, fbDate.min, fbDate.sec));
	fbText:SetGravity(1,0);
	fbText:ShowWindow(1);
end

function INDUNPLUS_TOGGLE_FRAME()
	local g = _G['ADDONS']['MONOGUSA']['INDUNPLUS'];
	local acutil = require('acutil');
	ui.ToggleFrame("indunplus");

	g.settings.show = not g.settings.show;
	acutil.saveJSON(g.settingsFileLoc, g.settings);
end

function INDUNPLUS_SHOW_PLAYCOUNT()
	local g = _G['ADDONS']['MONOGUSA']['INDUNPLUS'];
	local acutil = require('acutil');
	local records = g.settings.records;
	
	local frame = ui.GetFrame("indunplus");
	local fontSize = g.settings.fontSize or 16

	local topMargin = 15;
	local bottomMargin = 15;
	local width = 0;
	local height = 0;
	local cnt = 0;
	local rowMax = g.settings.rowMax or 5;
	
	local row = 0;
	local col = 0;
	
	local pageX = 0;
	local pageY = 15;
	local pageWidth = 200;
	local pageHeight = fontSize * 7 + 10;

	for cid, record in pairs(records) do

		if cnt > 0 and cnt % rowMax == 0 then
			row = 0;
			height = 0;
			col = col + 1;
			pageX = pageWidth * col;
		end

		pageY = pageHeight * row + topMargin;
		local page = frame:CreateOrGetControl("groupbox", "page_"..cid, pageX , pageY, pageWidth, pageHeight);
		page:SetSkinName('None');

		local y = 5;
		g.createCharaNameText(page, cid, record, fontSize, 12, y, pageWidth, 20);

		if nil ~= record.fbDebuffTime and  record.fbDebuffTime > os.time() then
			y = y + fontSize;
			g.createFBTimeText(page, cid, record, fontSize, 20, y, pageWidth, 20)
		end

		for type, counts in pairs(record.counts) do
			y = y + fontSize;

			local label = g.types[type].label;

			local color = "FFFFFF";
			if counts.playCount >= counts.maxPlayCount then
				color = "00FF00";
			elseif counts.playCount > 0 then
				color = "FFFF00";
			end

			local labelText = page:CreateOrGetControl("richtext", "label"..cid.."_"..type, 20, y, pageWidth/2, 15);
			tolua.cast(labelText, "ui::CRichText");
			labelText:SetText( string.format("{#%s}{s%d}%s{/}{/}", color, fontSize ,label));
			labelText:ShowWindow(1);

			local countText = page:CreateOrGetControl("richtext", "count"..cid.."_"..type, 0, y, pageWidth/2, 15);
			tolua.cast(countText, "ui::CRichText");
			countText:SetText( string.format("{#%s}{s%d}%d/%d{/}{/}", color, fontSize, counts.playCount, counts.maxPlayCount));
			countText:SetGravity(1,0);
			countText:ShowWindow(1);
		end

		page:Resize(pageWidth, pageHeight);

		if cnt < rowMax then
			height = pageHeight * (row + 1) + bottomMargin + topMargin;
		else
			height = pageHeight * rowMax + bottomMargin + topMargin;
		end

		cnt = cnt + 1;
		row = row + 1;
	end
	frame:Resize(pageWidth * (col + 1) + 10, height);

end

function INDUNPLUS_ON_INIT(addon, frame)
	local g = _G['ADDONS']['MONOGUSA']['INDUNPLUS'];
	local acutil = require('acutil');

	g.addon = addon;
	g.frame = frame;
	frame:ShowWindow(0);
	frame:SetEventScript(ui.LBUTTONDOWN, "INDUNPLUS_START_DRAG");
	frame:SetEventScript(ui.LBUTTONUP, "INDUNPLUS_END_DRAG");
	g.addon:RegisterMsg("GAME_START_3SEC", "INDUNPLUS_3SEC");
	g.addon:RegisterMsg('BUFF_ADD', 'INDUNPLUS_UPDATE_BUFF');
	g.addon:RegisterMsg('BUFF_REMOVE', 'INDUNPLUS_UPDATE_BUFF');

end


function INDUNPLUS_UPDATE_BUFF(frame, msg, argStr, argNum)
	local g = _G['ADDONS']['MONOGUSA']['INDUNPLUS'];

	if argNum == g.bossDebuffId then
		if msg == "BUFF_ADD" then
			INDUNPLUS_CHECK_BUFF();
			INDUNPLUS_SHOW_PLAYCOUNT();
		elseif msg == "BUFF_REMOVE" then
			INDUNPLUS_SAVE_FBBOSSDEBUFF(0);
			INDUNPLUS_SHOW_PLAYCOUNT();
		end
	end
end

function INDUNPLUS_SAVE_FBBOSSDEBUFF(fbTime)
	local g = _G['ADDONS']['MONOGUSA']['INDUNPLUS'];
	local acutil = require('acutil');

	local mySession = session.GetMySession();
	local cid = mySession:GetCID();

	g.settings.records[cid]["fbDebuffTime"] = fbTime;
	acutil.saveJSON(g.settingsFileLoc, g.settings);
end

function INDUNPLUS_CHECK_BUFF()
	local g = _G['ADDONS']['MONOGUSA']['INDUNPLUS'];
	local acutil = require('acutil');

	local fbDebuff = false;
	local fbTime = 0;

	local handle = session.GetMyHandle();
	local buffCount = info.GetBuffCount(handle);
	
	for i = 0, buffCount - 1 do
		local buff = info.GetBuffIndexed(handle, i);
		local class = GetClassByType('Buff', buff.buffID);
		--CHAT_SYSTEM(class.ClassName.."="..buff.buffID.." time:"..buff.time.."ms");
		
		if buff.buffID == g.bossDebuffId then
			fbDebuff = true;
			fbTime = os.time() + math.floor(buff.time / 1000);
			local fbDate = os.date("*t", fbTime);
		end
	end
	
	INDUNPLUS_SAVE_FBBOSSDEBUFF(fbTime);
end

function INDUNPLUS_START_DRAG(addon, frame)
	local g = _G['ADDONS']['MONOGUSA']['INDUNPLUS'];
	g.isDragging = true;
end

function INDUNPLUS_END_DRAG(addon, frame)
	local g = _G['ADDONS']['MONOGUSA']['INDUNPLUS'];
	g.isDragging = false;

	local frame = ui.GetFrame("indunplus");
	g.settings.xPosition = frame:GetX();
	g.settings.yPosition = frame:GetY();
	acutil.saveJSON(g.settingsFileLoc, g.settings);
end


function INDUNPLUS_3SEC()
	local g = _G['ADDONS']['MONOGUSA']['INDUNPLUS'];
	local acutil = require('acutil');

	acutil.slashCommand("/idp", g.processCommand);

	if not g.loaded then
		local t, err = acutil.loadJSON(g.settingsFileLoc, g.settings);
		if err then
			CHAT_SYSTEM('no save file');
		else
			CHAT_SYSTEM('indunplus savedata is loaded');
			g.settings = t;
		end
		g.loaded = true;
	end

	local frame = ui.GetFrame("indunplus");

	INDUNPLUS_SAVE_TIME();
	INDUNPLUS_SHOW_PLAYCOUNT();

	if frame ~= nil and not g.isDragging then
		if g.settings.show then
			frame:ShowWindow(1);
		else
			frame:ShowWindow(0);
		end
		frame:Move(0, 0);
		frame:SetOffset(g.settings.xPosition, g.settings.yPosition);
	end
end

function INDUNPLUS_SAVE_TIME()
	local g = _G['ADDONS']['MONOGUSA']['INDUNPLUS'];
	local acutil = require('acutil');
	
	INDUNPLUS_REFLESH_COUNTS();

	local mySession = session.GetMySession();
	local cid = mySession:GetCID();
	local charName = info.GetName(session.GetMyHandle());
	local time = os.time();

	g.settings.records[cid] = {
		["name"] = charName,
		["time"] = time,
		["counts"] = {},
	};
	
	INDUNPLUS_CHECK_BUFF();

	local counts = g.settings.records[cid]["counts"];

	for type, mission in pairs(g.types) do
		local playCount = g.getPlayCount(type);
		local maxPlayCount =  g.getMaxPlayCount(mission.id);

		counts[type] = {
			["playCount"] = playCount,
			["maxPlayCount"] = maxPlayCount,
		};
	end

	acutil.saveJSON(g.settingsFileLoc, g.settings);
end

function INDUNPLUS_REFLESH_COUNTS()
	local g = _G['ADDONS']['MONOGUSA']['INDUNPLUS'];
	local acutil = require('acutil');
	local resetTime = g.getResetTime();
	local records = g.settings.records;
	
	for cid, record in pairs(records) do
		if record.time < resetTime then

			local counts = record.counts;

			for type, mission in pairs(g.types) do
				local playCount = 0;
				local maxPlayCount =  g.getMaxPlayCount(mission.id);
	
				counts[type]["playCount"] = playCount;
				counts[type]["maxPlayCount"] = maxPlayCount;
			end
		end
	end
end