---
sidebar_position: 7
title: colors
hide_title: true
sidebar-label: 'colors'
---

### painttool colors consts
#### consts names
* colors.names = {"Gray", "Yellow", "LimeGreen", "Green", "Cyan", "Blue", "Violet", "Magenta", "Red", "Orange"}

#### number consts
* colors.num.Gray	    = {0xEEEEEE, 0x7F7F7F, 0x4A4A4A, 0x222222}
* colors.num.Yellow     = {0xF5F071, 0xE2DB13, 0x817C00, 0x323000}
* colors.num.LimeGreen  = {0xCBF66F, 0xA0EA00, 0x577D07, 0x375000}
* colors.num.Green	    = {0x68FF88, 0x19E753, 0x0E8031, 0x064023}
* colors.num.Cyan       = {0x7EEDED, 0x2CE6E6, 0x118787, 0x0A4444}
* colors.num.Blue       = {0x4C6FE3, 0x0A3EE2, 0x0F2E91, 0x0A1D5A}
* colors.num.Violet     = {0xAE79F0, 0x7514ED, 0x500AA6, 0x35086C}
* colors.num.Magenta    = {0xEE7BF0, 0xCF11D2, 0x720A74, 0x520653}
* colors.num.Red        = {0xF06767, 0xD02525, 0x7C0000, 0x560202}
* colors.num.Orange     = {0xEEAF5C, 0xDF7F00, 0x673B00, 0x472800}

#### string consts
* colors.str.Gray	    = {"EEEEEE", "7F7F7F", "4A4A4A", "222222"}
* colors.str.Yellow     = {"F5F071", "E2DB13", "817C00", "323000"}
* colors.str.LimeGreen  = {"CBF66F", "A0EA00", "577D07", "375000"}
* colors.str.Green	    = {"68FF88", "19E753", "0E8031", "064023"}
* colors.str.Cyan       = {"7EEDED", "2CE6E6", "118787", "0A4444"}
* colors.str.Blue       = {"4C6FE3", "0A3EE2", "0F2E91", "0A1D5A"}
* colors.str.Violet     = {"AE79F0", "7514ED", "500AA6", "35086C"}
* colors.str.Magenta    = {"EE7BF0", "CF11D2", "720A74", "520653"}
* colors.str.Red        = {"F06767", "D02525", "7C0000", "560202"}
* colors.str.Orange     = {"EEAF5C", "DF7F00", "673B00", "472800"}

#### smcolor consts
* colors.sm.Gray	    = {smcolor, smcolor, smcolor, smcolor}
* colors.sm.Yellow      = {smcolor, smcolor, smcolor, smcolor}
* colors.sm.LimeGreen   = {smcolor, smcolor, smcolor, smcolor}
* colors.sm.Green	    = {smcolor, smcolor, smcolor, smcolor}
* colors.sm.Cyan        = {smcolor, smcolor, smcolor, smcolor}
* colors.sm.Blue        = {smcolor, smcolor, smcolor, smcolor}
* colors.sm.Violet      = {smcolor, smcolor, smcolor, smcolor}
* colors.sm.Magenta     = {smcolor, smcolor, smcolor, smcolor}
* colors.sm.Red         = {smcolor, smcolor, smcolor, smcolor}
* colors.sm.Orange      = {smcolor, smcolor, smcolor, smcolor}
  
#### methods
* colors.hsvToRgb(h, s, v):r,g,b - all arguments have a range from 0 to 1, the output values also have a range from 0 to 1

#### example
```lua
colors = require("colors")
display = getComponents("display")[1]

display.clear(colors.str.Red[2]) --fill the screen with red painttool
display.flush()

function callback_loop()
    if _endtick then
        display.clear()
        display.flush()
    end
end
```

#### example 2
```lua
colors = require("colors")
display = getComponents("display")[1]

tick = 0
function callback_loop()
    if _endtick then
        display.clear()
        display.flush()
        return
    end

    display.clear(tostring(sm.color.new(colors.hsvToRgb((tick % 120) / 120, 1, 1))))
    display.flush()

    tick = tick + 1
end
```