﻿local SLE, T, E, L, V, P, G = unpack(select(2, ...))
local C = SLE:GetModule("Chat")
local CH = E:GetModule('Chat')
local _G = _G
--GLOBALS: hooksecurefunc

local FCFDockScrollFrame_JumpToTab = FCFDockScrollFrame_JumpToTab
local FCF_GetCurrentChatFrameID = FCF_GetCurrentChatFrameID
local FCFDock_GetSelectedWindow = FCFDock_GetSelectedWindow
local FCFTab_UpdateAlpha = FCFTab_UpdateAlpha
local FCFTab_UpdateColors = FCFTab_UpdateColors
local FCFDock_ScrollToSelectedTab = FCFDock_ScrollToSelectedTab
local PanelTemplates_TabResize = PanelTemplates_TabResize

--Styles for selected indicator
C.SelectedStrings = {
	["DEFAULT"] = "|cff%02x%02x%02x>|r %s |cff%02x%02x%02x<|r",
	["SQUARE"] = "|cff%02x%02x%02x[|r %s |cff%02x%02x%02x]|r",
	["HALFDEFAULT"] = "|cff%02x%02x%02x>|r %s",
	["CHECKBOX"] = [[|TInterface\ACHIEVEMENTFRAME\UI-Achievement-Criteria-Check:%s|t%s]],
	["ARROWRIGHT"] = [[|TInterface\BUTTONS\UI-SpellbookIcon-NextPage-Up:%s|t%s]],
	["ARROWDOWN"] = [[|TInterface\BUTTONS\UI-MicroStream-Green:%s|t%s]],
}

--Apply selected indicator to tab
function C:ApplySelectedTabIndicator(tab, title)
	local color = E.db.sle.chat.tab.color
	if E.db.sle.chat.tab.style == "DEFAULT" or E.db.sle.chat.tab.style == "SQUARE" then
		tab.Text:SetText(T.format(C.SelectedStrings[E.db.sle.chat.tab.style], color.r * 255, color.g * 255, color.b * 255, title, color.r * 255, color.g * 255, color.b * 255))
	elseif E.db.sle.chat.tab.style == "HALFDEFAULT" then
		tab.Text:SetText(T.format(C.SelectedStrings[E.db.sle.chat.tab.style], color.r * 255, color.g * 255, color.b * 255, title))
	else
		tab.Text:SetText(T.format(C.SelectedStrings[E.db.sle.chat.tab.style], (E.db.chat.tabFontSize + 12), title))
	end
end

--Analog for blizz dynamic chat framers calculation, used only here. Based on original blizz function with altered numbers and shit
local function SLE_FCFDock_CalculateTabSize(dock, numDynFrames, sleWidth, sleTotalCustomWidth)
	local MIN_SIZE, MAX_SIZE = 60, 100;
	local scrollSize = dock.scrollFrame:GetWidth() + (dock.overflowButton:IsShown() and dock.overflowButton.width or 0); --We want the total width assuming no overflow button.

	--First, see if we can fit all the tabs at the maximum size
	if ( numDynFrames * MAX_SIZE < scrollSize ) then
		return MAX_SIZE, false;
	end

	if (sleTotalCustomWidth > scrollSize) or ( scrollSize / MIN_SIZE < numDynFrames ) then
		--Not everything fits, so we'll need room for the overflow button.
		scrollSize = scrollSize - dock.overflowButton.width;
	end

	--Figure out how many tabs we're going to be able to fit at the minimum size
	local numWholeTabs = min(floor(scrollSize / sleWidth), numDynFrames)
	
	if ( scrollSize == 0 ) then
		return 1, (numDynFrames > 0);
	end
	if ( numWholeTabs == 0 ) then
		return scrollSize, true;
	end

	--How big each tab should be.
	local tabSize = E.db.sle.chat.tab.resize ~= "Blizzard" and sleWidth or (scrollSize / numWholeTabs);

	return tabSize, (numDynFrames > numWholeTabs);
end

