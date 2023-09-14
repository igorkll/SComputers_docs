options = args[1]
screen = options.screen
gui = guilib.create(screen)

scene = gui.createScene("cecece")

size = 5
if gui.sizeX >= 64 then
    size = 10
end
if gui.sizeX >= 128 then
    size = 20
end

label = scene.createLabel(0, 0, gui.sizeX - size - 5, size, "", "494949", "FFFFFF")

exitButton = scene.createButton(
    gui.sizeX - size,
    0,
    size,
    size,
    "X",
    "FF0000",
    "FFFFFF",
    "0000FF",
    "000000",
    1
)

function createButton(x, y, text, color)
    return scene.createButton(
        1 + (x * (size + 2)),
        size + 1 + (y * (size + 2)),
        size,
        size,
        text,
        color,
        "FFFFFF",
        color,
        "000000",
        1
    )
end

b1 = createButton(0, 0, "1", "0000FF")
b2 = createButton(1, 0, "2", "0000FF")
b3 = createButton(2, 0, "3", "0000FF")

b4 = createButton(0, 1, "4", "0000FF")
b5 = createButton(1, 1, "5", "0000FF")
b6 = createButton(2, 1, "6", "0000FF")

b7 = createButton(0, 2, "7", "0000FF")
b8 = createButton(1, 2, "8", "0000FF")
b9 = createButton(2, 2, "9", "0000FF")

bc = createButton(0, 3, "X", "FF0000")
b0 = createButton(1, 3, "0", "0000FF")
be = createButton(2, 3, "=", "00FF00")

bf1 = createButton(3, 0, "+", "FFFF00")
bf2 = createButton(3, 1, "-", "FFFF00")
bf3 = createButton(3, 2, "*", "FFFF00")
bf4 = createButton(3, 3, "/", "FFFF00")

bn = createButton(4, 0, "<", "FF0000")

gui.select(scene)

function onStart()
    str = ""
end

function onTick()
    gui.tick()
    if exitButton.getState() then
        utils.exit(object)
    elseif b1.getState() then
        str = str .. "1"
    elseif b2.getState() then
        str = str .. "2"
    elseif b3.getState() then
        str = str .. "3"
    elseif b4.getState() then
        str = str .. "4"
    elseif b5.getState() then
        str = str .. "5"
    elseif b6.getState() then
        str = str .. "6"
    elseif b7.getState() then
        str = str .. "7"
    elseif b8.getState() then
        str = str .. "8"
    elseif b9.getState() then
        str = str .. "9"
    elseif b0.getState() then
        str = str .. "0"
    elseif bf1.getState() then
        str = str .. "+"
    elseif bf2.getState() then
        str = str .. "-"
    elseif bf3.getState() then
        str = str .. "*"
    elseif bf4.getState() then
        str = str .. "/"
    elseif bc.getState() then
        str = ""
    elseif be.getState() then
        local result = {pcall(loadstring, "return " .. str)}
        if result[1] then
            local result = {pcall(result[2])}
            if result[1] then
                str = tostring(result[2] or "")
            end
        end
    elseif bn.getState() then
        str = str:sub(1, #str - 1)
    end
    label.text = str
    gui.draw()
end