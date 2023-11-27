dofile "$CONTENT_DATA/Scripts/Config.lua"

ScriptableComputer = class()

ScriptableComputer.maxParentCount = -1
ScriptableComputer.maxChildCount = -1
ScriptableComputer.connectionInput = sm.interactable.connectionType.composite + sm.interactable.connectionType.logic + sm.interactable.connectionType.power
ScriptableComputer.connectionOutput = sm.interactable.connectionType.composite + sm.interactable.connectionType.logic + sm.interactable.connectionType.power
ScriptableComputer.colorNormal = sm.color.new(0x1a8e15ff)
ScriptableComputer.colorHighlight = sm.color.new(0x23eb1aff)

ScriptableComputer.UV_NON_ACTIVE = 0
ScriptableComputer.UV_ACTIVE_OFFSET = 6
ScriptableComputer.UV_HAS_ERROR = 10
ScriptableComputer.UV_HAS_DISABLED = 9

ScriptableComputer.maxcodesize = 32 * 1024
ScriptableComputer.longOperationMsg = "the computer has been performing the operation for too long"
ScriptableComputer.oftenLongOperationMsg = "the computer exceeded the CPU time limit too often"
ScriptableComputer.lagMsg = "this computer caused lags, please optimize your code or disable 'anti-lag' in 'Permission Tool'"

ScriptableComputer.ledUuid = sm.uuid.new("94c8b309-b6fb-40f8-90bb-b5c3ac28bacd")
ScriptableComputer.stub = "--this computer was saved using SComputers (fork of ScriptableComputer) download: https://steamcommunity.com/sharedfiles/filedetails/?id=2949350596\nif not a then for _,v in ipairs(getDisplays())do v.clear('0A3EE2')v.drawText(1,1,'need','EEEEEE')v.drawText(1,8,'SComputers!','EEEEEE')v.flush()end a=1 end"

----------------------- yield -----------------------

local os_clock = os.clock
function ScriptableComputer:cl_init_yield()
	self.cl_startTickTime = os_clock()
end

function ScriptableComputer:cl_yield()
	local maxcputime = self.localScriptMode.cpulimit or sc.restrictions.cpu
	if os_clock() - self.cl_startTickTime > maxcputime then
		error(ScriptableComputer.longOperationMsg, 3)
	end
end


function ScriptableComputer:sv_init_yield()
	self.sv_startTickTime = os_clock()
end

function ScriptableComputer:sv_yield()
	local maxcputime = self.localScriptMode.cpulimit or sc.restrictions.cpu
	if os_clock() - self.sv_startTickTime > maxcputime then
		if self.sv_patience <= 0 then
			self.storageData.crashstate.hasException = true
			self.storageData.crashstate.exceptionMsg = ScriptableComputer.oftenLongOperationMsg
			self:sv_crash_to_real()
			error(ScriptableComputer.oftenLongOperationMsg, 3)
		else
			self.sv_startTickTime = os_clock() --if an error occurs in the application program of the operating system, the OS should be able to handle the error
			self.sv_patience = self.sv_patience - 1
			error(ScriptableComputer.longOperationMsg, 3)
		end
	end
end

----------------------- SERVER -----------------------

function ScriptableComputer:loadScript()
	self.scriptFunc = nil

	if not self.env then
		self.storageData.crashstate.exceptionMsg = "env is missing"
		self.storageData.crashstate.hasException = true
		self:sv_crash_to_real()
		return
	end

	if not self.storageData.script then
		self.storageData.crashstate.exceptionMsg = "script string is missing"
		self.storageData.crashstate.hasException = true
		self:sv_crash_to_real()
		return
	end

	--local text = self.storageData.script:gsub("%[NL%]", "\n")
	local text = self.storageData.script

	local code, err = safe_load_code(self, text, "=computer_" .. tostring(math.floor(self.shape and self.shape.id or self.tool.id)), "t", self.env)
	if code then
		self.scriptFunc = code
		self.storageData.crashstate.exceptionMsg = nil
		self.storageData.crashstate.hasException = false
	else
		self.scriptFunc = nil
		self.storageData.crashstate.exceptionMsg = err
		self.storageData.crashstate.hasException = true
	end
	self:sv_crash_to_real()

	if self.storageData.crashstate.hasException then
		self:sv_sendException()
	end
