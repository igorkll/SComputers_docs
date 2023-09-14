if __displayBaseLoaded then return end
__displayBaseLoaded = true

dofile "$CONTENT_DATA/Scripts/Config.lua"
dofile "$CONTENT_DATA/Scripts/vnetwork.lua"

sc.display.drawType = {
	clear = 0,
	drawPixel = 1,
	drawRect = 2,
	fillRect = 3,
	drawCircle = 4,
	fillCircle = 5,
	drawLine = 6,
	drawText = 7,
	optimize = 8,
}

sc.display.PIXEL_SCALE = 0.0072
sc.display.RENDER_DISTANCE = 15
sc.display.SKIP_RENDER_DT = 1 / 24

local font_chars = sc.display.font.chars.optimized
local font_width = sc.display.font.width
local font_height = sc.display.font.height
local table_remove = table.remove
local table_insert = table.insert
local string_lower = string.lower
local math_floor = math.floor
local math_abs = math.abs
local math_min = math.min
local math_max = math.max

local quad_visibleRot = sm.quat.fromEuler(sm.vec3.zero())
local quad_hideRot = sm.quat.fromEuler(sm.vec3.new(0, 180, 0))

local quad_displayOffset = sm.vec3.new(-0.117, 0, 0)
local quad_offsetRotation = sm.quat.fromEuler(sm.vec3.new(0, 0, 0))

local vec3_new = sm.vec3.new
local util_clamp = sm.util.clamp
local sc_display_PIXEL_SCALE = sc.display.PIXEL_SCALE
local sc_display_shapeUuid = sm.uuid.new("41d7c8b2-e2de-4c29-b842-5efd8af37ae6")

local function hashValue(input, dopValue)
	local value = 0

	if type(input) == "table" then
		local ldop = 0
		for k, v in pairs(input) do
			ldop = ldop + 45
			value = value + hashValue(k, ldop)
			ldop = ldop + 22
			value = value + hashValue(v, ldop)
		end
	elseif type(input) == "number" then
		value = input
	elseif type(input) == "string" then
		for i = 1, #input do
			value = value + (input:byte(i) * i)
		end
	else
		value = 0
	end
	
	return value + (dopValue or 0)
end

function sc.display.createDisplay(scriptableObject, width, height, pixelScale)
	local display = {
		renderingStack = {},
		width = width,
		height = height,
		pixelScale = pixelScale,
		scriptableObject = scriptableObject,
		needUpdate = false,
		clickData = {},
		maxClicks = 16,
		needSendData = false,

		-- client
		currentZ = 0,
		effects = {},
		zValues = {},
		clicksAllowed = false,
		isRendering = false,
		renderAtDistance = false,
		skipAtLags = true,
		dragging = {interact=false, tinker=false, interactLastPos={x=-1, y=-1}, tinkerLastPos={x=-1, y=-1}},
	}
	return display
end

----------------------------------------------server main

function sc.display.server_init(self)
	sc.displaysDatas[self.scriptableObject.interactable:getId()] = sc.display.server_createData(self)
end

function sc.display.server_update(self)
	if self.needUpdate then
		local dbuffcode = hashValue(self.renderingStack)

		if not self.dbuffcode or self.dbuffcode ~= dbuffcode then
			self.renderingStack.endPack = true
			self.network = self.scriptableObject.network
			self.shape = self.scriptableObject.shape
			if not pcall(vnetwork.sendToClients, self, "client_onReceiveDrawStack", self.renderingStack, 16) then
				self.renderingStack.endPack = false
				
				local index = 1
				local count = 4096
				while true do
					local datapack = {unpack(self.renderingStack, index, index + (count - 1))}

					local continue
					index = index + count
					if index > #self.renderingStack + count then
						datapack.endPack = true
						if not pcall(vnetwork.sendToClients, self, "client_onReceiveDrawStack", datapack, 16) then
							index = index - count
							count = math.floor((count / 2) + 0.5)
							continue = true
						else
							break
						end
					end

					if not continue and not pcall(vnetwork.sendToClients, self, "client_onReceiveDrawStack", datapack, 16) then
						index = index - count
						count = math.floor((count / 2) + 0.5)
					end
				end
			end
			self.renderingStack = {}
		end
		self.dbuffcode = dbuffcode
		
		self.needUpdate = false
	end

	if self.needSendData then
		self.scriptableObject.network:sendToClients("client_onDataResponse", sc.display.server_createNetworkData(self))
	end
