terminal = class()
terminal.maxParentCount = -1
terminal.maxChildCount = 0
terminal.connectionInput = sm.interactable.connectionType.composite + sm.interactable.connectionType.seated
terminal.connectionOutput = sm.interactable.connectionType.none
terminal.colorNormal = sm.color.new(0x7F7F7Fff)
terminal.colorHighlight = sm.color.new(0xFFFFFFff)
terminal.componentType = "terminal" --absences can cause problems

function terminal:server_onCreate()
    self.interactable.publicData = {
        sc_component = {
            type = terminal.componentType,
            api = {
                read = function()
                    local text = self.ctext
                    self.ctext = nil
                    return text
                end,
                clear = function ()
                    self.writes = nil
                    self.clear = true
                end,
                write = function (str)
                    checkArg(1, str, "string")
                    if not self.writes then self.writes = {} end
                    table.insert(self.writes, "#ffffff" .. str)
                end
            }
        }
    }
end

function terminal:server_onFixedUpdate()
    if self.clear then
        self.network:sendToClients("cl_clr")
        self.clear = nil
    end

    if self.writes then
        self.network:sendToClients("cl_log", self.writes)
        self.writes = nil
    end
end

function terminal:sv_text(text)
    self.ctext = text
end

-------------------------------------------

function terminal:client_onCreate()
    self.gui = sm.gui.createGuiFromLayout("$CONTENT_DATA/Gui/Layouts/terminal.layout", false)
    self.gui:setButtonCallback("send", "cl_send")
    self.gui:setTextAcceptedCallback("text", "cl_send")
    self.gui:setTextChangedCallback("text", "cl_edit")

    self.cltext = ""
    self.log = ""
end

function terminal:client_onInteract(_, state)
    if state then
        self.gui:open()
    end
end

function terminal:cl_edit(_, text)
    self.cltext = text
end

function terminal:cl_log(log)
    for index, text in ipairs(log) do
        local beepFind = text:find("%" .. string.char(7))
        if beepFind then
            sm.audio.play("Horn", self.shape.worldPosition)
            text = text:sub(1, beepFind - 1) .. text:sub(beepFind + 1, #text)
        end
        self.log = self.log .. text
    end
    self.log = self.log:sub(math.max(1, #self.log - (1024 * 4)), #self.log)
    self.gui:setText("log", self.log)
end

function terminal:cl_clr()
    self.log = ""
    self.gui:setText("log", self.log)
end

function terminal:cl_send()
    self.gui:setText("text", "")
    self.network:sendToServer("sv_text", self.cltext)
    self.cltext = ""
end