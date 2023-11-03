function loadExample(self, name)
    local str = ""
    if name == "eBios" then
        str = 
[[
--this example is very outdated,
--wait a little and I will make a new bios that supports the latest SComputers technologies

if bios_stop then
    if _endtick and bios_screen then
        pcall(bios_screen.clear, "000000")
        pcall(bios_screen.flush)
    end
    return
end
if not bios_start then
    bios_disk = getDisks()[1]
    bios_screen = getDisplays()[1]
    bios_bootfile = "/init.lua"

    systemDisk = bios_disk

    function bios_splash(str, isErr)
        --if isErr then
        --    print(str)
        --end

        if not bios_screen then
            --if isErr then
            --    error(str, 0)
            --end
            return
        end

        local function toParts(str, max)
            local strs = {}
            while #str > 0 do
                table.insert(strs, str:sub(1, max))
                str = str:sub(#strs[#strs] + 1)
            end
            return strs
        end

        local strs = toParts(str, math.floor(bios_screen.getWidth() / 5))
        bios_screen.clear("000000")
        for i, v in ipairs(strs) do
            bios_screen.drawText(0, (i - 1) * 7, v, "00FF00")
        end
        bios_screen.flush()
    end

    

    if not bios_disk then
        bios_splash("disk not found", true)
        bios_stop = true
        return
    elseif bios_disk.hasFile(bios_bootfile) then
        local ok, result = pcall(loadstring, bios_disk.readFile(bios_bootfile))
        if ok then
            bios_systemcode = result
        else
            bios_systemerror = result
        end

        if not bios_systemcode then
            bios_splash("failed to loading: " .. (bios_systemerror or "unknown"), true)
            bios_stop = true
            return
        end
    else
        bios_splash("init file not found", true)
        bios_stop = true
        return
    end

    bios_start = true
end

local ok, err = pcall(bios_systemcode, bios_disk)
if not ok then
    bios_splash("error in os: " .. (err or "unknown"), true)
    bios_stop = true
end]]
    elseif name == "eCamera" then
        str = 
[[
--connecting
--green - next camera
--blue - previous camera
--red - zoom
--any - on

--settings
maxdistance = 512 --metrs, one metr - 4 blocks
fov = math.rad(70)
zoomfov = math.rad(5)
drawingSpeed = 256

--code
cameraIndex = 1

function callback_loop()
    display = getDisplays()[1]
    if not display then return end
    display.reset()
    --this approach will allow you to cause fewer lags, due to which the mod will reduce the clock frequency of the computer (virtual) less, due to which the rendering will be faster.
    display.setSkipAtLags(true) --in order for rendering to be skipped if the game is lagging(true by default)
    display.setSkipAtNotSight(true) --in order for the picture not to be updated for those who do not look at the screen

    cameras = getCameras()

    ----------------------------

    if input("19e753ff") and not oldgreen then
        cameraIndex = cameraIndex + 1
        if cameraIndex > #cameras then
            cameraIndex = 1
        end
        camera = cameras[cameraIndex]
    end
    oldgreen = input("19e753ff")

    if input("0a3ee2ff") and not oldblue then
        cameraIndex = cameraIndex - 1
        if cameraIndex < 1 then
            cameraIndex = #cameras
        end
        camera = cameras[cameraIndex]
    end
    oldblue = input("0a3ee2ff")

    if not camera then
        camera = cameras[cameraIndex]
        if not camera then
            cameraIndex = 1
            camera = cameras[cameraIndex]
        end
    end

    if camera then
        if not pcall(function (...)
            camera.setFov(input("d02525ff") and zoomfov or fov)
            camera.setDistance(maxdistance)
            camera.setStep(drawingSpeed)
            camera.drawColorWithDepth(display)
        end) then
            camera = nil
        end
    else
        display.clear("09403cff")
    end

    if _endtick then
        display.clear()
        display.forceFlush()
        return
    end

    display.flush()
end]]
    elseif name == "eSiren" then
        str = 
[[
synthesizers = getComponents("synthesizer")

function calls(...)
    local args = {...}
    for i, cmp in ipairs(synthesizers) do
        cmp[args[1] ] (unpack(args, 2))
    end
end

calls("stop")

tick = 1
function callback_loop()
    if _endtick then
        calls("stop")
    else
        currentBeep = tick % 40 > 20

        if currentBeep ~= oldBeep then
            calls("stop")
            calls("clear")
            if currentBeep then
                calls("addBeep", 3, 0.5, 1, 40)
            else
                calls("addBeep", 3, 1, 1, 40)
            end
            calls("flush")
        end
        oldBeep = currentBeep
    end
    tick = tick + 1
end]]
    elseif name == "eLeds" then
        str = 
[[
ledsCount = 16

-------------------------------------

led = getComponents("led")[1]

function clamp(v, min, max)
    return math.max(math.min(v, max), min)
end

function genColorPart(resolution)
    return math.random(0, resolution) / resolution
end

function genColor(resolution, add)
    local r = genColorPart(resolution)
    local g = genColorPart(resolution)
    local b = genColorPart(resolution)
    local rBigger = r > g and r > b
    local gBigger = g > r and g > b
    local bBigger = b > g and b > r

    if rBigger then
        r = r - add
        g = g + add
        b = b + add
    end
    if gBigger then
        r = r + add
        g = g - add
        b = b + add
    end
    if bBigger then
        r = r + add
        g = g + add
        b = b - add
    end

    r = clamp(r, 0, 1)
    g = clamp(g, 0, 1)
    b = clamp(b, 0, 1)

    return r, g, b
end

targetColors = {}
currentColors = {}
for i = 1, ledsCount do
    table.insert(targetColors, {0, 0, 0})
    table.insert(currentColors, {0, 0, 0})
end

tick = 0
function callback_loop()
    if _endtick then
        for i = 0, ledsCount - 1 do
            led.setColor(i, sm.color.new(0, 0, 0))
        end
        return
    end

    if tick % 5 == 0 then
        for i = 1, 4 do
            targetColors[math.random(1, ledsCount)] = {0, 0, 0}
        end
        targetColors[math.random(1, ledsCount)] = {genColor(1, 0.1)}
    end
    
    for index, value in ipairs(targetColors) do
        local r, g, b = value[1], value[2], value[3]
        local cr, cg, cb = currentColors[index][1], currentColors[index][2], currentColors[index][3]
        
        cr = cr + ((r - cr) * 0.1)
        cg = cg + ((g - cg) * 0.1)
        cb = cb + ((b - cb) * 0.1)
    
        currentColors[index][1] = cr
        currentColors[index][2] = cg
        currentColors[index][3] = cb
    end
    
    for index, value in ipairs(currentColors) do
        led.setColor(index - 1, sm.color.new(value[1], value[2], value[3]))
    end
    
    tick = tick + 1
end]]
    elseif name == "eHolo" then
str =
[[
if _endtick then
    holo.clear()
    holo.flush()
    return
end

if not start then
    start = true
    tick = 0
    voxel_type = 2

    holo = getHoloprojectors()[1]
    holo.reset()
    holo.clear()

    holo.addVoxel(0, 1, 0, "812d03", voxel_type)
    holo.addVoxel(0, 2, 0, "812d03", voxel_type)
    holo.addVoxel(0, 3, 0, "812d03", voxel_type)
    
    holo.addVoxel(0, 5, 0, "418203", voxel_type)
    holo.addVoxel(0, 4, 0, "418203", voxel_type)
    holo.addVoxel(0, 4, 1, "418203", voxel_type)
    holo.addVoxel(0, 4, -1, "418203", voxel_type)
    holo.addVoxel(1, 4, 0, "418203", voxel_type)
    holo.addVoxel(-1, 4, 0, "418203", voxel_type)

    holo.flush()
end

holo.setScale(0.5, 0.5, 0.5)
holo.setRotation(0, math.rad(tick * 0.5), 0)
holo.setOffset(0, 1 + (math.sin(math.rad(tick)) * 0.8), 0)
tick = tick + 2]]
    elseif name == "eImgdraw" then
str  =
[[
local disk = getDisks()[1]
local display = getDisplays()[1]
display.reset()
display.setSkipAtLags(false)

local image = require("image")

--local img = assert(image.load(disk, "/colorbox64.bmp"))
local img = assert(image.load(disk, "/colorbox128.bmp"))
--local img = assert(image.load(disk, "/colorbox256.bmp"))
--local img = assert(image.load(disk, "/lighthouse64.bmp"))
--local img = assert(image.load(disk, "/lighthouse128.bmp"))
--local img = assert(image.load(disk, "/lighthouse256.bmp"))
--local img = assert(image.load(disk, "/mandelbulb64.bmp"))
--local img = assert(image.load(disk, "/mandelbulb128.bmp"))
--local img = assert(image.load(disk, "/mandelbulb256.bmp"))

display.clear()
img:draw(display)
display.forceFlush()

function callback_loop()
    if _endtick then
        display.clear()
        display.forceFlush()
    end
end
]]
    elseif name == "eDText" then
str = 
[[
if not start then
    text = "hello, world! abcdefghijklmnopqrstuvwxyz  ABCDEFGHIJKLMNOPQRSTUVWXYZ"

    display = getComponents("display")[1]
    display.reset()
    display.setSkipAtLags(true)
    display.setSkipAtNotSight(true)

    startPos = display.getWidth()
    textPos = startPos
    start = true
end

if _endtick then
    display.clear()
    display.forceFlush()
    return
end

display.clear("0076a1")
display.drawText(textPos, 1, text, "05a4dc")
display.flush()

textPos = textPos - 1 - getSkippedTicks()
if textPos < -(#text * (display.getFontWidth() + 1)) then
    textPos = startPos
end]]
    elseif name == "eImgdraw2" then
str  =
[[
local disk = getDisks()[1]
local display = getDisplays()[1]
display.reset()
display.setSkipAtLags(false)

local image = require("image")

--local img = assert(image.load(disk, "/colorbox64.bmp"))
local img = assert(image.load(disk, "/colorbox128.bmp"))
--local img = assert(image.load(disk, "/colorbox256.bmp"))
--local img = assert(image.load(disk, "/lighthouse64.bmp"))
--local img = assert(image.load(disk, "/lighthouse128.bmp"))
--local img = assert(image.load(disk, "/lighthouse256.bmp"))
--local img = assert(image.load(disk, "/mandelbulb64.bmp"))
--local img = assert(image.load(disk, "/mandelbulb128.bmp"))
--local img = assert(image.load(disk, "/mandelbulb256.bmp"))

display.clear()
display.forceFlush()

local drw = img:drawForTicks(display, 40 * 5)
function callback_loop()
    if _endtick then
        display.clear()
        display.forceFlush()
        return
    end

    if drw then
        if drw() then
            drw = nil
        end
        display.forceFlush()
    end
end
]]
    elseif name == "eGuiexample" then
    str = 
[[
display = getComponents("display")[1]
camera = getComponents("camera")[1]
display.reset()
display.clearClicks()
display.setSkipAtLags(false)
display.setClicksAllowed(true)

gui = require("gui").new(display)
image = require("image")

-------------------------

function buttonDrawer(self)
    local bg, fg = self.bg, self.fg
    if self.state then
        bg, fg = self.bg_press, self.fg_press
    end
    self.display.fillRect(self.x, self.y, self.sizeX, self.sizeY, bg)
    self.display.drawRect(self.x, self.y, self.sizeX, self.sizeY, fg)

    local x = math.floor(((self.x + (self.sizeX / 2)) - (((self.display.getFontWidth() + 1) * #self.text) / 2)) + 0.5)
    local y = math.floor(((self.y + (self.sizeY / 2)) - (self.display.getFontHeight() / 2)) + 0.5)
    self.display.drawText(x, y - 1, self.text, fg)
end

img = image.new(32, 32, sm.color.new(0, 0, 0))

scene = gui:createScene(sm.color.new(0, 0, 1))
button1 = scene:createButton(1, 1, 40, 8, false, "button")
button2 = scene:createButton(1, 9, 40, 8, true, "toggle")
selectScene2 = scene:createButton(1, 17, 40, 8, false, "scene2")

scene2 = gui:createScene(sm.color.new(0, 1, 1))
label = scene2:createLabel(1, 1, 40, 8, "label")
text = scene2:createText(1, 10, "text")
selectScene1 = scene2:createButton(1, 17, 40, 8, false, "scene1")
gimg = scene2:createImage(display.getWidth() - 32, display.getHeight() - 32, img)

selectScene1:setCustomStyle(buttonDrawer)
selectScene2:setCustomStyle(buttonDrawer)

scene:select()

tick = 0
function callback_loop()
    if _endtick then
        display.clear()
        display.forceFlush()
        return
    end

    gui:tick()
    if button1:isPress() then
        print("button pressed")
    end
    if button1:isReleased() then
        print("button released")
    end
    if button2:isPress() then
        print("toggle true")
    end
    if button2:isReleased() then
        print("toggle false")
    end

    if selectScene2:isPress() then
        print("scene 2")
        scene2:select()
    end
    if selectScene1:isPress() then
        print("scene 1")
        scene:select()
    end

    if scene2:isSelected() then
        if camera then
            img:fromCamera(camera, "drawDepth", sm.color.new(0, 1, 0))
            gimg:update()
        end
        text:clear()
        text:setText(tostring(tick))
        text:update()

        label:setBgColor(sm.color.new(math.random(), math.random(), math.random()))
        label:update()
    end

    if gui:needFlush() then
        gui:draw()
        display.flush()
    end

    tick = tick + 1
end
]]
    elseif name == "eMidi" then
        str = 
[[
midi = require("midi")

synthesizers = getSynthesizers()
disk = getDisks()[1]

player = midi.create()
player:load(disk, "2.mid")
player:setSynthesizers(synthesizers)
player:setSpeed(1)
player:setNoteShift(-50)
player:setNoteAlignment(1)
player:setVolume(0.1)
player:setDefaultInstrument(4)

player:start()
function callback_loop()
    if _endtick then
        player:stop()
    end
    player:tick()
end
]]
    elseif name == "eTerm" then
        str = 
[[
lineend = string.char(13)

terminal = getComponents("terminal")[1]
terminal.read()
terminal.clear()
terminal.write("#ffff00terminal demo code" .. lineend)

function callback_loop()
    local text = terminal.read()
    if text then
        if text == "/beep" then
            terminal.write(string.char(7))
        elseif text == "/clear" then
            terminal.clear()
        end
        terminal.write("#00ff00> " .. text .. lineend)
    end

    if _endtick then
        terminal.clear()
    end
end
]]
    elseif name == "eSCamera" then
        str = 
[[
--this simplest camera demonstrates the operation of the "image" library

image = require("image")
colors = require("colors")

display = getDisplays()[1]
disk = getDisks()[1]

if input(colors.sm.Red[2]) then
    disk.clear()

    local img = image.new(32, 32, sm.color.new(0, 0, 0))
    img:fromCameraAll(getCameras()[1], "drawDepth")
    img:save(disk, "/image")
elseif input(colors.sm.Green[2]) then
    local img = image.load(disk, "/image")
    display.clear()
    img:draw(display)
    display.forceFlush()
end

function callback_loop()
    if _endtick then
        display.clear()
        display.forceFlush()
    end
end
]]
    elseif name == "eScar" then
        str = 
[[
motor = getComponents("motor")[1]
motor.setActive(true)

display = getComponents("display")[1]
display.reset()
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
]]
    elseif name == "eVmtest" then
str = 
[[
--this script is testing lua. the lua virtual machine must pass all these tests

if start then return end
start = true
bad = 0

function badMsg(msg)
    bad = bad + 1
    print("bad: " .. msg)
end

print("------------------")

--------------------------------

anyvar = true
function func(anyvar)
    if anyvar then
        badMsg("test 1")
    end
end
func()

--------------------------------

do
    local anyVar2 = true
    function func2()
        if not anyVar2 then
            badMsg("test 2")
        end
    end
end
func2()

--------------------------------

local ok, code = pcall(loadstring, "return #{...}")
if ok and code then
    local ok, data = pcall(code, 1, 2, 3, 4, 5)
    if not ok or data ~= 5 then
        badMsg("test 3")
    end
else
    badMsg("test 3 (preparation)")
end

--------------------------------

function func3(a, b, ...)
    local tbl = {...}
    if #tbl ~= 3 then
        badMsg("test 4")
    end
end
func3(1, 2, 3, 4, 5)

--------------------------------

funcs = {}
for index, value in ipairs({1, 2, 3, 4, 5}) do
    funcs[index] = function ()
        return value
    end
end

if funcs[3]() ~= 3 then
    badMsg("test 5")
end

--------------------------------

local ok = pcall(load, "--[[any test\nany new line]\]")
if not ok then
    badMsg("test 6")
end

--------------------------------

local ok, code = pcall(load, [[
::lbl::
if asd then
    return b
end
local b = 2
asd = true
goto lbl
]\])
if ok and code then
    local ok, data = pcall(code)
    if not ok or data ~= nil then
        badMsg("test 7")
    end
else
    badMsg("test 7 (preparation)")
end

--------------------------------

do
    local test = 1
end
if test then
    badMsg("test 8")
end

--------------------------------

do
    local function getValues()
        return 1, 2, 3
    end
    local tbl1 = {0, getValues()}
    local tbl2 = {0, getValues(), 2}
    local tbl3 = {getValues()}
    local tbl4 = {getValues(), 2}

    if tbl1[1] ~= 0 or tbl1[2] ~= 1 or tbl1[3] ~= 2 or tbl1[4] ~= 3 or #tbl1 ~= 4 then
        badMsg("test 9. part 1")
    end
    if tbl2[1] ~= 0 or tbl2[2] ~= 1 or tbl2[3] ~= 2 or #tbl2 ~= 3 then
        badMsg("test 9. part 2")
    end
    if tbl3[1] ~= 1 or tbl3[2] ~= 2 or tbl3[3] ~= 3 or #tbl3 ~= 3 then
        badMsg("test 9. part 3")
    end
    if tbl4[1] ~= 1 or tbl4[2] ~= 2 or #tbl4 ~= 2 then
        badMsg("test 9. part 4")
    end
end

--------------------------------

do
    local anyVar3 = 7
    function tchange()
        anyVar3 = 3
    end
    function tget()
        return anyVar3
    end
end
if tget() ~= 7 then
    badMsg("test 10. part1")
end
tchange()
if tget() ~= 3 then
    badMsg("test 10. part2")
end

--------------------------------

if bad > 0 then
    print("bad-lua: " .. bad)
else
    print("normal-lua: " .. bad)
end
]]
    elseif name == "eIo" then
str = [[
--composite writer(input) - writes a number/boolean to the computer register, while the values are always represented as a number
--composite reader(output) - outputs the value of the computer register to the logic-block/number-logic-block

clearregs() --clears all registers

function callback_loop()
    local number = getreg("num")
    if number then
        setreg("out", number + 1)
    else
        setreg("out", -1)
    end
end
]]
    elseif name == "eIb" then
str = [[
image = require("image")

ibridge = getComponents("ibridge")[1]
display = getComponents("display")[1]
display.reset()

if not ibridge.isAllow() then
    display.clear()
    display.drawText(1, 1, "bridge")
    display.drawText(1, 9, "error")
    display.forceFlush()
    return
end

response = ibridge.get("https://raw.githubusercontent.com/igorkll/SComputers_docs/main/ROM/test.bmp", {})
img = image.decodeBmp(response[2])
display.clear()
img:draw(display)
display.forceFlush()

function callback_loop()
    if _endtick then
        display.clear()
        display.forceFlush()
    end
end
]]
    elseif name == "eGPS" then
str = [[
--The GPS module allows you to get your position, as well as get the GPSTAGS position
--to detect gps tag, you need to know its frequency (which is randomly selected when installing gpstag)
--at the moment, the GPS tag can be detected at a non-limited distance
--but the further the GPS Tag is from the GPS module, the more noise there is in the measurement
--there is also a minimum noise level that is present even when measuring your own position
--the noise level is 1 degree and 1 block per 100 meters of distance
--the minimum noise level is equal to the gps tag position at a distance of a meter(this noise is present even when measuring your own position)
--don't forget that the getSelfGpsData and getTagsGpsData methods can only be used 1 time per tick

utils = require("utils")
gps = getComponents("gps")[1]

function callback_loop()
    local gpsdata = gps.getSelfGpsData()

    print("------------------------------------------------")
    print("position-self", utils.roundTo(gpsdata.position.x, 1), utils.roundTo(gpsdata.position.y, 1), utils.roundTo(gpsdata.position.z, 1))
    print("rotation-self", utils.roundTo(gpsdata.rotation.x, 1), utils.roundTo(gpsdata.rotation.y, 1), utils.roundTo(gpsdata.rotation.z, 1), utils.roundTo(gpsdata.rotation.w, 1))
    print("rotation-euler-self", utils.roundTo(gpsdata.rotationEuler.x, 1), utils.roundTo(gpsdata.rotationEuler.y, 1), utils.roundTo(gpsdata.rotationEuler.z, 1))
    for i, v in ipairs(gps.getTagsGpsData(0)) do
        print("position-tag:" .. tostring(i), utils.roundTo(v.position.x, 1), utils.roundTo(v.position.y, 1), utils.roundTo(v.position.z, 1))
        print("rotation-tag:" .. tostring(i), utils.roundTo(v.rotation.x, 1), utils.roundTo(v.rotation.y, 1), utils.roundTo(v.rotation.z, 1), utils.roundTo(v.rotation.w, 1))
        print("rotation-euler-tag:" .. tostring(i), utils.roundTo(gpsdata.rotationEuler.x, 1), utils.roundTo(gpsdata.rotationEuler.y, 1), utils.roundTo(gpsdata.rotationEuler.z, 1))
    end
end
]]
    elseif name == "eRamfs" then
str = [[
--example, this code allows you to allocate a small file system in a computer data string
local ramfs = require("ramfs")

local currentComputerData = getData()
local fsobj
if currentComputerData == "" then
    fsobj = ramfs.create(1024 * 2)
else
    fsobj = ramfs.load(currentComputerData)
end

local disk = fsobj.fs

-----------------------------------

if not disk.hasFile("/test") then
    disk.createFile("/test")
    disk.writeFile("/test", "test data")
end

if not disk.hasFile("/test2") then
    disk.createFile("/test2")
    disk.writeFile("/test2", "test data 2")
end

print("files:")
for i, v in ipairs(disk.getFileList("/")) do
    print(v, ":", disk.readFile(v))
end

function callback_loop()
    if fsobj:isChange() then
        setData(fsobj:dump())
    end
end
]]
    elseif name == "eVD" then
str = [[
--makes a holographic display
vdisplay = require("vdisplay")
holo = getComponents("holoprojector")[1]
holo.reset()
holo.clear()
holo.flush()

width, height = 32, 32
currentContent = {}
currentId = {}
for y = 0, height - 1 do
    currentContent[y] = {}
    currentId[y] = {}
end

function clear(color)
    lastClearColor = color or "000000"
    buffer = {}
end
function set(x, y, color)
    if currentContent[y][x] ~= color then
        if currentId[y][x] then
            holo.delVoxel(currentId[y][x])
        end
        currentId[y][x] = holo.addVoxel(x - (width / 2), (((height - 1) - y) - (height / 2)) + 20, 0, color, 2)
        currentContent[y][x] = color
    end
end
function flush()
    for x = 0, width - 1 do
        for y = 0, height - 1 do
            local ytbl = buffer[y]
            if ytbl then
                set(x, y, ytbl[x] or lastClearColor)
            else
                set(x, y, lastClearColor)
            end
        end
    end
    holo.flush()
end

clear()
flush()

dsp_callbacks = {
    set = function (self, x, y, color)
        if not buffer[y] then buffer[y] = {} end
        buffer[y][x] = color or "ffffff"
    end,
    clear = function (self, color)
        clear(color)
    end,
    flush = function (self, isForce)
        flush()
    end
}
dsp = vdisplay.create(dsp_callbacks, width, height)
setComponentApi("display", dsp) --this line will cause your computer to be identified by other computers as a display
function callback_loop()
    if _endtick then
        holo.reset()
        holo.clear()
        holo.flush()
    end
end
]]
    elseif name == "eRadar" then
str = [[
--------------------- settings

local maxdist = 60

--------------------- code

local colors = require("colors")
local utils = require("utils")

local radar = getComponents("radar")[1]
local display = getComponents("display")[1]
display.reset()

radar.setHFov(math.rad(16))
radar.setVFov(math.rad(180))

local rx, ry = display.getWidth(), display.getHeight()
local crx, cry = rx / 2, ry / 2
local tick = 0

local points = {}
local idColors = {}

function callback_loop()
    if _endtick then
        display.clear()
        display.flush()
        return
    end

    local angle = utils.roundTo(math.rad(tick % 360))
    radar.setAngle(angle)

    display.clear()
    --display.drawLine(crx, cry, (math.sin(angle) * crx) + crx, (math.cos(angle) * cry) + cry)
    for i = #points, 1, -1 do
        local point = points[i]
        if point[3] == angle then
            table.remove(points, i)
        end
    end
    for index, value in ipairs(radar.getTargets()) do
        local id, hangle, vangle, dist, force, ctype = unpack(value)

        local s = (dist / maxdist) * crx

        local x = math.floor(math.sin(hangle) * s + crx)
        local y = math.floor(-math.cos(hangle) * s + crx)

        if not idColors[id] then
            if ctype == "character" then
                idColors[id] = colors.sm.Gray[1]
            else
                idColors[id] = sm.color.new(math.random(), math.random(), math.random())
            end
        end
        for i = #points, 1, -1 do
            local point = points[i]
            if point[4] == id then
                table.remove(points, i)
            end
        end
        table.insert(points, {x, y, angle, id})
    end
    for i = #points, 1, -1 do
        local point = points[i]
        display.drawPixel(point[1], point[2], idColors[ point[4] ])
    end
    for ix = -1, 1 do
        for iy = -1, 1 do
            if ix == 0 or iy == 0 then
                display.drawPixel(crx + ix, cry + iy, (ix == 0 and iy == -1) and "00ff00" or "ff0000")
            end
        end
    end
    display.flush()

    tick = tick + 16
end
]]
    elseif name == "eWASD" then
str = [[
local wasd = getComponents("wasd")[1]
local display = getComponents("display")[1]
display.reset()

function drawLabel(x, y, char, state, color)
    display.fillRect(x, y, 6, 7, state and color or "000000")
    display.drawText(x + 1, y + 1, char, state and "000000" or color)
end

function callback_loop()
    if _endtick then
        display.clear()
        display.flush()
        return
    end

    local color = wasd.isSeated() and "00ff00" or "ff0000"
    display.clear()
    drawLabel(5,  1, "W", wasd.isW(), color)
    drawLabel(5,  8, "S", wasd.isS(), color)
    drawLabel(-1, 8, "A", wasd.isA(), color)
    drawLabel(11, 8, "D", wasd.isD(), color)
    display.flush()
end
]]
    elseif name == "eCF" then
str = [[
local display = getComponents("display")[1]

display.reset()
display.clear()
display.setFont(
    {
        width = 3,
        height = 3,
        chars = {
            error = {
                "111",
                "1.1",
                "111"
            },
            a = {
                ".1.",
                "111",
                "1.1"
            },
            b = {
                "1..",
                "111",
                "111"
            },
            c = {
                "111",
                "1..",
                "111"
            }
        }
    }
)
display.drawText(1, 1, "abcdef", "ff0000")
display.flush()

function callback_loop()
    if _endtick then
        display.clear()
        display.flush()
    end
end
]]
    elseif name == "eRR" then
str = [[
local camera = getComponents("camera")[1]

function callback_loop()
    local data = camera.rawRay(0, 0, 512)
    if data then
        print("----------------")
        for k, v in pairs(data) do
            print(k, v)
        end
    end
end
]]
    elseif name == "eAR" then
str = [[
local display = getComponents("display")[1]
display.reset()
--this approach will allow you to cause fewer lags, due to which the mod will reduce the clock frequency of the computer (virtual) less, due to which the rendering will be faster.
display.setSkipAtLags(true) --in order for rendering to be skipped if the game is lagging(true by default)
display.setSkipAtNotSight(true) --in order for the picture not to be updated for those who do not look at the screen

local camera = getComponents("camera")[1]
camera.setFov(math.rad(60))
camera.setStep(512)

function callback_loop()
    if _endtick then
        display.clear()
        display.flush()
        return
    end

    camera.drawAdvanced(display)
    display.flush()
end
]]
    elseif name == "eCR" then
str = [[
--and why not))

local colors = require("colors")

local display = getComponents("display")[1]
display.reset()
--this approach will allow you to cause fewer lags, due to which the mod will reduce the clock frequency of the computer (virtual) less, due to which the rendering will be faster.
display.setSkipAtLags(true) --in order for rendering to be skipped if the game is lagging(true by default)
display.setSkipAtNotSight(true) --in order for the picture not to be updated for those who do not look at the screen

local camera = getComponents("camera")[1]
camera.setFov(math.rad(60))
camera.setStep(512)

function callback_loop()
    if _endtick then
        display.clear()
        display.flush()
        return
    end

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
]]
    elseif name == "eHSD" then
str = [[
--this is not my code, it was made by another person and we decided to add it here

vdisplay = require("vdisplay")
holo = getComponents("holoprojector")[1]
holo.reset()
holo.clear()
holo.flush()

holo.setScale(0.02, 0.02, 0.02)
holo.setOffset(0, 60, 0)

width, height = 32, 32
arg= 360/width
argy= 360/height
rx, ry, rz = 16, 16, 16

existsVoxels = {}

function clear(color)
    lastClearColor = color or "000000"
    buffer = {}
end
function set(x, y, color)

    q=math.sin(arg*x*math.pi/180)*math.sin(argy*y*math.pi/180)*rx
    w=math.cos(argy*y*math.pi/180)*ry
    e=math.sin(argy*y*math.pi/180)*math.cos(arg*x*math.pi/180)*rz

    local aq = math.floor(q + 0.5)
    local aw = math.floor(w + 0.5)
    local ae = math.floor(e + 0.5)

    if not existsVoxels[aq .. ":" .. aw .. ":" .. ae] then
        holo.addVoxel(q, w, e, color, 1)
        existsVoxels[aq .. ":" .. aw .. ":" .. ae] = true
    end
end
function flush()
    holo.clear()
    for x = 0, width - 1 do
        for y = 0, height - 1 do
            local ytbl = buffer[y]
            if ytbl then
                set(x, y, ytbl[x] or lastClearColor)
            else
                set(x, y, lastClearColor)
            end
        end
    end
    holo.flush()

    existsVoxels = {}
end

clear()
flush()

dsp_callbacks = {
    set = function (self, x, y, color)
        if not buffer[y] then buffer[y] = {} end
        buffer[y][x] = color or "ffffff"
    end,
    clear = function (self, color)
        clear(color)
    end,
    flush = function (self, isForce)
        flush()
    end
}
dsp = vdisplay.create(dsp_callbacks, width, height)
setComponentApi("display", dsp) --this line will cause your computer to be identified by other computers as a display
function callback_loop()
    if _endtick then
        holo.reset()
        holo.clear()
        holo.flush()
    end
holo.setRotation(0, sm.game.getCurrentTick()*math.pi/180, 0)
end
]]
    elseif name == "eRD" then
str = [[
local display = getComponents("display")[1]
local radarDetector = getComponents("radarDetector")[1]

local rx, ry = display.getWidth(), display.getHeight()

function callback_loop()
    if _endtick then
        display.clear()
        display.flush()
        return
    end

    display.clear()
    display.fillCircle(rx / 2, ry / 2, rx / 2,       "22ee22")
    display.fillCircle(rx / 2, ry / 2, (rx / 2) - 1, "002200")

    for _, vec in ipairs(radarDetector.getRadars()) do
        display.drawLine(rx / 2, ry / 2, (rx / 2) - (vec.y * (rx / 3)), (ry / 2) + (vec.x * (ry / 3)), "ff0000")
    end

    display.flush()
end
]]
    elseif name == "eIE" then
str = [[
local wasd = getComponents("wasd")[1]
local inertialEngine = getComponents("inertialEngine")[1]

inertialEngine.setActive(true)
inertialEngine.setStableMode(1)

local speed = 1
local rotateSpeed = math.rad(5)

--------------------------

local function up()
    inertialEngine.addPosition(sm.vec3.new(0, 0, speed))
end

local function down()
    inertialEngine.addPosition(sm.vec3.new(0, 0, -speed))
end

local function forward()
    inertialEngine.addPosition(sm.vec3.new(speed, 0, 0))
end

local function back()
    inertialEngine.addPosition(sm.vec3.new(-speed, 0, 0))
end

local function left()
    inertialEngine.addPosition(sm.vec3.new(0, speed, 0))
end

local function right()
    inertialEngine.addPosition(sm.vec3.new(0, -speed, 0))
end

--------------------------

local function _up()
    inertialEngine.addRotation(sm.vec3.new(0, -rotateSpeed, 0))
end

local function _down()
    inertialEngine.addRotation(sm.vec3.new(0, rotateSpeed, 0))
end

local function _left()
    inertialEngine.addRotation(sm.vec3.new(0, 0, rotateSpeed))
end

local function _right()
    inertialEngine.addRotation(sm.vec3.new(0, 0, -rotateSpeed))
end

--------------------------

function callback_loop()
    if _endtick then
        inertialEngine.setActive(false)
        return
    end

    forward()

    if wasd.isW() then
        _up()
    elseif wasd.isS() then
        _down()
    end

    if wasd.isA() then
        _left()
    elseif wasd.isD() then
        _right()
    end
end
]]
    else
        str = "--temporarily unavailable"
    end
    if str then
        str = str:gsub("]\\]", "]]")
        ScriptableComputer.cl_setText(self, str)
    end
end

function bindExamples(self)
    self.gui:setButtonCallback("eBios", "cl_onExample")
    self.gui:setButtonCallback("eCamera", "cl_onExample")
    self.gui:setButtonCallback("eSiren", "cl_onExample")
    self.gui:setButtonCallback("eLeds", "cl_onExample")
    self.gui:setButtonCallback("eHolo", "cl_onExample")
    self.gui:setButtonCallback("eGuicamera", "cl_onExample")
    self.gui:setButtonCallback("eGuiexample", "cl_onExample")
    self.gui:setButtonCallback("eImgdraw", "cl_onExample")
    self.gui:setButtonCallback("eFs", "cl_onExample")
    self.gui:setButtonCallback("eDText", "cl_onExample")
    self.gui:setButtonCallback("eImgdraw2", "cl_onExample")
    self.gui:setButtonCallback("eMidi", "cl_onExample")
    self.gui:setButtonCallback("eTerm", "cl_onExample")
    self.gui:setButtonCallback("eSCamera", "cl_onExample")
    self.gui:setButtonCallback("eScar", "cl_onExample")
    self.gui:setButtonCallback("eVmtest", "cl_onExample")
    self.gui:setButtonCallback("eIo", "cl_onExample")
    self.gui:setButtonCallback("eIb", "cl_onExample")
    self.gui:setButtonCallback("eGPS", "cl_onExample")
    self.gui:setButtonCallback("eRamfs", "cl_onExample")
    self.gui:setButtonCallback("eVD", "cl_onExample")
    self.gui:setButtonCallback("eRadar", "cl_onExample")
    self.gui:setButtonCallback("eWASD", "cl_onExample")
    self.gui:setButtonCallback("eCF", "cl_onExample")
    self.gui:setButtonCallback("eIE", "cl_onExample")
    self.gui:setButtonCallback("eST", "cl_onExample")
    self.gui:setButtonCallback("eRD", "cl_onExample")
    self.gui:setButtonCallback("eRR", "cl_onExample")
    self.gui:setButtonCallback("eAR", "cl_onExample")
    self.gui:setButtonCallback("eCR", "cl_onExample")
    self.gui:setButtonCallback("eHSD", "cl_onExample")
    self.gui:setButtonCallback("eHTD", "cl_onExample")
end