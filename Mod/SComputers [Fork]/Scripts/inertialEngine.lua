inertialEngine = class()
inertialEngine.maxParentCount = -1
inertialEngine.maxChildCount = 0
inertialEngine.connectionInput = sm.interactable.connectionType.composite + sm.interactable.connectionType.electricity + sm.interactable.connectionType.gasoline
inertialEngine.connectionOutput = sm.interactable.connectionType.none
inertialEngine.colorNormal = sm.color.new("#aa0000")
inertialEngine.colorHighlight = sm.color.new("#ff0303")
inertialEngine.componentType = "inertialEngine"

function inertialEngine:server_onCreate()
    self.active = false
    self.batteries = 0
    self.gasolines = 0
    self.tick = 0
    self.creative = self.data and self.data.creative
    self.stableMode = 1
    self:sv_reset()

    self.interactable.publicData = {
        sc_component = {
            type = inertialEngine.componentType,
            api = {
                isWorkAvailable = function ()
                    return self:sv_isWorkAvailable()
                end,
                setActive = function (state)
                    checkArg(1, state, "boolean")
                    if state ~= self.active then
                        self.active = state
                        self:sv_reset()
                    end
                end,
                isActive = function ()
                    return self.active
                end,
                getAvailableBatteries = function ()
                    return self.batteries
                end,
                getAvailableGas = function ()
                    return self.gasolines
                end,
                addRotation = function (angle)
                    checkArg(1, angle, "Vec3")
                    self.targetRotation.x = math.rad(math.deg(self.targetRotation.x + angle.x))
                    self.targetRotation.y = math.rad(math.deg(self.targetRotation.y + angle.y))
                    self.targetRotation.z = math.rad(math.deg(self.targetRotation.z + angle.z))
                end,
                addPosition = function (offset)
                    checkArg(1, offset, "Vec3")
                    local vec = sc.advDeepcopy(self.targetRotation)

                    local add1 = fromEulerVec(vec) * offset
                    add1.z = 0

                    vec.z = 0
                    local add2 = fromEulerVec(vec) * offset
                    add2.x = 0
                    add2.y = 0

                    self.targetPosition = self.targetPosition + add1 + add2
                end,
                setStableMode = function (mode)
                    checkArg(1, mode, "number")
                    if mode < 0 or mode > 4 then
                        error("stable mode must be [0:4]", 2)
                    end
                    self.stableMode = mode
                    self:recreatePID()
                end,

                getOffset = function()
                    return mathDist(self.targetPosition, self.shape.worldPosition)
                end,
                raw_rotation = function(vec)
                    if vec.x < -8 then vec.x = -8 end
                    if vec.x > 8 then vec.x = 8 end

                    if vec.y < -8 then vec.y = -8 end
                    if vec.y > 8 then vec.y = 8 end

                    if vec.z < -8 then vec.z = -8 end
                    if vec.z > 8 then vec.z = 8 end

                    sm.physics.applyTorque(self.shape.body, self.shape.worldRotation * (vec * self.shape.body.mass), true)
                end
            }
        }
    }

    sc.creativeCheck(self, self.creative)
end

function inertialEngine:server_onRefresh()
    self:server_onCreate()
end

function inertialEngine:server_onFixedUpdate()
    if self.creative then
        self.batteries = math.huge
        self.gasolines = math.huge
    else
        self.batteries = self:sv_mathCount(sm.interactable.connectionType.electricity)
        self.gasolines = self:sv_mathCount(sm.interactable.connectionType.gasoline)
    end

    if not self:sv_isWorkAvailable() then
        self:sv_reset()
    end

    local active = self.active and self:sv_isWorkAvailable()
    self.interactable:setActive(active)
    if active then
        self.tick = self.tick + 1

        --[[
        self.static = self.shape.body:isStatic()
        if not self.static and self.old_static then
            self:sv_reset()
        end
        self.old_static = self.static
        ]]

        self:sv_stable()
        self:sv_moveToPos()

        if self.tick % 40 == 0 and not self.creative then
            self:sv_removeItem(sm.interactable.connectionType.electricity)
            self:sv_removeItem(sm.interactable.connectionType.gasoline)
        end
    end

    sc.creativeCheck(self, self.creative)
end

function inertialEngine:sv_reset()
    self.targetPosition = self.shape.worldPosition

    self.targetRotation = self:getSelfRotation()
    self.targetRotation.x = 0
    self.targetRotation.y = 0
    
    self.mPidX = createPID(0.3, 0, 500)
    self.mPidY = createPID(0.3, 0, 500)
    self.mPidZ = createPID(0.3, 0, 500)

    self:recreatePID()
end

