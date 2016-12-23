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
  g.removingItem = nil;
  g.records = {};
  g.color = {
    normal = "FFFFFFFF",
    nearComplete = "FF00FFFF",
    complete = "FF00FF00",
  };

  g.settings = {
    version = 1.2;
    --表示非表示
    show = true;
    --X座標、Y座標
    xPosition = 500,
    yPosition = 500,
    --リセット時刻
    resetHour = 6,
    --1列に表示するキャラ数
    rowMax = 5,
  };

  g.bossDebuffId = 80001;
end


function INDUNPLUS_RELOAD()
  local t, err = acutil.loadJSON(g.settingsFileLoc, g.settings);
  if err then
    CHAT_SYSTEM('no save file');
  else
    CHAT_SYSTEM('indunplus savedata is loaded');
    g.settings = t;
  end

  INDUNPLUS_SHOW_PLAYCOUNT();
end


function INDUNPLUS_GET_MYSERIOUS_BOXS()
  return {
    --{ id=641233, chance=false, unstable=true},
    { id=642809, chance=false, unstable=false},
    { id=642811, chance=true, unstable=false},
    { id=642810, chance=false, unstable=true},
    { id=642812, chance=true, unstable=true},
  }
end

function INDUNPLUS_GET_BOX_BYID(id)
  local boxs = INDUNPLUS_GET_MYSERIOUS_BOXS();

  for i, box in ipairs(boxs) do
    if box.id == id then
      local itemCls = GetClassByType("Item", box.id);
      return box, itemCls;
    end
  end

  return nil, nil;
end


function INDUNPLUS_IS_BOX_EXIST()
  local boxs = INDUNPLUS_GET_MYSERIOUS_BOXS();

  for i, box in ipairs(boxs) do
    local invItem= session.GetInvItemByType(box.id);

    if invItem ~= nil then
      if invItem.count > 0 and g.removingItem ~= box.id then
        local itemCls = GetClassByType("Item", box.id);
        return box, itemCls;
      end
    end
  end

  return nil, nil;
end

function INDUNPLUS_GET_BOXCD(box)
  local result = 0;

  if box == nil then
    return 0;
  end

  local invItem= session.GetInvItemByType(box.id);

  if box.unstable then
  else
    --神秘的なキューブ
    local cdtime = item.GetCoolDown(box.id);

    if cdtime > 0 then
      result = os.time() + math.floor(cdtime / 1000);
    end
  end

  return result;
end

function INDUNPLUS_CHECK_BOX()
  local box = INDUNPLUS_IS_BOX_EXIST();
  local time = INDUNPLUS_GET_BOXCD(box);

  INDUNPLUS_SAVE_BOXTIME(box, time);
end

function INDUNPLUS_SAVE_BOXTIME(box, time)
  local mySession = session.GetMySession();
  local cid = mySession:GetCID();
  local boxId = nil;

  if box ~=nil then
    boxId = box.id;
  end

  g.records[cid]["boxId"] = boxId;
  g.records[cid]["boxTime"] = time;

  local fileName = string.format("../addons/indunplus/%s.json", cid);
  acutil.saveJSON(fileName, g.records[cid]);
end

function INDUNPLUS_GET_INDUNS()
  local clslist, cnt = GetClassList("Indun");
  local temp = {};
  local result = {};

  local categoryCount = 1;
  for i = 0 , cnt - 1 do
    local cls = GetClassByIndexFromList(clslist, i);
    local idx = temp[tostring(cls.PlayPerResetType)];

    if idx == nil and cls.Category ~= 'None' then
      table.insert(result,
        categoryCount,
        {
          ["type"] = tostring(cls.PlayPerResetType),
          ["label"] = cls.Category,
          ["id"] = cls.ClassID,
          ["level"] = cls.Level
        });
      temp[tostring(cls.PlayPerResetType)] = categoryCount;
      categoryCount = categoryCount + 1;
    elseif cls.Category ~= 'None' and result[idx]["level"] > cls.Level then
      result[idx]["level"] = cls.Level;
    end
  end

  return result;
