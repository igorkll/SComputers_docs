dofile( "$SURVIVAL_DATA/Scripts/util.lua" )
displayInitializer = class()
displayInitializer.rend = {"$CONTENT_DATA/Tools/Renderables/editor.rend"}
displayInitializer.displaySourceUuid = sm.uuid.new("4a7bd6e6-a48d-4932-8233-9dd6eb7386c8")
displayInitializer.displayCoreUuid = sm.uuid.new("ab36aa06-ea7d-4309-acd1-ed772e8c61fc")
displayInitializer.displayUuid = sm.uuid.new("c4704ff3-dd5a-4840-bfd6-0551497ccc32")
displayInitializer.effectRotation = sm.quat.fromEuler(sm.vec3.new(90, 0, 0))
displayInitializer.maxDisplayRes = 256 * 256
sm.tool.preloadRenderables(displayInitializer.rend)

local rotationZ, rotationX = sm.vec3.new(0, 1, 0), sm.vec3.new(0, 0, -1)
local lOffset = sm.vec3.new(1, 0, 1)

function displayInitializer:sv_make(data)
    sm.effect.playEffect("Part - Upgrade", data.shape.worldPosition, nil, displayInitializer.effectRotation)
    local boxX, boxY = data.box.y, data.box.x
    local rx, ry = data.resX, data.resY
    _g_displayData = {x = rx, y = ry, v = -0.25 / (rx / boxX), addPos = sm.vec3.new((boxX / 8) - (0.25 / 2), -((boxY / 8) - (0.25 / 2)), 0), addRot = sm.vec3.new(180, 0, 0), id = math.random()}
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

function displayInitializer:client_onCreate()
    self.gui = sm.gui.createGuiFromLayout("$CONTENT_DATA/Gui/Layouts/editor.layout")
    self.gui:setButtonCallback("make", "cl_make")
    self.gui:setButtonCallback("res_sub", "cl_gui_sub")
    self.gui:setButtonCallback("res_add", "cl_gui_add")
end

function displayInitializer:client_onDestroy()
    self.gui:close()
end

function displayInitializer:client_onEquippedUpdate(primaryState, secondaryState)
    if primaryState == sm.tool.interactState.start then
        local hit, result = sm.localPlayer.getRaycast(4)
        if hit and result then
            self:cl_gui(result:getShape())
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

function displayInitializer:cl_alert()
    sm.gui.displayAlertText("press the tool on the \"stretchable display\" block")
end

function displayInitializer:cl_gui(shape)
    if shape and shape.uuid == displayInitializer.displaySourceUuid then
        local box = shape:getBoundingBox()
        box.x = box.x * 4
        box.y = box.y * 4
        box.z = box.z * 4
        self.lastBox = box
        self.lastShape = shape
        self.currentResolutionX = box.y
        self.currentResolutionY = box.x
        if self.currentResolutionX * self.currentResolutionY > displayInitializer.maxDisplayRes then
            self.currentResolutionX = nil
            self.currentResolutionY = nil
        end
        if box.z == 1 then
            self:cl_gui_update()
            self.gui:open()
        else
            sm.gui.displayAlertText("the base of the display must be built parallel to the ground. then use welding")
        end
    else
        self:cl_alert()
    end
end

function displayInitializer:cl_gui_update()
    if self.currentResolutionX then
        self.gui:setText("res", self.currentResolutionX .. ":" .. self.currentResolutionY)
    else
        self.gui:setText("res", "incorrect display")
    end
end

function displayInitializer:cl_make()
    if self.currentResolutionX then
        self.network:sendToServer("sv_make", {shape = self.lastShape, box = self.lastBox, body = self.lastShape.body, resX = self.currentResolutionX, resY = self.currentResolutionY})
    else
        sm.gui.displayAlertText("incorrect display")
    end
    self.gui:close()
end

function displayInitializer:cl_gui_sub()
    if not self.currentResolutionX then return end
    local newX = self.currentResolutionX / 2
    local newY = self.currentResolutionY / 2
    if newX % 1 == 0 and newY % 1 == 0 then
        self.currentResolutionX = newX
        self.currentResolutionY = newY
    end
    self:cl_gui_update()
end

function displayInitializer:cl_gui_add()
    if not self.currentResolutionX then return end
    local newX = self.currentResolutionX * 2
    local newY = self.currentResolutionY * 2
    if newX * newY <= displayInitializer.maxDisplayRes then
        self.currentResolutionX = newX
        self.currentResolutionY = newY
    end
    self:cl_gui_update()
end