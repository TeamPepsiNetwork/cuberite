local name = "Cooldown"

local cooldown = 5

local INSTANCE = {
    name = name,
    enabledByDefault = true,
    load = function(config)
        cooldown = config:GetValueSetI(name, "Cooldown", cooldown)
    end,
    init = function()
        cPluginManager:AddHook(cPluginManager.HOOK_ENTITY_CHANGED_WORLD, OnEntityChangedWorld)
        cPluginManager:AddHook(cPluginManager.HOOK_TAKE_DAMAGE, OnTakeDamage)
    end,
    shutdown = function()
    end,
    onSpawn = function(a_Player, data)
        data.cooldown = 0
    end
}

function OnEntityChangedWorld(a_Entity, a_SourceWorld)
    if (a_Entity:IsPlayer()) then
        PLAYER_DATA[a_Entity:GetUUID()].cooldown = a_Entity:GetWorld():GetWorldAge()
    end
end

function OnTakeDamage(a_Receiver, a_TDI)
    if (a_TDI.Attacker ~= nil and a_TDI.Attacker:IsPlayer()) then
        local data = PLAYER_DATA[a_TDI.Attacker:GetUUID()]
        local age = a_TDI.Attacker:GetWorld():GetWorldAge()
        if (data.cooldown + cooldown > age) then
            data.cooldown = age
        else
            return true
        end
    end
end

ALL_MODULES[name] = INSTANCE
