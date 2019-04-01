--jeff

dofile(LOCAL_FOLDER .. "/../lib/PMLib.lua")

function BungeeTransferPlayer(a_Player, target)
    assert(type(target) == "string", "Target server must be a string!")
    a_Player:GetClientHandle():SendPluginMessage(PMLib:new("BungeeCord"):writeUTF("Connect"):writeUTF(target):GetOut())
end
