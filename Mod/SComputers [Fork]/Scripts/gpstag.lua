gpstag = class()
gpstag.maxParentCount = 1
gpstag.maxChildCount = 0
gpstag.connectionInput = sm.interactable.connectionType.composite
gpstag.connectionOutput = sm.interactable.connectionType.none
gpstag.colorNormal = sm.color.new(0x7F7F7Fff)
gpstag.colorHighlight = sm.color.new(0xFFFFFFff)
gpstag.componentType = "gpstag" --absences can cause problems

function gpstag:server_onCreate()
    self:sv_setData(self.storage:load() or {freq = math.random(0, 9999999)})

	self.interactable.publicData = {
        sc_component = {
            type = gpstag.componentType,
            api = {
                setFreq = function (freq)
					checkArg(1, freq, "number")
                    self.sdata.freq = freq
					self.saveData = true
                end,
                getFreq = function ()
                    return self.sdata.freq
                end
            }
        }
    }
end

function gpstag:server_onFixedUpdate()
	if self.saveData then
		self:sv_setData(self.sdata)
		self.saveData = nil
	end
end

function gpstag:server_onDestroy()
    sc.gpstags[self.interactable.id] = nil
end

function gpstag:sv_requireData(_, player)
    self.network:sendToClient(player, "cl_setData", self.sdata)
end

function gpstag:sv_setData(data)
    self.sdata = data
    self.publicApi = {
        shape = self.shape,
        freq = self.sdata.freq
    }
    sc.gpstags[self.interactable.id] = self.publicApi
    self.network:sendToClients("cl_setData", self.sdata)
    self.storage:save(self.sdata)
end

---------------------------------------

function gpstag:client_onCreate()
    self.gui = sm.gui.createGuiFromLayout("$CONTENT_DATA/Gui/Layouts/gpstag.layout", false, { backgroundAlpha = 0.5 })
	self.gui:setTextChangedCallback("Channel", "client_onChannelChanged")
	self.gui:setButtonCallback("Save", "client_onSave")

    self.network:sendToServer("sv_requireData")
end

function gpstag:client_onSave()
    self.csdata.freq = self.cl_temp_channel
    self.network:sendToServer("sv_setData", self.csdata)
	self.gui:close()
end

function gpstag:client_onInteract(_, state)
	if state then
        self.cl_temp_channel = self.csdata.freq
        self.gui:setText("Channel", tostring(self.cl_temp_channel))
	    self:client_guiError(nil)
		self.gui:open()
	end
end

function gpstag:client_onChannelChanged(_, data)
	if data:match "%d*" == data then
		local channel = tonumber(data)
		self.cl_temp_channel = channel
        self:client_guiError(nil)
	else
		self:client_guiError("bad integer")
	end
end

function gpstag:client_guiError(text)
	if text ~= nil then
		self.gui:setVisible("Save", false)
		self.gui:setText("Error", text)
	else
		self.gui:setVisible("Save", true)
		self.gui:setText("Error", "")
	end
end

function gpstag:cl_setData(data)
    self.csdata = data
end

function gpstag:client_onDestroy()
	self.gui:destroy()
end