---
sidebar_position: 16
title: setComponentApi
hide_title: true
sidebar-label: 'setComponentApi'
---

setComponentApi(name, api)/getComponentApi:name,api - allows you to make your computer visible to other computers not only as a computer, but also as a component
it will work even if your computer is in a state of invisibility (that is, it is not determined by the getParentComputers/getChildComputers methods)
but the api of the component does NOT work if the computer was turned off or destroy
and it doesn't matter which way the connection goes

#### removing api
```lua
setComponentApi() -- disables the component api
```

#### get self api
```lua
print(getComponentApi()) --will return what was installed using setComponentApi
```

#### example
```lua
setComponentApi("custom_component", {
    test = function()
        return 'a custom component'
    end
})

function callback_loop() end
```

#### using custom component
```lua
local custom_component = getComponents("custom_component")[1]
print("test:", custom_component.test())

function callback_loop() end
```