CATEGORIES = nil
NUMBERED_CATEGORIES = nil

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
    for _, category in pairs(CATEGORIES) do
        local challenges = {}
        for _, challengeId in pairs(category.challenges) do
            local challenge = cJson:Parse(cFile:ReadWholeFile(LOCAL_FOLDER .. "/challenges/" .. category.id .. "/" .. challengeId .. ".json"))
            challenges[challengeId] = challenge
            challenge.id = challengeId
        end
        category.challenges = challenges
    end
    local i = 0
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
        end
        local oldCounter = 0
        local counter = 0
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
    local categories = playerdata.challenges
    for id, category in pairs(CATEGORIES) do
        local challenges = categories[id]
        if (challenges == nil) then
            categories[id] = {}
            challenges = categories[id]
        end
        for subId, challenge in pairs(category.challenges) do
            if (challenges[subId] == nil) then
                challenges[subId] = 0
            end
        end
    end
end

function ShowChallengeWindowTo(a_Player)
    if (a_Player:GetWindow():GetWindowType() ~= -1) then
        return
    end
    local window = cLuaWindow(cWindow.wtChest, 9, 6, "Challenges")
    local data = GetPlayerdata(a_Player)
    local pageData = {
        page = 0
    } -- i think i need to keep everything in a table due to passing by value instead of by reference
    local updateWindow = function()
        a_Player:CloseWindow(false)
        if (pageData.page < 0) then
            pageData.page = #NUMBERED_CATEGORIES
        elseif (pageData.page > #NUMBERED_CATEGORIES) then
            pageData.page = 0
        end
        window:SetWindowTitle("Challenges - " .. NUMBERED_CATEGORIES[pageData.page].name)
        window:GetContents():Clear()
        window:SetSlot(a_Player, GUI_NEXT_SLOT, cItem(E_BLOCK_WOOL, 1, E_META_WOOL_LIGHTGREEN, nil, "§a§lNext page"))
        window:SetSlot(a_Player, GUI_PREV_SLOT, cItem(E_BLOCK_WOOL, 1, E_META_WOOL_LIGHTGREEN, nil, "§a§lPrevious page"))
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