end

function INDUNPLUS_GET_PLAY_COUNT(indun)
  local etcObj = GetMyEtcObject();
  local etcType = "InDunCountType_"..indun.type;
  local count = etcObj[etcType];

  return count;
end

function INDUNPLUS_GET_MAX_PLAY_COUNT(indun)
  local cls = GetClassByType("Indun", indun.id);
  local maxPlayCnt = cls.PlayPerReset;
  if true == session.loginInfo.IsPremiumState(ITEM_TOKEN) then 
    maxPlayCnt = maxPlayCnt + cls.PlayPerReset_Token;
  end

  return maxPlayCnt;
end

function INDUNPLUS_GET_RESETTIME()
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

function INDUNPLUS_CREATE_CHARALABEL(parent, cid, record, fontSize, x, y, width, height)
  local charaText = parent:CreateOrGetControl("richtext", "record"..cid, x, y, width, height)
  tolua.cast(charaText, "ui::CRichText");
  local text = "";

  local color = "FFFFFF"
  if cid == session.GetMySession():GetCID() then
    color = "FFFF00";
  end

  if record.level == nil then
    text = string.format("{@st48}{#%s}{s%d}%s{/}{/}{/}", color, fontSize, record.name);
  else
    text = string.format("{@st48}{#%s}{s%d}Lv%d %s{/}{/}{/}", color, fontSize, record.level, record.name);
  end

  charaText:SetText(text);

  if record.money ~= nil then
    local silverText = parent:CreateOrGetControl("richtext", "silver_"..cid, x, y, width, height)
    tolua.cast(silverText, "ui::CRichText");
    silverText:SetText("{@st48}{#AAAAAA}"..GetCommaedText(record.money).."s{/}{/}");
    silverText:SetGravity(ui.RIGHT, ui.TOP);
  end

end

function INDUNPLUS_CREATE_FBTIME(parent, cid, record, fontSize, x, y, width, height)
  local fbLabelText = parent:CreateOrGetControl("richtext", "fbLabel"..cid, x, y, width, height)
  local fbText = parent:CreateOrGetControl("richtext", "fbDebuff"..cid, x, y, width, height)

  local color = "FFFFFF";
  if nil ~= record.fbDebuffTime or record.fbDebuffTime <= os.time() then
    fbLabelText:ShowWindow(0);
    fbText:ShowWindow(0);
    return false;
  elseif record.fbDebuffTime - 600 < os.time()  then
    color = "00FF00";
  elseif record.fbDebuffTime - 3600 < os.time() then
    color = "FFFF00";
  end

  fbLabelText:ShowWindow(1);
  fbText:ShowWindow(1);

  local text = string.format("{@st48}{#%s}{s%d}%s{/}{/}{/}", color, fontSize, "BossDebuff");
  tolua.cast(fbLabelText, "ui::CRichText");
  fbLabelText:SetText(text);

  local fbDate = os.date("*t", record.fbDebuffTime);
  tolua.cast(fbText, "ui::CRichText");
  fbText:SetText(string.format("{@st48}{#%s}{s%d}%02d:%02d:%02d{/}{/}{/}",color, fontSize, fbDate.hour, fbDate.min, fbDate.sec));
  fbText:SetGravity(ui.RIGHT, ui.TOP);

  return true;
end


