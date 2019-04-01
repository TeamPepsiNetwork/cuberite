PORTALS = nil

function LoadPortals()
    assert(cFile:IsFolder(LOCAL_FOLDER .. "/portals"))
    PORTALS = {}
    for _, fileName in pairs(cFile:GetFolderContents(LOCAL_FOLDER .. "/portals/")) do
        local json = cJson:Parse(cFile:ReadWholeFile(LOCAL_FOLDER .. "/portals/" .. fileName))
        PORTALS[json.name] = {
            name = json.name,
            bb = cCuboid(json.x1, json.y1, json.z1, json.x2, json.y2, json.z2)
        }
    end
end

function ConsiderTeleportPlayer(a_Player)
    local x = a_Player:GetPosX()
    local y = a_Player:GetPosY()
    local z = a_Player:GetPosZ()
    --TODO
end
