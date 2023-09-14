servicetool = class()
servicetool.instance = nil

------------------------------------------------------------------

function servicetool:server_onCreate()
    dofile("$CONTENT_DATA/Scripts/Config.lua")
    sc.init()
    self.sendRestrictions = true
end

function servicetool:server_onFixedUpdate()
    if self._restrictionsUpdated then
        sc.restrictionsUpdated = nil
        self._restrictionsUpdated = nil
    end
    if sc.restrictionsUpdated then
        self._restrictionsUpdated = true
    end

    if self._rebootAll then
        sc.rebootAll = nil
        self._rebootAll = nil
    end
    if sc.rebootAll then
        self._rebootAll = true
    end
    
    if sc.restrictionsUpdated or self.sendRestrictions then
        self.network:sendToClients("cl_restrictions", sc.restrictions)
        self.sendRestrictions = nil
    end

    if sm.game.getCurrentTick() % (40 * 60 * 30) == 0 or sc.restrictionsUpdated then
        self:sv_print_vulnerabilities()
    end
end

function servicetool:sv_print_vulnerabilities()
    local vulnerabilities = {}

    if not sc.restrictions.adminOnly then
        table.insert(vulnerabilities, "any player can change the configuration of the mod(adminOnly: false)")
    end
    if sc.restrictions.allowChat then
        table.insert(vulnerabilities, "computers can output messages to chat(printON)")
    end
    if sc.restrictions.scriptMode ~= "safe" then
        table.insert(vulnerabilities, "computers can control the game(unsafe mode)")
    end
    if sc.restrictions.disCompCheck then
        table.insert(vulnerabilities, "component connectivity check is disabled")
    end

    self.network:sendToClients("cl_print_vulnerabilities", vulnerabilities)
end

function servicetool:sv_createGui()
    self.network:sendToClients("cl_createGui")
end

function servicetool:sv_dataRequest()
    self.sendRestrictions = true
end

function servicetool:sv_cheat(data)
    self.network:sendToClient(data.player, "cl_cheat")
end

function servicetool:sv_safe(data)
    local isHost = data.player == vnetwork.host
    if not sc.restrictions.adminOnly or isHost then
        self.network:sendToClients("cl_disToggleCheat")
        if isHost then -- clients can block theirselves
            sc.restrictions.adminOnly = true
        end
        sc.restrictions.allowChat = false
        sc.restrictions.scriptMode = "safe"
        sc.restrictions.disCompCheck = false

        sc.saveRestrictions()
        sc.rebootAll = true
    else
        self.network:sendToClient(data.player, "cl_noPermission")
    end
end

------------------------------------------------------------------

function servicetool:client_onCreate()
    dofile("$CONTENT_DATA/Scripts/Config.lua")
    if not self.tool:isLocal() then return end

    self:cl_createGui()
    sm.gui.chatMessage("#f08c02Thank you for using SComputers :)#ffffff")
    --sm.gui.chatMessage("#f03c02be sure to read the documentation#ffffff: https://scrapmechanictools.com/modapis/SComputers/Info")
    sm.gui.chatMessage("#f03c02be sure to read the documentation#ffffff: https://github.com/igorkll/SComputers_docs/blob/main/SComputers/Info.md")
    --sm.gui.chatMessage("current documentation is \"temporary\"")
    --sm.gui.chatMessage("because the scrapmechanictool site has closed")
    for _, warning in ipairs(warnings) do
        sm.gui.chatMessage(warning)
    end
    self.network:sendToServer("sv_dataRequest")
    servicetool.instance = self
end

function servicetool:client_onFixedUpdate()
    if self.gui and not self.gui:isActive() then
        self.gui:open()
    end

    if _G.tcCache and sm.game.getCurrentTick() % 80 == 0 then
        local size = 0
        local types = {}
        for dat in pairs(_G.tcCache) do
            size = size + 1
            local t = type(dat)
            if not types[t] then types[t] = 0 end
            types[t] = types[t] + 1
        end

        if size > 512 then
            print("clearing tableChecksum cache...")
            print("current size", size)
            print("types:")
            for t, count in pairs(types) do
                print(tostring(t) .. "-" .. tostring(count))
            end

            for key in pairs(_G.tcCache) do
                _G.tcCache[key] = nil
                if size < 256 then
                    break
                end
            end
        end
    end
end

function servicetool:cl_disToggleCheat()
    _G.allowToggleCheat = false
end

