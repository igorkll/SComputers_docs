local _utf8 = utf8
local objinstance = {}

local function txtLen(display, text)
    return ((display.getFontWidth() + 1) * _utf8.len(text)) - 1
end

local function formatColor(color, black)
    return (sm.canvas.formatColorToNumber(color, black and 0 or 0xffffffff) - 255) / 256
end

local function getObjectWidth(obj)
    if obj.isText then
        return txtLen(obj.display, obj.text)
    elseif obj.isImage and self.img then
        return (self.img:getSize())
    elseif obj.sizeX then
        return obj.sizeX
    end
    return 0
end

local function getObjectHeight(obj)
    if obj.isText then
        return obj.display.getFontHeight()
    elseif obj.image and self.img then
        return select(2, self.img:getSize())
    elseif obj.sizeY then
        return obj.sizeY
    end
    return 0
end

local function remathElementInWindowPos(obj)
    obj.x = (obj.sceneinstance.x or 0) + obj.sourceX
    obj.y = (obj.sceneinstance.y or 0) + obj.sourceY
end

-------- main

function objinstance:setPosition(x, y)
    self.sourceX = x
    self.sourceY = y
    remathElementInWindowPos(self)
end

function objinstance:setOffsetPosition(gobj, x, y)
    self:setPosition(gobj.sourceX + x, gobj.sourceY + y)
end

function objinstance:setLeft(gobj, padding)
    padding = padding or 1
    self:setOffsetPosition(gobj, -getObjectWidth(self) - padding, 0)
end

function objinstance:setRight(gobj, padding)
    padding = padding or 1
    self:setOffsetPosition(gobj, getObjectWidth(gobj) + padding, 0)
end

function objinstance:setUp(gobj, padding)
    padding = padding or 1
    self:setOffsetPosition(gobj, 0, -getObjectHeight(self) - padding)
end

function objinstance:setDown(gobj, padding)
    padding = padding or 1
    self:setOffsetPosition(gobj, 0, getObjectHeight(gobj) + padding)
end

function objinstance:setCustomStyle(style)
    self.style = style
end

function objinstance:update()
    self.needUpdate = true
    if self.sceneinstance:isSelected() then
        self.guiinstance.needFlushFlag = true
    end
end

function objinstance:getLastInteractionType()
    return self.lastInteractionType
end

function objinstance:destroy()
    for index, obj in ipairs(self.sceneinstance.panelObjs or {}) do
        sc.yield()
        if obj == self then
            table.remove(self.sceneinstance.panelObjs, index)
            self.guiinstance.needFlushFlag = true
            self.sceneinstance.needUpdate = true
        end
    end
    for index, obj in ipairs(self.sceneinstance.objs) do
        sc.yield()
        if obj == self then
            table.remove(self.sceneinstance.objs, index)
            self.guiinstance.needFlushFlag = true
            self.sceneinstance.needUpdate = true
            return true
        end
    end
    return false
end

function objinstance:clear(color)
    if not self.sceneinstance:isSelected() then return end
    if not color and self.sceneinstance.color and type(self.sceneinstance.color) ~= "function" then
        color = self.sceneinstance.color
    end
    color = formatColor(color, true)

    if self.sizeX then
        self.display.fillRect(self.x, self.y, self.sizeX, self.sizeY, color)
    elseif self.text then
        self.display.fillRect(self.x, self.y, txtLen(self.disable, self.text), self.display.getFontHeight(), color)
    elseif self.img then
        local sx, sy = self.img:getSize()
        self.display.fillRect(self.x, self.y, sx, sy, color)
    end
end

function objinstance:setDisabled(state)
    self.disable = state
end

function objinstance:setInvisible(state)
    self.invisible = state
end

-------- window

function objinstance:upPanel(color, textcolor, title, collapsibility)
    if color then
        self.up_color = formatColor(color, true)
        self.up_textcolor = formatColor(textcolor, true)
        self.up_title = title or ""
        self.up_collapsibility = collapsibility
        self.up_hide = false
        self.up_size = self.display.getFontHeight() + 2
        self.panelObjs = {}
    else
        self.up_color = nil
        self.up_title = nil
        self.up_collapsibility = nil
        self.up_hide = nil
        self.up_size = nil
        if self.panelObjs then
            for i, v in ipairs(self.panelObjs) do
                v:destroy()
            end
            self.panelObjs = nil
        end
    end
end