end

function ScriptableComputer:forceUpdateWriters()
	for k, v in pairs(self.interactable:getParents(sm.interactable.connectionType.composite)) do
		local writer = sc.writersRefs[v:getId()] 
		if writer then
			writer:server_updateComputerRegisterValue()
		end
	end
end

function ScriptableComputer:updateSharedData()
	if self.interactable then
		sc.computersDatas[self.interactable:getId()] = self.publicTable
		self:forceUpdateWriters()
	end
end



function ScriptableComputer:server_onCreate(constData)
	sc.init()

	if constData then
		self.cdata = constData
	else
		self.cdata = self.data or {}
	end

	------data
	local data = self.storage:load()
	if data then
		self.storageData = data

		if not self.storageData.crashstate then
			self.storageData.crashstate = {}
		end

		if not self.storageData.gsubFix then
			self.storageData.script = self.storageData.script:gsub("%[NL%]", "\n")
			self.storageData.gsubFix = true
		end

		if self.storageData.stub then
			local _, bs64 = unpack(strSplit(string, self.storageData.script, "\n--"))
			self.storageData.script = bs64
		else
			self.storageData.stub = true
		end

		if self.storageData.codeInBase64 then
			self.storageData.script = base64.decode(self.storageData.script)
		else
			self.storageData.codeInBase64 = true
		end

		if self.storageData.crashstate.hasException then
			self:sv_sendException()
		end
	else
		self.storageData = {
			script = "",
			crashstate = {},
			gsubFix = true,
			codeInBase64 = true,
			stub = true
		}

		if self.cdata.unsafe then
			self.storageData.invisible = true
		end	
	end
	
	------env settings

	self.envSettings = {vcomponents = {}}
	if self.cdata and self.cdata.fsSize then
		if self.storageData.fsData then
			self.fs = FileSystem.deserialize(self.storageData.fsData)
		else
			self.fs = FileSystem.new(math.floor(self.cdata.fsSize))
		end
		self.envSettings.vcomponents.disk = {FileSystem.createSelfData(self)}
	end
	
	if self.fs then
		fsmanager_init(self)
	end

	------init

	self.hostonly = not not self.cdata.unsafe

	self.sv_max_patience = 2
	self.sv_patience = self.sv_max_patience
	self.lagScore = 0
	self.skipped = 0
	self.uptime = 0
	self.wait = 5 --во избежании непрогрузки отдельных элементов цепи

	self:sv_reset()
	self:sv_reboot()

	self.old_sum = tableChecksum(self.storageData, "fsData")
end

function ScriptableComputer:sv_crash_to_real()
	self:sv_formatException()
	self.real_crashstate = {
		hasException = self.storageData.crashstate.hasException,
		exceptionMsg = self.storageData.crashstate.exceptionMsg
	}
end

function ScriptableComputer:sv_formatException()
	for k, v in pairs(self.storageData.crashstate) do
		if k ~= "hasException" and k ~= "exceptionMsg" then
			self.storageData.crashstate[k] = nil
		end
	end

	self.storageData.crashstate.hasException = not not self.storageData.crashstate.hasException
	if self.storageData.crashstate.hasException then
		local str = tostring(self.storageData.crashstate.exceptionMsg or "Unknown error"):sub(1, 1024)
		local newstr = {}
		for i = 1, #str do
			local b = str:byte(i)
			if b >= 32 and b <= 126 then
				table.insert(newstr, string.char(b))
			end
		end
		self.storageData.crashstate.exceptionMsg = table.concat(newstr)
		if #self.storageData.crashstate.exceptionMsg == 0 then
			self.storageData.crashstate.exceptionMsg = "Unknown error"
		end
	else
		self.storageData.crashstate.exceptionMsg = nil
	end
end

function ScriptableComputer:server_onDestroy()
	self:sv_disableComponentApi()
	if self.interactable then
		sc.computersDatas[self.interactable:getId()] = nil
	end
end

