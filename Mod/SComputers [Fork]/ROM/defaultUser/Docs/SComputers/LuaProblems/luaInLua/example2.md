---
sidebar_position: 2
title: example2
hide_title: true
sidebar-label: 'example2'
---

ATTENTION: this bug has been fixed, and is not contained in the remade version of luaInLua in SComputers
here we see how lua-in-lua incorrectly handles closures (unloads local variables ahead of time)

```lua
if not start then
    local anyVar = true
    function a()
        return anyVar and ("normal lua") or ("lua-in-lua")
    end

    start = true
end
print(a())
```