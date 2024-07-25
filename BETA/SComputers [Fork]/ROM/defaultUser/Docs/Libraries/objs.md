## additional elements for the gui

### textbox
scene:createCustom(0, 0, width, height, objs.textbox, "TEXT\nNEW-LINE", 0xff0000, true - (centering text), true - (centering lines), 0x0000ff - (fill))

### panel
scene:createCustom(0, 0, width, height, objs.panel, 0x0000ff)

### example
```lua
local gui = require("gui")
local styles = require("styles")
local objs = require("objs")

local display = getComponent("display")
local width, height = display.getWidth(), display.getHeight()
display.reset()
display.clearClicks()
display.setSkipAtLags(false)
display.setClicksAllowed(true)

local ui = gui.new(display)
local scene = ui:createScene()
scene:createCustom(0, 0, width, height, objs.textbox, "TEXT\nNEW-LINE", 0xffffff, true, true, 0x0000ee)

function callback_loop()
    if _endtick then
        display.reset()
        display.clear()
        display.flush()
        return
    end

    ui:tick()
    if ui:needFlush() then
        ui:draw()
        display.flush()
    end
end
```