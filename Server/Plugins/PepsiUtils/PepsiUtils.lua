-- A simple plugin with some various utilities for helping with running the server

NAME = "PepsiUtils"
VERSION_NUMBER = 1
VERSION = "v0.0.1-SNAPSHOT"

PLUGIN = nil
LOCAL_FOLDER = nil
CONFIG_FILE = nil

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
    LoadExternData()

    -- Register hooks
    cPluginManager:AddHook(cPluginManager.HOOK_WORLD_STARTED, OnWorldStarted)
    cPluginManager:AddHook(cPluginManager.HOOK_PLAYER_JOINED, OnPlayerJoined)

    cPluginManager:AddHook(cPluginManager.HOOK_PLAYER_USING_BLOCK, OnPlayerUsingBlock)
    cPluginManager:AddHook(cPluginManager.HOOK_EXPLODING, OnExploding)
    cPluginManager:AddHook(cPluginManager.HOOK_EXPLODED, OnExploded)
    cPluginManager:AddHook(cPluginManager.HOOK_TAKE_DAMAGE, OnTakeDamage)
    cPluginManager:AddHook(cPluginManager.HOOK_KILLED, OnKilled)
    cPluginManager:AddHook(cPluginManager.HOOK_WORLD_TICK, OnWorldTick)

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
    configIni:AddKeyComment("General", " \"Use_chat_prefixes\" controls whether or not to prefix chat messages (e.g. [INFO])")

    -- read values from config
    USE_CHAT_PREFIXES = configIni:GetValueSetB("General", "Use_chat_prefixes", false)

    -- sanity check values

    -- save config again
    configIni:WriteFile(CONFIG_FILE)
end

function LoadLuaFiles()
    local files = {
        "/DamageOverrideHooks.lua",
        "/ExternData.lua",
        "/Hooks.lua",
        -- libraries
        "/../lib/porklib.lua"
    }

    for _, file in pairs(files) do
        dofile(PLUGIN:GetLocalFolder() .. file)
    end
end
