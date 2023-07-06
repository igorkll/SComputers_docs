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

### ibridge component
* type - ibridge
* ibridge.isAllow():boolean - returns true if the use of the component is allowed and DLM is installed
* ibridge.get(url, headers) - sends a get request and returns the result
* ibridge.post(url, data, headers) - sends a post request and returns the result

#### example
```lua
function callback_loop() end

image = require("image")

ibridge = getComponents("ibridge")[1]
display = getComponents("display")[1]

if not ibridge.isAllow() then
    display.clear()
    display.drawText(1, 1, "bridge error")
    display.forceFlush()
    return
end

url = "http://1logic.ru/rom/test.bmp"
response = ibridge.get(url, {})

img = image.decodeBmp(response[2])
img:draw(display)
```