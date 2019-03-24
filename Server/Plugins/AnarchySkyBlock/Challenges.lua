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
