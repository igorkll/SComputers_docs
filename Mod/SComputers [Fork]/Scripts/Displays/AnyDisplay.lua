dofile("$CONTENT_DATA/Scripts/Config.lua")
dofile("$CONTENT_e8298053-4412-48e8-aff1-4271d1b07584/Scripts/canvas.lua")
AnyDisplay = class(sm.canvas.audienceCounter)
AnyDisplay.maxParentCount = 1
AnyDisplay.maxChildCount = 0
AnyDisplay.connectionInput = sm.interactable.connectionType.composite
AnyDisplay.colorNormal = sm.color.new(0xbbbb1aff)
AnyDisplay.colorHighlight = sm.color.new(0xecec1fff)
AnyDisplay.componentType = "display"

local PIXEL_SCALE = 0.0072
local RENDER_DISTANCE = 15
local defaultTrySend = 7000
local sc = sc

--------------------------------------- SERVER

local stackChecksum = sm.canvas.stackChecksum
local needPushStack = sm.canvas.needPushStack

local function sendStack(self, method, stack, force)
    if #sm.player.getAllPlayers() > 1 then
        local mul = 0.98

        stack.flush = true
        stack.force = force
        if not pcall(self.network.sendToClients, self.network, method, stack) then
            stack.flush = nil

            local index = 1
            local count = self.tryPacket or defaultTrySend
            local cycles = 0
            local lastIndex
            local datapack
            local dataPackI
            while true do
                lastIndex = index + (count - 1)
                datapack = {}
                dataPackI = 1
                for i = index, lastIndex do
                    datapack[dataPackI] = stack[i]
                    dataPackI = dataPackI + 1
                end
                datapack.force = force

                index = index + count
                if lastIndex >= #stack then
                    datapack.flush = true
                    if pcall(self.network.sendToClients, self.network, method, datapack) then
                        break
                    else
                        datapack.flush = nil
                        index = index - count
                        count = math.floor(count * mul)
                        self.tryPacket = count
                    end
                elseif not pcall(self.network.sendToClients, self.network, method, datapack) then
                    index = index - count
                    count = math.floor(count * mul)
                    self.tryPacket = count
                end

                cycles = cycles + 1
                if cycles > 100 then
                    print("try send: ", pcall(self.network.sendToClients, self.network, method, stack))
                    error("cycles to many 100")
                    break
                end
            end
        end
    else
        stack.force = force
        self["sendedData_" .. method] = stack
        self.network:sendToClients(method)
    end
end

local function isAllow(self)
    return self.width * self.height <= (sc.restrictions.maxDisplays * sc.restrictions.maxDisplays)
end

function AnyDisplay:server_onCreate()
	self.dataTunnel = {}
	self.width = self.data.x
	self.height = self.data.y
	self.api = sm.canvas.createScriptableApi(self.width, self.height, self.dataTunnel, function ()
        self.lastComputer = sc.lastComputer
    end)
	self.touchscreen = sm.canvas.addTouch(self.api, self.dataTunnel)

	self.api.isAllow = function()
		return isAllow(self)
	end

    self.api.getAudience = function()
        if self._getAudienceCount then
            return self._getAudienceCount()
        end
        return 0
    end

	self.interactable.publicData = {
		sc_component = {
			type = AnyDisplay.componentType,
			api = self.api
		}
	}
end