function INDUNPLUS_CREATE_BOXTIME(parent, cid, record, fontSize, x, y, width, height)
  local box, boxCls = nil, nil;

  if cid == session.GetMySession():GetCID() then
    box, boxCls = INDUNPLUS_IS_BOX_EXIST();
  else
    box, boxCls = INDUNPLUS_GET_BOX_BYID(record.boxId);
  end

  local boxLabel = parent:CreateOrGetControl("richtext", "boxLabel"..cid, x, y, width, height);
  local boxTime = parent:CreateOrGetControl("richtext", "boxTime"..cid, x, y, width, height)
  tolua.cast(boxLabel, "ui::CRichText");
  tolua.cast(boxTime, "ui::CRichText");

  if box == nil then
    boxLabel:ShowWindow(0);
    boxTime:ShowWindow(0);
    return false;
  else
    boxLabel:ShowWindow(1);
    boxTime:ShowWindow(1);
  end

  boxTime:SetGravity(ui.RIGHT, ui.TOP);

  if box.unstable then
    local color = "FF00FF";
    local text = string.format("{@st48}{#%s}{s%d}%s{/}{/}{/}", color, fontSize, boxCls.Name);
    boxLabel:SetText(text);
  else
    local color = "FFFFFF"

    if record.boxTime < os.time()  then
      color = "FFFF00";
    end

    local text = string.format("{@st48}{#%s}{s%d}%s{/}{/}{/}", color, fontSize, boxCls.Name);
    boxLabel:SetText(text);

    if record.boxTime == 0 or record.boxTime < os.time() then
      boxTime:SetText(string.format("{@st48}{#%s}{s%d}{/}Ready{/}{/}",color, fontSize));
    else
      local date = os.date("*t", record.boxTime);
      boxTime:SetText(string.format("{@st48}{#%s}{s%d}%02d/%02d %02d:%02d{/}{/}{/}",color, fontSize, date.month, date.day, date.hour, date.min));
    end

  end
  return true;
end

function INDUNPLUS_LOAD()
  --総合設定の読み取り
  if not g.loaded then
    local t, err = acutil.loadJSON(g.settingsFileLoc);
    if err then
      CHAT_SYSTEM('no save file');
    else
      if t.version ~= nil and t.version < 1.2 then
        CHAT_SYSTEM('[indunplus] savedata is loaded');
        g.settings = t;
      else
        CHAT_SYSTEM('[indunplus] delete old version save data');
        acutil.saveJSON(g.settingsFileLoc, g.settings);
      end
    end
    g.loaded = true;
  end

  --キャラごとのデータを読み込み
  local accountInfo = session.barrack.GetMyAccount();
  local cnt = accountInfo:GetPCCount();
  for i = 0 , cnt - 1 do
    local pcInfo = accountInfo:GetPCByIndex(i);
    local cid = tostring(pcInfo:GetCID());
    local fileName = string.format("../addons/indunplus/%s.json", cid);
    local t, err = acutil.loadJSON(fileName);
    if not err then
      g.records[cid] = t;
    end
  end
end


function INDUNPLUS_CREATE_INDUNLINE(parent, cid, record, indun, fontSize, x, y, width, height)

  local counts = record.counts[indun.type];

  if counts == nil then
    counts = {
      playCount = 0,
      maxPlayCount = INDUNPLUS_GET_MAX_PLAY_COUNT(indun),
    };
  end

  local label = indun.label;
  local type = indun.type;
  local color = "FFFFFF";

  if record.level ~= nil and indun.level > record.level then
    color = "444444";
  elseif counts.playCount >= counts.maxPlayCount then
    color = "00FF00";
  elseif counts.playCount > 0 then
    color = "FFFF00";
  end

  local labelText = parent:CreateOrGetControl("richtext", "label"..cid.."_"..type, 20, y, width / 2, 15);
  tolua.cast(labelText, "ui::CRichText");
  labelText:SetText(string.format("{@st48}{#%s}{s%d}%s{/}{/}{/}", color, fontSize ,label));

  local countText = parent:CreateOrGetControl("richtext", "count"..cid.."_"..type, 0, y, width / 2, 15);
  tolua.cast(countText, "ui::CRichText");
  countText:SetText(string.format("{@st48}{#%s}{s%d}%d/%d{/}{/}{/}", color, fontSize, counts.playCount, counts.maxPlayCount));
  countText:SetGravity(ui.RIGHT, ui.TOP);
end

