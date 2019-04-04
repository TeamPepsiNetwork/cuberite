-- DaPorkchop_'s SkyBlock plugin
--
-- much better than the original SkyBlock plugin for Cuberite, i made it fancier. e.g.:
-- - player data (including progress) is stored in an SQLite database rather than individual files
-- - challenges are defined using a much more powerful JSON-based system
-- - built-in support for the nether
-- - toggleable anarchy mode

NAME = "PorkSkyBlock"
VERSION_NUMBER = 1
VERSION = "v0.0.1-SNAPSHOT"

PLUGIN = nil       -- plugin instance
LOCAL_FOLDER = nil -- plugin folder
CONFIG_FILE = nil  -- config file path

WORLD_NAME = nil   -- name of the default world
NETHER_NAME = nil  -- name of the nether world
SPAWN_RADIUS = -1  -- random spawn radius
INSTANCE_NAME = "" -- name of this server

WORLD = nil        -- default world instance
NETHER = nil       -- nether world instance

ANARCHY = true     -- whether or not this is anarchy skyblock. if false, then this will be normal skyblock

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

    LoadDB()
    LoadChallenges()
    LoadStarterItems()
    LoadSpawnChunks()

    cRoot:Get():ForEachPlayer(LoadPlayerdata);

    -- Register hooks
    cPluginManager:AddHook(cPluginManager.HOOK_CHUNK_GENERATING, OnChunkGenerating)
    cPluginManager:AddHook(cPluginManager.HOOK_PLAYER_SPAWNED, OnPlayerSpawn)
    cPluginManager:AddHook(cPluginManager.HOOK_PLAYER_JOINED, OnPlayerJoined)
    cPluginManager:AddHook(cPluginManager.HOOK_PLAYER_DESTROYED, OnPlayerDestroyed)
    cPluginManager:AddHook(cPluginManager.HOOK_ENTITY_CHANGING_WORLD, OnEntityChangingWorld);

    -- Command Bindings
    cPluginManager:BindCommand("/challenge", "core.help", CommandChallenge, " - View " .. INSTANCE_NAME .. " challenges")
    cPluginManager:BindCommand("/start", "core.help", CommandStart, " - Get starter items for " .. INSTANCE_NAME)

    LOG(NAME .. " " .. VERSION .. " loaded successfully!")

    math.randomseed(os.time())
    return true
end

function OnDisable()
    cRoot:Get():ForEachPlayer(SavePlayerdata);
    LOG("Unloading " .. NAME .. " " .. VERSION .. "...")
    CloseDB()
    CHALLENGES = nil
    LOG(NAME .. " " .. VERSION .. " unloaded successfully!")
end

function LoadConfiguration()
    -- create ini file instance and load it
    local configIni = cIniFile()
    configIni:ReadFile(CONFIG_FILE)

    -- set up comments
    configIni:DeleteHeaderComments()
    configIni:DeleteKeyComments("Worlds")
    configIni:DeleteKeyComments("General")
    configIni:DeleteKeyComments("Anarchy")
    configIni:AddHeaderComment(" Configuration file for " .. NAME)
    configIni:AddHeaderComment(" Made by DaPorkchop_ for the Team Pepsi Server Network")
    configIni:AddHeaderComment(" https://daporkchop.net")
    configIni:AddHeaderComment(" https://pepsi.team")
    configIni:AddKeyComment("Worlds", " \"World_name\" is the name of the world that will be used as the SkyBlock overworld")
    configIni:AddKeyComment("Worlds", " \"Nether_name\" is the name of the world that will be used as the SkyBlock overworld")
    configIni:AddKeyComment("General", " \"Anarchy_mode\" toggles whether or not this is normal SkyBlock or anarchy SkyBlock")
    configIni:AddKeyComment("General", " \"Name\" is the name of this server instance")
    configIni:AddKeyComment("General", " \"Start_cooldown\" number of ticks between a player being allowed to start (i.e. obtain their starter items)")
    configIni:AddKeyComment("Anarchy", " \"Spawn_radius\" is the radius (in chunks) of the spawn area")

    -- read values from config
    ANARCHY = configIni:GetValueSetB("General", "Anarchy_mode", false)
    INSTANCE_NAME = configIni:GetValueSet("General", "Name", "SkyBlock")
    WORLD_NAME = configIni:GetValueSet("Worlds", "World_name", ANARCHY and "anarchyskyblock" or "skyblock")
    NETHER_NAME = configIni:GetValueSet("Worlds", "Nether_name", ANARCHY and "anarchyskyblock_nether" or "skyblock_nether")
    START_COOLDOWN = configIni:GetValueSetI("General", "Start_cooldown", 1728000) -- default 1 day
    SPAWN_RADIUS = configIni:GetValueSetI("Anarchy", "Spawn_radius", 8)

    -- sanity check values
    if (SPAWN_RADIUS < 1) then
        LOGERROR("Spawn radius may not be less than 1, resetting!")
        SPAWN_RADIUS = 1
        configIni:SetValueI("General", "Spawn_radius", 1)
    end

    SPAWN_RADIUS = (SPAWN_RADIUS * 16) - 8

    -- save config again in case it changed
    configIni:WriteFile(CONFIG_FILE)
end

function LoadLuaFiles()
    local files = {
        "/Challenges.lua",
        "/DB.lua",
        "/Hooks.lua",
        "/Playerdata.lua",
        -- commands
        "/command/CommandChallenge.lua",
        "/command/CommandStart.lua"
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
