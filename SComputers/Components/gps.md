---
sidebar_position: 7
title: gps
hide_title: true
sidebar-label: 'gps'
---

The GPS module allows you to get your position, as well as get the GPSTAGS position, GPS tag can be detected at a distance of 256 meters (1024 blocks) from the GPS module
to detect gps tag, you need to know its frequency (which is randomly selected when installing gpstag)

### gps component
* type - gps
* gps.getSelfGpsData():gpsdata - returns gpsdata corresponding to gps-module position and rotation
* gps.getTagsGpsData(tagfreq:number):{gpsdata, gpsdata, ...} - returns gpsdata corresponding to the position and rotation of gpstag
* gps.getRadius():number - returns the maximum distance in meters (1 meter - 4 blocks) at which the gps-module sees gpstag

# gpsdata object
* gpsdata.position - vec3 position object
* gpsdata.rotation - quat rotation object

#### example
```lua
gps = getComponents("gps")[1]

function callback_loop()
    local gpsdata = gps.getSelfGpsData()
    print("self", gpsdata.position.x, gpsdata.position.y, gpsdata.position.z)
    for i, v in ipairs(gps.getTagsGpsData(0)) do
        print("tag:" .. tostring(i), v.position.x, v.position.y, v.position.z)
    end
end
```