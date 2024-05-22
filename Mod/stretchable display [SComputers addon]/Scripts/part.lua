part = class()

function part:server_onCreate()
    self.data = self.storage:load()
    if not self.data then
        self.data = {id = _g_displayData.id}
        self.storage:save(self.data)
    end
    self.interactable.publicData = {id = self.data.id}
    self.publicData = self.interactable.publicData
end

function part:server_canErase()
    self.shapes = self.shape.body:getCreationShapes()
    self.id = self.data.id
    self.shapeID = self.shape.id
    return true
end

function part:server_onDestroy()
    if not self.publicData.del and self.shapes then
        for _, shape in ipairs(self.shapes) do
            pcall(function()
                if sm.exists(shape) and shape.id ~= self.shapeID and shape.interactable and shape.interactable.publicData and shape.interactable.publicData.id == self.id then
                    shape.interactable.publicData.del = true
                    shape:destroyShape()
                end
            end)
        end
    end
end

function part:server_onFixedUpdate()
    local color = self.shape.color
    self.oldColor = self.oldColor or color
    if color ~= self.oldColor then
        self.oldColor = color
        for _, shape in ipairs(self.shape.body:getCreationShapes()) do
            pcall(function()
                if sm.exists(shape) and shape.id ~= self.shape.id and shape.interactable and shape.interactable.publicData and shape.interactable.publicData.id == self.data.id then
                    shape.color = color
                end
            end)
        end
    end
end