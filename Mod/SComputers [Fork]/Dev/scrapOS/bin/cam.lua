options = args[1]
screen = options.screen
local old_skipatlags = screen.getSkipAtLags()
screen.setSkipAtLags(false)
gui = guilib.create(screen)


currentFrame = {x = screen.getWidth(), y = screen.getHeight(), data = {}}
for y = 1, screen.getHeight() do
    currentFrame.data[y] = {}
    for x = 1, screen.getWidth() do
        currentFrame.data[y][x] = "000000"
    end
end

---------------------------------------------------

scene = gui.createScene("000077")


exitButton = scene.createButton(
    gui.sizeX - 8,
    0,
    8,
    8,
    "X",
    "FF0000",
    "FFFFFF",
    nil,
    nil,
    1
)

selectCameraButton = scene.createButton(
    gui.sizeX - 8,
    8,
    8,
    8,
    "S",
    "00FF00",
    "FFFFFF",
    nil,
    nil,
    1
)

loadButton = scene.createButton(
    gui.sizeX - 8,
    16,
    8,
    8,
    "L",
    "ffff00",
    "FFFFFF",
    nil,
    nil,
    1
)

removeButton = scene.createButton(
    gui.sizeX - 8,
    16 + 8,
    8,
    8,
    "R",
    "ff0000",
    "FFFFFF",
    nil,
    nil,
    1
)

photoButton = scene.createButton(
    gui.sizeX - 8,
    gui.sizeY - 8,
    8,
    8,
    "P",
    "ffffff",
    "000000",
    nil,
    nil,
    1
)

---------------------------------------------------

gui.select(scene)

function resetCounter()
    if camera then
        camera.resetCounter()
    end
end

function onStart()
end

function onTick()
    gui.tick()

    if splashFlag then
        if gui.click and gui.click[3] == "pressed" then
            splashFlag = nil
        end
        return
    end

    if selectedPhoto then
        if not drawEnd then
            if not drawX then drawX = 1 end
            for y = 1, selectedPhoto.y do
                if not selectedPhoto.data[y] or not selectedPhoto.data[y][drawX] then
                    splashFlag = true
                    selectedPhoto = nil
                    drawX = nil
                    drawEnd = nil
                    gui.splash("the picture is broken")
                    return
                end
                screen.drawPixel(drawX - 1, y - 1, selectedPhoto.data[y][drawX])
            end
            drawX = drawX + 1
            if drawX > selectedPhoto.x then
                drawX = nil
                drawEnd = true
            end
        end
        gui.update()
        
        if gui.click and gui.click[3] == "pressed" then
            selectedPhoto = nil
            drawEnd = nil
            drawX = nil
        end
        return
    end
    
    if camera then
        if not pcall(function () --для обработки удаления камеры
            camera.drawColorWithDepth({
                getWidth = function ()
                    return gui.sizeX
                end,
                getHeight = function ()
                    return gui.sizeY
                end,
                drawPixel = function (x, y, color)
                    currentFrame.data[y + 1][x + 1] = color
                    screen.drawPixel(x, y, color)
                end
            })
        end) then
            camera = nil
        end
        gui.draw(true)
    else
        gui.draw()
    end

    if removePhotoMenu then
        removePhotoMenu.draw()

        local action = removePhotoMenu.getSelected()
        if action then
            if action ~= true then
                fs.remove(removePhotoMenu.files[action])
            end
            removePhotoMenu = nil

            resetCounter()
        end
    elseif selectCameraMenu then
        selectCameraMenu.draw()

        local action = selectCameraMenu.getSelected()
        if action then
            if action ~= true then
                camera = selectCameraMenu.cameras[action]

                camera.setStep(256)
                camera.setDistance(256)
                camera.setFov(math.rad(75))
            end
            selectCameraMenu = nil

            resetCounter()
        end
    elseif selectPhotoMenu then
        selectPhotoMenu.draw()

        local action = selectPhotoMenu.getSelected()
        if action then
            if action ~= true then
                if not pcall(function ()
                    selectedPhoto = sm.json.parseJsonString(fs.read(selectPhotoMenu.files[action]))
                end) then
                    gui.splash("the picture is broken")
                    splashFlag = true
                end
            end
            selectPhotoMenu = nil

            resetCounter()
        end
    else
        if exitButton.getState() then
            screen.setSkipAtLags(old_skipatlags)
            utils.exit(object)
        end
        
        if selectCameraButton.getState() then
            local names = {}
            local cameras = {}
            for index, camera in ipairs(getCameras()) do
                table.insert(names, "cam: " .. index)
                cameras[index] = camera
            end
            selectCameraMenu = gui.context(1, 1, names)
            selectCameraMenu.cameras = cameras
        end

        if photoButton.getState() then
            if camera then
                fs.write("/data/photos/" .. tostring(sm.uuid.new()):sub(1, 6), sm.json.writeJsonString(currentFrame))
            else
                gui.splash("select camera")
                splashFlag = true
            end
        end

        if loadButton.getState() or removeButton.getState() then
            local names = {}
            local files = {}
            for _, name in ipairs(fs.list("/data/photos") or {}) do
                table.insert(names, name)
                table.insert(files, fs.concat("/data/photos", name))
            end

            if removeButton.getState() then
                removePhotoMenu = gui.context(1, 1, names)
                removePhotoMenu.files = files
            else
                selectPhotoMenu = gui.context(1, 1, names)
                selectPhotoMenu.files = files
            end
        end
    end
end