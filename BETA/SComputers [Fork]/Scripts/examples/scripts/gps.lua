--The GPS module allows you to get your position, as well as get the GPSTAGS position
--to detect gps tag, you need to know its frequency (which is randomly selected when installing gpstag)
--at the moment, the GPS tag can be detected at a non-limited distance
--but the further the GPS Tag is from the GPS module, the more noise there is in the measurement
--there is also a minimum noise level that is present even when measuring your own position
--the noise level is 1 degree and 1 block per 100 meters of distance
--the minimum noise level is equal to the gps tag position at a distance of a meter(this noise is present even when measuring your own position)
--don't forget that the getSelfGpsData and getTagsGpsData methods can only be used 1 time per tick

utils = require("utils")
gps = getComponents("gps")[1]

function callback_loop()
    local gpsdata = gps.getSelfGpsData()

    print("------------------------------------------------")
    print("position-self", utils.roundTo(gpsdata.position.x, 1), utils.roundTo(gpsdata.position.y, 1), utils.roundTo(gpsdata.position.z, 1))
    print("rotation-self", utils.roundTo(gpsdata.rotation.x, 1), utils.roundTo(gpsdata.rotation.y, 1), utils.roundTo(gpsdata.rotation.z, 1), utils.roundTo(gpsdata.rotation.w, 1))
    print("rotation-euler-self", utils.roundTo(gpsdata.rotationEuler.x, 1), utils.roundTo(gpsdata.rotationEuler.y, 1), utils.roundTo(gpsdata.rotationEuler.z, 1))
    for i, v in ipairs(gps.getTagsGpsData(0)) do
        print("position-tag:" .. tostring(i), utils.roundTo(v.position.x, 1), utils.roundTo(v.position.y, 1), utils.roundTo(v.position.z, 1))
        print("rotation-tag:" .. tostring(i), utils.roundTo(v.rotation.x, 1), utils.roundTo(v.rotation.y, 1), utils.roundTo(v.rotation.z, 1), utils.roundTo(v.rotation.w, 1))
        print("rotation-euler-tag:" .. tostring(i), utils.roundTo(v.rotationEuler.x, 1), utils.roundTo(v.rotationEuler.y, 1), utils.roundTo(v.rotationEuler.z, 1))
    end
end