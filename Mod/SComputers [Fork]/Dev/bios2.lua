----The bios can be used to run operating systems from the hard disk

---- protection
local setData, setCode = setData, setCode --save the original methods for the bios work
_G.setData = function(newdata) --the data section is occupied by bios settings
end
_G.setCode = function(newcode) --it is unacceptable to rewrite the bios from the operating system
end

---- graphic
local function clearDisplay(display)
    display.reset()
    display.clearClicks()
    display.clear()
    display.forceFlush()
end

local display, gui, width, height = getComponents("display")[1]
if display then
    clearDisplay(display)
    width, height = display.getWidth(), display.getHeight()
    gui = require("gui").new(display)
end

---- functions
local function bootTo(disk)
    local bootFile = "/init.lua"
    if disk.hasFile(bootFile) then
        local data = disk.readFile(bootFile)
        if data then
            local code, err = load(data, "=init")
            if not code then
                return nil, err or "unknown load error"
            end

            clearDisplay(display)
            local ok, err = pcall(code, disk) --passes the disk as the first argument. so that the system knows where to read its resources from
            if not ok then
                return ok, err or "unknown runtime error"
            end

            return nil, "operating system halted"
        end
    end
    return nil, "failed to read /init.lua file"    
end

---- main
display.clear(sm.color.new(0, 0, 1))
display.forceFlush()

function callback_loop()
    if _endtick then
        clearDisplay(display)
        return
    end

    local disk = getDisks()[1]
    if disk then
        print(bootTo(disk))
    end
end