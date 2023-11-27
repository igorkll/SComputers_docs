local colors = require("colors")

local ledCount = 64
local leds = getComponents("led")

function callback_loop()
    if _endtick then
        for i = 0, ledCount - 1 do
            for _, led in ipairs(leds) do
                led.setColor(i, sm.color.new(0, 0, 0))
            end
        end
        return
    end

    local val = getUptime() / 2
    for i = 0, ledCount - 1 do
        local hue = ((i - val) / 64) % 1
        for _, led in ipairs(leds) do
            led.setColor(i, sm.color.new(colors.hsvToRgb(hue, 1, 1)))
        end
    end
end