function ScriptableComputer:server_onFixedUpdate()
	self:sv_createLocalScriptMode()

	if sm.game.getCurrentTick() % (3 * 40) == 0 then
		self.sv_patience = self.sv_max_patience
	end

	if self.reboot_flag then
		self:sv_reboot(true, true)
		self.reboot_flag = nil
		return
	end

	if self.new_code then
		self:sv_updateScript(self.new_code, nil, true)
		self.new_code = nil
	end

	local sendTable = self:sv_genTable()
	local sendSum = tableChecksum(sendTable)
	if sendSum ~= self.old_sendSum then
		--self.network:sendToClients("cl_getParam", sendTable)
		self:sv_onDataRequired()
		self.old_sendSum = sendSum
	end
	
	if #self.clientInvokes > 0 then
		for _, data in ipairs(self.clientInvokes) do
			if data.player then
				local player
				if type(data.player) == "string" then
					for _, lplayer in ipairs(sm.player.getAllPlayers()) do
						if lplayer.name == data.player then
							player = lplayer
							break
						end
					end
				else
					player = data.player
				end

				if player then
					self.network:sendToClient(player, "cl_invokeScript", data)
				end
			else
				self.network:sendToClients("cl_invokeScript", data)
			end
		end
		self.clientInvokes = {}
	end

	if self.interactable then
		self.old_publicData = self.interactable.publicData
		if self.customcomponent_flag then
			self:sv_disableComponentApi(true)
			if self.customcomponent_name and self.customcomponent_api then
				self.interactable.publicData = {
					sc_component = {
						type = self.customcomponent_name,
						api = self.customcomponent_api
					}
				}
			end
			self.customcomponent_flag = nil
		end
	end

	local activeNow = not not (self.storageData.alwaysOn or self.storageData.active_button)
	if self.interactable then
		for k, inter in pairs(self.interactable:getParents(sm.interactable.connectionType.logic)) do
			if inter:isActive() then
				activeNow = true
				break
			end
		end
	end

	--------------------------------------------------------power control

	if self.wait then
		self.wait = self.wait - 1
		if self.wait <= 0 then
			self.wait = nil
		end
	end
	
	if not self.storageData.crashstate.hasException and not self.wait then
		if not activeNow and self.isActive then
			self.uptime = 0
			self:sv_execute(true) --последняя итерация после отключения входа, чтобы отлавить выключения
			self:sv_disableComponentApi()
		end
		
		if activeNow and not self.isActive then
			self.uptime = 0
			self:sv_reboot()
		end

		if activeNow then
			local dropFreq = 0
			if sc.restrictions.adrop then
				if sc.deltaTime >= (1 / 15) then
					dropFreq = 8
				elseif sc.deltaTime >= (1 / 25) then
					dropFreq = 4
				elseif sc.deltaTime >= (1 / 30) then
					dropFreq = 2
				end
			end
			dropFreq = dropFreq + math.floor(self.lagScore / 10)
			if self.lagScore >= 50 then
				dropFreq = dropFreq * 2
			end
			if dropFreq == 1 then dropFreq = 2 end
			if dropFreq == 0 or self.cdata.unsafe or sm.game.getCurrentTick() % dropFreq == 0 then
				self:sv_execute()
				self.skipped = 0
			else
				self.skipped = self.skipped + 1
			end
			self.uptime = self.uptime + 1
		end
	end
	if activeNow ~= self.isActive then
		self.network:sendToClients("cl_setActive", activeNow)
	end
	self.isActive = activeNow

	if sc.rebootAll then
		self:sv_reboot()
	end

	--[[
	if self.storageData.crashstate.hasException then
		self.interactable:setActive(false)
        self.interactable:setPower(0)
	end
	]]

	self:sv_formatException()
	if self.storageData.crashstate.hasException ~= self.oldhasException or
	self.storageData.crashstate.exceptionMsg ~= self.oldexceptionMsg then
		self.oldhasException = self.storageData.crashstate.hasException
		self.oldexceptionMsg = self.storageData.crashstate.exceptionMsg
		self:sv_sendException()
	end

	if sc.needSaveData() then  --saving content
		if self.changed then
			self.storageData.fsData = self.fs:serialize()
			self.changed = nil
	
			self.saveContent = true
		end

		local sum = tableChecksum(self.storageData, "fsData")
		if self.saveContent or self.old_sum ~= sum then
			local newtbl = sc.deepcopy(self.storageData)
			newtbl.script = ScriptableComputer.stub .. "\n--" .. base64.encode(newtbl.script)
			self.storage:save(newtbl)

			self.saveContent = nil
			self.old_sum = sum
		end
	end

	if self.lagScore > 0 then
		self.lagScore = self.lagScore - 1
		if self.lagScore < 0 then
			self.lagScore = 0
		end
	end
