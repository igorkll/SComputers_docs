local sm_color_new = sm.color.new
local string_byte = string.byte
local string_char = string.char
local checkArg = checkArg
local formatColor = sc.formatColor
local concat = table.concat
local type = type

local function findPixelDataOffset(bmpData)
    -- Размер заголовка BMP (54 байта)
    local headerSize = 54

    -- Прочитать значение поля bfOffBits из BITMAPFILEHEADER (смещение 10-го байта)
    local bfOffBits = 0
    for i = 1, 4 do
        bfOffBits = bfOffBits + bmpData:byte(10 + i) * 256^(i - 1)
    end

    -- Вычислить смещение пиксельных данных
    local pixelDataOffset = headerSize + bfOffBits

    return pixelDataOffset
end


local function getPaletteFromBMP(filedata)
  local header = string.sub(filedata, 1, 54)

  local paletteOffset = bit.bor(bit.lshift(string.byte(header, 11), 0),
                                 bit.lshift(string.byte(header, 12), 8),
                                 bit.lshift(string.byte(header, 13), 16),
                                 bit.lshift(string.byte(header, 14), 24))

  local palette = {}
  for i = 0, 255 do
    local colorData = string.sub(filedata, paletteOffset + i * 4 + 1, paletteOffset + i * 4 + 4)
    local r, g, b = string.byte(colorData, 1, 3)
    palette[i] = {r, g, b}
  end

  return palette
end


local function colorToBytes(color)
    return string_char(math.floor((color.r * 255) + 0.5)) .. string_char(math.floor((color.g * 255) + 0.5)) ..
    string_char(math.floor((color.b * 255) + 0.5)) .. string_char(math.floor((color.a * 255) + 0.5))
end

local function bytesToColor(bytes)
    return sm_color_new(
        string_byte(bytes, 1) / 255,
        string_byte(bytes, 2) / 255,
        string_byte(bytes, 3) / 255,
        string_byte(bytes, 4) / 255
    )
end

