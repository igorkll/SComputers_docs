gps = class()
gps.maxParentCount = 1
gps.maxChildCount = 0
gps.connectionInput = sm.interactable.connectionType.composite
gps.connectionOutput = sm.interactable.connectionType.none
gps.colorNormal = sm.color.new(0x7F7F7Fff)
gps.colorHighlight = sm.color.new(0xFFFFFFff)
gps.componentType = "gps" --absences can cause problems
gps.minimalNoise = 1
gps.maximumNoise = 4096

local function noise(meters)
    return (math.random() * meters) - (meters / 2)
end

local function clampRotation(val)
    if val > math.pi then val = math.pi end
    if val < -math.pi then val = -math.pi end
    return val
end

function gps:generateNoise(dist, gpsdata)
    dist = constrain(dist, gps.minimalNoise, gps.maximumNoise)
    local degrees = dist / 100
    local meters = degrees / 4

    gpsdata.position = gpsdata.position + sm.vec3.new(noise(meters), noise(meters), noise(meters))

    --[[
    gpsdata.rotation.x = gpsdata.rotation.x + math.rad(noise(degrees))
    gpsdata.rotation.y = gpsdata.rotation.y + math.rad(noise(degrees))
    gpsdata.rotation.z = gpsdata.rotation.z + math.rad(noise(degrees))
    gpsdata.rotation.w = gpsdata.rotation.w + math.rad(noise(degrees))
    gpsdata.rotation = NormalizeQuaternion(gpsdata.rotation)
    ]]

    --[[
    gpsdata.rotationEuler.x = clampRotation(gpsdata.rotationEuler.x + math.rad(noise(degrees)))
    gpsdata.rotationEuler.y = clampRotation(gpsdata.rotationEuler.y + math.rad(noise(degrees)))
    gpsdata.rotationEuler.z = clampRotation(gpsdata.rotationEuler.z + math.rad(noise(degrees)))
    gpsdata.rotation = fromEuler(gpsdata.rotationEuler.x, gpsdata.rotationEuler.y, gpsdata.rotationEuler.z)
    --gpsdata.rotation = sm.quat.fromEuler(gpsdata.rotationEuler)
    ]]

    return gpsdata
end

function gps:sv_createGpsData(shape)
    return sc.advDeepcopy({
        position = shape.worldPosition,
        rotation = shape.worldRotation,
        rotationEuler = toEuler(shape.worldRotation)
    })
end

function gps:server_onCreate()
    self.interactable.publicData = {
        sc_component = {
            type = gps.componentType,
            api = {
                getRadius = function ()
                    return math.huge
                end,
                getSelfGpsData = function ()
                    local tick = sm.game.getCurrentTick()
                    if tick == self.old_tick and not sc.restrictions.disableCallLimit then
                        error("getSelfGpsData can only be used 1 time per tick on one GPS-Module", 2)
                    end
                    self.old_tick = tick

                    return self:generateNoise(0, self:sv_createGpsData(self.shape))
                end,
                getTagsGpsData = function (freq)
                    checkArg(1, freq, "number")

                    local tick = sm.game.getCurrentTick()
                    if tick == self.old_tick2 and not sc.restrictions.disableCallLimit then
                        error("getTagsGpsData can only be used 1 time per tick on one GPS-Module", 2)
                    end
                    self.old_tick2 = tick

                    local gpsdatas = {}
                    for id, gpstag in pairs(sc.gpstags) do
                        if gpstag.freq == freq then
                            table.insert(gpsdatas, self:generateNoise(mathDist(self.shape.worldPosition, gpstag.shape.worldPosition), self:sv_createGpsData(gpstag.shape)))
                        end
                    end
                    return gpsdatas
                end
            }
        }
    }
end