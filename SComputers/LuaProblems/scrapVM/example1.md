---
sidebar_position: 1
title: example1
hide_title: true
sidebar-label: 'example1'
---

this example shows how scrapVM does not handle ... correctly
all arguments get there, although only those after a, b should

```lua
function test(a, b, ...)
    local tbl = {...}
    print(#tbl == 3 and "normal lua" or "scrapVM")
end

test(1, 2, 3, 4, 5)
```