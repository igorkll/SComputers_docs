local filesystem = {}
filesystem.mounts = {}

function filesystem.get(path)
    path = filesystem.canonical(path)
    if path:sub(#path, #path) ~= "/" then path = path .. "/" end

    for i, v in ipairs(filesystem.mounts) do
        local lpath = v.path
        if lpath:sub(#lpath, #lpath) ~= "/" then lpath = lpath .. "/" end

        if lpath:sub(1, #path) == lpath then
            return v.proxy, filesystem.canonical(path:sub(#lpath, #path))
        end
    end
end

function filesystem.mount(proxy, path)
    path = filesystem.canonical(path)

    for i, v in ipairs(filesystem.mounts) do
        if v.path == path then
            return nil, "another filesystem is already mounted here"
        end
    end

    table.insert(filesystem.mounts, {proxy = proxy, path = path})
    table.sort(filesystem.mounts, function(a, b)
        return #a[1] > #b[1]
    end)
end

function filesystem.umount(path)
    path = filesystem.canonical(path)
    for i, v in ipairs(filesystem.mounts) do
        if v.path == path then
            table.remove(filesystem.mounts, i)
            return true
        end
    end
    return false
end

-----------------------------------

function filesystem.canonical(path)
    if path:sub(#path, #path) == "/" then
        path = path:sub(1, #path - 1)
    end
    if path:sub(1, 1) ~= "/" then
        path = "/" .. path
    end
    return path
end

-----------------------------------

function filesystem.segments(path)
    local parts = {}
    for part in path:gmatch("[^\\/]+") do
        local current, up = part:find("^%.?%.$")
        if current then
            if up == 2 then
                table.remove(parts)
            end
        else
            table.insert(parts, part)
        end
    end
    return parts
end

function filesystem.concat(...)
    return filesystem.canonical(table.concat({...}, "/"))
end

function filesystem.xconcat(...) --работает как concat но пути начинаюшиеся со / НЕ обрабатываються как отновительные а откидывают путь в начало
    local set = table.pack(...)
    for index, value in ipairs(set) do
        if value:sub(1, 1) == "/" and index > 1 then
            local newset = {}
            for i = index, #set do
                table.insert(newset, set[i])
            end
            return filesystem.xconcat(table.unpack(newset))
        end
    end
    return filesystem.canonical(table.concat(set, "/"))
end

function filesystem.sconcat(main, ...) --работает так же как concat но если итоговый путь не указывает на целевой обьект первого путя то вернет false
    main = filesystem.canonical(main) .. "/"
    local path = filesystem.concat(main, ...) .. "/"
    if string.sub(path, 1, string.len(main)) == main then
        return path:sub(1, #path - 1)
    end
    return false
end

function filesystem.path(path)
    local parts = filesystem.segments(path)
    local result = table.concat(parts, "/", 1, #parts - 1) .. "/"
    return filesystem.canonical(result)
end
  
function filesystem.name(path)
    local parts = filesystem.segments(path)
    return parts[#parts]
end

function filesystem.exp(str)
    local exp = nil

    for i = 1, #str do
        local char = str:sub(i, i)
        if char == "." then
            exp = ""
        elseif exp then
            exp = exp .. char
        end
    end

    return exp
end

function filesystem.hideExp(str)
    local exp = filesystem.exp(str)
    if exp then
        return str:sub(1, #str - (#exp + 1))
    end
    return str
end

-----------------------------------

function filesystem.mkdir(path)
    local proxy, proxyPath = filesystem.get(path)
    if proxy then
        local segments = filesystem.segments(proxyPath)
        local lpath = segments[1]
        if lpath then
            pcall(proxy.createFolder, lpath)
            for i = 2, #segments do
                lpath = filesystem.concat(lpath, segments[i])
                pcall(proxy.createFolder, lpath)
            end
        end
    end
    return nil, "no such filesystem"
end

function filesystem.remove(path)
    local proxy, proxyPath = filesystem.get(path)
    if proxy then
        return pcall(proxy.deleteFile, proxyPath) or pcall(proxy.deleteFolder, proxyPath)
    end
    return nil, "no such filesystem"
end

function filesystem.exists(path)
    local proxy, proxyPath = filesystem.get(path)
    local value = false
    if proxy then
        pcall(function()
            value = proxy.hasFile(proxyPath) or proxy.hasFolder(proxyPath)
        end)
    end
    return value
end

function filesystem.isDirectory(path)
    local proxy, proxyPath = filesystem.get(path)
    local value = false
    if proxy then
        pcall(function()
            value = proxy.hasFolder(proxyPath)
        end)
    end
    return value
end

function filesystem.read(path)
    local proxy, proxyPath = filesystem.get(path)
    if proxy then
        return proxy.readFile(proxyPath)
    end
    return nil, "no such filesystem"
end

function filesystem.write(path, data)
    local proxy, proxyPath = filesystem.get(path)
    if proxy then
        filesystem.mkdir(filesystem.path(path))
        pcall(proxy.createFile, proxyPath)
        local ok, err = pcall(proxy.writeFile, proxyPath, data)
        if not ok then
            pcall(proxy.deleteFile, proxyPath)
        end
        return ok, err
    end
    return nil, "no such filesystem"
end

function filesystem.copy(path, path2)
    local proxy, proxyPath = filesystem.get(path)
    local targetProxy, targetProxyPath = filesystem.get(path2)
    if proxy and targetProxy then
        local data = filesystem.read(proxyPath)
        if not data then return true end
        filesystem.write(targetProxyPath, data)
        return true
    end
    return false
end

function filesystem.move(path, path2)
    if filesystem.copy(path, path2) then
        return filesystem.remove(path)
    end
    return false
end

function filesystem.list(path)
    path = filesystem.canonical(path)
    local proxy, proxyPath = filesystem.get(path)
    if proxy then
        if filesystem.isDirectory(path) then
            local list = {}
            pcall(function ()
                for i, v in ipairs(proxy.getFileList(proxyPath)) do table.insert(list, v) end
                for i, v in ipairs(proxy.getFolderList(proxyPath)) do table.insert(list, v) end
            end)
            return list
        else
            return nil, "no such directory"
        end
    else
        return nil, "no such filesystem"
    end
end

filesystem.mount(systemDisk, "/")
return filesystem