local function checkAllowMessage(self)
    if not self.localScriptMode.allowChat then
        error("print/alert/debug methods are disabled", 3)
    end
    return self.localScriptMode.allowChat
end

local function makeMsg(...)
    local printResult = ""
    local args = {...}
    local len = 0
    for i in pairs(args) do
        if i > len then
            len = i
        end
    end
    
    for i = 1, len do
        local str = tostring(args[i])
        printResult = printResult .. str
        if i ~= len then
            local strlen = #str
            local dtablen = 8
            local tablen = 0
            while tablen <= 0 do
                tablen = dtablen - strlen
                dtablen = dtablen + 8
            end
            printResult = printResult .. string.rep(" ", tablen * 2)
        end
    end

    --printResult = string.gsub(printResult, "\n", "%[NL%]")
    return printResult
end
local jsonEncodeInputCheck = jsonEncodeInputCheck


function createSafeEnv(self, settings)
    --[[
    local function getScriptTree(script)
        local ran, tokens = pcall(ll_Scanner.scan, ll_Scanner, script)
        if ran then
            local ran, tree = pcall(ll_Parser.parse, ll_Parser, tokens)
            return ran, tree
        else
            return ran, tokens
        end
    end
    ]]

    --методы ninput, input, getChildComputers, getParentComputers были переделанны на ipairs вместо pairs
    --чтобы сохранялся порядок подключений

    local bit32 = _G.bit32 or _G.bit --я знаю что это странно
    local bit = _G.bit or _G.bit32

    local pcall, xpcall = pcall, xpcall

	local env
	env = {
        _VERSION = sc.restrictions.vm,
        
        require = function (name)
            checkArg(1, name, "string")
            sc.coroutineCheck()
            if name:find("%.") or name:find("%/") or name:find("%\\") then error("the library name cannot contain the characters: \"/.\\\"", 2) end
            if self.libcache[name] then return self.libcache[name] end
            if dlm and dlm.loadfile then
                local code, err = dlm.loadfile("$CONTENT_3aeb81c2-71b9-45a1-9479-1f48f1e8ff21/Scripts/internal_libs/" .. name .. ".lua", _G)
                if type(code) ~= "function" then
                    error("load error: " .. tostring(err or "unknown"), 2)
                end

                local result = {pcall(code)}
                if not result[1] or type(result[2]) ~= "table" then
                    error("exec error: " .. tostring(result[2] or "unknown"), 2)
                end

                self.libcache[name] = result[2]
            else
                if not _G.internal_libs[name] then
                    pcall(dofile, "$CONTENT_DATA/Scripts/internal_libs/" .. name .. ".lua")
                end
                self.libcache[name] = sc.advDeepcopy(_G.internal_libs[name])
            end
            return self.libcache[name] or error("the \"" .. name .. "\" library was not found", 2)
        end,

        checkArg = checkArg, --это не стандартный метод lua он был взят из opencomputers(machine.lua) и определен в methods.lua
        class = class,

		alert = function (...)
            sc.coroutineCheck()
            if checkAllowMessage(self) then
                local msg = makeMsg(...)
                if sm.isServerMode() then
                    sc.lastComputer.network:sendToClients("cl_alertMessage", msg)
                else
                    sc.lastComputer:cl_alertMessage(msg)
                end
            end
		end,
        print = function (...)
            sc.coroutineCheck()
            if checkAllowMessage(self) then
                local msg = makeMsg(...)
                if sm.isServerMode() then
                    sc.lastComputer.network:sendToClients("cl_chatMessage", msg)
                else
                    sc.lastComputer:cl_chatMessage(msg)
                end
            end
		end,
		debug = function (...)
            if checkAllowMessage(self) then
                print(...)
            end
        end,
		tostring = tostring,
		tonumber = tonumber,
		type = type,

        utf8 = sc.deepcopy(utf8),
		string = sc.deepcopy(string),
		table = sc.deepcopy(table),
		math = sc.deepcopy(math),
		bit = sc.deepcopy(bit),
        bit32 = sc.deepcopy(bit32),
		os = {
			clock = os.clock,
			date = os.date, --os.data is not in Scrap Mechanic, but if it appears, it will appear in SComputers
			difftime = os.difftime,
			--execute = os.execute,
			--exit = os.exit,
			--getenv = os.getenv,
			--remove = os.remove,
			--rename = os.rename,
			--setlocale = os.setlocale,
			time = os.time,
			--tmpname = os.tmpname
		},


		assert = assert,
		error = error,
		ipairs = ipairs,
		pairs = pairs,
		next = next,
		pcall = function (...)
            sc.yield()
            local ret = {pcall(...)}
            sc.yield()
            return unpack(ret)
        end,
		xpcall = function (...)
            sc.yield()
            local ret = {xpcall(...)}
            sc.yield()
            return unpack(ret)
        end,
		select = select,
		unpack = unpack,

		getmetatable = function (t) return t.__metatable or {} end,
		setmetatable = function (t1, t2) t1.__metatable = t2 end,

        sm = {
            vec3 = sc.deepcopy(sm.vec3),
            util = sc.deepcopy(sm.util),
            quat = sc.deepcopy(sm.quat),
            noise = sc.deepcopy(sm.noise),
            color = sc.deepcopy(sm.color),
            uuid = sc.deepcopy(sm.uuid),
            json = {
                parseJsonString = function (str)
                    checkArg(1, str, "string")
                    return sm.json.parseJsonString(str)
                end,
                writeJsonString = function (obj)
                    checkArg(1, obj, "table")
                    jsonEncodeInputCheck(obj, 0)
                    return sm.json.writeJsonString(obj)
                end,
            },
            game = {
                getCurrentTick = sm.game.getCurrentTick,
                getServerTick = sm.game.getServerTick
            }
        },

        getreg = function (n) return self.registers[n] end,
        setreg = function (n, v)
            if type(v) == "boolean" or type(v) == "number" then
                self.registers[n] = v
            else
                error("Value must be number or boolean", 2)
            end
        end,

        out = function (p)
            sc.coroutineCheck()
            if not self.interactable then return end

            if type(p) == "number" then
                self.interactable:setActive(p ~= 0)
                self.interactable:setPower(p)
            elseif type(p) == "boolean" then
                self.interactable:setActive(p)
                self.interactable:setPower(p and 1 or 0)
            else
                error("Type must be number or boolean", 2)
            end
        end,

        input = function (color)
            sc.coroutineCheck()
            if not self.interactable then return false end

            if color then
                color = sc.formatColorStr(color)
                
                for i, v in ipairs(self.interactable:getParents(sm.interactable.connectionType.logic)) do
                    local p_color = sc.formatColorStr(v.shape.color)
                    
                    if p_color == color and v:isActive() then
                        return true
                    end
                end
            else
                for i, v in ipairs(self.interactable:getParents(sm.interactable.connectionType.logic)) do
                    if v:isActive() then
                        return true
                    end
                end
            end
            return false
        end,

        ninput = function (color)
            sc.coroutineCheck()
            if not self.interactable then return {} end

            if color then
                color = sc.formatColorStr(color)

                local out = {}
                for i, v in ipairs(self.interactable:getParents()) do
                    local p_color = sc.formatColorStr(v.shape.color)
                    if p_color == color then
                        table.insert(out, v:getPower())
                    end
                end
                return out
            else
                local out = {}
                for i, v in ipairs(self.interactable:getParents()) do
                    table.insert(out, v:getPower())
                end
                return out
            end
        end,

        clearregs = function ()
            for k in pairs(self.registers) do
                self.registers[k] = nil
            end
        end,

        getParentComputers = function ()
            sc.coroutineCheck()
            if not self.interactable then return {} end

            local ret = {}
            local datas = sc.computersDatas
            for i, v in ipairs(self.interactable:getParents(sm.interactable.connectionType.composite)) do
                local data = datas[v:getId()]
                if data and not data.self.storageData.invisible and data.public then
                    table.insert(ret, data.public)
                end
            end
            return ret
        end,

        getChildComputers = function ()
            sc.coroutineCheck()
            if not self.interactable then return {} end
            
            local ret = {}
            local datas = sc.computersDatas
            for i, v in ipairs(self.interactable:getChildren(sm.interactable.connectionType.composite)) do
                local data = datas[v:getId()]
                if data and not data.self.storageData.invisible and data.public then
                    table.insert(ret, data.public)
                end
            end
            return ret
        end,


        load = function (chunk, chunkname, mode, lenv)
			return safe_load_code(self, chunk, chunkname, mode, lenv or env)
		end,

        loadstring = function (chunk, lenv)
            local ret = {safe_load_code(self, chunk, nil, "t", lenv or env)}
            if not ret[1] then
                error(ret[2], 2)
            end
            return unpack(ret)
        end,

        execute = function (chunk, lenv, ...)
            local ret = {safe_load_code(self, chunk, nil, "t", lenv or env)}
            if not ret[1] then
                error(ret[2], 2)
            end
            return ret[1](...)
        end,

        

		setLock = function (state, permanent)
            checkArg(1, state, "boolean", "nil")
            checkArg(2, permanent, "boolean", "nil")
            state = not not state
            permanent = not not permanent

            if not self.storageData.__permanent_lock_state then
                self.storageData.__lock = state
                self.storageData.__permanent_lock_state = permanent
                return
            end
            error("the lock status is permanent", 2)
		end,
        getLock = function ()
			return not not self.storageData.__lock, not not self.storageData.__permanent_lock_state
		end,



        setCode = function (code)
            checkArg(1, code, "string")
            if #code > self.maxcodesize then
                error("the maximum amount of code is 32 KB", 2)
            end
            self.new_code = code
            sc.addLagScore(4)
        end,
        getCode = function ()
            return self.storageData.script or ""
        end,
        


        setData = function (data)
            checkArg(1, data, "string")
            if #data > (1024 * 4) then
                error("the maximum amount of userdata is 4kb", 2)
            end
            self.storageData.userdata = base64.encode(data)
            self.storageData.userdata_bs64 = true
            sc.addLagScore(4)
        end,
        getData = function ()
            if self.storageData.userdata then
                if self.storageData.userdata_bs64 then
                    return (base64.decode(self.storageData.userdata))
                else
                    return self.storageData.userdata
                end
            else
                return ""
            end
        end,
        


        setInvisible = function (state, permanent) --make computer invisible for other computers
            checkArg(1, state, "boolean", "nil")
            checkArg(2, permanent, "boolean", "nil")
            state = not not state
            permanent = not not permanent

            if not self.storageData.__permanent_invisible_state then
                self.storageData.invisible = state
                self.storageData.__permanent_invisible_state = permanent
                return
            end
            error("the invisible status is permanent", 2)
        end,
        getInvisible = function ()
            return not not self.storageData.invisible, not not self.storageData.__permanent_invisible_state
        end,



        setAlwaysOn = function (state)
            checkArg(1, state, "boolean")
            self.storageData.alwaysOn = state
        end,
        getAlwaysOn = function ()
            return not not self.storageData.alwaysOn
        end,



        setComponentApi = function (name, api)
            checkArg(1, name, "string", "nil")
            checkArg(2, api,  "table",  "nil")
            if name and api then
                self.customcomponent_name = name
                self.customcomponent_api = api
            end
            self.customcomponent_flag = true
        end,
        getComponentApi = function ()
            return self.customcomponent_name, self.customcomponent_api
        end,


        
        reboot = function ()
            --self:sv_reboot(true, true)

            local noSoftwareReboot = {
                [ScriptableComputer.oftenLongOperationMsg] = true,
                [ScriptableComputer.lagMsg] = true
            }

            if self.real_crashstate and noSoftwareReboot[self.real_crashstate.exceptionMsg] then
                error("this computer cannot be restarted programmatically", 2)
            end
            
            self.reboot_flag = true
        end,
        getCurrentComputer = function ()
            return self.publicTable.public
        end,
        getComponents = function (name)
            checkArg(1, name, "string")
            sc.coroutineCheck()
            return sc.getComponents(self, name, settings)
        end,
        getMaxAvailableCpuTime = function ()
            return round(self.localScriptMode.cpulimit or sc.restrictions.cpu, 5)
        end,

        getDeltaTime = function ()
            return sc.deltaTime or 0
        end,
        getSkippedTicks = function ()
            return self.skipped
        end,
        getLagScore = function ()
            return self.lagScore
        end,
        getUptime = function ()
            return self.uptime
        end,

        --limitations of the amount of RAM in development
        getUsedRam = function ()
            return self.usedRam
        end,
        getTotalRam = function ()
            return self.cdata.ram
        end
	}

    ---------------- dlm

    local coroutine = sc.getApi("coroutine")
    if coroutine then
        env.coroutine = sc.deepcopy(coroutine)
    end

    ---------------- links

    env.table.unpack = env.unpack

    env._G = env
    env._ENV = env
    env.sci = env --для совместимости

    ---------------- legacy
    
    env.getDisplays = function ()
        return env.getComponents("display")
    end

    env.getMotors = function ()
        return env.getComponents("motor")
    end
    
    env.getRadars = function ()
        return env.getComponents("radar")
    end
    
    env.getPorts = function ()
        return env.getComponents("port")
    end

    env.getDisks = function ()
        return env.getComponents("disk")
    end

    env.getCameras = function ()
        return env.getComponents("camera")
    end

    env.getHoloprojectors = function ()
        return env.getComponents("holoprojector")
    end

    env.getSynthesizers = function ()
        return env.getComponents("synthesizer")
    end

    env.getLeds = function ()
        return env.getComponents("led")
    end

    env.getKeyboards = function ()
		return env.getComponents("keyboard")
	end

    env.getParentComputersData = env.getParentComputers
    env.getChildComputersData = env.getChildComputers
    env.getConnectedDisplaysData = env.getDisplays
    env.getConnectedMotorsData = env.getMotors
    env.getConnectedRadarsData = env.getRadars

    env.getLagsScore = env.getLagScore

    ---------------- safety

    if env.coroutine then
        local function disableCoroutine(api)
            for funcname, func in pairs(api) do
                api[funcname] = function (...)
                    sc.coroutineCheck()
                    local result = {pcall(func, ...)}
                    if result[1] then
                        return unpack(result, 2)
                    else
                        error(result[2], 2)
                    end
                end
            end
        end

        for apiname, api in pairs(env.sm) do
            disableCoroutine(api) --you can't call scrapmechanic methods from coroutine because it calls bugsplat
        end
    end    

    local positiveModulo = sm.util.positiveModulo
    env.sm.util.positiveModulo = function (x, n) --для предотвашения bugsplat(зашита от дебилов/рукожопов)
        if n ~= 0 then
            return positiveModulo(x, n)
        end
        error("cannot be divided by 0", 2)
    end

    env.math.randomseed = nil --this method is not in the game, but if it is added, it STILL should not be in SComputers
    env.string.rep = customRep --in the case of ("str").rep(), the "tweaks" method in the methods.lua file will work

	return env
