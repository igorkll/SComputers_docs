local display = getComponents("display")[1]

display.reset()
display.clearClicks()
display.setSkipAtLags(false)
display.setClicksAllowed(true)
display.setFrameCheck(false)

local gui = require("gui").new(display)
local colors = require("colors")

-------------------------

scene = gui:createScene(colors.sm.Blue[2])
scene:createText(1, 1, "NFC CONTROLLER", colors.sm.Gray[1])

scene:select()

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