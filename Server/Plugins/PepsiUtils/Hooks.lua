function OnWorldStarted(a_World)
    a_World:SetShouldUseChatPrefixes(USE_CHAT_PREFIXES)
end

function OnPlayerJoined(a_Player)
    local rankName = RANK_LOOKUP[a_Player:GetUUID()]
    --LOG("Setting player rank to " .. (rankName == nil and "null" or rankName))
    if (rankName ~= nil) then
        cRankManager:SetPlayerRank(a_Player:GetUUID(), a_Player:GetName(), rankName)
    end
    --a_Player:SendMessage(GetDisplayName(a_Player))
end