end

function createUnsafeEnv(self, settings)
	local env = createSafeEnv(self, settings)

	env.global = _G
	env.self = self
	env.sm = sm
    env.dlm = dlm

    env.clientInvoke = function (code, ...)
        checkArg(1, code, "string")
        table.insert(self.clientInvokes, {code, self.localScriptMode.scriptMode == "safe", {...}})
    end

    env.clientInvokeTo = function (player, code, ...)
        checkArg(1, player, "string", "Player")
        checkArg(2, code, "string")
        table.insert(self.clientInvokes, {code, self.localScriptMode.scriptMode == "safe", {...}, player = player})
    end

	return env
end

function removeServerMethods(env) --called before execution clientInvoke
    env.getComponents = nil
    env.reboot = nil
    env.setCode = nil
    env.getCode = nil
    env.getData = nil
    env.setData = nil
    env.setLock = nil
    env.getLock = nil
    env.setAlwaysOn = nil
    env.getAlwaysOn = nil
    env.setInvisible = nil
    env.getInvisible = nil
    env.getCurrentComputer = nil
    env.getChildComputers = nil
    env.getParentComputers = nil
    env.clearregs = nil
    env.getreg = nil
    env.setreg = nil
    env.ninput = nil
    env.input = nil
    env.out = nil
    env.getParentComputersData = nil
    env.getChildComputersData = nil
    env.getConnectedDisplaysData = nil
    env.getConnectedMotorsData = nil
    env.getConnectedRadarsData = nil
    env.getDisplays = nil
    env.getMotors = nil
    env.getRadars = nil
    env.getPorts = nil
    env.getDisks = nil
    env.getCameras = nil
    env.getHoloprojectors = nil
    env.getSynthesizers = nil
    env.getLeds = nil
    env.getKeyboards = nil
    env.setComponentApi = nil
    env.getComponentApi = nil
    env.getMaxAvailableCpuTime = nil
    env.getDeltaTime = nil
    env.getUsedRam = nil
    env.getTotalRam = nil
    env.getUptime = nil
end