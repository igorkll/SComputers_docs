dofile( "$SURVIVAL_DATA/Scripts/util.lua" )
displayInitializer = class()
displayInitializer.rend = {"$CONTENT_DATA/Tools/Renderables/editor.rend"}
displayInitializer.displaySourceUuid = sm.uuid.new("4a7bd6e6-a48d-4932-8233-9dd6eb7386c8")
displayInitializer.displayCoreUuid = sm.uuid.new("ab36aa06-ea7d-4309-acd1-ed772e8c61fc")
displayInitializer.displayUuid = sm.uuid.new("c4704ff3-dd5a-4840-bfd6-0551497ccc32")
displayInitializer.effectRotation = sm.quat.fromEuler(sm.vec3.new(90, 0, 0))
sm.tool.preloadRenderables(displayInitializer.rend)

local rotationZ, rotationX = sm.vec3.new(0, 1, 0), sm.vec3.new(0, 0, -1)
local lOffset = sm.vec3.new(1, 0, 1)

function displayInitializer:sv_make(data)
    sm.effect.playEffect("Part - Upgrade", data.shape.worldPosition, nil, displayInitializer.effectRotation)
    local rx, ry = data.box.y, data.box.x
    _g_displayData = {x = rx * 8, y = ry * 8, v = -0.25 / 8, addPos = sm.vec3.new((rx / 8) - (0.25 / 2), -((ry / 8) - (0.25 / 2)), 0), addRot = sm.vec3.new(180, 0, 0), id = math.random()}
    for ix = 0, data.box.x - 1 do
        for iy = 0, data.box.y - 1 do
            for iz = 0, data.box.z - 1 do
                local needSource = ix == 0 and iy == 0 and iz == data.box.z - 1
                local uuid = needSource and displayInitializer.displayCoreUuid or displayInitializer.displayUuid
                local localPos = data.shape.localPosition + sm.vec3.new(ix, iy, iz) + lOffset
                data.body:createPart(uuid, localPos, rotationZ, rotationX)
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
                if box.z == 1 then
                    self.network:sendToServer("sv_make", {shape = shape, box = box, body = shape.body})
                else
                    sm.gui.displayAlertText("the base of the display must be built parallel to the ground. then use welding")
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