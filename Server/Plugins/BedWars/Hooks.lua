ARENA_BLOCKS = nil

function OnPlayerSpawned(a_Player)
    if (a_Player:GetPosX() == 0 and a_Player:GetPosY() == 0 and a_Player:GetPosZ() == 0) then
        local world = a_Player:GetWorld()
        -- player is respawning
        if (world:GetName() == WORLD_NAME and not TeleportPlayerToRandomPosition(a_Player, a_Player:GetWorld(), 0, 0, 32, 1024)) then
            a_Player:TeleportToCoords(0.5, 256, 0.5)
        end
    end
end

function OnPlayerMoving(a_Player, a_OldPos, a_NewPos)
    if ((a_NewPos.x > ARENA_RADIUS or a_NewPos.x < -ARENA_RADIUS or a_NewPos.y > 257 or a_NewPos.y < 1 or a_NewPos.z > ARENA_RADIUS or a_NewPos.z < -ARENA_RADIUS) and not a_Player:HasPermission("bedwars.leavearena")) then
        return true
    end
end

function OnPlayerBreakingBlock(a_Player, a_BlockX, a_BlockY, a_BlockZ, a_BlockFace, a_BlockType, a_BlockMeta)
    if ((a_BlockX >= ARENA_RADIUS or a_BlockX < -ARENA_RADIUS or a_BlockZ >= ARENA_RADIUS or a_BlockZ < -ARENA_RADIUS) and not a_Player:HasPermission("bedwars.leavearena")) then
        return true
    end
end

function PrepareArena()
    ARENA_BLOCKS = cBlockArea()
    ARENA_BLOCKS:Create(ARENA_RADIUS * 2, 256, ARENA_RADIUS * 2, 3)
    ARENA_BLOCKS:Fill(3, E_BLOCK_AIR, 0)
    ARENA_BLOCKS:FillRelCuboid(0, ARENA_RADIUS * 2, 1, 64, 0, ARENA_RADIUS * 2, 3, E_BLOCK_OBSIDIAN, 0)
    ARENA_BLOCKS:FillRelCuboid(0, ARENA_RADIUS * 2, 0, 1, 0, ARENA_RADIUS * 2, 3, E_BLOCK_BEDROCK, 0)
    ResetArena(WORLD)
end

function ResetArena(a_World)
    ARENA_BLOCKS:Write(a_World, -ARENA_RADIUS, 0, -ARENA_RADIUS, 3)
end
