if __displayBaseLoaded then return end
__displayBaseLoaded = true

dofile "$CONTENT_DATA/Scripts/Config.lua"
dofile "$CONTENT_DATA/Scripts/vnetwork.lua"

local vnetwork = vnetwork
local sc = sc
local probability = probability
local checkArg = checkArg

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

--local _utf8 = string
local _utf8 = utf8
local sc_display_drawType = sc.display.drawType
local constrain, mathDist = constrain, mathDist

sc.display.PIXEL_SCALE = 0.0072
sc.display.RENDER_DISTANCE = 15
sc.display.SKIP_RENDER_DT = 1 / 30
sc.display.SKIP_RENDER_DT_ALL = 1 / 20
sc.display.deltaTime = 0

sc.display.quad = {}

local RENDER_DISTANCE = sc.display.RENDER_DISTANCE

local sm = sm
local sm_effect_createEffect = sm.effect.createEffect
local sm_quat_fromEuler = sm.quat.fromEuler

local table_insert = table.insert
local table_remove = table.remove

local math_rad = math.rad
local math_random = math.random
local math_floor = math.floor
local math_abs = math.abs
local math_max = math.max
local math_min = math.min
local string_sub = string.sub
local string_byte = string.byte
local sm_exists = sm.exists
local ipairs = ipairs
local pairs = pairs
local print = print
local type = type
local unpack = unpack
local getCurrentTick = sm.game.getCurrentTick
local sm_localPlayer = sm.localPlayer
local sm_localPlayer_getPlayer = sm_localPlayer.getPlayer


local util_clamp = sm.util.clamp
local sm_vec3_new = sm.vec3.new
local sc_display_PIXEL_SCALE = sc.display.PIXEL_SCALE

local formatColor = sc.formatColor
local formatColorStr = sc.formatColorStr

local emptyEffect = sm.effect.createEffect(sc.getEffectName())
local effect_setParameter = emptyEffect.setParameter
local effect_stop = emptyEffect.stop
local effect_destroy = emptyEffect.destroy
local effect_start = emptyEffect.start
local effect_isDone = emptyEffect.isDone
local effect_setScale = emptyEffect.setScale
local effect_setOffsetPosition = emptyEffect.setOffsetPosition
local effect_setOffsetRotation = emptyEffect.setOffsetRotation
effect_stop(emptyEffect)
effect_destroy(emptyEffect)


local quad_visibleRot = sm_quat_fromEuler(sm.vec3.zero())
local quad_hideRot = sm_quat_fromEuler(sm_vec3_new(0, 180, 0))

local quad_displayOffset = sm_vec3_new(-0.125, 0, 0)
local quad_offsetRotation = sm_quat_fromEuler(sm_vec3_new(0, 0, 0))

local function cl_displayRaycast(self, r)
	if _G.raycastCache and (getCurrentTick() - _G.raycastCache.time) < 20 then
		return _G.raycastCache.shapes
	end

	--[[
	local shapes = {}
	local maxoffset = math.pi / 3
	for x = -maxoffset, maxoffset, maxoffset / 10 do
		for y = -maxoffset, maxoffset, maxoffset / 10 do
			local offset = sm.vec3.new(
				0, --why does it work relative to the world and not relative to the player?
				0, --why does it work relative to the world and not relative to the player?
				y
			)
			

			local ok, result = sm.localPlayer.getRaycast(r, nil, sm.localPlayer.getDirection() + offset)
			
			if result.pointWorld then
				sm.debris.createDebris(
					sm.uuid.new("d3db3f52-0a8d-4884-afd6-b4f2ac4365c2"),
					result.pointWorld,
					sm.quat.fromEuler(sm.vec3.new(0, 0, 0)),
					sm.vec3.zero(),
					sm.vec3.zero(),
					sm.color.new(1, 0, 0),
					1 / 40
				)
			end
			if ok and result and result.type == "body" then
				--sm.debugDraw.addSphere("11", result.pointWorld, 0.5, sm.color.new(1, 0, 0))
				shapes[result:getShape()] = result
			end
		end
	end
	]]

	----createRays
	local character = sm_localPlayer_getPlayer().character

	local position = character.worldPosition + sm_vec3_new(0, 0, 0.5)
	local rotation = sm.camera.getRotation() * sm_quat_fromEuler(sm_vec3_new(90, 180, 0))

	local resolutionX, resolutionY = self.restrictions.rays, self.restrictions.rays
	local distance = self.restrictions.rend
	local fov = math_rad(sm.camera.getFov() * 2)
	local rays = {}
	local u, v, direction
	for x = 1, resolutionX do
		for y = 1, resolutionY do
			u = ( x / resolutionX - 0.5 ) * fov
			v = ( y / resolutionY - 0.5 ) * fov

			direction = rotation * sm_vec3_new(-u, -v, 1)

			table_insert(rays, {
				type = "ray",
				startPoint = position,
				endPoint = position + direction * distance,
			})
		end
	end

	----raycasting
	local casts = sm.physics.multicast(rays)

	local shapes = {}
	for _, data in pairs(casts) do
		if data[1] then
			local shape = data[2]:getShape()
			if shape then
				shapes[shape] = data[2]
			end

			--[[
			sm.debris.createDebris(
				sm.uuid.new("d3db3f52-0a8d-4884-afd6-b4f2ac4365c2"),
				data[2].pointWorld,
				sm.quat.fromEuler(sm.vec3.new(0, 0, 0)),
				sm.vec3.zero(),
				sm.vec3.zero(),
				sm.color.new(1, 0, 0),
				1 / 40
			)
			]]
		end
	end
	
	_G.raycastCache = {shapes = shapes, time = getCurrentTick()}
	return shapes
end

local function debug_print_force(...)
	print(...)
end

local function debug_print(...)
	--print(...)
end

local sc_display_shapesUuid = sm.uuid.new("41d7c8b2-e2de-4c29-b842-5efd8af37ae6")

local sc_getEffectName = sc.getEffectName

local quadIntersectsCircle, quad_createNode, quad_createRoot, quad_updateEffectColor
local quad_createEffect, quad_effectHide, quad_effectShow, quad_destroy, quad_destroyEffect
local quad_destroyChildren, quad_optimize, quad_split
local quad_findChild
local quad_treeMultiSetColor
local quad_treeSetColor
local quad_treeFillRect
local quad_treeFillCircle
local quad_treeShow
local quad_treeHide
local quad_rootRealShow
local quad_rootRealHide
local sc_display_client_clear
local sc_display_client_drawPixelForce
local sc_display_client_drawPixel
local sc_display_client_drawRect
local sc_display_client_fillRect
local drawCircle_putpixel
local sc_display_client_drawCircle
local sc_display_client_fillCircle
local sc_display_client_drawLineForce
local sc_display_client_drawLine
local sc_display_client_optimize


