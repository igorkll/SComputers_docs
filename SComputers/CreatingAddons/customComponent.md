---
sidebar_position: 3
title: Creating Custom Component
hide_title: true
sidebar-label: 'Creating Custom Component'
---

### to create a script for your component for SComputers, use the following template
```lua
exampleComponent = class()
exampleComponent.maxParentCount = 1
exampleComponent.maxChildCount = 0
exampleComponent.connectionInput = sm.interactable.connectionType.composite
exampleComponent.connectionOutput = sm.interactable.connectionType.none
exampleComponent.colorNormal = sm.color.new(0x7F7F7Fff)
exampleComponent.colorHighlight = sm.color.new(0xFFFFFFff)
exampleComponent.componentType = "example" --absences can cause problems

function exampleComponent:server_onCreate()
    self.interactable.publicData = {
        sc_component = {
            type = exampleComponent.componentType,
            api = {
                test = function()
                    sc.checkComponent(self)
                    return "ok"
                end
            }
        }
    }
end
```

### test
```lua
exampleComponent = getComponents("example")[1]
print("out: ", exampleComponent.test()) --make sure that print is enabled in PermitTool(the third menu item)
```