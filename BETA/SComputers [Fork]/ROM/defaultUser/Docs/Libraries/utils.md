---
sidebar_position: 10
title: utils
hide_title: true
sidebar-label: 'utils'
---

#### methods
* utils.clamp(value, min, max):number - limits the range of the number(support float)
* utils.map(value, low, high, low2, high2) - changes the range of the number
* utils.roundTo(number, numbers(default 3)) - rounds the number to a certain number of digits after "."
* utils.split(tool(utf8/string), string, separators):tbl - separates a string, separators can consist of several characters and you can specify several pieces, also, if the separator is at the beginning/end, it will separate the string from the void
* utils.splitByMaxSize(str, maxsize):tbl - divides string into segments, and you can specify the maximum length of the segment, the last segment can be smaller than the specified size, but not one can be larger
* utils.splitByMaxSizeWithTool(tool(utf8/string), str, maxsize):tbl - divides string into segments, and you can specify the maximum length of the segment, the last segment can be smaller than the specified size, but not one can be larger
* utils.deepcopy(tbl):tbl - clones a table, understands nesting and types such as Color, Vec3, Quat
* utils.md5(data):md5sum - calculates the md5 amount, please note that this is a complex operation and can cause lags(returns a text md5)
* utils.md5bin(data):md5sum - returns md5 in binary format
* utils.dist(pos1:vec3, pos2:vec3):number - calculates the distance between two points in three-dimensional space
* utils.fromEuler(euler:vec3):quat - custom implementation because the implementation of scrap mechanic does not always work correctly
* utils.toEuler(quat:quat):vec3 - converts a quaternion to euler

##### utils.split example
```lua
local utils = require("utils")
local seps = utils.split(string, ".1:2:3:4::5:6:7:8.9:8:7:6::", {"::", "."})
print("(" .. table.concat(seps, "        ") .. ")") --(        1:2:3:4        5:6:7:8        9:8:7:6        ) 
function callback_loop() end
```

##### utils.roundTo example
```lua
local utils = require("utils")
print(utils.roundTo(1.245678)) -- 1.245
function callback_loop() end
```

##### utils.splitByMaxSize example
```lua
local utils = require("utils")
for k, v in pairs(utils.splitByMaxSize("12345", 2)) do --{"12", "34", "5"}
    print(k, v) 
end
function callback_loop() end
```

##### utils.splitByMaxSizeWithTool example
```lua
local utils = require("utils")
for k, v in pairs(utils.splitByMaxSizeWithTool(utf8, "anyUtf8String", 2)) do --{"an", "yU", "tf", "8S", "tr", "in", "g"}
    print(k, v) 
end
function callback_loop() end
```

##### utils.deepcopy example
```lua
local utils = require("utils")

local tbl = {a = 1, b = 2, c = 3}
tbl.d = tbl

for k, v in pairs(utils.deepcopy(tbl)) do
    print(k, v) 
end

function callback_loop() end
```