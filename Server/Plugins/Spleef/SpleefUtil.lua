function BeginSpectate(a_Player)
    PLAYER_LIST[a_Player:GetUUID()].ingame = false
    a_Player:GetInventory():Clear()
    a_Player:SetGameMode(eGameMode_Spectator)
    a_Player:TeleportToCoords(0, 128, 0)
    TryStartGame()
end

function BeginPlay(a_Player)
    PLAYER_LIST[a_Player:GetUUID()].ingame = true
    a_Player:SetGameMode(eGameMode_Survival)

    local inv = a_Player:GetInventory()
    inv:Clear()

    inv:SetHotbarSlot(0, cItem(E_ITEM_DIAMOND_SHOVEL, 1, 0))

    a_Player:SendAboveActionBarMessage("")
end

function TryStartGame()
    if (CanStartGame()) then
        DoStartGame()
    end
end

function DoStartGame()
    if (#CURRENT_GAME == 1) then
        for _, data in pairs(CURRENT_GAME) do
            WORLD:DoWithPlayerByUUID(data.uuid, OnWin)
        end
        CURRENT_GAME = {}
    end
    for k, v in pairs(PLAYER_LIST) do
        CURRENT_GAME[k] = v
        WORLD:DoWithPlayerByUUID(v.uuid, BeginPlay)
    end
end

function CanStartGame()
    return #CURRENT_GAME <= 1 and #PLAYER_LIST >= 2
end

function OnWin(a_Player)
    WINS_OBJECTIVE:AddScore(GetDisplayName(a_Player), 1)
    a_Player:GetClientHandle():SendSoundEffect("entity.experience_orb.pickup", a_Player:GetEyePosition(), 1.0, 63)
    WORLD:BroadcastChat("§aWinner: " .. GetDisplayName(a_Player) .. "§r§a!")
end
