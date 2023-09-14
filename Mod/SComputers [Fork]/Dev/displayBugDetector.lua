display = getDisplays()[1]

if not start then
    state = not display.getSkipAtLags()
    display.setSkipAtLags(state)

    start = true
end

print(display.getSkipAtLags(), state)
if not not display.getSkipAtLags() ~= state then
    print("red")
    display.clear("ff0000")
else
    print("green")
    display.clear("00ff00")
end
--display.setSkipAtLags(state)

if _endtick then
    display.clear("000000")
end
display.flush()