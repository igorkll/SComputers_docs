---
sidebar_position: 11
title: inertialEngine
hide_title: true
sidebar-label: 'inertialEngine'
---

the inertial engine allows you to move quickly in space, when working it consumes one battery and one fuel per second
consumption does not depend on the load
when working, creation balances
the engine remembers the position and rotation when starting, and strives to occupy this position
no other means of traction can be used together with this engine
please note that the engine always tries to take a horizontal position
hint: you can connect several containers of the same type so that you have more fuel
please note that the movements can be so fast that they can break through the wall of the world!
note that the addPosition method perceives as a rotation for processing movement not a real rotation but a target one

### inertialEngine component
* type - inertialEngine
* inertialEngine.setActive(state:boolean) - starts or stops the engine. returns true even if there are no resources to work with in order to find out the true state use: inertialEngine.isActive() and inertialEngine.isWorkAvailable()
* inertialEngine.isActive():boolean - outputs the state set via setActive
* inertialEngine.isWorkAvailable():boolean - outputs true if the engine can work at the moment (there is enough fuel and batteries)
* inertialEngine.getAvailableBatteries():number - returns the number of batteries available to the engine
* inertialEngine.getAvailableGas():number - returns the amount of fuel available to the engine
* inertialEngine.addRotation(offset:vec3) - adds an angle in radians to the target angle of rotation of the structure
* inertialEngine.addPosition(offset:vec3) - adds a position in meters to the target position of the structure(the position is added taking into account the rotation)
* inertialEngine.setStableMode(mode) - sets the stabilization mode (default 1) to a maximum of 4. this changes the stabilization force

### stable modes
* 0 - no stabilization
* 1 - small creation
* 2 - medium creation
* 3 - big creation
* 4 - very big creation

```lua
local wasd = getComponents("wasd")[1]
local inertialEngine = getComponents("inertialEngine")[1]

inertialEngine.setActive(true)
inertialEngine.setStableMode(1)

local speed = 1
local rotateSpeed = math.rad(5)

--------------------------

local function up()
    inertialEngine.addPosition(sm.vec3.new(0, 0, speed))
end

local function down()
    inertialEngine.addPosition(sm.vec3.new(0, 0, -speed))
end

local function forward()
    inertialEngine.addPosition(sm.vec3.new(speed, 0, 0))
end

local function back()
    inertialEngine.addPosition(sm.vec3.new(-speed, 0, 0))
end

local function left()
    inertialEngine.addPosition(sm.vec3.new(0, speed, 0))
end

local function right()
    inertialEngine.addPosition(sm.vec3.new(0, -speed, 0))
end

--------------------------

local function _up()
    inertialEngine.addRotation(sm.vec3.new(0, -rotateSpeed, 0))
end

local function _down()
    inertialEngine.addRotation(sm.vec3.new(0, rotateSpeed, 0))
end

local function _left()
    inertialEngine.addRotation(sm.vec3.new(0, 0, rotateSpeed))
end

local function _right()
    inertialEngine.addRotation(sm.vec3.new(0, 0, -rotateSpeed))
end

--------------------------

function callback_loop()
    if _endtick then
        inertialEngine.setActive(false)
        return
    end

    forward()

    if wasd.isW() then
        _up()
    elseif wasd.isS() then
        _down()
    end

    if wasd.isA() then
        _left()
    elseif wasd.isD() then
        _right()
    end
end
```