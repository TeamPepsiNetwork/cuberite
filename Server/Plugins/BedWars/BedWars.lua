-- basically a port of torobedwars to cuberite
-- as usual, by DaPorkchop_
-- yeet

NAME = "BedWars"
VERSION_NUMBER = 1
VERSION = "v0.0.1-SNAPSHOT"

PLUGIN = nil       -- plugin instance
LOCAL_FOLDER = nil -- plugin folder
CONFIG_FILE = nil  -- config file path

WORLD_NAME = nil   -- name of the world

WORLD = nil        -- default world instance

ARENA_RADIUS = 0   -- radius of the arena (in blocks)

function Initialize(Plugin)
    LOG("Loading " .. NAME .. " " .. VERSION .. " (version id " .. VERSION_NUMBER .. ")")

    Plugin:SetName(NAME)
    Plugin:SetVersion(VERSION_NUMBER)

    PLUGIN = Plugin
    LOCAL_FOLDER = PLUGIN:GetLocalFolder()
    CONFIG_FILE = LOCAL_FOLDER .. "/Config.ini"

    LoadLuaFiles() -- load all
    LoadConfiguration()

    WORLD = cRoot:Get():GetWorld(WORLD_NAME)
    if (WORLD == nil) then
        LOGERROR(PLUGIN:GetName() .. " requires the world \"" .. WORLD_NAME .. "\", but it was not found!")
        LOGERROR("Create the world or edit the world name \"Config.ini\".")
        return false
    end
    WORLD:SetSpawn(0, 0, 0)
    PrepareArena()

    -- Register hooks
    cPluginManager:AddHook(cPluginManager.HOOK_PLAYER_SPAWNED, OnPlayerSpawned)
    cPluginManager:AddHook(cPluginManager.HOOK_PLAYER_MOVING, OnPlayerMoving)
    cPluginManager:AddHook(cPluginManager.HOOK_PLAYER_BREAKING_BLOCK, OnPlayerBreakingBlock)

    -- Command Bindings
    cPluginManager:BindCommand("/resetarena", "bedwars.reset", function(a_Split, a_Player)
        ResetArena(WORLD)
        a_Player:SendMessage("§a§lArena reset!")
        return true
    end, "§6- Reset BedWars arena")

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
    configIni:DeleteKeyComments("Worlds")
    configIni:DeleteKeyComments("Arenas")
    configIni:AddHeaderComment(" Configuration file for " .. NAME)
    configIni:AddHeaderComment(" Made by DaPorkchop_ for the Team Pepsi Server Network")
    configIni:AddHeaderComment(" https://daporkchop.net")
    configIni:AddHeaderComment(" https://pepsi.team")
    configIni:AddKeyComment("Worlds", " \"World_name\" is the name of the world that will be used as the lobby world")
    configIni:AddKeyComment("Arenas", " \"Arena_radius\" is the radius of the arena")

    -- read values from config
    WORLD_NAME = configIni:GetValueSet("Worlds", "World_name", "world_nether")
    ARENA_RADIUS = configIni:GetValueSetI("Arenas", "Arena_radius", 32)

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
        dofile(PLUGIN:GetLocalFolder() .. file)
    end
end
