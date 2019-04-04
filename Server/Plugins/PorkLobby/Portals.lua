PORTALS = nil
PORTAL_CREATE_QUEUE = {}

function LoadPortals()
    assert(cFile:IsFolder(LOCAL_FOLDER .. "/portals"))
    PORTALS = {}
    for _, fileName in pairs(cFile:GetFolderContents(LOCAL_FOLDER .. "/portals/")) do
        local json = cJson:Parse(cFile:ReadWholeFile(LOCAL_FOLDER .. "/portals/" .. fileName))
        PORTALS[json.name] = cBoundingBox(json.x1, json.x2, json.y1, json.y2, json.z1, json.z2)
    end
end

function ConsiderTeleportPlayer(a_Player, a_NewPos)
    if (a_NewPos == nil) then
        a_NewPos = Vector3d(a_Player:GetPosX(), a_Player:GetPosY(), a_Player:GetPosZ())
    end
    local playerBB = cBoundingBox(a_NewPos, 0.3, 1.8)
    for id, bb in pairs(PORTALS) do
        if (bb:DoesIntersect(playerBB)) then
            LOG("Sending player to " .. id .. "...")
            BungeeTransferPlayer(a_Player, id)
            TeleportPlayerToSpawn(a_Player)
            return true
        end
    end
    return false
end

function DoAddPortal(a_Player, x, y, z)
    local dst = PORTAL_CREATE_QUEUE[a_Player:GetUUID()]
    if (dst == nil) then
        return
    else
        PORTAL_CREATE_QUEUE[a_Player:GetUUID()] = nil
    end
    local minX = x
    while (WORLD:GetBlock(minX - 1, y, z) == E_BLOCK_NETHER_PORTAL) do
        minX = minX - 1
    end
    local maxX = x
    while (WORLD:GetBlock(maxX + 1, y, z) == E_BLOCK_NETHER_PORTAL) do
        maxX = maxX + 1
    end
    local minY = y
    while (WORLD:GetBlock(x, minY - 1, z) == E_BLOCK_NETHER_PORTAL) do
        minY = minY - 1
    end
    local maxY = y
    while (WORLD:GetBlock(x, maxY + 1, z) == E_BLOCK_NETHER_PORTAL) do
        maxY = maxY + 1
    end
    local minZ = z
    while (WORLD:GetBlock(x, y, minZ - 1) == E_BLOCK_NETHER_PORTAL) do
        minZ = minZ - 1
    end
    local maxZ = z
    while (WORLD:GetBlock(x, y, maxZ + 1) == E_BLOCK_NETHER_PORTAL) do
        maxZ = maxZ + 1
    end
    if (minX == maxX) then
        maxX = maxX + 1
        minZ = minZ - 0.5
        maxZ = maxZ + 0.5
    end
    if (minZ == maxZ) then
        maxZ = maxZ + 1
        minX = minX - 0.5
        maxX = maxX + 0.5
    end
    minY = minY - 0.5
    maxY = maxY + 0.5
    PORTALS[dst] = cBoundingBox(minX, maxX, minY, maxY, minZ, maxZ)
    local file = io.open(LOCAL_FOLDER .. "/portals/" .. dst .. ".json", "w+")
    file:write(cJson:Serialize({
        name = dst,
        x1 = minX,
        y1 = minY,
        z1 = minZ,
        x2 = maxX,
        y2 = maxY,
        z2 = maxZ
    }))
    file:close()
    a_Player:SendMessage("§aCreated portal from (" .. minX .. ", " .. minY .. ", " .. minZ .. ") to (" .. maxX .. ", " .. maxY .. ", " .. maxZ .. ") successfully!")
end

function CommandAddPortal(a_Split, a_Player)
    if (#a_Split ~= 2) then
        a_Player:SendMessage("§cUsage: /addportal <destination>")
    elseif (PORTALS[a_Split[2]] ~= nil) then
        a_Player:SendMessage("§cPortal to §l" .. a_Split[2] .. "§r§c already exists!")
    else
        PORTAL_CREATE_QUEUE[a_Player:GetUUID()] = a_Split[2]
        a_Player:SendMessage("§aBreak the portal that should be used!")
    end
    -- if (#a_Split ~= 8) then
    --     a_Player:SendMessage("§cUsage: /addportal <destination> <x1> <y1> <z1> <x2> <y2> <z2>")
    -- elseif (PORTALS[a_Split[2]] ~= nil) then
    --     a_Player:SendMessage("§cPortal to §l" .. a_Split[2] .. "§r§c already exists!")
    -- else
    --     local a = {
    --         x1 = tonumber(a_Split[3]),
    --         y1 = tonumber(a_Split[4]),
    --         z1 = tonumber(a_Split[5]),
    --         x2 = tonumber(a_Split[6]),
    --        y2 = tonumber(a_Split[7]),
    --         z2 = tonumber(a_Split[8])
    --     }
    --      if (a.x1 == a.x2) then
    --         a.x2 = a.x1 + 1
    --     end
    --     if (a.z1 == a.z2) then
    --         a.z2 = a.z1 + 1
    --     end
    --     local pos1 = Vector3i(a.x1, a.y1, a.z1)
    --    local pos2 = Vector3i(a.x2, a.y2, a.z2)
    --   local cuboid = cCuboid(pos1, pos2)
    --    cuboid:Sort()
    --    local file = io.open(LOCAL_FOLDER .. "/portals/" .. a_Split[2] .. ".json", "w+")
    --    file:write(cJson:Serialize({
    --        name = a_Split[2],
    --       x1 = cuboid.p1.x,
    --        y1 = cuboid.p1.y,
    --         z1 = cuboid.p1.z,
    --        x2 = cuboid.p2.x,
    --         y2 = cuboid.p2.y,
    --        z2 = cuboid.p2.z
    --    }))
    --     file:close()
    --     PORTALS[a_Split[2]] = cuboid
    --    WORLD:QueueTask(function (a_World)
    --         for x = cuboid.p1.x, cuboid.p2.x do
    --             for y = cuboid.p1.y, cuboid.p2.y do
    --                 for z = cuboid.p1.z, cuboid.p2.z do
    --                      a_World:SetBlock(x, y, z, E_BLOCK_NETHER_PORTAL, 0)
    --                     a_World:SendBlockTo(x, y, z, a_Player)
    --                 end
    --             end
    --        end
    --    end)
    --    a_Player:SendMessage("§aPortal created successfully!")
    -- end
    return true
end

function CommandDelPortal(a_Split, a_Player)
    if (#a_Split ~= 2) then
        a_Player:SendMessage("§cUsage: /delportal <destination>")
    elseif (PORTALS[a_Split[2]] == nil) then
        a_Player:SendMessage("§cPortal to §l" .. a_Split[2] .. "§r§c not found!")
    else
        PORTALS[a_Split[2]] = nil
        os.remove(LOCAL_FOLDER .. "/portals/" .. a_Split[2] .. ".json")
        a_Player:SendMessage("§aPortal deleted successfully!")
    end
    return true
end

function ExpandCuboid(a_Cuboid)
    a_Cuboid:Expand(1, 1, 1, 1, 1, 1)
end
