---
sidebar_position: 10
title: radarDetector
hide_title: true
sidebar-label: 'radarDetector'
---

### radarDetector component
* type - radarDetector
* radarDetector.getRadars():table{vec3, vec3, ...} - returns a table with direction vectors up to the radars that see your creation(body). all vectors in the local coordinate system are relative to the radarDetector

### example
```lua
local display = getComponents("display")[1]
local radarDetector = getComponents("radarDetector")[1]

local rx, ry = display.getWidth(), display.getHeight()

function callback_loop()
    if _endtick then
        display.clear()
        display.flush()
        return
    end

    display.clear()
    display.fillCircle(rx / 2, ry / 2, rx / 2,       "22ee22")
    display.fillCircle(rx / 2, ry / 2, (rx / 2) - 1, "002200")

    for _, vec in ipairs(radarDetector.getRadars()) do
        display.drawLine(rx / 2, ry / 2, (rx / 2) - (vec.y * (rx / 3)), (ry / 2) + (vec.x * (ry / 3)), "ff0000")
    end

    display.flush()
end
```