local name = "AntiSpeed"
local log = true

-- from https://minecraft.gamepedia.com/Transportation#Methods
WALK_SPEED = 4.3 / 20.0
SPRINT_SPEED = 5.6 / 20.0
SNEAK_SPEED = 1.3 / 20.0
WATER_SPEED = 2.2 / 20.0

local INSTANCE = {
    name = name,
    load = function(config)
        log = config:GetValueSetB(name, "Log", log)
    end,
    init = function()
        cPluginManager:AddHook(cPluginManager.HOOK_ENTITY_CHANGED_WORLD, OnEntityChangedWorld)
        cPluginManager:AddHook(cPluginManager.HOOK_ENTITY_CHANGING_WORLD, OnEntityChangingWorld)
        cPluginManager:AddHook(cPluginManager.HOOK_ENTITY_TELEPORT, OnEntityTeleport)
        cPluginManager:AddHook(cPluginManager.HOOK_PLAYER_MOVING, OnPlayerMoving)
        cPluginManager:AddHook(cPluginManager.HOOK_WORLD_TICK, OnWorldTick)
    end,
    shutdown = function()
    end,
    onSpawn = function(a_Player, data)
        data.antispeed = {
            --lastMove = 0
        }
    end
}

ALL_MODULES[name] = INSTANCE

function OnEntityTeleport(a_Entity, a_Old, a_New)
    if (a_Entity:IsPlayer()) then
        local data = PLAYER_DATA[a_Entity:GetUUID()].antispeed
        data.lastPosition = a_New
        data.lastMove = a_Entity:GetWorld():GetWorldAge()
    end
end

function OnPlayerMoving(a_Player, a_Old, a_New)
    --local data = PLAYER_DATA[a_Player:GetUUID()].antispeed
    if (false and not a_Player:IsRiding() and DistanceXZ(a_Old, a_New) > GetMaxSpeed(a_Player)) then
        if (log) then
            LOG("Player " .. a_Player:GetName() .. " moved too quickly! " .. DistanceXZ(a_Old, a_New) .. " > " .. GetMaxSpeed(a_Player, data) .. " (scale=" .. 1.0 .. ")")
        end
        return true
    end
    --data.lastMove = a_Player:GetWorld():GetWorldAge()
end

function OnEntityChangingWorld(a_Entity, a_TargetWorld)
    if (a_Entity:IsPlayer()) then
        local data = PLAYER_DATA[a_Entity:GetUUID()].antispeed
        data.lastPosition = nil
        --data.lastMove = 0
    end
end

function OnEntityChangedWorld(a_Entity, a_SourceWorld)
    if (a_Entity:IsPlayer()) then
        local data = PLAYER_DATA[a_Entity:GetUUID()].antispeed
        data.lastPosition = nil
        --data.lastMove = 0
    end
end

function OnWorldTick(a_World, a_TimeDelta)
    local scale = a_TimeDelta / 50.0 + 2.5
    a_World:ForEachPlayer(function(a_Player)
        if (a_Player:IsRiding()) then
            LOG("Player is riding an entity.")
            return
        end
        LOG("Player is NOT riding an entity.")
        local data = PLAYER_DATA[a_Player:GetUUID()].antispeed
        local pos = a_Player:GetPosition()
        if (data.lastPosition ~= nil and DistanceXZ(data.lastPosition, pos) > GetMaxSpeed(a_Player, scale)) then
            if (log) then
                LOG("Player " .. a_Player:GetName() .. " moved too quickly! " .. DistanceXZ(data.lastPosition, pos) .. " > " .. GetMaxSpeed(a_Player, scale) .. " (scale=" .. scale .. ")")
            end
            a_Player:TeleportToCoords(data.lastPosition.x, data.lastPosition.y, data.lastPosition.z)
        else
            data.lastPosition = pos
        end
    end)
end

function GetMaxSpeed(a_Player, a_Scale)
    if (a_Scale == nil) then
        a_Scale = 1.0
    end
    if (a_Player:IsGameModeCreative() or a_Player:IsGameModeSpectator()) then
        return 1000000000.0
    elseif (a_Player:IsSprinting()) then
        return SPRINT_SPEED * a_Scale
    elseif (a_Player:IsInWater()) then
        return WATER_SPEED * a_Scale
    elseif (a_Player:IsCrouched()) then
        return SNEAK_SPEED * a_Scale
    else
        return WALK_SPEED * a_Scale
    end
end
