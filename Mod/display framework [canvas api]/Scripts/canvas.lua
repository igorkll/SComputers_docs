print("> canvas.lua")
dofile("$CONTENT_e8298053-4412-48e8-aff1-4271d1b07584/Scripts/font.lua")
dofile("$CONTENT_e8298053-4412-48e8-aff1-4271d1b07584/Scripts/utf8.lua")

local canvasAPI = {
    draw = {
        clear = 0,
        set   = 1,
        fill  = 2,
        rect  = 3,
        text  = 4,
        line  = 5,
        circle  = 6,
        circleF = 7,
        circleC = 8
    },
    material = {
        classic = sm.uuid.new("64d41b06-9b71-4e19-9f87-1e7e63845e59"),
        glass = sm.uuid.new("a683f897-5b8a-4c96-9c46-7b9fbc76d186")
    }
}

local string_len = string.len
local bit = bit or bit32
local bit_rshift = bit.rshift
local bit_lshift = bit.lshift
local utf8 = utf8
local string = string
local font = font
local type = type
local math_ceil = math.ceil
local math_max = math.max
local string_format = string.format
local table_insert = table.insert
local table_remove = table.remove
local math_floor = math.floor
local vec3_new = sm.vec3.new
local color_new = sm.color.new
local quat_fromEuler = sm.quat.fromEuler
local ipairs = ipairs
local pairs = pairs
local string_byte = string.byte
local defaultError = font.optimized.error
local tostring = tostring
local math_abs = math.abs
local math_min = math.min
local string_sub = string.sub
local table_concat = table.concat
local tonumber = tonumber
local utf8_len = utf8.len
local utf8_sub = utf8.sub

local black = color_new(0, 0, 0)
local white = color_new(1, 1, 1)
local blackNumber = 0x000000ff
local whiteNumber = 0xffffffff

local getEffectName
do
    local currentEffect = 1
    local effectsNames = {
        "ShapeRenderable",
    }

    for i = 2, 114 do
        table_insert(effectsNames, "ShapeRenderable" .. tostring(i))
    end

    function getEffectName()
        local name = effectsNames[currentEffect]
        currentEffect = currentEffect + 1
        if currentEffect > #effectsNames then
            currentEffect = 1
        end
        return name
    end
end

local sm_effect_createEffect = sm.effect.createEffect
local emptyEffect = sm_effect_createEffect(getEffectName())
local effect_setParameter = emptyEffect.setParameter
local effect_stop = emptyEffect.stop
local effect_destroy = emptyEffect.destroy
local effect_start = emptyEffect.start
local effect_isDone = emptyEffect.isDone
local effect_isPlaying = emptyEffect.isPlaying
local effect_setScale = emptyEffect.setScale
local effect_setOffsetPosition = emptyEffect.setOffsetPosition
local effect_setOffsetRotation = emptyEffect.setOffsetRotation
effect_destroy(emptyEffect)

local function checkFont(font)
	if type(font) ~= "table" then
		error("the font should be a table", 3)
    elseif type(font.chars) ~= "table" or type(font.width) ~= "number" or type(font.height) ~= "number" then
		error("font failed integrity check", 3)
	elseif font.width > 32 then
		error("the font width should not exceed 32", 3)
    elseif font.height > 32 then
		error("the font height should not exceed 32", 3)
	end
	for char, data in pairs(font.chars) do
		if type(char) ~= "string" or type(data) ~= "table" or #data ~= font.height then
			error("font failed integrity check", 3)
		end
		for _, line in ipairs(data) do
			if type(line) ~= "string" or #line ~= font.width then
				error("font failed integrity check", 3)
			end
		end
	end
end

local function tableClone(tbl)
    local newtbl = {}
    for k, v in pairs(tbl) do
        newtbl[k] = v
    end
    return newtbl
end

local function stackChecksum(stack)
    local num = -#stack
    local t, v
    for i = 1, #stack do
        v = stack[i]
        t = type(v)
        num = num - i
        if t == "number" then
            num = num + (v * i) + v + i
        elseif t == "Color" then
            num = num + ((i * (v.r / i) * -4) + v.g)
            num = num - ((i * (v.g + i) * 5) + v.b)
            num = num + ((i * (v.b - i) * 8) + v.r)
        elseif t == "string" then
            for i3 = 1, #v do
                num = num + (i * (-i3 - (string_byte(v, i3) * i3)))
            end
        end
    end
    return num
end

local function checkArg(n, have, ...)
	have = type(have)
	local tbl = {...}
	for _, t in ipairs(tbl) do
		if have == t then
			return
		end
	end
	error(string_format("bad argument #%d (%s expected, got %s)", n, table_concat(tbl, " or "), have), 3)
end

local function remathRect(offset, stack, sizeX, sizeY)
    local x, y, w, h = stack[offset], stack[offset+1], stack[offset+2], stack[offset+3]
    if w < 0 then
        w = math_abs(w)
        x = x - w
    end
    if h < 0 then
        h = math_abs(h)
        y = y - h
    end
    if x < 0 then
        w = w + x
        x = 0
    end
    if y < 0 then
        h = h + y
        y = 0
    end
    w = math_min(w, sizeX - x)
    h = math_min(h, sizeY - y)
    stack[offset], stack[offset+1], stack[offset+2], stack[offset+3] = x, y, w, h