function inertialEngine:recreatePID()
    if self.stableMode == 4 then
        self.rPidX = createPID(10, 0, 50000)
        self.rPidY = createPID(10, 0, 50000)
        self.rPidZ = createPID(10, 0, 50000)
    elseif self.stableMode == 3 then
        self.rPidX = createPID(3, 0, 5000)
        self.rPidY = createPID(3, 0, 5000)
        self.rPidZ = createPID(3, 0, 5000)
    elseif self.stableMode == 2 then
        self.rPidX = createPID(2, 0, 1500)
        self.rPidY = createPID(2, 0, 1500)
        self.rPidZ = createPID(2, 0, 1500)
    elseif self.stableMode == 1 then
        self.rPidX = createPID(0.8, 0, 250)
        self.rPidY = createPID(0.8, 0, 250)
        self.rPidZ = createPID(0.8, 0, 250)
    else
        self.rPidX = createPID(0, 0, 0)
        self.rPidY = createPID(0, 0, 0)
        self.rPidZ = createPID(0, 0, 0)
    end
end

function inertialEngine:sv_moveToPos()
    local target = self.targetPosition
    local current = self.shape.worldPosition
    local vec = sm.vec3.new(
        self.mPidX(target.x, current.x),
        self.mPidY(target.y, current.y),
        self.mPidZ(target.z, current.z)
    )

    if vec.x < -5 then vec.x = -5 end
    if vec.x >  5 then vec.x = 5  end

    if vec.y < -5 then vec.y = -5 end
    if vec.y >  5 then vec.y = 5  end

    if vec.z < -5 then vec.z = -5 end
    if vec.z >  5 then vec.z = 5  end

    sm.physics.applyImpulse(self.shape.body, vec * self.shape.body.mass, true)
end

function inertialEngine:sv_stable()
    --[[
    local vec = toEuler(self.shape.worldRotation)
    vec.z = self.targetRotation - vec.z

    local max = 0.05
    local amax = 2
    vec.x = constrain(-vec.x, -max, max)
    vec.y = constrain(-vec.y, -max, max)
    vec.z = constrain(vec.z, -amax, amax)
    ]]

    local target = self.targetRotation
    local current = self:getSelfRotation()

    local function short_angle_dist(from, to)
        local fmod = math.fmod
        local max_angle = math.pi * 2
        local difference = fmod(to - from, max_angle)
        return fmod(2 * difference, max_angle) - difference
    end

    local vec = sm.vec3.new(
        self.rPidX(short_angle_dist(current.x, target.x), 0),
        self.rPidY(short_angle_dist(current.y, target.y), 0),
        self.rPidZ(short_angle_dist(current.z, target.z), 0)
    )

    sm.physics.applyTorque(self.shape.body, self.shape.worldRotation * (vec * self.shape.body.mass), true)
end

function inertialEngine:getSelfRotation()
    local out = toEuler(self.shape.worldRotation)
    return out
end

function inertialEngine:sv_removeItem(ctype)
    local itype
    if ctype == sm.interactable.connectionType.electricity then
        itype = obj_consumable_battery
    elseif ctype == sm.interactable.connectionType.gasoline then
        itype = obj_consumable_gas
    end

    for _, parent in ipairs(self.interactable:getParents()) do
        if parent:hasOutputType(ctype) then
            local container = parent:getContainer(0)
            if container and sm.container.canSpend(container, itype, 1) then
                sm.container.beginTransaction()
                sm.container.spend(container, itype, 1, true)
                if sm.container.endTransaction() then
                    break
                end
            end
		end
	end
end

function inertialEngine:sv_mathCount(ctype)
    local count = 0
    for _, parent in ipairs(self.interactable:getParents()) do
        if parent:hasOutputType(ctype) then
            local container = parent:getContainer(0)
            for i = 0, container.size - 1 do
                count = count + (container:getItem(i).quantity)
            end
		end
	end
    return count
end

function inertialEngine:sv_isWorkAvailable()
    return self.batteries > 0 and self.gasolines > 0
end

-----------------------------------------------

function inertialEngine:client_onFixedUpdate()
    if self.interactable:isActive() then
        if not self.effect then
            self.effect = sm.effect.createEffect("ElectricEngine - Level 2", self.interactable)
            self.effect2 = sm.effect.createEffect("GasEngine - Level 3", self.interactable)
            self.effect:setAutoPlay(true)
            self.effect2:setAutoPlay(true)

            self.effect:setParameter("rpm", 0.7)
		    self.effect:setParameter("load", 0.5)

            self.effect2:setParameter("rpm", 1)
		    self.effect2:setParameter("load", 0.8)
        end
    else
        if self.effect then
            self.effect:setAutoPlay(false)
            self.effect2:setAutoPlay(false)
            self.effect:stop()
            self.effect2:stop()
            self.effect:destroy()
            self.effect2:destroy()
            self.effect = nil
            self.effect2 = nil
        end
    end
end