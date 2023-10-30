local display = getDisplays()[1]
local mode = 0

display.reset()
local w, h = display.getWidth(), display.getHeight()

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
    if getUptime() % 40 == 0 then
        mode = mode + 1
        if mode > 5 then
            mode = 0
            display.clear()
        end
    end

    if mode == 0 then
        display.drawPixel(rPos(), rPos(), rCol())
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
    end

    display.flush()
end