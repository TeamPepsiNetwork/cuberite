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
GUI_TOGGLE_USED_CHALLENGES = GetSlotIndex(2, 5)
GUI_TOGGLE_INACCESSIBLE_CHALLENGES = GetSlotIndex(3, 5)

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
            challenge.categoryId = category.id
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
        local realCounter = 0
        local realOrdered = {}
        local passNumber = 0
        while (TableLength(challenges) > realCounter) do
            for _, challenge in pairs(challenges) do
                if (not IsChallengeInList(challenge.fullId, realOrdered) and not (passNumber == 0 and challenge.depends ~= nil and #challenge.depends > 0) and (challenge.depends == nil or AreAllDependenciesInList(challenge, realOrdered))) then
                    counter = counter + 1
                    ordered[counter] = challenge
                end
            end
            for _, challenge in pairs(ordered) do
                realCounter = realCounter + 1
                realOrdered[realCounter] = challenge
            end
            counter = 0
            ordered = {}
            passNumber = passNumber + 1
        end
        category.ordered = realOrdered
    end
end

function AreAllDependenciesInList(challenge, list)
    for _, dep in pairs(challenge.depends) do
        if (string.find(dep, challenge.categoryId) ~= nil and not IsChallengeInList(dep, list)) then
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
    for _ in pairs(T) do
        count = count + 1
    end
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
        page = 1,
        challenges = {}
    } -- i think i need to keep everything in a table due to passing by value instead of by reference
    local updateWindow = function(force)
        if (not force and a_Player:GetWindow():GetWindowTitle() ~= window:GetWindowTitle()) then
            --LOG("Forcing gui refresh... Current GUI is named: \"" .. a_Player:GetWindow():GetWindowTitle() .. "\"")
            force = true
        end
        --LOG("Full GUI refresh: " .. (force and "true" or "false"))
        if (force) then
            a_Player:CloseWindow(false)
        end
        if (pageData.page <= 0) then
            pageData.page = #NUMBERED_CATEGORIES
        elseif (pageData.page > #NUMBERED_CATEGORIES) then
            pageData.page = 1
        end
        pageData.category = NUMBERED_CATEGORIES[pageData.page]
        local category = pageData.category
        window:SetWindowTitle("Challenges - " .. category.name)
        grid:Clear()
        grid:SetSlot(GUI_NEXT_SLOT, cItem(E_BLOCK_WOOL, 1, E_META_WOOL_LIGHTBLUE, nil, "§a§lNext page"))
        grid:SetSlot(GUI_PREV_SLOT, cItem(E_BLOCK_WOOL, 1, E_META_WOOL_LIGHTBLUE, nil, "§a§lPrevious page"))
        if (true) then
            local item = cItem(E_BLOCK_WOOL, 1, data.challengeGui.showUsed and E_META_WOOL_LIGHTGREEN or E_META_WOOL_RED)
            item.m_CustomName = "§9§lDisplay used challenges"
            item.m_LoreTable = {
                "Toggles whether or not challenges with no remaining uses will be displayed.",
                "Current state: " .. (data.challengeGui.showUsed and "§a§lEnabled" or "§c§lDisabled")
            }
            grid:SetSlot(GUI_TOGGLE_USED_CHALLENGES, item)
        end
        if (true) then
            local item = cItem(E_BLOCK_WOOL, 1, data.challengeGui.showInaccessible and E_META_WOOL_LIGHTGREEN or E_META_WOOL_RED)
            item.m_CustomName = "§9§lDisplay inaccessible challenges"
            item.m_LoreTable = {
                "Toggles whether or not challenges whose requirements have not yet been satisfied will be displayed.",
                "Current state: " .. (data.challengeGui.showInaccessible and "§a§lEnabled" or "§c§lDisabled")
            }
            grid:SetSlot(GUI_TOGGLE_INACCESSIBLE_CHALLENGES, item)
        end
        local slot = 0
        pageData.challenges = {}
        for _, challenge in pairs(category.ordered) do
            --LOG("Displaying challenge: " .. challenge.fullId)
            --LOG("id=" .. challenge.display.m_ItemType .. ", count=" .. challenge.display.m_ItemCount)
            local displayItem = cItem(challenge.display)
            local usedCount = data.challenges[challenge.fullId]
            assert(usedCount ~= nil, challenge.fullId)

            local secret = challenge.secret == nil and false or challenge.secret
            local lore = {}
            local loreIndex = secret and 1 or 3
            if (challenge.info ~= nil) then
                for _, line in pairs(challenge.info) do
                    lore[loreIndex] = line
                    loreIndex = loreIndex + 1
                end
                lore[loreIndex] = ""
                loreIndex = loreIndex + 1
            end
            if (not secret) then
                lore[loreIndex] = "§7Needed:"
                loreIndex = loreIndex + 1
                for _, item in pairs(challenge.needs) do
                    lore[loreIndex] = "- " .. ItemDisplayName(item) .. " x" .. item.count
                    loreIndex = loreIndex + 1
                end
                lore[loreIndex] = "§7Rewards:"
                loreIndex = loreIndex + 1
                for _, item in pairs(challenge.rewards) do
                    lore[loreIndex] = "- " .. ItemDisplayName(item) .. " x" .. item.count
                    loreIndex = loreIndex + 1
                end
            end
            local dependenciesFufilled = true
            if (challenge.depends ~= nil and #challenge.depends > 0) then
                lore[loreIndex] = "§7Requires:"
                loreIndex = loreIndex + 1
                for _, challengeId in pairs(challenge.depends) do
                    local fufilled = data.challenges[challengeId] > 0
                    lore[loreIndex] = (fufilled and "§a" or "§c") .. "- " .. INDEXED_CHALLENGES[challengeId].name
                    loreIndex = loreIndex + 1
                    if (not fufilled) then
                        dependenciesFufilled = false
                    end
                end
            end
            local usable = challenge.usageLimit == -1 or usedCount < challenge.usageLimit
            --LOG("Usable: " .. (usable and "true" or "false") .. ", showUsed: " .. (data.challengeGui.showUsed == nil and "null" or (data.challengeGui.showUsed and "true" or "false")))
            local display = true
            if (not usable and not data.challengeGui.showUsed) then
                display = false
            elseif (not dependenciesFufilled and not data.challengeGui.showInaccessible) then
                display = false
            end
            if (display) then
                if (not dependenciesFufilled) then
                    displayItem.m_ItemType = E_BLOCK_BARRIER
                    displayItem.m_ItemDamage = 0
                    displayItem.m_ItemCount = 1
                --elseif (not usable) then
                --    displayItem.m_ItemType = E_BLOCK_IRON_BARS
                --    displayItem.m_ItemDamage = 0
                --    displayItem.m_ItemCount = 1
                end
                displayItem.m_CustomName = (dependenciesFufilled and (usable and "§a" or "§7") or "§c") .. "§l" .. challenge.name
                if (not secret) then
                    lore[1] = "§9Remaining uses: " .. (dependenciesFufilled and usable and "§a" or "§7") .. (challenge.usageLimit == -1 and "Unlimited" or (challenge.usageLimit - usedCount) .. "/" .. challenge.usageLimit)
                    lore[2] = "§9Times used: " .. (usedCount > 0 and "§a" or "§7") .. usedCount
                end
                displayItem.m_LoreTable = lore
                grid:SetSlot(slot, displayItem)
                slot = slot + 1
                pageData.challenges[slot] = challenge
            end
        end
        if (force) then
            a_Player:OpenWindow(window)
        end
    end
    window:SetOnClicked(function(a_Window, a_Player, a_SlotNum, a_ClickAction, a_ClickedItem)
        --LOG(a_SlotNum)
        if (a_SlotNum < 9 * 6) then
            if (a_SlotNum == GUI_NEXT_SLOT) then
                pageData.page = pageData.page + 1
                updateWindow(true)
            elseif (a_SlotNum == GUI_PREV_SLOT) then
                pageData.page = pageData.page - 1
                updateWindow(true)
            elseif (a_SlotNum == GUI_TOGGLE_USED_CHALLENGES) then
                data.challengeGui.showUsed = not data.challengeGui.showUsed
                updateWindow(false)
            elseif (a_SlotNum == GUI_TOGGLE_INACCESSIBLE_CHALLENGES) then
                data.challengeGui.showInaccessible = not data.challengeGui.showInaccessible
                --LOG("showInaccessible=" .. (data.challengeGui.showInaccessible and "true" or "false"))
                updateWindow(false)
            elseif (not a_ClickedItem:IsEmpty()) then
                if (a_ClickedItem.m_ItemType == E_BLOCK_BARRIER and a_ClickedItem.m_ItemDamage == 0) then
                    a_Player:SendMessage("§cComplete all previous challenges first!")
                --elseif (a_ClickedItem.m_ItemType == E_BLOCK_IRON_BARS and a_ClickedItem.m_ItemDamage == 0) then
                --    a_Player:SendMessage("§cYou've used this challenge too many times!")
                else
                    --local category = pageData.category
                    local challenge = pageData.challenges[a_SlotNum + 1]
                    if (TryCompleteChallenge(a_Player, challenge)) then
                        updateWindow(false)
                    end
                end
            end
        end
        if ((a_SlotNum >= 0 and a_SlotNum < 9 * 6) or a_ClickAction == caShiftLeftClick or a_ClickAction == caShiftRightClick) then
            --LOG("Returning true")
            return true
        end
    end)
    updateWindow(true)
end

function TryCompleteChallenge(a_Player, challenge, silent)
    local challengesData = GetPlayerdata(a_Player).challenges
    local usable = challenge.usageLimit == -1 or challengesData[challenge.fullId] < challenge.usageLimit
    if (not usable) then
        a_Player:SendMessage("§cYou've used this challenge too many times!")
        return false
    end
    if (challenge.secret and silent == false) then
        a_Player:SendMessage("§cThis challenge cannot be completed via the menu!")
        return false
    end
    local inventory = a_Player:GetInventory()
    for _, item in pairs(challenge.needs) do
        --LOG("Checking for item: " .. item.id .. ":" .. item.meta .. " x" .. item.count)
        local count = inventory:HowManyItems(item.realItems[1])
        --LOG("Found " .. count .. " items")
        if (count < item.count) then
            --LOG("Not present!")
            if (silent == nil and true or silent) then
                a_Player:SendMessage("§cMissing items: §l" .. ItemDisplayName(item) .. " x" .. (item.count - count))
            end
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
    challengesData[challenge.fullId] = challengesData[challenge.fullId] + 1
    a_Player:SendMessage("§aCompleted challenge: §l" .. challenge.name .. "§r§a!")
    return true
end

function ItemDisplayName(desc)
    local id = desc.id .. (desc.meta == 0 and "" or ":" .. desc.meta)
    local name = ITEM_DISPLAY_NAMES[id]
    return name == nil and id or name
end