end

function ScriptableComputer:sv_createLocalScriptMode()
	self.localScriptMode = {
		scriptMode = sc.restrictions.scriptMode,
		allowChat = sc.restrictions.allowChat
	}

	if self.cdata.unsafe then
		self.localScriptMode.scriptMode = "unsafe"
		self.localScriptMode.allowChat  = true
	end

	if self.cdata.cpulimit then
		self.localScriptMode.cpulimit = self.cdata.cpulimit
	end
end

function ScriptableComputer:sv_genTable()
	local tbl = {
		restrictions = sc.restrictions,
		script = self.storageData.script,
		__lock = self.storageData.__lock,
		alwaysOn = self.storageData.alwaysOn,
		invisible = self.storageData.invisible,
		__permanent_lock_state = self.storageData.__permanent_lock_state,
		__permanent_invisible_state = self.storageData.__permanent_invisible_state,
		fs = not not self.fs,
		scriptMode = self.localScriptMode.scriptMode,
		vm = sc.restrictions.vm,
		allowChat = self.localScriptMode.allowChat,
		hasException = self.storageData.crashstate.hasException,
		computersAllow = _G.computersAllow,
		localScriptMode = self.localScriptMode,
		hostonly = self.hostonly
	}

	if self.storageData.__lock then
		tbl.script = nil
	end

	return tbl
end

function ScriptableComputer:sv_n_reboot()
	self:sv_reboot(true)
end

function ScriptableComputer:sv_disableComponentApi(notRemoveFlags)
	if not self.interactable then return end
	if not notRemoveFlags then
		self.customcomponent_flag = nil
		self.customcomponent_name = nil
		self.customcomponent_api = nil
	end

	if self.old_publicData and self.old_publicData.sc_component and self.old_publicData.sc_component.api then
		for key, value in pairs(self.old_publicData.sc_component.api) do
			self.old_publicData.sc_component.api[key] = nil
		end
		self.old_publicData.sc_component.api = nil
		self.old_publicData.sc_component.name = nil
		self.old_publicData.sc_component = nil
		if sm.exists(self.interactable) then
			self.interactable.publicData = {}
		end
	end
end

function ScriptableComputer:sv_reset()
	self:sv_createLocalScriptMode()
	self.clientInvokes = {}
	self.componentCache = {}
	self.luastate = {}
	self.libcache = {}
	self.registers = {}
	self.uptime = 0
	self.env = self.localScriptMode.scriptMode == "unsafe" and createUnsafeEnv(self, self.envSettings) or createSafeEnv(self, self.envSettings)
	self.publicTable = {
		public = {
			registers = self.registers,
			env = self.env,
			crashstate = self.storageData.crashstate
		},
		self = self
	}
	self:updateSharedData()
end

function ScriptableComputer:sv_reboot(force, not_execute)
	local fromException = self.storageData.crashstate.hasException
	if force and self.storageData.crashstate.hasException then
		self.storageData.crashstate.hasException = nil
		self.storageData.crashstate.exceptionMsg = nil
		self:sv_sendException()
	end

	if self.storageData.crashstate.hasException then
		return
	end

	self.storageData.crashstate.hasException = nil
	self.storageData.crashstate.exceptionMsg = nil
	self.oldhasException = nil
	self.oldexceptionMsg = nil

	if self.isActive and not not_execute and not fromException then
		self:sv_execute(true) --последняя итерация после отключения входа, чтобы отлавить выключения
	end

	----------------------------

	self:sv_reset()
	self:loadScript()
	self:sv_disableComponentApi()
	self.network:sendToClients("cl_clear")
	self:sv_crash_to_real()
