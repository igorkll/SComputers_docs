dofile("$CONTENT_DATA/Scripts/Config.lua")
led = class()
led.maxParentCount = 1
led.maxChildCount = -1
led.connectionInput = sm.interactable.connectionType.composite
led.connectionOutput = sm.interactable.connectionType.composite
led.colorNormal = sm.color.new(0x787878ff)
led.colorHighlight = sm.color.new(0xffffffff)
led.componentType = "led"

ledsDatas = ledsDatas or {}

function led:server_onCreate()
    self.sv_glow = 1

    self.interactable.publicData = {
        sc_component = {
            type = led.componentType,
            api = {
                setColor = function (index, color)
                    color = sc.formatColor(color, true)

                    if index <= 0 then
                        if self.shape.color ~= color then
                            self.shape:setColor(color)
                        end
                        return
                    end
                    index = index - 1
                    for _, child in ipairs(self.interactable:getChildren()) do
                        ledsDatas[child.id].setColor(index, color)
                    end
                end,
                setGlow = function (index, multiplier)
                    checkArg(1, multiplier, "number")

                    if index <= 0 then
                        if multiplier < 0 or multiplier > 1 then
                            error("the range should be from 0 to 1", 2)
                        end
                        if multiplier ~= self.sv_glow then
                            self.sv_glow = multiplier
                            self.sendData = true
                        end
                        return
                    end

                    index = index - 1
                    for _, child in ipairs(self.interactable:getChildren()) do
                        ledsDatas[child.id].setGlow(index, multiplier)
                    end
                end
            }
        }
    }
    ledsDatas[self.interactable.id] = self.interactable.publicData.sc_component.api
end

function led:server_onFixedUpdate()
    if self.sendData then
        self:sv_sendData()
        self.sendData = nil
    end
end

function led:server_onDestroy()
    ledsDatas[self.interactable.id] = nil
end

function led:sv_sendData()
    self.network:sendToClients("cl_setGlow", self.sv_glow)
end

------------------------------------------------

function led:client_onCreate()
    self.network:sendToServer("sv_sendData")
    self.cl_glow = 1
end

function led:client_onFixedUpdate()
    self.interactable:setGlowMultiplier(self.cl_glow + 0.01) --чтобы setColor не сбрасывал setGlowMultiplier
    self.interactable:setGlowMultiplier(self.cl_glow)
end

function led:cl_setGlow(value)
    self.cl_glow = value
end