local AnyDisplay = sm.sc_g.AnyDisplay
core = class(AnyDisplay)

function core:load()
    self.data = self.data:load()
    if not self.data then
        self.data = _g_coreData
        self.data:save(self.data)
    end
end

function core:server_onCreate()
    self:load()
    self.server_onCreate(AnyDisplay)
    self.network:sendToClients("cl_init", self.data)
end

function core:sv_request(_, player)
    self.network:sendToClient(player.id, "cl_init", self.data)
end

function core:client_onCreate()
    self.network:sendToServer("sv_request")
end

function core:cl_init(data)
    if not self.data then
        self.data = data
    end
    self.client_onCreate(AnyDisplay)
end