end

local function posCheck(width, height, x, y)
    return x >= 0 and y >= 0 and x < width and y < height
end

local hashChar = string.byte("#")
local bit = bit or bit32
local band = bit.band
local rshift = bit.rshift
local function hexToRGB(color)
    return band(rshift(color, 16), 0xFF) / 255, band(rshift(color, 8), 0xFF) / 255, band(color, 0xFF) / 255
end

local function formatColor(color, default)
    local t = type(color)
    if t == "Color" then
        return color
    elseif t == "string" then
        return color_new(color)
    elseif t == "number" then
        return color_new(hexToRGB(color))
    end

    return default
end

local redMul = 256 * 256 * 256
local greenMul = 256 * 256
local blueMul = 256
local function formatColorToNumber(color, default)
    local t = type(color)
    if t == "Color" then
        return (math_floor(color.r * 255) * redMul) + (math_floor(color.g * 255) * greenMul) + (math_floor(color.b * 255) * blueMul) + math_floor(color.a * 255)
    elseif t == "string" then
        local val
        if string_byte(color) == hashChar then
            val = tonumber(string_sub(color, 2, -1), 16) or 0
        else
            val = tonumber(color, 16) or 0
        end
        if #color > 7 then
            return val
        end
        return (val * 256) + 255
    elseif t == "number" then
        return (color * 256) + 255
    end

    return default
end

local function mathDist(pos1, pos2)
    return math.sqrt(((pos1.x - pos2.x) ^ 2) + ((pos1.y - pos2.y) ^ 2) + ((pos1.z - pos2.z) ^ 2))
end

local function needPushStack(canvas, dataTunnel, dt, skipAt) --returns true if the rendering stack should be applied
    return dataTunnel.display_forceFlush or not ((dataTunnel.skipAtNotSight and not canvas.isRendering()) or (dataTunnel.skipAtLags and dt and dt >= (1 / (skipAt or 20))))
end

local dataSizes = {
    [0] = 2,
    4,
    6,
    6,
    5,
    6,
    5,
    5,
    5
}

