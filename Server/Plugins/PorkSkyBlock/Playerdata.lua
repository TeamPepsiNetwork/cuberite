-- methods for working with the playerdata thing i made

PLAYER_DATA = {}
ISLANDS = {}

ISLAND_SIZE = 128
ISLAND_PERIOD = 512

-- player
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
    return data
end

function SavePlayerdata(a_Player)
    local uuid = a_Player:GetUUID()
    local data = PLAYER_DATA[uuid]
    PLAYER_DATA[uuid] = nil
    assert(data ~= nil)
    local json = cJson:Serialize(data)
    TryExec("REPLACE INTO skyblock VALUES('" .. uuid .. "', '" .. json .. "')")
    if (not ANARCHY and data.island ~= nil) then
        SaveIslandData(data.island)
    end
end

function DefaultPlayerdata(a_Player)
    local data = {
        uuid = a_Player:GetUUID(),
        name = a_Player:GetName(),
        lastIsland = -1,
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

function GetPlayerdata(a_Player)
    local data = PLAYER_DATA[a_Player:GetUUID()]
    if (data == nil) then
        data = LoadPlayerdata(a_Player)
    end
    return data
end

--island
function LoadIslandData(id)
    local island = nil
    for row in DB:nrows("SELECT * FROM islands WHERE id = " .. id .. "") do
        island = cJson:Parse(row.data)
    end
    if (island == nil) then
        island = DefaultIslandData(id)
    end
    -- EnsureIslandDataHasAllValues(id, island)
    ISLANDS[id] = island
    return island
end

function SaveIslandData(id)
    local island = ISLANDS[id]
    ISLANDS[id] = nil
    assert(island ~= nil)
    local json = cJson:Serialize(island)
    TryExec("REPLACE INTO islands (id, data) VALUES(" .. id .. ", '" .. json .. "')")
end

function DefaultIslandData(id, ownerUUID)
    local data = {
        id = id,
        owner = ownerUUID,
        allowed = {},
        spawn = { -- spawn position, relative to island center
            x = 0,
            y = 128,
            z = 0
        },
        x = 0,
        z = 0
    }
    return data
end

function CreateOwnedIslandFor(a_Player, playerData)
    TryExec("REPLACE INTO islands (data, owner) VALUES('{}', '" .. a_Player:GetUUID() .. "')")
    local id = -1
    for row in DB:nrows("SELECT * FROM islands WHERE owner = '" .. a_Player:GetUUID() .. "'") do
        id = row.id
    end
    assert(id ~= -1, "Couldn't allocate DB row!")
    playerData.island = id
    local island = DefaultIslandData(id, a_Player:GetUUID())
    TryExec("REPLACE INTO islands (id, data) VALUES(" .. id .. ", '" .. cJson:Serialize(island) .. "')")
    return island
end

function GetOwnedIsland(a_Player, createIfMissing)
    if (createIfMissing == nil) then
        createIfMissing = false
    end
    local playerData = GetPlayerdata(a_Player)
    local island = playerData.island ~= nil and GetIslandById(playerData.island) or nil
    if (island == nil and createIfMissing) then
        island = CreateOwnedIslandFor(a_Player, playerData)
    end
    return island
end

function ResetIsland(island)
    island.spawn = {
        x = 0,
        y = 128,
        z = 0
    }
    -- TODO: actually reset it
end

function GetIslandById(id)
    if (id < 0) then
        return nil
    end
    local island = ISLANDS[id]
    if (island == nil) then
        island = LoadIslandData(id)
    end
    return island
end

function DoesPlayerHavePermission(a_Player, x, z)
    if (a_Player:HasPermission("skyblock.admin")) then
        return true
    end
    local island = GetIslandByPos(x, z)
    if (island == nil) then
        return false
    elseif (island.owner == a_Player:GetUUID()) then
        return true
    end
    for _, uuid in pairs(island.allowed) do
        if (uuid == a_Player:GetUUID()) then
            return true
        end
    end
    return false
end

function GetIslandByPos(x, z)
    return GetIslandById(math.floor(x / ISLAND_SIZE) + math.floor(z / ISLAND_SIZE) * ISLAND_PERIOD)
end

-- misc utils
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

function GetCooldownString(a_Player)
    return GetCooldownStringFromRemaining(GetPlayerdata(a_Player).startTime + START_COOLDOWN - a_Player:GetWorld():GetWorldAge())
end

function GetCooldownStringFromRemaining(remaining)
    remaining = remaining / 20
    return math.floor(remaining / 86400) .. "d:" .. (math.floor(remaining / 3600) % 24) .. "h:" .. (math.floor(remaining / 60) % 60) .. "m:" .. math.floor(remaining % 60) .. "s"
end