local font_chars = sc.display.font.chars.optimized
local font_width = sc.display.font.width
local font_height = sc.display.font.height

local total_effects = 0
local effectsData = {}

local function pointInQuad(x, y, qx, qy, qs)
	return (x >= qx and x < qx + qs) and (y >= qy and y < qy + qs)
end

local function pointInCircle(x, y, cx, cy, cr)
	local dx = cx - x
	local dy = cy - y

	return dx*dx + dy*dy <= cr*cr
end

local function quadInRect(qx, qy, qs, rx, ry, rw, rh)
	return (qx >= rx and qx + qs <= rx + rw) and (qy >= ry and qy + qs <= ry + rh)
end

local function quadInCircle(qx, qy, qs, cx, cy, cr)
	local lx = qx - cx
	local ly = qy - cy

	local cr_sq = cr*cr

	local pointIn = function (dx, dy)
		return dx*dx + dy*dy <= cr_sq
	end

	return pointIn(lx, ly) and pointIn(lx + qs, ly) and pointIn(lx, ly + qs) and pointIn(lx + qs, ly + qs)
end

local function quadIntersectsRect(qx, qy, qs, rx, ry, rw, rh)
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

function quad_createNode(parent, x, y, sizeX, sizeY, color)
	local node =  {
		x = x,
		y = y,
		sizeX = sizeX,
		sizeY = sizeY,
		size = math_max(sizeX, sizeY),
		children = nil,
		parent = parent,
		effect = nil,
		color = color,
		root = parent.root,
		display = parent.root.display,
		--uroot = parent.root.display.quadTree
	}

	--[[
	print(color, parent.root.display.lastLastClearColor, color == parent.root.display.lastLastClearColor)
	if color == parent.root.display.lastLastClearColor then
		node.effect = quad_createEffect(node.root, x, y, sizeX, sizeY)
		--quad_updateEffectColor(node)
		effect_setParameter(node.effect, "color", sm.color.new(1, 0, 0))
		effect_setScale(node.effect, sm.vec3.new(0.01, 0.01, 0.01))
		return node
	end
	]]

	node.effect = quad_createEffect(node.root, x, y, sizeX, sizeY)
	quad_updateEffectColor(node, true)

	--if parent.root.display.isRendering then
	--	quad_treeShow(node)
	--end
	
	return node
end

function quad_createRoot(display, x, y, size, maxX, maxY)
	local node = {
		x = x,
		y = y,
		size = size,
		maxX = maxX,
		maxY = maxY,
		sizeX = maxX,
		sizeY = maxY,
		children = nil,
		parent = nil,
		effect = nil,
		color = nil,
		display = display,
		bufferedEffects = {},
		allEffects = {}
	}

	node.root = node
	node.back_effect = quad_createEffect(node, x, y, maxX, maxY, 0.05, true)

	--node.effect = quad_createEffect(node, x, y, maxX, maxY)

	--if display.isRendering then
	--	quad_treeShow(node)
	--end

	--node.uroot = node
	return node
end

function quad_updateEffectColor(self, force)
	if not self.effect or not sm_exists(self.effect) then return end
	local color = self.color

	--[[
	if color ~= self.display.lastLastClearColor or force then
		--effect_setScale(effect, sm.vec3.new(0.02, 0.02, 0.02))

		if not self.effect then
			self.effect = quad_createEffect(self.root, self.x, self.y, self.sizeX, self.sizeY)
		end
		effect_setParameter(self.effect, "color", color)
	end
	]]

	effect_setParameter(self.effect, "color", color)
end

function quad_destroy(self, removeAll)
	if self.children then
		quad_destroyChildren(self)
	end
	quad_destroyEffect(self)


	if removeAll then
		debug_print("removeAll")
		
		effect_stop(self.back_effect)
		effect_destroy(self.back_effect)
		for effect in pairs(self.allEffects) do
			if effect and sm_exists(effect) then
				total_effects = total_effects - 1
				effect_stop(effect)
				effect_destroy(effect)
			end
		end
		self.allEffects = {}
		self.bufferedEffects = {}
	end
end

function quad_createEffect(root, x, y, sizeX, sizeY, z, nonBuf, nativeScale)
	--local attemptRemove

	--::attempt::

	sizeY = sizeY or sizeX
	local rmaxX = root.maxX
	local rmaxY = root.maxY
	if x > rmaxX then x = rmaxX end
	if y > rmaxY then y = rmaxY end
	if x + sizeX > rmaxX then sizeX = sizeX - ((x + (sizeX)) - rmaxX) end
	if y + sizeY > rmaxY then sizeY = sizeY - ((y + (sizeY)) - rmaxY) end

	local effect
	local display = root.display
	local bufferedEffects = root.bufferedEffects

	if not nonBuf and #bufferedEffects > 0 then
		effect = table_remove(bufferedEffects)
	else
		--if total_effects < (1050000) then
			--debug_print(effectsNames[currentEffect])

			effect = sm_effect_createEffect(sc_getEffectName(), display.scriptableObject.character or display.scriptableObject.interactable)
			--effect = {stop = function() end, start = function() end, destroy = function() end,
			--setScale = function() end, setOffsetPosition = function() end, setOffsetRotation = function() end,
			--setParameter = function() end, id = math.random(0, 99999), trash = string.rep(" ", 1024 * 8)}
			--print("create_id", effect.id)

			effect_setParameter(effect, "uuid", sc_display_shapesUuid)
			--effect:start()

			if not nonBuf and display.newEffects then
				display.newEffects[effect] = true
			end
			if not nonBuf then
				root.allEffects[effect] = true
			end

			if not nonBuf then
				total_effects = total_effects + 1
			end

			--[[
			if effect and sm_exists(effect) then
				if not nonBuf then
					
				end
			else
				debug_print("EFFECTS OVERFLOW!!!!", total_effects)
			end
			]]
		--else
			--[[
			if attemptRemove then
				return
			else
				local count = 0
				for effect in pairs(root.allEffects) do
					if effect and sm_exists(effect) then
						quad_effectHide(effect)
						table_insert(bufferedEffects, effect)
						
						count = count + 1
						if count >= 50 then
							break
						end

						debug_print("super quad_destroyEffect")
					end
				end
					

				attemptRemove = true
				goto attempt
			end
			]]
		--end
	end

	if not effect or not sm_exists(effect) then return effect end

	local scale = sc_display_PIXEL_SCALE * display.pixelScale
	local vx = scale * sizeX + 1e-4
	local vy = scale * sizeY + 1e-4
	local vecScale = sm_vec3_new(0, vy, vx)
	if nativeScale then
		effect_setScale(effect, sm_vec3_new(0, sizeX, sizeY))
	else
		effect_setScale(effect, vecScale)
	end

	local offset = sm_vec3_new(z or 0, y - display.height/2 + sizeY/2, display.width/2 - x - sizeX/2) * scale

	local chr = display.scriptableObject.character
	if chr then
		local x, y, z = offset.x, offset.y, offset.z
		offset.z = x
		offset.x = z
		offset.y = -y
		offset = offset + sm_vec3_new(0, 1, 1)
		effect_setOffsetPosition(effect, offset)
	else
		offset = quad_displayOffset + offset
		effect_setOffsetPosition(effect, offset)
	end

	local tbl = {offset = offset, sizeX = sizeX, sizeY = sizeY}
	if chr then
		tbl.quad_hideRot =    sm_quat_fromEuler(sm_vec3_new(0, 90, 0))
		tbl.quad_visibleRot = sm_quat_fromEuler(sm_vec3_new(0, 180 + 90,   0))
	else
		tbl.quad_hideRot = quad_hideRot
		tbl.quad_visibleRot = quad_visibleRot
	end
	effectsData[effect.id] = tbl
	quad_effectShow(effect)
	
	return effect
