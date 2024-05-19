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

# all callbacks
* you are implementing: set:function(self, x, y, color) - called when the color of the display pixel changes(by default, all display pixels are black)
* you are implementing: flush:function(self, isForce) - called when calling "flush" / "forceFlush" / "update"
* the library implements: pushClick:function(tbl) - registers clicks on the screen, this table will be returned unchanged by the "getClick" method
* the library implements: updateAudience:function(count) - updates the number of the display audience. if the number is 0, then the display may stop updating in some cases

```lua
--makes a holographic display
vdisplay = require("vdisplay")
holo = getComponents("holoprojector")[1]
holo.reset()
holo.clear()
holo.flush()

width, height = 32, 32

function clear(color)
    lastClearColor = color or "000000"
    buffer = {}
end
function set(x, y, color)
    holo.addVoxel(x - (width / 2), (((height - 1) - y) - (height / 2)) + 20, 0, color, 2)
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
```