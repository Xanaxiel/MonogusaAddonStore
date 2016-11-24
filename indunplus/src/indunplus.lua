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
	g.settings = {
		show = false;
		xPosition = 500,
		yPosition = 500,
		resetHour = 6,
		records = {},
	};

	g.bossDebuffId = 80001;

	g.types = {
		["100"] = {
			id = "Indun_startower",
			label = "ID",
		},
		["200"] = {
			id = "Request_Mission1",
			label = "傭兵依頼",
		},
		["300"] = {
			id = "Request_Mission7",
			label = "サルラス",
		},
		["400"] = {
			id = "M_GTOWER_1",
			label = "大地",
		},
		["500"] = {
			id = "Request_Mission10",
			label = "防衛",
		},
	};

end

function g.processCommand(words)
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
	local height = -10;
	
	for cid, record in pairs(records) do
		local line = record.name.." ";

		height = height + 20;
		local charaText = frame:CreateOrGetControl("richtext", "record"..cid, 10, height, 200, 20);
		tolua.cast(charaText, "ui::CRichText");
		charaText:SetText("{s14}"..record.name);
		charaText:ShowWindow(1);
		
		if nil ~= record.fbDebuffTime then
			if record.fbDebuffTime > os.time() then
				height = height + 15;
				local fbLabelText = frame:CreateOrGetControl("richtext", "fbLabel"..cid, 20, height, 100, 15);
				tolua.cast(fbLabelText, "ui::CRichText");
				fbLabelText:SetText("{s14}".."FBデバフ");
				fbLabelText:ShowWindow(1);
			
				local fbText = frame:CreateOrGetControl("richtext", "fbDebuff"..cid, -20, height, 100, 15);
				local fbDate = os.date("*t", record.fbDebuffTime);
				tolua.cast(fbText, "ui::CRichText");
				fbText:SetText(string.format("{s14}".."%02d:%02d:%02d", fbDate.hour, fbDate.min, fbDate.sec));
				fbText:SetGravity(1,0);
				fbText:ShowWindow(1);
			end
		end

		for type, counts in pairs(record.counts) do
			height = height + 15;
			local label = g.types[type].label;
			
			local labelText = frame:CreateOrGetControl("richtext", "label"..cid.."_"..type, 20, height, 100, 15);
			tolua.cast(labelText, "ui::CRichText");
			labelText:SetText("{s14}"..label);
			labelText:ShowWindow(1);

			local countText = frame:CreateOrGetControl("richtext", "count"..cid.."_"..type, -20, height, 100, 15);
			tolua.cast(countText, "ui::CRichText");
			countText:SetText("{s14}"..counts.playCount.."/"..counts.maxPlayCount);
			countText:SetGravity(1,0);
			countText:ShowWindow(1);
		end
	end
	frame:Resize(frame:GetWidth(),height + 30);
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

	if frame ~= nil and not g.isDragging then
		if g.settings.show then
			frame:ShowWindow(1);
		else
			frame:ShowWindow(0);
		end
		frame:Move(0, 0);
		frame:SetOffset(g.settings.xPosition, g.settings.yPosition);
	end

	INDUNPLUS_SAVE_TIME();
	INDUNPLUS_SHOW_PLAYCOUNT();
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

	local frame = ui.GetFrame("indunplus");
	g.settings.xPosition = frame:GetX();
	g.settings.yPosition = frame:GetY();

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