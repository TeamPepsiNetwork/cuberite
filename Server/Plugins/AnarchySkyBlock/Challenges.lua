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
                tmp[key] = ParseItem(value)
            end
            challenge.needs = tmp
            tmp = {}
            for key, value in pairs(challenge.rewards) do
                tmp[key] = ParseItem(value)
            end
            challenge.rewards = tmp
            challenge.display = ParseItem(challenge.display)
        end
        local oldCounter = 0
        local counter = 1
        local ordered = {}
        while (#challenges ~= 0) do
            for _, challenge in pairs(challenges) do
                if (challenge.depends == nil or #challenge.depends == 0 or IsChallengeInList(challenge.id, ordered)) then
                    ordered[counter] = challenge
                    counter = counter + 1
                end
            end
            if (oldCounter == counter) then
                -- safeguard against infinite loop by skipping if we do a full cycle without adding any challenges
                break
            else
                oldCounter = counter
            end
        end
        for _, challenge in pairs(challenges) do
            ordered[counter] = challenge
            counter = counter + 1
        end
        category.ordered = ordered
    end
    INDEXED_CHALLENGES = {}
    for categoryId, category in pairs(CATEGORIES) do
        for id, challenge in pairs(category.challenges) do
            local fullId = categoryId .. "." .. id
            INDEXED_CHALLENGES[fullId] = challenge
            challenge.fullId = fullId
        end
    end
end

function IsChallengeInList(id, list)
    for _, c in pairs(list) do
        if (c.id == id) then
            return true
        end
    end
    return false
end

function ParseItem(desc)
    assert(desc ~= nil, "Parameter is null!")
    assert(type(desc) == "table", "Parameter is not a table: \"" .. type(desc) .. "\"!")
    local id, meta, count
    if (desc.id == nil) then
        error("Id is null!")
    elseif (type(desc.id) == "string") then
        id = BlockStringToType(desc.id)
    elseif (type(desc.id) == "number") then
        id = desc.id
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
    return cItem(id, count, meta)
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
            local displayItem = cItem(challenge.display)
            local usedCount = data.challenges[challenge.fullId]
            assert(usedCount ~= nil, challenge.fullId)
            local lore = {}
            lore[2] = "§7Needed:"
            local i = 3
            for _, item in pairs(challenge.needs) do
                lore[i] = "- " .. ItemDisplayName(item) .. " x" .. item.m_ItemCount
                i = i + 1
            end
            lore[i] = "§7Rewards:"
            i = i + 1
            for _, item in pairs(challenge.rewards) do
                lore[i] = "- " .. ItemDisplayName(item) .. " x" .. item.m_ItemCount
                i = i + 1
            end
            local dependenciesFufilled = true
            if (#challenge.depends > 0) then
                lore[i] = "§7Requires:"
                i = i + 1
                for _, challengeId in pairs(challenge.depends) do
                    local fufilled = data.challenge[challengeId] > 0
                    lore[i] = (fufilled and "§a" or "§c") .. "- " .. INDEXED_CHALLENGES[challengeId]
                    i = i + 1
                    if (not fufilled) then
                        dependenciesFufilled = false
                    end
                end
            end
            local usable = usedCount < challenge.usageLimit
            if (not dependenciesFufilled) then
                displayItem.m_ItemType = E_BLOCK_WOOL
                displayItem.m_ItemDamage = E_META_WOOL_RED
            elseif (not usable) then
                displayItem.m_ItemType = E_BLOCK_GLASS_PANE
                displayItem.m_ItemDamage = E_META_STAINED_GLASS_PANE_GRAY
            end
            displayItem.m_CustomName = (dependenciesFufilled and (usable and "§a" or "§7") or "§c") .. "§l" .. challenge.name
            lore[1] = "§9Remaining uses: " .. (usable and "§a" or "§7") .. (challenge.usageLimit - usedCount) .. "/" .. challenge.usageLimit
            displayItem.m_LoreTable = lore
            grid:SetSlot(id - 1, displayItem)
        end
        a_Player:OpenWindow(window)
    end
    window:SetOnClicked(function(a_Window, a_Player, a_SlotNum, a_ClickAction, a_ClickedItem)
        if (a_SlotNum == GUI_NEXT_SLOT) then
            pageData.page = pageData.page + 1
            updateWindow()
        elseif (a_SlotNum == GUI_PREV_SLOT) then
            pageData.page = pageData.page - 1
            updateWindow()
        end
        return true -- returning true cancels the event
    end)
    updateWindow()
end

function ItemDisplayName(a_Item)
    local name = ITEM_DISPLAY_NAMES[ItemToString(a_Item)]
    return name == nil and ItemToString(a_Item) or name
end
