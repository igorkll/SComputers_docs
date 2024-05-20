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