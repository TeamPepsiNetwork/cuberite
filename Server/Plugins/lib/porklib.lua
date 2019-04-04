--jeff

dofile(LOCAL_FOLDER .. "/../lib/pork/PMLib.lua")

function BungeeTransferPlayer(a_Player, target, display)
    assert(type(target) == "string", "Target server must be a string!")
    a_Player:SendMessage("§9Connecting to §l" .. (display == nil and target or display) .. "§r§9...")
    a_Player:GetClientHandle():SendPluginMessage(PMLib:new("BungeeCord"):writeUTF("Connect"):writeUTF(target):GetOut())
end