function AnyDisplay:server_onFixedUpdate()
	local ctick = sm.game.getCurrentTick()
	if ctick % sc.restrictions.screenRate == 0 then
		self.allow_send = true
	end

    if ctick % (40 * 4) == 0 then
        self.tryPacket = nil
    end

    if self.lastComputer and self._getLagDetector then
        local lagScore = self._getLagDetector()
        if type(sc.restrictions.lagDetector) == "number" then
            self.lastComputer.lagScore = self.lastComputer.lagScore + (lagScore * sc.restrictions.lagDetector)
        end
    end

    self.dataTunnel.scriptableApi_update()

	if isAllow(self) then
		if self.allow_send then
			if self.dataTunnel.dataUpdated then
				self.network:sendToClients("cl_dataTunnel", sm.canvas.minimizeDataTunnel(self.dataTunnel))
				self.allow_send = nil
                self.dataTunnel.dataUpdated = nil
                self.dataTunnel.display_reset = nil
			end
	
			if self.dataTunnel.display_flush then
                sendStack(self, "cl_pushStack", self.dataTunnel.display_stack, self.dataTunnel.display_forceFlush)
				
				self.dataTunnel.display_flush()
				self.dataTunnel.display_stack = nil
				self.dataTunnel.display_flush = nil
                self.dataTunnel.display_forceFlush = nil
				self.allow_send = nil
			end
		end
	elseif self.dataTunnel.display_flush then
        self.dataTunnel.display_flush()
        self.dataTunnel.display_stack = nil
        self.dataTunnel.display_flush = nil
        self.dataTunnel.display_forceFlush = nil
	end
end

function AnyDisplay:sv_dataRequest()
    self.tryPacket = nil
end

function AnyDisplay:sv_recvPress(data)
	self.touchscreen(data)
end

--------------------------------------- CLIENT

function AnyDisplay:client_onCreate()
	local material = sm.canvas.material.classic
	local rotate
	local ypos = 0
	local zpos = 0.12
	if self.data then
		if self.data.glass then
			material = sm.canvas.material.glass
		end

		if self.data.zpos then
			zpos = self.data.zpos
		end

		if self.data.offset then
			ypos = -(self.data.offset / 4)
		end

		if self.data.rotate then
			rotate = true
			ypos = -ypos
		end
	end

	self.width = self.data.x
	self.height = self.data.y
    local rot = sm.vec3.new(0, -90, (not rotate) and 180 or 0)
    local pos = sm.vec3.new(0, ypos, zpos)
    if self.data.addRot then
        rot = rot + self.data.addRot
    end
    if self.data.addPos then
        pos = pos + self.data.addPos
    end
	self.canvas = sm.canvas.createCanvas(self.interactable, self.width, self.height, self.data.v, pos, sm.quat.fromEuler(rot), material)
	self.network:sendToServer("sv_dataRequest")

	self.c_dataTunnel = {}
	self.pixelScale = self.data.v
	self.dragging = {interact=false, tinker=false, interactLastPos={x=-1, y=-1}, tinkerLastPos={x=-1, y=-1}}
end

function AnyDisplay:client_onDestroy()
	self.canvas.destroy()
end

local function client_onClick(self, type, action, localPoint) -- type - 1:interact|2:tinker (e.g 1 or 2), action - pressed, released, drag
    if self.data and self.data.noTouch then
        return
    end

    local function detect(pointX, pointY)
        pointX = math.floor(pointX + 0.5)
        pointY = math.floor(pointY + 0.5)

        if pointX >= 0 and pointX < self.width and pointY >= 0 and pointY < self.height then
            if action == "drag" then
                local t = type == 1 and self.dragging.interactLastPos or self.dragging.tinkerLastPos

                if t.x ~= -1 then
                    if t.x == pointX and t.y == pointY then 
                        return
                    else
                        t.x = pointX
                        t.y = pointY
                    end
                else
                    t.x = pointX
                    t.y = pointY
                    return
                end
            end

            local reverseX, reverseY, changeXY
            if self.c_dataTunnel.rotation == 1 then
                changeXY = true
                reverseX = true
            elseif self.c_dataTunnel.rotation == 2 then
                reverseX = true
                reverseY = true
            elseif self.c_dataTunnel.rotation == 3 then
                changeXY = true
                reverseY = true
            end
            if reverseX then
                pointX = self.width - pointX - 1
            end
            if reverseY then
                pointY = self.height - pointY - 1
            end
            if changeXY then
                pointX, pointY = pointY, pointX
            end

            --print("touch", pointX, pointY)
            self.network:sendToServer("sv_recvPress", {pointX, pointY, action, type})
        end
    end

    local function reg(localPoint)
        if localPoint and localPoint.x < 0 then
            local localPoint = sm.vec3.new(0, localPoint.y, localPoint.z)
            local scale = PIXEL_SCALE * self.pixelScale

            local pointX = math.floor(self.width / 2 - localPoint.z / scale)
            local pointY = math.floor(self.height / 2 + localPoint.y / scale)
        
            detect(pointX, pointY)
        end
    end
    
    if localPoint then
        reg(localPoint)
    elseif self.shape then
        local succ, res = sm.localPlayer.getRaycast((sc.restrictions and sc.restrictions.rend) or RENDER_DISTANCE)
        if succ then
            local shape = self.shape
            local localPoint = shape:transformPoint(res.pointWorld)
            reg(localPoint)
        end
    elseif self.tablet_posX and self.tablet_posY then
        detect(self.tablet_posX, self.tablet_posY)
    end
