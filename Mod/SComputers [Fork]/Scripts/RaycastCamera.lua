dofile '$CONTENT_DATA/Scripts/Config.lua'

RaycastCamera = class(nil)

RaycastCamera.maxParentCount = 0
RaycastCamera.maxChildCount = 1
RaycastCamera.connectionOutput = sm.interactable.connectionType.composite
RaycastCamera.colorNormal = sm.color.new(0x139d9eff)
RaycastCamera.colorHighlight = sm.color.new(0x1adbddff)
RaycastCamera.componentType = "camera"

local rc_raycast = sm.physics.raycast
local rc_multicast = sm.physics.multicast
local rc_insert = table.insert
local rc_remove = table.remove
local rc_vec3_new = sm.vec3.new
local rc_floor = math.floor
local rc_color_new = sm.color.new

local vec3_new = rc_vec3_new
local floor = rc_floor
local insert = rc_insert

local formatColor = sc.formatColor
local formatColorStr = sc.formatColorStr
local tostring = tostring

local rad_0 = math.rad(0)
local rad_1 = math.rad(1)
local rad_45 = math.rad(45)
local rad_60 = math.rad(60)
local rad_90 = math.rad(90)

function RaycastCamera:createData()
	return {
		drawColorWithDepth = function (display, noCollideColor, terrainColor, unitsColor)
			self:server_drawColorWithDepth(display, noCollideColor, terrainColor, unitsColor)
		end,
		drawColor = function (display, noCollideColor, terrainColor, unitsColor)
			self:server_drawColor(display, noCollideColor, terrainColor, unitsColor)
		end,
		drawDepth = function (display, baseColor, noCollideColor, unitsColor)
			self:server_drawDepth(display, baseColor, noCollideColor, unitsColor)
		end,
		drawCustom = function (display, drawer)
			self:server_drawCustom(display, drawer)
		end,
		drawAdvanced = function (display)
			self:server_drawAdvanced(display)
		end,
		rawRay = function (x, y, maxdist)
			return self:sv_rawRay(x, y, maxdist)
		end,
		getSkyColor = function ()
			return self:sv_getSkyColor()
		end,
		
		setStep = function (step)
			if type(step) == "number" and step % 1 == 0 and step > 0 and step <= 2048 then
				self.step = step
				self.stepM = self.step - 1
			else
				error("integer must be in [1; 2048]")
			end
		end,
		getStep = function () return self.step end,
		setDistance = function (dist) 
			if type(dist) == "number" and dist >= 0 then
				self.distance = dist
				if self.distance > 2048 then
					self.distance = 2048
				end
			else
				error("number must be (0; 2048)")
			end
		end,
		getDistance = function () return self.distance end,
		setFov = function (fov)
			checkArg(1, fov, "number")
			if fov < rad_1 then
				self.fov = rad_1
			elseif fov > rad_90 then
				self.fov = rad_90
			else
				self.fov = fov
			end
		end,
		getFov = function () return self.fov end,
		getNextPixel = function () return self.nextPixel end,
		resetCounter = function () self.nextPixel = 0 end
	}
end

function RaycastCamera:server_rays(displayData)
	local shape = self.shape
	local position = shape:getWorldPosition()
	local rotation = shape:getWorldRotation()
	
	local resolutionX, resolutionY = displayData.getWidth(), displayData.getHeight()

	local currentPixel = self.nextPixel

	local stepM = self.stepM
	local distance = self.distance
	local fov = self.fov

	local rays = {}
	local raysI = 0
	for i = 0, stepM do
		local pixel = currentPixel + i
		local x = floor(pixel / resolutionY) % resolutionX
		local y = pixel % resolutionY

		local u = ( x / resolutionX - 0.5 ) * fov
		local v = ( y / resolutionY - 0.5 ) * fov

		local direction = rotation * vec3_new( -u, -v, 1 )

		raysI = raysI + 1
		rays[raysI] = {
			type = "ray",
			startPoint = position,
			endPoint = position + direction * distance,
		}
	end

	return rc_multicast(rays)
end

