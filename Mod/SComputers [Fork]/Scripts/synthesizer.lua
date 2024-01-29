dofile("$CONTENT_DATA/Scripts/Config.lua")
synthesizer = class()
synthesizer.maxParentCount = 1
synthesizer.maxChildCount = 0
synthesizer.connectionInput = sm.interactable.connectionType.composite
synthesizer.colorNormal = sm.color.new(   0x006e93ff)
synthesizer.colorHighlight = sm.color.new(0x00beffff)
synthesizer.poseWeightCount = 1
synthesizer.componentType = "synthesizer"

local maxBeeps = 4
local maxLoops = 4
local loopsList = {}
for i = 1, 5 do
    table.insert(loopsList, "ElectricEngine - Level " .. i)
    table.insert(loopsList, "GasEngine - Level " .. i)
end

local function checkNum(num)
    if num < 1 or num > maxLoops or num % 1 ~= 0 then
        error("invalid cycle number", 3)
    end
end

function synthesizer:server_onCreate()
    self.loopData = {}
    self.flushLoops = true

    sc.synthesizerDatas[self.interactable.id] = {
        clear = function ()
            self.beeps = nil
        end,
        flush = function ()
            self.flushFlag = true
        end,
        addBeep = function (device, pitch, volume, duration)
            checkArg(1, device, "number", "nil")
            checkArg(2, pitch, "number", "nil")
            checkArg(3, volume, "number", "nil")
            checkArg(4, duration, "number", "nil")

            if not self.beeps then self.beeps = {} end
            if #self.beeps < maxBeeps then
                table.insert(self.beeps, {
                    device,
                    pitch,
                    volume,
                    duration
                })
            end
        end,
        stop = function ()
            self.stopFlag = true
        end,

        -- loop api
        getLoopsCount = function()
            return maxLoops
        end,
        getLoopsWhilelist = function()
            return sc.advDeepcopy(loopsList)
        end,
        startLoop = function(number, loopname, params)
            checkArg(1, number, "number")
            checkArg(2, loopname, "string")
            checkArg(3, params, "table", "nil")
            checkNum(number)
            for i, v in ipairs(loopsList) do
                if v == loopname then
                    self.loopData[number] = {loopname, params}
                    self.flushLoops = true
                    return
                end
            end
            error("unknown loop effect", 2)
        end,
        stopLoop = function(number)
            checkArg(1, number, "number")
            checkNum(number)
            self.loopData[number] = nil
            self.flushLoops = true
        end,
        stopLoops = function()
            self.loopData = {}
            self.flushLoops = true
        end,
        setLoopParams = function(number, params)
            checkArg(1, number, "number")
            checkArg(2, params, "table")
            checkNum(number)
            if not self.loopData[number] then
                error("the loop effect number " .. math.floor(number) .. " is not running", 2)
            end
            self.loopData[number][2] = params
            if not self.flushParams then self.flushParams = {} end
            self.flushParams[number] = params
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

    if self.flushLoops then
        self:sv_flushLoops()
        self.flushLoops = nil
    end

    if self.flushParams then
        self.network:sendToClients("cl_flushParams", self.flushParams)
        self.flushParams = nil
    end
end

function synthesizer:sv_flushLoops()
    self.network:sendToClients("cl_flushLoops", self.loopData)
end




function synthesizer:client_onCreate()
    self.effects = {}
    self.effectsCache = {}
    self.currentLoops = {}
    self.oldEffectsName = {}
    self.network:sendToServer("sv_flushLoops")
end

function synthesizer:client_onDestroy()
    for _, data in ipairs(self.effects) do
        data.effect:stop()
        data.effect:destroy()
    end

    for _, effect in pairs(self.currentLoops) do
        effect:destroy()
    end
end

function synthesizer:cl_flushParams(data)
    for i, ldat in pairs(data) do
        if self.currentLoops[i] then
            for k, v in pairs(ldat) do
                self.currentLoops[i]:setParameter(k, v)
            end
        end
    end
end

function synthesizer:cl_flushLoops(data)
    print(data)
    local alt = {}
    for i, effect in pairs(self.currentLoops) do
        if not data[i] or self.oldEffectsName[i] ~= data[i][1] then
            effect:destroy()
            self.currentLoops[i] = nil
            self.oldEffectsName[i] = nil
        else
            alt[i] = effect
        end
    end

    for i, ldat in pairs(data) do
        local effect = alt[i] or sm.effect.createEffect(ldat[1], self.interactable)
        for k, v in pairs(ldat[2] or {}) do
            effect:setParameter(k, v)
        end
        if effect:isDone() then
            effect:setAutoPlay(true)
            effect:start()
        end
        self.currentLoops[i] = effect
        self.oldEffectsName[i] = ldat[1]
    end
end

function synthesizer:client_onFixedUpdate()
    for i = #self.effects, 1, -1 do
        local data = self.effects[i]
        if data[4] then
            data[4] = data[4] - 1
        
            if data[4] <= 0 then
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
    for _, effect in pairs(self.currentLoops) do
        num = 1
        break
    end

    if not self.pose then self.pose = 0 end
    self.pose = self.pose + ((num - self.pose) * 0.3)
    self.interactable:setPoseWeight(0, sm.util.clamp(self.pose, 0.01, 0.7))
end

function synthesizer:cl_stop()
    for _, data in ipairs(self.effects) do
        data.effect:stop()

        if not self.effectsCache[data[1]] then self.effectsCache[data[1]] = {} end
        table.insert(self.effectsCache[data[1]], data.effect)
    end
    self.effects = {}
end

function synthesizer:cl_upload(datas)
    for _, data in ipairs(datas) do
        data[1] = data[1] or 0

        for i = 1, math.floor(sm.util.clamp((data[3] or 0.1) * 10, 0, 10) + 0.5) do
            local effect
            if self.effectsCache[data[1]] and #self.effectsCache[data[1]] > 0 then
                effect = table.remove(self.effectsCache[data[1]])
            else
                if data[1] == 0 then
                    effect = sm.effect.createEffect("Horn - Honk", self.interactable)
                else
                    effect = sm.effect.createEffect(sc.getSoundEffectName("tote" .. data[1]), self.interactable)
                end    
            end
            
            if effect then
                effect:setParameter("pitch", data[2] or 0.5)
                effect:start()
                
                data.effect = effect
                table.insert(self.effects, data)
            end
        end
    end
end