function INDUNPLUS_TOGGLE_FRAME()
  if g.frame:IsVisible() == 0 then
    g.frame:ShowWindow(1);
    g.settings.show = true;
  else
    g.frame:ShowWindow(0);
    g.settings.show = false;
  end

  acutil.saveJSON(g.settingsFileLoc, g.settings);
end

function INDUNPLUS_SHOW_PLAYCOUNT()
  local records = g.records;

  local frame = ui.GetFrame("indunplus");
  local fontSize = 16
  local lineHeight = fontSize + 6;
  local induns = INDUNPLUS_GET_INDUNS();
  local lineNum = #induns + 3;

  local topMargin,bottomMargin = 30, 20;
  local width, height = 0, 0;
  local cnt = 0;
  local rowMax = g.settings.rowMax or 5;

  local row = 0;
  local col = 0;

  local pageX = 0;
  local pageY = 15;
  local pageWidth = 250;
  local pageHeight = fontSize * lineNum + 15;

  local title = frame:CreateOrGetControl("richtext", "title", 10, 12, pageWidth, fontSize);
  local minButton = frame:CreateOrGetControl("button", "minimize", 0, 0, 25, 25);

  if g.settings.minimize then
    --最小化時
    minButton:Move(0, 0);
    minButton:SetOffset(180 -30, 5);
    frame:Resize(180, 35);
    frame:Move(0, 0);
    frame:SetOffset(g.settings.xPosition, g.settings.yPosition);
    return;
  end

  for cid, record in pairs(records) do
    local pcPCInfo = session.barrack.GetMyAccount():GetByStrCID(cid);
    if pcPCInfo ~= nil then
      if cnt > 0 and cnt % rowMax == 0 then
        row = 0;
        height = 0;
        col = col + 1;
        pageX = pageWidth * col;
      end

      pageY = pageHeight * row + topMargin;
      local page = frame:CreateOrGetControl("groupbox", "page_"..cid, pageX , pageY, pageWidth, pageHeight);
      page:SetSkinName('None');
      page:EnableHitTest(0);

      local job = page:CreateOrGetControl("picture", "job_"..cid, 100, lineHeight/2, 128, 128);
      tolua.cast(job, "ui::CPicture");
      job:SetGravity(ui.LEFT, ui.TOP);
      job:SetEnableStretch(1);
      job:SetColorTone("AAFFFFFF");
      if record.job ~= nil then
        job:SetImage(GET_JOB_ICON(record.job));
      end

      local y = 5;
      INDUNPLUS_CREATE_CHARALABEL(page, cid, record, fontSize, 12, y, pageWidth, lineHeight);
      y = y + 2;

      y = y + fontSize;
      if not INDUNPLUS_CREATE_FBTIME(page, cid, record, fontSize, 20, y, pageWidth, lineHeight) then
        y = y - fontSize;
      end

      y = y + fontSize;
      if not INDUNPLUS_CREATE_BOXTIME(page, cid, record, fontSize, 20, y, pageWidth, lineHeight) then
        y = y - fontSize;
      end

      for i, indun in ipairs(induns) do
        y = y + fontSize;
        INDUNPLUS_CREATE_INDUNLINE(page, cid, record, indun, fontSize, 20, y, pageWidth, lineHeight)
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
  end

  minButton:Move(0, 0);
  minButton:SetOffset(pageWidth * (col + 1) -30, 10);
  frame:Resize(pageWidth * (col + 1) + 10, height);
  frame:Move(0, 0);
  frame:SetOffset(g.settings.xPosition, g.settings.yPosition);
end

function INDUNPLUS_MINIMIZE_FRAME()
  local frame = g.frame;
  g.settings.xPosition = frame:GetX();
  g.settings.yPosition = frame:GetY();
  g.settings.minimize = not g.settings.minimize;

  acutil.saveJSON(g.settingsFileLoc, g.settings);
  INDUNPLUS_SHOW_PLAYCOUNT();
end

