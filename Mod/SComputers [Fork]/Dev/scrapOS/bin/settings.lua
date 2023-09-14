options = args[1]
screen = options.screen
gui = guilib.create(screen)

scene = gui.createScene("000000")

label = scene.createLabel(4, (gui.sizeY / 2) - 5, gui.sizeX - 8, 10, "222222", "00ff00")
exitButton = scene.createButton(
    gui.sizeX - 8,
    0,
    8,
    8,
    "X",
    "00ff00",
    "000000",
    "0000FF",
    "000000",
    1
)

gui.select(scene)

----------------------------------

function onTick()
    gui.tick()

    if exitButton.getState() then
        utils.exit(object)
    end

    local keyboard = getKeyboards()[1]
    if keyboard then
        label.text = "esc - load, enter - save"

        local str = sm.json.writeJsonString(settings.current)
        local kstr = keyboard.read()

        if keyboard.isEsc() then
            keyboard.write(str)
        end
        
        if keyboard.isEnter() then
            pcall(function ()
                settings.current = sm.json.parseJsonString(kstr)
                settings.save()
            end)
        end
        keyboard.resetButtons()
    else
        label.text = "connect the keyboard"
    end

    gui.draw()
end