end

function sc.display.server_destroy(self)
	sc.displaysDatas[self.scriptableObject.interactable:getId()] = nil
end

function sc.display.server_createData(self)
	local data = {
		getWidth = function () return self.width end,
		getHeight = function () return self.height end,
		clear = function (c) sc.display.server_clear(self, c) end,
		drawPixel = function (x, y, c) sc.display.server_drawPixel(self, x, y, c) end,
		drawRect = function (x, y, w, h, c) sc.display.server_drawRect(self, x, y, w, h, c) end,
		fillRect = function (x, y, w, h, c) sc.display.server_fillRect(self, x, y, w, h, c) end,
		drawCircle = function (x, y, r, c) sc.display.server_drawCircle(self, x + 0.5, y + 0.5, r, c) end, -- +0.5 because center of pixel
		fillCircle = function (x, y, r, c) sc.display.server_fillCircle(self, x + 0.5, y + 0.5, r, c) end,
		drawLine = function (x, y, x1, y1, c) sc.display.server_drawLine(self, x, y, x1, y1, c) end,
		drawText = function (x, y, text, c) sc.display.server_drawText(self, x, y, text, c) end,
		optimize = function () sc.display.server_optimize(self) end,
		update = function () sc.display.server_flushStack(self) end,
		flush = function () sc.display.server_flushStack(self) end,
		
		getClick = function ()
			local res = table_remove(self.clickData, 1)
			return res
		end,
		setMaxClicks = function (c)
			if type(c) == "number" and c % 1 == 0 and c > 0 and c <= 16 then
				self.maxClicks = c
			else
				error("integer must be in [1; 16]")
			end
		end,
		getMaxClicks = function ()
			return self.maxClicks
		end,
		clearClicks = function ()
			self.clickData = {}
		end,



		setRenderAtDistance = function (state)
			if type(state) == "boolean" then
				if self.renderAtDistance ~= state then
					self.renderAtDistance = state
					self.needSendData = true
				end
			else
				error("Type must be boolean")
			end
		end,
		getRenderAtDistance = function ()
			return self.renderAtDistance
		end,
		setSkipAtLags = function (state)
			if type(state) == "boolean" then
				if self.skipAtLags ~= state then
					self.skipAtLags = state
					self.needSendData = true
				end
			else
				error("Type must be boolean")
			end
		end,
		getSkipAtLags = function ()
			return self.skipAtLags
		end,
		setClicksAllowed = function (state)
			if type(state) == "boolean" then
				if self.clicksAllowed ~= state then
					self.clicksAllowed = state
					self.needSendData = true
				end
			else
				error("Type must be boolean")
			end
		end,
		getClicksAllowed = function ()
			return self.clicksAllowed
		end
	}
	return data
end

function sc.display.server_createNetworkData(self)
	return {
		renderAtDistance = self.renderAtDistance,
		clicksAllowed = self.clicksAllowed,
		skipAtLags = self.skipAtLags,
	}
end

function sc.display.server_onDataRequired(self, client)
	self.scriptableObject.network:sendToClient(client, "client_onDataResponse", sc.display.server_createNetworkData(self))
end

----------------------------------------------server render methods

function sc.display.server_clear(self, color)
	self.renderingStack = {}
	table_insert(self.renderingStack, {
		type = sc.display.drawType.clear,
		color = color
	})
end

function sc.display.server_drawPixel(self, x, y, color)
	table_insert(self.renderingStack, {
		type = sc.display.drawType.drawPixel,
		x = x,
		y = y,
		color = color
	})
end

function sc.display.server_drawRect(self, x, y, w, h, color)
	table_insert(self.renderingStack, {
		type = sc.display.drawType.drawRect,
		x = x,
		y = y,
		w = w,
		h = h,
		color = color
	})
end

function sc.display.server_fillRect(self, x, y, w, h, color)
	table_insert(self.renderingStack, {
		type = sc.display.drawType.fillRect,
		x = x,
		y = y,
		w = w,
		h = h,
		color = color
	})
end

function sc.display.server_drawCircle(self, x, y, r, color)
	table_insert(self.renderingStack, {
		type = sc.display.drawType.drawCircle,
		x = x,
		y = y,
		r = r,
		color = color
	})
end

