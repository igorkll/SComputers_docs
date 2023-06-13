---
sidebar_position: 6
title: terminal
hide_title: true
sidebar-label: 'terminal'
---

### terminal component
* type - terminal
* clear() - clear the terminal log
* read():string,nil - reads the last text entered into the terminal
* write(str) - sends a string to the terminal

#### example
```lua
lineend = string.char(13)

terminal = getComponents("terminal")[1]
terminal.read()
terminal.clear()
terminal.write("#ffff00terminal demo code" .. lineend)

function callback_loop()
    local text = terminal.read()
    if text then
        if text == "/beep" then
            terminal.write(string.char(7))
        elseif text == "/clear" then
            terminal.clear()
        end
        terminal.write("#00ff00> " .. text .. lineend)
    end

    if _endtick then
        terminal.clear()
    end
end
```