end

function ScriptableComputer:sv_sendException()
	self:sv_crash_to_real()
	if self.storageData.crashstate.hasException then
		self:sv_disableComponentApi()
		print("computer crashed", self.storageData.crashstate.exceptionMsg)
		self.network:sendToClients("cl_onComputerException", self.storageData.crashstate.exceptionMsg)
	else
		self.network:sendToClients("cl_onComputerException")
	end
end

function ScriptableComputer:sv_execute(endtick)
	tweaks()
	sc.lastComputer = self

	if self.scriptFunc and _G.computersAllow then
		local startExecTime = os.clock()

		if not self.env then
			self.storageData.crashstate.hasException = true
			self.storageData.crashstate.exceptionMsg = "Unknown error"
			self:sv_crash_to_real()
			return
		end

		if endtick then
			self.env._endtick = true
		end

		--if sc.restrictions.vm == "luaInLua" then
		--	ll_Interpreter:reset()
		--end
		
		local func
		if self.env and self.env.callback_loop then
			func = self.env.callback_loop
		else
			func = self.scriptFunc
		end
		
		self:sv_init_yield()
		local ran, err = pcall(func)
		do
			local lok, lerr = pcall(function(self) self:sv_yield() end, self) --касыль с лямбдой НУЖЕН для правильного разположения ошибки
			if not lok and not err then
				self.storageData.crashstate.hasException = true
				self.storageData.crashstate.exceptionMsg = lerr
				self:sv_crash_to_real()
			end
		end

		if self.storageData.crashstate.hasException then
			return
		end

		if ran and self.lagScore > 100 then
			self.lagScore = 0
			self.storageData.crashstate.hasException = true
			self.storageData.crashstate.exceptionMsg = ScriptableComputer.lagMsg
			self:sv_crash_to_real()
		end
		
		if not ran then
			if sc.restrictions.vm == "luaInLua" then
				err = ll_shorterr(err)
			end

			self.storageData.crashstate.hasException = true
			self.storageData.crashstate.exceptionMsg = err
			self:sv_crash_to_real()
			
			if self.env.callback_error then
				self:sv_init_yield()
				local ran, err = pcall(self.env.callback_error, err)
				if not ran then
					print("error in callback_error", err)
				end
			end
		end

		sc.addLagScore((os.clock() - startExecTime) * sc.clockLagMul)
	end

	unTweaks()
	sc.lastComputer = nil
end

function ScriptableComputer:sv_updateData(data)
	if self.storageData.__lock then
		return
	end

	for key, value in pairs(data) do --чтобы не перетереть ключи которых нет на клиенте(по этому тут цикл а не просто присвоения)
		self.storageData[key] = value
	end
end

------------network
function ScriptableComputer:sv_updateScript(data, caller, notReboot)
	if caller and self:needBlockCall(caller) then return end

	if caller and self.storageData.__lock then
		return
	end

	if not data or #data > ScriptableComputer.maxcodesize then
		if caller then
			self.network:sendToClient(caller, "cl_internal_alertMessage", "the maximum amount of code is 32 KB")
		end
		return
	end

	self.storageData.script = data
	if not notReboot then
		self:sv_reboot(true)
	end

	for _, player in ipairs(sm.player.getAllPlayers()) do
		if not caller or player ~= caller then
			if not self.storageData.__lock then
				self.network:sendToClient(player, "cl_updateScript", self.storageData.script)
			else
				self.network:sendToClient(player, "cl_updateScript")
			end
		end
	end
end

function ScriptableComputer:sv_onDataRequired(_, client)
	local players
	if client then
		players = {client}
	else
		players = sm.player.getAllPlayers()
	end
	
	for index, lclient in ipairs(players) do
		if not self:needBlockCall(lclient) then
			if client then
				if not self.storageData.__lock then
					self.network:sendToClient(lclient, "cl_updateScript", self.storageData.script)
				else
					self.network:sendToClient(lclient, "cl_updateScript")
				end
			end
			self.network:sendToClient(lclient, "cl_getParam", self:sv_genTable())
			self.network:sendToClient(lclient, "cl_setActive", self.isActive)

			if self.cdata.arduino then
				self.network:sendToClient(lclient, "cl_createEffect")
			end
		end
	end
