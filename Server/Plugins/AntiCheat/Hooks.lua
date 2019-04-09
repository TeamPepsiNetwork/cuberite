PLAYER_DATA = {}

function OnPlayerSpawned(a_Player)
    local data = {}
    PLAYER_DATA[a_Player:GetUUID()] = data
    for _, module in pairs(MODULES) do
        if (module.onSpawn ~= nil) then
            module.onSpawn(a_Player, data)
        end
    end
end

function OnPlayerDestroyed(a_Player)
    PLAYER_DATA[a_Player:GetUUID()] = nil
end
