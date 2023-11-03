local display = getComponents("display")[1]
local disk = getComponents("disk")[1]
if not display then return end
display.reset()
display.clearClicks()
display.setSkipAtLags(false)
display.setClicksAllowed(true)

local gui = require("gui").new(display)
local image = require("image")

local black = sm.color.new(0, 0, 0)
local blue = sm.color.new(0, 0, 1)
local green = sm.color.new(0, 1, 1)
local red = sm.color.new(1, 0, 0)
local white = sm.color.new(1, 1, 1)

local rx, ry = display.getWidth(), display.getHeight()
local cameraIndex
local fov = 60
local speed = 256

local currentFrame = image.new(rx, ry, black)

----------------------------------

local mainScene = gui:createScene(function ()
    local camera = getComponents("camera")[cameraIndex or -1]
    if camera then
        camera.setFov(math.rad(fov))
        camera.setStep(speed)
        camera.drawColorWithDepth(display)
    else
        display.clear(blue)
        cameraIndex = nil
    end
end)
local openSettings = mainScene:createButton(0, ry - 7, 6, 7, false, "M")

----------------------------------

local settingsScene = gui:createScene(blue)
local openMain = settingsScene:createButton(0, ry - 7, 6, 7, false, "<", red, white)
local fovButton = settingsScene:createButton(1, 1, rx - 2, 7)
local speedButton = settingsScene:createButton(1, 9, rx - 2, 7)
local selectCamera = settingsScene:createButton(1, 17, rx - 2, 7)

----------------------------------

mainScene:select()

function callback_loop()
    if _endtick then
        display.clear()
        display.flush()
        return
    end

    if sm.game.getCurrentTick() % 5 ~= 0 then return end

    gui:tick()
    if mainScene:isSelected() then
        if cameraIndex then
            mainScene:update()
        end

        if openSettings:isReleased() then
            settingsScene:select()
        end
    elseif settingsScene:isSelected() then
        if fovButton:isReleased() then
            fov = fov + 10
            if fov > 90 then
                fov = 10
            end
        end
        fovButton:setText("fov: " .. fov)

        if speedButton:isReleased() then
            speed = speed * 2
            if speed > 1024 then
                speed = 64
            end
        end
        speedButton:setText("speed: " .. speed)

        if selectCamera:isReleased() then
            if not cameraIndex then
                cameraIndex = 0
            end

            cameraIndex = cameraIndex + 1
            if not getComponents("camera")[cameraIndex or -1] then
                cameraIndex = nil
            end
        end
        selectCamera:setText("camera: " .. (cameraIndex or "none"))

        if openMain:isReleased() then
            mainScene:select()
        end
    end
    if gui:needFlush() then
        gui:draw()
        display.flush()
    end
end