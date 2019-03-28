CATEGORIES = nil
ITEM_DISPLAY_NAMES = nil
NUMBERED_CATEGORIES = nil
INDEXED_CHALLENGES = nil

GUI_WIDTH = 9
GUI_HEIGHT = 6

function GetSlotIndex(x, y)
    assert(x < 9, "x must be less than 9!")
    assert(y < 9, "y must be less than 9!")
    assert(x >= 0, "x must be greater than or equal to 0!")
    assert(y >= 0, "y must be greater than or equal to 0!")
    return y * GUI_WIDTH + x
end

GUI_NEXT_SLOT = GetSlotIndex(8, 5)
GUI_PREV_SLOT = GetSlotIndex(0, 5)

function LoadChallenges()
    assert(cFile:IsFolder(LOCAL_FOLDER .. "/challenges"), "Not a folder: \"" .. LOCAL_FOLDER .. "/challenges\"!")
    assert(cFile:IsFile(LOCAL_FOLDER .. "/challenges/categories.json"), "Not a file: \"" .. LOCAL_FOLDER .. "/challenges/categories.json\"!")
    CATEGORIES = cJson:Parse(cFile:ReadWholeFile(LOCAL_FOLDER .. "/challenges/categories.json"))
    ITEM_DISPLAY_NAMES = CATEGORIES.names
    CATEGORIES = CATEGORIES.categories
    for _, category in pairs(CATEGORIES) do
        local challenges = {}
        for _, challengeId in pairs(category.challenges) do
            local challenge = cJson:Parse(cFile:ReadWholeFile(LOCAL_FOLDER .. "/challenges/" .. category.id .. "/" .. challengeId .. ".json"))
            challenges[challengeId] = challenge
            challenge.id = challengeId
        end
        category.challenges = challenges
    end
    INDEXED_CHALLENGES = {}
    for _, category in pairs(CATEGORIES) do
        for id, challenge in pairs(category.challenges) do
            local fullId = category.id .. "." .. id
            INDEXED_CHALLENGES[fullId] = challenge
            challenge.fullId = fullId
        end
    end
    local i = 1
    NUMBERED_CATEGORIES = {}
    for categoryId, category in pairs(CATEGORIES) do
        NUMBERED_CATEGORIES[i] = category
        i = i + 1
        local challenges = {} -- copy challenges from category
        for id, challenge in pairs(category.challenges) do
            challenges[id] = challenge
            -- replace challenge stuff with cItem instances
            local tmp = {}
            for key, value in pairs(challenge.needs) do
                tmp[key] = PreParseItem(value)
            end
            challenge.needs = tmp
            tmp = {}
            for key, value in pairs(challenge.rewards) do
                tmp[key] = PreParseItem(value)
            end
            challenge.rewards = tmp
            challenge.display = PreParseItem(challenge.display).realItems[1]
        end
        local counter = 0
        local ordered = {}
        while (TableLength(challenges) > counter) do
            for _, challenge in pairs(challenges) do
                if (not IsChallengeInList(challenge.fullId, ordered) and (challenge.depends == nil or AreAllDependenciesInList(challenge, ordered))) then
                    counter = counter + 1
                    ordered[counter] = challenge
                end
            end
        end
        category.ordered = ordered
    end
end

function AreAllDependenciesInList(challenge, list)
    for _, dep in pairs(challenge.depends) do
        if (not IsChallengeInList(dep, list)) then
            --LOG("Dependency " .. dep .. " not found.")
            return false
        end
    end
    return true
end

function IsChallengeInList(id, list)
    for _, c in pairs(list) do
        if (c.fullId == id) then
            --LOG(id .. " found!")
            return true
        end
    end
    --LOG(id .. " not found.")
    return false
end

function TableLength(T)
    local count = 0
    for _ in pairs(T) do count = count + 1 end
    return count
end

