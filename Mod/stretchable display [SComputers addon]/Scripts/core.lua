local AnyDisplay = sm.sc_g.AnyDisplay
core = class(AnyDisplay)

function core:load()
    self.data = self.storage:load()
    if not self.data then
        self.data = _g_displayData or {}
        self.storage:save(self.data)
    end
end

function core:server_onCreate()
    self:load()
    AnyDisplay.server_onCreate(self)
    self.interactable.publicData.id = self.data.id
    self.publicData = self.interactable.publicData
    self.network:sendToClients("cl_init", self.data)
end

function core:sv_request(_, player)
    self.network:sendToClient(player, "cl_init", self.data)
end

function core:client_onCreate()
    self.network:sendToServer("sv_request")
end

function core:cl_init(data)
    if not self.data then
        self.data = data
    end
    AnyDisplay.client_onCreate(self)
end

function core:server_canErase()
    self.shapes = self.shape.body:getCreationShapes()
    self.id = self.data.id
    self.shapeID = self.shape.id
    return true
end

function core:server_onDestroy()
    if not self.publicData.del then
        for _, shape in ipairs(self.shapes) do
            if sm.exists(shape) and shape.id ~= self.shapeID and shape.interactable and shape.interactable.publicData and shape.interactable.publicData.id == self.id then
                shape.interactable.publicData.del = true
                shape:destroyShape()
            end
        end
    end
end