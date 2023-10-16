local colors = require("colors")
local display = getComponents("display")[1]
local rx, ry = display.getWidth(), display.getHeight()
display.reset()
display.clearClicks()
display.setSkipAtLags(false)
display.setClicksAllowed(true)
display.setFrameCheck(false)

function math.round(num)
    return math.floor(num + 0.5)
end

local gui = require("gui").new(display)
local passwordScene = gui:createScene(colors.sm.Gray[3])
local keys = {
    {"1", "2", "3"},
    {"4", "5", "6"},
    {"7", "8", "9"},
    {"<", "0", "#"},
}
local bsize = 5
local osize = bsize + 1
local offsetX, offsetY = math.round((rx / 2) - ((#keys[1] * osize) / 2)), math.round((ry / 2) - ((#keys * osize) / 2))
for y, line in ipairs(keys) do
    for x, char in ipairs(line) do
        line[x] = passwordScene:createButton(((x - 1) * osize) + offsetX, ((y - 1) * osize) + offsetY, bsize, bsize, false, char, tonumber(char) and colors.sm.Red[2] or colors.sm.Orange[2])
    end
end

passwordScene:select()

function callback_loop()
    if _endtick then
        display.clear()
        display.flush()
        return
    end

    gui:tick()
    if gui:needFlush() then
        gui:draw()
        display.flush()
    end

end