function INDUNPLUS_ON_INIT(addon, frame)
  g.addon = addon;
  g.frame = frame;
  frame:ShowWindow(0);
  frame:EnableHitTest(1);
  frame:SetEventScript(ui.RBUTTONDOWN, "INDUNPLUS_CONTEXT_MENU");

  frame:SetEventScript(ui.LBUTTONDOWN, "INDUNPLUS_START_DRAG");
  frame:SetEventScript(ui.LBUTTONUP, "INDUNPLUS_END_DRAG");

  addon:RegisterMsg('SHOT_START', 'INDUNPLUS_ON_ITEM_CHANGE_COUNT');
  addon:RegisterMsg('INV_ITEM_ADD', 'INDUNPLUS_ON_ITEM_CHANGE_COUNT');
  addon:RegisterMsg('INV_ITEM_REMOVE', 'INDUNPLUS_ON_ITEM_CHANGE_COUNT');
  addon:RegisterMsg('INV_ITEM_CHANGE_COUNT', 'INDUNPLUS_ON_ITEM_CHANGE_COUNT');

  addon:RegisterMsg("GAME_START_3SEC", "INDUNPLUS_3SEC");
  addon:RegisterMsg('BUFF_ADD', 'INDUNPLUS_UPDATE_BUFF');
  addon:RegisterMsg('BUFF_REMOVE', 'INDUNPLUS_UPDATE_BUFF');

  local title = frame:CreateOrGetControl("richtext", "title", 10, 12, 200, 16);
  title:EnableHitTest(0);
  tolua.cast(title, "ui::CRichText");
  title:SetText("{@st48}IndunPlus /idp{/}");

  local minButton = frame:CreateOrGetControl("button", "minimize", 0, 0, 25, 25);
  minButton:SetEventScript(ui.LBUTTONDOWN, "INDUNPLUS_MINIMIZE_FRAME");
  minButton:SetText("_");
end

function INDUNPLUS_CONTEXT_MENU(frame, msg, clickedGroupName, argNum)
  local context = ui.CreateContextMenu("INDUNPLUS_RBTN", "IndunPlus", 0, 0, 300, 100);
  ui.AddContextMenuItem(context, "Hide (/idp)", "INDUNPLUS_TOGGLE_FRAME()");
  ui.AddContextMenuItem(context, "Toggle Minimize", "INDUNPLUS_MINIMIZE_FRAME()");

  local subContextRowNum = ui.CreateContextMenu("SUBCONTEXT_ROWNUM", "", 0, 0, 0, 0);
  for i = 1, 5 do
    ui.AddContextMenuItem(subContextRowNum, ""..i , string.format("INDUNPLUS_CHANGE_ROWNUM(%d)", i));
  end

  ui.AddContextMenuItem(context, "Row Num {img white_right_arrow 18 18}", "", nil, 0, 1, subContextRowNum);

  context:Resize(300, context:GetHeight());
  ui.OpenContextMenu(context);
end

function INDUNPLUS_CHANGE_ROWNUM(num)
  g.settings.rowMax = num;
  acutil.saveJSON(g.settingsFileLoc, g.settings);
  INDUNPLUS_SHOW_PLAYCOUNT();
end

function INDUNPLUS_UPDATE_BUFF(frame, msg, argStr, argNum)
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
  local mySession = session.GetMySession();
  local cid = mySession:GetCID();

  g.records[cid]["fbDebuffTime"] = fbTime;
  local fileName = string.format("../addons/indunplus/%s.json", cid);
  acutil.saveJSON(fileName, g.records[cid]);
end

function INDUNPLUS_CHECK_BUFF()
  local fbDebuff = false;
  local fbTime = 0;

  local handle = session.GetMyHandle();
  local buffCount = info.GetBuffCount(handle);

  for i = 0, buffCount - 1 do
    local buff = info.GetBuffIndexed(handle, i);

    if buff.buffID == g.bossDebuffId then
      fbDebuff = true;
      fbTime = os.time() + math.floor(buff.time / 1000);
    end
  end

  INDUNPLUS_SAVE_FBBOSSDEBUFF(fbTime);