function sc.display.server_fillCircle(self, x, y, r, color)
	table_insert(self.renderingStack, {
		type = sc.display.drawType.fillCircle,
		x = x,
		y = y,
		r = r,
		color = color
	})
end

function sc.display.server_drawLine(self, x, y, x1, y1, color)
	table_insert(self.renderingStack, {
		type = sc.display.drawType.drawLine,
		x = x,
		y = y,
		x1 = x1,
		y1 = y1,
		color = color
	})
end

function sc.display.server_drawText(self, x, y, text, color)
	table_insert(self.renderingStack, {
		type = sc.display.drawType.drawText,
		x = x,
		y = y,
		text = text,
		color = color
	})
end

function sc.display.server_optimize(self)
	table_insert(self.renderingStack, {
		type = sc.display.drawType.optimize
	})
end

function sc.display.server_flushStack(self)
	self.needUpdate = true
end

----------------------------------------------client render methods

local function mathZValue(self, x, y, sizeX, sizeY)
	local zValue = 0
	for cx = x, x + (sizeX - 1) do
		for cy = y, y + (sizeY - 1) do
			if (self.zValues[cx + (cy * self.width)] or 0) > zValue then
				zValue = self.zValues[cx + (cy * self.width)] or 0
			end
		end
	end
	return zValue
end

local function createEffect(self, x, y, sizeX, sizeY, color)
	if x > self.width then x = self.width end
	if y > self.height then y = self.height end
	if x + sizeX > self.width then sizeX = sizeX - ((x + (sizeX)) - self.width) end
	if y + sizeY > self.height then sizeY = sizeY - ((y + (sizeY)) - self.height) end
	local tableIndex = x + (y * self.width)

	local zValue = mathZValue(self, x, y, sizeX, sizeY)
	if self.effects[tableIndex] then
		local effectsDatas = self.effects[tableIndex]
		for key, effectData in pairs(effectsDatas) do
			if sizeX >= effectData.sizeX and sizeY >= effectData.sizeY then
				if zValue ~= effectData.currentZ or
				effectData.sizeX ~= sizeX or effectData.sizeY ~= sizeY or
				effectData.x ~= x or effectData.y ~= y or effectData.color ~= color then
					effectData.effect:destroy()
					effectsDatas[key] = nil
					for cx = effectData.x, effectData.x + (effectData.sizeX - 1) do
						for cy = effectData.y, effectData.y + (effectData.sizeY - 1) do
							self.zValues[cx + (cy * self.width)] = self.zValues[cx + (cy * self.width)] - 1
						end
					end
				end
			end
		end
	end

	local effect = sm.effect.createEffect("ShapeRenderable", self.scriptableObject.interactable)

	zValue = mathZValue(self, x, y, sizeX, sizeY)
	if not self.effects[tableIndex] then
		self.effects[tableIndex] = {{
			x = x,
			y = y,
			sizeX = sizeX,
			sizeY = sizeY,
			color = color,
			effect = effect,
			currentZ = zValue
		}}
	else
		table.insert(self.effects[tableIndex], {
			x = x,
			y = y,
			sizeX = sizeX,
			sizeY = sizeY,
			color = color,
			effect = effect,
			currentZ = zValue
		})
	end

	effect:setParameter("uuid", sc_display_shapeUuid)
	local scale = sc_display_PIXEL_SCALE * self.pixelScale
	local vx = scale * sizeX + 1e-4
	local vy = scale * sizeY + 1e-4
	effect:setScale(vec3_new(0, vy + 0.002, vx + 0.002))
	local offset = vec3_new(-zValue, y - self.height/2 + sizeY/2, self.width/2 - x - sizeX/2) * scale
	effect:setOffsetPosition(quad_displayOffset + offset)
	effect:setParameter("color", color)
	effect:start()

	for cx = x, x + (sizeX - 1) do
		for cy = y, y + (sizeY - 1) do
	--for cx = x - 1, x + sizeX do
	--	for cy = y - 1, y + sizeY do

			if self.effects[cx + (cy * self.width)] then
				local eff = self.effects[cx + (cy * self.width)]
				
			end
			if cx >= 0 and cx < self.width and cy >= 0 and cy < self.height then
				self.zValues[cx + (cy * self.width)] = zValue + 1
			end
		end
	end
end

