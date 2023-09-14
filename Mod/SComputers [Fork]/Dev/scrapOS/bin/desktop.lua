options = args[1]
screen = options.screen
gui = guilib.create(screen)

-----------------

scene = gui.createScene("00FFFF")

scene.createDrawer(0, gui.sizeY - 10, gui.sizeX, 10, function(screen, x, y, sx, sy)
    screen.fillRect(x, y, sx, sy, utils.formatColor("00FF00"))
end)

menuButton = scene.createButton(
    0,
    gui.sizeY - 10,
    10,
    10,
    "M",
    "0000FF",
    "FFFFFF",
    "FF0000",
    "000000",
    1
)

gui.select(scene)

function updateProgramsList()
    if programmButtons then
        for i, v in ipairs(programmButtons) do
            for i2, v2 in ipairs(scene.objects) do
                if v == v2 then
                    table.remove(scene.objects, i2)
                    break
                end
            end
        end
    end
    
    programmButtons = {}
    
    local count = 0
    for i, v in ipairs(fs.list("/bin")) do
        local path = fs.concat("/bin", v)
        if not fs.isDirectory(path) and path ~= object.path then
            local button = scene.createButton(
                4,
                (count * 11) + 4,
                gui.sizeX / 2,
                10,
                fs.hideExp(v),
                "FFFFFF",
                "333333",
                "000000",
                "FFFFFF",
                1
            )
            button.path = path
            table.insert(programmButtons, button)
            count = count + 1
        end
    end
end

function onStart()
    updateProgramsList()
end

function onTick()
    if not openProgramm then
        gui.tick()
        if textOnScreen then
            if gui.click and gui.click[3] == "pressed" then
                textOnScreen = nil
            end
        elseif contextMenu then
            contextMenu.draw()
            gui.screen.flush()

            local out = contextMenu.getSelected()
            if out then
                contextMenu = nil
            end
        else
            --[[
            if menuButton.getState() then
                contextMenu = gui.context((gui.sizeX / 2) + 6, 4, {"qwe 1", "asd 2", "zxc 3", "tyu 4"})
            end
            ]]
            if menuButton.getState() then
                contextMenu = gui.yesno("123")
            end

            for i, v in ipairs(programmButtons) do
                if v.getState() then
                    openProgramm = {enable = true, path = v.path, args = {{screen = screen}}, notPrintError = true}
                    table.insert(_G.openPrograms, openProgramm)
                end
            end

            gui.draw()
        end
    else
        local finded = false
        for i, v in ipairs(_G.openPrograms) do
            if v == openProgramm then
                finded = true
                break
            end
        end
        if not finded or openProgramm.error then
            if openProgramm.error then
                gui.splash(openProgramm.error)
                textOnScreen = true
            end
            for i, v in ipairs(_G.openPrograms) do
                if v == openProgramm then
                    table.remove(_G.openPrograms, i)
                    break
                end
            end
            openProgramm = nil
        end
    end
end