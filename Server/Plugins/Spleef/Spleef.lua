-- simple spleef plugin for cuberite
-- as usual, by DaPorkchop_
-- yeet

NAME = "Spleef"
VERSION_NUMBER = 1
VERSION = "v0.0.1-SNAPSHOT"

PLUGIN = nil                      -- plugin instance
LOCAL_FOLDER = nil                -- plugin folder
CONFIG_FILE = nil                 -- config file path

WORLD_NAME = nil                  -- name of the world

WORLD = nil                       -- default world instance

SCOREBOARD = nil                  -- the Scoreboard instance for the world
WINS_OBJECTIVE_NAME = "wins"      -- the name of the win counter objective
KILLS_OBJECTIVE_NAME = "kills"    -- the name of the kill counter objective
WINS_OBJECTIVE = nil              -- the win counter objective
KILLS_OBJECTIVE = nil             -- the kill counter objective

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
    for x = -3, 3 do
        for z = -3, 3 do
            WORLD:SetChunkAlwaysTicked(x, z, true)
        end
    end
    PrepareArena()

    SCOREBOARD = WORLD:GetScoreBoard()
    KILLS_OBJECTIVE = SCOREBOARD:GetObjective(KILLS_OBJECTIVE_NAME)
    if (KILLS_OBJECTIVE == nil) then
        KILLS_OBJECTIVE = SCOREBOARD:RegisterObjective(KILLS_OBJECTIVE_NAME, "jeff", cObjective.otStat)
        assert(KILLS_OBJECTIVE ~= nil, "Unable to register kills objective!")
    end
    KILLS_OBJECTIVE:SetDisplayName("§9§lKills§r")
    --SCOREBOARD:SetDisplay(KILLS_OBJECTIVE_NAME, cScoreboard.dsSidebar)

    WINS_OBJECTIVE = SCOREBOARD:GetObjective(WINS_OBJECTIVE_NAME)
    if (WINS_OBJECTIVE == nil) then
        WINS_OBJECTIVE = SCOREBOARD:RegisterObjective(WINS_OBJECTIVE_NAME, "jeff", cObjective.otStat)
        assert(WINS_OBJECTIVE ~= nil, "Unable to register kills objective!")
    end
    WINS_OBJECTIVE:SetDisplayName("§9§lWins§r")
    SCOREBOARD:SetDisplay(WINS_OBJECTIVE_NAME, cScoreboard.dsList)

    SCOREBOARD:SetDisplay(WINS_OBJECTIVE_NAME, cScoreboard.dsSidebar) --temp

    -- Register hooks
    cPluginManager:AddHook(cPluginManager.HOOK_PLAYER_SPAWNED, OnPlayerSpawned)
    cPluginManager:AddHook(cPluginManager.HOOK_PLAYER_DESTROYED, OnPlayerDestroyed)
    cPluginManager:AddHook(cPluginManager.HOOK_PLAYER_MOVING, OnPlayerMoving)
    cPluginManager:AddHook(cPluginManager.HOOK_PLAYER_BREAKING_BLOCK, OnPlayerBreakingBlock)
    cPluginManager:AddHook(cPluginManager.HOOK_CHUNK_GENERATED, OnChunkGenerated)
    cPluginManager:AddHook(cPluginManager.HOOK_WORLD_TICK, OnWorldTick)
    cPluginManager:AddHook(cPluginManager.HOOK_ENTITY_CHANGED_WORLD, OnEntityChangedWorld)

    -- Command Bindings

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
    configIni:AddHeaderComment(" Configuration file for " .. NAME)
    configIni:AddHeaderComment(" Made by DaPorkchop_ for the Team Pepsi Server Network")
    configIni:AddHeaderComment(" https://daporkchop.net")
    configIni:AddHeaderComment(" https://pepsi.team")
    configIni:AddKeyComment("Worlds", " \"World_name\" is the name of the world that will be used as the spleef world")

    -- read values from config
    WORLD_NAME = configIni:GetValueSet("Worlds", "World_name", "spleef")

    -- sanity check values

    -- save config again
    configIni:WriteFile(CONFIG_FILE)
end

function LoadLuaFiles()
    local files = {
        "/Hooks.lua",
        "/SpleefUtil.lua",
        -- libraries
        "/../lib/porklib.lua"
    }

    for _, file in pairs(files) do
        dofile(PLUGIN:GetLocalFolder() .. file)
    end
end
