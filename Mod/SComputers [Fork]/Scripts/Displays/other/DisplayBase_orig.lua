if __displayBaseLoaded then return end
__displayBaseLoaded = true

dofile "$MOD_DATA/Scripts/Config.lua"

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

sc.display.drawActions = {
	[sc.display.drawType.clear] = function (self, t) sc_display_client_clear(self, sm.color.new(t.color)) end,
	[sc.display.drawType.drawPixel] = function (self, t) sc_display_client_drawPixel(self, t.x, t.y, sm.color.new(t.color)) end,
	[sc.display.drawType.drawRect] = function (self, t) sc_display_client_drawRect(self, t.x, t.y, t.w, t.h, sm.color.new(t.color)) end,
	[sc.display.drawType.fillRect] = function (self, t) sc_display_client_fillRect(self, t.x, t.y, t.w, t.h, sm.color.new(t.color)) end,
	[sc.display.drawType.drawCircle] = function (self, t) sc_display_client_drawCircle(self, t.x, t.y, t.r, sm.color.new(t.color)) end,
	[sc.display.drawType.fillCircle] = function (self, t) sc_display_client_fillCircle(self, t.x, t.y, t.r, sm.color.new(t.color)) end,
	[sc.display.drawType.drawLine] = function (self, t) sc_display_client_drawLine(self, t.x, t.y, t.x1, t.y1, sm.color.new(t.color)) end,
	[sc.display.drawType.drawText] = function (self, t) sc_display_client_drawText(self, t.x, t.y, t.text, sm.color.new(t.color)) end,
	[sc.display.drawType.optimize] = function (self) sc_display_client_optimize(self) end,
}

sc.display.PIXEL_SCALE = 0.0072
sc.display.RENDER_DISTANCE = 15
sc.display.SKIP_RENDER_DT = 1 / 24
sc.display.SKIP_RENDER_DT_ALL = 1 / 14
sc.display.deltaTime = 0

sc.display.quad = {}

quad_visibleRot = sm.quat.fromEuler(sm.vec3.zero())
quad_hideRot = sm.quat.fromEuler(sm.vec3.new(0, 180, 0))

quad_displayOffset = sm.vec3.new(-0.117, 0, 0)
quad_offsetRotation = sm.quat.fromEuler(sm.vec3.new(0, 0, 0))

table_insert = table.insert
table_remove = table.remove

math_floor = math.floor
math_abs = math.abs
math_max = math.max
math_min = math.min

util_clamp = sm.util.clamp

--total_effects = 0
function pointInQuad(x, y, qx, qy, qs)
	return (x >= qx and x < qx + qs) and (y >= qy and y < qy + qs)
end

function pointInCircle(x, y, cx, cy, cr)
	local dx = cx - x
	local dy = cy - y

	return dx*dx + dy*dy <= cr*cr
end

function quadInRect(qx, qy, qs, rx, ry, rw, rh)
	return (qx >= rx and qx + qs <= rx + rw) and (qy >= ry and qy + qs <= ry + rh)
end

function quadInCircle(qx, qy, qs, cx, cy, cr)
	local lx = qx - cx
	local ly = qy - cy

	local cr_sq = cr*cr

	local pointIn = function (dx, dy)
		return dx*dx + dy*dy <= cr_sq
	end

	return pointIn(lx, ly) and pointIn(lx + qs, ly) and pointIn(lx, ly + qs) and pointIn(lx + qs, ly + qs)
end

function quadIntersectsRect(qx, qy, qs, rx, ry, rw, rh)
	return (qx < rx + rw and qx + qs > rx) and (qy < ry + rh and qy + qs > ry)
end

function quadIntersectsCircle(qx, qy, qs, cx, cy, cr)
	local clamp = util_clamp
	local closestX = clamp(cx, qx, qx + qs)
	local closestY = clamp(cy, qy, qy + qs)

	local dx = cx - closestX
	local dy = cy - closestY

	return dx*dx + dy*dy <= cr*cr
end

