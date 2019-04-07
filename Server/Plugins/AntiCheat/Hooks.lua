PLAYER_DATA = {}

function OnPlayerSpawned(a_Player)
    local data = {}
    PLAYER_DATA[a_Player:GetName()] = data
    for _, module in pairs(MODULES) do
        if (module.onJoin ~= nil) then
            module.onJoin(a_Player, data)
        end
    end
end

function OnPlayerDestroyed(a_Player)
    PLAYER_DATA[a_Player:GetName()] = nil
end
