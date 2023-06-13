---
sidebar_position: 1
title: example1
hide_title: true
sidebar-label: 'example1'
---

here you can see how the priority of variables is incorrectly implemented in lua-in-lua

```lua
if not start then
    anyvar = true
    function a(anyvar)
        return anyvar and ("lua-in-lua") or ("normal lua")
    end

    start = true
end
print(a())
```