function sc.display.client_clear(self, color)
	for _, v in pairs(self.effects) do
		for _, obj in pairs(v) do
			if sm.exists(obj.effect) then
				obj.effect:destroy()
			end
		end
	end
	self.effects = {}
	self.zValues = {}

	createEffect(self, 0, 0, self.width, self.height, color)
end

function sc.display.client_drawPixelForce(self, x, y, color)
	createEffect(self, x, y, 1, 1, color)
end

function sc.display.client_drawPixel(self, x, y, color)
	x = math_floor(x)
	y = math_floor(y)

	if x >= 0 and x < self.width and y >= 0 and y < self.height then
		sc.display.client_drawPixelForce(self, x, y, color)
	end
end

function sc.display.client_drawRect(self, x, y, w, h, color)
	if x >= self.width then return end
	if y >= self.height then return end
	local lx = math_floor(x >= 0 and x or 0)
	
	local ly = math_floor(y >= 0 and y or 0)
	
	local lw = w - (lx - x)
	local lh = h - (ly - y)

	local rw = self.width - lx
	local rh = self.height - ly

	lw = math_floor(lw < rw and lw or rw)
	lh = math_floor(lh < rh and lh or rh)

	for i = lx,lx+lw-1 do
		sc.display.client_drawPixelForce(self, i, ly, color)
	end

	local ex = lx+lw-1
	for iy = ly+1, ly+lh-2 do
		sc.display.client_drawPixelForce(self, lx, iy, color)
		sc.display.client_drawPixelForce(self, ex, iy, color)
	end

	local ey = ly + lh - 1
	for i = lx,lx+lw-1 do
		sc.display.client_drawPixelForce(self, i, ey, color)
	end

end

function sc.display.client_fillRect(self, x, y, w, h, color)
	createEffect(self, math_floor(x), math_floor(y), math_floor(w), math_floor(h), color)
end

function sc.display.client_drawCircle(self, x, y, r, color)
	local floor = math_floor

	x = floor(x)
	y = floor(y)
	r = floor(r)

	local function put(self, cx, cy, x, y, color)
		local drawPixel = sc.display.client_drawPixel
		local draw = function (x, y) drawPixel(self, x, y, color) end
	
		local posDX_x = cx + x
		local negDX_x = cx - x
		local posDX_y = cx + y
		local negDX_y = cx - y
	
		local posDY_y = cy + y
		local negDY_y = cy - y
		local posDY_x = cy + x
		local negDY_x = cy - x
	
		draw(posDX_x, posDY_y)
		draw(negDX_x, posDY_y)
		draw(posDX_x, negDY_y)
		draw(negDX_x, negDY_y)
		draw(posDX_y, posDY_x)
		draw(negDX_y, posDY_x)
		draw(posDX_y, negDY_x)
		draw(negDX_y, negDY_x)
	end
	
	local lx = 0
	local ly = r
	local d = 3 - 2 * r

	put(self, x, y, lx, ly, color)

	while ly >= lx do
		lx = lx + 1

		if d > 0 then
			ly = ly - 1
			d = d + 4 * (lx - ly) + 10
		else
			d = d + 4 * lx + 6
		end

		put(self, x, y, lx, ly, color)
	end
end

function sc.display.client_fillCircle(self, x, y, r, color)
	--quad_treeFillCircle(self.quadTree, x, y, r, color)
end

function sc.display.client_drawLineForce(self, x, y, x1, y1, color)
	x = math_floor(x)
	y = math_floor(y)
	x1 = math_floor(x1)
	y1 = math_floor(y1)

	local dx = math_abs(x1 - x)
    local sx = x < x1 and 1 or -1
    local dy = -math_abs(y1 - y)
    local sy = y < y1 and 1 or -1

    local drawPixel = sc.display.client_drawPixelForce
    
    local error = dx + dy
    while true do
        drawPixel(self, x, y, color)

        if x == x1 and y == y1 then break end
        local e2 = error * 2
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
end

