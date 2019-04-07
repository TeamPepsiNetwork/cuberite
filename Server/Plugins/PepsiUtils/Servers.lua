SERVER_LIST = {}

function LoadServers()
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

function CommandChangeServer(a_Split, a_Player)
    local data = SERVER_LIST[a_Split[1]]
    if (data == nil) then
        a_Player:SendMessage("§cUnknown server: §l" .. a_Split[1])
    else
        BungeeTransferPlayer(a_Player, data.id, data.displayname)
    end
    return true
end
