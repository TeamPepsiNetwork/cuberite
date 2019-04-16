local name = "Reach"

local maxReach = 5.0

local INSTANCE = {
    name = name,
    enabledByDefault = true,
    load = function(config)
    end,
    init = function()
        cPluginManager:AddHook(cPluginManager.HOOK_PLAYER_USING_BLOCK, OnPlayerUsingBlock)
        cPluginManager:AddHook(cPluginManager.HOOK_PLAYER_BREAKING_BLOCK, OnPlayerBreakingBlock)
        cPluginManager:AddHook(cPluginManager.HOOK_PLAYER_PLACING_BLOCK, OnPlayerPlacingBlock)
        cPluginManager:AddHook(cPluginManager.HOOK_TAKE_DAMAGE, OnTakeDamage)
        -- cPluginManager:AddHook(cPluginManager.HOOK_PLAYER_RIGHT_CLICKING_ENTITY, OnPlayerRightClickingEntity)
    end,
    shutdown = function()
    end,
    onSpawn = function(a_Player, data)
    end
}

function OnPlayerUsingBlock(a_Player, a_BlockX, a_BlockY, a_BlockZ, a_BlockFace, a_CursorX, a_CursorY, a_CursorZ, a_BlockType, a_BlockMeta)
    return cBlockInfo:IsSolid(a_BlockType) and not IsInLineOfSight(a_Player, Vector3i(a_BlockX, a_BlockY, a_BlockZ), false)
end

function OnPlayerBreakingBlock(a_Player, a_BlockX, a_BlockY, a_BlockZ, a_BlockFace, a_BlockType, a_BlockMeta)
    return cBlockInfo:IsSolid(a_BlockType) and not IsInLineOfSight(a_Player, Vector3i(a_BlockX, a_BlockY, a_BlockZ), false)
end

function OnPlayerPlacingBlock(a_Player, a_BlockX, a_BlockY, a_BlockZ, a_BlockType, a_BlockMeta)
    if (a_BlockType == E_BLOCK_BED and a_BlockMeta >= 8) then
        return false
    end
    local prevented = true
    local eyePos = a_Player:GetEyePosition()
    local endPos = eyePos + a_Player:GetLookVector() * maxReach
    cLineBlockTracer:Trace(a_Player:GetWorld(), {
        OnNextBlock = function(ray_BlockX, ray_BlockY, ray_BlockZ, a_BlockType, a_BlockMeta)
            if (ray_BlockX == a_BlockX and ray_BlockY == a_BlockY and ray_BlockZ == a_BlockZ) then
                prevented = false
                return true
            end
        end
    }, eyePos.x, eyePos.y, eyePos.z, endPos.x, endPos.y, endPos.z)
    return prevented
end

function OnTakeDamage(a_Receiver, a_TDI)
    if (a_TDI.Attacker ~= nil and a_TDI.Attacker:IsPlayer() and a_TDI.DamageType ~= dtArrow) then
        if (Distance(a_Receiver:GetPosition(), a_TDI.Attacker:GetEyePosition()) - 1 > maxReach) then
            return true
        end
    end
end

function OnPlayerRightClickingEntity(a_Player, a_Entity)
end

function IsInLineOfSight(a_Player, pos, transparent)
    local eyes = a_Player:GetEyePosition()
    local hasHit, _, hitPos
    if (transparent) then
        hasHit, _, hitPos = cLineBlockTracer:FirstOpaqueHitTrace(a_Player:GetWorld(), eyes, eyes + a_Player:GetLookVector() * maxReach)
    else
        hasHit, _, hitPos = cLineBlockTracer:FirstSolidHitTrace(a_Player:GetWorld(), eyes, eyes + a_Player:GetLookVector() * maxReach)
    end
    -- LOG(hasHit and "Hit! " .. VectorToString(hitPos) or "Trace missed...")
    return hasHit and pos.x == hitPos.x and pos.y == hitPos.y and pos.z == hitPos.z
end

ALL_MODULES[name] = INSTANCE
