dofile("$CONTENT_DATA/Scripts/Config.lua")
keyboard = class()
keyboard.maxParentCount = 1
keyboard.maxChildCount = 1
keyboard.connectionInput = sm.interactable.connectionType.seated
keyboard.connectionOutput = sm.interactable.connectionType.composite
keyboard.colorNormal = sm.color.new(   0x9c1561ff)
keyboard.colorHighlight = sm.color.new(0xff30a5ff)
keyboard.poseWeightCount = 1
keyboard.maxSize = 32 * 1024
keyboard.componentType = "keyboard"

function keyboard:server_onCreate()
    local data = self.storage:load()
    if not data then
        data = {currentData = ""}
        self.storage:save(data)
    end
    self.sdata = data


    sc.keyboardDatas[self.interactable.id] = {
        clear = function ()
            self.writeData = ""
        end,
        read = function ()
            return self.sdata.currentData
        end,
        write = function (text)
            checkArg(1, text, "string")

            if #text > keyboard.maxSize then
                error("a string larger than 32 kb", 2)
            else
                self.writeData = text
                self.sdata.currentData = text
            end
            return true
        end,
        isEnter = function ()
            return not not self.btns.enter
        end,
        isEsc = function ()
            return not not self.btns.esc
        end,
        resetButtons = function ()
            self.btns = {}
        end
    }
    self.btns = {}

    self.network:sendToClients("cl_writeData", self.sdata.currentData)
end

function keyboard:server_onFixedUpdate()
    local ctick = sm.game.getCurrentTick()
	if ctick % sc.restrictions.screenRate == 0 then self.allow_update = true end

    if self.writeData and self.allow_update then
        self:sv_writeData(self.writeData)
        self.writeData = nil
        self.allow_update = nil
    end
end

function keyboard:server_onDestroy()
    sc.keyboardDatas[self.interactable.id] = nil
end



function keyboard:sv_writeData(data, caller)
    self.sdata.currentData = data
    self.storage:save(self.sdata)

    for _, player in ipairs(sm.player.getAllPlayers()) do
        if not caller or caller.id ~= player.id then
            self.network:sendToClient(player, "cl_writeData", data)
        end
    end

    if caller then
        for _, player in ipairs(sm.player.getAllPlayers()) do
            if caller.id ~= player.id then
                self.network:sendToClient(player, "cl_sound_1")
            end
        end
    end
end

function keyboard:sv_pressButton(btn, caller)
    self.btns[btn] = true

    for _, player in ipairs(sm.player.getAllPlayers()) do
        if  caller.id ~= player.id then
            self.network:sendToClient(player, "cl_sound_2")
        end
    end
end

function keyboard:sv_getData(_, caller)
    self.network:sendToClient(caller, "cl_writeData", self.sdata.currentData)
end

-------------------------------------------------------

function keyboard:client_onCreate()
    self.gui = sm.gui.createGuiFromLayout("$CONTENT_DATA/Gui/Layouts/keyboard.layout")
    self.gui:setButtonCallback("enter", "cl_pressButton")
    self.gui:setButtonCallback("esc", "cl_pressButton")
    self.gui:setTextChangedCallback("text", "cl_updateData")

    self.network:sendToServer("sv_getData")
end

function keyboard:client_onFixedUpdate()
    --self.interactable:setUvFrameIndex((self.lastdata and #self.lastdata ~= 0) and 6 or 0)
    --self.interactable:setUvFrameIndex(self.changedText and 6 or 0)
    self.interactable:setUvFrameIndex(6)
    self.changedText = nil
end

function keyboard:client_onDestroy()
    self.gui:close()
    self.gui:destroy()
end

function keyboard:client_onInteract(_, state)
    if state then
        self.gui:open()
    end
end



function keyboard:cl_updateData(_, data)
    self:cl_sound_1()
    data = formatAfterGui(data)
    if #data > keyboard.maxSize then
        self.gui:setText("text", formatBeforeGui(self.lastdata))
    else
        self.network:sendToServer("sv_writeData", data)
        self.lastdata = data
    end
end

function keyboard:cl_pressButton(name)
    self:cl_sound_2()

    self.network:sendToServer("sv_pressButton", name)
end




function keyboard:cl_writeData(data)
    self.lastdata = data
    self.gui:setText("text", formatBeforeGui(data))
end


function keyboard:cl_sound_1()
    self.changedText = true

    if self.data and self.data.scifi then
        sm.audio.play("Sensor on", self.shape.worldPosition)
    else
        sm.audio.play("Button off", self.shape.worldPosition)
    end
end

function keyboard:cl_sound_2()
    self.changedText = true

    if self.data and self.data.scifi then
        sm.audio.play("Sensor off", self.shape.worldPosition)
    else
        sm.effect.playEffect("keyboard", self.shape.worldPosition)
    end
end