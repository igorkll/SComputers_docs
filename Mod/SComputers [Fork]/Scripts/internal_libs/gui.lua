local _utf8 = utf8
local objinstance = {}

-------- main

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
    for index, obj in ipairs(self.objs) do
        sc.yield()
        if obj == self then
            table.remove(self.sceneinstance.objs, index)
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
    color = sc.formatColorStr(color, true)

    if self.sizeX then
        self.display.fillRect(self.x, self.y, self.sizeX, self.sizeY, color)
    elseif self.text then
        self.display.fillRect(self.x, self.y, ((self.display.getFontWidth() + 1) * _utf8.len(self.text)) - 1, self.display.getFontHeight(), color)
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

-------- label / text

function objinstance:setText(text)
    if self.text ~= text then
        self.text = text
        self:update()
    end
end

function objinstance:setFgColor(color)
    if self.fg ~= color then
        self.fg = sc.formatColorStr(color)
        self:update()
    end
end

function objinstance:setBgColor(color)
    if self.bg ~= color then
        self.bg = sc.formatColorStr(color)
        self:update()
    end
end

function objinstance:setPfgColor(color)
    if self.fg_press ~= color then
        self.fg_press = sc.formatColorStr(color)
        self:update()
    end
end

function objinstance:setPbgColor(color)
    if self.bg_press ~= color then
        self.bg_press = sc.formatColorStr(color)
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

-------- service

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
        end
        self.old_state = self.state
    end
    if not click or click == true then return end

    local tx, ty = click[1], click[2]
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
            end
        else
            if clktype == "released" then
                self.state = false
            end
            if selected and clktype == "pressed" then
                self.state = true
            end
        end

        if self.state ~= self.old_state then
            self:update()
        end
    end
end

function objinstance:_draw(force)
    if self.invisible then return end
    if not force and not self.needUpdate then return end
    self.needUpdate = false

    if self.style then
        self:style()
    else
        if self.button or self.label then
            local bg, fg = self.bg, self.fg
            if self.state then
                bg, fg = self.bg_press, self.fg_press
            end
            self.display.fillRect(self.x, self.y, self.sizeX, self.sizeY, bg)
    
            local x = math.floor(((self.x + (self.sizeX / 2)) - (((self.display.getFontWidth() + 1) * _utf8.len(self.text)) / 2)) + 0.5)
            local y = math.floor(((self.y + (self.sizeY / 2)) - (self.display.getFontHeight() / 2)) + 0.5)
            self.display.drawText(x, y, self.text, fg)
        elseif self.istext then
            self.display.drawText(self.x, self.y, self.text, self.fg)
        elseif self.image then
            self.img:draw(self.display, self.x, self.y, self.sceneinstance.guiinstance.gamelight)
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
    for _, obj in ipairs(self.objs) do
        sc.yield()
        obj:_tick(click)
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

local function attachMethods(self, obj)
    obj.guiinstance = self.guiinstance
    obj.sceneinstance = self
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
    attachMethods(self, obj)
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
    bg = sc.formatColorStr(bg)
    fg = sc.formatColorStr(fg, true)
    bg_press = bg_press or fg
    fg_press = fg_press or bg

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

        setText = objinstance.setText,
        setBgColor = objinstance.setBgColor,
        setFgColor = objinstance.setFgColor,
        setPbgColor = objinstance.setPbgColor,
        setPfgColor = objinstance.setPfgColor,

        state = false,
        button = true
    }
    attachMethods(self, obj)
    table.insert(self.objs, obj)
    return obj
end

function sceneinstance:createImage(x, y, img)
    local obj = {
        x = x,
        y = y,
        img = img,

        updateImage = objinstance.updateImage,

        image = true
    }
    attachMethods(self, obj)
    table.insert(self.objs, obj)
    return obj
end

function sceneinstance:createLabel(x, y, sizeX, sizeY, text, bg, fg)
    text = text or ""
    bg = sc.formatColorStr(bg)
    fg = sc.formatColorStr(fg, true)

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
    attachMethods(self, obj)
    table.insert(self.objs, obj)
    return obj
end

function sceneinstance:createText(x, y, text, fg)
    text = text or ""
    fg = sc.formatColorStr(fg)

    local obj = {
        x = x,
        y = y,
        text = text,
        fg = fg,

        setText = objinstance.setText,
        setFgColor = objinstance.setFgColor,

        istext = true
    }
    attachMethods(self, obj)
    table.insert(self.objs, obj)
    return obj
end

-----------------------------------gui instance

local guiinstance = {}

function guiinstance:tick()
    if self.scene then
        self.scene:_tick()
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