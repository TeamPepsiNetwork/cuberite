-- fill all chunks with air
function OnChunkGenerating(a_World, a_ChunkX, a_ChunkZ, a_ChunkDesc)
    if (a_World:GetName() == WORLD_NAME) then
        FillBlocks(a_ChunkDesc)
        if ((a_ChunkX == -1 or a_ChunkX == 0) and (a_ChunkZ == -1 or a_ChunkZ == 0)) then
            a_ChunkDesc:FillRelCuboid(0, 15, 128, 128, 0, 15, E_BLOCK_STONE, 0)
        end
    elseif (a_World:GetName() == NETHER_NAME) then
        FillBlocks(a_ChunkDesc)
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

    if (true) then
        LOG("Player spawned at x=" .. a_Player:GetPosX() .. ",y=" .. a_Player:GetPosY() .. ",z=" .. a_Player:GetPosZ() .. " and has existed for " .. a_Player:GetTicksAlive() .. " ticks")
    end

    if (a_Player:GetPosX() == 0 and a_Player:GetPosY() == 0 and a_Player:GetPosZ() == 0) then
        -- player is respawning
        local a_BedPos = a_Player:GetLastBedPos()
        if (a_BedPos.x == 0 and a_BedPos.y == 0 and a_BedPos.z == 0) then
            -- player does not have a bed
            -- find random valid spawn position
            local a_World = a_Player:GetWorld()
            while (true) do
                local x = math.random(-SPAWN_RADIUS, SPAWN_RADIUS)
                local y = math.random(1, 256)
                local z = math.random(-SPAWN_RADIUS, SPAWN_RADIUS)

                local below = a_World:GetBlock(x, y - 1, z)
                local feet = y > 255 and 0 or a_World:GetBlock(x, y, z)
                local head = y > 254 and 0 or a_World:GetBlock(x, y + 1, z)
                if (below ~= E_BLOCK_AIR
                        and below ~= E_BLOCK_FIRE
                        and below ~= E_BLOCK_LAVA
                        and below ~= E_BLOCK_STATIONARY_LAVA
                        and below ~= E_BLOCK_WATER
                        and below ~= E_BLOCK_STATIONARY_WATER
                        and below ~= E_BLOCK_CACTUS
                        and below ~= E_BLOCK_SIGN
                        and feet == 0
                        and head == 0) then
                    a_Player:TeleportToCoords(x + 0.5, y, z + 0.5)

                    -- TODO store player history in a database, to limit the speed of obtaining items
                    local a_Grid = a_Player:GetInventory():GetInventoryGrid()
                    --resources
                    a_Grid:SetSlot(0, 0, cItem(E_ITEM_LAVA_BUCKET, 1));
                    a_Grid:SetSlot(1, 0, cItem(E_BLOCK_ICE, 2));
                    a_Grid:SetSlot(2, 0, cItem(E_BLOCK_SAND, 8));
                    a_Grid:SetSlot(3, 0, cItem(E_BLOCK_DIRT, 8));
                    a_Grid:SetSlot(4, 0, cItem(E_ITEM_FLINT, 1));
                    --food and other growable stuff
                    a_Grid:SetSlot(0, 1, cItem(E_BLOCK_SAPLING, 1));
                    a_Grid:SetSlot(1, 1, cItem(E_ITEM_MELON_SLICE, 1));
                    a_Grid:SetSlot(2, 1, cItem(E_BLOCK_CACTUS, 1));
                    a_Grid:SetSlot(3, 1, cItem(E_BLOCK_BROWN_MUSHROOM, 1));
                    a_Grid:SetSlot(4, 1, cItem(E_BLOCK_RED_MUSHROOM, 1));
                    a_Grid:SetSlot(5, 1, cItem(E_BLOCK_PUMPKIN, 1));
                    a_Grid:SetSlot(6, 1, cItem(E_ITEM_SEEDS, 4));
                    a_Grid:SetSlot(7, 1, cItem(E_ITEM_SUGARCANE, 1));
                    a_Grid:SetSlot(8, 1, cItem(E_ITEM_CARROT, 1));
                    a_Grid:SetSlot(0, 2, cItem(E_ITEM_POTATO, 1));
                    a_Grid:SetSlot(1, 2, cItem(E_ITEM_BONE, 3));
                    return
                end
            end
        end
    end
end

function OnPlayerJoined(a_Player)
    local uuid = a_Player:GetUUID()
    DB:exec("SELECT * FROM skyblock WHERE uuid = '" .. uuid .. "'", function(data, a, b, c)
        LOG("Found data! i=" .. data.started)
        PLAYER_DATA[data.uuid] = data
        return 0
    end)
    if (PLAYER_DATA[uuid] == nil) then
        LOG("Data not found, using default")
        PLAYER_DATA[uuid] = {}
        PLAYER_DATA[uuid].uuid = uuid
        PLAYER_DATA[uuid].started = 0
    end
    LOG("Loaded data for player \"" .. a_Player:GetName() .. "\": " .. PLAYER_DATA[uuid].uuid .. " => " .. PLAYER_DATA[uuid].started)
end

function OnPlayerDestroyed(a_Player)
    local uuid = a_Player:GetUUID()
    local data = PLAYER_DATA[uuid]
    PLAYER_DATA[uuid] = nil
    SUBMIT:bind_names{uuid = data.uuid, started = data.started}
    SUBMIT:step()
    SUBMIT:reset()
    LOG("Saved data for player \"" .. a_Player:GetName() .. "\"!")
end
