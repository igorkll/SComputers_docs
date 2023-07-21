---
sidebar_position: 8
title: ibridge
hide_title: true
sidebar-label: 'ibridge'
---

allows you to send get/post requests to the real internet!!
DLM is required to work.
it weighs a lot and is very expensive to craft
I cannot be completely sure of the security of this component,
it is recommended to disable it in the "Permission Tool" on public servers
it is also not necessary to send requests often, as this causes a noticeable lag
please note that for some reason unknown to me, DLM may refuse to accept a response from a server without https

### ibridge component
* type - ibridge
* ibridge.isAllow():boolean - returns true if the use of the component is allowed and DLM is installed
* ibridge.get(url, headers) - sends a get request and returns the result
* ibridge.post(url, data, headers) - sends a post request and returns the result

#### example
```lua
image = require("image")

ibridge = getComponents("ibridge")[1]
display = getComponents("display")[1]
display.reset()

if not ibridge.isAllow() then
    display.clear()
    display.drawText(1, 1, "bridge")
    display.drawText(1, 9, "error")
    display.forceFlush()
    return
end

response = ibridge.get("https://raw.githubusercontent.com/igorkll/SComputers_docs/main/ROM/test.bmp", {})
img = image.decodeBmp(response[2])
display.clear()
img:draw(display)
display.forceFlush()

function callback_loop()
    if _endtick then
        display.clear()
        display.forceFlush()
    end
end
```