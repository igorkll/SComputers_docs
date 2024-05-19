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
* inertialEngine.getOffset():number - returns the distance in meters from the actual location to the target point
* inertialEngine.setRawMovement(boolean) - sets the raw movement mode. in this mode, the "addPosition" method will not affect the position of the creation, and the movements will need to be carried out using the "raw_move" method
* inertialEngine.isRawMovement():boolean
* inertialEngine.setGravity(number) - sets the local gravity for the inertialEngine that will run in rawmode. The default is 1 (The standard gravity of the game). minimum values -1 maximum 1
* inertialEngine.getGravity():number
* inertialEngine.raw_rotation(vec3) - makes the rotation pulse relative to the current rotation. it cannot be called more than once per tick, the maximum value of the vector element is 8. Note that the momentum is multiplied by the mass of the creation
* inertialEngine.raw_move(vec3) - makes the pulse relative to the current rotation. it cannot be called more than once per tick, the maximum value of the vector element is 5. Note that the momentum is multiplied by the mass of the creation


### stable modes
* 0 - no stabilization
* 1 - small creation
* 2 - medium creation
* 3 - big creation
* 4 - very big creation

```lua
local wasd = getComponent("wasd")
local inertialEngine = getComponent("inertialEngine")

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

    if wasd.isSeated() then
        forward()
    end

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