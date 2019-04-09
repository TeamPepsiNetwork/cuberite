local name = "Template"
local INSTANCE = {
    name = name,
    load = function(config)
    end,
    init = function()
    end,
    shutdown = function()
    end,
    onSpawn = function(a_Player, data)
    end
}

ALL_MODULES[name] = INSTANCE
