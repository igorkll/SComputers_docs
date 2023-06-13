---
sidebar_position: 5
title: gui
hide_title: true
sidebar-label: 'gui'
---

![gui demo](/img/gui_demo.png)

### gui library
* gui.new(display:table):guiinstance - create a new gui instance

### gui instance
* guiinstance:tick() - processing clicks, etc
* guiinstance:draw() - draw a current scene, redrawing is optional only if necessary
* guiinstance:drawForce() - draw a current scene, redrawing always happens
* guiinstance:createScene(autoclearcolor:smcolor):sceneinstance - create a new scene, you can transfer the color so that when you select a scene, the screen is cleared automatically
* guiinstance:setGameLight(gamelight:number(0-1)) - sets the game lighting for the gui (it only applies to elements that do not transmit color manually(at the moment, only with pictures))
* guiinstance:getGameLight():number(0-1) - gets the game lighting for the gui
* guiinstance:needFlush():boolean - returns true if at least one element has been updated, if you make updates only when necessary, then you should turn off framecheck

### scene instance
* sceneinstance:isSelected():boolean - returns true if this scene is selected
* sceneinstance:select() - select a current scene
* sceneinstance:createButton(x, y, sizeX, sizeY, toggle, text, bg:smcolor, fg:smcolor, bg_press:smcolor, fg_press:smcolor):gbutton - create a new button
* sceneinstance:createLabel(x, y, sizeX, sizeY, text, bg:smcolor, fg:smcolor):glabel - create a new label
the label looks like a button
* sceneinstance:createImage(x, y, img):gimage - creates a picture, the size is set by the size of the picture
* sceneinstance:createText(x, y, text, color):gtext - creates text


### any object
* gobj:destroy():boolean - removes an object from the list
* gobj:getLastInteractionType():number or nil - returns the type of the last interaction(1-E 2-U)
* gobj:update() - forced redrawing of the object will occur at the next gui.draw call
* gobj:clear(smcolor) - clears the place where the object is located with the selected color, if the color is not passed, the color of the scene will be used (if there is one)
* gobj:setCustomStyle(function(gobj) ) - sets the function that will be used to draw the object

### object button
* gbutton:setState(boolean) - sets the button state, use for buttons in toggle mode
* gbutton:getState():boolean - for normal buttons, it returns true if the button is held down. for toggle mode, it will return the button states
* gbutton:isPress():boolean - returns true when the button is press (values are output for 1 tick)
* gbutton:isReleased():boolean - returns true when the button is released (values are output for 1 tick)
* gbutton:setText(text)
* gbutton:setFgColor(smcolor)
* gbutton:setBgColor(smcolor)
* gbutton:setPfgColor(smcolor) - sets fg when pressed
* gbutton:setPbgColor(smcolor) - sets bg when pressed

### object image
* gimage:updateImage(img) - sets a new image object to draw. however, you can change the old one and call gimage:update

### object text
* gtext:setText(text)
* gtext:setFgColor(smcolor)

### object label
* glabel:setText(text)
* glabel:setFgColor(smcolor)
* glabel:setBgColor(smcolor)



### gui example
```lua
display = getComponents("display")[1]
camera = getComponents("camera")[1]
display.reset()
display.clearClicks()
display.setSkipAtLags(false)
display.setClicksAllowed(true)
display.setFrameCheck(false) --display.flush is called only when necessary, it makes no sense to check the frame on the side of the screen

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
        display.flush()
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
```