end

function ScriptableComputer:needBlockCall(caller)
	if self.hostonly and caller.id ~= vnetwork.host.id then
		return true
	end
end

----------------------- CLIENT -----------------------

function ScriptableComputer.client_onCreate(self)
	self.network:sendToServer("sv_onDataRequired")
	self.last_script = ""
end

function ScriptableComputer.client_onFixedUpdate(self, dt)
	if not self.cStorageData then return end

	if not sm.isHost and self.cStorageData.hostonly and self.interact then
		self:cl_internal_alertMessage("#ff0000only the host can open unsafe-computer")
		self.interact = nil
		self.flag1 = nil
		self.flag2 = nil
	end

	if self.interactable then
		local uvpos
		local isActive = self.interactable:isActive()
		if isActive then
			uvpos = ScriptableComputer.UV_NON_ACTIVE + ScriptableComputer.UV_ACTIVE_OFFSET
		else
			uvpos = ScriptableComputer.UV_NON_ACTIVE
		end

		if self.cStorageData.hasException or not self.cStorageData.computersAllow then
			local uv = ScriptableComputer.UV_HAS_ERROR
			if not self.cStorageData.computersAllow then
				uv = ScriptableComputer.UV_HAS_DISABLED
			end

			local blk = (sm.game.getCurrentTick() % 60 >= 30)
			self.interactable:setUvFrameIndex(blk and uv or uvpos)
			if self.led_eff then
				self.led_eff:setParameter("color", sm.color.new(1, 0, 0))
				if blk then
					if not self.led_eff:isPlaying() then
						self.led_eff:start()
					end
				else
					self.led_eff:stop()
				end
			end
		else
			self.interactable:setUvFrameIndex(uvpos)
			if self.led_eff then
				self.led_eff:setParameter("color", sm.color.new(0, 1, 0))
				if isActive then
					if not self.led_eff:isPlaying() then
						self.led_eff:start()
					end
				else
					self.led_eff:stop()
				end
			end
		end

		if self.pwr_eff then
			if self.clIsActive then
				if not self.pwr_eff:isPlaying() then
					self.pwr_eff:start()
				end
			else
				self.pwr_eff:stop()
			end
		end
	end

	if self.gui and self.tmpData then
		if not self.gui:isActive() and self.tmpDataUpdated then
			self.cStorageData.__lock = self.tmpData.__lock
			self.cStorageData.__permanent_lock_state = self.tmpData.__permanent_lock_state
			self.cStorageData.__permanent_invisible_state = self.tmpData.__permanent_invisible_state

			self.network:sendToServer("sv_updateData", self.cStorageData)
			self.tmpDataUpdated = nil
		end

		if sc.restrictions then
			self.gui:setText("scrMode", "Script Mode: " .. self.cStorageData.vm .. "-" .. sc.restrictions.scriptMode .. "-" .. (sc.restrictions.allowChat and "printON" or "printOFF"))
		end
		self.gui:setText("lscrMode", "Local Script Mode: " .. self.cStorageData.vm .. "-" .. self.cStorageData.scriptMode .. "-" .. (self.cStorageData.allowChat and "printON" or "printOFF"))
		
		self.gui:setButtonState("alwaysOn", self.cStorageData.alwaysOn)
		self.gui:setButtonState("editLock", self.tmpData.__lock)
		self.gui:setButtonState("invisible", self.cStorageData.invisible)


		--self.gui:setButtonState("notsaved", self.cStorageData.script ~= string.gsub(self.last_code, "\n", "%[NL%]"))
		local script = self.cStorageData.script or self.old_script
		self.gui:setButtonState("notsaved", script ~= self.last_script)
		self.gui:setButtonState("lperm", self.tmpData.__permanent_lock_state)
		self.gui:setButtonState("linvs", self.tmpData.__permanent_invisible_state)
	end

	if self.interact and not self.flag1 and not self.flag2 then
		self.interact = nil

		self:cl_createGUI()
		self.gui:setText("lastMessage", "")

		if not self.cStorageData.computersAllow then
			self:cl_internal_alertMessage("computers are disabled in this game session")
		end

		if self.cStorageData.__lock then
			self:cl_internal_alertMessage("this computer is locked")
			return
		end

		self.gui:setText("ScriptData", formatBeforeGui(self.last_script))
		self.gui:open()
	end
