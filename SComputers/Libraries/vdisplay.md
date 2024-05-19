---
sidebar_position: 11
title: vdisplay
hide_title: true
sidebar-label: 'vdisplay'
---

the "vdisplay" library allows you to create a virtual display with an API identical to a regular display.
this display does not respond to resolution limitations in the mod configuration, as it is purely software-based.

### library methods
* vdisplay.create(callbacks:table, rx:number, ry:number):dsp - creates a virtual display

# callbacks (for the exchange of callbacks, a table is used that you pass when creating a virtual display)
* you are implementing: set:function(self, x, y, color) - called when the color of the display pixel changes(by default, all display pixels are black)
* you are implementing: flush:function(self, isForce) - called when calling "flush" / "forceFlush" / "update"
* the library implements: pushClick:function(tbl) - registers clicks on the screen, this table will be returned unchanged by the "getClick" method
* the library implements: updateAudience:function(count) - updates the number of the display audience. if the number is 0, then the display may stop updating in some cases(the default is 1)

```lua
--makes a holographic display from a holographic projector (in fact, you'd better use a separate part of the holographic display for this)
local vdisplay = require("vdisplay")
local holo = getComponents("holoprojector")[1]
holo.reset()
holo.clear()
holo.flush()

local width, height = 32, 32
local idBuffer = {}

local callbacks = {
    set = function (self, x, y, color)
        local index = x + (y * width)
        if idBuffer[index] then holo.delVoxel(idBuffer[index]) end
        idBuffer[index] = holo.addVoxel(x - (width / 2), (((height - 1) - y) - (height / 2)) + 20, 0, color, 2)
    end,
    flush = function (self, isForce)
        holo.flush()
    end
}
setComponentApi("display", vdisplay.create(callbacks, width, height)) --this line will cause your computer to be identified by other computers as a display

function callback_loop()
    if _endtick then
        holo.reset()
        holo.clear()
        holo.flush()
    end

    --[[ an example of simulated clicks
    callbacks.pushClick({0, 0, "pressed", 1})
    callbacks.pushClick({0, 0, "released", 1})
    ]]

    --[[ if you know that someone is not looking at your screen now, then it is better to inform the library about it
    if mySecretSource_thereIsNoOneAround then
        callbacks.updateAudience(0)
    else
        callbacks.updateAudience(1)
    end
    ]]
end
```