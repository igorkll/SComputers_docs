return {create = function(screen)
    local gui = {}
    gui.scenes = {}
    gui.screen = screen
    gui.selected = nil
    gui.charSizeX = 4
    gui.charSizeY = 8
    gui.sizeX = gui.screen.getWidth()
    gui.sizeY = gui.screen.getHeight()
    gui.lockCount = 0

    gui.screen.setClicksAllowed(false)

    function gui.createScene(color)
        local scene = {}
        scene.color = utils.formatColor(color or "000000")
        scene.objects = {}

        function scene.draw(noClear)
            if scene ~= gui.selected then return end
            if not noClear then
                gui.screen.clear(scene.color)
            end
            for i, v in ipairs(scene.objects) do
                v.draw()
            end
        end

        function scene.createLabel(x, y, sx, sy, text, color2, textcolor)
            local obj = {}
            obj.posX = x
            obj.posY = y
            obj.sizeX = sx or 10
            obj.sizeY = sy or 10
            obj.text = text or ""
            obj.color = utils.formatColor(color2 or "FFFFFF")
            obj.textcolor = utils.formatColor(textcolor or "000000")
            obj.scene = scene
            obj.type = "label"

            function obj.draw()
                if scene ~= gui.selected then return end
                gui.screen.fillRect(obj.posX, obj.posY, obj.sizeX, obj.sizeY, obj.color)
                gui.screen.drawText(
                    obj.posX + math.floor((obj.sizeX / 2) - (#obj.text * ((gui.charSizeX + 1) / 2))),
                    obj.posY + math.floor((obj.sizeY / 2) - (gui.charSizeY / 2)) + 2,
                    obj.text,
                    obj.textcolor
                )
            end


            table.insert(scene.objects, obj)
            return obj
        end

        function scene.createButton(x, y, sx, sy, text, color2, textcolor, invertColor, invertColorText, mode, state)
            gui.screen.setClicksAllowed(true)
            
            local obj = {}
            obj.posX = x
            obj.posY = y
            obj.sizeX = sx or 10
            obj.sizeY = sy or 10
            obj.text = text or ""
            obj.color = utils.formatColor(color2 or "FFFFFF")
            obj.textcolor = utils.formatColor(textcolor or "000000")
            obj.invertColor = utils.formatColor(invertColor or color2 or "000000")
            obj.invertColorText = utils.formatColor(invertColorText or textcolor or "FFFFFF")
            obj.mode = mode or 1
            obj.state = state
            obj.type = "button"
            obj.scene = scene

            function obj.draw(invert)
                if scene ~= gui.selected then return end
                
                if obj.state then
                    invert = true
                end
                
                gui.screen.fillRect(obj.posX, obj.posY, obj.sizeX, obj.sizeY, invert and obj.invertColor or obj.color)
                gui.screen.drawText(
                    obj.posX + math.floor((obj.sizeX / 2) - (#obj.text * ((gui.charSizeX + 1) / 2))),
                    obj.posY + math.floor((obj.sizeY / 2) - (gui.charSizeY / 2)) + 2,
                    obj.text,
                    invert and obj.invertColorText or obj.textcolor
                )
            end

            function obj.getState()
                local pressFlag = gui.click and gui.click[1] >= obj.posX and gui.click[2] >= obj.posY and gui.click[1] < (obj.posX + obj.sizeX) and gui.click[2] < (obj.posY + obj.sizeY)
                if obj.mode == 1 then --classic
                    if pressFlag then
                        if gui.click[3] == "pressed" then
                            obj.state = true
                            return true
                        end
                    end
                    if gui.click and (gui.click[3] == "released" or (not pressFlag and gui.click[3] == "pressed")) then
                        obj.state = false
                    end
                elseif obj.mode == 2 then --togle
                    if pressFlag and gui.click[3] == "pressed" then
                        obj.state = not obj.state
                        gui.draw()
                        return true
                    end
                    return not not obj.state
                elseif obj.mode == 3 then --пока жмеш тода и true
                    if pressFlag then
                        if gui.click[3] == "pressed" then
                            obj.state = true
                        end
                    end
                    if gui.click and gui.click[3] == "released" then
                        obj.state = false
                    end
                    return not not obj.state
                end
                return false
            end

            table.insert(scene.objects, obj)
            return obj
        end

        function scene.createDrawer(x, y, sx, sy, drawer)
            local obj = {}
            obj.posX = x
            obj.posY = y
            obj.sizeX = sx or 10
            obj.sizeY = sy or 10
            obj.drawer = drawer
            obj.type = "drawer"
            obj.scene = scene

            function obj.draw()
                obj.drawer(gui.screen, obj.posX, obj.posY, obj.sizeX, obj.sizeY)
            end
    
            table.insert(scene.objects, obj)
            return obj
        end

        function scene.createList(x, y, sx, sy, strs, color2, textcolor, panelcolor)
            local obj = {}
            obj.posX = x
            obj.posY = y
            obj.sizeX = sx or 40
            obj.sizeY = sy or 80
            obj.type = "list"
            obj.scene = scene

            obj.color = utils.formatColor(color2 or "e87272")
            obj.textcolor = utils.formatColor(textcolor or "72e88e")
            obj.panelcolor = utils.formatColor(panelcolor or "729ee8")

            obj.strs = strs
            obj.scroll = 0

            function obj.mathSize()
                return -(obj.charSizeY * #obj.strs), 0
            end

            function obj.draw()
                gui.screen.fillRect(
                    obj.posX,
                    obj.posY,
                    obj.sizeX,
                    obj.sizeY,
                    obj.color
                )
                gui.screen.fillRect(
                    obj.posX + (obj.sizeX - 10),
                    obj.posY,
                    10,
                    obj.sizeY,
                    obj.panelcolor
                )
                
                for i, v in ipairs(obj.strs) do
                    gui.screen.drawText(obj.posX + 1, obj.posY + 1 + obj.scroll + ((i - 1) * gui.charSizeY), v, obj.textcolor)
                end
            end

            function obj.getSelect()
                if not gui.click then return false end
                local pressFlag = gui.click[1] >= obj.posX and gui.click[1] < (obj.posX + obj.sizeX) and gui.click[2] >= gui.posY and gui.click[2] < (obj.posY + obj.sizeY)
                if gui.click[3] == "drag" then
                    if pressFlag then
                        
                    end
                end
                return false
            end
    
            table.insert(scene.objects, obj)
            return obj
        end

        table.insert(gui.scenes, scene)
        return scene
    end

    function gui.update()
        gui.screen.optimize()
        gui.screen.flush()
    end

    function gui.draw(noClear)
        gui.selected.draw(noClear)
        gui.update()
    end

    function gui.select(scene)
        gui.selected = scene
        gui.draw()
    end

    function gui.tick()
        gui.click = screen.getClick()
        for i, v in ipairs(gui.scenes) do
            for i, v in ipairs(v.objects) do
                if v.type == "button" then
                    if (gui.lockCount ~= 0 or gui.selected ~= v.scene) and v.mode ~= 2 then
                        v.state = false
                    end
                end
            end
        end
    end

    function gui.context(posX, posY, strs, active)
        local deactivete
        if #strs == 0 then
            deactivete = true
            table.insert(strs, "    ")
        end

        if not active then
            active = {}
            for i = 1, #strs do
                table.insert(active, true)
            end
        end

        local sizeX = 0
        local sizeY = (gui.charSizeY * #strs) + 2
        for i = 1, #strs do
            local size = (#strs[#strs] * (gui.charSizeX + 1))
            if size > sizeX then
                sizeX = size
            end
        end
        sizeX = sizeX + 15

        gui.lockCount = gui.lockCount + 1
        --print(gui.lockCount)

        return {
            draw = function()
                gui.screen.fillRect(posX + 3, posY + 3, sizeX, sizeY, utils.formatColor("666666"))
                gui.screen.fillRect(posX, posY, sizeX, sizeY, utils.formatColor("FFFFFF"))
                for i = 1, #strs do
                    gui.screen.drawText(posX + 10, posY + ((gui.charSizeY + 1) * (i - 1)) + 1, strs[i], active[i] and utils.formatColor("000000") or utils.formatColor("AAAAAA"))
                end
            end,
            getSelected = function()
                if not gui.click then return false end
                if gui.click[3] == "pressed" then
                    if gui.click[1] >= posX and gui.click[2] >= posY and gui.click[2] < (posY + sizeY) and gui.click[1] < (posX + sizeX) then
                        local index = math.floor((gui.click[2] - (posY + 1)) / gui.charSizeY) + 1
                        if index >= 1 and index <= #strs and active[index] then
                            gui.lockCount = gui.lockCount - 1
                            if not deactivete then
                                return index, strs[index]
                            end
                            return true
                        end
                    else
                        gui.lockCount = gui.lockCount - 1
                        return true
                    end
                end
                return false
            end
        }
    end

    function gui.splash(text, color)
        local strs = utils.toParts(text, math.floor(gui.sizeX / (gui.charSizeX + 1)))
        
        gui.screen.clear(utils.formatColor("000000"))
        for i, v in ipairs(strs) do
            gui.screen.drawText(0, (i - 1) * (gui.charSizeY - 1), v, utils.formatColor(color or "ffff00"))
        end
        gui.screen.optimize()
        gui.screen.flush()
    end

    function gui.yesno(text)
        return {
            draw = function()
                local size = 5
                if gui.sizeX >= 64 then
                    size = 10
                end
                if gui.sizeX >= 128 then
                    size = 20
                end

                gui.screen.fillRect(size, size * 2, gui.sizeX - (size * 2), gui.sizeY - (size * 4), utils.formatColor("d8d8d8"))
                gui.screen.drawText(size + 5, (size * 2) + 5, text, utils.formatColor("000000"))

                gui.screen.fillRect(gui.sizeX - size - 10, gui.sizeY - (size * 2) - 10, 10, 10, utils.formatColor("FF0000"))
                gui.screen.drawText((gui.sizeX - size - 10) + 2, (gui.sizeY - (size * 2) - 10) + 2, "N", utils.formatColor("FFFFFF"))

                gui.screen.fillRect(size, gui.sizeY - (size * 2) - 10, 10, 10, utils.formatColor("00FF00"))
                gui.screen.drawText(size + 2, (gui.sizeY - (size * 2) - 10) + 2, "Y", utils.formatColor("FFFFFF"))
            end,
            getSelected = function()
                if not gui.click then return false end
                if gui.click[3] == "pressed" then
                    local size = 5
                    if gui.sizeX >= 64 then
                        size = 10
                    end
                    if gui.sizeX >= 128 then
                        size = 20
                    end
                    
                    if gui.click[1] >= gui.sizeX - size - 10 and gui.click[2] >= gui.sizeY - (size * 2) - 10 then
                        if gui.click[1] < gui.sizeX - 10 and gui.click[2] < gui.sizeY - (size * 1) - 10 then
                            return 2
                        end
                    end

                    if gui.click[1] >= size and gui.click[2] >= gui.sizeY - (size * 2) - 10 then
                        if gui.click[1] < size * 2 and gui.click[2] < gui.sizeY - (size * 1) - 10 then
                            return 1
                        end
                    end
                end
                return false
            end
        }
    end

    return gui
end}