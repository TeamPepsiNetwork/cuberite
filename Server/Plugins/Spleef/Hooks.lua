PLAYER_LIST = {}
CURRENT_GAME = {}

function OnChunkGenerated(a_World, a_ChunkX, a_ChunkZ, a_ChunkDesc)
    if (a_World == WORLD) then
        a_ChunkDesc:FillBlocks(E_BLOCK_AIR, 0)
        a_ChunkDesc:SetUseDefaultBiomes(false)
        a_ChunkDesc:SetUseDefaultHeight(false)
        a_ChunkDesc:SetUseDefaultComposition(false)
        a_ChunkDesc:SetUseDefaultFinish(false)
    end
end

function OnPlayerSpawned(a_Player)
    if (a_Player:GetWorld() == WORLD) then
        PLAYER_LIST[a_Player:GetUUID()] = {
            uuid = a_Player:GetUUID(),
            ingame = false
        }
        BeginSpectate(a_Player)
    end
end

function OnPlayerDestroyed(a_Player)
    PLAYER_LIST[a_Player:GetUUID()] = nil
    CURRENT_GAME[a_Player:GetUUID()] = nil
end

function OnEntityChangedWorld(a_Entity, a_SrcWorld)
    if (a_Entity:IsPlayer()) then
        if (a_Entity:GetWorld() == WORLD) then
            PLAYER_LIST[a_Entity:GetUUID()] = {
                uuid = a_Entity:GetUUID(),
                ingame = false
            }
            BeginSpectate(a_Entity)
        elseif (a_SrcWorld == WORLD) then
            OnPlayerDestroyed(a_Player)
        end
    end
end

function OnPlayerMoving(a_Player, a_OldPos, a_NewPos)
    if (a_Player:GetWorld() == WORLD) then
        if (a_NewPos.y <= 126) then
            BeginSpectate(a_Player)
            return true
        end
    end
end

function OnPlayerBreakingBlock(a_Player, a_BlockX, a_BlockY, a_BlockZ, a_BlockFace, a_BlockType, a_BlockMeta)
    if (a_BlockType ~= E_BLOCK_SNOW_BLOCK and not a_Player:HasPermission("spleef.admin")) then
        return true
    end
end

function OnWorldTick(a_World, a_TimeDelta)
    if (a_World == WORLD) then
        for _, data in pairs(PLAYER_LIST) do
            if (not data.ingame) then
                a_World:DoWithPlayerByUUID(data.uuid, function(a_Player)
                    a_Player:SendAboveActionBarMessage("§aWaiting for current round to end and players to join...")
                end)
            end
        end
    end
end

function PrepareArena()
    ARENA_BLOCKS = cBlockArea()
    ARENA_BLOCKS:Create(ARENA_RADIUS * 2, 256, ARENA_RADIUS * 2)
    for x = 0, ARENA_RADIUS * 2 - 1 do
        for z = 0, ARENA_RADIUS * 2 - 1 do
            ARENA_BLOCKS:SetRelBlockType(x, 0, z, E_BLOCK_BEDROCK)
            for y = 1, 32 do
                ARENA_BLOCKS:SetRelBlockType(x, y, z, E_BLOCK_OBSIDIAN)
            end
        end
    end
    ResetArena(WORLD)
end

function ResetArena(a_World)
    DoResetArena(a_World)
    a_World:ScheduleTask(RESET_DELAY, ResetArena)
end

function DoResetArena(a_World)
    RESET_COUNTER = RESET_COUNTER + 1
    a_World:ScheduleTask(0, function(a_World)
        a_World:ForEachEntity(function(a_Entity)
            if (a_Entity:IsPickup()) then
                a_Entity:Destroy()
            elseif (a_Entity:IsPlayer()) then
                a_Entity:SendMessage("§9§lResetting arena...")
            end
        end)
        ARENA_BLOCKS:Write(a_World, -ARENA_RADIUS, 0, -ARENA_RADIUS)
        a_World:ForEachPlayer(ResetPlayer)
    end)
end
