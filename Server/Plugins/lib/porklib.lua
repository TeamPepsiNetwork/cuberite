--jeff

dofile(LOCAL_FOLDER .. "/../lib/pork/PMLib.lua")

function BungeeTransferPlayer(a_Player, target, display)
    assert(type(target) == "string", "Target server must be a string!")
    a_Player:SendMessage("§9Connecting to §l" .. (display == nil and target or display) .. "§r§9...")
    a_Player:GetClientHandle():SendPluginMessage(PMLib:new("BungeeCord"):writeUTF("Connect"):writeUTF(target):GetOut())
end

function clamp(val, min, max)
    if (val > max) then
        return max
    elseif (val < min) then
        return min
    else
        return val
    end
end

function TeleportPlayerToRandomPosition(a_Player, a_World, a_CenterX, a_CenterZ, a_Radius, a_MaxTries)
    if (a_MaxTries == nil) then
        a_MaxTries = 512
    elseif (a_MaxTries == -1) then
        a_MaxTries = 2147483647
    end
    for i = 0, a_MaxTries do
        local x = math.random(a_CenterX - a_Radius, a_CenterX + a_Radius - 1)
        local y = math.random(1, 256)
        local z = math.random(a_CenterZ - a_Radius, a_CenterZ + a_Radius - 1)

        local below = a_World:GetBlock(x, y - 1, z)
        local feet = y > 255 and 0 or a_World:GetBlock(x, y, z)
        local head = y > 254 and 0 or a_World:GetBlock(x, y + 1, z)
        if (below ~= E_BLOCK_AIR
                and feet == E_BLOCK_AIR
                and head == E_BLOCK_AIR
                and below ~= E_BLOCK_FIRE
                and below ~= E_BLOCK_LAVA
                and below ~= E_BLOCK_STATIONARY_LAVA
                and below ~= E_BLOCK_WATER
                and below ~= E_BLOCK_STATIONARY_WATER
                and below ~= E_BLOCK_CACTUS
                and below ~= E_BLOCK_SIGN) then
            a_Player:TeleportToCoords(x + 0.5, y, z + 0.5)
            return true
        end
    end
    return false
end

function XYZToString(x, y, z)
    return "(" .. x .. ", " .. y .. ", " .. z .. ")"
end

function GetDisplayName(a_Player)
    local _, _, color = cRankManager:GetPlayerMsgVisuals(a_Player:GetUUID())
    if (color ~= nil) then
        return "§" .. color .. a_Player:GetName() .. "§r"
    else
        return a_Player:GetName()
    end
end