--low level drawer API
function canvasAPI.createDrawer(sizeX, sizeY, callback, callbackBefore)
    local obj = {}
    local oldStackSum
    local rSizeX, rSizeY = sizeX, sizeY
    local maxX, maxY = sizeX - 1, sizeY - 1
    local newBuffer, newBufferBase = {}, 0
    local realBuffer, realBufferBase = {}, 0
    local maxBuffer = ((sizeX - 1) + ((sizeY - 1) * sizeX)) + 1
    local currentFont = font.optimized
    local fontWidth, fontHeight = font.width, font.height
    local rotation = 0
    local utf8Support = false
    local updated = false
    local maxLineSize = sizeX + sizeY
    local textCache = {}
    local textCacheSize = 0

    local lsetList = {
        function (x, y, color)
            newBuffer[(x + (y * rSizeX)) + 1] = color
        end,
        function (x, y, color)
            newBuffer[((rSizeX - y - 1) + (x * rSizeX)) + 1] = color
        end,
        function (x, y, color)
            newBuffer[((rSizeX - x - 1) + ((rSizeY - y - 1) * rSizeX)) + 1] = color
        end,
        function (x, y, color)
            newBuffer[(y + ((rSizeY - x - 1) * rSizeX)) + 1] = color
        end
    }
    local lset = lsetList[1]

    local function checkSet(px, py, col)
        if posCheck(sizeX, sizeY, px, py) then
            lset(px, py, col)
        end
    end

    function obj.drawerReset()
        textCache = {}
        textCacheSize = 0
    end

    function obj.setSoftwareRotation(_rotation)
        rotation = _rotation
        if rotation == 1 or rotation == 3 then
            sizeX = rSizeY
            sizeY = rSizeX
        else
            sizeX = rSizeX
            sizeY = rSizeY
        end
        maxX, maxY = sizeX - 1, sizeY - 1
        lset = lsetList[rotation + 1]
    end

    function obj.setUtf8Support(state)
        utf8Support = not not state
    end

    function obj.setFont(customFont)
        if customFont then
            currentFont = font.optimizeFont(customFont.chars, customFont.width, customFont.height)
            fontWidth, fontHeight = customFont.width, customFont.height
        else
            currentFont = font.optimized
            fontWidth, fontHeight = font.width, font.height
        end
        textCache = {}
        textCacheSize = 0
    end

    local old_rotation
    local old_utf8support
    local old_customFont
    function obj.pushDataTunnelParams(params)
        if params.rotation ~= old_rotation then
            obj.setSoftwareRotation(params.rotation)
            old_rotation = params.rotation
        end
        if params.utf8support ~= old_utf8support then
            obj.setUtf8Support(params.utf8support)
            old_utf8support = params.utf8support
        end
        if params.customFont ~= old_customFont then
            obj.setFont(params.customFont)
            old_customFont = params.customFont
        end
    end

    function obj.pushStack(stack)
        updated = true

        local tx, ty
        local px, py, px2, py2, col
        local chr
        local chrdata
        local offset = 2
        local actionNum
        local sx, sy, e2, err, dx, dy
        local text
        while stack[offset] do
            actionNum = stack[offset-1]

            if actionNum == 0 then
                newBufferBase = stack[offset]
                newBuffer = {}
            elseif actionNum == 1 then
                px, py, col = stack[offset], stack[offset+1], stack[offset+2]
                if posCheck(sizeX, sizeY, px, py) then
                    lset(px, py, col)
                end
            elseif actionNum == 2 then
                remathRect(offset, stack, sizeX, sizeY)
                tx, ty = stack[offset], stack[offset+1]
                px, py = stack[offset+2], stack[offset+3]
                col = stack[offset+4]
                for ix = tx, tx + (px - 1) do
					for iy = ty, ty + (py - 1) do
                        lset(ix, iy, col)
					end
				end
            elseif actionNum == 3 then
                remathRect(offset, stack, sizeX, sizeY)
                tx = stack[offset]
                ty = stack[offset+1]
                px = tx + (stack[offset+2] - 1)
				py = ty + (stack[offset+3] - 1)
                col = stack[offset+4]
                for ix = tx, px do
                    lset(ix, ty, col)
                    lset(ix, py, col)
				end
				for iy = ty + 1, py - 1 do
                    lset(tx, iy, col)
                    lset(px, iy, col)
				end
            elseif actionNum == 4 then
                tx, ty = stack[offset], stack[offset+1]
                text = stack[offset+2]
                col = stack[offset+3]
                if textCache[text] then
                    chr = textCache[text]
                    for i = 1, #chr, 2 do
                        px, py = tx + chr[i], ty + chr[i+1]
                        if posCheck(sizeX, sizeY, px, py) then
                            lset(px, py, col)
                        end
                    end
                else
                    if textCacheSize < 1024 then
                        e2 = {}
                        err = 1
                        if utf8Support then
                            for i = 1, utf8_len(text) do
                                chr = utf8_sub(text, i, i)
                                chrdata = currentFont[chr] or currentFont.error or defaultError
                                for i2 = 1, #chrdata, 2 do
                                    sx, sy = chrdata[i2] + ((i - 1) * (fontWidth + 1)), chrdata[i2 + 1]
                                    px, py = tx + sx, ty + sy
                                    e2[err] = sx
                                    err = err + 1
                                    e2[err] = sy
                                    err = err + 1
                                    if posCheck(sizeX, sizeY, px, py) then
                                        lset(px, py, col)
                                    end
                                end
                            end
                        else
                            for i = 1, string_len(text) do
                                chr = string_byte(text, i)
                                chrdata = currentFont[chr] or currentFont.error or defaultError
                                for i2 = 1, #chrdata, 2 do
                                    sx, sy = chrdata[i2] + ((i - 1) * (fontWidth + 1)), chrdata[i2 + 1]
                                    px, py = tx + sx, ty + sy
                                    e2[err] = sx
                                    err = err + 1
                                    e2[err] = sy
                                    err = err + 1
                                    if posCheck(sizeX, sizeY, px, py) then
                                        lset(px, py, col)
                                    end
                                end
                            end
                        end
                        textCache[text] = e2
                        textCacheSize = textCacheSize + 1
                    else
                        if utf8Support then
                            for i = 1, utf8_len(text) do
                                chr = utf8_sub(text, i, i)
                                chrdata = currentFont[chr] or currentFont.error or defaultError
                                for i2 = 1, #chrdata, 2 do
                                    px, py = tx + chrdata[i2] + ((i - 1) * (fontWidth + 1)), ty + chrdata[i2 + 1]
                                    if posCheck(sizeX, sizeY, px, py) then
                                        lset(px, py, col)
                                    end
                                end
                            end
                        else
                            for i = 1, string_len(text) do
                                chr = string_byte(text, i)
                                chrdata = currentFont[chr] or currentFont.error or defaultError
                                for i2 = 1, #chrdata, 2 do
                                    px, py = tx + chrdata[i2] + ((i - 1) * (fontWidth + 1)), ty + chrdata[i2 + 1]
                                    if posCheck(sizeX, sizeY, px, py) then
                                        lset(px, py, col)
                                    end
                                end
                            end
                        end
                    end
                end
            elseif actionNum == 5 then
                px = stack[offset]
                py = stack[offset+1]
                px2 = stack[offset+2]
                py2 = stack[offset+3]
                col = stack[offset+4]
                dx = math_abs(px2 - px)
                dy = math_abs(py2 - py)
                sx = (px < px2) and 1 or -1
                sy = (py < py2) and 1 or -1
                err = dx - dy
                for _ = 1, maxLineSize do
                    if posCheck(sizeX, sizeY, px, py) then
                        lset(px, py, col)
                    end
                    if px == px2 and py == py2 then
                        break
                    end
                    e2 = bit_lshift(err, 1)
                    if e2 > -dy then
                        err = err - dy
                        px = px + sx
                    end
                    if e2 < dx then
                        err = err + dx
                        py = py + sy
                    end
                end
            elseif actionNum == 6 or actionNum == 8 then --Michener’s Algorithm
                err = actionNum == 8
                px = stack[offset]
                py = stack[offset+1]
                e2 = stack[offset+2]
                col = stack[offset+3]
                dx = 0
                dy = e2
                chr = 3 - 2 * e2

                if err and e2 % 2 == 0 then
                    while dx <= dy do
                        checkSet(px + dx - 1, py + dy - 1, col)
                        checkSet(px + dy - 1, py + dx, col)
                        checkSet(px - dy, py + dx, col)
                        checkSet(px - dx, py + dy - 1, col)
                        checkSet(px + dy - 1, py - dx, col)
                        checkSet(px + dx - 1, py - dy, col)
                        checkSet(px - dy, py - dx, col)
                        checkSet(px - dx, py - dy, col)
    
                        if chr < 0 then
                            chr = chr + 4 * dx + 6
                        else
                            chr = chr + 4 * (dx - dy) + 10
                            dy = dy - 1
                        end
                        dx = dx + 1
                    end
                else
                    while dx <= dy do
                        checkSet(px + dx, py + dy, col)
                        checkSet(px + dy, py + dx, col)
                        checkSet(px - dy, py + dx, col)
                        checkSet(px - dx, py + dy, col)
                        checkSet(px + dy, py - dx, col)
                        checkSet(px + dx, py - dy, col)
                        checkSet(px - dy, py - dx, col)
                        checkSet(px - dx, py - dy, col)
    
                        if chr < 0 then
                            chr = chr + 4 * dx + 6
                        else
                            chr = chr + 4 * (dx - dy) + 10
                            dy = dy - 1
                        end
                        dx = dx + 1
                    end
                end
            elseif actionNum == 7 then
                px = stack[offset]
                py = stack[offset+1]
                e2 = stack[offset+2]
                chr = e2*e2
                col = stack[offset+3]
                for ix = math_max(-e2, -px), math_min(e2, (sizeX - px) - 1) do
					dx = px + ix
                    sx = ix + 0.5
					for iy = math_max(-e2, -py), math_min(e2, (sizeY - py) - 1) do
						dy = py + iy
                        sy = iy + 0.5
						if (sx * sx) + (sy * sy) <= chr then
							lset(dx, dy, col)
						end
					end
				end
            end

            offset = offset + dataSizes[actionNum]
        end
    end

    function obj.flush(force)
        if (not obj.wait and updated) or force then
            if callbackBefore then
                callbackBefore(newBufferBase)
            end
            local color
            if force then
                for i = 1, maxBuffer do
                    color = newBuffer[i] or newBufferBase
                    callback((i - 1) % rSizeX, math_floor((i - 1) / rSizeX), color, newBufferBase)
                    realBuffer[i] = color
                end
            else
                for i = 1, maxBuffer do
                    color = newBuffer[i] or newBufferBase
                    if color ~= (realBuffer[i] or realBufferBase) then
                        callback((i - 1) % rSizeX, math_floor((i - 1) / rSizeX), color, newBufferBase)
                        realBuffer[i] = color
                    end
                end
            end
            updated = false
        end
    end

    function obj.setWait(state)
        obj.wait = state
        if not state then
            obj.flush()
        end
    end

    return obj