end

function quad_destroyEffect(self)
	local effect = self.effect

	if effect and sm_exists(effect) then
		quad_effectHide(effect)
		table_insert(self.root.bufferedEffects, effect)
	end

	self.effect = nil
end

function quad_effectHide(effect)
	if effect and sm_exists(effect) then
		effect_setOffsetRotation(effect, effectsData[effect.id].quad_hideRot)
	end
end

function quad_effectShow(effect)
	if effect and sm_exists(effect) then
		effect_setOffsetRotation(effect, effectsData[effect.id].quad_visibleRot)
	end
end

function quad_destroyChildren(self)
	local children = self.children

	quad_destroy(children[1])
	quad_destroy(children[2])
	quad_destroy(children[3])
	quad_destroy(children[4])

	self.children = nil
	self.effect = quad_createEffect(self.root, self.x, self.y, self.size)
end


function quad_optimize(self)
	do return end

	local children = self.children
	if children then
		--debug_print("children found!!!")

		quad_optimize(children[1])
		quad_optimize(children[2])
		quad_optimize(children[3])
		quad_optimize(children[4])

		local color = children[1].color
		
		-- check children the same color
		local same = true
		for i = 2, 4 do
			if children[i].color ~= color then
				--debug_print("color is not equals", tostring(children[i].color), tostring(color))
				same = false
				break
			end
		end

		--[[
		local same = false
		for i = 2, 4 do
			if children[i].color == color then
				--debug_print("color is not equals", tostring(children[i].color), tostring(color))
				same = true
				break
			end
		end
		]]

		if color and same then
			--debug_print("quad_optimize successful")

			quad_destroyChildren(self)

			--[[
			quad_destroy(children[1])
			for i = 2, 4 do
				if children[i].color == color then quad_destroy(children[i]) end
			end

			self.children = nil
			self.effect = quad_createEffect(self.root, self.x, self.y, self.sizeX, self.sizeY)
			]]



			self.color = color
			quad_updateEffectColor(self)

			--if self.root.display.isRendering then
			--	quad_effectShow(self.effect)
			--end
		end
	end

	return not not children
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
		quad_createNode(self, x, y, hsize, hsize, color),
		quad_createNode(self, x + hsize, y, hsize, hsize, color),
		quad_createNode(self, x, y + hsize, hsize, hsize, color),
		quad_createNode(self, x + hsize, y + hsize, hsize, hsize, color)
	}

	self.color = nil
end

function quad_findChild(self, tx, ty, size)
	if self.size ~= size then
		if not self.children then quad_split(self) end

		local hsize = self.size / 2

		local i = math_floor((tx - self.x) / hsize) + 2 * math_floor((ty - self.y) / hsize)
		--assert(self.children[i + 1] ~= nil, "children[i+1] is nil, i:"..i.." x:"..tx.." y:"..ty)
		return quad_findChild(self.children[i + 1], tx, ty, size)
	else
		return self
	end
end

function quad_treeMultiSetColor(self, coords, color)
	local coord0 = table_remove(coords, 1)

	if coord0 then
		local x0, y0 = unpack(coord0)
		local child
		local function updateChild(x, y)
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
			if not self.children then quad_split(self) end

			local Q_hsize = 2 / self.size

			local i = math_floor((tx - self.x) * Q_hsize) + 2 * math_floor((ty - self.y) * Q_hsize)
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
			if not self.children then quad_split(self) end
			local children = self.children

			quad_treeFillRect(children[1], x, y, w, h, color)
			quad_treeFillRect(children[2], x, y, w, h, color)
			quad_treeFillRect(children[3], x, y, w, h, color)
			quad_treeFillRect(children[4], x, y, w, h, color)
		else
			if self.children then
				quad_destroyChildren(self)
			end

			if self.color ~= color then
				self.color = color
				quad_updateEffectColor(self)
			end
			--if self.root.display.isRendering then
			--	quad_effectShow(self.effect)
			--end
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
				if not self.children then quad_split(self) end

				local children = self.children

				quad_treeFillCircle(children[1], x, y, r, color)
				quad_treeFillCircle(children[2], x, y, r, color)
				quad_treeFillCircle(children[3], x, y, r, color)
				quad_treeFillCircle(children[4], x, y, r, color)
			end
		else
			if self.children then
				quad_destroyChildren(self)
			end

			if self.color ~= color then
				self.color = color
				quad_updateEffectColor(self)
			end

			--if self.root.display.isRendering then
			--	quad_effectShow(self.effect)
			--end
		end
	end
end

function quad_treeShow(self)
	if self.children then
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
	if self.children then
		local children = self.children

		quad_treeHide(children[1])
		quad_treeHide(children[2])
		quad_treeHide(children[3])
		quad_treeHide(children[4])
	else
		quad_effectHide(self.effect)
	end
end

function quad_rootRealShow(self, noRecurse)
	if self.children then
		local children = self.children

		quad_rootRealShow(children[1])
		quad_rootRealShow(children[2])
		quad_rootRealShow(children[3])
		quad_rootRealShow(children[4])
	end
	if self.effect and sm_exists(self.effect) and effect_isDone(self.effect) then
		effect_start(self.effect)
	end

	if self.bufferedEffects and noRecurse then
		if effect_isDone(self.back_effect) then
			effect_start(self.back_effect)
		end

		for k, v in pairs(self.bufferedEffects) do
			if sm_exists(v) and effect_isDone(v) then
				effect_start(v)
			end
		end
	end
end

function quad_rootRealHide(self, noRecurse)
	if self.children then
		local children = self.children

		quad_rootRealHide(children[1])
		quad_rootRealHide(children[2])
		quad_rootRealHide(children[3])
		quad_rootRealHide(children[4])
	end
	if self.effect and sm_exists(self.effect) then
		effect_stop(self.effect)
	end

	if self.bufferedEffects and noRecurse then
		effect_stop(self.back_effect)

		for k, v in pairs(self.bufferedEffects) do
			if sm_exists(v) then
				effect_stop(v)
			end
		end
	end
