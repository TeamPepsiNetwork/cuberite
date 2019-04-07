QUEUED_RIGHT_CLICKS = {}
CURRENT_KILL_PLAYER = nil

function OnPlayerUsingBlock(a_Player, a_BlockX, a_BlockY, a_BlockZ, a_BlockFace, a_CursorX, a_CursorY, a_CursorZ, a_BlockType, a_BlockMeta)
    if (a_Player:GetWorld() == WORLD and a_BlockType == E_BLOCK_BED) then
        -- LOG("Processing player right-click...")
        QUEUED_RIGHT_CLICKS[XYZToString(a_BlockX, a_BlockY, a_BlockZ)] = a_Player
    end
end

function OnExploding(a_World, a_ExplosionSize, a_CanCauseFire, X, Y, Z, a_Source, a_SourceData)
    if (a_World == WORLD and a_Source == esBed) then
        -- LOG("Processing explosion...")
        local key = XYZToString(a_SourceData.x, a_SourceData.y, a_SourceData.z)
        local player = QUEUED_RIGHT_CLICKS[key]
        if (player ~= nil) then
            -- LOG("Found explosion source player!")
            QUEUED_RIGHT_CLICKS[key] = nil
            CURRENT_KILL_PLAYER = player
        end
    end
end

function OnExploded(a_World, a_ExplosionSize, a_CanCauseFire, X, Y, Z, a_Source, a_SourceData)
    if (a_World == WORLD and a_Source == esBed) then
        -- LOG("Explosion processing complete.")
        CURRENT_KILL_PLAYER = nil
    end
end

function OnTakeDamage(a_Victim, a_Info)
    if (a_Victim:GetWorld() == WORLD and a_Victim:IsPlayer()) then
        local attacker = a_Info.Attacker
        a_Info.FinalDamage = CalculateMaxDealableDamage(a_Victim, a_Info.FinalDamage)
        if (a_Info.DamageType == dtExplosion and CURRENT_KILL_PLAYER ~= nil) then
            attacker = CURRENT_KILL_PLAYER
            ManageDamageDealtStatistic(attacker, a_Victim, a_Info.FinalDamage)
        end
        if (a_Victim:GetHealth() - a_Info.FinalDamage == 0) then
            LOG("Player took damage and will be killed by it!")
            a_Victim:GetStatManager():AddValue(statDamageTaken, math.floor(a_Info.FinalDamage * 10 + 0.5))
        end
        LOG("Final damage dealt (not killed): " .. a_Info.FinalDamage)
    end
end

function OnKilled(a_Victim, a_Info, a_DeathMessage)
    if (a_Victim:GetWorld() == WORLD and a_Victim:IsPlayer()) then
        local killer = a_Info.Attacker
        a_Info.FinalDamage = CalculateMaxDealableDamage(a_Victim, a_Info.FinalDamage)
        if (a_Info.DamageType == dtExplosion and CURRENT_KILL_PLAYER ~= nil) then
            killer = CURRENT_KILL_PLAYER
            ManageDamageDealtStatistic(killer, a_Victim, a_Info.FinalDamage)
        end
        if (killer ~= nil) then
            -- LOG("Player " .. a_Victim:GetName() .. " killed by " .. killer:GetName() .. "!")
            -- LOG("Damage dealt: " .. a_Info.FinalDamage)
            killer:Killed(a_Victim)
            killer:GetClientHandle():SendSoundEffect("entity.experience_orb.pickup", killer:GetEyePosition(), 1.0, 63)
            if (killer ~= a_Victim) then
                KILLS_OBJECTIVE:AddScore(killer:GetName(), 1)
            end
        end
        KILLS_OBJECTIVE:SubScore(a_Victim:GetName(), 1)
        LOG("Final damage dealt: " .. a_Info.FinalDamage)
    end
end

function CalculateMaxDealableDamage(victim, amount)
    LOG("Attempting to deal " .. amount .. " damage, victim has " .. victim:GetHealth() .. " remaining.")
    return math.max(math.min(amount, victim:GetHealth()), 0)
end

function ManageDamageDealtStatistic(attacker, victim, amount)
    -- LOG("Attempting to deal " .. amount .. " damage, victim has " .. victim:GetHealth() .. " remaining.")
    --amount = CalculateMaxDealableDamage(victim, amount)
    if (amount > 0) then
        LOG("Damage dealt: " .. amount)
        amount = math.floor(amount * 10 + 0.5)
        attacker:GetStatManager():AddValue(statDamageDealt, amount)
    end
end
-- TODO: move all this damage stuff into pepsiutils
