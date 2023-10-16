function injectService(self, code, env) --спизженно с: https://github.com/Ocawesome101/oc-cynosure/blob/dev/base/load.lua
    local yield
    if sm.isServerMode() then
        yield = self.sv_yield
    else
        yield = self.cl_yield
    end

    local function local_yield()
        yield(self)
    end

    local setmetatable = sc.getApi("setmetatable")
    local getmetatable = sc.getApi("getmetatable")
    if setmetatable and getmetatable then
        setmetatable(env, nil)
        env.__internal_yield = nil
        setmetatable(env,
            {
                __index = {
                    __internal_yield = local_yield
                },
                __newindex = function (self, key, value)
                    if key == "__internal_yield" then
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
        env.__internal_yield = local_yield
    end

    --------------------------------

    local patterns = {
        --[[
        { "if([ %(])(.-)([ %)])then([ \n])", "if%1%2%3then%4__internal_yield() " },
        { "elseif([ %(])(.-)([ %)])then([ \n])", "elseif%1%2%3then%4__internal_yield() " },
        { "([ \n])else([ \n])", "%1else%2__internal_yield() " },--]]
        {"([%);\n ])do([ \n%(])", "%1do%2 __internal_yield() "},
        {"([%);\n ])repeat([ \n%(])", "%1repeat%2 __internal_yield() "},
        {"([%);\n ])goto([ \n%(])", " __internal_yield() %1goto%2"},
        {"([%);\n ])until([ \n%(])", " __internal_yield() %until%2"},
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

    return "do " .. process(code) .. " \n end __internal_yield() ", env
end




function load_code(self, chunk, chunkname, mode, env)
    checkArg(1, chunk,     "string")
    checkArg(2, chunkname, "string", "nil")
    checkArg(3, mode,      "string", "nil")
    checkArg(4, env,       "table",  "nil")

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
                
                ll_Interpreter.internalData[env.__internal_yield] = true --а нехер перезаписывать __internal_yield, крашеры ебаные
				local result = {pcall(ll_Interpreter.evaluate, ll_Interpreter, tree, enclosedEnv)}
                ll_Interpreter.internalData[env.__internal_yield] = nil
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
    checkArg(1, chunk,     "string")
    checkArg(2, chunkname, "string", "nil")
    checkArg(3, mode,      "string", "nil")
    checkArg(4, env,       "table",  "nil")

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

    chunk, env = injectService(self, chunk, env)
    return load_code(self, chunk, chunkname, mode, env)
end