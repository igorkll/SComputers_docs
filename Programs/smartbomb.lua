local colors = require("colors")
local display = getComponents("display")[1]
display.reset()
display.clearClicks()
display.setSkipAtLags(false)
display.setClicksAllowed(true)
local rx, ry = display.getWidth(), display.getHeight()
if rx ~= ry then
    display.setRotation(1)
    rx, ry = display.getWidth(), display.getHeight()
end

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

local inputText = ""

local buttonSize = 10
local labelSize = 7
local buttonSize2 = buttonSize + 1
local offsetX, offsetY = math.round((rx / 2) - ((#keys[1] * buttonSize2) / 2)), math.round(((ry / 2) - ((#keys * buttonSize2) / 2)) + 7)
for y, line in ipairs(keys) do
    for x, char in ipairs(line) do
        line[x] = keyScene:createButton(((x - 1) * buttonSize2) + offsetX, ((y - 1) * buttonSize2) + offsetY, buttonSize, buttonSize, false, char, tonumber(char) and colors.sm.Red[2] or colors.sm.Orange[2])
    end
end

local modeLabel = keyScene:createLabel(1, 1, rx - 2, labelSize, nil, colors.sm.Gray[3], colors.sm.Gray[4])
local inputLabel = keyScene:createLabel(1, labelSize + 2, rx - 2, labelSize, nil, colors.sm.Gray[3], colors.sm.Gray[4])

keyScene:select()

------------------------------------------------

local splash
local splashTimer
local currentPassword
local timer

function callback_loop()
    out(0)

    if _endtick then
        display.clear()
        display.flush()
        return
    end

    gui:tick()

    modeLabel:setFgColor(colors.sm.Gray[4])
    if splashTimer and splashTimer > 0 then
        modeLabel:setFgColor(colors.sm.Green[2])
        modeLabel:setText(splash)

        splashTimer = splashTimer - 1
        if splashTimer <= 0 then
            splashTimer = nil
        end
    elseif timer then
        modeLabel:setFgColor(colors.sm.Red[2])
        modeLabel:setText(tostring(math.round(timer / 40)))
        timer = timer - 1
        if timer <= 0 then
            out(1)
            timer = nil
            currentPassword = nil
        end
    elseif currentPassword then
        modeLabel:setText("set timer")
    else
        modeLabel:setText("set pswd")
    end
    
    if keyScene:isSelected() then
        for y, line in ipairs(keys) do
            for x, button in ipairs(line) do
                if button:isPress() then
                    local str = tonumber(button.text)
                    if str then
                        if #inputText < 4 then
                            inputText = inputText .. str
                        end
                    elseif button.text == "<" then
                        inputText = inputText:sub(1, #inputText - 1)
                    elseif button.text == "#" then
                        local inp = inputText
                        inputText = ""
                        inputLabel:setText("")

                        if #inp > 0 then
                            if inp == "5456" then
                                setLock(false)
                                splashTimer = 40
                                splash = "UNLOCKED"
                            elseif not currentPassword then
                                currentPassword = inp
                            elseif not timer then
                                timer = tonumber(inp) * 40
                            else
                                if inp == currentPassword then
                                    timer = nil
                                    currentPassword = nil
                                end
                            end
                        end
                    end

                    if currentPassword and not timer then
                        inputLabel:setText(inputText)
                    else
                        inputLabel:setText(string.rep("*", #inputText))
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