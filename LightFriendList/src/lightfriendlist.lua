local addonName = "LIGHTFRIENDLIST";
local addonNameLower = string.lower(addonName);

_G['ADDONS'] = _G['ADDONS'] or {};
_G['ADDONS']['MONOGUSA'] = _G['ADDONS']['MONOGUSA'] or {};
_G['ADDONS']['MONOGUSA'][addonName] = _G['ADDONS']['MONOGUSA'][addonName] or {};

local g = _G['ADDONS']['MONOGUSA'][addonName];
local acutil = require('acutil');

CHAT_SYSTEM('LIGHTFRIENDLIST is enable');

function LIGHTFRIENDLIST_ON_INIT(addon, frame)
  acutil.setupHook(UPDATE_FRIEND_LIST_HOOKED, "UPDATE_FRIEND_LIST");
  acutil.setupHook(BUILD_FRIEND_LIST_HOOKED, "BUILD_FRIEND_LIST");
end

function UPDATE_FRIEND_LIST_HOOKED(frame)
  local cpuTime = os.clock();
  local showOnlyOnline = config.GetXMLConfig("Friend_ShowOnlyOnline")

  local normaltree = GET_CHILD_RECURSIVELY(frame, 'friendtree_normal','ui::CTreeControl')
  local requesttree = GET_CHILD_RECURSIVELY(frame, 'friendtree_request','ui::CTreeControl')

  normaltree:Clear();
  requesttree:Clear();

  BUILD_FRIEND_LIST(frame, FRIEND_LIST_COMPLETE, FRIEND_GET_GROUPNAME(FRIEND_LIST_COMPLETE));
  BUILD_FRIEND_LIST(frame, FRIEND_LIST_REQUESTED, FRIEND_GET_GROUPNAME(FRIEND_LIST_REQUESTED));
  BUILD_FRIEND_LIST(frame, FRIEND_LIST_REQUEST, FRIEND_GET_GROUPNAME(FRIEND_LIST_REQUEST));
  BUILD_FRIEND_LIST(frame, FRIEND_LIST_REJECTED, FRIEND_GET_GROUPNAME(FRIEND_LIST_REJECTED));
  BUILD_FRIEND_LIST(frame, FRIEND_LIST_BLOCKED, FRIEND_GET_GROUPNAME(FRIEND_LIST_BLOCKED));

end

function BUILD_FRIEND_LIST_HOOKED(frame, listType, groupName, iscustom)
  local showOnlyOnline = config.GetXMLConfig("Friend_ShowOnlyOnline")

  local treename = 'friendtree_normal'
  local treegboxname = 'friendtree_normal_gbox'

  if listType ~= FRIEND_LIST_COMPLETE then
    treename = 'friendtree_request'
    treegboxname = 'friendtree_request_gbox'
  end

  local tree = GET_CHILD_RECURSIVELY(frame, treename,'ui::CTreeControl')
  local treegbox = GET_CHILD_RECURSIVELY(frame, treegboxname,'ui::CTreeControl')

  local slotWidth = ui.GetControlSetAttribute(GET_FRIEND_CTRLSET_NAME(listType), 'width');
  local slotHeight = ui.GetControlSetAttribute(GET_FRIEND_CTRLSET_NAME(listType), 'height');

  local friendListGroup = tree:FindByValue(groupName);
  if tree:IsExist(friendListGroup) == 0 then
    if iscustom == "custom" and listType == FRIEND_LIST_COMPLETE then
      local grouptext = tree:CreateOrGetControl('richtext',groupName,0,0,200,30) 
      friendListGroup = tree:Add(groupName, groupName);
    else
      friendListGroup = tree:Add(ScpArgMsg(groupName), groupName);
    end
    tree:SetNodeFont(friendListGroup,"brown_16_b")
  end

  local pageCtrlName = "PAGE_" .. groupName;

  local page = tree:GetChild(pageCtrlName);

  if page == nil then
    page = tree:CreateOrGetControl('page', pageCtrlName, 0, 1000, treegbox:GetWidth()-35, 0);

    tolua.cast(page, 'ui::CPage')
    page:SetSkinName('None');

    if listType == FRIEND_LIST_COMPLETE then
      slotHeight = FRIEND_MINIMIZE_HEIGHT
    end

    page:SetSlotSize(slotWidth, slotHeight);
    page:SetFocusedRowHeight(-1, slotHeight);
    page:SetFitToChild(true, 10);
    page:SetSlotSpace(0, 0)
    page:SetBorder(5, 0, 0, 0)

    tree:Add(friendListGroup, page);	
  end

  if listType == FRIEND_LIST_COMPLETE then
    FRIEND_MINIMIZE_FOCUS(page);
  end
  tolua.cast(page, 'ui::CPage')
  page:RemoveAllChild();
  page:SetFocusedRow(-1);

  local cnt = session.friends.GetFriendCount(listType);
  for i = 0 , cnt - 1 do

    local f = session.friends.GetFriendByIndex(listType, i);		
    if showOnlyOnline == 0 or (showOnlyOnline == 1 and f.mapID ~= 0)
    or  (showOnlyOnline == 1 and FRIEND_LIST_COMPLETE ~= listType) then

      local ctrlSet = page:CreateOrGetControlSet(GET_FRIEND_CTRLSET_NAME(listType), "FR_" .. listType .. "_" .. f:GetInfo():GetACCID(), 0, 0);
      if listType == FRIEND_LIST_COMPLETE then
        ctrlSet:Resize(ctrlSet:GetOriginalWidth(),FRIEND_MINIMIZE_HEIGHT)
      end
      UPDATE_FRIEND_CONTROLSET(ctrlSet, listType, f);
    end
  end
  tree:OpenNodeAll();

end