end

--low level display api
local hiddenOffset = sm.vec3.new(1000000, 1000000, 1000000)
function canvasAPI.createCanvas(parent, sizeX, sizeY, pixelSize, offset, rotation, material)
    local obj = {sizeX = sizeX, sizeY = sizeY}
    local maxX, maxY = sizeX - 1, sizeY - 1
    local dist
    local showState = false
    local disable = false

    material = material or canvasAPI.material.classic

    local effects = {}
    local flushedDefault = false
    local oldBackplateColor = 0
    local blackplate
    if material == canvasAPI.material.classic then
        blackplate = sm_effect_createEffect(getEffectName(), parent)
        effect_setParameter(blackplate, "uuid", material)
        effect_setParameter(blackplate, "color", black)
    end

    local function setOffsetPosition(effect, posX, posY)
        effect_setOffsetPosition(effect, rotation * (offset + vec3_new(((posX + 0.5) - (sizeX / 2)) * pixelSize.x, ((posY + 0.5) - (sizeY / 2)) * -pixelSize.y, blackplate and 0.001 or 0)))
    end

    local function setScale(effect)
        effect_setScale(effect, pixelSize * 1.02)
    end

    local function setOffsetRotation(effect)
        effect_setOffsetRotation(effect, rotation)
    end

    local drawer = canvasAPI.createDrawer(sizeX, sizeY, function (x, y, color, base)
        local index = x + (y * sizeX)
        local effectData = effects[index]

        if blackplate and color == base then
            if effectData and effectData[4] then
                effect_setOffsetPosition(effectData[1], hiddenOffset)
                effectData[4] = false
            end
        elseif effectData then
            if effectData[5] ~= color then
                effect_setParameter(effectData[1], "color", color_new(color))
                effectData[5] = color
            end

            if not effectData[4] then
                setOffsetPosition(effectData[1], effectData[2], effectData[3])
                effectData[4] = true
            end
        else
            local effect = sm_effect_createEffect(getEffectName(), parent)
            effect_setParameter(effect, "uuid", material)
            effect_setParameter(effect, "color", color_new(color))

            effects[index] = {
                effect,
                x,
                y,
                true,
                color
            }

            setOffsetPosition(effect, x, y)
            setScale(effect)
            setOffsetRotation(effect)
            effect_start(effect)
        end
    end, blackplate and function (base)
        if oldBackplateColor ~= base then
            effect_setParameter(blackplate, "color", color_new(base))
            oldBackplateColor = base
        end
    end)
    drawer.setWait(true)

    local function getSelfPos()
        local pt = type(parent)
        if pt == "Interactable" then
            return parent.shape.worldPosition
        elseif pt == "Character" then
            return parent.worldPosition
        end
    end

    function obj.isRendering()
        return showState
    end

    function obj.disable(state)
        disable = state
    end

    function obj.setRenderDistance(_dist)
        dist = _dist
    end

    function obj.update()
        local newShowState = true
        if disable then
            newShowState = false
        elseif dist then
            newShowState = mathDist(getSelfPos(), sm.localPlayer.getPlayer().character.worldPosition) <= dist
        end

        if newShowState ~= showState then
            if newShowState then
                if not blackplate and not flushedDefault then
                    drawer.flush(true)
                    flushedDefault = true
                end
                for _, effect in pairs(effects) do
                    effect_start(effect[1])
                end
                if blackplate then
                    effect_start(blackplate)
                end
                drawer.setWait(false)
            else
                for _, effect in pairs(effects) do
                    effect_stop(effect[1])
                end
                if blackplate then
                    effect_stop(blackplate)
                end
                drawer.setWait(true)
            end
            showState = newShowState
        end
    end

    function obj.setPixelSize(_pixelSize)
        pixelSize = _pixelSize
        for _, data in pairs(effects) do
            setScale(data[1])
        end
        if blackplate then
            effect_setScale(blackplate, vec3_new(pixelSize.x * sizeX, pixelSize.y * sizeY, pixelSize.z))
        end
    end

    function obj.setOffset(_offset)
        offset = _offset
        for _, data in pairs(effects) do
            setOffsetPosition(data[1], data[2], data[3])
        end
        if blackplate then
            effect_setOffsetPosition(blackplate, rotation * (offset + vec3_new(((sizeX / 2) - (sizeX / 2)) * pixelSize.x, ((sizeY / 2) - (sizeY / 2)) * -pixelSize.y, 0)))
        end
    end

    function obj.setCanvasRotation(_rotation)
        rotation = _rotation
        for _, data in pairs(effects) do
            setOffsetRotation(data[1])
        end
        if blackplate then
            effect_setOffsetRotation(blackplate, rotation)
        end
    end

    function obj.destroy()
        for _, data in pairs(effects) do
            effect_destroy(data[1])
        end
        if blackplate then
            effect_destroy(blackplate)
        end
    end

    ---------------------------------------

    if type(pixelSize) == "number" then
        local vec = vec3_new(0.0072, 0.0072, 0) * pixelSize
        vec.z = 0.001
        obj.setPixelSize(vec)
    else
        obj.setPixelSize(pixelSize or vec3_new(0.25 / 4, 0.25 / 4, 0.05 / 4))
    end
    obj.setCanvasRotation(rotation or quat_fromEuler(vec3_new(0, 0, 0)))
    obj.setOffset(offset or vec3_new(0, 0, 0))

    ---------------------------------------

    obj.drawer = drawer
    for k, v in pairs(drawer) do
        obj[k] = v
    end

    return obj
