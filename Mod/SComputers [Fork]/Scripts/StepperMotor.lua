dofile '$CONTENT_DATA/Scripts/Config.lua'

StepperMotor = class(nil)

StepperMotor.maxParentCount = -1
StepperMotor.maxChildCount = 16
StepperMotor.connectionInput = sm.interactable.connectionType.composite + sm.interactable.connectionType.electricity
StepperMotor.connectionOutput = sm.interactable.connectionType.bearing
StepperMotor.colorNormal = sm.color.new(0x9f6213ff)
StepperMotor.colorHighlight = sm.color.new(0xde881bff)
StepperMotor.componentType = "motor"

--StepperMotor.nonActiveImpulse = 0.25
StepperMotor.nonActiveImpulse = 0
StepperMotor.chargeAdditions = 200000

-- SERVER --

function StepperMotor.server_createData(self)
	return {
		getVelocity = function () return self.velocity end,
		setVelocity = function (v)
		    if type(v) == "number" then
				self.velocity = sm.util.clamp(v, -self.mVelocity, self.mVelocity)
			else
				error("Value must be number")
			end
		end,
		getStrength = function () return self.maxImpulse end,
		setStrength = function (v)
		    if type(v) == "number" then
				self.maxImpulse = sm.util.clamp(v, 0, self.mImpulse)
			else
				error("Value must be number")
			end
		end,
		getAngle = function () return self.angle end,
		setAngle = function (v)
			if type(v) == "number" or type(v) == "nil" then
				self.angle = v and sm.util.clamp(v, -3.402e+38, 3.402e+38) or nil
			else
				error("Value must be number or nil")
			end
		end,
		isActive = function () return self.isActive end,
		setActive = function (v) 
			if type(v) == "boolean" then
				self.isActive = v
			elseif type(v) == "number" then
				self.isActive = v > 0
			else
				error("Type must be boolean or number")
			end
		end,

		getAvailableBatteries = function ()
			return (self.data and self.data.survival) and (self.batteries or 0) or math.huge
		end,
		getCharge = function ()
			return self.energy
		end,
		getChargeDelta = function ()
			return self.chargeDelta
		end,
		isWorkAvailable = function ()
			if self.data and self.data.survival then
				if self.energy > 0 then
					return true
				end

				if self.batteries and self.batteries > 0 then
					return true
				end

				return false
			end
			return true
		end,
		getBearingsCount = function ()
			return self.bearingsCount or 0
		end,

		maxStrength = function ()
			return self.mImpulse
		end,
		maxVelocity = function ()
			return self.mVelocity
		end,
		getChargeAdditions = function ()
			return StepperMotor.chargeAdditions
		end,
		setSoundType = function (num)
			checkArg(1, num, "number")
			self.soundtype = num
		end,
		getSoundType = function ()
			return self.soundtype
		end
	}
end

function StepperMotor.server_onCreate(self)
	self.chargeDelta = 0
	
	self.soundtype = 1
	self.mVelocity = 10000
	self.mImpulse = 10000
	self.energy = math.huge
	if self.data and self.data.survival then
		self.mVelocity = self.data.v or 500
		self.mImpulse = self.data.i or 1000
		self.energy = 0
	end

	self.velocity = 0
	self.maxImpulse = 0
	self.angle = nil
	self.isActive = false
	self.wasActive = false
	self.bearingsCount = #self.interactable:getBearings()

	sc.motorsDatas[self.interactable:getId()] = self:server_createData()

	sc.creativeCheck(self, self.energy == math.huge)
end

function StepperMotor.server_onDestroy(self)
	sc.motorsDatas[self.interactable:getId()] = nil
end