end

function INDUNPLUS_START_DRAG(addon, frame)
  g.isDragging = true;
end

function INDUNPLUS_END_DRAG(addon, frame)
  g.isDragging = false;
  g.settings.xPosition = g.frame:GetX();
  g.settings.yPosition = g.frame:GetY();
  acutil.saveJSON(g.settingsFileLoc, g.settings);
end


function INDUNPLUS_3SEC()
  acutil.slashCommand("/idp", INDUNPLUS_TOGGLE_FRAME);
  INDUNPLUS_LOAD();

  local frame = g.frame;

  INDUNPLUS_SAVE_TIME();
  INDUNPLUS_SHOW_PLAYCOUNT();

  if frame ~= nil then
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
  INDUNPLUS_REFLESH_COUNTS();

  local mySession = session.GetMySession();
  local cid = mySession:GetCID();
  local charName = info.GetName(session.GetMyHandle());
  local time = os.time();
  local level = info.GetLevel(session.GetMyHandle());
  local job = info.GetJob(session.GetMyHandle());

  g.records[cid] = {
    ["version"] = 1.2,
    ["level"] = level,
    ["name"] = charName,
    ["time"] = time,
    ["job"] = job,
    ["money"] = GET_TOTAL_MONEY();
    ["counts"] = {},
  };

  INDUNPLUS_CHECK_BOX();
  INDUNPLUS_CHECK_BUFF();

  local counts = g.records[cid]["counts"];

  local induns = INDUNPLUS_GET_INDUNS();

  for i, indun in ipairs(induns) do
    counts[indun.type] = {
      ["playCount"] = INDUNPLUS_GET_PLAY_COUNT(indun),
      ["maxPlayCount"] = INDUNPLUS_GET_MAX_PLAY_COUNT(indun),
    };
  end

  local fileName = string.format("../addons/indunplus/%s.json", cid);
  acutil.saveJSON(fileName, g.records[cid]);
end

function INDUNPLUS_REFLESH_COUNTS()
  local resetTime = INDUNPLUS_GET_RESETTIME();

  for cid, record in pairs(g.records) do
    if record.time < resetTime then

      local counts = record.counts;
      local induns = INDUNPLUS_GET_INDUNS();

      for i, indun in ipairs(induns) do
        counts[indun.type]["playCount"] = 0;
        counts[indun.type]["maxPlayCount"] = INDUNPLUS_GET_MAX_PLAY_COUNT(indun);
      end
    end
  end
end

function INDUNPLUS_ON_ITEM_CHANGE_COUNT(frame, msg, argStr, argNum)
  local invItem, itemCls = nil, nil;
  if msg == "INV_ITEM_ADD" then
    invItem = session.GetInvItem(argNum);
  else
    invItem = GET_PC_ITEM_BY_GUID(argStr);
  end

  itemCls = GetIES(invItem:GetObject());
  if msg == "INV_ITEM_REMOVE" then
    g.removingItem = itemCls.ClassID;
  end

  if MONEY_NAME == itemCls.ClassName then
    --金情報を更新
    local cid = session.GetMySession():GetCID();
    g.records[cid]["money"] = invItem.count;
    acutil.saveJSON(g.settingsFileLoc, g.settings);
    local silverText = GET_CHILD_RECURSIVELY(g.frame, "silver_"..cid, "ui::CRichText");
    silverText:SetText("{@st48}{#AAAAAA}"..GetCommaedText(invItem.count).."s{/}{/}");
    g.removingItem = nil;
    return;
  end

  local box, boxCls = INDUNPLUS_GET_BOX_BYID(itemCls.ClassID);

  if box ~= nil then
    --箱の表示更新
    INDUNPLUS_CHECK_BOX();
    INDUNPLUS_SHOW_PLAYCOUNT();
    g.removingItem = nil;
    return;
  end
  g.removingItem = nil;
end

