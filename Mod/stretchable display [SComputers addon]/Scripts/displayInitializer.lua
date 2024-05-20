dofile( "$SURVIVAL_DATA/Scripts/util.lua" )
displayInitializer = class()
displayInitializer.rend = {"$CONTENT_DATA/Tools/Renderables/editor.rend"}
displayInitializer.displaySourceUuid = sm.uuid.new("4a7bd6e6-a48d-4932-8233-9dd6eb7386c8")
displayInitializer.displayCoreUuid = sm.uuid.new("ab36aa06-ea7d-4309-acd1-ed772e8c61fc")
displayInitializer.displayUuid = sm.uuid.new("c4704ff3-dd5a-4840-bfd6-0551497ccc32")
sm.tool.preloadRenderables(displayInitializer.rend)

local effectRotation = sm.quat.fromEuler(sm.vec3.new(90, 0, 0))
local rotationZ, rotationX = sm.vec3.new(0, 0, 1), sm.vec3.new(1, 0, 0)

function displayInitializer:sv_make(data)
    sm.effect.playEffect("Part - Upgrade", data.shape.worldPosition, nil, effectRotation)
    local sizes = {}
    if data.box.x > 1 then table.insert(sizes, data.box.x) end
    if data.box.y > 1 then table.insert(sizes, data.box.y) end
    if data.box.z > 1 then table.insert(sizes, data.box.z) end
    local rx, ry = sizes[1], sizes[1]
    _g_coreData = {x = rx, y = ry}
    for ix = 0, data.box.x - 1 do
        for iy = 0, data.box.y - 1 do
            for iz = 0, data.box.z - 1 do
                local needSource = ix == 0 and iy == 0 and iz == 0
                local uuid = needSource and displayInitializer.displayCoreUuid or displayInitializer.displayUuid
                data.body:createPart(uuid, data.shape.localPosition + sm.vec3.new(ix, iy, iz), rotationZ, rotationX)
            end
        end
    end
    data.shape:destroyShape()
end

--------------------------------------

function displayInitializer:cl_alert()
    sm.gui.displayAlertText("press the tool on the \"stretchable display\" block")
end

function displayInitializer:client_onEquippedUpdate(primaryState, secondaryState)
    if primaryState == sm.tool.interactState.start then
        local hit, result = sm.localPlayer.getRaycast(4)
        if hit and result then
            local shape = result:getShape()
            if shape and shape.uuid == displayInitializer.displaySourceUuid then
                local box = shape:getBoundingBox()
                box.x = box.x * 4
                box.y = box.y * 4
                box.z = box.z * 4
                if box.x == 1 or box.y == 1 or box.z == 1 then
                    self.network:sendToServer("sv_make", {shape = shape, box = box, body = shape.body})
                else
                    sm.gui.displayAlertText("one of the sides of your display should have a thickness of 1")
                end
            else
                self:cl_alert()
            end
        else
            self:cl_alert()
        end
    end

    self.tool:updateFpAnimation("connecttool_use_connect", 1, 1)
    return true, true
end

function displayInitializer:client_onEquip()
    self.tool:setTpRenderables(displayInitializer.rend)
    self.tool:setFpRenderables(displayInitializer.rend)
end