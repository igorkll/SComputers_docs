---
sidebar_position: 3
title: example3
hide_title: true
sidebar-label: 'example3'
---

ATTENTION: this bug has been fixed, and is not contained in the remade version of luaInLua in SComputers
this example shows how lua-in-lua does not handle "..." correctly

```lua
print(pcall(loadstring([[local asd = ...]])) and "normal lua" or "lua-in-lua")
```