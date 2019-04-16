-- basically allows the correct attacker to be located when exploding a bed in the nether
-- also prevents impossible amounts of damage from being dealt

QUEUED_RIGHT_CLICKS = {}
CURRENT_KILL_PLAYER = nil

function OnPlayerUsingBlock(a_Player, a_BlockX, a_BlockY, a_BlockZ, a_BlockFace, a_CursorX, a_CursorY, a_CursorZ, a_BlockType, a_BlockMeta)
    if (DoBedsExplode(a_Player:GetWorld()) and a_BlockType == E_BLOCK_BED) then
        QUEUED_RIGHT_CLICKS[XYZToString(a_BlockX, a_BlockY, a_BlockZ)] = a_Player
    end
end

function OnExploding(a_World, a_ExplosionSize, a_CanCauseFire, X, Y, Z, a_Source, a_SourceData)
    if (DoBedsExplode(a_World) and a_Source == esBed) then
        local key = XYZToString(a_SourceData.x, a_SourceData.y, a_SourceData.z)
        local player = QUEUED_RIGHT_CLICKS[key]
        if (player ~= nil) then
            QUEUED_RIGHT_CLICKS[key] = nil
            CURRENT_KILL_PLAYER = player
        end
    end
end

function OnExploded(a_World, a_ExplosionSize, a_CanCauseFire, X, Y, Z, a_Source, a_SourceData)
    if (DoBedsExplode(a_World) and a_Source == esBed) then
        CURRENT_KILL_PLAYER = nil
    end
end

function OnTakeDamage(a_Victim, a_Info)
    --local old = a_Info.FinalDamage
    a_Info.FinalDamage = CalculateMaxDealableDamage(a_Victim, a_Info.FinalDamage)
    if (a_Info.DamageType == dtExplosion and DoBedsExplode(a_Victim:GetWorld()) and a_Info.Attacker == nil and CURRENT_KILL_PLAYER ~= nil) then
        a_Info.Attacker = CURRENT_KILL_PLAYER
    end
    --if (a_Info.DamageType == dtArrow) then
    --    LOG("Took " .. a_Info.FinalDamage .. " damage from arrow")
    --end
    --LOG("PepsiUtils: Took " .. a_Info.FinalDamage .. " damage from " .. DamageTypeToString(a_Info.DamageType) .. "! (old=" .. old .. ")")
end

function OnKilled(a_Victim, a_Info, a_DeathMessage)
    --local old = a_Info.FinalDamage
    a_Info.FinalDamage = CalculateMaxDealableDamage(a_Victim, a_Info.FinalDamage)
    if (DoBedsExplode(a_Victim:GetWorld()) and a_Info.DamageType == dtExplosion and a_Info.Attacker == nil and CURRENT_KILL_PLAYER ~= nil) then
        a_Info.Attacker = CURRENT_KILL_PLAYER
    end
    --if (a_Info.DamageType == dtArrow) then
    --    LOG("Took " .. a_Info.FinalDamage .. " damage from arrow")
    --end
    --LOG("PepsiUtils: Killed with " .. a_Info.FinalDamage .. " damage from " .. DamageTypeToString(a_Info.DamageType) .. "! (old=" .. old .. ")")
end

function DoBedsExplode(a_World)
    local dim = a_World:GetDimension()
    return dim == dimNether or dim == dimEnd
end

function CalculateMaxDealableDamage(victim, amount)
    return math.max(math.min(amount, victim:GetHealth()), 0)
end
