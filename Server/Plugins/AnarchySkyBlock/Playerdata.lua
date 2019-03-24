-- methods for working with the playerdata thing i made

PLAYER_DATA = {}

function LoadPlayerdata(a_Player)
    local uuid = a_Player:GetUUID()
    local data = nil
    for row in DB:nrows("SELECT * FROM skyblock WHERE uuid = '" .. uuid .. "'") do
        LOG("Found player data for \"" .. uuid .. "\"!")
        data = row
    end
    if (data == nil) then
        data = DefaultPlayerdata(a_Player)
    end
    PLAYER_DATA[uuid] = data
end

function SavePlayerdata(a_Player)
    local uuid = a_Player:GetUUID()
    local data = PLAYER_DATA[uuid];
    if (data ~= nil) then
        PLAYER_DATA[uuid] = nil
        local json = cJson:Serialize(data)
        return TryExec("REPLACE INTO skyblock VALUES('" .. uuid .. "', '" .. json .. "')")
    else
        return false
    end
end

function DefaultPlayerdata(a_Player)
    return {
        uuid = a_Player:GetUUID(),
        name = a_Player:GetName(),
        startTime = 0,
        challenges = {} -- TODO: fill with false for all challenges
    }
end

function GetPlayerdata(a_Player)
    return PLAYER_DATA[a_Player:GetUUID()]
end