function quad_createNode(parent, x, y, size, color)
	local node =  {
		x = x,
		y = y,
		size = size,
		children = nil,
		parent = parent,
		effect = nil,
		color = color,
		root = parent.root
	}

	node.effect = quad_createEffect(node.root, x, y, size)
	quad_updateEffectColor(node)

	if parent.root.display.isRendering then
		quad_treeShow(node)
	end
	
	return node
end

function quad_createRoot(display, x, y, size)
	local node = {
		x = x,
		y = y,
		size = size,
		children = nil,
		parent = nil,
		effect = nil,
		color = nil,
		display = display,
		bufferedEffects = {}
	}

	node.root = node
	node.effect = quad_createEffect(node, x, y, size)

	if display.isRendering then
		quad_treeShow(node)
	end
	return node
end

function quad_updateEffectColor(self)
	local color = self.color
	local effect = self.effect

	--assert(color ~= nil, "color is nil")

	effect:setParameter("color", color)
end

function quad_destroy(self)
	if self.children ~= nil then
		quad_destroyChildren(self)
	end
	quad_destroyEffect(self)
end

sm_vec3_new = sm.vec3.new
sc_display_PIXEL_SCALE = sc.display.PIXEL_SCALE
sc_display_shapeUuid = sm.uuid.new("41d7c8b2-e2de-4c29-b842-5efd8af37ae6")

function quad_createEffect(root, x, y, size)
	local effect
	local display = root.display

	local bufferedEffects = root.bufferedEffects

	if #bufferedEffects > 0 then
		effect = table_remove(bufferedEffects)
	else
		effect = sm.effect.createEffect("ShapeRenderable", display.scriptableObject.interactable)
		effect:setParameter("uuid", sc_display_shapeUuid)
		--effect:setParameter("uuid", sm.uuid.new("4aa2a6f0-65a4-42e3-bf96-7dec62570e0b"))
		effect:start()
	end

	local vec3_new = sm_vec3_new

	local scale = sc_display_PIXEL_SCALE * display.pixelScale
	local v = scale * size + 1e-4
	effect:setScale(vec3_new(v, v, v))

	local offset = vec3_new(0, y - display.height/2 + size/2, display.width/2 - x - size/2) * scale
	effect:setOffsetPosition(quad_displayOffset + offset)
	--total_effects = total_effects + 1
	return effect
end

function quad_destroyEffect(self)
	--total_effects = total_effects - 1
	local effect = self.effect

	quad_effectHide(effect)
	table_insert(self.root.bufferedEffects, effect)

	self.effect = nil
end

function quad_effectHide(effect)
	effect:setOffsetRotation(quad_hideRot)
end

function quad_effectShow(effect)
	effect:setOffsetRotation(quad_visibleRot)
end

function quad_destroyChildren(self)
	--assert(self.children ~= nil, "children field is nil")
	local children = self.children

	quad_destroy(children[1])
	quad_destroy(children[2])
	quad_destroy(children[3])
	quad_destroy(children[4])

	self.children = nil
	self.effect = quad_createEffect(self.root, self.x, self.y, self.size)
end

--[[function quad_optimizeToUp(self) -- down to up
	if self.children then
		local color = self.children[1].color
		local same = true

		-- check children the same color
		for k, v in pairs(self.children) do
			if v.color ~= color then same = false end
		end

		if same then
			quad_destroyChildren(self)

			self.color = color
			quad_updateEffectColor(self)

			if self.parent then
				quad_optimizeToUp(self.parent)
			end
		end
	else
		error("no children")
	end
end]]

function quad_optimize(self)
	local children = self.children

	if children then
		quad_optimize(children[1])
		quad_optimize(children[2])
		quad_optimize(children[3])
		quad_optimize(children[4])

		local color = children[1].color
		local same = true

		-- check children the same color
		for i = 2, 4 do
			if children[i].color ~= color then same = false end
		end

		if color ~= nil and same then
			quad_destroyChildren(self)

			self.color = color
			quad_updateEffectColor(self)

			if self.root.display.isRendering then
				quad_effectShow(self.effect)
			end
		end
	end
end

