STARTER_ITEMS = nil
START_COOLDOWN = 0

function LoadStarterItems()
    STARTER_ITEMS = cItems()
    if (false) then
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
    else
        -- also set starter items, but based on config
        if (cFile:IsFile(LOCAL_FOLDER .. "/startitems.json")) then
            local i = 0
            local startItems = cJson:Parse(cFile:ReadWholeFile(LOCAL_FOLDER .. "/startitems.json"))
            for _, item in pairs(startItems) do
                if (item.id ~= nil) then
                    local type = BlockStringToType(item.id)
                    local meta = item.meta == nil and 0 or item.meta
                    local count = item.count == nil and 1 or item.count
                    STARTER_ITEMS:Add(cItem(type, count, meta))
                    i = i + 1
                end
            end
            LOG("Loaded " .. i .. " starter items!")
        end
    end
end

function CommandStart(a_Split, a_Player)
    local data = GetPlayerdata(a_Player)
    local age = WORLD:GetWorldAge()
    if (data.startTime + START_COOLDOWN > age) then
        a_Player:SendMessage("§cYou can't do that for " .. GetCooldownString(a_Player))
    elseif (#a_Split ~= 2 or a_Split[2] ~= "confirm") then
        if (data.startTime == 0) then
            a_Player:SendMessage("§9You will not be able to restart again for another " .. GetCooldownStringFromRemaining(START_COOLDOWN) .. ".")
        else
            a_Player:SendMessage("§9This will reset all your challenges, and you will not be able to restart again for another " .. GetCooldownStringFromRemaining(START_COOLDOWN) .. ".")
        end
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
