function TeleportPlayerToSpawn(a_Player)
    if (world:GetName() == WORLD_NAME and not TeleportPlayerToRandomPosition(a_Player, a_Player:GetWorld(), 0, 0, 32, 1024)) then
        a_Player:TeleportToCoords(world:GetSpawnX(), world:GetSpawnY(), world:GetSpawnZ())
    end
end

function OnPlayerMoving(a_Player, a_OldPos, a_NewPos)
    if ((a_NewPos.x > ARENA_RADIUS or a_NewPos.x < -ARENA_RADIUS or a_NewPos.y > 257 or a_NewPos.y < 1 or a_NewPos.z > ARENA_RADIUS or a_NewPos.z < -ARENA_RADIUS) and not a_Player:HasPermission("bedwars.leavearena")) then
        return true
    else
        return ConsiderTeleportPlayer(a_Player, a_NewPos)
    end
end

function OnPlayerBreakingBlock(a_Player, a_BlockX, a_BlockY, a_BlockZ, a_BlockFace, a_BlockType, a_BlockMeta)
end