local colors = {
	sm.color.new("#000008"),
	sm.color.new("#182c43"),
	sm.color.new("#6099bb"),
	sm.color.new("#6ab4c8"),
	sm.color.new("#73c4cc"),
	sm.color.new("#7bc9cb"),
	sm.color.new("#93b394"),
	sm.color.new("#c48933"),
	sm.color.new("#c88322"),
	sm.color.new("#643037"),
	sm.color.new("#31073d"),
	sm.color.new("#000008"),
}
function RaycastCamera:sv_getSkyColor()
	local time = self.time or 0
	local index = math.floor(map(time, 0, 1, 1, #colors))
	return colors[index] or colors[1]
end

function RaycastCamera:sv_getRaydata(successful, raydata, maxdist)
	if successful then
		local shape = raydata:getShape()
		local character = raydata:getCharacter()
		local harvestable = raydata:getHarvestable()
		local lift = raydata:getLiftData()
		local joint = raydata:getJoint()
		--local trigger = raydata:getAreaTrigger()

		if shape then
			local tbl =  {
				color = shape.color,
				fraction = raydata.fraction,
				distance = raydata.fraction * maxdist,
				type = "shape"
			}

			if raydata.fraction * maxdist <= 4 then
				tbl.uuid = shape.uuid
			end

			return tbl
		elseif character then
			return {
				color = character:getColor(),
				fraction = raydata.fraction,
				distance = raydata.fraction * maxdist,
				type = "character"
			}
		elseif harvestable then
			return {
				color = harvestable:getColor(),
				fraction = raydata.fraction,
				distance = raydata.fraction * maxdist,
				type = "harvestable"
			}
		elseif lift then
			return {
				fraction = raydata.fraction,
				distance = raydata.fraction * maxdist,
				type = "lift"
			}
		elseif joint then
			return {
				color = joint:getColor(),
				fraction = raydata.fraction,
				distance = raydata.fraction * maxdist,
				type = "joint"
			}

		elseif raydata.type == "limiter" then
			return {
				fraction = raydata.fraction,
				distance = raydata.fraction * maxdist,
				type = "limiter"
			}
		elseif raydata.type == "terrainAsset" then
			return {
				fraction = raydata.fraction,
				distance = raydata.fraction * maxdist,
				type = "asset"
			}		
		else
			return {
				fraction = raydata.fraction,
				distance = raydata.fraction * maxdist,
				type = "terrain"
			}
		end
	end
end

function RaycastCamera:sv_rawRay(xAngle, yAngle, maxdist)
	local shape = self.shape
	local position = shape:getWorldPosition()
	local rotation = shape:getWorldRotation()

	if xAngle < -rad_45 then
		xAngle = -rad_45
	elseif xAngle > rad_45 then
		xAngle = rad_45
	end

	if yAngle < -rad_45 then
		yAngle = -rad_45
	elseif yAngle > rad_45 then
		yAngle = rad_45
	end

	local successful, raydata = rc_raycast(position, position + (rotation * vec3_new(-xAngle, -yAngle, 1)) * maxdist)
	return self:sv_getRaydata(successful, raydata, maxdist)
end

function RaycastCamera:server_drawAdvanced(displayData)
	local function addDot(posx, posy, dist, color)
		if dist and dist > 0 and math.floor(((posx + 1.523) + (posy * 2.131)) % constrain(dist, 1, 128)) == 0 then
			color = color * 0.9
		end
		return color
	end

	local function drawer(posx, posy, raydata)
		if not raydata or raydata.type == "limiter" then return addDot(posx, posy, raydata and raydata.distance, self:sv_getSkyColor()) end
		--if raydata.type == "limiter" then return posx % 2 == 0 and sm.color.new(1, 1, 0) or sm.color.new(0, 0, 0) end
		local mul = (1 - (raydata.fraction or 0))
		if raydata.type == "asset" then return addDot(posx, posy, raydata.distance, sm.color.new(0.5, 0.5, 0.5) * mul) end
        return addDot(posx, posy, raydata.distance, (raydata.color or sm.color.new("13a20d")) * mul)
	end

	return self:server_drawCustom(displayData, drawer)
end

function RaycastCamera:server_drawCustom(displayData, drawer)
	local results = self:server_rays(displayData)
	local resolutionX, resolutionY = displayData.getWidth(), displayData.getHeight()
	local currentPixel = self.nextPixel
	local drawPixel = displayData.drawPixel
	
	for i = 0, self.stepM do
		local res = results[i+1]
		local pixel = currentPixel + i

		local x = floor(pixel / resolutionY) % resolutionX
		local y = pixel % resolutionY
		drawPixel(x, y, formatColorStr(drawer(x, y, self:sv_getRaydata(res and res[1], res[2], self.distance)), true))
	end

	self.nextPixel = (currentPixel + self.step) % (resolutionX * resolutionY)
end

function RaycastCamera:server_drawColorWithDepth(displayData, noCollideColor, terrainColor, unitsColor)
	noCollideColor = formatColorStr(noCollideColor or "000000")
	terrainColor = formatColor(terrainColor or "666666")
	unitsColor = formatColor(unitsColor or "ffffff")

	local results = self:server_rays(displayData)
	local resolutionX, resolutionY = displayData.getWidth(), displayData.getHeight()
	local currentPixel = self.nextPixel
	local drawPixel = displayData.drawPixel
	
	for i = 0, self.stepM do
		local res = results[i+1]
		local pixel = currentPixel + i

		local x = floor(pixel / resolutionY) % resolutionX
		local y = pixel % resolutionY
		if res and res[1] then
			local data = res[2]
			local shape = data:getShape()
			local character = data:getCharacter()
			if character then
				drawPixel(x, y, tostring(unitsColor * (1 - data.fraction)))
			elseif shape then
				drawPixel(x, y, tostring(shape.color * (1 - data.fraction)))
			elseif data.type ~= "limiter" then
				drawPixel(x, y, tostring(terrainColor * (1 - data.fraction)))
			else
				drawPixel(x, y, noCollideColor)
			end
		else
			drawPixel(x, y, noCollideColor)
		end
	end

	self.nextPixel = (currentPixel + self.step) % (resolutionX * resolutionY)
end

function RaycastCamera:server_drawDepth(displayData, baseColor, noCollideColor, unitsColor)
	baseColor = formatColor(baseColor or "666666")
	noCollideColor = formatColorStr(noCollideColor or "000000")
	unitsColor = formatColor(unitsColor or "ffffff")

	local results = self:server_rays(displayData)
	local resolutionX, resolutionY = displayData.getWidth(), displayData.getHeight()
	local currentPixel = self.nextPixel
	local drawPixel = displayData.drawPixel
	for i = 0, self.stepM do
		local res = results[i+1]
		local pixel = currentPixel + i

		local x = floor(pixel / resolutionY) % resolutionX
		local y = pixel % resolutionY
		if res and res[1] then
			local data = res[2]
			local character = data:getCharacter()
			if character then
				drawPixel(x, y, tostring(unitsColor * (1 - data.fraction)))
			elseif data.type ~= "limiter" then
				drawPixel(x, y, tostring(baseColor * (1 - data.fraction)))
			else
				drawPixel(x, y, noCollideColor)
			end
		else
			drawPixel(x, y, noCollideColor)
		end
	end

	self.nextPixel = (currentPixel + self.step) % (resolutionX * resolutionY)
end

function RaycastCamera:server_drawColor(displayData, noCollideColor, terrainColor, unitsColor)
	noCollideColor = formatColorStr(noCollideColor or "45c2de")
	terrainColor = formatColorStr(terrainColor or "666666")
	unitsColor = formatColorStr(unitsColor or "ffffff")

	local results = self:server_rays(displayData)
	local resolutionX, resolutionY = displayData.getWidth(), displayData.getHeight()
	local currentPixel = self.nextPixel
	local drawPixel = displayData.drawPixel
	for i = 0, self.stepM do
		local res = results[i+1]
		local pixel = currentPixel + i

		local x = floor(pixel / resolutionY) % resolutionX
		local y = pixel % resolutionY
		if res and res[1] then
			local data = res[2]
			local shape = data:getShape()
			local character = data:getCharacter()
			if character then
				drawPixel(x, y, unitsColor)
			elseif shape then
				drawPixel(x, y, tostring(shape.color))
			elseif data.type ~= "limiter" then
				drawPixel(x, y, terrainColor)
			else
				drawPixel(x, y, noCollideColor)
			end
		else
			drawPixel(x, y, noCollideColor)
		end
	end

	self.nextPixel = (currentPixel + self.step) % (resolutionX * resolutionY)
end

function RaycastCamera.server_onCreate(self)
	sc.camerasDatas[self.interactable:getId()] = self:createData()

	self.step = 256
	self.stepM = self.step - 1
	self.nextPixel = 0
	self.distance = 250
	self.fov = rad_60
end

function RaycastCamera.server_onDestroy(self)
	sc.camerasDatas[self.interactable:getId()] = nil
end



function RaycastCamera:sv_n_settime(value)
	self.time = value
end

function RaycastCamera:client_onCreate()
	if sm.isHost then
		self.network:sendToServer("sv_n_settime", sm.render.getOutdoorLighting())
	end
end

function RaycastCamera:client_onFixedUpdate()
	if sm.isHost and sm.game.getCurrentTick() % 40 == 0 then
		self.network:sendToServer("sv_n_settime", sm.render.getOutdoorLighting())
	end
end