local function bytesToColorBMP(bytes, palette)
    if #bytes == 4 then
        return sm_color_new(
            string_byte(bytes, 3) / 255,
            string_byte(bytes, 2) / 255,
            string_byte(bytes, 1) / 255,
            string_byte(bytes, 4) / 255
        )
    elseif #bytes == 3 then
        return sm_color_new(
            string_byte(bytes, 3) / 255,
            string_byte(bytes, 2) / 255,
            string_byte(bytes, 1) / 255
        )
    elseif #bytes == 1 then
        local r, g, b = unpack(palette[string_byte(bytes)])
        return sm_color_new(
            r / 255,
            g / 255,
            b / 255
        )
    else
        --error("failed to parse " .. tostring(#bytes) .. " bytes: " .. bytes)
        return sm_color_new(
            1,
            0,
            0
        )
    end
end

local function colorToString(color)
    return tostring(color):sub(1, 6)
end

-----------------------------------

local image = {}

local function addMethods(img)
    img.draw = image.draw
    img.getSize = image.getSize
    img.set = image.set
    img.get = image.get
    img.encode = image.encode
    img.save = image.save
    img.drawForTicks = image.drawForTicks
    img.fromCamera = image.fromCamera
    img.fromCameraAll = image.fromCameraAll
end

-----------------------------------

function image.encode(img)
    local data = ""
    data = data .. string_char(img.x - 1)
    data = data .. string_char(img.y - 1)

    if img.x > 256 then return error("resolution x greater than 256", 2) end
    if img.y > 256 then return error("resolution y greater than 256", 2) end

    local datas = {}
    local i = 1
    for y = 0, img.y - 1 do
        for x = 0, img.x - 1 do
            datas[i] = colorToBytes(img.data[x + (y * img.x)])
            i = i + 1
        end
    end

    return data .. concat(datas)
end

function image.decode(data)
    local resX, resY = data:byte(1) + 1, data:byte(2) + 1

    if resX > 256 then return error("resolution x greater than 256", 2) end
    if resY > 256 then return error("resolution y greater than 256", 2) end

    local img = {x = resX, y = resY, data = {}}
    local i = 3
    for y = 0, resY - 1 do
        for x = 0, resX - 1 do
            img.data[x + (y * resX)] = bytesToColor(data:sub(i, i + 3))
            i = i + 4
        end
    end
    addMethods(img)
    return img
end

function image.decodeBmp(bmp_content)
    local bmp_header = bmp_content:sub(1, 54)

    local resX = string.byte(bmp_header, 19) + bit.lshift(string.byte(bmp_header, 20), 8) + bit.lshift(string.byte(bmp_header, 21), 16) + bit.lshift(string.byte(bmp_header, 22), 24)
    local resY = string.byte(bmp_header, 23) + bit.lshift(string.byte(bmp_header, 24), 8) + bit.lshift(string.byte(bmp_header, 25), 16) + bit.lshift(string.byte(bmp_header, 26), 24)
    local bpp = string.byte(bmp_header, 29) + bit.lshift(string.byte(bmp_header, 30), 8)
   
    if resX > 256 then return error("resolution x greater than 256", 2) end
    if resY > 256 then return error("resolution y greater than 256", 2) end

    local startRead, palette
    if bpp == 8 then bpp = -1 end --8 bit depth tempory unavailable
    if bpp == 32 then
        startRead = 54 + (4 * 24)
    elseif bpp == 24 then
        startRead = 54
    elseif bpp == 8 then
        startRead = 54 + (3 * 24)
        palette = getPaletteFromBMP(bmp_content)
    else
        error("not supported color depth, supported only: 32, 24", 2)
    end
    startRead = startRead + 1
    local colorbytes = bpp / 8

    local img = {x = resX, y = resY, data = {}}
    local i = startRead

    if resX > 256 then return error("resolution x greater than 256", 2) end
    if resY > 256 then return error("resolution y greater than 256", 2) end
    
    for y = resY - 1, 0, -1 do
        for x = 0, resX - 1 do
            local str = bmp_content:sub(i, i + (colorbytes - 1))
            str = bytesToColorBMP(str, palette)
            img.data[x + (y * resX)] = str
            i = i + colorbytes
        end
    end
    addMethods(img)
    return img
end

-----------------------------------

function image.new(resX, resY, color)
    checkArg(1, resX, "number")
    checkArg(2, resY, "number")
    checkArg(3, color, "Color")

    if resX > 256 then return error("resolution x greater than 256", 2) end
    if resY > 256 then return error("resolution y greater than 256", 2) end

    local img = {x = resX, y = resY, data = {}}
    for y = 0, resY - 1 do
        for x = 0, resX - 1 do
            img.data[x + (y * resX)] = color
        end
    end
    addMethods(img)
    return img
end

function image.load(disk, path)
    checkArg(1, disk, "table")
    checkArg(2, path, "string")

    local extension = string.find(path, "%.[^%.]*$")
    if extension then
        extension = string.sub(path, extension + 1)
    end
    local data = disk.readFile(path)
    if extension == "bmp" then
        return image.decodeBmp(data)
    else
        return image.decode(data)
    end 
end

function image.save(img, disk, path)
    checkArg(1, img, "table")
    checkArg(2, disk, "table")
    checkArg(3, path, "string")

    disk.createFile(path)
    disk.writeFile(path, image.encode(img))
end

-----------------------------------

function image.draw(img, display, posX, posY, light)
    checkArg(1, img, "table")
    checkArg(2, display, "table")
    checkArg(3, posX, "number", "nil")
    checkArg(4, posY, "number", "nil")
    checkArg(5, light, "number", "nil")
    posX = posX or 0
    posY = posY or 0
    light = light or 1

    if img.x > 256 then return error("resolution x greater than 256", 2) end
    if img.y > 256 then return error("resolution y greater than 256", 2) end

    for y = 0, img.y - 1 do
        for x = 0, img.x - 1 do
            sc.yield()
            
            local color = img.data[x + (y * img.x)]
            if color.a > 0 then
                display.drawPixel(posX + x, posY + y, tostring(sm_color_new(color.r, color.g, color.b, light)))
            end
        end
    end
end

function image.drawForTicks(img, display, ticks, posX, posY, light)
    checkArg(1, img, "table")
    checkArg(2, display, "table")
    checkArg(3, ticks, "number", "nil")
    checkArg(4, posX, "number", "nil")
    checkArg(5, posY, "number", "nil")
    checkArg(6, light, "number", "nil")
    ticks = ticks or 40
    posX = posX or 0
    posY = posY or 0
    light = light or 1
    if ticks < 1 then error("ticks < 1", 2) end

    local pixelForDraw = math.floor(((img.x * img.y) / ticks) + 0.5)
    local currentPixel = 0

    if pixelForDraw > (256 * 256) then
        error("you can't draw more than 65536 pixels per tick", 2)
    end

    return function ()
        for i = 1, pixelForDraw do
            sc.yield()

            local color = img.data[currentPixel]
            if not color then return true end

            local x = currentPixel % img.x
            local y = math.floor(currentPixel / img.x)

            if color.a > 0 then
                display.drawPixel(posX + x, posY + y, tostring(sm_color_new(color.r, color.g, color.b, light)))
            end

            currentPixel = currentPixel + 1
        end
    end
end

function image.getSize(img)
    checkArg(1, img, "table")
    return img.x, img.y
end

function image.set(img, x, y, color)
    checkArg(1, img, "table")
    checkArg(2, x, "number")
    checkArg(3, y, "number")
    checkArg(4, color, "Color")
    if x < 0 or x >= img.x then error("invalid pixel pos", 2) end
    if y < 0 or y >= img.y then error("invalid pixel pos", 2) end
    img.data[x + (y * img.x)] = color
end

function image.get(img, x, y)
    checkArg(1, img, "table")
    checkArg(2, x, "number")
    checkArg(3, y, "number")
    if x < 0 or x >= img.x then error("invalid pixel pos", 2) end
    if y < 0 or y >= img.y then error("invalid pixel pos", 2) end
    return img.data[x + (y * img.x)]
end

function image.fromCamera(img, camera, methodName, ...)
    checkArg(1, img, "table")
    checkArg(2, camera, "table")
    checkArg(3, methodName, "string")

    local sx, sy, data = img.x, img.y, img.data
    local vdisplay = {
        getWidth = function ()
            return sx
        end,
        getHeight = function ()
            return sy
        end,
        drawPixel = function (x, y, color)
            data[x + (y * sx)] = sm_color_new(color)
        end
    }
    camera[methodName](vdisplay, ...)
end

function image.fromCameraAll(img, camera, methodName, ...)
    checkArg(1, img, "table")
    checkArg(2, camera, "table")
    checkArg(3, methodName, "string")

    camera.resetCounter()

    local notEnd = true
    local notStart
    local sx, sy, data = img.x, img.y, img.data
    local vdisplay = {
        getWidth = function ()
            return sx
        end,
        getHeight = function ()
            return sy
        end,
        drawPixel = function (x, y, color)
            if x ~= 0 or y ~= 0 then
                notStart = true
            end
            if notStart and x == 0 and y == 0 then
                notEnd = false
            end
            
            data[x + (y * sx)] = sm_color_new(color)
        end
    }
    while notEnd do
        sc.yield()
        camera[methodName](vdisplay, ...)
    end
end

-----------------------------------

sc.reg_internal_lib("image", image)