end

function ScriptableComputer.client_onDestroy(self)
	if self.gui then
		self.gui:destroy()
	end
end

function ScriptableComputer.client_onInteract(self, _, state)
	if state then
		self.network:sendToServer("sv_onDataRequired", sm.localPlayer.getPlayer())

		self.tmpData = {}
		for key, value in pairs(self.cStorageData) do
			self.tmpData[key] = value
		end

		self.flag1 = true
		self.flag2 = true
		self.interact = true
	end
end

function ScriptableComputer:cl_createEffect()
	if not self.pwr_eff then
		self.pwr_eff = sm.effect.createEffect(sc.getEffectName(), self.interactable)
		self.led_eff = sm.effect.createEffect(sc.getEffectName(), self.interactable)

		self.pwr_eff:setParameter("color", sm.color.new(1, 0, 0))

		self.pwr_eff:setParameter("uuid", ScriptableComputer.ledUuid)
		self.led_eff:setParameter("uuid", ScriptableComputer.ledUuid)

		self.pwr_eff:setScale(sm.vec3.new(0.03, 0.02, 0.01))
		self.led_eff:setScale(sm.vec3.new(0.03, 0.02, 0.01))

		self.pwr_eff:setOffsetPosition(sm.vec3.new(0.27, 0.095, -0.11))
		self.led_eff:setOffsetPosition(sm.vec3.new(-0.03, 0.15, -0.11))
	end
end

function ScriptableComputer:cl_setActive(isActive)
	self.clIsActive = isActive
end

------------gui
function ScriptableComputer:cl_createGUI()
	if self.gui then return end
	
	self.gui = sm.gui.createGuiFromLayout("$CONTENT_DATA/Gui/Layouts/ComputerMenu.layout", false)
	self.gui:setButtonCallback("ScriptSave", "cl_onSaveScript")
	self.gui:setButtonCallback("CloseGui", "cl_onCloseGui")
	self.gui:setTextChangedCallback("ScriptData", "cl_onScriptDataChanged")

	self.gui:setButtonCallback("openStorage", "cl_openStorage")
	
	self.gui:setText("ExceptionData", "No errors")

	self.gui:setButtonCallback("alwaysOn", "cl_onCheckbox")
	self.gui:setButtonCallback("editLock", "cl_onCheckbox")
	self.gui:setButtonCallback("invisible", "cl_onCheckbox")
	self.gui:setButtonCallback("reboot", "cl_reboot")

	self.gui:setButtonCallback("lperm", "cl_onCheckbox")
	self.gui:setButtonCallback("linvs", "cl_onCheckbox")

	bindExamples(self)
end

function ScriptableComputer:cl_openStorage()
	if self.cStorageData.__lock then
		self:cl_internal_alertMessage("this computer is locked")
		return
	end

	if not self.cStorageData.fs then
		self:cl_internal_alertMessage("this computer is not contain internal storage")
		return
	end

	self.gui:close()
	fsmanager_init(self)
	fsmanager_open(self)
end

function ScriptableComputer:cl_reboot()
	self.network:sendToServer("sv_n_reboot")
end

