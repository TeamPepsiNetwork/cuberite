ARENA_BLOCKS = nil
PLAYER_HISTORY = {}
RESET_COUNTER = 0

function OnChunkGenerated(a_World, a_ChunkX, a_ChunkZ, a_ChunkDesc)
    a_ChunkDesc:ReplaceRelCuboid(0, 16, 0, 256, 0, 16, E_BLOCK_AIR, 0, E_BLOCK_BARRIER, 0)
end

function OnPlayerSpawned(a_Player)
    if (a_Player:GetPosX() == 0 and a_Player:GetPosY() == 0 and a_Player:GetPosZ() == 0) then
        -- player is respawning, reset their stuff
        ResetPlayer(a_Player)
    elseif (PLAYER_HISTORY[a_Player:GetUUID()] == nil or PLAYER_HISTORY[a_Player:GetUUID()] ~= RESET_COUNTER) then
        -- the arena has been reset since the last time the player was around
        ResetPlayer(a_Player)
    end
end

function ResetPlayer(a_Player)
    local world = a_Player:GetWorld()
    if (world:GetName() == WORLD_NAME and not TeleportPlayerToRandomPosition(a_Player, a_Player:GetWorld(), 0, 0, ARENA_RADIUS, -1)) then
        a_Player:TeleportToCoords(0.5, 256, 0.5)
    end
    local inv = a_Player:GetInventory()
    -- reset everything
    inv:Clear()
    a_Player:SetMaxHealth(20)
    a_Player:SetHealth(20)
    a_Player:SetFoodLevel(20)
    a_Player:SetFoodSaturationLevel(20)
    a_Player:SetFoodTickTimer(0)
    a_Player:ClearEntityEffects()
    a_Player:SetInvulnerableTicks(40)

    -- default items
    inv:SetHotbarSlot(0, cItem(E_ITEM_DIAMOND_SWORD, 1, 0, "sharpness=5;fireaspect=2;unbreaking=3;knockback=3"))
    inv:SetHotbarSlot(1, cItem(E_ITEM_BOW, 1, 0, "power=5;flame=1;unbreaking=3;knockback=3"))
    inv:SetHotbarSlot(2, cItem(E_ITEM_DIAMOND_PICKAXE, 1, 0, "efficiency=7;unbreaking=3"))
    inv:SetHotbarSlot(3, cItem(E_BLOCK_OBSIDIAN, 64, 0))
    inv:SetHotbarSlot(8, cItem(E_ITEM_GOLDEN_APPLE, 64, E_META_GOLDEN_APPLE_ENCHANTED))
    inv:SetInventorySlot(8, cItem(E_ITEM_ARROW, 64))
    inv:SetArmorSlot(0, cItem(E_ITEM_DIAMOND_HELMET, 1, 0, "unbreaking=3;blastprotection=4"))
    inv:SetArmorSlot(1, cItem(E_ITEM_DIAMOND_CHESTPLATE, 1, 0, "unbreaking=3;blastprotection=4"))
    inv:SetArmorSlot(2, cItem(E_ITEM_DIAMOND_LEGGINGS, 1, 0, "unbreaking=3;blastprotection=4"))
    inv:SetArmorSlot(3, cItem(E_ITEM_DIAMOND_BOOTS, 1, 0, "unbreaking=3;blastprotection=4;featherfalling=4"))
    local colors = {
        E_META_WOOL_WHITE,
        E_META_WOOL_LIGHTBLUE,
        E_META_WOOL_CYAN,
        E_META_WOOL_BLUE,
        E_META_WOOL_RED
    }
    for i = 4, 40 - 1 do
        if (inv:GetSlot(i):IsEmpty()) then
            inv:SetSlot(i, cItem(E_ITEM_BED, 1, colors[math.random(1, #colors)]))
        end
    end
    PLAYER_HISTORY[a_Player:GetUUID()] = RESET_COUNTER
end

function OnPlayerMoving(a_Player, a_OldPos, a_NewPos)
    if (a_Player:GetWorld() == WORLD and (a_NewPos.x > ARENA_RADIUS or a_NewPos.x < -ARENA_RADIUS or a_NewPos.y > 257 or a_NewPos.y < 1 or a_NewPos.z > ARENA_RADIUS or a_NewPos.z < -ARENA_RADIUS) and not a_Player:HasPermission("bedwars.leavearena")) then
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
        QUEUED_RIGHT_CLICKS = {}
    end)
end

function OnKilled(a_Victim, a_Info, a_DeathMessage)
    if (a_Victim:GetWorld() == WORLD and a_Victim:IsPlayer()) then
        if (a_Info.Attacker == nil) then
            -- LOG("Warning: null attacker!")
        elseif (a_Info.Attacker:IsPlayer()) then
            a_Info.Attacker:GetClientHandle():SendSoundEffect("entity.experience_orb.pickup", a_Info.Attacker:GetEyePosition(), 1.0, 63)
            if (a_Info.Attacker ~= a_Victim) then
                KILLS_OBJECTIVE:AddScore(a_Info.Attacker:GetName(), 1)
            end
        end
        KILLS_OBJECTIVE:SubScore(a_Victim:GetName(), 1)
        -- LOG("BedWars: Killed with " .. a_Info.FinalDamage .. " damage from " .. DamageTypeToString(a_Info.DamageType) .. "!")
    end
end
