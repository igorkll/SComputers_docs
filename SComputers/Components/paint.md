---
sidebar_position: 14
title: paint
hide_title: true
sidebar-label: 'paint'
---

## paint component
* type - paint
* paint.shot(color) - shoots a paintball of the desired color, this ball can be paint: shape / robot / tree

## example
```lua
local colors = require("colors")

function callback_loop()
    getComponents("paint")[1].shot(sm.color.new(colors.hsvToRgb((getUptime() % 160) / 160, 1, 1)))
end
```