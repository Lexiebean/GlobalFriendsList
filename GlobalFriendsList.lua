GlobalList = false
GlobalFriendsList_FriendsList_gl = {}
GlobalFriendsList_FriendsList_lc = {}
GlobalFriendsList_MarkDelete = {}
local gfind = string.gmatch or string.gfind

function tablefind(tab,el)
    for index, value in pairs(tab) do
        if value == el then
            return index
        end
    end
end

--Delay code from LFT
local GFLDelay = CreateFrame("Frame")
GFLDelay:Hide()

GFLDelay:SetScript("OnShow", function()
    this.startTime = GetTime()
end)

GFLDelay:SetScript("OnHide", function()
    FriendsList()
end)

GFLDelay:SetScript("OnUpdate", function()
    local plus = 30 --seconds
    local gt = GetTime() * 1000
    local st = (this.startTime + plus) * 1000
    if gt >= st then
        GFLDelay:Hide()
    end
end)

function FriendsList()
	local GlobalFriendsList_FriendsList = {}
	-- Get the local or global friendslist
	if (GlobalList == true) then
		GlobalFriendsList_FriendsList = GlobalFriendsList_FriendsList_gl
	else
		GlobalFriendsList_FriendsList = GlobalFriendsList_FriendsList_lc
	end
	
	-- Make a copy of the friends list
	local FriendsList = GlobalFriendsList_FriendsList
	
	local FriendsListCurrent = {}
	
    for i=1, GetNumFriends() do
		-- Remove any Unknowns
		name = GetFriendInfo(i)
		if (name == "Unknown") then
			RemoveFriend(i)
		-- Remove any friends that were deleted while playing another toon.
		elseif (tablefind(GlobalFriendsList_MarkDelete,name)) then
			DEFAULT_CHAT_FRAME:AddMessage("|cffbe5eff[GlobalFriendsList]|r Removing Friend "..name..". They were removed from your friends while playing another toon.")
			RemoveFriend(i)
		else
			-- Check the current list against the saved list
			-- Remove any current friends from the copied list. Only missing friends will remain.
			if (table.getn(GlobalFriendsList_FriendsList) ~= 0) then
				if tablefind(GlobalFriendsList_FriendsList,name) then
					table.remove(FriendsList,tablefind(GlobalFriendsList_FriendsList,name))
				end
			end
			-- Generate a list of current friends
			table.insert(FriendsListCurrent,name)
		end
    end
	
	-- Display missing friends
	if (table.getn(FriendsList) ~= 0) then
		DEFAULT_CHAT_FRAME:AddMessage("|cffbe5eff[GlobalFriendsList]|r Missing Friends:")
		for i=1, table.getn(FriendsList) do
			DEFAULT_CHAT_FRAME:AddMessage(FriendsList[i])
			
			-- Attempt to re-add any missing friends
			AddFriend(FriendsList[i])
		end
	end
	
	-- Save the current FriendsList
	if (table.getn(FriendsListCurrent) ~= 0) then
		if (GlobalList == true) then
			GlobalFriendsList_FriendsList_gl = FriendsListCurrent
		else
			GlobalFriendsList_FriendsList_lc = FriendsListCurrent
		end
	end
end

GlobalFriendsList_ChatFrame_OnEvent = ChatFrame_OnEvent
function ChatFrame_OnEvent(event)
	if (event == "CHAT_MSG_SYSTEM") then
		_, _, removedfriend = string.find(arg1,"(%a+) removed from friends")
		_, _, addedfriend = string.find(arg1,"(%a+) added to friends")
		if (removedfriend) then
			-- If we're using a global list and we removed them, mark them for deletion across all toons.
			if (GlobalList == true) then
				-- Only make them for deletion if they haven't already been marked 
				if not tablefind(GlobalFriendsList_MarkDelete,removedfriend) then
					table.insert(GlobalFriendsList_MarkDelete,removedfriend)
				end
			end
			-- Remove them from the global list
			if tablefind(GlobalFriendsList_FriendsList_gl,removedfriend) then
				table.remove(GlobalFriendsList_FriendsList_gl,tablefind(GlobalFriendsList_FriendsList_gl,removedfriend))
			end
			-- Remove them from the local list
			if tablefind(GlobalFriendsList_FriendsList_lc,removedfriend) then
				table.remove(GlobalFriendsList_FriendsList_lc,tablefind(GlobalFriendsList_FriendsList_lc,removedfriend))
			end
		end
		if (addedfriend) then
			if tablefind(GlobalFriendsList_MarkDelete,addedfriend) then
				table.remove(GlobalFriendsList_MarkDelete,tablefind(GlobalFriendsList_MarkDelete,addedfriend))
			end
			-- Add new friend to the global or local list
			if (GlobalList == true) then
				table.insert(GlobalFriendsList_FriendsList_gl,addedfriend)
			else
				table.insert(GlobalFriendsList_FriendsList_lc,addedfriend)
			end

		end
	end
	GlobalFriendsList_ChatFrame_OnEvent(event);
end

-- Options
SLASH_GLOBALFRIENDSLIST1, SLASH_GLOBALFRIENDSLIST2 = "/gfl", "/GlobalFriendsList"
SlashCmdList["GLOBALFRIENDSLIST"] = function(message)
	local commandlist = { }
	local command

	for command in gfind(message, "[^ ]+") do
		table.insert(commandlist, string.lower(command))
	end

	-- toggle global mode
	if commandlist[1] == "global" then
		if GlobalList then
			GlobalList = false
		else
			GlobalList = true
		end
		DEFAULT_CHAT_FRAME:AddMessage("|cffbe5eff[GlobalFriendsList]|r Global Friends List:|cffbe5eff ".. tostring(GlobalList))
		FriendsList()
	-- manual run
	elseif commandlist[1] == "run" then
		FriendsList()
	else
		DEFAULT_CHAT_FRAME:AddMessage("|cffbe5eff[GlobalFriendsList]|r v"..tostring(GetAddOnMetadata("GlobalFriendsList", "Version")))
		DEFAULT_CHAT_FRAME:AddMessage("|cffbe5eff/gfl global|cffaaaaaa - |rGlobal Friends List: |cffbe5eff".. tostring(GlobalList))
		DEFAULT_CHAT_FRAME:AddMessage("|cffbe5eff/gfl run|cffaaaaaa - |rManually run the Friends List check.")
	end
end

GFLDelay:Show()