function TeleportPlayerToSpawn(a_Player)
    -- teleport player to world spawn
    local world = a_Player:GetWorld()
    if (world:GetName() == WORLD_NAME) then
        a_Player:TeleportToCoords(world:GetSpawnX(), world:GetSpawnY(), world:GetSpawnZ())
    end
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
    --LOG("Player moved to x=" .. a_NewPos.x .. ", y=" .. a_NewPos.y .. ", z=" .. a_NewPos.z)
    return ConsiderTeleportPlayer(a_Player, a_NewPos)
end

--function OnEntityChangingWorld(a_Entity, a_DstWorld)
--    return a_Entity:IsPlayer() and ConsiderTeleportPlayer(a_Entity, nil)
--end

function OnPlayerBreakingBlock(a_Player, a_BlockX, a_BlockY, a_BlockZ, a_BlockFace, a_BlockType, a_BlockMeta)
    if (a_BlockType == E_BLOCK_NETHER_PORTAL and a_Player:GetWorld() == WORLD and PORTAL_CREATE_QUEUE[a_Player:GetUUID()] ~= nil) then
        DoAddPortal(a_Player, a_BlockX, a_BlockY, a_BlockZ)
        return true
    end
end
