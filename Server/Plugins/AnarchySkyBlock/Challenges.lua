CHALLENGES = nil

function LoadChallenges()
    CHALLENGES = {}
    local count = 0
    if (cFile:IsFolder(LOCAL_FOLDER .. "/challenges")) then
        local files = cFile:GetFolderContents(LOCAL_FOLDER .. "/challenges")
        for _, fileName in pairs(files) do
            local challenge = cJson:Parse(cFile:ReadWholeFile(LOCAL_FOLDER .. "/challenges/" .. fileName))
            local realId = ReplaceString(fileName, ".json", "")
            if (challenge.id == nil) then
                challenge.id = realId
            elseif (challenge.id ~= realId) then
                LOGWARNING("Challenge \"" .. realId .. "\" has wrong id!")
                challenge.id = realId
            end
            CHALLENGES[challenge.id] = challenge
            count = count + 1
        end
    end
    LOG("Loaded " .. count .. " challenges!")
end

function EnsurePlayerdataContainsAllChallenges(playerdata)
    local dataChallenges = playerdata.challenges
    for id, _ in pairs(CHALLENGES) do
        if (dataChallenges[id] == nil) then
            dataChallenges[id] = false
        end
    end
end

function ShowChallengeWindowTo(a_Player)
    if (a_Player:GetInventory():GetWindowType() ~= -1) then
        return
    end
    local a_Window = cWindow(cWindow.wtChest, 9, 6, "Challenges")
    local data = GetPlayerdata(a_Player)
    local pageX = 0
    local pageY = 0
    local pageData = {}
    local updateWindow = function() end
    window:SetOnClicked(function(a_Window, a_Player, a_SlotNum, a_ClickAction, a_ClickedItem)
        return true -- returning true cancels the event
    end)
    a_Player:OpenWindow(a_Window)
end