function PreParseItem(desc)
    assert(desc ~= nil, "Parameter is null!")
    assert(type(desc) == "table", "Parameter is not a table: \"" .. type(desc) .. "\"!")
    local id, meta, count
    if (desc.id == nil) then
        error("Id is null!")
    elseif (type(desc.id) == "string") then
        id = desc.id
    elseif (type(desc.id) == "number") then
        id = ItemTypeToString(desc.id)
    else
        error("Unknown type for id: \"" .. type(desc.id) .. "\"!")
    end
    if (desc.meta == nil) then
        meta = 0
    elseif (type(desc.meta) == "number") then
        meta = desc.meta
    else
        error("Unknown type for meta: \"" .. type(desc.meta) .. "\"!")
    end
    if (desc.count == nil) then
        count = 1
    elseif (type(desc.count) == "number") then
        count = desc.count
    else
        error("Unknown type for count: \"" .. type(desc.count) .. "\"!")
    end
    --LOG(count)
    return {
        id = id,
        meta = meta,
        count = count,
        realItems = ParseItems(BlockStringToType(id), meta, count)
    }
end

function ParseItems(id, meta, count)
    local a = {}
    local i = 1
    local c = count
    while (c > 0) do
        local min = math.min(64, c)
        a[i] = cItem(id, min, meta)
        c = c - min
        i = i + 1
    end
    return a
end

function EnsurePlayerdataContainsAllChallenges(playerdata)
    for id, _ in pairs(INDEXED_CHALLENGES) do
        if (playerdata.challenges[id] == nil) then
            playerdata.challenges[id] = 0
        end
    end
end

