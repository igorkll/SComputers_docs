local utils = {}

function utils.toParts(str, max) --toParts("12345", 2) == {"12", "34", "5"}
    local strs = {}
    while #str > 0 do
        table.insert(strs, str:sub(1, max))
        str = str:sub(#strs[#strs] + 1)
    end
    return strs
end

function utils.split(str, sep)
    local parts, count, i = {}, 1, 1
    while true do
        if i > #str then break end
        local char = str:sub(i, #sep + (i - 1))
        if not parts[count] then parts[count] = "" end
        if char == sep then
            count = count + 1
            i = i + #sep
        else
            parts[count] = parts[count] .. str:sub(i, i)
            i = i + 1
        end
    end
    if str:sub(#str - (#sep - 1), #str) == sep then table.insert(parts, "") end
    return parts
end

function utils.deepcopy(t)
    local cache = {}
    local function recurse(tbl, newtbl)
        local newtbl = newtbl or {}
    
        for k, v in pairs(tbl) do
            if type(v) == "table" then
                local ltbl = cache[v]
                if not ltbl then
                    cache[v] = {}
                    ltbl = cache[v]
                    recurse(v, cache[v])
                end
                newtbl[k] = ltbl
            else
                newtbl[k] = v
            end
        end

        return newtbl
    end

    return recurse(t)
end

function utils.createEnv()
    local env = {}
    for key, value in pairs(_G) do
        env[key] = value
    end
    env.onStart = nil
    env.onTick = nil
    env.onError = nil
    env.onStop = nil

    env._ENV = env
    env._G = _G

    return env
end

function utils.formatColor(color)
    color = color:lower()
    if #color == 8 then
        return color
    elseif #color == 6 then
        return color .. settings.current.screenBrightness
    else
        error("bad color", 1)
    end
end

function utils.exit(object)
    for i, v in ipairs(_G.openPrograms) do
        if not object.default and v == object then
            table.remove(_G.openPrograms, i)
            break
        end
    end
end

return utils