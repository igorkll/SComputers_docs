local type = type
local _utf8_code = utf8.code
local _utf8_sub = utf8.sub
local _utf8_len = utf8.len
local string_sub = string.sub
local string_len = string.len
local math_floor = math.floor
local string_char = string.char
local string_byte = string.byte
local ipairs = ipairs
local pairs = pairs
local table_insert = table.insert

local font_chars = sc.display.font.optimized
local font_width = sc.display.font.width
local font_height = sc.display.font.height



local function loadChar(font, c)
	local chars = font and font.chars or font_chars
	local pixels = chars[c]
	if not pixels and type(c) == "number" then
		pixels = chars[string_char(c)]
	end
	if pixels then return pixels end
	return chars.error or font_chars.error
end

local function drawChar(self, font, drawPixel, x, y, c, color)
	local pixels = loadChar(font, c)
	local v
	for i = 1, #pixels do
		v = pixels[i]
		drawPixel(self, x + v[1], y + v[2], color)
	end
end

function basegraphic_checkFont(font)
	if type(font) ~= "table" then
		error("the font should be a table", 3)
	end
	if type(font.chars) ~= "table" or type(font.width) ~= "number" or type(font.height) ~= "number" then
		error("font failed integrity check", 3)
	end
	if font.width > 32 then
		error("the font width should not exceed 32", 3)
	end
	if font.height > 32 then
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

function basegraphic_printText(font, utf8support, self, drawPixel, drawPixelForce, x, y, width, height, text, color)
    x = math_floor(x)
	y = math_floor(y)

    local font_width = font and font.width or font_width
	local font_height = font and font.height or font_height

    if not self.printData or font ~= self.printData_old_font or utf8support ~= self.printData_old_utf8support then
        self.printData = {textcache = {}, textcount = 0}
        self.printData_old_font = font
        self.printData_old_utf8support = utf8support
    end
    local printData = self.printData

    if printData.textcache[text] then
        local dat, px, py = printData.textcache[text]
        for i = 1, dat.n do
            px, py = x + dat[i][1], y + dat[i][2]
            if px >= (width + font_width) then
                return
            end
            if px >= 0 and py >= 0 and px < width and py < height then
                drawPixelForce(self, px, py, color)
            end
        end
        return
    end

	local sub, flen, byte
	if utf8support then
		sub = _utf8_sub
		flen = _utf8_len
		byte = _utf8_code
	else
		sub = string_sub
		flen = string_len
		byte = string_byte
	end

	local len = flen(text)

	if x < 0 then
		local ic = 1
		while x + font_width < 0 do
			x = x + font_width + 1
			ic = ic + 1
			if ic > len or x >= width then
				return
			end
		end
		drawChar(self, font, drawPixel, x, y, sub(text, ic, ic), color)
		x = x + font_width + 1
		text = sub(text, ic + 1, len)
		len = len - ic
	end

	--старый вариант
	--if y >= 0 and (y + font_height) < self.height then
    --вот допустим размер шрифта по вертикали 1, в таком случаи предельное значения(например 127) окажеться не в пределах, так как 127 + 1 это 128, а 128 не меньше 128
	
	local ex, c
	if y >= 0 and (y + font_height) <= height then
		for i = 1, len do
			c = byte(text, i)

			ex = x + font_width
			if ex < width then
				drawChar(self, font, drawPixelForce, x, y, c, color)
			else
				drawChar(self, font, drawPixel, x, y, c, color)
				break
			end
			x = ex + 1
		end
	else
		for i = 1, len do
			c = byte(text, i)

			ex = x + font_width
			drawChar(self, font, drawPixel, x, y, c, color)
			if ex >= width then
				break
			end
			x = ex + 1
		end
	end

    if printData.textcount >= 256 then
        for key in pairs(printData.textcache) do
            printData.textcache[key] = nil
            break
        end
        printData.textcount = printData.textcount - 1
    end

    ex = {}
    local tbli = 1
    for i = 1, flen(text) do
        c = loadChar(font, byte(text, i))
        for i2 = 1, #c do
            ex[tbli] = {c[i2][1] + ((i - 1) * (font_width + 1)), c[i2][2]}
            tbli = tbli + 1
        end
    end
    ex.n = #ex
    printData.textcache[text] = ex
    printData.textcount = printData.textcount + 1
end