---
sidebar_position: 11
title: vdisplay
hide_title: true
sidebar-label: 'vdisplay'
---

The vdisplay library allows you to create a virtual display that will have an API identical to a regular SComputers display
vdisplay implements type and range checks
if you want to process clicks (from any of your sources), you must replace the getClick method in the virtual display with your own
please note that performance when using "vdisplay" performance may be lower, because there are fewer optimizations in it

### methods that are stubs (setters and getters will accept and give the set values, and when reset is called, they will be reset, but these methods are still "dummy"):
* isAllow - the virtual display can have any resolution, regardless of the maximum available on the server
* getClick / setMaxClicks / getMaxClicks / clearClicks / setClicksAllowed / getClicksAllowed - the virtual display does not have a touchscreen
* setRenderAtDistance / getRenderAtDistance / setSkipAtLags / getSkipAtLags / setSkipAtNotSight / getSkipAtNotSight - all these methods require a physical display
* optimize

### library methods
* vdisplay.create(callbacks:table, rx:number, ry:number):dsp - creates a virtual display

# all callbacks (they all need to be implemented)
* clear:function(self, color) - called when cleaning
* set:function(self, x, y, color) - called when setting pixels by any methods(including text)
* flush:function(self, isForce) - called when calling "flush" / "forceFlush" / "update"

### display object methods
* setRotation / getRotation
* setUtf8Support / getUtf8Support
* setFont / getFontWidth / getFontHeight
* flush / update / forceFlush - all these methods do exactly the same thing in the context of a virtual display

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