function servicetool:cl_print_vulnerabilities(vulnerabilities)
    if _G.allowToggleCheat then
        table.insert(vulnerabilities, "you can activate cheats (which may lead to accidental activation)")
    end

    if #vulnerabilities > 0 then
        sm.gui.chatMessage("#ff0000warnings from the SComputers security system:#ffffff")
        for index, value in ipairs(vulnerabilities) do
            sm.gui.chatMessage(tostring(index) .. ". " .. value .. ".")
        end
        sm.gui.chatMessage("#ffff00the host can enter /sv_scomputers_safe to automatically bring security back to normal#ffffff")
    end
end

function servicetool:cl_createGui()
    if not sm.isHost then return end
    --[[ fuck the human autopilot
    self.gui = sm.gui.createGuiFromLayout("$GAME_DATA/Gui/Layouts/PopUp/PopUp_YN.layout", false)
    self.gui:setText("Title", "SComputers")
    self.gui:setText("Message", "Allow computers to work in this gaming session?\nIf you have a computer that breaks the game, turn off the computers and put it away.\nTo open this menu, type the command: /computers ")
    self.gui:setButtonCallback("Yes", "cl_allow")
    self.gui:setButtonCallback("No", "cl_notAllow")
    ]]
    self.gui = sm.gui.createGuiFromLayout("$CONTENT_DATA/Gui/Layouts/allow.layout", false)
    self.gui:setButtonCallback("yes", "cl_allow")
    self.gui:setButtonCallback("no", "cl_notAllow")
end

function servicetool:cl_allow()
    if not self.vul_printed then
        self.network:sendToServer("sv_print_vulnerabilities")
        self.vul_printed = true
    end
    
    _G.computersAllow = true
    _G.updateToolSettings = true
    self.gui:close()
    self.gui:destroy()
    self.gui = nil
end

function servicetool:cl_notAllow()
    if not self.vul_printed then
        self.network:sendToServer("sv_print_vulnerabilities")
        self.vul_printed = true
    end

    _G.computersAllow = nil
    _G.updateToolSettings = true
    self.gui:close()
    self.gui:destroy()
    self.gui = nil
end

function servicetool:client_onUpdate(dt)
	sc.deltaTime = dt
end

function servicetool:cl_restrictions(data)
    if sm.isHost then return end
    sc.restrictions = data
end

function servicetool:cl_noPermission()
    sm.gui.chatMessage("#ff0000you don't have rights to use this command")
end

function servicetool:cl_cheat()
    if not _G.allowToggleCheat and sm.game.getLimitedInventory() then
        sm.gui.chatMessage("#ff0000it is impossible to enable cheats in survival")
        return
    end

    _G.allowToggleCheat = not _G.allowToggleCheat
    if _G.allowToggleCheat then
        sm.gui.chatMessage("#ffff00now you can activate cheats")
    else
        sm.gui.chatMessage("#00ff00you can no longer activate cheats")
    end
end

------------------------------------------------------------------

if not commandsBind then
    local added
    local oldBindCommand = sm.game.bindChatCommand
    local function bindCommandHook(command, params, callback, help)
        oldBindCommand(command, params, callback, help)
        if not added then
            if sm.isHost then
                oldBindCommand("/computers", {}, "cl_onChatCommand", "opens the SComputers configuration menu")
            end
            oldBindCommand("/cl_scomputers_cheat", {}, "cl_onChatCommand", "enables/disables cheat-buttons in the \"Creative Permission-tool\"")
            oldBindCommand("/sv_scomputers_safe", {}, "cl_onChatCommand", "returns SComputers parameters to safe")

            added = true
        end
    end
    sm.game.bindChatCommand = bindCommandHook

    --------------------------------------------

    local oldWorldEvent = sm.event.sendToWorld
    local function worldEventHook(world, callback, params)
        if params then
            if params[1] == "/computers" then
                sm.event.sendToTool(servicetool.instance.tool, "sv_createGui")
                return
            elseif params[1] == "/cl_scomputers_cheat" then
                sm.event.sendToTool(servicetool.instance.tool, "sv_cheat", {player = params.player})
                return
            elseif params[1] == "/sv_scomputers_safe" then
                sm.event.sendToTool(servicetool.instance.tool, "sv_safe", {player = params.player})
                return
            end
        end

        oldWorldEvent(world, callback, params)
    end
    sm.event.sendToWorld = worldEventHook

    --------------------------------------------

    commandsBind = true
end