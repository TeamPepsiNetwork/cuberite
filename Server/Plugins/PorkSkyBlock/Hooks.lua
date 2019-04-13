-- fill all chunks with air
function OnChunkGenerating(a_World, a_ChunkX, a_ChunkZ, a_ChunkDesc)
    if (a_World:GetName() == WORLD_NAME) then
        FillBlocks(a_ChunkDesc)
        -- if ((a_ChunkX == -1 or a_ChunkX == 0) and (a_ChunkZ == -1 or a_ChunkZ == 0)) then
        --     a_ChunkDesc:FillRelCuboid(0, 15, 128, 128, 0, 15, E_BLOCK_STONE, 0)
        -- end
    elseif (a_World:GetName() == NETHER_NAME) then
        FillBlocks(a_ChunkDesc)
        for x = 0, 15 do
            for z = 0, 15 do
                a_ChunkDesc:SetBiome(x, z, biHell)
            end
        end
    end
end

function FillBlocks(a_ChunkDesc)
    a_ChunkDesc:FillBlocks(E_BLOCK_AIR, 0)
    a_ChunkDesc:SetUseDefaultBiomes(false)
    a_ChunkDesc:SetUseDefaultHeight(false)
    a_ChunkDesc:SetUseDefaultComposition(false)
    a_ChunkDesc:SetUseDefaultFinish(false)
end

-- random spawn position and starter items
function OnPlayerSpawn(a_Player)
    if (a_Player:GetWorld():GetName() ~= WORLD_NAME) then
        return
    end

    if (a_Player:GetPosX() == 0 and a_Player:GetPosY() == 0 and a_Player:GetPosZ() == 0) then
        -- player is respawning
        local a_BedPos = a_Player:GetLastBedPos()
        if (a_BedPos.x == 0 and a_BedPos.y == 0 and a_BedPos.z == 0) then
            -- player does not have a bed
            if (ANARCHY) then
                -- find random valid spawn position
                if (not TeleportPlayerToRandomPosition(a_Player, a_Player:GetWorld(), 0, 0, SPAWN_RADIUS, MAX_SPAWN_TRIES)) then
                    LOG("Unable to find spawn position for player within " .. MAX_SPAWN_TRIES .. " searches!")
                    a_Player:TeleportToCoords(SPAWN_X + 0.5, SPAWN_Y, SPAWN_Z + 0.5)
                end
            else
                local data = GetPlayerdata(a_Player)
                if (data.island == nil) then
                    a_Player:TeleportToCoords(SPAWN_X + 0.5, SPAWN_Y + 0.5, SPAWN_Z + 0.5)
                else
                end
                -- TODO: respawn player on their island if they have one
            end
        end
    end
end

function OnPlayerJoined(a_Player)
    LoadPlayerdata(a_Player)
    a_Player:SendMessage("§9Welcome to §l" .. INSTANCE_NAME .. "§r§9!")
    a_Player:SendMessage("§9Type §o/start§r§9 to obtain starter items.")
    a_Player:SendMessage("§9Type §o/challenge§r§9 to view the challenge list.")
end

function OnPlayerDestroyed(a_Player)
    SavePlayerdata(a_Player)
end

function OnEntityChangingWorld(a_Entity, a_World)
    if (a_Entity:IsPlayer() and a_World == NETHER) then
        local data = GetPlayerdata(a_Entity)
        local netherChallenge = INDEXED_CHALLENGES["misc.nether"]
        if (netherChallenge ~= nil and data.challenges["misc.nether"] == 0) then
            for _, challengeId in pairs(netherChallenge.depends) do
                if (data.challenges[challengeId] == 0) then
                    return
                end
            end
            TryCompleteChallenge(a_Entity, netherChallenge, true)
        end
    end
end

function OnWorldTick(a_World, a_TimeDelta)
    if (ANARCHY and SPAWN_REBUILD) then
        for x = -3, 3 do
            for z = -3, 3 do
                a_World:FastSetBlock(x, 128, z, E_BLOCK_BEDROCK, 0)
                a_World:FastSetBlock(x, 129, z, E_BLOCK_AIR, 0)
                a_World:FastSetBlock(x, 130, z, E_BLOCK_AIR, 0)
            end
        end
    end
end

function OnPlayerBreakingOrPlacingBlock(a_Player, a_BlockX, a_BlockY, a_BlockZ, a_BlockType, a_BlockMeta)
    if (ANARCHY) then
        if (SPAWN_REBUILD and a_BlockX <= 3 and a_BlockX >= -3 and a_BlockY <= 130 and a_BlockY >= 128 and a_BlockZ <= 3 and a_BlockZ >= -3 and not a_Player:HasPermission("skyblock.buildspawn")) then
            return true
        end
    elseif (not DoesPlayerHavePermission(a_Player, a_BlockX, a_BlockZ)) then
        return true
    end
end