function quad_split(self)
	--assert(self.children == nil, "quad node already has children")
	--assert(self.size > 1, "cant split size 1")

	--quad_effectHide(self.effect)
	quad_destroyEffect(self)

	local hsize = self.size / 2
	local x = self.x
	local y = self.y
	local color = self.color

	self.children = {
		quad_createNode(self, x, y, hsize, color),
		quad_createNode(self, x + hsize, y, hsize, color),
		quad_createNode(self, x, y + hsize, hsize, color),
		quad_createNode(self, x + hsize, y + hsize, hsize, color)
	}

	self.color = nil
end

function quad_findChild(self, tx, ty, size)
	if self.size ~= size then
		if self.children == nil then quad_split(self) end

		local hsize = self.size / 2
		local floor = math_floor

		local i = floor((tx - self.x) / hsize) + 2 * floor((ty - self.y) / hsize)
		--assert(self.children[i + 1] ~= nil, "children[i+1] is nil, i:"..i.." x:"..tx.." y:"..ty)
		return quad_findChild(self.children[i + 1], tx, ty, size)
	else
		return self
	end
end

function quad_treeMultiSetColor(self, coords, color)
	local coord0 = table_remove(coords, 1)

	if coord0 ~= nil then
		local x0, y0 = unpack(coord0)

		local child

		function updateChild(x, y)
			child = quad_findChild(self, x, y, 4)
		end

		updateChild(x0, y0)
		quad_treeSetColor(child, x0, y0, color)

		for k, v in pairs(coords) do
			local x, y = unpack(v)
			if pointInQuad(x, y, child.x, child.y, child.size) then
				quad_treeSetColor(child, x, y, color)
			else
				updateChild(x, y)
				quad_treeSetColor(child, x, y, color)
			end
		end
	end
end



function quad_treeSetColor(self, tx, ty, color)
	if self.color ~= color then
		if self.size ~= 1 then
			if self.children == nil then quad_split(self) end

			local Q_hsize = 2 / self.size
			local floor = math_floor

			local i = floor((tx - self.x) * Q_hsize) + 2 * floor((ty - self.y) * Q_hsize)
			quad_treeSetColor(self.children[i + 1], tx, ty, color)
		else
			if self.color ~= color then
				self.color = color
				quad_updateEffectColor(self)
			end
		end
	end
end

function quad_treeFillRect(self, x, y, w, h, color)
	local sx = self.x
	local sy = self.y
	local ssize = self.size

	if quadIntersectsRect(sx, sy, ssize, x, y, w, h) then

		if not quadInRect(sx, sy, ssize, x, y, w, h) then
			if self.children == nil then quad_split(self) end
			local children = self.children

			quad_treeFillRect(children[1], x, y, w, h, color)
			quad_treeFillRect(children[2], x, y, w, h, color)
			quad_treeFillRect(children[3], x, y, w, h, color)
			quad_treeFillRect(children[4], x, y, w, h, color)
		else
			if self.children ~= nil then
				quad_destroyChildren(self)
			end

			if self.color ~= color then
				self.color = color
				quad_updateEffectColor(self)
			end
			if self.root.display.isRendering then
				quad_effectShow(self.effect)
			end
		end
	end
end

function quad_treeFillCircle(self, x, y, r, color)
	local sx = self.x
	local sy = self.y
	local ssize = self.size

	if quadIntersectsCircle(sx, sy, ssize, x, y, r) then

		if not quadInCircle(sx, sy, ssize, x, y, r) then
			if ssize ~= 1 then
				if self.children == nil then quad_split(self) end

				local children = self.children

				quad_treeFillCircle(children[1], x, y, r, color)
				quad_treeFillCircle(children[2], x, y, r, color)
				quad_treeFillCircle(children[3], x, y, r, color)
				quad_treeFillCircle(children[4], x, y, r, color)
			end
		else
			if self.children ~= nil then
				quad_destroyChildren(self)
			end

			if self.color ~= color then
				self.color = color
				quad_updateEffectColor(self)
			end

			if self.root.display.isRendering then
				quad_effectShow(self.effect)
			end
		end
	end
end

function quad_treeShow(self)
	if self.children ~= nil then
		local children = self.children

		quad_treeShow(children[1])
		quad_treeShow(children[2])
		quad_treeShow(children[3])
		quad_treeShow(children[4])
	else
		quad_effectShow(self.effect)
	end