end

--simulates the API of screens from SComputers on the client side of your parts
function canvasAPI.createClientScriptableCanvas(parent, sizeX, sizeY, pixelSize, offset, rotation, material)
    local dataTunnel = {}
    local canvas = canvasAPI.createCanvas(parent, sizeX, sizeY, pixelSize, offset, rotation, material)
    local api = canvasAPI.createScriptableApi(sizeX, sizeY, dataTunnel)
    api.registerClick = canvasAPI.addTouch(api, dataTunnel)
    api.dataTunnel = dataTunnel
    api.canvas = canvas

    local renderDistance = 15

    for k, v in pairs(canvas) do
        if k ~= "flush" then
            api[k] = v
        end
    end

    function api.getAudience()
        return canvas.isRendering() and 1 or 0
    end

    function api.update(dt)
        canvas.disable(not api.isAllow())
        if dataTunnel.renderAtDistance then
            canvas.setRenderDistance()
        else
            canvas.setRenderDistance(renderDistance)
        end
        canvas.pushDataTunnelParams(dataTunnel)
        canvas.update()
        dataTunnel.scriptableApi_update()

        if dataTunnel.display_reset then
            canvas.drawerReset()
            dataTunnel.display_reset = nil
        end

        if dataTunnel.display_flush then
            if needPushStack(canvas, dataTunnel, dt) then
                canvas.pushStack(dataTunnel.display_stack)
                canvas.flush()
            end
            
            dataTunnel.display_flush()
            dataTunnel.display_stack = nil
            dataTunnel.display_flush = nil
            dataTunnel.display_forceFlush = nil
        end
    end

    function api.setRenderDistance(dist)
        renderDistance = dist
    end

    return api
