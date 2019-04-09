-- simple anti-cheat plugin for cuberite
-- as usual, by DaPorkchop_
-- yeet

NAME = "AntiCheat"
VERSION_NUMBER = 1
VERSION = "v0.0.1-SNAPSHOT"

PLUGIN = nil                      -- plugin instance
LOCAL_FOLDER = nil                -- plugin folder
CONFIG_FILE = nil                 -- config file path

ALL_MODULES = {}
MODULES = {}

function Initialize(Plugin)
    LOG("Loading " .. NAME .. " " .. VERSION .. " (version id " .. VERSION_NUMBER .. ")")

    Plugin:SetName(NAME)
    Plugin:SetVersion(VERSION_NUMBER)

    PLUGIN = Plugin
    LOCAL_FOLDER = PLUGIN:GetLocalFolder()
    CONFIG_FILE = LOCAL_FOLDER .. "/Config.ini"

    LoadLuaFiles() -- load all
    LoadConfiguration()

    -- Register hooks
    cPluginManager:AddHook(cPluginManager.HOOK_PLAYER_SPAWNED, OnPlayerSpawned)
    cPluginManager:AddHook(cPluginManager.HOOK_PLAYER_DESTROYED, OnPlayerDestroyed)

    for _, module in pairs(MODULES) do
        if (module.init ~= nil) then
            module.init()
            LOG("Loaded " .. module.name)
        end
    end

    cRoot:Get():ForEachPlayer(OnPlayerSpawned)

    -- Command Bindings

    LOG(NAME .. " " .. VERSION .. " loaded successfully!")
    return true
end

function OnDisable()
    LOG("Unloading " .. NAME .. " " .. VERSION .. "...")
    for _, module in pairs(MODULES) do
        if (module.shutdown ~= nil) then
            module.shutdown()
        end
    end
end

function LoadConfiguration()
    -- create ini file instance and load it
    local configIni = cIniFile()
    configIni:ReadFile(CONFIG_FILE)

    -- set up comments
    configIni:DeleteHeaderComments()
    for _, module in pairs(ALL_MODULES) do
        configIni:DeleteKeyComments(module.name)
    end
    configIni:AddHeaderComment(" Configuration file for " .. NAME)
    configIni:AddHeaderComment(" Made by DaPorkchop_ for the Team Pepsi Server Network")
    configIni:AddHeaderComment(" https://daporkchop.net")
    configIni:AddHeaderComment(" https://pepsi.team")

    -- read values from config
    for key, module in pairs(ALL_MODULES) do
        if (module.name == nil) then
            module.name = key
        end
        if (configIni:GetValueSetB("Modules", module.name, true)) then
            MODULES[key] = module
        end
        if (module.load ~= nil) then
            module.load(configIni)
        end
    end

    -- sanity check values

    -- save config again
    configIni:WriteFile(CONFIG_FILE)
end

function LoadLuaFiles()
    local files = {
        "/Hooks.lua",
        -- libraries
        "/../lib/porklib.lua"
    }

    for _, file in pairs(files) do
        dofile(LOCAL_FOLDER .. file)
    end

    for _, name in pairs(cFile:GetFolderContents(LOCAL_FOLDER .. "/modules/")) do
        dofile(LOCAL_FOLDER .. "/modules/" .. name)
    end
end
