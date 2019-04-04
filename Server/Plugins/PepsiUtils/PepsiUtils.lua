-- A simple plugin with some various utilities for helping with running the server

NAME = "PepsiUtils"
VERSION_NUMBER = 1
VERSION = "v0.0.1-SNAPSHOT"

PLUGIN = nil
LOCAL_FOLDER = nil
CONFIG_FILE = nil

DISABLE_JOIN_MESSAGE = true
USE_CHAT_PREFIXES = false

function Initialize(Plugin)
    LOG("Loading " .. NAME .. " " .. VERSION .. " (version id " .. VERSION_NUMBER .. ")")

    Plugin:SetName(NAME)
    Plugin:SetVersion(VERSION_NUMBER)

    PLUGIN = Plugin
    LOCAL_FOLDER = PLUGIN:GetLocalFolder()
    CONFIG_FILE = LOCAL_FOLDER .. "/Config.ini"

    LoadLuaFiles() -- load all
    LoadConfiguration()
    LoadServers()

    -- Register hooks
    cPluginManager:AddHook(cPluginManager.HOOK_PLAYER_JOINED, OnPlayerJoined)
    cPluginManager:AddHook(cPluginManager.HOOK_PLAYER_DESTROYED, OnPlayerDestroyed)
    cPluginManager:AddHook(cPluginManager.HOOK_WORLD_STARTED, OnWorldStarted)

    LOG(NAME .. " " .. VERSION .. " loaded successfully!")
    return true
end

function OnDisable()
    LOG("Unloading " .. NAME .. " " .. VERSION .. "...")
end

function LoadConfiguration()
    -- create ini file instance and load it
    local configIni = cIniFile()
    configIni:ReadFile(CONFIG_FILE)

    -- set up comments
    configIni:DeleteHeaderComments()
    configIni:AddHeaderComment(" Configuration file for " .. NAME)
    configIni:AddHeaderComment(" Made by DaPorkchop_ for the Team Pepsi Server Network")
    configIni:AddHeaderComment(" https://daporkchop.net")
    configIni:AddHeaderComment(" https://pepsi.team")
    configIni:AddKeyComment("General", " \"Disable_join_message\" controls whether or not to broadcast player join/leave messages")
    configIni:AddKeyComment("General", " \"Use_chat_prefixes\" controls whether or not to prefix chat messages (e.g. [INFO])")

    -- read values from config
    DISABLE_JOIN_MESSAGE = configIni:GetValueSetB("General", "Disable_join_message", true)
    USE_CHAT_PREFIXES = configIni:GetValueSetB("General", "Use_chat_prefixes", false)

    -- sanity check values

    -- save config again
    configIni:WriteFile(CONFIG_FILE)
end

function LoadLuaFiles()
    local files = {
        "/Hooks.lua",
        "/Servers.lua",
        -- libraries
        "/../lib/porklib.lua"
    }

    for _, file in pairs(files) do
        dofile(PLUGIN:GetLocalFolder() .. file)
    end
end
