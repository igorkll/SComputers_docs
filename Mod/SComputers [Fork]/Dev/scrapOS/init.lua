do --загаловок, инициализирует главные функции компьютера
    if STOPPED then return end --если комп остановлен(комп делает дополнительный тик после выключения)
    if STARTED then --если комп уже запушен
        if not _endtick then --если комп сейчас на выключаеться
            if not ERROR then --если нет ошибок, то комп работает, если ошибка появиться то он перестанет вызывать onTick, и будет ждать выключения
                local ran, err = pcall(onTick) --тикаем
                if not ran then
                    ERROR = err or "unknown"
                    onError(ERROR) --передали в программу что шляпа
                end
            end
        else
            STOPPED = true
            onStop()
        end
        return --неважно подан синал или нет, после старта комп не будет подгружать функции заного
    elseif onStart then --если комп еще не запушен, но методы уже подгружены
        local ran, err = pcall(onStart)
        if not ran then
            ERROR = err or "unknown"
            onError(ERROR)
        end
        if _endtick then --для коректной обработки запуска на один тик(комп сделаел 2 тика, это фича чтобы отследить отключения)
            STOPPED = true
            onStop()
        end

        STARTED = true
        return --и опять return
    end
end

-----------------------------------

function onStart()
    _OSVERSION = "scrapOS v2.0"

    do
        utils = assert(load(systemDisk.readFile("/lib/utils.lua"), "=/lib/utils.lua"))()
        fs = assert(load(systemDisk.readFile("/lib/fs.lua"), "=/lib/fs.lua", nil, utils.createEnv()))()

        for _, name in ipairs(fs.list("/lib")) do
            if not _G[fs.hideExp(name)] then
                local path = fs.concat("/lib", name)
                _G[fs.hideExp(name)] = assert(load(fs.read(path), "=" .. path, nil, utils.createEnv()))()
            end
        end
    end

    openPrograms = {}

    do
        local path = "/services"
        if fs.exists(path) and fs.isDirectory(path) then
            for i, v in ipairs(fs.list(path)) do
                local programmPath = fs.concat(path, v)
                table.insert(openPrograms, {enable = true, path = programmPath})
            end
        end
    end
    
    do
        mainProgrammPath = settings.current.mainProgrammPath
        
        if not settings.current.disableWorkingWithScreens then
            for i, v in ipairs(getDisplays()) do
                v.setSkipAtLags(not not settings.current.defaultSkipAtLags)
                while v.getClick() do end
                table.insert(openPrograms, {default = true, enable = true, path = mainProgrammPath, args = {{screen = v}}})
                if settings.current.onlyAFirstScreen then
                    break
                end
            end
        end
    end
end

function onStop()
    for i, v in ipairs(getDisplays()) do
        v.clear(utils.formatColor("000000"))
        v.flush()
    end
end

function onTick()
    for i, v in ipairs(openPrograms) do
        if v.enable then
            if not v.runned then
                v.runned = true

                if not v.env then v.env = utils.createEnv() end
                v.env.object = v
                v.env.args = v.args or {} --... в обычьных чанках кода не работает, видимо баг интерпритатора

                local result, err = load(fs.read(v.path), "=" .. v.path, nil, v.env)
                if not result then
                    v.enable = false
                    v.error = err or "unknown"
                else
                    local ok, err = pcall(result, unpack(v.args or {}))
                    if not ok then
                        v.enable = false
                        v.error = "on init: " .. (err or "unknown")
                    else
                        if v.env.onStart then
                            local ok, err = pcall(v.env.onStart, unpack(v.args or {}))
                            if not ok then
                                v.enable = false
                                v.error = "on start: " .. (err or "unknown")
                                pcall(v.env.onError, err, unpack(v.args or {}))
                            end
                        end
                    end
                end
            else
                if v.env.onTick then
                    local ok, err = pcall(v.env.onTick, unpack(v.args or {}))
                    if not ok then
                        v.enable = false
                        v.error = "on tick: " .. (err or "unknown")
                        pcall(v.env.onError, err, unpack(v.args or {}))
                    end
                end
            end
        end
        if v.error and not v.printedError and not v.notPrintError then
            --print(v.path, v.error)
            if v.default then
                error(v.error, 0)
            end
            v.printedError = true
        end
    end
end

function onError(err)
    error(err, 0)
end