end

function quad_treeHide(self)
	if self.children ~= nil then
		local children = self.children

		quad_treeHide(children[1])
		quad_treeHide(children[2])
		quad_treeHide(children[3])
		quad_treeHide(children[4])
	else
		quad_effectHide(self.effect)
	end
end

function quad_rootRealShow(self)
	if self.children ~= nil then
		local children = self.children

		quad_rootRealShow(children[1])
		quad_rootRealShow(children[2])
		quad_rootRealShow(children[3])
		quad_rootRealShow(children[4])
	else
		self.effect:start()
	end
end

function quad_rootRealHide(self)
	if self.children ~= nil then
		local children = self.children

		quad_rootRealHide(children[1])
		quad_rootRealHide(children[2])
		quad_rootRealHide(children[3])
		quad_rootRealHide(children[4])
	else
		self.effect:stop()
	end
end

function sc.display.createDisplay(scriptableObject, width, height, pixelScale)
	local display = {
		renderingStack = {},
		width = width,
		height = height,
		pixelScale = pixelScale,
		scriptableObject = scriptableObject,
		needFlush = false,
		clickData = {},
		maxClicks = 16,
		needSendData = false,

		-- client
		clicksAllowed = false,
		quadTree = nil,
		isRendering = false,
		renderAtDistance = false,
		dragging = {interact=false, tinker=false, interactLastPos={x=-1, y=-1}, tinkerLastPos={x=-1, y=-1}}
	}
	return display
end

function sc.display.server_init(self)
	sc.displaysDatas[self.scriptableObject.interactable:getId()] = sc.display.server_createData(self)
end

function sc.display.server_update(self)
	if self.needFlush then
		self.scriptableObject.network:sendToClients("client_onReceiveDrawStack", self.renderingStack)
		self.renderingStack = {}
		self.needFlush = false
	end

	if self.needSendData then
		self.scriptableObject.network:sendToClients("client_onDataResponse", sc.display.server_createNetworkData(self))
	end
end

function sc.display.client_init(self)
	local size = math.min(self.width, self.height)
	local root = quad_createRoot(self, 0, 0, size)
	self.quadTree = root

	sc_display_client_clear(self, sm.color.new("000000ff"))

	self.scriptableObject.network:sendToServer("server_onDataRequired", sm.localPlayer.getPlayer())
end


function sc.display.server_destroy(self)
	sc.displaysDatas[self.scriptableObject.interactable:getId()] = nil
end

function sc.display.client_destroy(self)
	local quadTree = self.quadTree

	quad_destroy(quadTree)
	for k, v in pairs(quadTree.bufferedEffects) do
		v:destroy()
	end
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
		flush = function () sc.display.server_flushStack(self) end,
		setClicksAllowed = function (c)
			if type(c) == "boolean" then
				sc.display.server_setClicksAllowed(self, c)
			else
				error("Type must be boolean")
			end
		end,
		getClicksAllowed = function () return self.clicksAllowed end,
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
		setRenderAtDistance = function (c)
			if type(c) == "boolean" then
				sc.display.server_setRenderAtDistance(self, c)
			else
				error("Type must be boolean")
			end
		end,
		getRenderAtDistance = function () return self.renderAtDistance end,
	}
	return data
end

function sc.display.server_createNetworkData(self)
	return {
		renderAtDistance = self.renderAtDistance,
		clicksAllowed = self.clicksAllowed
	}
end

function sc.display.server_setClicksAllowed(self, c)
	if self.clicksAllowed ~= c then
		self.clicksAllowed = c
		self.needSendData = true
	end
end

function sc.display.server_setRenderAtDistance(self, c)
	if self.renderAtDistance ~= c then
		self.renderAtDistance = c
		self.needSendData = true
	end
end

function sc.display.server_clear(self, color)
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
	self.needFlush = true
end

function sc.display.server_onDataRequired(self, client)
	self.scriptableObject.network:sendToClient(client, "client_onDataResponse", sc.display.server_createNetworkData(self))
end

function sc.display.server_recvPress(self, p)
	local d = self.clickData
	if #d <= self.maxClicks then
		table_insert(d, p)
	end