end

function AnyDisplay:client_onFixedUpdate()
	self.canvas.disable(not isAllow(self))
	if self.c_dataTunnel.renderAtDistance and sc.restrictions.allowDist then
		self.canvas.setRenderDistance()
	else
		self.canvas.setRenderDistance((sc.restrictions and sc.restrictions.rend) or RENDER_DISTANCE)
	end
	self.canvas.update()
    self:audienceCounter(self.canvas.isRendering())

	if self.dragging.interact then
		client_onClick(self, 1, "drag")
	elseif self.dragging.tinker then
		client_onClick(self, 2, "drag")
	end

	if self.character then
        if self.tablet_left ~= self.old_tablet_left then
            self:client_onInteract(nil, not not self.tablet_left)
        end
    
        if self.tablet_right ~= self.old_tablet_right then
            self:client_onTinker(nil, not not self.tablet_right)
        end

        self.old_tablet_left = self.tablet_left
        self.old_tablet_right = self.tablet_right
    else
        if _G.stylus_left ~= self.old_stylus_left then
            self:client_onInteract(nil, not not _G.stylus_left)
        end
    
        if _G.stylus_right ~= self.old_stylus_right then
            self:client_onTinker(nil, not not _G.stylus_right)
        end

        self.old_stylus_left = _G.stylus_left
        self.old_stylus_right = _G.stylus_right
    end
end

function AnyDisplay:client_onInteract(character, state)
    self.dragging.interact = state
    if state then
        local t = self.dragging.interactLastPos
        t.x = -1
        t.y = -1
    end
    client_onClick(self, 1, state and "pressed" or "released")
end

function AnyDisplay:client_onTinker(character, state)
    self.dragging.tinker = state
    if state then
        local t = self.dragging.tinkerLastPos
        t.x = -1
        t.y = -1
    end
    client_onClick(self, 2, state and "pressed" or "released")
end

function AnyDisplay:client_canInteract(character)
	if self.data and self.data.noTouch then
        return false
    end

	return not not (self.c_dataTunnel.clicksAllowed)
end

function AnyDisplay:client_canTinker(character)
	if self.data and self.data.noTouch then
        return false
    end

	return not not (self.c_dataTunnel.clicksAllowed)
end

function AnyDisplay:cl_pushStack(stack)
    if self.sendedData_cl_pushStack then
        if self.sendedData_cl_pushStack.force or needPushStack(self.canvas, self.c_dataTunnel, sc.deltaTime, sc.restrictions.skipFps) then
            local startTime = os.clock()
            self.canvas.pushStack(self.sendedData_cl_pushStack)
            self.canvas.flush()
            self.sendedData_cl_pushStack = nil
            self:lagDetector(os.clock() - startTime, sc.clockLagMul)
        end
        return
    elseif self.stack then
		for _, action in ipairs(stack) do
			table.insert(self.stack, action)
		end
	else
		self.stack = stack
	end

	if stack.flush and (stack.force or needPushStack(self.canvas, self.c_dataTunnel, sc.deltaTime, sc.restrictions.skipFps)) then
        local startTime = os.clock()
		self.canvas.pushStack(self.stack)
		self.canvas.flush()
		self.stack = nil
        self:lagDetector(os.clock() - startTime, sc.clockLagMul)
	end
end

function AnyDisplay:cl_dataTunnel(data)
	self.c_dataTunnel = data
    if data.display_reset then
        self.canvas.drawerReset()
    end
    self.canvas.pushDataTunnelParams(data)
end