function ScriptableComputer:cl_onCheckbox(widgetName)
	if widgetName == "alwaysOn" then
		self.cStorageData.alwaysOn = not self.cStorageData.alwaysOn
	elseif widgetName == "editLock" then
		if not self.tmpData.__permanent_lock_state then
			self.tmpData.__lock = not self.tmpData.__lock
			self.tmpDataUpdated = true
		else
			self:cl_internal_alertMessage("the lock status is permanent")
		end
	elseif widgetName == "invisible" then
		if not self.cStorageData.__permanent_invisible_state then
			self.cStorageData.invisible = not self.cStorageData.invisible
		else
			self:cl_internal_alertMessage("the invisible status is permanent")
		end
	elseif widgetName == "lperm" then
		if not self.tmpData.__permanent_lock_state then
			self.tmpData.__permanent_lock_state = true
			self.tmpDataUpdated = true
		else
			self:cl_internal_alertMessage("this parameter is permanent")
		end
	elseif widgetName == "linvs" then
		if not self.tmpData.__permanent_invisible_state then
			self.tmpData.__permanent_invisible_state = true
			self.tmpDataUpdated = true
		else
			self:cl_internal_alertMessage("this parameter is permanent")
		end
	end

	self.network:sendToServer("sv_updateData", self.cStorageData)
end

function ScriptableComputer.cl_onScriptDataChanged(self, widgetName, data)
	--self.oldtext = data
	self.last_script = formatAfterGui(data)
end

function ScriptableComputer.cl_onSaveScript(self)
	--self.gui:setText("ExceptionData", "No errors")

	if #self.last_script > ScriptableComputer.maxcodesize then
		self:cl_internal_alertMessage("the maximum amount of code is 32 KB")
		--self.network:sendToServer("sv_updateScript")
	else
		self.network:sendToServer("sv_updateScript", self.last_script)
	end
end

function ScriptableComputer.cl_onCloseGui(self)
	self.gui:close()
end



------------network
function ScriptableComputer:cl_invokeScript(tbl)
	local script, isSafe, args = unpack(tbl)
	--script = script:gsub("%[NL%]", "\n")

	local env
	if self.client_env and isSafe == self.client_env_isSafe then
		env = self.client_env
	else
		env = isSafe and createSafeEnv(self) or createUnsafeEnv(self)
		removeServerMethods(env)
		self.client_env = env
		self.client_env_isSafe = isSafe
	end
	
	--if self.cStorageData.restrictions.vm == "luaInLua" then
	--	ll_Interpreter:reset()
	--end

	local code, err = safe_load_code(self, script, "=client_invoke", "t", env)
	if not code then
		print("client invoke syntax error: " .. (err or "Unknown error"))
		return
	end

	self:cl_init_yield()

	tweaks()
	sc.lastComputer = self
	local ran, err = pcall(code, unpack(args))
	unTweaks()
	sc.lastComputer = nil

	if not ran then
		print("client invoke error: " .. (err or "Unknown error"))
	end
end

function ScriptableComputer:cl_clear()
	self.client_env = nil
	self.client_env_isSafe = nil
end

function ScriptableComputer:cl_onComputerException(msg)
	self:cl_createGUI()

	if msg then msg = formatBeforeGui(msg) end
	self.gui:setText("ExceptionData", msg or "No errors")
end

function ScriptableComputer:cl_getParam(data)
	self.flag2 = nil
	self.cStorageData = data

	if sm.isHost then return end
	self.localScriptMode = data.localScriptMode
end

function ScriptableComputer:cl_updateScript(code)
	self.flag1 = nil

	if code then
		self.last_script = code
		self.old_script = code

		self:cl_createGUI()
		if self.gui:isActive() then
			self.gui:setText("ScriptData", formatBeforeGui(code))
		end
	end
end

function ScriptableComputer:cl_onExample(name)
	loadExample(self, name)
end

function ScriptableComputer:cl_chatMessage(msg)
	--msg = msg:gsub("%[NL%]", "\n")
	--sm.gui.chatMessage("[SComputers]: " .. msg)
	sm.gui.chatMessage(msg)
end

function ScriptableComputer:cl_alertMessage(msg)
	--msg = msg:gsub("%[NL%]", "\n")
	sm.gui.displayAlertText(msg, 4)
end

function ScriptableComputer:cl_internal_alertMessage(msg)
	--msg = msg:gsub("%[NL%]", "\n")
	self:cl_createGUI()
	self.gui:setText("lastMessage", msg)
	sm.gui.displayAlertText(msg)
end

function ScriptableComputer:cl_setText(code)
	self.last_script = code
	self.gui:setText("ScriptData", formatBeforeGui(code))
end