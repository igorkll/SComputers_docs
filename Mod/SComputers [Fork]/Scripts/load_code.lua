local pcall, unpack, error, pairs, type = pcall, unpack, error, pairs, type

function injectService(self, code, env) --спизженно с: https://github.com/Ocawesome101/oc-cynosure/blob/dev/base/load.lua
    local computer = self
    local yieldName = self.yieldName
    local yieldArg = self.yieldArg

    local yield
    if sm.isServerMode() then
        yield = self.sv_yield
    else
        yield = self.cl_yield
    end

    local mathram_doTable
    local analysis = false

    do
        local smartYield = sc.smartYield

        local function doObj(parsed, val)
            local ctype = type(val)
            if ctype == "table" then
                return mathram_doTable(parsed, val) + 16
            elseif ctype == "number" then
                return 4
            elseif ctype == "string" then
                return #val
            elseif ctype == "boolean" then
                return 1
            else
                return 1024
            end
        end

        function mathram_doTable(parsed, tbl)
            if parsed[tbl] then return 0 end
            parsed[tbl] = true

            local usedRam = 0
            for k, v in pairs(tbl) do
                smartYield(self)
                usedRam = usedRam + doObj(parsed, k)
                usedRam = usedRam + doObj(parsed, v)
            end
            return usedRam
        end
    end

    local function errCheck(func, ...)
        local result = {pcall(func, ...)}
        if result[1] then
            return unpack(result, 2)
        else
            analysis = false
            error(result[2], 3)
        end
    end

    local function local_yield(arg, locals)
        if arg ~= self.yieldArg then
            error("yield abuse detected", 2)
        else
            yield(self)
        end

        --[[
        --RAM limitations in development
        if not analysis then
            analysis = true

            local parsed = {}
            local usedRamGlobals = errCheck(mathram_doTable, parsed, self.env)
            local usedRamLocals = 0
            if locals then
                usedRamLocals = errCheck(mathram_doTable, parsed, locals)
            end

            local usedRam = usedRamGlobals + usedRamLocals
            if usedRam > self.cdata.ram then
                analysis = false
                error("not enough memory", 2)
            end

            self.usedRam = usedRam
            analysis = false
        end
        ]]
    end

    local setmetatable = sc.getApi("setmetatable")
    local getmetatable = sc.getApi("getmetatable")
    if setmetatable and getmetatable then
        setmetatable(env, nil)
        env[yieldName] = nil
        setmetatable(env,
            {
                __index = {
                    [yieldName] = local_yield
                },
                __newindex = function (self, key, value)
                    if key == yieldName then
                        error("failed to rewrite a mod-protected function", 2)
                    end

                    local mt = getmetatable(self)
                    setmetatable(self, nil)
                    self[key] = value
                    setmetatable(self, mt)
                end
            }
        )
    else
        env[yieldName] = local_yield
    end

    --------------------------------

    local patterns = {
        --[[
        { "if([ %(])(.-)([ %)])then([ \n])", "if%1%2%3then%4__internal_yield() " },
        { "elseif([ %(])(.-)([ %)])then([ \n])", "elseif%1%2%3then%4__internal_yield() " },
        { "([ \n])else([ \n])", "%1else%2__internal_yield() " },--]]
        {"([%);\n ])do([ \n%(])", "%1do%2 " .. yieldName .. "('" .. yieldArg .. "') "},
        {"([%);\n ])repeat([ \n%(])", "%1repeat%2 " .. yieldName .. "('" .. yieldArg .. "') "},
        {"([%);\n ])goto([ \n%(])", " " .. yieldName .. "('" .. yieldArg .. "') %1goto%2"},
        {"([%);\n ])until([ \n%(])", " " .. yieldName .. "('" .. yieldArg .. "') %until%2"},
        --{"([%);\n ])?)([ \n%(])", "%1?)%2__internal_yield() "} --пожалуй лишнее
    }

    local function gsub(s)
        for i = 1, #patterns, 1 do
            s = s:gsub(patterns[i][1], patterns[i][2])
        end
        return s
    end

    local function process(code)
        local wrapped = ""
        local in_str = false

        while #code > 0 do
            if not (code:find('"', nil, true) or code:find("'", nil, true) or code:find("[", nil, true)) then
                wrapped = wrapped .. gsub(code)
                break
            end

            local chunk, quote = code:match('(.-)([%["\'])')
            code = code:sub(#chunk + 2)

            if quote == '"' or quote == "'" then
                if in_str == quote then
                    in_str = false
                    wrapped = wrapped .. chunk .. quote
                elseif not in_str then
                    in_str = quote
                    wrapped = wrapped .. gsub(chunk) .. quote
                else
                    wrapped = wrapped .. gsub(chunk) .. quote
                end
            elseif quote == "[" then
                local prefix = "%]"
                if code:sub(1, 1) == "[" then
                    prefix = "%]%]"
                    code = code:sub(2)
                    wrapped = wrapped .. gsub(chunk) .. quote .. "["
                elseif code:sub(1, 1) == "=" then
                    local pch = code:find("(=-%[)")
                    if not pch then -- syntax error
                        return wrapped .. chunk .. quote .. code
                    end
                    local e = code:sub(1, pch)
                    prefix = prefix .. e .. "%]"
                    code = code:sub(pch + #e + 1)
                    wrapped = wrapped .. gsub(chunk) .. "[" .. e .. "["
                else
                    wrapped = wrapped .. gsub(chunk) .. quote
                end

                if #prefix > 2 then
                    local strend = code:match(".-" .. prefix)
                    code = code:sub(#strend + 1)
                    wrapped = wrapped .. strend
                end
            end
        end

        return wrapped
    end

    --------------------------------

    local code, err = process(code)
    if code then
        return yieldName .. "('" .. yieldArg .. "') do " .. code .. " \n end " .. yieldName .. "('" .. yieldArg .. "') ", env
    else
        return nil, err or "unknown error"
    end
end




function load_code(self, chunk, chunkname, mode, env)
    checkArg(1, self,      "table")
    checkArg(2, chunk,     "string")
    checkArg(3, chunkname, "string", "nil")
    checkArg(4, mode,      "string", "nil")
    checkArg(5, env,       "table",  "nil")

    mode = mode or "bt"
    env = env or _G

    local vm = sc.restrictions.vm
    if vm == "fullLuaEnv" and a and a.load then
        return a.load(chunk, chunkname, mode, env)
    elseif vm == "scrapVM" and _G.luavm then
        if not self.luastate then
            self.luastate = {}
        end

        local code, err = _G.luavm.custom_loadstring(self.luastate, chunk, env)
        if code then
            return code --я хз че там в втором аргументе в данный момент
        else
            return code, err
        end
    elseif vm == "dlm" and dlm and dlm.loadstring then
        return dlm.loadstring(chunk, chunkname, env)
    elseif vm == "hsandbox" and _HENV and _HENV.load then
        return _HENV.load(chunk, chunkname, mode, env)
    elseif vm == "advancedExecuter" and sm.advancedExecuter then
        return sm.advancedExecuter.loadstring(chunk, chunkname, mode, env)
    elseif ll_Scanner and ll_Parser and ll_Interpreter then
        --vm == "luaInLua" был убран, для того чтобы если не получилось использовать целевую VM компьютеры переключились на luaInLua
        --такая ситуация может вазникнуть если DLM был удален или на хосте стоит DLM а на клиентах его нет, и если бы эта проверка была то на
        --клиентах мод бы тоже пытался использовать DLM и clientInvoke в unsafe-mode был сламался
        local function getScriptTree(script)
			local ran, tokens = pcall(ll_Scanner.scan, ll_Scanner, script)
			if ran then
				local ran, tree = pcall(ll_Parser.parse, ll_Parser, tokens)
				return ran, tree
			else
				return ran, tokens
			end
		end
		
        local newchunk, getargsfunc = ll_fix(chunk)
		local ran, tree = getScriptTree(newchunk)
		if ran then
            local enclosedEnv = ll_Interpreter:encloseEnvironment(env)
            return function (...)
                local args = {...}
                env[getargsfunc] = function ()
                    return unpack(args)
                end
                
                ll_Interpreter.internalData[self.env[self.yieldName]] = true --а нехер перезаписывать __internal_yield, крашеры ебаные
				local result = {pcall(ll_Interpreter.evaluate, ll_Interpreter, tree, enclosedEnv)}
                ll_Interpreter.internalData[self.env[self.yieldName]] = nil

                if result[1] then
                    return unpack(result, 2)
                else
                    error(ll_shorterr(result[2]), 2)
                end
			end
		else
            return nil, ll_shorterr(tree)
		end
    else
        return nil, 'failed to load the code, try changing "vm" in "PermissionTool"'
    end
end

function safe_load_code(self, chunk, chunkname, mode, env)
    checkArg(1, self,      "table")
    checkArg(2, chunk,     "string")
    checkArg(3, chunkname, "string", "nil")
    checkArg(4, mode,      "string", "nil")
    checkArg(5, env,       "table",  "nil")

    if sc.shutdownFlag then
        return nil, "CRITICAL ISSUE IN SCOMPUTERS"
    end

    local codelen = #chunk
    if codelen > sc.maxcodelen then
        return nil, "the code len " .. math.round(codelen) .. " bytes, the maximum code len " .. sc.maxcodelen .. " bytes"
    end

    env = env or {}
    mode = mode or "bt"

    if mode == "bt" then
        mode = "t"
    elseif mode == "t" then
        mode = "t"
    elseif mode == "b" then
        return nil, "bytecode is unsupported"
    else
        return nil, "this load mode is unsupported"
    end

    local preloadOk, preloadErr = load_code(self, chunk, chunkname, mode, {}) --syntax errors check
    if not preloadOk then
        return nil, preloadErr
    end

    chunk, env = injectService(self, chunk, env) --env may be a error
    if not chunk then
        return nil, env
    end
    return load_code(self, chunk, chunkname, mode, env)
end