end

------------------------------------------------------------

local function hideNewEffects(self)
	if self.newEffects then
		for eff in pairs(self.newEffects) do
			effect_stop(eff)
			--quad_effectHide(eff)
		end
	end
end

local function showNewEffects(self)
	if self.newEffects then
		for eff in pairs(self.newEffects) do
			if effect_isDone(eff) then
				effect_start(eff)
			end
			--quad_effectShow(eff)
		end
	end
end

local function applyNew(self)
	if self.isRendering then
		effect_start(self.quadTree.back_effect)
		showNewEffects(self)
	else
		effect_stop(self.quadTree.back_effect)
		hideNewEffects(self)
	end
end

------------------------------------------------------------

local function random_hide_show(self, probabilityNum, allow)
	--[[
	local sendallow = (allow or 0) + 1
	if self.children then
		local children = self.children

		random_hide_show(children[1], probabilityNum, sendallow)
		random_hide_show(children[2], probabilityNum, sendallow)
		random_hide_show(children[3], probabilityNum, sendallow)
		random_hide_show(children[4], probabilityNum, sendallow)
	end
	if self.effect and allow and allow >= 2 then
		if probability(probabilityNum) then
			self.effect:stop()
		else
			self.effect:start()
		end
	end
	]]

	local edata
	for effect in pairs(self.quadTree.allEffects) do
		if sm_exists(effect) then
			if probabilityNum > 0 and probability(probabilityNum) then
				edata = effectsData[effect.id]
				--если писклесь хотябы по одной оси меньше или равно 1
				--это позволит рендерить изображения в сильно упрошенном виде
				if edata.sizeX <= 1 or edata.sizeY <= 1 then
					effect_stop(effect)
				end
			elseif effect_isDone(effect) then
				effect_start(effect)
			end
		end
	end
end

function sc.display.createDisplay(scriptableObject, width, height, pixelScale)
	vnetwork.init()

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
		rnd = math_random(0, 40 * 5),
		dbuffPixels = {},
		clicksAllowed = false,
		quadTree = nil,
		renderAtDistance = false,
		skipAtLags = true,
		dragging = {interact=false, tinker=false, interactLastPos={x=-1, y=-1}, tinkerLastPos={x=-1, y=-1}},
	}

	return display
end

function sc.display.server_init(self)
	if self.scriptableObject.interactable then
		sc.displaysDatas[self.scriptableObject.interactable.id] = sc.display.server_createData(self)
	end
end

--local doValueHashCache = {}
local function doValueHash(input, localCache)
	--do return math.random() end
	
	--local cache = doValueHashCache or localCache
	--if cache and cache[input] then return cache[input] end

	local value = 16421
	if type(input) == "table" then
		local ldop = 0
		for k, v in pairs(input) do
			ldop = ldop + 45
			value = value + (doValueHash(k) * ldop)
			ldop = ldop + 22
			value = value + (doValueHash(v) * ldop)
		end
	elseif type(input) == "number" then
		value = (input + 82) * 7
	elseif type(input) == "string" then
		for i = 1, #input do
			value = value + ((string_byte(input, i) + 7) * (i * 2))
		end
		--if not localCache and cache then
		--	cache[input] = value
		--end
	else
		input = tostring(input)

		for i = 1, #input do
			value = value + ((string_byte(input, i) + 7) * (i * 2))
		end
	end

	--if localCache and cache then
	--	cache[input] = value
	--end
	return value
end

local function sendFont(self, client)
	local function send(name, arg)
		if client then
			self.scriptableObject.network:sendToClient(client, name, arg)
		else
			self.scriptableObject.network:sendToClients(name, arg)
		end
	end

	if self.customFont then
		send("client_onDataResponse", {fontdata = {width = self.customFont.width, height = self.customFont.height}})
		for name, data in pairs(self.customFont.chars) do
			send("client_onDataResponse", {fontdata = {name = name, data = data}})
		end
	else
		send("client_onDataResponse", {fontdata = {remove = true}})
	end
end

function sc.display.server_update(self)
	if self.needSendData or sc.restrictionsUpdated then
		--debug_print("self.needSendData")
		self.scriptableObject.network:sendToClients("client_onDataResponse", sc.display.server_createNetworkData(self))
		sendFont(self)

		self.needSendData = false
	end

	if self.needUpdate then
		--debug_print("self.needUpdate")
		local dbuffcode
		if self.isStackCheckEnable then
			dbuffcode = doValueHash(self.renderingStack)
		end

		--optimize
		--[[
		if #self.renderingStack <= 1024 then
			local localCache = {}

			for i = #self.renderingStack, 1, -1 do
				if self.renderingStack[i - 1] and doValueHash(self.renderingStack[i], localCache) == doValueHash(self.renderingStack[i - 1], localCache) then
					table_remove(self.renderingStack, i)
				end
			end
		end
		]]

		--sending
		
		if not self.isStackCheckEnable or not self.dbuffcode or self.dbuffcode ~= dbuffcode then
			--debug_print("self.needUpdate-sending")

			--[[
			for i = #self.renderingStack, 1, -1 do
				local action = self.renderingStack[i]
				
				if action.type == sc_display_drawType.drawPixel then
					local width = self.width
					local currentColor = self.dbuffPixels[action.x + (action.y * width)] or self.dbuffPixelsAll

					if currentColor and currentColor == action.color then
						table_remove(self.renderingStack, i)
					end
				end
			end
			]]

			self.renderingStack.endPack = true
			--[[
			local dist = RENDER_DISTANCE
			if self.renderAtDistance or self.player then
				dist = nil
			end
			]]
			--local dist = nil --sending to all players

			local whitelist
			if self.player then
				whitelist = {[self.player.id] = true}
			end

			if not pcall(vnetwork.sendToClients, self.scriptableObject, "client_onReceiveDrawStack", self.renderingStack, nil, whitelist) then
				self.renderingStack.endPack = false
				
				local index = 1
				local count = 4096
				local cycles = 0

				local datapack
				local continue
				while true do
					datapack = {unpack(self.renderingStack, index, index + (count - 1))}

					continue = nil
					index = index + count
					if index > #self.renderingStack + count then
						datapack.endPack = true
						if not pcall(vnetwork.sendToClients, self.scriptableObject, "client_onReceiveDrawStack", datapack, nil, whitelist) then
							index = index - count
							count = math_floor((count / 2) + 0.5)
							continue = true
						else
							break
						end
					end

					if not continue and not pcall(vnetwork.sendToClients, self.scriptableObject, "client_onReceiveDrawStack", datapack, nil, whitelist) then
						index = index - count
						count = math_floor((count / 2) + 0.5)
					end

					cycles = cycles + 1
					if cycles > 100 then
						debug_print_force("cycles to many 100", pcall(vnetwork.sendToClients, self.scriptableObject, "client_onReceiveDrawStack", self.renderingStack, nil, whitelist))
						error("cycles to many 100")
						break
					end
				end
				debug_print("self.needUpdate-sending end")
			end
			
			self.isStackCheckEnable = nil
			self.renderingStack = {}
		--else
		--	debug_print("self.needUpdate-dropped")
		end
		self.dbuffcode = dbuffcode
		
		self.needUpdate = false
	end