end

--simulates the SComputers API, does not implement data transfer
function canvasAPI.createScriptableApi(width, height, dataTunnel)
    dataTunnel = dataTunnel or {}
    dataTunnel.rotation = 0
    dataTunnel.skipAtLags = true
    dataTunnel.skipAtNotSight = false
    dataTunnel.utf8support = false
    dataTunnel.renderAtDistance = false
    dataTunnel.display_forceFlush = true
    dataTunnel.dataUpdated = true

    local stack = {}
    local stackIndex = 1
    local pixelsCache = {} --optimizations for cameras
    local pixelsCacheExists = false
    local oldStackSum

    local function clearStack()
        if dataTunnel.display_stack == stack then
            stack = {}
            stackIndex = 1
        end
    end

    local function setForceFrame()
        if pixelsCacheExists then
            pixelsCache = {}
            pixelsCacheExists = false
        end
        oldStackSum = nil
        dataTunnel.display_forceFlush = true
    end

    function dataTunnel.scriptableApi_update()
        if sm.game.getCurrentTick() % (40 * 4) == 0 then
            setForceFrame()
        end
    end

    local rwidth, rheight = width, height
    local rmwidth, rmheight = width - 1, height - 1
    local fontX, fontY = font.width, font.height
    local mFontX, mFontY = fontX - 1, fontY - 1
    local xFontX, xFontY = fontX + 1, fontY + 1
    local utf8support = false
    local index

    local api
    api = {
        -- not implemented (implement it yourself if necessary)
        isAllow = function()
            return true
        end,
        getAudience = function()
            return 1
        end,


        -- stubs (outdated methods)
        optimize = function() end,
        setFrameCheck = function () end,
        getFrameCheck = function () return false end,


        -- main
        getWidth = function()
            return rwidth
        end,
        getHeight = function()
            return rheight
        end,
        clear = function(color)
            if pixelsCacheExists then
                pixelsCache = {}
                pixelsCacheExists = false
            end

            stack[1] = 0
            stack[2] = formatColorToNumber(color, blackNumber)
            for i = 3, stackIndex - 1 do
                stack[i] = nil
            end
            stackIndex = 3
        end,
        drawPixel = function(x, y, color)
            x, y = math_floor(x + 0.5), math_floor(y + 0.5)
            index = x + (y * rwidth) + 1
            if pixelsCache[index] ~= color then
                pixelsCache[index] = color
                pixelsCacheExists = true

                stack[stackIndex] = 1
                stackIndex = stackIndex + 1
                stack[stackIndex] = x
                stackIndex = stackIndex + 1
                stack[stackIndex] = y
                stackIndex = stackIndex + 1
                stack[stackIndex] = formatColorToNumber(color, whiteNumber)
                stackIndex = stackIndex + 1
            end
        end,
        fillRect = function(x, y, sizeX, sizeY, color)
            stack[stackIndex] = 2
            stackIndex = stackIndex + 1
            stack[stackIndex] = math_floor(x + 0.5)
            stackIndex = stackIndex + 1
            stack[stackIndex] = math_floor(y + 0.5)
            stackIndex = stackIndex + 1
            stack[stackIndex] = math_floor(sizeX + 0.5)
            stackIndex = stackIndex + 1
            stack[stackIndex] = math_floor(sizeY + 0.5)
            stackIndex = stackIndex + 1
            stack[stackIndex] = formatColorToNumber(color, whiteNumber)
            stackIndex = stackIndex + 1
            
            if pixelsCacheExists then
                pixelsCache = {}
                pixelsCacheExists = false
            end
        end,
        drawRect = function(x, y, sizeX, sizeY, color)
            stack[stackIndex] = 3
            stackIndex = stackIndex + 1
            stack[stackIndex] = math_floor(x + 0.5)
            stackIndex = stackIndex + 1
            stack[stackIndex] = math_floor(y + 0.5)
            stackIndex = stackIndex + 1
            stack[stackIndex] = math_floor(sizeX + 0.5)
            stackIndex = stackIndex + 1
            stack[stackIndex] = math_floor(sizeY + 0.5)
            stackIndex = stackIndex + 1
            stack[stackIndex] = formatColorToNumber(color, whiteNumber)
            stackIndex = stackIndex + 1
            
            if pixelsCacheExists then
                pixelsCache = {}
                pixelsCacheExists = false
            end
        end,
        drawText = function(x, y, text, color)
            if y > rmheight or y + mFontY < 0 then return end
            local maxTextLen = math_ceil((width - x) / xFontX)
            if maxTextLen <= 0 then return end
            local startTextFrom = math_max(1, math_floor((0 - x) / xFontX) + 1)
            text = tostring(text)

            stack[stackIndex] = 4
            stackIndex = stackIndex + 1
            stack[stackIndex] = math_floor(x + 0.5) + ((startTextFrom - 1) * xFontX)
            stackIndex = stackIndex + 1
            stack[stackIndex] = math_floor(y + 0.5)
            stackIndex = stackIndex + 1
            if utf8support then
                if utf8.len(text) > maxTextLen or startTextFrom > 1 then
                    stack[stackIndex] = utf8.sub(text, startTextFrom, maxTextLen)
                else
                    stack[stackIndex] = text
                end
            else
                if #text > maxTextLen or startTextFrom > 1 then
                    stack[stackIndex] = text:sub(startTextFrom, maxTextLen)
                else
                    stack[stackIndex] = text
                end
            end
            stackIndex = stackIndex + 1
            stack[stackIndex] = formatColorToNumber(color, whiteNumber)
            stackIndex = stackIndex + 1
            
            if pixelsCacheExists then
                pixelsCache = {}
                pixelsCacheExists = false
            end
        end,
        drawLine = function(x, y, x2, y2, color)
            stack[stackIndex] = 5
            stackIndex = stackIndex + 1
            stack[stackIndex] = math_floor(x + 0.5)
            stackIndex = stackIndex + 1
            stack[stackIndex] = math_floor(y + 0.5)
            stackIndex = stackIndex + 1
            stack[stackIndex] = math_floor(x2 + 0.5)
            stackIndex = stackIndex + 1
            stack[stackIndex] = math_floor(y2 + 0.5)
            stackIndex = stackIndex + 1
            stack[stackIndex] = formatColorToNumber(color, whiteNumber)
            stackIndex = stackIndex + 1
            
            if pixelsCacheExists then
                pixelsCache = {}
                pixelsCacheExists = false
            end
        end,
        drawCircle = function (x, y, r, color)
            if r > 1024 then r = 1024 end

            stack[stackIndex] = 6
            stackIndex = stackIndex + 1
            stack[stackIndex] = math_floor(x + 0.5)
            stackIndex = stackIndex + 1
            stack[stackIndex] = math_floor(y + 0.5)
            stackIndex = stackIndex + 1
            stack[stackIndex] = math_floor(r + 0.5)
            stackIndex = stackIndex + 1
            stack[stackIndex] = formatColorToNumber(color, whiteNumber)
            stackIndex = stackIndex + 1
            
            if pixelsCacheExists then
                pixelsCache = {}
                pixelsCacheExists = false
            end
        end,
        fillCircle = function (x, y, r, color)
            if r > 1024 then r = 1024 end
            
            stack[stackIndex] = 7
            stackIndex = stackIndex + 1
            stack[stackIndex] = math_floor(x + 0.5)
            stackIndex = stackIndex + 1
            stack[stackIndex] = math_floor(y + 0.5)
            stackIndex = stackIndex + 1
            stack[stackIndex] = math_floor(r + 0.5)
            stackIndex = stackIndex + 1
            stack[stackIndex] = formatColorToNumber(color, whiteNumber)
            stackIndex = stackIndex + 1
            
            if pixelsCacheExists then
                pixelsCache = {}
                pixelsCacheExists = false
            end
        end,
        drawCircleEvenly = function (x, y, r, color)
            if r > 1024 then r = 1024 end

            stack[stackIndex] = 8
            stackIndex = stackIndex + 1
            stack[stackIndex] = math_floor(x + 0.5)
            stackIndex = stackIndex + 1
            stack[stackIndex] = math_floor(y + 0.5)
            stackIndex = stackIndex + 1
            stack[stackIndex] = math_floor(r + 0.5)
            stackIndex = stackIndex + 1
            stack[stackIndex] = formatColorToNumber(color, whiteNumber)
            stackIndex = stackIndex + 1
            
            if pixelsCacheExists then
                pixelsCache = {}
                pixelsCacheExists = false
            end
        end,
        flush = function()
            local stachSum = stackChecksum(stack)
            if stachSum ~= oldStackSum then
                dataTunnel.display_stack = stack
                dataTunnel.display_flush = clearStack
                oldStackSum = stachSum
            end
        end,
        forceFlush = function()
            api.flush()
            dataTunnel.display_forceFlush = true
        end,


        -- settings
        setUtf8Support = function (state)
            if type(state) == "boolean" then
                if dataTunnel.utf8support ~= state then
                    dataTunnel.utf8support = state
                    dataTunnel.dataUpdated = true
                    utf8support = state
                end
            else
                error("Type must be boolean", 2)
            end
        end,
        getUtf8Support = function () return dataTunnel.utf8support end,

        setRenderAtDistance = function (c)
            if type(c) == "boolean" then
                if dataTunnel.renderAtDistance ~= c then
                    dataTunnel.renderAtDistance = c
                    dataTunnel.dataUpdated = true
                end
            else
                error("Type must be boolean", 2)
            end
        end,
        getRenderAtDistance = function () return dataTunnel.renderAtDistance end,

        setRotation = function (rotation)
            if type(rotation) == "number" and rotation % 1 == 0 and rotation >= 0 and rotation <= 3 then
                if rotation ~= dataTunnel.rotation then
                    dataTunnel.rotation = rotation
                    dataTunnel.dataUpdated = true

                    if pixelsCacheExists then
                        pixelsCache = {}
                        pixelsCacheExists = false
                    end

                    if rotation == 1 or rotation == 3 then
                        rwidth = height
                        rheight = width
                    else
                        rwidth = width
                        rheight = height
                    end
                    rmheight = rheight - 1
                    rmwidth = rwidth - 1
                end
            else
                error("integer must be in [0 3]", 2)
            end
        end,
        getRotation = function () return dataTunnel.rotation end,

        setFont = function (customFont)
            checkArg(1, customFont, "table", "nil")
            if customFont then
                checkFont(customFont)
                fontX, fontY = customFont.width, customFont.height
            else
                fontX, fontY = font.width, font.height
            end
            dataTunnel.customFont = customFont
            dataTunnel.dataUpdated = true
        end,
        getFontWidth = function ()
            return fontX
        end,
        getFontHeight = function ()
            return fontY
        end,

        setSkipAtLags = function(state)
            checkArg(1, state, "boolean")
            dataTunnel.skipAtLags = state
            dataTunnel.dataUpdated = true
        end,
        getSkipAtLags = function() return dataTunnel.skipAtLags end,

        setSkipAtNotSight = function (state)
            checkArg(1, state, "boolean")
            dataTunnel.skipAtNotSight = state
            dataTunnel.dataUpdated = true
        end,
        getSkipAtNotSight = function () return dataTunnel.skipAtNotSight end,

        reset = function()
            if api.setFont then api.setFont() end
            if api.setRotation then api.setRotation(0) end
            if api.setUtf8Support then api.setUtf8Support(false) end
            if api.setClicksAllowed then api.setClicksAllowed(false) end
            if api.setMaxClicks then api.setMaxClicks(16) end
            if api.clearClicks then api.clearClicks() end
            if api.setSkipAtLags then api.setSkipAtLags(true) end
            if api.setSkipAtNotSight then api.setSkipAtNotSight(false) end
            if api.setRenderAtDistance then api.setRenderAtDistance(false) end
            dataTunnel.display_reset = true
        end
    }
    api.update = api.flush

    return api
