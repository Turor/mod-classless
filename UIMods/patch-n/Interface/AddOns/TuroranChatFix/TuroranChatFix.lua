-- 3.3.5 FrameXML never defined CHAT_NOT_IN_LFG_NOTICE. ChatFrame.lua:2802
-- still does format(_G["CHAT_"..arg1.."_NOTICE"], channelIndex, channelName)
-- when the client maps SMSG_CHANNEL_NOTIFY 0x21 to arg1 "NOT_IN_LFG".
-- AzerothCore sends that notice for LookingForGroup if Channel.RestrictedLfg
-- is on and the character is not in the dungeon finder.

CHAT_NOT_IN_LFG_NOTICE = CHAT_NOT_IN_LFG_NOTICE or
    "|Hchannel:%d|h[%s]|h You must be queued in looking for group before joining this channel."
CHAT_NOT_IN_LFG_NOTICE_BN = CHAT_NOT_IN_LFG_NOTICE_BN or CHAT_NOT_IN_LFG_NOTICE

-- Any other notice type without a global string used to throw
-- "bad argument #1 to 'format' (string expected, got nil)".
local orig = ChatFrame_MessageEventHandler
function ChatFrame_MessageEventHandler(self, event, ...)
    if event == "CHAT_MSG_CHANNEL_NOTICE" or event == "CHAT_MSG_CHANNEL_NOTICE_USER" then
        local notice = ...
        if type(notice) == "string" then
            local key = "CHAT_" .. notice .. "_NOTICE"
            if not _G[key] and not _G[key .. "_BN"] then
                _G[key] = "|Hchannel:%d|h[%s]|h"
            end
        end
    end
    return orig(self, event, ...)
end
