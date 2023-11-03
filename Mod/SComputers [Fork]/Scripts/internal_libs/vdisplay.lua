local vdisplay = {}

--local checkArg = checkArg
local math_floor = math.floor
local _utf8_code = utf8.code
local _utf8_sub = utf8.sub
local _utf8_len = utf8.len
local string_sub = string.sub
local string_len = string.len
local string_byte = string.byte
local string_char = string.char
local basegraphic_printText = basegraphic_printText
local formatColor = sc.formatColor
local formatColorStr = sc.formatColorStr

function vdisplay.create(callbacks, width, height)
    local dsp
    local maxClicks
    local rotation
    local skipAtNotSight
    local utf8support
    local renderAtDistance
    local skipAtLags
    local clicksAllowed
    local font, font_width, font_height
    local ffont = nil --шрифт в формете {chars = chars, width = width, height = height}
    
    local currentColors = {}
    local currentColor

    local fakeself = {}
    local needFlush = true

    local function makeFFont()
        ffont = {chars = font, width = font_width, height = font_height}
    end

    local function reset()
        maxClicks = 16
        rotation = 0
        skipAtNotSight = false
        utf8support = false
        renderAtDistance = false
        skipAtLags = true
        clicksAllowed = false

        font = sc.display.font.optimized
        font_width = sc.display.font.width
        font_height = sc.display.font.height
        makeFFont()
    end

    local function flush(isForce)
        if callbacks.flush and (isForce or needFlush) then
            callbacks.flush(dsp, isForce)
            needFlush = false
        end
    end

    local function set(_, x, y, color)
        x = math_floor(x + 0.5)
        y = math_floor(y + 0.5)
        color = formatColorStr(color)

        local rmaxX = width
        local rmaxY = height
        local reverseX, reverseY, changeXY

        if rotation == 1 then
            changeXY = true
            reverseX = true
        elseif rotation == 2 then
            reverseX = true
            reverseY = true
        elseif rotation == 3 then
            changeXY = true
            reverseY = true
        end

        if changeXY then
            x, y = y, x
            --rmaxX, rmaxY = rmaxY, rmaxX
            --sizeX, sizeY = sizeY, sizeX
        end
        if reverseX then x = (rmaxX - x) - 1 end
        if reverseY then y = (rmaxY - y) - 1 end
        
        --[[
        if x < 0 then x = 0 end
        if y < 0 then y = 0 end
        if x >= rmaxX then x = rmaxX - 1 end
        if y >= rmaxY then y = rmaxY - 1 end
        ]]

        if x >= 0 and y >= 0 and x < rmaxX and y < rmaxY and callbacks.set then
            if (currentColors[x + (y * width)] or currentColor) ~= color then
                callbacks.set(dsp, x, y, color)
                currentColors[x + (y * width)] = color
                needFlush = true
            end
        end
    end

    local function setForce(_, x, y, color)
        color = formatColorStr(color)

        local rmaxX = width
        local rmaxY = height
        local reverseX, reverseY, changeXY

        if rotation == 1 then
            changeXY = true
            reverseX = true
        elseif rotation == 2 then
            reverseX = true
            reverseY = true
        elseif rotation == 3 then
            changeXY = true
            reverseY = true
        end

        if changeXY then
            x, y = y, x
            --rmaxX, rmaxY = rmaxY, rmaxX
            --sizeX, sizeY = sizeY, sizeX
        end
        if reverseX then x = (rmaxX - x) - 1 end
        if reverseY then y = (rmaxY - y) - 1 end
        
        --[[
        if x < 0 then x = 0 end
        if y < 0 then y = 0 end
        if x >= rmaxX then x = rmaxX - 1 end
        if y >= rmaxY then y = rmaxY - 1 end
        ]]

        if callbacks.set and ((currentColors[x + (y * width)] or currentColor) ~= color) then
            callbacks.set(dsp, x, y, color)
            currentColors[x + (y * width)] = color
            needFlush = true
        end
    end

    local function putpixel(cx, cy, x, y, color, fill)
        if fill then
            for ix = 0, x do
                for iy = 0, y do
                    putpixel(cx, cy, ix, iy, color)
                end
            end
        else
            local posDX_x = cx + x
            local negDX_x = cx - x
            local posDX_y = cx + y
            local negDX_y = cx - y
        
            local posDY_y = cy + y
            local negDY_y = cy - y
            local posDY_x = cy + x
            local negDY_x = cy - x
        
            set(nil, posDX_x, posDY_y, color)
            set(nil, negDX_x, posDY_y, color)
            set(nil, posDX_x, negDY_y, color)
            set(nil, negDX_x, negDY_y, color)
            set(nil, posDX_y, posDY_x, color)
            set(nil, negDX_y, posDY_x, color)
            set(nil, posDX_y, negDY_x, color)
            set(nil, negDX_y, negDY_x, color)
        end
    end
    
    --[[
    local function loadChar(c)
        local pixels = font[c]
        if not pixels and type(c) == "number" then
            pixels = font[string_char(c)]
        end
        if pixels then return pixels end
        return font.error or dfont.error
    end

    local function drawChar(x, y, c, color)
        local pixels = loadChar(c)
        local v
        for i = 1, #pixels do
            v = pixels[i]
            set(nil, x + v[1], y + v[2], color)
        end
    end
    ]]

    reset()

    dsp = {
        getWidth = function ()
            if rotation == 1 or rotation == 3 then
				return height
			else
				return width
			end
        end,
        getHeight = function ()
            if rotation == 1 or rotation == 3 then
				return width
			else
				return height
			end
        end,

        reset = reset,
        isAllow = function () --there are no restrictions on the size of the virtual display
            return true
        end,
        optimize = function ()
        end,
        getClick = function ()
            return nil
        end,
        clearClicks = function ()
        end,


        setMaxClicks = function (c)
            if type(c) == "number" and c % 1 == 0 and c > 0 and c <= 16 then
				maxClicks = c
			else
				error("integer must be in [1; 16]", 2)
			end
        end,
        getMaxClicks = function ()
            return maxClicks
        end,

        setRotation = function (value)
            if type(value) == "number" and value % 1 == 0 and value >= 0 and value <= 3 then
				rotation = value
			else
				error("integer must be in [0; 3]", 2)
			end
        end,
        getRotation = function ()
            return rotation
        end,

        setClicksAllowed = function (state)
            --checkArg(1, state, "boolean")
            clicksAllowed = state
        end,
        getClicksAllowed = function ()
            return clicksAllowed
        end,

        setSkipAtLags = function (state)
            --checkArg(1, state, "boolean")
            skipAtLags = state
        end,
        getSkipAtLags = function ()
            return skipAtLags
        end,

        setSkipAtNotSight = function (state)
            --checkArg(1, state, "boolean")
            skipAtNotSight = state
        end,
        getSkipAtNotSight = function ()
            return skipAtNotSight
        end,

        setFrameCheck = function (state) end, --legacy (stub)
        getFrameCheck = function () return true end, --legacy (stub)

        setRenderAtDistance = function (state)
            --checkArg(1, state, "boolean")
            renderAtDistance = state
        end,
        getRenderAtDistance = function ()
            return renderAtDistance
        end,

        setUtf8Support = function (state)
			if type(state) == "boolean" then
				utf8support = state
			else
				error("Type must be boolean", 2)
			end
		end,
		getUtf8Support = function ()
            return utf8support
        end,

        setFont = function (cfont)
			--checkArg(1, cfont, "table", "nil")
			if cfont then
				if not cfont.chars or not cfont.width or not cfont.height then
					error("font failed integrity check", 2)
				end

                font = sc.display.optimizeFont(cfont.chars, cfont.width, cfont.height)
                font_width = cfont.width
                font_height = cfont.height
			else
				font = sc.display.font.optimized
                font_width = sc.display.font.width
                font_height = sc.display.font.height
			end
            makeFFont()
		end,

		getFontWidth = function ()
			return font_width
		end,

		getFontHeight = function ()
			return font_height
		end,

        flush = flush,
        update = flush,
        forceFlush = function ()
            flush(true)
        end,

        clear = function (color)
            --checkArg(1, color, "Color", "string", "nil")
            color = formatColorStr(color, true)

            if callbacks.clear then
                callbacks.clear(dsp, color)
            end
            needFlush = true
            currentColors = {}
            currentColor = color
        end,
        drawPixel = function (x, y, color)
            --checkArg(1, x, "number")
            --checkArg(2, y, "number")
            --checkArg(3, color, "Color", "string", "nil")
            set(nil, x, y, color)
        end,
        fillRect = function (x, y, w, h, color)
            --checkArg(1, x, "number")
            --checkArg(2, y, "number")
            --checkArg(3, w, "number")
            --checkArg(4, h, "number")
            --checkArg(5, color, "Color", "string", "nil")

            w = (w + x) - 1
            h = (h + y) - 1
            for cx = x, w do
                for cy = y, h do
                    set(nil, cx, cy, color)
                end
            end
        end,
        drawRect = function (x, y, w, h, color)
            --checkArg(1, x, "number")
            --checkArg(2, y, "number")
            --checkArg(3, w, "number")
            --checkArg(4, h, "number")
            --checkArg(5, color, "Color", "string", "nil")

            w = (w + x) - 1
            h = (h + y) - 1
            for cx = x, w do
                for cy = y, h do
                    if (cx == x or cx == w) or (cy == y or cy == h) then
                        set(nil, cx, cy, color)
                    end
                end
            end
        end,

        drawLine = function (x, y, x1, y1, color)
            x = math_floor(x)
            y = math_floor(y)
            x1 = math_floor(x1)
            y1 = math_floor(y1)

            local dx = math.abs(x1 - x)
            local sx = x < x1 and 1 or -1
            local dy = -math.abs(y1 - y)
            local sy = y < y1 and 1 or -1

            local error = dx + dy
            local e2
            while true do
                sc.yield()

                set(nil, x, y, color)

                if x == x1 and y == y1 then break end
                e2 = error * 2
                if e2 >= dy then
                    if x == x1 then break end
                    error = error + dy
                    x = x + sx
                end
                if e2 <= dx then
                    if y == y1 then break end
                    error = error + dx
                    y = y + sy
                end
            end
        end,
        fillCircle = function (x, y, r, color)
            x = math_floor(x + 0.5)
            y = math_floor(y + 0.5)
            r = math_floor(r - 1)
        
            local lx = 0
            local ly = r
            local d = 3 - 2 * r
        
            putpixel(x, y, lx, ly, color, true)
        
            while ly >= lx do
                sc.yield()

                lx = lx + 1
        
                if d > 0 then
                    ly = ly - 1
                    d = d + 4 * (lx - ly) + 10
                else
                    d = d + 4 * lx + 6
                end
        
                putpixel(x, y, lx, ly, color, true)
            end
        end,
        drawCircle = function (x, y, r, color)
            x = math_floor(x + 0.5)
            y = math_floor(y + 0.5)
            r = math_floor(r)
        
            local lx = 0
            local ly = r
            local d = 3 - 2 * r
        
            putpixel(x, y, lx, ly, color)
        
            while ly >= lx do
                sc.yield()

                lx = lx + 1
        
                if d > 0 then
                    ly = ly - 1
                    d = d + 4 * (lx - ly) + 10
                else
                    d = d + 4 * lx + 6
                end
        
                putpixel(x, y, lx, ly, color)
            end
        end,

        drawText = function (x, y, text, color)
            basegraphic_printText(ffont, utf8support, fakeself, set, setForce, x, y, dsp.getWidth(), dsp.getHeight(), text, color)
            --[[
            x = math_floor(x)
            y = math_floor(y)

            local sub, len, byte
            if utf8support then
                sub = _utf8_sub
                len = _utf8_len
                byte = _utf8_code
            else
                sub = string_sub
                len = string_len
                byte = string_byte
            end

            local len = len(text)
            local font_width = font_width
            local font_height = font_height
            local width = dsp.getWidth()

            if x < 0 then
                local ic = 1
                while x + font_width < 0 do
                    x = x + font_width + 1
                    ic = ic + 1
                    if ic > len or x >= width then
                        return
                    end
                end
                drawChar(x, y, sub(text, ic, ic), color)
                x = x + font_width + 1
                text = sub(text, ic + 1, len)
                len = len - ic
            end

            --старый вариант
            --if y >= 0 and (y + font_height) < self.height then
            --вот допустим размер шрифта по вертикали 1, в таком случаи предельное значения(например 127) окажеться не в пределах, так как 127 + 1 это 128, а 128 не меньше 128
            
            local height = dsp.getHeight()
            local ex, c
            if y >= 0 and (y + font_height) <= height then
                for i = 1, len do
                    c = byte(text, i)

                    ex = x + font_width
                    if ex < width then
                        drawChar(x, y, c, color)
                    else
                        drawChar(x, y, c, color)
                        break
                    end
                    x = ex + 1
                end
            else
                for i = 1, len do
                    c = byte(text, i)

                    ex = x + font_width
                    drawChar(x, y, c, color)
                    if ex >= width then
                        break
                    end
                    x = ex + 1
                end
            end
            ]]
        end
    }

    return dsp
end

sc.reg_internal_lib("vdisplay", vdisplay)
return vdisplay