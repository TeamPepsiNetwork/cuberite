function TeleportPlayerToSpawn(a_Player)
    -- teleport player to world spawn
    local world = a_Player:GetWorld()
    a_Player:TeleportToCoords(world:GetSpawnX(), world:GetSpawnY(), world:GetSpawnZ())
end

function OnChunkGenerating(a_World, a_ChunkX, a_ChunkZ, a_ChunkDesc)
    -- override terrain gen with our amazing custom terrain
end
