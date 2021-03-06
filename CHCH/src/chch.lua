local addonName = "CHCH";

_G['ADDONS'] = _G['ADDONS'] or {};
_G['ADDONS']['MONOGUSA'] = _G['ADDONS']['MONOGUSA'] or {};
_G['ADDONS']['MONOGUSA'][addonName] = _G['ADDONS']['MONOGUSA'][addonName] or {};

local g = _G['ADDONS']['MONOGUSA'][addonName];

CHAT_SYSTEM("CHCH is loaded");

function g.getCurrentChannel()
    local channel = session.loginInfo.GetChannel();
    return channel;
end

function g.getNumberOfChannels()
    local mapName = session.GetMapName();
    local mapCls = GetClass("Map", mapName);
    local zoneInsts = session.serverState.GetMap(mapCls.ClassID);

	local cnt = zoneInsts:GetZoneInstCount();
	local numberOfChannels = -1;

	for i = 0  , cnt - 1 do
		local zoneInst = zoneInsts:GetZoneInstByIndex(i);

		if numberOfChannels < zoneInst.channel then
			numberOfChannels = zoneInst.channel;
		end
	end

	return numberOfChannels + 1;
end

function g.getNextChannel()
	local g = _G['ADDONS']['MONOGUSA']['CHCH'];

    local numberOfChannels = g.getNumberOfChannels();
    local currentChannel = g.getCurrentChannel();
    local nextChannel = (1 + currentChannel) % numberOfChannels;
    return nextChannel;
end

function g.getPrevChannel()
	local g = _G['ADDONS']['MONOGUSA']['CHCH'];

    local numberOfChannels = g.getNumberOfChannels();
    local currentChannel = g.getCurrentChannel();
    local prevChannel = (currentChannel - 1) % numberOfChannels;
    return prevChannel;
end

function CHCH_ON_INIT(addon, frame)
	local acutil = require("acutil");
    acutil.slashCommand("/chch", CHCH_COMMAND);
end

function CHCH_COMMAND(command)
    local cmd = "";

    if #command > 0 then
        cmd = table.remove(command, 1);
    else
		local msg = '';
		msg = msg.. '/chch [number]{nl}';
		msg = msg.. '数字で指定したチャンネルに移動する{nl}';
		msg = msg.. '-----------{nl}';
		msg = msg.. '/chch prev{nl}';
		msg = msg.. '前のチャンネルに移動する（2chなら1ch、1chなら5chなど）{nl}';
		msg = msg.. '-----------{nl}';
		msg = msg.. '/chch next{nl}';
		msg = msg.. '次のチャンネルに移動する（1chなら2ch、5chなら1chなど）{nl}';
		return ui.MsgBox(msg,"","Nope")
    end

    if cmd == "prev" then
        CHCH_CHANGE_PREV_CHANNEL();
        return;
    end

    if cmd == "next" then
        CHCH_CHANGE_NEXT_CHANNEL();
        return;
    end
    
    local channel = tonumber(cmd);
    if channel ~= nil then
        CHCH_CHANGE_CHANNEL(channel - 1);
        return;
    else
        CHAT_SYSTEM("[CHCH] Invalid Command");
    end
    
end

function CHCH_CHANGE_NEXT_CHANNEL()
	local g = _G['ADDONS']['MONOGUSA']['CHCH'];

    local next = g.getNextChannel();
    CHCH_CHANGE_CHANNEL(next);
end

function CHCH_CHANGE_PREV_CHANNEL()
	local g = _G['ADDONS']['MONOGUSA']['CHCH'];

    local prev = g.getPrevChannel();
    CHCH_CHANGE_CHANNEL(prev);
end

function CHCH_CHANGE_CHANNEL(channel)
	local g = _G['ADDONS']['MONOGUSA']['CHCH'];

    local mapName = session.GetMapName();
    local mapCls = GetClass("Map", mapName);
    local zoneInsts = session.serverState.GetMap(mapCls.ClassID);

    CHAT_SYSTEM("change to channel"..(channel+1));

    if zoneInsts.pcCount == -1 then
        CHAT_SYSTEM("[CHCH] Invalid Channel");
        return;
    end

    app.ChangeChannel(channel);
end

