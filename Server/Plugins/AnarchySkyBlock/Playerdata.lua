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
    EnsurePlayerdataHasAllValues(a_Player, data)
    PLAYER_DATA[uuid] = data
end

function SavePlayerdata(a_Player)
    local uuid = a_Player:GetUUID()
    local data = PLAYER_DATA[uuid]
    PLAYER_DATA[uuid] = nil
    assert(data ~= nil)
    local json = cJson:Serialize(data)
    TryExec("REPLACE INTO skyblock VALUES('" .. uuid .. "', '" .. json .. "')")
end

function DefaultPlayerdata(a_Player)
    local data = {
        uuid = a_Player:GetUUID(),
        name = a_Player:GetName(),
        startTime = 0,
        challengeGui = {
            showUsed = false,
            showInaccessible = true
        },
        challenges = {}
    }
    return data
end

function EnsurePlayerdataHasAllValues(a_Player, data)
    local default = DefaultPlayerdata(a_Player)
    RemoveAllFromOther(data, default)
    AddAllFromOther(data, default)
    EnsurePlayerdataContainsAllChallenges(data)
end

function RemoveAllFromOther(main, other)
    for key, value in pairs(main) do
        local otherValue = other[key]
        if (otherValue ~= nil and type(value) == "table" and type(otherValue) == "table") then
            RemoveAllFromOther(value, otherValue)
        else
            other[key] = nil
        end
    end
end

function AddAllFromOther(main, other)
    for key, value in pairs(other) do
        local mainValue = main[key]
        if (mainValue ~= nil and type(value) == "table" and type(mainValue) == "table") then
            AddAllFromOther(mainValue, value)
        else
            main[key] = value
        end
    end
end

function GetPlayerdata(a_Player)
    local data = PLAYER_DATA[a_Player:GetUUID()]
    if (data == nil) then
        data = LoadPlayerdata(a_Player)
    end
    return data
end

function GetCooldownString(a_Player)
    return GetCooldownStringFromRemaining(GetPlayerdata(a_Player).startTime + START_COOLDOWN - a_Player:GetWorld():GetWorldAge())
end

function GetCooldownStringFromRemaining(remaining)
    return math.floor(remaining / 86400) .. "d:" .. (math.floor(remaining / 3600) % 24) .. "h:" .. (math.floor(remaining / 60) % 60) .. "m:" .. math.floor(remaining % 60) .. "s"
end