end

function sc.display.client_init(self)
	--local size = math_max(self.width, self.height)
	--local root = quad_createRoot(self, 0, 0, size, self.width, self.height)
	--self.quadTree = root

	self.scriptableObject.network:sendToServer("server_onDataRequired", sm_localPlayer_getPlayer())


	self.newEffects = {}
	sc_display_client_clear(self, sm.color.new("000000ff"), true)
	applyNew(self)
	self.newEffects = nil
end


function sc.display.server_destroy(self)
	if self.scriptableObject.interactable then
		sc.displaysDatas[self.scriptableObject.interactable.id] = nil
	end
end

function sc.display.client_destroy(self)
	local quadTree = self.quadTree

	quad_destroy(quadTree, true)
end

function sc.display.server_createData(self)
	local server_clear = sc.display.server_clear
	local server_drawPixel = sc.display.server_drawPixel
	local server_drawRect = sc.display.server_drawRect
	local server_fillRect = sc.display.server_fillRect
	local server_drawCircle = sc.display.server_drawCircle
	local server_fillCircle = sc.display.server_fillCircle
	local server_drawLine = sc.display.server_drawLine
	local server_drawText = sc.display.server_drawText
	local server_optimize = sc.display.server_optimize
	local server_flushStack = sc.display.server_flushStack

	local width = self.width
	local height = self.height

	local data = {
		getWidth = function () return width end,
		getHeight = function () return height end,
		clear = function (color)
			self.isStackCheckEnable = nil
			self.renderingStack = {}

			table_insert(self.renderingStack, {
				type = sc_display_drawType.clear,
				--color = formatColorStr(color, true)
				color = color
			})
		end,
		drawPixel = function (x, y, color)
			table_insert(self.renderingStack, {
				type = sc_display_drawType.drawPixel,
				x = x,
				y = y,
				--color = formatColorStr(color)
				color = color
			})
		end,
		drawRect = function (x, y, w, h, c) server_drawRect(self, x, y, w, h, c) end,
		fillRect = function (x, y, w, h, c) server_fillRect(self, x, y, w, h, c) end,
		drawCircle = function (x, y, r, c) server_drawCircle(self, x + 0.5, y + 0.5, r, c) end, -- +0.5 because center of pixel
		fillCircle = function (x, y, r, c) server_fillCircle(self, x + 0.5, y + 0.5, r, c) end,
		drawLine = function (x, y, x1, y1, c) server_drawLine(self, x, y, x1, y1, c) end,
		drawText = function (x, y, text, c)
			self.isStackCheckEnable = true
			server_drawText(self, x, y, text, c)
		end,
		optimize = function () server_optimize(self) end,
		update = function () server_flushStack(self) end,
		flush = function () server_flushStack(self) end,
		
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

		setFont = function (font)
			checkArg(1, font, "table", "nil")
			if font then
				self.customFont = {
					width = font.width,
					height = font.height,
					chars = sc.display.optimizeFont(font.chars, font.width, font.height)
				}
			else
				self.customFont = nil
			end
			self.needSendData = true
		end,

		getFontWidth = function ()
			return (self.customFont and self.customFont.width) or font_width
		end,

		getFontHeight = function ()
			return (self.customFont and self.customFont.height) or font_height
		end,

		setClicksAllowed = function (c)
			if type(c) == "boolean" then
				sc.display.server_setClicksAllowed(self, c)
			else
				error("Type must be boolean")
			end
		end,
		getClicksAllowed = function () return self.clicksAllowed end,

		setRenderAtDistance = function (c)
			if type(c) == "boolean" then
				sc.display.server_setRenderAtDistance(self, c)
			else
				error("Type must be boolean")
			end
		end,
		getRenderAtDistance = function () return self.renderAtDistance end,

		setSkipAtLags = function (state)
			if type(state) == "boolean" then
				sc.display.server_setSkipAtLags(self, state)
			else
				error("Type must be boolean")
			end
		end,
		getSkipAtLags = function () return self.skipAtLags end
	}
	return data
end

