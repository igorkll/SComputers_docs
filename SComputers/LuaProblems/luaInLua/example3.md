---
sidebar_position: 3
title: example3
hide_title: true
sidebar-label: 'example3'
---

this example shows how lua-in-lua does not handle "..." correctly

```lua
print(pcall(loadstring([[local asd = ...]])) and "normal lua" or "lua-in-lua")
```