function objinstance:panelButton(sizeX, ...)
    if self.panelObjs then
        local posX = self.panelObjs[#self.panelObjs]
        if posX then
            posX = posX.sourceX - sizeX
        else
            posX = self.sizeX - sizeX
        end
        local button = self:createButton(posX, 0, sizeX, self.up_size, ...)
        table.insert(self.panelObjs, button)
        return button
    end
end

function objinstance:minimize(state)
    if self.up_color then
        self.up_hide = state
    end
end

function objinstance:setDraggable(state)
    self.draggable = state
end

function objinstance:setColor(color)
    self.color = color
end

function objinstance:isSelected()
    return self.sceneinstance:isSelected()
end

-------- label / text

function objinstance:setText(text)
    if self.text ~= text then
        self.text = text
        self:update()
    end
end

function objinstance:setFgColor(color)
    if self.fg ~= color then
        self.fg = formatColor(color)
        self:update()
    end
end

function objinstance:setBgColor(color)
    if self.bg ~= color then
        self.bg = formatColor(color)
        self:update()
    end
end

function objinstance:setPfgColor(color)
    if self.fg_press ~= color then
        self.fg_press = formatColor(color)
        self:update()
    end
end

function objinstance:setPbgColor(color)
    if self.bg_press ~= color then
        self.bg_press = formatColor(color)
        self:update()
    end
end

-------- image

function objinstance:updateImage(img)
    self.img = img
    self:update()
end

-------- button

function objinstance:getState()
    return self.state
end

function objinstance:isPress()
    return self.state and not self.old_state
end

function objinstance:isReleased()
    return self.old_state and not self.state
end

function objinstance:setState(state)
    self.state = state
    self:update()
end

function objinstance:attachCallback(callback)
    self.callback = callback
end

-------- service

local function toUpperLevel(self)
    local pobjs = self.sceneinstance.objs
    if pobjs[#pobjs] ~= self then
        local selfIndex
        for i = 1, #pobjs do
            if pobjs[i] == self then
                selfIndex = i
                break
            end
        end
        if selfIndex then
            table.remove(pobjs, selfIndex)
            table.insert(pobjs, self)
        end
    end
end

local function _checkIntersection(x, y, object1, object2)
    return x < object2.math_x + object2.math_width or 
            x + object1.math_width > object2.math_x or 
            y < object2.math_y + object2.math_height or 
            y + object1.math_height > object2.math_y
end

local function windowPosCheck(self)
    if self.sceneinstance.isWindow then
        local maxX = self.sceneinstance.sizeX - self.sizeX
        if self.sourceX < 0 then
            self.sourceX = 0
        elseif self.sourceX >= maxX then
            self.sourceX = maxX
        end

        local minY = self.sceneinstance.up_size or 0
        local maxY = self.sceneinstance.sizeY
        if self.up_hide then
            maxY = maxY - self.up_size
        else
            maxY = maxY - self.sizeY
        end
        if self.sourceY < minY then
            self.sourceY = minY
        elseif self.sourceY >= maxY then
            self.sourceY = maxY
        end
    end

    self.x = self.sourceX + (self.sceneinstance.x or 0)
    self.y = self.sourceY + (self.sceneinstance.y or 0)

    local function recursionUpdate(objs)
        sc.yield()
        for _, obj in ipairs(objs) do
            sc.yield()
            obj:setPosition(obj.sourceX, obj.sourceY)
            if obj.isWindow then
                recursionUpdate(obj.objs)
            end
        end
    end
    recursionUpdate(self.objs)
end

function objinstance:_tick(click)
    if not self.sizeX or self.disable then
        return
    end

    if self.customHandler then
        if click == true and self.state then
            self:customHandler(-1, -1, "released", -1) --release the pressed items when switching the scene
            self.state = false
        end
    elseif self.button then
        if click == true and not self.toggle then
            self.state = false
            if self.callback then self:callback(false, false) end
        end
        self.old_state = self.state
    end
    if not click or click == true then return end

    local tx, ty = click[1], click[2]
    local lx, ly = tx - self.x, ty - self.y
    local selected = click[1] >= self.x and click[2] >= self.y and click[1] < (self.x + self.sizeX) and click[2] < (self.y + self.sizeY)
    local clktype = click[3]
    local btntype = click[4]

    self.lastInteractionType = btntype

    if self.customHandler then
        if selected or (self.state and clktype == "released") then
            self.state = clktype ~= "released"
            if self:customHandler(tx, ty, clktype, btntype) then
                self:update()
            end
        end
    elseif self.button then
        if self.toggle then
            if selected and clktype == "pressed" then
                self.state = not self.state
                if self.callback then self:callback(self.state, true) end
            end
        elseif selected and clktype == "pressed" then
            self.state = true
            if self.callback then self:callback(true, true) end
        elseif clktype == "released" and self.state then
            self.state = false
            if self.callback then self:callback(false, selected) end
        end

        if self.state ~= self.old_state then
            self:update()
        end
    elseif self.isWindow then
        local elementCapture = false
        if self.up_hide then
            if self.panelObjs then
                for i = #self.panelObjs, 1, -1 do
                    local obj = self.panelObjs[i]
                    sc.yield()
                    if obj:_tick(click) then
                        elementCapture = true
                        break
                    end
                end
            end
        else
            for i = #self.objs, 1, -1 do
                local obj = self.objs[i]
                sc.yield()
                if obj:_tick(click) then
                    elementCapture = true
                    break
                end
            end
        end

        if elementCapture and clktype == "pressed" then
            self.touchX = nil
            self.touchY = nil
            toUpperLevel(self)
            self.guiinstance.needFlushFlag = true
            self.sceneinstance.needUpdate = true
        elseif clktype == "pressed" then
            if selected then
                local upSel = ly < self.up_size
                if self.up_color and self.up_collapsibility and upSel and lx < self.display.getFontWidth() + 2 then
                    self.up_hide = not self.up_hide
                    windowPosCheck(self)
                    toUpperLevel(self)
                    self.guiinstance.needFlushFlag = true
                    self.sceneinstance.needUpdate = true
                    return true
                elseif not self.up_hide or upSel then
                    self.touchX = tx
                    self.touchY = ty
                    toUpperLevel(self)
                    self.guiinstance.needFlushFlag = true
                    self.sceneinstance.needUpdate = true
                    return true
                end
            end
        elseif clktype == "released" then
            self.touchX = nil
            self.touchY = nil
        elseif clktype == "drag" and self.touchX and self.draggable then
            self.guiinstance.needFlushFlag = true
            self.sceneinstance.needUpdate = true
            local dx = tx - self.touchX
            local dy = ty - self.touchY
            self.touchX = tx
            self.touchY = ty
            self.sourceX = self.sourceX + dx
            self.sourceY = self.sourceY + dy
            windowPosCheck(self)
            toUpperLevel(self)
            return true
        else
            self.touchX = nil
            self.touchY = nil
        end
    end

    if self.up_hide then
        return false
    end
    return selected
end

function objinstance:_draw(force)
    if self.invisible then return end
    if not force and not self.needUpdate then
        if self.isWindow then
            for _, obj in ipairs(self.objs) do
                sc.yield()
                obj:_draw()
            end
        end
        return
    end
    self.needUpdate = false

    if self.style then
        self:style()
    elseif self.button or self.label then
        local bg, fg = self.bg, self.fg
        if self.state then
            bg, fg = self.bg_press, self.fg_press
        end
        self.display.fillRect(self.x, self.y, self.sizeX, self.sizeY, bg)

        local x = math.floor(((self.x + (self.sizeX / 2)) - (((self.display.getFontWidth() + 1) * _utf8.len(self.text)) / 2)) + 0.5)
        local y = math.floor(((self.y + (self.sizeY / 2)) - (self.display.getFontHeight() / 2)) + 0.5)
        self.display.drawText(x, y, self.text, fg)
    elseif self.isText then
        self.display.drawText(self.x, self.y, self.text, self.fg)
    elseif self.isImage then
        self.img:draw(self.display, self.x, self.y, self.sceneinstance.guiinstance.gamelight)
    elseif self.isWindow then
        if not self.up_hide then
            if type(self.color) == "function" then
                self:color()
            elseif self.color then
                self.display.fillRect(self.x, self.y, self.sizeX, self.sizeY, self.color)
            end
        end
        if self.up_color then
            self.display.fillRect(self.x, self.y, self.sizeX, self.up_size, self.up_color)
            if self.up_collapsibility then
                local fontX = self.display.getFontHeight()
                self.display.drawText(self.x + 1, self.y + 1, (self.up_hide and "\5" or "\6") .. self.up_title, self.up_textcolor)
            else
                self.display.drawText(self.x + 1, self.y + 1, self.up_title, self.up_textcolor)
            end
        end
        if self.up_hide then
            for _, obj in ipairs(self.objs) do
                sc.yield()
                if obj.sourceY < self.up_size then
                    obj:_draw(true)
                end
            end
        else
            for _, obj in ipairs(self.objs) do
                sc.yield()
                obj:_draw(not not self.color)
            end
        end
    end
end

-----------------------------------scene instance

local sceneinstance = {}

function sceneinstance:update()
    self.needUpdate = true
    if self:isSelected() then
        self.guiinstance.needFlushFlag = true
    end
end

function sceneinstance:_tick(clean)
    local click = true
    if not clean then
        click = self.display.getClick()
    end
    for i = #self.objs, 1, -1 do
        local obj = self.objs[i]
        sc.yield()
        if obj:_tick(click) and click ~= true then
            if not click or click[3] ~= "released" then
                break
            end
        end
    end
    if click ~= true then
        return click
    end
end

function sceneinstance:_draw(force)
    if self.needUpdate or force then
        if self.color then
            if type(self.color) == "function" then
                self:color()
            else
                self.display.clear(self.color)
            end
        end
        self.needUpdate = false
        force = true
    end
    for _, obj in ipairs(self.objs) do
        sc.yield()
        obj:_draw(force)
    end
end

function sceneinstance:select()
    if self.guiinstance.scene then
        self.guiinstance.scene:_tick(true) --чтобы сбросить все кнопки(не переключатели)
    end
    self.guiinstance.scene = self

    self:update()
end

function sceneinstance:isSelected()
    return self == self.guiinstance.scene
end

local function initObject(self, obj)
    obj.guiinstance = self.guiinstance
    obj.sceneinstance = self
    obj.onWindow = self.isWindow
    obj.display = self.display
    obj._tick = objinstance._tick
    obj._draw = objinstance._draw
    obj.destroy = objinstance.destroy
    obj.getLastInteractionType = objinstance.getLastInteractionType
    obj.update = objinstance.update
    obj.clear = objinstance.clear
    obj.setCustomStyle = objinstance.setCustomStyle
    obj.setInvisible = objinstance.setInvisible
    obj.setDisabled = objinstance.setDisabled

    obj.guiinstance.needFlushFlag = true
    obj.sceneinstance.needUpdate = true

    obj.setPosition = objinstance.setPosition
    obj.setOffsetPosition = objinstance.setOffsetPosition
    obj.setLeft = objinstance.setLeft
    obj.setRight = objinstance.setRight
    obj.setUp = objinstance.setUp
    obj.setDown = objinstance.setDown

    -- pos math
    obj.x = obj.x or 1
    obj.y = obj.y or ((self.up_size or 0) + 1)
    obj.sourceX = obj.x
    obj.sourceY = obj.y
    remathElementInWindowPos(obj)
end

function sceneinstance:createWindow(x, y, sizeX, sizeY, color)
    local obj = {
        x = x,
        y = y,
        sizeX = sizeX,
        sizeY = sizeY,
        color = color,
        disable = false,
        invisible = false,
        draggable = false,
        objs = {},

        createButton = sceneinstance.createButton,
        createImage = sceneinstance.createImage,
        createText = sceneinstance.createText,
        createLabel = sceneinstance.createLabel,
        createCustom = sceneinstance.createCustom,
        createWindow = sceneinstance.createWindow,

        setDraggable = objinstance.setDraggable,
        setColor = objinstance.setColor,
        isSelected = objinstance.isSelected,
        upPanel = objinstance.upPanel,
        panelButton = objinstance.panelButton,
        minimize = objinstance.minimize,

        isWindow = true
    }
    initObject(self, obj)
    table.insert(self.objs, obj)
    return obj
end

function sceneinstance:createCustom(x, y, sizeX, sizeY, cls, ...)
    local obj = {
        x = x,
        y = y,
        sizeX = sizeX,
        sizeY = sizeY,
        disable = false,
        invisible = false,
        state = false,
        args = {...},
        style = cls.drawer,
        customHandler = cls.handler
    }
    initObject(self, obj)
    if cls.methods then
        for k, v in pairs(cls.methods) do
            obj[k] = v
        end
    end
    if cls.init then
        cls.init(obj, ...)
    end
    table.insert(self.objs, obj)
    return obj
end

function sceneinstance:createButton(x, y, sizeX, sizeY, toggle, text, bg, fg, bg_press, fg_press)
    text = text or ""
    bg = formatColor(bg)
    fg = formatColor(fg, true)
    if bg_press then
        bg_press = formatColor(bg_press)
    else
        bg_press = fg
    end
    if fg_press then
        fg_press = formatColor(fg_press, true)
    else
        fg_press = bg
    end

    local obj = {
        x = x,
        y = y,
        sizeX = sizeX,
        sizeY = sizeY,
        toggle = toggle,
        text = text,
        bg = bg,
        fg = fg,
        bg_press = bg_press,
        fg_press = fg_press,
        disable = false,
        invisible = false,

        getState = objinstance.getState,
        setState = objinstance.setState,
        isPress = objinstance.isPress,
        isReleased = objinstance.isReleased,
        attachCallback = objinstance.attachCallback,

        setText = objinstance.setText,
        setBgColor = objinstance.setBgColor,
        setFgColor = objinstance.setFgColor,
        setPbgColor = objinstance.setPbgColor,
        setPfgColor = objinstance.setPfgColor,

        state = false,
        button = true
    }
    initObject(self, obj)
    table.insert(self.objs, obj)
    return obj
end

function sceneinstance:createImage(x, y, img)
    local obj = {
        x = x,
        y = y,
        img = img,

        updateImage = objinstance.updateImage,

        isImage = true
    }
    initObject(self, obj)
    table.insert(self.objs, obj)
    return obj
end

function sceneinstance:createLabel(x, y, sizeX, sizeY, text, bg, fg)
    text = text or ""
    bg = formatColor(bg)
    fg = formatColor(fg, true)

    local obj = {
        x = x,
        y = y,
        sizeX = sizeX,
        sizeY = sizeY,
        text = text,
        bg = bg,
        fg = fg,

        setText = objinstance.setText,
        setBgColor = objinstance.setBgColor,
        setFgColor = objinstance.setFgColor,

        label = true
    }
    initObject(self, obj)
    table.insert(self.objs, obj)
    return obj
end

function sceneinstance:createText(x, y, text, fg)
    text = text or ""
    fg = formatColor(fg)

    local obj = {
        x = x,
        y = y,
        text = text,
        fg = fg,

        setText = objinstance.setText,
        setFgColor = objinstance.setFgColor,

        isText = true
    }
    initObject(self, obj)
    table.insert(self.objs, obj)
    return obj
end

-----------------------------------gui instance

local guiinstance = {}

function guiinstance:tick()
    if self.scene then
        return self.scene:_tick()
    end
end

function guiinstance:draw()
    if self.scene then
        self.scene:_draw()
    end
end

function guiinstance:drawForce()
    if self.scene then
        self.scene:_draw(true)
    end
end

function guiinstance:setGameLight(number)
    self.gamelight = constrain(number, 0, 1)
end

function guiinstance:getGameLight()
    return self.gamelight
end

function guiinstance:needFlush()
    local needFlushFlag = self.needFlushFlag
    self.needFlushFlag = false
    return needFlushFlag
end

function guiinstance:createScene(color)
    if color and type(color) ~= "function" then
        color = sc.formatColor(color)
    end

    local scene = {
        guiinstance = self,
        display = self.display,
        color = color,
        objs = {},

        createButton = sceneinstance.createButton,
        createImage = sceneinstance.createImage,
        createText = sceneinstance.createText,
        createLabel = sceneinstance.createLabel,
        createCustom = sceneinstance.createCustom,
        createWindow = sceneinstance.createWindow,

        select = sceneinstance.select,
        isSelected = sceneinstance.isSelected,
        update = sceneinstance.update,

        _tick = sceneinstance._tick,
        _draw = sceneinstance._draw
    }

    if not self.scene then
        scene:select()
    end

    return scene
end

-----------------------------------gui

local gui = {}

function gui.new(display)
    return {
        display = display,
        gamelight = 1,
        needFlushFlag = false,

        tick = guiinstance.tick,
        draw = guiinstance.draw,
        drawForce = guiinstance.drawForce,
        createScene = guiinstance.createScene,
        setGameLight = guiinstance.setGameLight,
        getGameLight = guiinstance.getGameLight,
        needFlush = guiinstance.needFlush
    }
end

-----------------------------------

sc.reg_internal_lib("gui", gui)
return gui