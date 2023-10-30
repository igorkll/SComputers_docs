local utils = require("utils")

local display = getDisplays()[1]
local mode = 0

display.reset()
display.clear()
display.flush()
local w, h = display.getWidth(), display.getHeight()
local fw, fh = display.getFontWidth(), display.getFontHeight()

local function rPos()
    return math.random(1, w)
end

local function rCol()
    return sm.color.new(math.random(), math.random(), math.random())
end

local function rVal()
    return math.random(1, w / 2)
end

function callback_loop()
    if _endtick then
        display.clear()
        display.forceFlush()
        return
    end

    if math.random(0, 40) == 0 then
        mode = mode + 1
        if mode > 6 then
            mode = 0
        end
        display.clear()
    end

    if mode == 0 then
        for i = 1, 128 do
            display.drawPixel(rPos(), rPos(), rCol())
        end
    elseif mode == 1 then
        display.drawRect(rPos(), rPos(), rVal(), rVal(), rCol())
    elseif mode == 2 then
        display.fillRect(rPos(), rPos(), rVal(), rVal(), rCol())
    elseif mode == 3 then
        display.drawCircle(rPos(), rPos(), rVal(), rCol())
    elseif mode == 4 then
        display.fillCircle(rPos(), rPos(), rVal(), rCol())
    elseif mode == 5 then
        display.drawLine(rPos(), rPos(), rPos(), rPos(), rCol())
    elseif mode == 6 then
        local text = tostring(sm.uuid.generateRandom())
        display.drawText(rPos() - ((#text * fw) / 2), rPos() - (fh / 2), text, rCol())
    end

    display.fillRect(0, 0, 32, 7, "ff0000")
    display.drawText(1, 1, utils.roundTo(getLagsScore()))

    display.fillRect(0, 7, 32, 7, "0000ff")
    display.drawText(1, 8, math.floor(getSkippedTicks()))

    display.flush()
end