end

--adds a touch screen API (does not implement click processing)
function canvasAPI.addTouch(api, dataTunnel)
    dataTunnel = dataTunnel or {}
    dataTunnel.clicksAllowed = false
    dataTunnel.maxClicks = 16
    dataTunnel.clickData = {}

    api.getClick = function ()
        return (table_remove(dataTunnel.clickData, 1))
    end

    api.setMaxClicks = function (c)
        if type(c) == "number" and c % 1 == 0 and c > 0 and c <= 16 then
            dataTunnel.maxClicks = c
        else
            error("integer must be in [1 16]", 2)
        end
    end

    api.getMaxClicks = function ()
        return dataTunnel.maxClicks
    end

    api.clearClicks = function ()
        dataTunnel.clickData = {}
    end

    api.setClicksAllowed = function (c)
        if type(c) == "boolean" then
            if dataTunnel.clicksAllowed ~= c then
                dataTunnel.clicksAllowed = c
                dataTunnel.dataUpdated = true
            end
        else
            error("Type must be boolean", 2)
        end
    end

    api.getClicksAllowed = function ()
        return dataTunnel.clicksAllowed
    end

    return function (tbl)
        table_insert(dataTunnel.clickData, tbl)
    end
end

--leaves only those tunnel fields that are needed for transmission over the network
function canvasAPI.minimizeDataTunnel(dataTunnel)
    return {
        clicksAllowed = dataTunnel.clicksAllowed,
        rotation = dataTunnel.rotation,
        renderAtDistance = dataTunnel.renderAtDistance,
        skipAtNotSight = dataTunnel.skipAtNotSight,
        skipAtLags = dataTunnel.skipAtLags,
        utf8support = dataTunnel.utf8support,
        customFont = dataTunnel.customFont,
        display_reset = dataTunnel.display_reset
    }
end

-------- additional
canvasAPI.stackChecksum = stackChecksum
canvasAPI.formatColor = formatColor
canvasAPI.formatColorToNumber = formatColorToNumber
canvasAPI.checkFont = checkFont
canvasAPI.remathRect = remathRect
canvasAPI.hexToRGB = hexToRGB
canvasAPI.posCheck = posCheck
canvasAPI.mathDist = mathDist
canvasAPI.needPushStack = needPushStack
canvasAPI.font = font
canvasAPI.tableClone = tableClone

function canvasAPI.pushData(stack, ...)
    for i, v in ipairs({...}) do
        table.insert(stack, v)
    end
end

sm.canvas = canvasAPI