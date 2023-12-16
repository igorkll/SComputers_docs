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

local math_max = math.max
local math_min = math.min

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
local basegraphic_printText = basegraphic_printText

function basegraphic_drawLine(x, y, x1, y1, color, width, height, buffer1)
	x = math_floor(x)
	y = math_floor(y)
	x1 = math_floor(x1)
	y1 = math_floor(y1)

	local sign_x, sign_y

	local clip_xmin = 0
	local clip_xmax = width - 1

	local clip_ymin = 0
	local clip_ymax = height - 1

	if x == x1 then
		if x < clip_xmin or x > clip_xmax then return end

		if y <= y1 then
			if y1 < clip_ymin or y > clip_xmax then return end

			y = math_max(y, clip_ymin)
			y1 = math_min(y1, clip_ymax)

			for iy = y, y1 do
				buffer1[x + (iy * width)] = color
			end
		else
			if y < clip_ymin or y1 > clip_ymax then return end

			y1 = math_max(y1, clip_ymin)
			y = math_min(y, clip_ymax)

			for iy = y, y1, -1 do
				buffer1[x + (iy * width)] = color
			end
		end

		return
	end

	if y == y1 then
		if y < clip_ymin or y > clip_ymax then return end

		if x <= x1 then
			if x1 < clip_xmin or x > clip_xmax then return end

			x = math_max(x, clip_xmin)
			x1 = math_min(x1, clip_xmax)

			for ix = x, x1 do
				buffer1[ix + (y * width)] = color
			end
		else
			if x < clip_xmin or x1 > clip_xmax then return end

			x1 = math_max(x1, clip_xmin)
			x = math_min(x, clip_xmax)

			for ix = x, x1, -1 do
				buffer1[ix + (y * width)] = color
			end
		end

		return
	end

	if x < x1 then
		if x > clip_xmax or x1 < clip_xmin then return end
		sign_x = 1
	else
		if x1 > clip_xmax or x < clip_xmin then return end
		x = -x
		x1 = -x1
		clip_xmin, clip_xmax = -clip_xmax, -clip_xmin

		sign_x = -1
	end

	if y < y1 then
		if y > clip_ymax or y1 < clip_ymin then return end
		sign_y = 1
	else
		if y1 > clip_ymax or y < clip_ymin then return end
		y = -y
		y1 = -y1
		clip_ymin, clip_ymax = -clip_ymax, -clip_ymin

		sign_y = -1
	end

	local delta_x = x1 - x
	local delta_y = y1 - y

	local delta_x_step = 2 * delta_x
	local delta_y_step = 2 * delta_y

	local xpos = x
	local ypos = y

	if delta_x >= delta_y then
		local error = delta_y_step - delta_x
		local exit = false

		if y < clip_ymin then
			local temp = (2 * (clip_ymin - y) - 1) * delta_x
			local msd = math_floor(temp / delta_y_step)

			xpos = xpos + msd

			if xpos > clip_xmax then return end

			if xpos >= clip_xmin then
				local rem = temp - msd * delta_y_step

				ypos = clip_ymin
				error = error - rem - delta_x

				if rem > 0 then
					xpos = xpos + 1
					error = error + delta_y_step
				end

				exit = true
			end
		end

		if not exit and x < clip_xmin then
			local temp = delta_y_step * (clip_xmin - x)
			local msd = math_floor(temp / delta_x_step)

			ypos = ypos + msd
			local rem = temp % delta_x_step

			if ypos > clip_ymax or (ypos == clip_ymax and rem >= delta_x) then return end

			xpos = clip_xmin
			error = error + rem

			if rem >= delta_x then
				ypos = ypos + 1
				error = error - delta_x_step
			end
		end

		local xpos_end = x1

		if y1 > clip_ymax then
			local temp = delta_x_step * (clip_ymax - y) + delta_x
			local msd = math_floor(temp / delta_y_step)

			xpos_end = x + msd

			if (temp - msd * delta_y_step) == 0 then
				xpos_end = xpos_end - 1
			end
		end

		xpos_end = math_min(xpos_end, clip_xmax) + 1

		if sign_y == -1 then 
			ypos = -ypos 
		end
		if sign_x == -1 then -- TODO * sign
			xpos = -xpos
			xpos_end = -xpos_end
		end

		delta_x_step = delta_x_step - delta_y_step

		while xpos ~= xpos_end do
			buffer1[xpos + (ypos * width)] = color

			if error >= 0 then
				ypos = ypos + sign_y
				error = error - delta_x_step
			else
				error = error + delta_y_step
			end

			xpos = xpos + sign_x
		end
	else
		local error = delta_x_step - delta_y
		local exit = false

		if x < clip_xmin then
			local temp = (2 * (clip_xmin - x) - 1) * delta_y
			local msd = math_floor(temp / delta_x_step)
			ypos = ypos + msd

			if ypos > clip_ymax then return end

			if ypos >= clip_ymin then
				local rem = temp - msd * delta_x_step

				xpos = clip_xmin
				error = error - rem - delta_y

				if rem > 0 then
					ypos = ypos + 1
					error = error + delta_x_step
				end

				exit = true
			end
		end

		if not exit and y < clip_ymin then
			local temp = delta_x_step * (clip_ymin - y)
			local msd = math_floor(temp / delta_y_step)

			xpos = xpos + msd

			local rem = temp % delta_y_step

			if xpos > clip_xmax or (xpos == clip_xmax and rem >= delta_y) then return end

			ypos = clip_ymin
			error = error + rem

			if rem >= delta_y then
				xpos = xpos + 1
				error = error - delta_y_step
			end
		end

		local ypos_end = y1

		if x1 > clip_xmax then
			local temp = delta_y_step * (clip_xmax - x) + delta_y
			local msd = math_floor(temp / delta_x_step)

			ypos_end = y + msd

			if (temp - msd * delta_x_step) == 0 then
				ypos_end = ypos_end - 1
			end
		end

		ypos_end = math_min(ypos_end, clip_ymax) + 1

		if sign_x == -1 then -- TODO * sign
			xpos = -xpos
		end
		if sign_y == -1 then
			ypos = -ypos
			ypos_end = -ypos_end
		end

		delta_y_step = delta_y_step - delta_x_step

		while ypos ~= ypos_end do
			buffer1[xpos + (ypos * width)] = color

			if error >= 0 then
				xpos = xpos + sign_x
				error = error - delta_y_step
			else
				error = error + delta_x_step
			end

			ypos = ypos + sign_y
		end
	end