end

--[[function sc_display_client_setClicksAllowed(self, c)
	self.clicksAllowed = c
end]]

function sc_display_client_clear(self, color)
	local quadTree = self.quadTree

	if quadTree.children then
		quad_destroyChildren(quadTree)
	end

	if quadTree.color ~= color then
		quadTree.color = color
		quad_updateEffectColor(quadTree)
	end

	if self.isRendering then
		quad_effectShow(quadTree.effect)
	end
end

sc.display.client_clear = sc_display_client_clear

function sc_display_client_drawPixelForce(self, x, y, color)
	quad_treeSetColor(self.quadTree, x, y, color)
end

sc.display.client_drawPixelForce = sc_display_client_drawPixelForce

function sc_display_client_drawPixel(self, x, y, color)
	floor = math_floor

	x = floor(x)
	y = floor(y)

	if x >= 0 and x < self.width and y >= 0 and y < self.height then
		sc_display_client_drawPixelForce(self, x, y, color)
	end
end

sc.display.client_drawPixel = sc_display_client_drawPixel

function sc_display_client_drawRect(self, x, y, w, h, color)
	local floor = math_floor


	if x >= self.width then return end
	if y >= self.height then return end
	local lx = floor(x >= 0 and x or 0)
	
	local ly = floor(y >= 0 and y or 0)
	
	local lw = w - (lx - x)
	local lh = h - (ly - y)

	local rw = self.width - lx
	local rh = self.height - ly

	lw = floor(lw < rw and lw or rw)
	lh = floor(lh < rh and lh or rh)

	for i = lx,lx+lw-1 do
		sc_display_client_drawPixelForce(self, i, ly, color)
	end

	local ex = lx+lw-1
	for iy = ly+1, ly+lh-2 do
		sc_display_client_drawPixelForce(self, lx, iy, color)
		sc_display_client_drawPixelForce(self, ex, iy, color)
	end

	local ey = ly + lh - 1
	for i = lx,lx+lw-1 do
		sc_display_client_drawPixelForce(self, i, ey, color)
	end

end

sc.display.client_drawRect = sc_display_client_drawRect

function sc_display_client_fillRect(self, x, y, w, h, color)
	--[[if x >= self.width then return end
	if y >= self.height then return end
	local lx = x >= 0 and x or 0
	
	local ly = y >= 0 and y or 0
	
	local lw = w - (lx - x)
	local lh = h - (ly - y)

	local rw = self.width - lx
	local rh = self.height - ly

	lw = lw < rw and lw or rw
	lh = lh < rh and lh or rh

	quad_treeFillRect(self.quadTree, lx, ly, lw, lh, color)]]--
	local floor = math_floor
	quad_treeFillRect(self.quadTree, floor(x), floor(y), floor(w), floor(h), color)
end

sc.display.client_fillRect = sc_display_client_fillRect

function drawCircle_putpixel(self, cx, cy, x, y, color)
	local drawPixel = sc_display_client_drawPixel
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

function sc_display_client_drawCircle(self, x, y, r, color)
	local floor = math_floor

	x = floor(x)
	y = floor(y)
	r = floor(r)

	local put = drawCircle_putpixel

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

sc.display.client_drawCircle = sc_display_client_drawCircle

function sc_display_client_fillCircle(self, x, y, r, color)
	quad_treeFillCircle(self.quadTree, x, y, r, color)
end

sc.display.client_fillCircle = sc_display_client_fillCircle

function sc_display_client_drawLineForce(self, x, y, x1, y1, color)
	local floor = math_floor

	x = floor(x)
	y = floor(y)
	x1 = floor(x1)
	y1 = floor(y1)

	local dx = math_abs(x1 - x)
    local sx = x < x1 and 1 or -1
    local dy = -math_abs(y1 - y)
    local sy = y < y1 and 1 or -1

    local drawPixel = sc_display_client_drawPixelForce
    
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

sc.display.client_drawLineForce = sc_display_client_drawLineForce


