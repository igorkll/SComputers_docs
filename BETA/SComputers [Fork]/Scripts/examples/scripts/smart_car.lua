motor = getComponents("motor")[1]
motor.setActive(true)

display = getComponents("display")[1]
display.reset()
display.clear()
display.setSkipAtLags(false)
display.setClicksAllowed(true)

width, height = display.getWidth(), display.getHeight()

colors = require("colors")
gui = require("gui").new(display)
utils = require("utils")

--------------------------------------------- scene 1

scene = gui:createScene(colors.sm.Gray[4])
velocityLabel = scene:createText(1, 1, "", colors.str.Green[2])
velocityAdd = scene:createButton(width - 7, 1, 6, 5, false, "+")
velocitySub = scene:createButton(width - 14, 1, 6, 5, false, "-")

strengthLabel = scene:createText(1, 7, "", colors.str.Green[2])
strengthAdd = scene:createButton(width - 7, 7, 6, 5, false, "+")
strengthSub = scene:createButton(width - 14, 7, 6, 5, false, "-")

loadLabel = scene:createText(1, 7 + 6, "", colors.str.Green[2])
chargeLabel = scene:createText(1, 7 + 12, "", colors.str.Green[2])

--------------------------------------------- scene 2

scene2 = gui:createScene(colors.sm.Gray[4])
scene2:createText(1, 1, "no batteries", colors.str.Red[2])

--------------------------------------------- main

strength = 100
velocity = 100

function callback_loop()
    if _endtick then
        motor.setActive(false)

        display.clear()
        display.forceFlush()
        return
    end

    if sm.game.getCurrentTick() % 5 ~= 0 then return end

    local currentWork = motor.isWorkAvailable()
    if currentWork ~= oldWork then
        if currentWork then
            scene:select()
        else
            scene2:select()
        end
        oldWork = currentWork
    end
    
    velocityLabel:clear()
    velocityLabel:setText("VEL:" .. tostring(velocity))
    velocityLabel:update()

    strengthLabel:clear()
    strengthLabel:setText("PWR:" .. tostring(strength))
    strengthLabel:update()

    loadLabel:clear()
    loadLabel:setText("LOAD:" .. tostring(utils.roundTo((motor.getChargeDelta() / motor.getStrength() / motor.getBearingsCount()) * 100, 1)) .. "%")
    loadLabel:update()

    chargeLabel:clear()
    chargeLabel:setText("CHRG:" .. tostring(motor.getAvailableBatteries() + utils.roundTo(motor.getCharge() / motor.getChargeAdditions())) .. "%")
    chargeLabel:update()
    
    motor.setStrength(strength)
    motor.setVelocity(ninput()[1] * velocity)

    gui:tick()
    if velocityAdd:isPress() then
        velocity = velocity + 25
    elseif velocitySub:isPress() then
        velocity = velocity - 25
    end
    if strengthAdd:isPress() then
        strength = strength + 25
    elseif strengthSub:isPress() then
        strength = strength - 25
    end
    if velocity > motor.maxVelocity() then
        velocity = motor.maxVelocity()
    elseif velocity < 25 then
        velocity = 25
    end
    if strength > motor.maxStrength() then
        strength = motor.maxStrength()
    elseif strength < 25 then
        strength = 25
    end
    
    if gui:needFlush() then
        gui:draw()
        display.flush()
    end
end