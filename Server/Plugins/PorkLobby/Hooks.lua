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
