dofile("$CONTENT_DATA/Scripts/Config.lua")
synthesizer = class()
synthesizer.maxParentCount = 1
synthesizer.maxChildCount = 0
synthesizer.connectionInput = sm.interactable.connectionType.composite
synthesizer.colorNormal = sm.color.new(   0x006e93ff)
synthesizer.colorHighlight = sm.color.new(0x00beffff)
synthesizer.poseWeightCount = 1
synthesizer.componentType = "synthesizer"
synthesizer.maxBeeps = 4

function synthesizer:server_onCreate()
    sc.synthesizerDatas[self.interactable.id] = {
        clear = function ()
            self.beeps = nil
        end,
        flush = function ()
            self.flushFlag = true
        end,
        addBeep = function (device, pitch, volume, duration)
            if not self.beeps then self.beeps = {} end
            if #self.beeps < synthesizer.maxBeeps then
                table.insert(self.beeps, {
                    device = device,
                    pitch = pitch,
                    volume = volume,
                    duration = duration
                })
            end
        end,
        stop = function ()
            self.stopFlag = true
        end
    }
end

function synthesizer:server_onDestroy()
    sc.synthesizerDatas[self.interactable.id] = nil
end

function synthesizer:server_onFixedUpdate()
    if self.stopFlag then
        self.network:sendToClients("cl_stop")
        self.stopFlag = nil
    end
    
    if self.flushFlag then
        if self.beeps then
            local index = 1
            local count = 64

            while true do
                local beeps = {unpack(self.beeps, index, index + (count - 1))}

                self.network:sendToClients("cl_upload", beeps)
                index = index + count
                if index > #self.beeps + count then
                    break
                end
            end
        end

        self.flushFlag = nil
    end
end



function synthesizer:client_onCreate()
    self.effects = {}
    self.effectsCache = {}
end

function synthesizer:client_onDestroy()
    for _, data in ipairs(self.effects) do
        data.effect:stop()
        data.effect:destroy()
    end
end

function synthesizer:client_onFixedUpdate()
    for i = #self.effects, 1, -1 do
        local data = self.effects[i]
        if data.duration then
            data.duration = data.duration - 1
        
            if data.duration <= 0 then
                data.effect:stop()
                data.effect:destroy()
                table.remove(self.effects, i)
            end
        elseif not data.effect:isPlaying() then
            data.effect:stop()
            data.effect:destroy()
            table.remove(self.effects, i)
        end
    end

    local num = #self.effects == 0 and 0 or 1

    if not self.pose then self.pose = 0 end
    self.pose = self.pose + ((num - self.pose) * 0.3)
    self.interactable:setPoseWeight(0, sm.util.clamp(self.pose, 0.01, 0.7))
end

function synthesizer:cl_stop()
    for _, data in ipairs(self.effects) do
        data.effect:stop()

        if not self.effectsCache[data.device] then self.effectsCache[data.device] = {} end
        table.insert(self.effectsCache[data.device], data.effect)
    end
    self.effects = {}
end

function synthesizer:cl_upload(datas)
    for _, data in ipairs(datas) do
        data.device = data.device or 0

        for i = 1, math.floor(sm.util.clamp((data.volume or 0.1) * 10, 0, 10) + 0.5) do
            local effect
            if self.effectsCache[data.device] and #self.effectsCache[data.device] > 0 then
                effect = table.remove(self.effectsCache[data.device])
            else
                if data.device == 0 then
                    effect = sm.effect.createEffect("Horn - Honk", self.interactable)
                else
                    effect = sm.effect.createEffect(sc.getSoundEffectName("tote" .. data.device), self.interactable)
                end    
            end
            
            if effect then
                effect:setParameter("pitch", data.pitch or 0.5)
                effect:start()
                
                table.insert(self.effects, {effect = effect, duration = data.duration or math.huge, device = data.device})
            end
        end
    end
end