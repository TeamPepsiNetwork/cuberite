function OnPlayerJoined(a_Player)
    return DISABLE_JOIN_MESSAGE
end

function OnPlayerDestroyed(a_Player)
    return DISABLE_JOIN_MESSAGE
end

function OnWorldStarted(a_World)
    a_World:SetShouldUseChatPrefixes(USE_CHAT_PREFIXES)
end