--Full update tabs function. Hooking to it allows to set size and selection at the same time.
--Most of the content is default blizz function with sligh modifications
function C:FCFDock_UpdateTabs(dock, forceUpdate)
	if ( not dock.isDirty and not forceUpdate ) then --No changes have been made since the last update.
		return;
	end

	local scrollChild = dock.scrollFrame:GetScrollChild();
	local lastDockedStaticTab = nil;
	local lastDockedDynamicTab = nil;

	local numDynFrames = 0;	--Number of dynamicly sized frames.
	local selectedDynIndex = nil;

	local sleTotalCustomWidth = 0 --This variable is used to see if overflow button should be shown when using non-blizz width
	local sleWidth --Determain width for non blizzard resize. Needed cause I fucked up in the past allowing it for non-scroll tabs only

	for index, chatFrame in T.ipairs(dock.DOCKED_CHAT_FRAMES) do
		local chatTab = _G[chatFrame:GetName().."Tab"];
		if chatTab.Text then chatTab.Text:SetText(chatFrame.name) end --Reseting tab name
		if ( chatFrame == FCFDock_GetSelectedWindow(dock) ) and E.db.sle.chat.tab.select then --Tab is selected and option is enabled
			C:ApplySelectedTabIndicator(chatTab, chatFrame.name)
		end

		--Resizing tabs, don't need to do that if blizz sizing is selected
		if E.db.sle.chat.tab.resize ~= "Blizzard" then
			--Setting the width now
			sleWidth = (E.db.sle.chat.tab.resize == "None" and chatTab.origWidth) or (E.db.sle.chat.tab.resize == "Title" and (chatTab.textWidth)) or (E.db.sle.chat.tab.resize == "Custom" and E.db.sle.chat.tab.customWidth)
			if sleWidth < 45 then sleWidth = 45 end --We have a min of 45. If somehow this happens to be lower., stuff looks ugly.
			
			if ( chatFrame.isStaticDocked ) then
				chatTab:SetParent(dock);
				PanelTemplates_TabResize(chatTab, chatTab.isTemporary and 20 or 10, nil, nil, nil, sleWidth);
				if ( lastDockedStaticTab ) then
					chatTab:SetPoint("LEFT", lastDockedStaticTab, "RIGHT", 0, 0);
				else
					chatTab:SetPoint("LEFT", dock, "LEFT", 0, 0);
				end
				lastDockedStaticTab = chatTab;
			else
				chatTab:SetParent(scrollChild);
				numDynFrames = numDynFrames + 1;

				if ( FCFDock_GetSelectedWindow(dock) == chatFrame ) then
					selectedDynIndex = numDynFrames;
				end

				if ( lastDockedDynamicTab ) then
					chatTab:SetPoint("LEFT", lastDockedDynamicTab, "RIGHT", 0, 0);
				else
					chatTab:SetPoint("LEFT", scrollChild, "LEFT", 0, 0);
				end
				lastDockedDynamicTab = chatTab;
				sleTotalCustomWidth = sleTotalCustomWidth + sleWidth
			end
		end
	end

	--If blizz sizing is selected then messing around with scroll frame is unnessesary
	if E.db.sle.chat.tab.resize == "Blizzard" then return end
	local dynTabSize, hasOverflow = SLE_FCFDock_CalculateTabSize(dock, numDynFrames, sleWidth, sleTotalCustomWidth) --Call for own dynamic size calc, cause blizz one fuck up custom sized due to not even knowing we do custom shit

	--Dynamically resize tabs
	for index, chatFrame in T.ipairs(dock.DOCKED_CHAT_FRAMES) do
		if ( not chatFrame.isStaticDocked ) then
			local chatTab = _G[chatFrame:GetName().."Tab"];
			PanelTemplates_TabResize(chatTab, chatTab.sizePadding or 0, dynTabSize);
		end
	end

	dock.scrollFrame:SetPoint("LEFT", lastDockedStaticTab, "RIGHT", 0, 0);
	if ( hasOverflow or origOverflow ) then
		dock.overflowButton:Show();
		dock.scrollFrame:SetPoint("BOTTOMRIGHT", dock.overflowButton, "BOTTOMLEFT", 0, 0);
	else
		dock.overflowButton:Hide();
		dock.scrollFrame:SetPoint("BOTTOMRIGHT", dock, "BOTTOMRIGHT", 0, -5);
	end

	--Cache some of this data on the scroll frame for animating to the selected tab.
	dock.scrollFrame.dynTabSize = dynTabSize;
	dock.scrollFrame.numDynFrames = numDynFrames;
	dock.scrollFrame.selectedDynIndex = selectedDynIndex;

	dock.isDirty = false;

	--This may be needed to return for check in FCFDock_OnUpdate
	return FCFDock_ScrollToSelectedTab(dock)
end

function C:InitTabs()
	if E.db.sle.chat.tab.resize == true then E.db.sle.chat.tab.resize = "None" end

	--Getting initial chat tabs width, so other stuff will work
	if C.CreatedFrames == 0 then
		--Not all tabs have been styled yet
		E:Delay(0.2, C.InitTabs)
		return
	else
		for id = 1, C.CreatedFrames do _G["ChatFrame"..id.."Tab"].origWidth = _G["ChatFrame"..id.."Tab"]:GetWidth() end
	end

	--Hooking to chat updating function
	hooksecurefunc("FCFDock_UpdateTabs", function(dock, forceUpdate) C:FCFDock_UpdateTabs(dock, forceUpdate) end)
	--Without this hooked previous hook will never execute automatically apart from specific situations
	hooksecurefunc("FCFDock_SelectWindow", function(dock, chatFrame) FCFDock_UpdateTabs(dock, true) end)

	--Calling in update after hooks. Why 2 times? No idea, doesn't work otherwise
	FCF_DockUpdate()
	FCF_DockUpdate()
end