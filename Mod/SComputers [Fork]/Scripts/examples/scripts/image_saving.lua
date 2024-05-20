--this simplest camera demonstrates the operation of the "image" library
--red button - make photo
--green button - show photo

image = require("image")
colors = require("colors")

display = getDisplays()[1]
disk = getDisks()[1]

if input(colors.sm.Red[2]) then
    disk.clear()

    local img = image.new(display.getWidth(), display.getHeight(), sm.color.new(0, 0, 0))
    img:fromCameraAll(getCameras()[1], "drawAdvanced")
    img:save(disk, "/image")

    display.clear("0000ff")
    display.drawText(1, 1, "photo maked!")
    display.forceFlush()
elseif input(colors.sm.Green[2]) then
    if disk.hasFile("/image") then
        local img = image.load(disk, "/image")
        display.clear()
        img:draw(display)
        display.forceFlush()
    else
        display.clear("0000ff")
        display.drawText(1, 1, "no photo")
        display.forceFlush()
    end
end

function callback_loop()
    if _endtick then
        display.clear()
        display.forceFlush()
    end
end