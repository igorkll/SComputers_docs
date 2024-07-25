---
sidebar_position: 16
title: checkArg
hide_title: true
sidebar-label: 'checkArg'
---

checkArg(argnum, arg, ...) - checks the correctness of the arguments

#### usage
```lua
function test(num)
    checkArg(1, num, "number", "nil")
    if num ~= nil then
        return num + 1
    end
    return true
end
test(1)    --ok
test(4)    --ok
test(-111) --ok
test(nil)  --ok
test("a")  --error: 

function callback_loop() end
```