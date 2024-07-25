local colors = require("colors")
local utils = require("utils")

local disk = getComponents("disk")[1]
local env = utils.deepcopy(_G)

-----------------------------------------

function env.load(chunk, chunkname, mode, lenv)
    return load(chunk, chunkname, mode, lenv or env)
end

function env.loadstring(chunk, lenv)
    return loadstring(chunk, lenv or env)
end

function env.execute(chunk, lenv, ...)
    return execute(chunk, lenv or env, ...)
end

-----------------------------------------

local function graphic_clear()
    for _, display in ipairs(getComponents("display")) do
        display.reset()
        display.clear()
        display.flush()
    end

    for _, terminal in ipairs(getComponents("terminal")) do
        terminal.clear()
    end
end

local function graphic_error(text)
    local bsodBackground = colors.sm.Blue[2]
    local bsodForeground = colors.sm.Gray[1]
    local bsodLabelBackground = colors.sm.Gray[1]
    local bsodLabelForeground = colors.sm.Blue[2]

    for _, display in ipairs(getComponents("display")) do
        local sx = display.getWidth()
        local fsx, fsy = display.getFontWidth() + 1, display.getFontHeight() + 1
        local strMaxSize = math.floor(sx / fsx)

        local function centerPrint(text, y, color)
            display.drawText((sx / 2) - ((utf8.len(text) / 2) * fsx), y, text, color)
        end

        display.reset()
        display.clear(bsodBackground)
        display.fillRect(0, 0, sx, fsy + 1, bsodLabelBackground)
        centerPrint("ERROR", 1, bsodLabelForeground)
        local index = 1
        for _, str in ipairs(utils.split(utf8, tostring(text):upper(), "\n")) do
            local partsCount = 0
            for _, lstr in ipairs(utils.splitByMaxSizeWithTool(utf8, str, strMaxSize)) do
                centerPrint(lstr, (index * fsy) + 2, bsodForeground)
                index = index + 1
                partsCount = partsCount + 1
            end
            if partsCount == 0 then
                index = index + 1
            end
        end
        display.forceFlush()
    end

    for _, terminal in ipairs(getComponents("terminal")) do
        terminal.clear()
        terminal.write("#ff0000ERROR: " .. tostring(text))
    end
end

-----------------------------------------

graphic_clear()

local targetFile = "init.lua"
local initCode
if disk then
    if disk.hasFile(targetFile) then
        local code, err = load(disk.readFile(targetFile), "=init", nil, env)
        if code then
            initCode = code
        else
            graphic_error(err)
        end
    else
        graphic_error("there is no init.lua file")
    end
else
    graphic_error("no bootable medium found")
end

function callback_loop()
    if _endtick then
        env._endtick = true
    end

    if initCode then
        local successfully, err = pcall(env.callback_loop or initCode, disk)
        if not successfully then
            initCode = nil
            if env.callback_error then
                pcall(env.callback_error, err)
            end
            graphic_error(err)
        end
    end

    if _endtick then
        graphic_clear()
    end
end
callback_loop()