function sc.display.server_createNetworkData(self)
	return {
		renderAtDistance = self.renderAtDistance,
		clicksAllowed = self.clicksAllowed,
		skipAtLags = self.skipAtLags,
		restrictions = sc.restrictions
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

function sc.display.server_setSkipAtLags(self, c)
	if self.skipAtLags ~= c then
		self.skipAtLags = c
		self.needSendData = true
	end
end

function sc.display.server_clear(self, color)
	
end

function sc.display.server_drawPixel(self, x, y, color)
	
end

function sc.display.server_drawRect(self, x, y, w, h, color)
	table_insert(self.renderingStack, {
		type = sc_display_drawType.drawRect,
		x = x,
		y = y,
		w = w,
		h = h,
		--color = formatColorStr(color)
		color = color
	})
end

function sc.display.server_fillRect(self, x, y, w, h, color)
	table_insert(self.renderingStack, {
		type = sc_display_drawType.fillRect,
		x = x,
		y = y,
		w = w,
		h = h,
		--color = formatColorStr(color)
		color = color
	})
end

function sc.display.server_drawCircle(self, x, y, r, color)
	table_insert(self.renderingStack, {
		type = sc_display_drawType.drawCircle,
		x = x,
		y = y,
		r = r,
		--color = formatColorStr(color)
		color = color
	})
end

function sc.display.server_fillCircle(self, x, y, r, color)
	table_insert(self.renderingStack, {
		type = sc_display_drawType.fillCircle,
		x = x,
		y = y,
		r = r,
		--color = formatColorStr(color)
		color = color
	})
end

function sc.display.server_drawLine(self, x, y, x1, y1, color)
	table_insert(self.renderingStack, {
		type = sc_display_drawType.drawLine,
		x = x,
		y = y,
		x1 = x1,
		y1 = y1,
		--color = formatColorStr(color)
		color = color
	})
end

function sc.display.server_drawText(self, x, y, text, color)
	table_insert(self.renderingStack, {
		type = sc_display_drawType.drawText,
		x = x,
		y = y,
		text = text,
		--color = formatColorStr(color)
		color = color
	})
end

function sc.display.server_optimize(self)
	table_insert(self.renderingStack, {
		type = sc_display_drawType.optimize
	})
end

function sc.display.server_flushStack(self)
	self.needUpdate = true
end

function sc.display.server_onDataRequired(self, client)
	--self.dbuffPixels = {}
	--self.dbuffPixelsAll = nil

	self.scriptableObject.network:sendToClient(client, "client_onDataResponse", sc.display.server_createNetworkData(self))
	sendFont(self, client)
end

function sc.display.server_recvPress(self, p)
	local d = self.clickData
	if #d <= self.maxClicks then
		table_insert(d, p)
	end
end


function sc_display_client_clear(self, color, removeAll)
	self.lastLastClearColor = color

	local quadTree = self.quadTree
	if removeAll then
		if quadTree then
			quad_destroy(quadTree, true)
		end

		local size = math_max(self.width, self.height)
		local root = quad_createRoot(self, 0, 0, size, self.width, self.height)
		self.quadTree = root
		quadTree = root

		--total_effects = 1 --в мире можно быть много дисплеев
	end

	-------------------------

	if quadTree.children then
		quad_destroyChildren(quadTree)
	end

	--[[
	if quadTree.color ~= color then
		quadTree.color = color
		quad_updateEffectColor(quadTree)
	end
	]]

	--if self.isRendering then
	--	quad_effectShow(quadTree.effect)
	--end

	--effect_setParameter(self.quadTree.back_effect, "color", color)

	self.dbuffPixels = {}
	self.dbuffPixelsAll = color
end

sc.display.client_clear = sc_display_client_clear

function sc_display_client_drawPixelForce(self, x, y, color)
	local width = self.width
	local currentColor = self.dbuffPixels[x + (y * width)] or self.dbuffPixelsAll

	if not currentColor or currentColor ~= color then
		quad_treeSetColor(self.quadTree, x, y, color)
		self.dbuffPixels[x + (y * width)] = color
	else
		return true
	end
end

sc.display.client_drawPixelForce = sc_display_client_drawPixelForce

function sc_display_client_drawPixel(self, x, y, color)
	x = math_floor(x)
	y = math_floor(y)

	if x >= 0 and x < self.width and y >= 0 and y < self.height then
		return sc_display_client_drawPixelForce(self, x, y, color)
	end
end

sc.display.client_drawPixel = sc_display_client_drawPixel

function sc_display_client_drawRect(self, x, y, w, h, color)
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
	quad_treeFillRect(self.quadTree, math_floor(x), math_floor(y), math_floor(w), math_floor(h), color)
	for cx = x, x + (w - 1) do
		for cy = y, y + (h - 1) do
			if cx >= 0 and cy >= 0 and cx < self.width and cy < self.height then
				self.dbuffPixels[cx + (cy * self.width)] = color
			end
		end
	end
end

sc.display.client_fillRect = sc_display_client_fillRect

function drawCircle_putpixel(self, cx, cy, x, y, color)
	local posDX_x = cx + x
	local negDX_x = cx - x
	local posDX_y = cx + y
	local negDX_y = cx - y

	local posDY_y = cy + y
	local negDY_y = cy - y
	local posDY_x = cy + x
	local negDY_x = cy - x

	sc_display_client_drawPixel(self, posDX_x, posDY_y, color)
	sc_display_client_drawPixel(self, negDX_x, posDY_y, color)
	sc_display_client_drawPixel(self, posDX_x, negDY_y, color)
	sc_display_client_drawPixel(self, negDX_x, negDY_y, color)
	sc_display_client_drawPixel(self, posDX_y, posDY_x, color)
	sc_display_client_drawPixel(self, negDX_y, posDY_x, color)
	sc_display_client_drawPixel(self, posDX_y, negDY_x, color)
	sc_display_client_drawPixel(self, negDX_y, negDY_x, color)
end

function sc_display_client_drawCircle(self, x, y, r, color)
	--self.dbuffPixels = {}
	--self.dbuffPixelsAll = nil

	x = math_floor(x)
	y = math_floor(y)
	r = math_floor(r)

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
	self.dbuffPixels = {}
	self.dbuffPixelsAll = nil

	quad_treeFillCircle(self.quadTree, x, y, r, color)
end

sc.display.client_fillCircle = sc_display_client_fillCircle

function sc_display_client_drawLineForce(self, x, y, x1, y1, color)
	x = math_floor(x)
	y = math_floor(y)
	x1 = math_floor(x1)
	y1 = math_floor(y1)

	local dx = math_abs(x1 - x)
    local sx = x < x1 and 1 or -1
    local dy = -math_abs(y1 - y)
    local sy = y < y1 and 1 or -1

    local drawPixel = sc_display_client_drawPixelForce
    
    local error = dx + dy
	local e2
    while true do
        drawPixel(self, x, y, color)

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
end

sc.display.client_drawLineForce = sc_display_client_drawLineForce


-- y = y0 + round( (x-x0) * dy / dx )
function sc_display_client_drawLine(self, x, y, x1, y1, color)
	x = math_floor(x)
	y = math_floor(y)
	x1 = math_floor(x1)
	y1 = math_floor(y1)

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

local function loadChar(self, c)
	local chars = font_chars
	if self.customFont and self.customFont.chars then
		chars = self.customFont.chars
	end
	local pixels = chars[c]

	if not pixels then
		pixels = chars.error or font_chars.error
	end
	return pixels
end

local drawPixelForce = sc_display_client_drawPixelForce
local function sc_display_client_drawCharForce(self, x, y, c, color)
	local pixels = loadChar(self, c)
	local v
	for i = 1, #pixels do
		v = pixels[i]
		drawPixelForce(self, x + v[1], y + v[2], color)
	end
end

sc.display.client_drawCharForce = sc_display_client_drawCharForce

local drawPixel = sc_display_client_drawPixel
local function sc_display_client_drawChar(self, x, y, c, color)
	local pixels = loadChar(self, c)
	local v
	for i = 1, #pixels do
		v = pixels[i]
		drawPixel(self, x + v[1], y + v[2], color)
	end
end

sc.display.client_drawChar = sc_display_client_drawChar

local _utf8_sub = _utf8.sub
local _utf8_len = _utf8.len
local drawChar = sc_display_client_drawChar
local drawCharForce = sc_display_client_drawCharForce
local function sc_display_client_drawText(self, x, y, text, color)
	x = math_floor(x)
	y = math_floor(y)

	local len = _utf8_len(text)
	local font_width = (self.customFont and self.customFont.width) or font_width
	local font_height = (self.customFont and self.customFont.height) or font_height
	local width, height = self.width, self.height

	if x < 0 then
		local ic = 1
		while x + font_width < 0 do
			x = x + font_width + 1
			ic = ic + 1
			if ic > len or x >= width then
				return
			end
		end
		drawChar(self, x, y, _utf8_sub(text, ic, ic), color)
		x = x + font_width + 1
		text = _utf8_sub(text, ic + 1, len)
		len = _utf8_len(text)
	end

	--старый вариант
	--if y >= 0 and (y + font_height) < self.height then
    --вот допустим размер шрифта по вертикали 1, в таком случаи предельное значения(например 127) окажеться не в пределах, так как 127 + 1 это 128, а 128 не меньше 128
	
	local ex, c
	if y >= 0 and (y + font_height) <= height then
		for i = 1, len do
			c = _utf8_sub(text, i, i)

			ex = x + font_width
			if ex < width then
				drawCharForce(self, x, y, c, color)
			else
				drawChar(self, x, y, c, color)
				break
			end
			x = ex + 1
		end
	else
		for i = 1, len do
			c = _utf8_sub(text, i, i)

			ex = x + font_width
			drawChar(self, x, y, c, color)
			if ex >= width then
				break
			end
			x = ex + 1
		end
	end

	--НЕ ВРУБАЙТЬ!!
	--ДАЖЕ ЕСЛИ ОСНОВНОЙ КОД БАГОВОНЫЙ
	--ОНО НЕ ОПТИМИЗИРОВАННО
	--[[
	for i = 1, #text do
		drawChar(self, x, y, string_sub(text, i, i), color)
		x = x + font_width + 1
	end
	]]
end

sc.display.client_drawText = sc_display_client_drawText

function sc_display_client_optimize(self)
	quad_optimize(self.quadTree)
end

sc.display.client_optimize = sc_display_client_optimize

function sc.display.client_update(self, dt)
	--debug_print("total_effects", total_effects)
	--[[
	local allEffs = 0
	for key, value in pairs(self.quadTree.allEffects) do
		allEffs = allEffs + 1
	end
	debug_print("allEffs", allEffs)
	]]

	local scriptableObject = self.scriptableObject
	local quadTree = self.quadTree
	local bufferedEffects = quadTree.bufferedEffects
	local allEffects = quadTree.allEffects

	--debug_print("total_effects", total_effects, #bufferedEffects)

	if #bufferedEffects >= 10000 then
		local effect
		for i = 1, 250 do
			if #bufferedEffects >= 10000 then
				effect = table_remove(bufferedEffects)
				if effect and sm_exists(effect) then
					effect_stop(effect)
					effect_destroy(effect)
					total_effects = total_effects - 1

					allEffects[effect] = nil
				end
			end
		end
	end

	--debug_print("cursor works")
	if scriptableObject.character and self.clicksAllowed and self.tablet_posX and self.tablet_posY then
		if not self.cursor then
			self.cursor = quad_createEffect(quadTree, 0, 0, 0.02, 0.02, -0.5, true, true)
			--self.cursor:setParameter("color", sm.color.new("FF0000FF"))
			effect_setParameter(self.cursor, "color", sm.color.new("FF0000FF"))
			effect_start(self.cursor)
		else
			if sm_exists(self.cursor) then
				effect_setOffsetPosition(self.cursor, effectsData[self.cursor.id].offset - sm_vec3_new((self.tablet_posX / self.width) * 0.91, (self.tablet_posY / self.height) * 0.91, 0))
			else
				self.cursor = nil
			end
		end
	elseif self.cursor then
		effect_stop(self.cursor)
		effect_destroy(self.cursor)
		self.cursor = nil
	end

	--debug_print("dispValue works")
	if self.dispValue then
		self.dispValue = self.dispValue - 1
		if self.dispValue <= 0 then
			self.dispValue = nil
			
			debug_print("lastClearColor", self.lastClearColor)

			self.newEffects = {}
			sc_display_client_clear(self, self.lastClearColor, true)
			applyNew(self)
			self.newEffects = nil

			self.lastClearColor = nil
		end
	end

	local ctick = getCurrentTick()
	if self.clientDrawingTimer and
	(not self.old_autooptimize or self.optimize_flag or
	ctick - self.old_autooptimize > 80 --[[or
	ctick - self.clientDrawingTimer >= 40]]) then
		self.old_autooptimize = ctick
		self.optimize_flag = nil
		
		debug_print("autooptimize")

		self.newEffects = {}
		quad_optimize(quadTree)
		applyNew(self)
		self.newEffects = nil
	end
	

	local localPlayer = sm_localPlayer_getPlayer().character
	if localPlayer then
		local playerPos = localPlayer.worldPosition
		local selfPos
		if scriptableObject.shape then
			selfPos = scriptableObject.shape.worldPosition
		else
			selfPos = scriptableObject.character.worldPosition
		end

		local nowIsRendering = false
		local dist = mathDist(selfPos, playerPos)

		local r = (self.restrictions and self.restrictions.rend) or RENDER_DISTANCE
		if not scriptableObject.character then
			if self.renderAtDistance or dist < r then
				if self.renderAtDistance then
					nowIsRendering = true
				elseif self.last_raycast_time then
					nowIsRendering = (getCurrentTick() - self.last_raycast_time) < 40
				end

				if not nowIsRendering then
					if not self.restrictions or self.restrictions.rays == 0 then
						nowIsRendering = true
					else
						local detectedShapes = cl_displayRaycast(self, r)
						for shape, result in pairs(detectedShapes) do
							if shape.id == scriptableObject.shape.id then
								local localPoint = shape:transformPoint(result.pointWorld)
		
								if localPoint and localPoint.x < 0 then
									local localPoint = sm_vec3_new(0, localPoint.y, localPoint.z)
									local scale = sc_display_PIXEL_SCALE * self.pixelScale
					
									local pointX = math_floor(self.width / 2 - localPoint.z / scale)
									local pointY = math_floor(self.height / 2 + localPoint.y / scale)
								
									if pointX >= 0 and pointX < self.width and pointY >= 0 and pointY < self.height then
										nowIsRendering = true
										self.last_raycast_time = getCurrentTick()
										break
									end
								end
							end
						end
					end
				end
			end
		else
			if self.tablet_posX or self.renderAtDistance then
				nowIsRendering = true
			end
		end

		--debug_print("isRendering works")
		local nowRender
		if self.isRendering ~= nowIsRendering then
			if nowIsRendering then
				nowRender = true
				quad_rootRealShow(quadTree, self)
			else
				quad_rootRealHide(quadTree, self)
			end
		end
		self.isRendering = nowIsRendering

		--debug_print("click works")
		if self.dragging.interact then
			sc.display.client_onClick(self, 1, "drag")
		elseif self.dragging.tinker then
			sc.display.client_onClick(self, 2, "drag")
		end

		--debug_print("random_hide_show works")
		if self.isRendering and self.restrictions and self.restrictions.opt then
			local meters = math_floor(dist + 0.5) * self.restrictions.optSpeed
			if meters ~= self.meters or nowRender or not self.old_opt then
				--if self.clientDrawingTimer then
				--	random_hide_show(self, 0)
				--end
				--debug_print("meters changed")
				
				local p = 0
				if meters > 4 then
					p = (meters / self.pixelScale) * 4
					p = constrain(p, 0, 100)
					if p < 10 then
						p = 0
					--elseif p > 60 then
					--	p = (p * 0.5) + 30
					end
					if p > 80 then
						p = 80
					end
				end

				if not self.old_p then self.old_p = p end
				--print("P", p, self.old_p, math.abs(p - self.old_p))
				if math_abs(p - self.old_p) > 5 or nowRender or not self.old_opt then
					random_hide_show(self, p)
					self.old_p = p
				end

				self.meters = meters
			end
		end

		if self.isRendering then
			if self.old_opt and not self.restrictions.opt then
				random_hide_show(self, 0)
			end
		end
		self.old_opt = self.restrictions.opt
	end

	--debug_print("self.restrictions", self.restrictions, self.isRendering and self.restrictions and self.restrictions.opt)

	--[[
	if (getCurrentTick() + self.rnd) % (40 * 4) == 40 then
		debug_print("clear doValueHashCache")
		doValueHashCache = {}
	end
	]]

	------stylus
	--debug_print("stylus works")
	if scriptableObject.character then
		if self.tablet_left ~= self.old_tablet_left then
			sc.display.client_onInteract(self, nil, not not self.tablet_left)
		end
	
		if self.tablet_right ~= self.old_tablet_right then
			sc.display.client_onTinker(self, nil, not not self.tablet_right)
		end

		self.old_tablet_left = self.tablet_left
		self.old_tablet_right = self.tablet_right
	else
		if _G.stylus_left ~= self.old_stylus_left then
			sc.display.client_onInteract(self, nil, not not _G.stylus_left)
		end
	
		if _G.stylus_right ~= self.old_stylus_right then
			sc.display.client_onTinker(self, nil, not not _G.stylus_right)
		end

		self.old_stylus_left = _G.stylus_left
		self.old_stylus_right = _G.stylus_right
	end

	------end
	self.clientDrawingTimer = nil
end

function sc.display.client_onDataResponse(self, data)
	debug_print("client_onDataResponse", data)
	local font_data = data.fontdata
	if font_data then
		if not sm.isHost then
			if font_data.remove then
				debug_print("custom font erase")
				self.customFont = nil
			else
				if font_data.width then
					debug_print("custom font init")
					self.customFont = {width = font_data.width, height = font_data.height, chars = {}}
				else
					--debug_print("custom font add", font_data.name, tostring(font_data.data))
					self.customFont.chars[font_data.name] = font_data.data
				end
			end
		end
		return
	end

	self.restrictions = data.restrictions

	if sm.isHost then return end
	self.clicksAllowed = data.clicksAllowed
	self.renderAtDistance = data.renderAtDistance
	self.skipAtLags = data.skipAtLags
end


local drawActions = {
	[sc_display_drawType.clear] = function (self, t) return sc_display_client_clear(self, t.color) end,
	[sc_display_drawType.drawPixel] = function (self, t) return sc_display_client_drawPixel(self, t.x, t.y, t.color) end,
	[sc_display_drawType.drawRect] = function (self, t) return sc_display_client_drawRect(self, t.x, t.y, t.w, t.h, t.color) end,
	[sc_display_drawType.fillRect] = function (self, t) return sc_display_client_fillRect(self, t.x, t.y, t.w, t.h, t.color) end,
	[sc_display_drawType.drawCircle] = function (self, t) return sc_display_client_drawCircle(self, t.x, t.y, t.r, t.color) end,
	[sc_display_drawType.fillCircle] = function (self, t) return sc_display_client_fillCircle(self, t.x, t.y, t.r, t.color) end,
	[sc_display_drawType.drawLine] = function (self, t) return sc_display_client_drawLine(self, t.x, t.y, t.x1, t.y1,t.color) end,
	[sc_display_drawType.drawText] = function (self, t) return sc_display_client_drawText(self, t.x, t.y, t.text, t.color) end,
	[sc_display_drawType.optimize] = function (self) self.optimize_flag = true end,
}

function sc.display.client_drawStack(self, sendstack)
	sendstack = sendstack or self.scriptableObject.sendData
	if sendstack then
		if not sendstack.endPack then
			if not self.savestack then self.savestack = {} end
			for _, value in ipairs(sendstack) do
				table_insert(self.savestack, value)
			end
			return
		else
			if self.savestack then
				for _, value in ipairs(sendstack) do
					table_insert(self.savestack, value)
				end
			else
				self.savestack = sendstack
			end
		end
	end
	local stack = self.savestack
	self.savestack = nil
	if not stack then
		return
	end



	--if not self.isRendering and not self.scriptableObject.character then return end
	
	-- to save minimal fps
	if self.skipAtLags then 
		--if  (sc.deltaTime >= SKIP_RENDER_DT_ALL) or 
		--    (self.renderAtDistance and sc.deltaTime >= SKIP_RENDER_DT) 
		--	then return end
		if self.restrictions and sc.deltaTime >= (1 / self.restrictions.skipFps) then return end
	end

	local isEndClear = false
	local clearColor
	self.newEffects = {}
	local isEffect --если от всего стека был хоть какой-то смысл
	for _, v in ipairs(stack) do
		v.color = formatColor(v.color, true)
		
		if v.type == sc_display_drawType.clear then
			clearColor = v.color
			isEndClear = true
		elseif v.type == sc_display_drawType.optimize then
		else
			isEndClear = false
		end

		--если хоть что-то не вернуло значения, значит эфект от стека был
		if v.type ~= sc_display_drawType.optimize and not drawActions[v.type](self, v) then
			isEffect = true
		end
	end
	
	--debug_print("isEffect", isEffect)
	if isEffect then
		if isEndClear then
			self.lastClearColor = clearColor
			self.dispValue = 40 * 2
		else
			self.lastClearColor = nil
			self.dispValue = nil
		end
		
		self.clientDrawingTimer = getCurrentTick()

		applyNew(self)
	end
	self.newEffects = nil
end


function sc.display.client_onClick(self, type, action) -- type - 1:interact|2:tinker (e.g 1 or 2), action - pressed, released, drag
	if not self.clicksAllowed then
		return
	end

	local function detect(pointX, pointY)
		pointX = math_floor(pointX + 0.5)
		pointY = math_floor(pointY + 0.5)

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
	
	if not self.scriptableObject.shape then
		if self.tablet_posX and self.tablet_posY then
			detect(self.tablet_posX, self.tablet_posY)
		end
	else
		local succ, res = sm_localPlayer.getRaycast((self.restrictions and self.restrictions.rend) or RENDER_DISTANCE)
		if succ then
			local shape = self.scriptableObject.shape
			local localPoint = shape:transformPoint(res.pointWorld)
	
			if localPoint and localPoint.x < 0 then
				local localPoint = sm_vec3_new(0, localPoint.y, localPoint.z)
				local scale = sc_display_PIXEL_SCALE * self.pixelScale

				local pointX = math_floor(self.width / 2 - localPoint.z / scale)
				local pointY = math_floor(self.height / 2 + localPoint.y / scale)
			
				detect(pointX, pointY)
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