end
local basegraphic_drawLine = basegraphic_drawLine

local function quadInCircle(qx, qy, qs, cx, cy, cr)
	local lx = qx - cx
	local ly = qy - cy

	local cr_sq = cr*cr

	local pointIn = function (dx, dy)
		return dx*dx + dy*dy <= cr_sq
	end

	return pointIn(lx, ly) and pointIn(lx + qs, ly) and pointIn(lx, ly + qs) and pointIn(lx + qs, ly + qs)
end

local formatColor = sc.formatColor
function basegraphic_doubleBuffering(self, stack, width, height, font, utf8support, flush)
	local newstack = {}
	local newstackI = 1
	local maxBuf = (width * height) - 1
	local buffer1, buffer2 = self.buffer1, self.buffer2

	if stack then
		local function draw(_, x, y, color)
			if x >= 0 and y >= 0 and x < width and y < height then
				buffer1[math_floor(x) + (math_floor(y) * width)] = color
			end
		end

		local function drawCircle_putpixel(cx, cy, x, y, color)
			local posDX_x = cx + x
			local negDX_x = cx - x
			local posDX_y = cx + y
			local negDX_y = cx - y
		
			local posDY_y = cy + y
			local negDY_y = cy - y
			local posDY_x = cy + x
			local negDY_x = cy - x
		
			draw(nil, posDX_x, posDY_y, color)
			draw(nil, negDX_x, posDY_y, color)
			draw(nil, posDX_x, negDY_y, color)
			draw(nil, negDX_x, negDY_y, color)
			draw(nil, posDX_y, posDY_x, color)
			draw(nil, negDX_y, posDY_x, color)
			draw(nil, posDX_y, negDY_x, color)
			draw(nil, negDX_y, negDY_x, color)
		end

		local col
		for _, v in ipairs(stack) do
			col = formatColor(v[2], v[1] == 0)

			if v[1] == 0 then
				buffer1 = {}
				self.buffer1 = buffer1
				self.buffer1All = col
			elseif v[1] == 1 then
				buffer1[v[3] + (v[4] * width)] = col
			elseif v[1] == 2 then
				for ix = v[3], v[3] + (v[5] - 1) do
					for iy = v[4], v[4] + (v[6] - 1) do
						if ix == v[3] or iy == v[4] or ix == (v[3] + (v[5] - 1)) or iy == (v[4] + (v[6] - 1)) then
							buffer1[ix + (iy * width)] = col
						end
					end
				end
			elseif v[1] == 3 then
				for ix = v[3], v[3] + (v[5] - 1) do
					for iy = v[4], v[4] + (v[6] - 1) do
						buffer1[ix + (iy * width)] = col
					end
				end
			elseif v[1] == 4 then
				local x = v[3]
				local y = v[4]
				local r = v[5]

				local lx = 0
				local ly = r
				local d = 3 - 2 * r

				drawCircle_putpixel(x, y, lx, ly, col)
				while ly >= lx do
					lx = lx + 1

					if d > 0 then
						ly = ly - 1
						d = d + 4 * (lx - ly) + 10
					else
						d = d + 4 * lx + 6
					end

					drawCircle_putpixel(x, y, lx, ly, col)
				end
			elseif v[1] == 5 then
				local nx, ny = v[3], v[4]
				local x = math_floor(v[3])
				local y = math_floor(v[4])
				local r = v[5]

				local cx, cy = math_min(r, 1024), math_min(r, 1024)
				local px, py
				for ix = math_max(-cx, -x), math_min(cx, (width - x) - 1) do
					px = x + ix
					for iy = math_max(-cy, -y), math_min(cy, (height - y) - 1) do
						py = y + iy
						if quadInCircle(px, py, 1, nx, ny, r) then
							buffer1[px + (py * width)] = col
						end
					end
				end
			elseif v[1] == 6 then
				basegraphic_drawLine(v[3], v[4], v[5], v[6], col, width, height, buffer1)
			elseif v[1] == 7 then
				basegraphic_printText(font, utf8support, self, draw, draw, v[3], v[4], width, height, v[5], col)
			end
		end
	end

	if flush then
		local buffer1All = self.buffer1All
		local buffer2All = self.buffer2All
		for i = 0, maxBuf do
			local col = buffer1[i] or buffer1All
			if col ~= (buffer2[i] or buffer2All) then
				newstack[newstackI] = math_floor(i % width)
				newstackI = newstackI + 1

				newstack[newstackI] = math_floor(i / width)
				newstackI = newstackI + 1

				newstack[newstackI] = col
				newstackI = newstackI + 1

				buffer2[i] = col
			end
		end
	end

	return newstack, newstackI - 1
end