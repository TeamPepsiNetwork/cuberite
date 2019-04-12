SERVER_LIST = {}
RANK_LOOKUP = {}

function LoadExternData()
    LoadServers()
    LoadPlayers()
end

function LoadServers()
    cPluginManager:BindCommand("/transfer", "pepsiutils.transfer", CommandTransfer, "")
    cPluginManager:BindConsoleCommand("transfer", ConsoleCommandTransfer, "")
    cUrlClient:Get("https://gist.githubusercontent.com/DaMatrix/8b7ff92fcc7e49c0f511a8ed207d8e92/raw/teampepsi-server-list.json",
            function(a_Body, a_Data)
                if (a_Body) then
                    local tempList = cJson:Parse(a_Body)
                    for id, data in pairs(tempList) do
                        SERVER_LIST[id] = data
                        SERVER_LIST["/" .. id] = data
                        data.id = id
                        local aliasesString = nil
                        for _, alias in pairs(data.aliases) do
                            if (id ~= alias) then
                                if (SERVER_LIST[alias] ~= nil or SERVER_LIST["/" .. alias] ~= nil) then
                                    LOGERROR("Duplicate server alias: " .. alias)
                                else
                                    SERVER_LIST[alias] = data
                                    SERVER_LIST["/" .. alias] = data
                                end
                                --cPluginManager:BindCommand("/" .. alias, data.public and "core.help" or "core.ban", CommandChangeServer, "§7 - Warp to §l" .. data.displayname)
                                cPluginManager:BindCommand("/" .. alias, data.public and "core.help" or "pepsiutils.transfer." .. id, CommandChangeServer, "")
                                if (aliasesString == nil) then
                                    aliasesString = "/" .. alias
                                else
                                    aliasesString = aliasesString .. ", /" .. alias
                                end
                            end
                        end
                        cPluginManager:BindCommand("/" .. id, data.public and "core.help" or "pepsiutils.transfer." .. id, CommandChangeServer, "§7 - Warp to §l" .. data.displayname .. (aliasesString == nil and "" or ("§r§7 (aliases: " .. aliasesString .. ")")))
                    end
                else
                    LOGERROR("Unable to fetch server list!!!")
                    LOGERROR(a_Data)
                end
            end)
end

function LoadPlayers()
    cUrlClient:Get("https://gist.githubusercontent.com/DaMatrix/8b7ff92fcc7e49c0f511a8ed207d8e92/raw/teampepsi-server-players.json",
            function(a_Body, a_Data)
                if (a_Body) then
                    local tempList = cJson:Parse(a_Body)
                    for _, data in pairs(tempList) do
                        if (#data.name > 0) then
                            --cRankManager:RemoveRank(data.name)
                            cRankManager:AddRank(data.name, "", "", data.prefix)
                            cRankManager:SetRankVisuals(data.name, "", "", data.prefix)
                            cRankManager:AddGroupToRank(data.name == "Admin" and "Everything" or "Default", data.name)
                            for _, uuid in pairs(data.members) do
                                --aUUID:FromString(uuid)
                                --cRankManager:SetPlayerRank(uuid, cMojangAPI:GetPlayerNameFromUUID(uuid), data.name)
                                --cRankManager:SetPlayerRank(uuid, "jeff", data.name)
                                --LOG("Fetching name for " .. uuid .. "...")
                                --LOG(uuid .. " => " .. cMojangAPI:GetPlayerNameFromUUID(aUUID))
                                RANK_LOOKUP[cMojangAPI:MakeUUIDShort(uuid)] = data.name
                                cRoot:Get():DoWithPlayerByUUID(uuid, OnPlayerJoined)
                            end
                        end
                    end
                else
                    LOGERROR("Unable to fetch server list!!!")
                    LOGERROR(a_Data)
                end
            end)
end

function CommandChangeServer(a_Split, a_Player)
    local data = SERVER_LIST[a_Split[1]]
    if (data == nil) then
        a_Player:SendMessage("§cUnknown server: §l" .. a_Split[1])
    else
        BungeeTransferPlayer(a_Player, data.id, data.displayname)
    end
    return true
end

function CommandTransfer(a_Split, a_Player)
    if (#a_Split ~= 3) then
        if (a_Player == nil) then
            LOGERROR("Usage: /transfer <player> <destination>")
        else
            a_Player:SendMessage("§cUsage: §l/transfer <player> <destination>")
        end
        return false
    end
    local data = SERVER_LIST[a_Split[3]]
    if (data == nil) then
        if (a_Player == nil) then
            LOGERROR("Unknown server: " .. a_Split[3])
        else
            a_Player:SendMessage("§cUnknown server: " .. a_Split[3])
        end
        return false
    elseif (not cRoot:Get():FindAndDoWithPlayer(a_Split[2], function(a_Player)
        BungeeTransferPlayer(a_Player, data.id, data.displayname)
    end)) then
        if (a_Player == nil) then
            LOGERROR("Unknown player: " .. a_Split[2])
        else
            a_Player:SendMessage("§cUnknown player: " .. a_Split[2])
        end
        return false
    end
    if (a_Player ~= nil) then
        a_Player:SendMessage("§9Transferred §l" .. a_Split[2] .. "§r§9 to §l" .. a_Split[2] .. "§r§9!")
    end
    return true
end

function ConsoleCommandTransfer(a_Split)
    return CommandTransfer(a_Split, nil)
end
