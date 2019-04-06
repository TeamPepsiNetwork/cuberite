function TeleportPlayerToSpawn(a_Player)
    -- teleport player to world spawn
    a_Player:TeleportToCoords(a_Player:GetWorld():GetSpawnX(), a_Player:GetWorld():GetSpawnY(), a_Player:GetWorld():GetSpawnZ())
end

function OnChunkGenerating(a_World, a_ChunkX, a_ChunkZ, a_ChunkDesc)
    if (a_World:GetName() == WORLD_NAME) then
        -- override terrain gen with our own custom terrain
        a_ChunkDesc:SetUseDefaultBiomes(false)
        a_ChunkDesc:SetUseDefaultHeight(false)
        a_ChunkDesc:SetUseDefaultComposition(false)
        GenerateChunk(a_ChunkX, a_ChunkZ, a_ChunkDesc)
    end
end

function OnPlayerMoving(a_Player, a_OldPos, a_NewPos)
    if ((a_NewPos.x > SPAWN_MAX_X or a_NewPos.x < SPAWN_MIN_X or a_NewPos.y > SPAWN_MAX_Y or a_NewPos.y < SPAWN_MIN_Y or a_NewPos.z > SPAWN_MAX_Z or a_NewPos.z < SPAWN_MIN_Z) and not a_Player:HasPermission("porklobby.leavespawn")) then
        return true
    else
        return ConsiderTeleportPlayer(a_Player, a_NewPos)
    end
end

function OnPlayerBreakingBlock(a_Player, a_BlockX, a_BlockY, a_BlockZ, a_BlockFace, a_BlockType, a_BlockMeta)
    if (a_BlockType == E_BLOCK_NETHER_PORTAL and a_Player:GetWorld() == WORLD and PORTAL_CREATE_QUEUE[a_Player:GetUUID()] ~= nil) then
        DoAddPortal(a_Player, a_BlockX, a_BlockY, a_BlockZ)
        return true
    end
end
