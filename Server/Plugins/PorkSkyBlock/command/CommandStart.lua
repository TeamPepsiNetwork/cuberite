STARTER_ITEMS = nil
START_COOLDOWN = 0

function LoadStarterItems()
    STARTER_ITEMS = cItems()
    -- set starter items based on config
    assert(cFile:IsFile(LOCAL_FOLDER .. "/startitems.json"), "Not a file: \"" .. LOCAL_FOLDER .. "/startitems.json\"!")
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
        data.startTime = age
        data.challenges = {}
        EnsurePlayerdataContainsAllChallenges(data)
        a_Player:GetWorld():SpawnItemPickups(STARTER_ITEMS, a_Player:GetPosX(), a_Player:GetPosY(), a_Player:GetPosZ(), 0, false)
        a_Player:SendMessage("§aWelcome to " .. INSTANCE_NAME .. "!")
    end
    return true
end