-- y = y0 + round( (x-x0) * dy / dx )
function sc.display.client_drawLine(self, x, y, x1, y1, color)
	x = math_floor(x)
	y = math_floor(y)
	x1 = math_floor(x1)
	y1 = math_floor(y1)

	local sign_x, sign_y

	local clip_xmin = 0
	local clip_xmax = self.width - 1

	local clip_ymin = 0
	local clip_ymax = self.height - 1

	local drawPixel = sc.display.client_drawPixelForce

	if x == x1 then
		if x < clip_xmin or x > clip_xmax then return end

		if y <= y1 then
			if y1 < clip_ymin or y > clip_xmax then return end

			y = math_max(y, clip_ymin)
			y1 = math_min(y1, clip_ymax)

			for iy = y, y1 do
				drawPixel(self, x, iy, color)
			end
		else
			if y < clip_ymin or y1 > clip_ymax then return end

			y1 = math_max(y1, clip_ymin)
			y = math_min(y, clip_ymax)

			for iy = y, y1, -1 do
				drawPixel(self, x, iy, color)
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
				drawPixel(self, ix, y, color)
			end
		else
			if x < clip_xmin or x1 > clip_xmax then return end

			x1 = math_max(x1, clip_xmin)
			x = math_min(x, clip_xmax)

			for ix = x, x1, -1 do
				drawPixel(self, ix, y, color)
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
			drawPixel(self, xpos, ypos, color)

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
			drawPixel(self, xpos, ypos, color)

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

function sc.display.client_drawCharForce(self, x, y, c, color)
	local chars = font_chars
	local pixels = chars[c]
	if pixels == nil then
		pixels = chars.error
	end

	local drawPixel = sc.display.client_drawPixelForce

	for i = 1, #pixels do
		local v = pixels[i]
		drawPixel(self, x + v[1], y + v[2], color)
	end
end

function sc.display.client_drawChar(self, x, y, c, color)
	x = math_floor(x)
	y = math_floor(y)

	local pixels = font_chars[c]
	if pixels == nil then
		pixels = font_chars.error
	end

	local drawPixel = sc.display.client_drawPixel

	for i = 1, #pixels do
		local v = pixels[i]
		drawPixel(self, x + v[1], y + v[2], color)
	end
end

