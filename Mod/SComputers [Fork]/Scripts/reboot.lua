dofile("$CONTENT_DATA/Scripts/Config.lua")
reboot = class()
reboot.maxParentCount = -1
reboot.maxChildCount = -1
reboot.connectionInput = sm.interactable.connectionType.composite + sm.interactable.connectionType.logic
reboot.connectionOutput = sm.interactable.connectionType.composite + sm.interactable.connectionType.logic
reboot.colorNormal = sm.color.new("#8a05a6")
reboot.colorHighlight = sm.color.new("#d50bff")

function reboot:server_onFixedUpdate()
    local active
    local rebootFlag

    for _, parent in ipairs(self.interactable:getParents()) do
        local publicApi = sc.computersDatas[parent.id]
        if publicApi and publicApi.self and publicApi.self.storageData and publicApi.self.storageData.crashstate then
            if publicApi.self.storageData.crashstate.hasException then
                active = true
            end
        elseif parent:isActive() then
            rebootFlag = true
        end
    end

    for _, child in ipairs(self.interactable:getChildren()) do
        local publicApi = sc.computersDatas[child.id]
        if publicApi and publicApi.self and publicApi.self.storageData and publicApi.self.storageData.crashstate and publicApi.self.storageData.crashstate.hasException then
            active = true
            break
        end
    end

    if rebootFlag and not self.oldReboot then
        self:sv_reboot()
    end
    self.oldReboot = rebootFlag

    self.interactable:setActive(active)
end

function reboot:sv_reboot()
    for _, parent in ipairs(self.interactable:getParents()) do
        local publicApi = sc.computersDatas[parent.id]
        if publicApi and publicApi.self then
            publicApi.self.reboot_flag = true
        end
    end

    for _, child in ipairs(self.interactable:getChildren()) do
        local publicApi = sc.computersDatas[child.id]
        if publicApi and publicApi.self then
            publicApi.self.reboot_flag = true
        end
    end

    self.network:sendToClients("cl_blink")
end




function reboot:client_onFixedUpdate()
    if self.blick then
        self.blick = nil
    else
        if self.interactable:isActive() and sm.game.getCurrentTick() % 60 >= 30 then
            self.interactable:setUvFrameIndex(7)
        else
            self.interactable:setUvFrameIndex(0)
        end
    end
end

function reboot:client_onInteract(_, state)
    if state then
        self.network:sendToServer("sv_reboot")
    end
end

function reboot:cl_blink()
    self.interactable:setUvFrameIndex(6)
    self.blick = true
end