function StepperMotor.server_onFixedUpdate(self, dt)
	self.bearingsCount = #self.interactable:getBearings()

	--------------------------------------------------------

	local container
	for _, parent in ipairs(self.interactable:getParents()) do
		if parent:hasOutputType(sm.interactable.connectionType.electricity) then
			container = parent:getContainer(0)
			break
		end
	end

	self.batteries = self:sv_mathCount()
	self.chargeDelta = 0

	--------------------------------------------------------

	local active = self.isActive
	if active and self.energy <= 0 then
		self:sv_removeItem()
		if self.energy <= 0 then
			active = nil
		end
	end

	if active then
		if self.angle == nil then
			for k, v in pairs(self.interactable:getBearings()) do
				v:setMotorVelocity(self.velocity, self.maxImpulse)
			end
		else
			for k, v in pairs(self.interactable:getBearings()) do
				v:setTargetAngle(self.angle, self.velocity, self.maxImpulse)
			end
		end

		if self.maxImpulse > 0 then
			for k, v in pairs(self.interactable:getBearings()) do
				self.chargeDelta = self.chargeDelta + math.abs(v:getAppliedImpulse())				
			end
			self.energy = self.energy - self.chargeDelta
		end
	elseif self.wasActive then
		for k, v in pairs(self.interactable:getBearings()) do
			v:setMotorVelocity(0, StepperMotor.nonActiveImpulse)
		end
	end
	self.wasActive = active

	if self.energy < 0 then
		self.energy = 0
	end

	local rpm = self.velocity / self.mVelocity
	local load = (self.chargeDelta / self.maxImpulse) / (self.bearingsCount or 0)
	if self.old_active ~= active or
	rpm ~= self.old_rpm or
	load ~= self.old_load or
	self.soundtype ~= self.old_type then
		if active and self.soundtype ~= 0 then
			local lload, lrpm = load, rpm
			if self.soundtype == 1 then
				lrpm = lload
			end
			self.network:sendToClients("cl_setEffectParams", {
				rpm = lrpm,
				load = lload,
				soundtype = self.soundtype
			})
		else
			self.network:sendToClients("cl_setEffectParams")
		end
	end
	self.old_active = active
	self.old_rpm = rpm
	self.old_load = load
	self.old_type = self.soundtype

	sc.creativeCheck(self, self.energy == math.huge)
end

function StepperMotor:sv_removeItem()
	for _, parent in ipairs(self.interactable:getParents()) do
        if parent:hasOutputType(sm.interactable.connectionType.electricity) then
			local container = parent:getContainer(0)
			if sm.container.canSpend(container, obj_consumable_battery, 1) then
				sm.container.beginTransaction()
				sm.container.spend(container, obj_consumable_battery, 1, true)
				if sm.container.endTransaction() then
					self.energy = self.energy + StepperMotor.chargeAdditions
					break
				end
			end
		end
	end
end

function StepperMotor:sv_mathCount()
    local count = 0
    for _, parent in ipairs(self.interactable:getParents()) do
        if parent:hasOutputType(sm.interactable.connectionType.electricity) then
            local container = parent:getContainer(0)
            for i = 0, container.size - 1 do
                count = count + (container:getItem(i).quantity)
            end
		end
	end
    return count
end


-- CLIENT --

function StepperMotor:client_onCreate()
end

function StepperMotor:cl_setEffectParams(tbl)
	if tbl then
		if tbl.soundtype ~= self.cl_oldSoundType then
			if self.effect then
				self.effect:setAutoPlay(false)
				self.effect:stop()
				self.effect:destroy()
				self.effect = nil
			end
			self.cl_oldSoundType = tbl.soundtype
		end
		if not self.effect then
			if tbl.soundtype == 1 then
				self.effect = sm.effect.createEffect("ElectricEngine - Level 2", self.interactable)
			elseif tbl.soundtype == 2 then
				self.effect = sm.effect.createEffect("GasEngine - Level 3", self.interactable)
			end
			
			if self.effect then
				self.effect:setAutoPlay(true)
				self.effect:start()
			end
		end

		if self.effect then
			self.effect:setParameter("rpm", tbl.rpm)
			self.effect:setParameter("load", tbl.load)
		end
	else
		if self.effect then
			self.effect:setAutoPlay(false)
			self.effect:stop()
			self.effect:destroy()
			self.effect = nil
		end
	end
end