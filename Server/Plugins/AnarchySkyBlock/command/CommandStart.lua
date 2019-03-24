STARTER_ITEMS = cItems()
START_COOLDOWN = 0

function CommandStart(a_Split, a_Player)
    if (STARTER_ITEMS:Size() == 0) then
        -- set starter items
        -- TODO: all commented items: make these into challenges

        -- resources
        STARTER_ITEMS:Add(cItem(E_ITEM_LAVA_BUCKET, 1))
        STARTER_ITEMS:Add(cItem(E_BLOCK_ICE, 2))
        --STARTER_ITEMS:Add(cItem(E_BLOCK_SAND, 8))
        STARTER_ITEMS:Add(cItem(E_BLOCK_DIRT, 8))
        --STARTER_ITEMS:Add(cItem(E_ITEM_FLINT, 1))

        -- food and other growable stuff
        STARTER_ITEMS:Add(cItem(E_BLOCK_SAPLING, 1))
        --STARTER_ITEMS:Add(cItem(E_ITEM_MELON_SLICE, 1))
        --STARTER_ITEMS:Add(cItem(E_BLOCK_CACTUS, 1))
        --STARTER_ITEMS:Add(cItem(E_BLOCK_BROWN_MUSHROOM, 1))
        --STARTER_ITEMS:Add(cItem(E_BLOCK_RED_MUSHROOM, 1))
        --STARTER_ITEMS:Add(cItem(E_BLOCK_PUMPKIN, 1))
        --STARTER_ITEMS:Add(cItem(E_ITEM_SEEDS, 4))
        --STARTER_ITEMS:Add(cItem(E_ITEM_SUGARCANE, 1))
        STARTER_ITEMS:Add(cItem(E_ITEM_CARROT, 1))
        STARTER_ITEMS:Add(cItem(E_ITEM_POTATO, 1))
        STARTER_ITEMS:Add(cItem(E_ITEM_BONE, 3))
    end

    local data = GetPlayerdata(a_Player)
    local age = WORLD:GetWorldAge()
    if (data.startTime + START_COOLDOWN > age) then
        local remaining = (data.startTime + START_COOLDOWN - age) / 20
        a_Player:SendMessage("§cYou can't do that for " .. (remaining / 86400) .. "d:" .. ((remaining / 3600) % 24) .. "h:" .. ((remaining / 60) % 60) .. "m:" .. (remaining % 60) .. "s")
    elseif (#a_Split ~= 2 or a_Split[2] ~= "confirm") then
        a_Player:SendMessage("§9This will reset all your challenges, and you will not be able to restart again for another 1 day(s).")
        a_Player:SendMessage("§9Are you sure you want to restart?")
        a_Player:SendMessage("§9Type §l/start confirm§r§9 to confirm.")
    else
        a_Player:GetWorld():SpawnItemPickups(STARTER_ITEMS, a_Player:GetPosX(), a_Player:GetPosY(), a_Player:GetPosZ(), 0, false)
        a_Player:SendMessage("§aWelcome to AnarchySkyBlock!")
        -- TODO: reset challenges
        data.startTime = age
    end
    return true
end