-- y = y0 + round( (x-x0) * dy / dx )
function sc_display_client_drawLine(self, x, y, x1, y1, color)
	local floor = math_floor

	x = floor(x)
	y = floor(y)
	x1 = floor(x1)
	y1 = floor(y1)

	local sign_x, sign_y

	local clip_xmin = 0
	local clip_xmax = self.width - 1

	local clip_ymin = 0
	local clip_ymax = self.height - 1

	local drawPixel = sc_display_client_drawPixelForce

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

sc.display.client_drawLine = sc_display_client_drawLine

function sc_display_client_drawCharForce(self, x, y, c, color)
	local chars = sc.display.font.chars.optimized
	local pixels = chars[c]
	if pixels == nil then
		pixels = chars.error
	end

	local drawPixel = sc_display_client_drawPixelForce

	for i = 1, #pixels do
		local v = pixels[i]
		drawPixel(self, x + v[1], y + v[2], color)
	end
end

sc.display.client_drawCharForce = sc_display_client_drawCharForce

font_chars = sc.display.font.chars.optimized
font_width = sc.display.font.width
font_height = sc.display.font.height

function sc_display_client_drawChar(self, x, y, c, color)
	local floor = math_floor

	x = floor(x)
	y = floor(y)

	local chars = font_chars
	local pixels = chars[c]
	if pixels == nil then
		pixels = chars.error
	end

	local drawPixel = sc_display_client_drawPixel

	for i = 1, #pixels do
		local v = pixels[i]
		drawPixel(self, x + v[1], y + v[2], color)
	end
end

sc.display.client_drawChar = sc_display_client_drawChar

function sc_display_client_drawText(self, x, y, text, color)
	local floor = math_floor

	text = text:lower()

	x = floor(x)
	y = floor(y)

	local ix = x
	local fw = font_width
	local ey = y + font_height

	local drawChar = sc_display_client_drawChar
	local drawCharForce = sc_display_client_drawCharForce

	local font_width = font_width

	if ix < 0 then
		local ic = 1
		while ix + fw < 0 do
			ix = ix + fw + 1
			ic = ic + 1
		end
		drawChar(self, ix, y, text:sub(ic, ic), color)
		ix = ix + fw + 1
		text = text:sub(ic + 1, #text)
	end

	if y >= 0 and ey < self.height then
		for c in text:gmatch(".") do
			local ex = ix + fw

			if ex < self.width then
				drawCharForce(self, ix, y, c, color)
			else
				drawChar(self, ix, y, c, color)
				break
			end

			ix = ex + 1
		end
	else
		for c in text:gmatch(".") do
			local ex = ix + font_width

			drawChar(self, ix, y, c, color)

			if ex >= self.width then
				break
			end

			ix = ex + 1
		end
	end
end

sc.display.client_drawText = sc_display_client_drawText

function sc_display_client_optimize(self)
	quad_optimize(self.quadTree)
end

sc.display.client_optimize = sc_display_client_optimize

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
			quad_rootRealHide(self.quadTree)
		elseif not self.isRendering and nowIsRendering then
			quad_rootRealShow(self.quadTree)
		end

		self.isRendering = nowIsRendering

		if self.dragging.interact then
			sc.display.client_onClick(self, 1, "drag")
		elseif self.dragging.tinker then
			sc.display.client_onClick(self, 2, "drag")
		end
	end
end

function sc.display.client_onDataResponse(self, data)
	self.clicksAllowed = data.clicksAllowed
	self.renderAtDistance = data.renderAtDistance
end

function sc.display.client_drawStack(self, stack)
	-- to save minimal fps
	if not self.isRendering and not self.renderAtDistance then return end

	--if sc.restrictions.displaysAtLagsMode == "skip" then 
		if	(sc.deltaTime >= sc.display.SKIP_RENDER_DT_ALL) or 
			(self.renderAtDistance and sc.deltaTime >= sc.display.SKIP_RENDER_DT) 
			then return end
	--end

	local actions = sc.display.drawActions

	for i = 1, #stack do
		local v = stack[i]
		actions[v.type](self, v)
	end
	--quad_optimize(self.quadTree)
end


function sc.display.client_onClick(self, type, action) -- type - 1:interact|2:tinker (e.g 1 or 2), action - pressed, released, drag
	local succ, res = sm.localPlayer.getRaycast(3)
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