function ShowChallengeWindowTo(a_Player)
    if (a_Player:GetWindow():GetWindowType() ~= -1) then
        return
    end
    local window = cLuaWindow(cWindow.wtChest, 9, 6, "Challenges")
    local grid = window:GetContents()
    local data = GetPlayerdata(a_Player)
    local pageData = {
        page = 1
    } -- i think i need to keep everything in a table due to passing by value instead of by reference
    local updateWindow = function()
        a_Player:CloseWindow(false)
        if (pageData.page <= 0) then
            pageData.page = #NUMBERED_CATEGORIES
        elseif (pageData.page > #NUMBERED_CATEGORIES) then
            pageData.page = 1
        end
        pageData.category = NUMBERED_CATEGORIES[pageData.page]
        local category = pageData.category
        window:SetWindowTitle("Challenges - " .. category.name)
        grid:Clear()
        grid:SetSlot(GUI_NEXT_SLOT, cItem(E_BLOCK_WOOL, 1, E_META_WOOL_LIGHTGREEN, nil, "§a§lNext page"))
        grid:SetSlot(GUI_PREV_SLOT, cItem(E_BLOCK_WOOL, 1, E_META_WOOL_LIGHTGREEN, nil, "§a§lPrevious page"))
        for id, challenge in pairs(category.ordered) do
            --LOG("Displaying challenge: " .. challenge.fullId)
            --LOG("id=" .. challenge.display.m_ItemType .. ", count=" .. challenge.display.m_ItemCount)
            local displayItem = cItem(challenge.display)
            local usedCount = data.challenges[challenge.fullId]
            assert(usedCount ~= nil, challenge.fullId)
            local lore = {}
            lore[2] = "§7Needed:"
            local i = 3
            for _, item in pairs(challenge.needs) do
                lore[i] = "- " .. ItemDisplayName(item) .. " x" .. item.count
                i = i + 1
            end
            lore[i] = "§7Rewards:"
            i = i + 1
            for _, item in pairs(challenge.rewards) do
                lore[i] = "- " .. ItemDisplayName(item) .. " x" .. item.count
                i = i + 1
            end
            local dependenciesFufilled = true
            if (challenge.depends ~= nil and #challenge.depends > 0) then
                lore[i] = "§7Requires:"
                i = i + 1
                for _, challengeId in pairs(challenge.depends) do
                    local fufilled = data.challenges[challengeId] > 0
                    lore[i] = (fufilled and "§a" or "§c") .. "- " .. INDEXED_CHALLENGES[challengeId].name
                    i = i + 1
                    if (not fufilled) then
                        dependenciesFufilled = false
                    end
                end
            end
            local usable = challenge.usageLimit == -1 or usedCount < challenge.usageLimit
            if (not dependenciesFufilled) then
                displayItem.m_ItemType = E_BLOCK_WOOL
                displayItem.m_ItemDamage = E_META_WOOL_RED
            elseif (not usable) then
                displayItem.m_ItemType = E_BLOCK_IRON_BARS
                displayItem.m_ItemDamage = 0
            end
            displayItem.m_CustomName = (dependenciesFufilled and (usable and "§a" or "§7") or "§c") .. "§l" .. challenge.name
            lore[1] = "§9Remaining uses: " .. (dependenciesFufilled and usable and "§a" or "§7") .. (challenge.usageLimit == -1 and "Unlimited" or (challenge.usageLimit - usedCount) .. "/" .. challenge.usageLimit)
            displayItem.m_LoreTable = lore
            grid:SetSlot(id - 1, displayItem)
        end
        a_Player:OpenWindow(window)
    end
    window:SetOnClicked(function(a_Window, a_Player, a_SlotNum, a_ClickAction, a_ClickedItem)
        --LOG(a_SlotNum)
        if (a_SlotNum < 9 * 6) then
            if (a_SlotNum == GUI_NEXT_SLOT) then
                pageData.page = pageData.page + 1
                updateWindow()
            elseif (a_SlotNum == GUI_PREV_SLOT) then
                pageData.page = pageData.page - 1
                updateWindow()
            elseif (not a_ClickedItem:IsEmpty()) then
                if (a_ClickedItem.m_ItemType == E_BLOCK_WOOL and a_ClickedItem.m_ItemDamage == E_META_WOOL_RED) then
                    a_Player:SendMessage("§cComplete all previous challenges first!")
                elseif (a_ClickedItem.m_ItemType == E_BLOCK_IRON_BARS and a_ClickedItem.m_ItemDamage == 0) then
                    a_Player:SendMessage("§cYou've used this challenge too many times!")
                else
                    local category = pageData.category
                    local challenge = category.ordered[a_SlotNum + 1]
                    if (TryCompleteChallenge(a_Player, challenge)) then
                        updateWindow()
                    end
                end
            end
        end
        if ((a_SlotNum >= 0 and a_SlotNum < 9 * 6) or a_ClickAction == caShiftLeftClick or a_ClickAction == caShiftRightClick) then
            --LOG("Returning true")
            return true
        end
    end)
    updateWindow()
end

function TryCompleteChallenge(a_Player, challenge)
    local inventory = a_Player:GetInventory()
    for _, item in pairs(challenge.needs) do
        --LOG("Checking for item: " .. item.id .. ":" .. item.meta .. " x" .. item.count)
        local count = inventory:HowManyItems(item.realItems[1])
        --LOG("Found " .. count .. " items")
        if (count < item.count) then
            --LOG("Not present!")
            a_Player:SendMessage("§cMissing items: §l" .. ItemDisplayName(item) .. " x" .. (item.count - count))
            return false
        end
    end
    for _, item in pairs(challenge.needs) do
        for _, realItem in pairs(item.realItems) do
            inventory:RemoveItem(realItem)
        end
    end
    for _, item in pairs(challenge.rewards) do
        for _, realItem in pairs(item.realItems) do
            inventory:AddItem(realItem)
        end
    end
    local challengesData = GetPlayerdata(a_Player).challenges
    challengesData[challenge.fullId] = challengesData[challenge.fullId] + 1
    a_Player:SendMessage("§aCompleted challenge: §l" .. challenge.name .. "§r§a!")
    return true
end

function ItemDisplayName(desc)
    local id = desc.id .. (desc.meta == 0 and "" or ":" .. desc.meta)
    local name = ITEM_DISPLAY_NAMES[id]
    return name == nil and id or name
end
