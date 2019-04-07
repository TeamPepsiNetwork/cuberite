QUEUED_RIGHT_CLICKS = {}
CURRENT_KILL_PLAYER = nil

function OnPlayerUsingBlock(a_Player, a_BlockX, a_BlockY, a_BlockZ, a_BlockFace, a_CursorX, a_CursorY, a_CursorZ, a_BlockType, a_BlockMeta)
    if (a_Player:GetWorld() == WORLD and a_BlockType == E_BLOCK_BED) then
        LOG("Processing player right-click...")
        QUEUED_RIGHT_CLICKS[XYZToString(a_BlockX, a_BlockY, a_BlockZ)] = a_Player
    end
end

function OnExploding(a_World, a_ExplosionSize, a_CanCauseFire, X, Y, Z, a_Source, a_SourceData)
    if (a_World == WORLD and a_Source == esBed) then
        LOG("Processing explosion...")
        local key = XYZToString(a_SourceData.x, a_SourceData.y, a_SourceData.z)
        local player = QUEUED_RIGHT_CLICKS[key]
        if (player ~= nil) then
            LOG("Found explosion source player!")
            QUEUED_RIGHT_CLICKS[key] = nil
            CURRENT_KILL_PLAYER = player
        end
    end
end

function OnExploded(a_World, a_ExplosionSize, a_CanCauseFire, X, Y, Z, a_Source, a_SourceData)
    if (a_World == WORLD and a_Source == esBed) then
        LOG("Explosion processing complete.")
        CURRENT_KILL_PLAYER = nil
    end
end

function OnKilled(a_Victim, a_Info, a_DeathMessage)
    if (a_Victim:GetWorld() == WORLD and a_Victim:IsPlayer()) then
        if (a_Info.DamageType == dtExplosion and CURRENT_KILL_PLAYER ~= nil) then
            LOG("Player " .. a_Victim:GetName() .. " killed by " .. CURRENT_KILL_PLAYER:GetName() .. "!")
            if (CURRENT_KILL_PLAYER ~= a_Victim) then
                CURRENT_KILL_PLAYER:Killed(a_Victim)
                KILLS_OBJECTIVE:AddScore(CURRENT_KILL_PLAYER:GetName(), 1)
                CURRENT_KILL_PLAYER:GetClientHandle():SendSoundEffect("entity.experience_orb.pickup", CURRENT_KILL_PLAYER:GetEyePosition(), 1.0, 63)
            end
        end
        KILLS_OBJECTIVE:SubScore(a_Victim:GetName(), 1)
    end
end
