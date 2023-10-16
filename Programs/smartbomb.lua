local colors = require("colors")
local display = getComponents("display")[1]
display.reset()
display.clearClicks()
display.setSkipAtLags(false)
display.setClicksAllowed(true)
display.setFrameCheck(false)
display.setRotation(1)
local rx, ry = display.getWidth(), display.getHeight()

function math.round(num)
    return math.floor(num + 0.5)
end

local gui = require("gui").new(display)

------------------------------------------------

local keyScene = gui:createScene(colors.sm.Gray[4])
local keys = {
    {"1", "2", "3"},
    {"4", "5", "6"},
    {"7", "8", "9"},
    {"<", "0", "#"},
}

local input = ""

local buttonSize = 8
local buttonSize2 = buttonSize + 1
local offsetX, offsetY = math.round((rx / 2) - ((#keys[1] * buttonSize2) / 2)), math.round(((ry / 2) - ((#keys * buttonSize2) / 2)) + (buttonSize2 / 2))
for y, line in ipairs(keys) do
    for x, char in ipairs(line) do
        line[x] = keyScene:createButton(((x - 1) * buttonSize2) + offsetX, ((y - 1) * buttonSize2) + offsetY, buttonSize, buttonSize, false, char, tonumber(char) and colors.sm.Red[2] or colors.sm.Orange[2])
    end
end
local modeLabel = keyScene:createLabel(1, 1, rx - 2, buttonSize, nil, colors.sm.Gray[3], colors.sm.Gray[4])
local inputLabel = keyScene:createLabel(1, buttonSize + 2, rx - 2, buttonSize, nil, colors.sm.Gray[3], colors.sm.Gray[4])

keyScene:select()

------------------------------------------------

function callback_loop()
    if _endtick then
        display.clear()
        display.flush()
        return
    end

    gui:tick()
    
    if keyScene:isSelected() then
        for y, line in ipairs(keys) do
            for x, button in ipairs(line) do
                if button:isPress() then
                    local str = tonumber(button.text)
                    if str then
                        input = input .. str
                    end
                end
            end
        end
    end

    if gui:needFlush() then
        gui:draw()
        display.flush()
    end
end