-- DaPorkchop_'s anarchy SkyBlock plugin
-- Basically just a modded version of the original SkyBlock plugin for Cuberite
-- yeet

NAME = "AnarchySkyBlock"
VERSION_NUMBER = 1
VERSION = "v0.0.1-SNAPSHOT"

PLUGIN = nil
LOCAL_FOLDER = nil
CONFIG_FILE = nil

WORLD_NAME = nil
NETHER_NAME = nil
SPAWN_RADIUS = -1

WORLD = nil
NETHER = nil
DB = nil

PLAYER_DATA = {}

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
    NETHER = cRoot:Get():GetWorld(NETHER_NAME)
    if (NETHER == nil) then
        LOGERROR(PLUGIN:GetName() .. " requires the world \"" .. NETHER_NAME .. "\", but it was not found!")
        LOGERROR("Create the world or edit the world name \"Config.ini\".")
        return false
    end
    WORLD:SetLinkedNetherWorldName(NETHER_NAME)
    NETHER:SetLinkedOverworldName(WORLD_NAME)
    WORLD:SetSpawn(0, 0, 0)
    NETHER:SetSpawn(0, 0, 0)

    DB = sqlite3.open(LOCAL_FOLDER .. "/database.sqlite3")
    if (DB:exec("CREATE TABLE IF NOT EXISTS skyblock (uuid CHAR(32) NOT NULL, started INTEGER NOT NULL, PRIMARY KEY(uuid))") ~= sqlite3.OK) then
        LOGERROR("Unable to create table!")
        return false
    end

    LoadSpawnChunks()

    -- Register hooks
    cPluginManager:AddHook(cPluginManager.HOOK_CHUNK_GENERATING, OnChunkGenerating)
    cPluginManager:AddHook(cPluginManager.HOOK_PLAYER_SPAWNED, OnPlayerSpawn)
    cPluginManager:AddHook(cPluginManager.HOOK_PLAYER_JOINED, OnPlayerJoined)
    cPluginManager:AddHook(cPluginManager.HOOK_PLAYER_DESTROYED, OnPlayerDestroyed)

    -- Command Bindings

    LOG(NAME .. " " .. VERSION .. " loaded successfully!")

    math.randomseed(os.time())
    return true
end

function OnDisable()
    LOG("Unloading " .. NAME .. " " .. VERSION .. "...")
    DB:close()
end

function LoadConfiguration()
    -- create ini file instance and load it
    local configIni = cIniFile()
    configIni:ReadFile(CONFIG_FILE)

    -- set up comments
    configIni:DeleteHeaderComments()
    configIni:DeleteKeyComments("Worlds")
    configIni:DeleteKeyComments("General")
    configIni:AddHeaderComment("Configuration file for " .. NAME)
    configIni:AddHeaderComment("Made by DaPorkchop_ for the Team Pepsi Server Network")
    configIni:AddHeaderComment("https://daporkchop.net")
    configIni:AddHeaderComment("https://pepsi.team")
    configIni:AddKeyComment("Worlds", "\"World_name\" is the name of the world that will be used as the SkyBlock overworld")
    configIni:AddKeyComment("Worlds", "\"Nether_name\" is the name of the world that will be used as the SkyBlock overworld")
    configIni:AddKeyComment("General", "\"Spawn_radius\" is the radius (in chunks) of the spawn area")

    -- read values from config
    WORLD_NAME = configIni:GetValueSet("Worlds", "World_name", "anarchyskyblock")
    NETHER_NAME = configIni:GetValueSet("Worlds", "Nether_name", "anarchyskyblock_nether")
    SPAWN_RADIUS = configIni:GetValueSetI("General", "Spawn_radius", 8)

    -- sanity check values
    if (SPAWN_RADIUS < 1) then
        LOGERROR("Spawn radius may not be less than 1, resetting!")
        SPAWN_RADIUS = 1
        configIni:SetValueI("General", "Spawn_radius", 1)
    end

    SPAWN_RADIUS = (SPAWN_RADIUS * 16) - 8

    -- save config again
    configIni:WriteFile(CONFIG_FILE)
end

function LoadLuaFiles()
    local files = {
        "/Hooks.lua"
    }

    for _, file in pairs(files) do
        dofile(PLUGIN:GetLocalFolder() .. file)
    end
end

function LoadSpawnChunks()
    local min = math.floor((-SPAWN_RADIUS) / 16)
    local max = math.ceil(SPAWN_RADIUS / 16)
    local chunks = {}
    for x = min, max do
        for z = min, max do
            table.insert(chunks, { x, z })
        end
    end

    WORLD:ChunkStay(chunks, nil, function()
    end)

    return true
end
