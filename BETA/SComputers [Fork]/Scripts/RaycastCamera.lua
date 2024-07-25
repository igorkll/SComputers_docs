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
        drawCustom = function (display, drawer, ...)
            self:server_drawCustom(display, drawer, ...)
        end,
        drawAdvanced = function (...)
            self:server_drawAdvanced(...)
        end,
        rawRay = function (x, y, maxdist)
            return self:sv_rawRay(x, y, maxdist)
        end,
        getSkyColor = function ()
            return self:sv_getSkyColor()
        end,
        
        setStep = function (step)
            if type(step) == "number" and step % 1 == 0 and step > 0 and step <= 2048 then
                if step ~= self.step then
                    self.step = step
                    self.stepM = self.step - 1
                    self.raysCache = {}
                end
            else
                error("integer must be in [1; 2048]")
            end
        end,
        getStep = function () return self.step end,
        setDistance = function (dist) 
            if type(dist) == "number" and dist >= 0 then
                if self.distance > 2048 then
                    self.distance = 2048
                end
                if dist ~= self.distance then
                    self.raysCache = {}
                    self.distance = dist
                end
            else
                error("number must be (0; 2048)")
            end
        end,
        getDistance = function () return self.distance end,
        setFov = function (fov)
            checkArg(1, fov, "number")
            if fov < rad_1 then
                fov = rad_1
            elseif fov > rad_90 then
                fov = rad_90
            end
            if fov ~= self.fov then
                self.raysCache = {}
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

    if self.raysCache.x then
        if self.raysCache.x ~= resolutionX or self.raysCache.y ~= resolutionY then
            self.raysCache = {}
        end
    else
        self.raysCache.x = resolutionX
        self.raysCache.y = resolutionY
    end
    if not self.raysCache[currentPixel] then
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
        self.raysCache[currentPixel] = rays
    end

    return rc_multicast(self.raysCache[currentPixel])
end

local defaultRayColor = sm.color.new("#80A520")
local liftColor = sm.color.new("#ebb700")
local assetColor = sm.color.new("#808080")

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

local materialColors = {
    Rock = sm.color.new("#95977F"),
    Sand = sm.color.new("#FFBA5F"),
    Dirt = sm.color.new("#7E6135")
}

function RaycastCamera:sv_getSkyColor()
    local time = self.time or 0
    local index = math.floor(map(time, 0, 1, 1, #colors))
    return colors[index] or colors[1]
end

function RaycastCamera:sv_getRaydata(successful, raydata, maxdist)
    if not successful then return end

    local rtype = raydata.type
    if rtype == "limiter" then
        return {
            fraction = raydata.fraction,
            distance = raydata.fraction * maxdist,
            type = "limiter"
        }
    elseif rtype == "terrainAsset" then
        return {
            fraction = raydata.fraction,
            distance = raydata.fraction * maxdist,
            normalWorld = raydata.normalWorld,
            color = assetColor,
            type = "asset"
        }
    elseif rtype == "body" then
        local shape = raydata:getShape()
        local tbl =  {
            color = shape.color,
            fraction = raydata.fraction,
            normalWorld = raydata.normalWorld,
            distance = raydata.fraction * maxdist,
            type = "shape"
        }

        if raydata.fraction * maxdist <= 4 then
            tbl.uuid = shape.uuid
        end

        return tbl
    elseif rtype == "character" then
        local character = raydata:getCharacter()
        return {
            color = character:getColor(),
            fraction = raydata.fraction,
            normalWorld = raydata.normalWorld,
            distance = raydata.fraction * maxdist,
            type = "character"
        }
    elseif rtype == "harvestable" then
        local harvestable = raydata:getHarvestable()
        return {
            color = harvestable:getColor(),
            fraction = raydata.fraction,
            normalWorld = raydata.normalWorld,
            distance = raydata.fraction * maxdist,
            type = "harvestable"
        }
    elseif rtype == "lift" then
        local lift = raydata:getLiftData()
        return {
            color = liftColor,
            fraction = raydata.fraction,
            normalWorld = raydata.normalWorld,
            distance = raydata.fraction * maxdist,
            type = "lift"
        }
    elseif rtype == "joint" then
        local joint = raydata:getJoint()
        return {
            color = joint:getColor(),
            fraction = raydata.fraction,
            normalWorld = raydata.normalWorld,
            distance = raydata.fraction * maxdist,
            type = "joint"
        }
    else
        return {
            fraction = raydata.fraction,
            distance = raydata.fraction * maxdist,
            normalWorld = raydata.normalWorld,
            color = materialColors[sm.physics.getGroundMaterial(raydata.pointWorld)],
            type = "terrain"
        }
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

local constrain = constrain
local floor = math.floor
local abs = math.abs
local max = math.max
local shadowVec = sm.vec3.new(0, 0, 0.8)
local function addDot(posx, posy, dist, color, noSpatialPoints, width)
    if not noSpatialPoints and dist and dist > 0 then
        local step = map(constrain(dist, 1, 64), 1, 64, 1, width / 3)
        if step < 2 then step = 2 end
        if posy % 2 == 0 and floor((posx + 1) % step) == 0 then
            color = color * 0.92
        end
    end
    color.a = 1
    return color
end

local function drawAdvanced(posx, posy, raydata, noSpatialPoints, skyColor, width)
    if not raydata or raydata.type == "limiter" then
        return addDot(posx, posy, raydata and raydata.distance, skyColor, true)
    end
    local mul = (1 - (raydata.fraction or 0))
    local shadowMul = 1
    if raydata.normalWorld then
        shadowMul = max((shadowVec:dot(raydata.normalWorld) + 1) / 2, 0.2)
    end
    return addDot(posx, posy, raydata.distance, (raydata.color or defaultRayColor) * mul * shadowMul, noSpatialPoints, width)
end

function RaycastCamera:server_drawAdvanced(displayData, noSpatialPoints)
    return self:server_drawCustom(displayData, drawAdvanced, noSpatialPoints, self:sv_getSkyColor(), displayData.getWidth())
end

function RaycastCamera:server_drawCustom(displayData, drawer, ...)
    local results = self:server_rays(displayData)
    local resolutionX, resolutionY = displayData.getWidth(), displayData.getHeight()
    local currentPixel = self.nextPixel
    local drawPixel = displayData.drawPixel
    
    for i = 0, self.stepM do
        local res = results[i+1]
        local pixel = currentPixel + i

        local x = floor(pixel / resolutionY) % resolutionX
        local y = pixel % resolutionY
        drawPixel(x, y, formatColorStr(drawer(x, y, self:sv_getRaydata(res and res[1], res and res[2], self.distance), ...), true))
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
    self.raysCache = {}
end

local function simpleQuatDif(q1, q2)
    return math.abs(q1.x - q2.x) + math.abs(q1.y - q2.y) + math.abs(q1.z - q2.z) + math.abs(q1.w - q2.w)
end

function RaycastCamera:server_onFixedUpdate()
    local pos = self.shape.worldPosition
    local rot = self.shape.worldRotation

    if self.oldPos then
        if mathDist(self.oldPos, pos) > 0.01 or simpleQuatDif(rot, self.oldRot) > 0.01 then
            self.raysCache = {}
            self.oldPos = pos
            self.oldRot = rot
        end
    else
        self.oldPos = pos
        self.oldRot = rot
    end
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