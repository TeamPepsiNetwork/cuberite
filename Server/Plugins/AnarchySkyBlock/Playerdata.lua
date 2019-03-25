-- methods for working with the playerdata thing i made

PLAYER_DATA = {}

function LoadPlayerdata(a_Player)
    local uuid = a_Player:GetUUID()
    local data = nil
    for row in DB:nrows("SELECT * FROM skyblock WHERE uuid = '" .. uuid .. "'") do
        data = cJson:Parse(row.data)
    end
    if (data == nil) then
        data = DefaultPlayerdata(a_Player)
    end
    EnsurePlayerdataContainsAllChallenges(data)
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
    local data = {
        uuid = a_Player:GetUUID(),
        name = a_Player:GetName(),
        startTime = 0,
        challenges = {}
    }
    return data
end

function GetPlayerdata(a_Player)
    return PLAYER_DATA[a_Player:GetUUID()]
end

function GetCooldownString(a_Player)
    return GetCooldownStringFromRemaining(GetPlayerdata(a_Player).startTime + START_COOLDOWN - a_Player:GetWorld():GetWorldAge())
end

function GetCooldownStringFromRemaining(remaining)
    return math.floor(remaining / 86400) .. "d:" .. (math.floor(remaining / 3600) % 24) .. "h:" .. (math.floor(remaining / 60) % 60) .. "m:" .. math.floor(remaining % 60) .. "s"
end
