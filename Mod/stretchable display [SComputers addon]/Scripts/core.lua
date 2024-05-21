local AnyDisplay = sm.sc_g.AnyDisplay
core = class(AnyDisplay)

function core:load()
    self.data = self.storage:load()
    if not self.data then
        self.data = _g_displayData or {}
        _g_displayData = nil
        self.storage:save(self.data)
    end
end

function core:server_onCreate()
    self:load()
    AnyDisplay.server_onCreate(self)
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