local colors = require("colors")

local display = getComponents("display")[1]
display.reset()
display.clear()
--this approach will allow you to cause fewer lags, due to which the mod will reduce the clock frequency of the computer (virtual) less, due to which the rendering will be faster.
display.setSkipAtLags(true) --in order for rendering to be skipped if the game is lagging(true by default)
display.setSkipAtNotSight(true) --in order for the picture not to be updated for those who do not look at the screen

local camera = getComponents("camera")[1]
camera.setFov(math.rad(60))
camera.setStep(512)

function callback_loop()
    if _endtick then
        display.clear()
        display.forceFlush()
        return
    end

    if display.getAudience() > 0 then
        camera.drawCustom(display, function (x, y, raydata)
            if not raydata then
                return sm.color.new(0, math.random(), math.random())
            elseif raydata.type == "limiter" then
                return sm.color.new(math.random(), math.random(), math.random())
            elseif raydata.type == "terrain" then
                return sm.color.new(0, math.random(), 0)
            elseif raydata.type == "asset" then
                return sm.color.new(math.random(), 0, 0)
            end
            return sm.color.new(colors.hsvToRgb(((x + y) / 32) % 1, 1, 1)) * (raydata.color or sm.color.new(1, 1, 1))
        end)
        display.flush()
    end
end