function sc.display.client_drawText(self, x, y, text, color)
	local drawChar = sc.display.client_drawChar
	local drawCharForce = sc.display.client_drawCharForce


	text = string_lower(text)
	x = math_floor(x)
	y = math_floor(y)

	if x < 0 then
		local ic = 1
		while x + font_width < 0 do
			x = x + font_width + 1
			ic = ic + 1
		end
		drawChar(self, x, y, text:sub(ic, ic), color)
		x = x + font_width + 1
		text = text:sub(ic + 1, #text)
	end

	local ex
	if y >= 0 and (y + font_height) < self.height then
		for c in text:gmatch(".") do
			ex = x + font_width

			if ex < self.width then
				drawCharForce(self, x, y, c, color)
			else
				drawChar(self, x, y, c, color)
				break
			end

			x = ex + 1
		end
	else
		for c in text:gmatch(".") do
			ex = x + font_width

			drawChar(self, x, y, c, color)

			if ex >= self.width then
				break
			end

			x = ex + 1
		end
	end
end

function sc.display.client_optimize(self)
end

----------------------------------------------client main

function sc.display.client_init(self)
end

function sc.display.client_destroy(self)
	for _, v in pairs(self.effects) do
		for _, obj in pairs(v) do
			if sm.exists(obj.effect) then
				obj.effect:destroy()
			end
		end
	end
end

function sc.display.client_update(self, dt)
	local localPlayer = sm.localPlayer.getPlayer().character

	if localPlayer ~= nil then
		local playerPos = localPlayer.worldPosition
		local selfPos = self.scriptableObject.shape.worldPosition

		local nowIsRendering = false

		local r = sc.display.RENDER_DISTANCE
		if (playerPos - selfPos):length2() < r * r then
			nowIsRendering = true
		end

		if self.isRendering and not nowIsRendering then
			--quad_rootRealHide(self.quadTree, self)
		elseif not self.isRendering and nowIsRendering then
			--quad_rootRealShow(self.quadTree, self)
		end

		self.isRendering = nowIsRendering

		if self.dragging.interact then
			sc.display.client_onClick(self, 1, "drag")
		elseif self.dragging.tinker then
			sc.display.client_onClick(self, 2, "drag")
		end
	end

	if self.clientDrawingTimer and sm.game.getCurrentTick() - self.clientDrawingTimer >= 80 then
		self.clientDrawingTimer = nil

		--print("autooptimize")
		--quad_optimize(self.quadTree)
	end
end

function sc.display.client_onDataResponse(self, data)
	if sm.isHost then return end
	self.clicksAllowed = data.clicksAllowed
	self.renderAtDistance = data.renderAtDistance
	self.skipAtLags = data.skipAtLags
end

local drawActions = {
	[sc.display.drawType.clear] = function (self, t) sc.display.client_clear(self, sm.color.new(t.color)) end,
	[sc.display.drawType.drawPixel] = function (self, t) sc.display.client_drawPixel(self, t.x, t.y, sm.color.new(t.color)) end,
	[sc.display.drawType.drawRect] = function (self, t) sc.display.client_drawRect(self, t.x, t.y, t.w, t.h, sm.color.new(t.color)) end,
	[sc.display.drawType.fillRect] = function (self, t) sc.display.client_fillRect(self, t.x, t.y, t.w, t.h, sm.color.new(t.color)) end,
	[sc.display.drawType.drawCircle] = function (self, t) sc.display.client_drawCircle(self, t.x, t.y, t.r, sm.color.new(t.color)) end,
	[sc.display.drawType.fillCircle] = function (self, t) sc.display.client_fillCircle(self, t.x, t.y, t.r, sm.color.new(t.color)) end,
	[sc.display.drawType.drawLine] = function (self, t) sc.display.client_drawLine(self, t.x, t.y, t.x1, t.y1, sm.color.new(t.color)) end,
	[sc.display.drawType.drawText] = function (self, t) sc.display.client_drawText(self, t.x, t.y, t.text, sm.color.new(t.color)) end,
	[sc.display.drawType.optimize] = function (self) sc.display.client_optimize(self) end,
}
function sc.display.client_drawStack(self, sendstack)
	----getting
	sendstack = sendstack or _G.sendData

	if sendstack then
		if not self.savestack then self.savestack = {} end
		for _, value in ipairs(sendstack) do
			table.insert(self.savestack, value)
		end
		if not sendstack.endPack then return end
	end

	local stack = self.savestack
	self.savestack = nil

	if not stack then return end

	----drawing
	if not self.isRendering and not self.renderAtDistance then return end
	if self.skipAtLags and sc.deltaTime >= sc.display.SKIP_RENDER_DT then
		return
	end

	for _, v in ipairs(stack) do
		drawActions[v.type](self, v)
	end
	self.clientDrawingTimer = sm.game.getCurrentTick()
	--quad_optimize(self.quadTree)
end

------------------------------------------clicks

function sc.display.server_recvPress(self, p)
	local d = self.clickData
	if #d <= self.maxClicks then
		table_insert(d, p)
	end
end

function sc.display.client_onClick(self, type, action) -- type - 1:interact|2:tinker (e.g 1 or 2), action - pressed, released, drag
	local succ, res = sm.localPlayer.getRaycast(8)
	if succ then
		local shape = self.scriptableObject.shape
		local localPoint = shape:transformPoint(res.pointWorld)

		if localPoint.x < 0 then
			localPoint = sm.vec3.new(0, localPoint.y, localPoint.z)
			local scale = sc.display.PIXEL_SCALE * self.pixelScale

			local pointX = math_floor(self.width / 2 - localPoint.z / scale)
			local pointY = math_floor(self.height / 2 + localPoint.y / scale)
			
			if pointX >= 0 and pointX < self.width and pointY >= 0 and pointY < self.height then
				if action == "drag" then
					local t = type == 1 and self.dragging.interactLastPos or self.dragging.tinkerLastPos

					if t.x ~= -1 then
						if t.x == pointX and t.y == pointY then 
							return
						else
							t.x = pointX
							t.y = pointY
						end
					else
						t.x = pointX
						t.y = pointY
						return
					end
				end
				self.scriptableObject.network:sendToServer("server_recvPress", { pointX, pointY, action, type })
			end
		end
	end
end

function sc.display.client_onInteract(self, character, state)
	self.dragging.interact = state
	if state then
		local t = self.dragging.interactLastPos
		t.x = -1
		t.y = -1
	end
	sc.display.client_onClick(self, 1, state and "pressed" or "released")
end

function sc.display.client_onTinker(self, character, state)
	self.dragging.tinker = state
	if state then
		local t = self.dragging.tinkerLastPos
		t.x = -1
		t.y = -1
	end
	sc.display.client_onClick(self, 2, state and "pressed" or "released")
end

function sc.display.client_canInteract(self, character)
	return self.clicksAllowed
end

function sc.display.client_canTinker(self, character)
	return self.clicksAllowed
end