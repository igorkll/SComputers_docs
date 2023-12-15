if __scConfigLoaded then return end
__scConfigLoaded = true

dofile("$SURVIVAL_DATA/Scripts/game/survival_constants.lua")
dofile("$SURVIVAL_DATA/Scripts/game/survival_items.lua")
dofile("examples.lua")

---- libs
dofile("base64.lua")
dofile("utf8.lua")
dofile("json.lua")
dofile("md5.lua")

---- main
dofile "$CONTENT_DATA/Scripts/methods.lua"
dofile "$CONTENT_DATA/Scripts/FileSystem.lua"
dofile "$CONTENT_DATA/Scripts/fsmanager.lua"
dofile "$CONTENT_DATA/Scripts/env.lua"
dofile "$CONTENT_DATA/Scripts/load_code.lua"
dofile "$CONTENT_DATA/Scripts/vnetwork.lua"
dofile("etc/load_etc.lua")

---- lua-in-lua
dofile "$CONTENT_DATA/Scripts/remade-lua-in-lua/lua/scanner.lua"
dofile "$CONTENT_DATA/Scripts/remade-lua-in-lua/lua/parser.lua"
dofile "$CONTENT_DATA/Scripts/remade-lua-in-lua/lua/interpreter.lua"
dofile "$CONTENT_DATA/Scripts/remade-lua-in-lua/lua/fixer.lua"
ll_Interpreter.MAX_ITERATIONS = math.huge

---- scrapVM
dofile("remade-scrapVM/scrapvm.lua")

-------------------------------------------------------

local pairs = pairs
local ipairs = ipairs
local type = type

local sm_color_new = sm.color.new
local sm_vec3_new = sm.vec3.new
local sm_quat_new = sm.quat.new

-------------------------------------------------------


sm.interactable.connectionType.composite = (4096 * 8)
sm.interactable.connectionType.networking = (8192 * 8)

local sc = {
	gpstags = {},
	antennasApis = {},

	writersRefs = {},
	antennasRefs = {},

	computersDatas = {},
	displaysDatas = {},
	motorsDatas = {},
	radarsDatas = {},
	networkPortsDatas = {},
	hardDiskDrivesDatas = {},
	camerasDatas = {},
	holoDatas = {},
	synthesizerDatas = {},
	keyboardDatas = {}
}
_G.sc = sc

sc.version = "2.4a"

sc.deltaTime = 0
sc.maxcodelen = 32 * 1024
sc.clockLagMul = 150
sc.radarDetectedBodies = {}

sc.display = {}
sc.networking = {}

function sc.shutdown()
end

function sc.yield(computer) --для библиотек
	if computer then
		local ok, err = pcall(computer.env[computer.yieldName], computer.yieldArg)
		if not ok then
			error(err or "unknown", 3)
		end
	elseif sc.lastComputer and sc.lastComputer.env then
		local ok, err = pcall(sc.lastComputer.env[sc.lastComputer.yieldName], sc.lastComputer.yieldArg)
		if not ok then
			error(err or "unknown", 3)
		end
	end
end

local count = 0
function sc.smartYield(computer) --для библиотек
	if count >= 128 then
		sc.yield(computer)
		count = 0
	else
		count = count + 1
	end
end

function sc.atan2(y, x)
	return math.atan(y/x) + ((x < 0 and y < 0) and -math.pi or (y < 0 and math.pi or 0))
end

function sc.setmetatable(t, meta) -- analog of native setmetatable
	for k, v in pairs(meta) do
		t[k] = v
	end

	t.__metatable = meta
	return t
end

function sc.getmetatable(t)
	return t.__metatable
end

function sc.networking.packetCopyPath(packet)
	packet = sc_copy(packet)
	packet.transmitterPath = sc_copy(packet.transmitterPath)

	return packet
end

function sc.advDeepcopy(t)
	local cache = {}

	local function clone(v, ctype)
		if ctype == "Color" then
			return sm_color_new(v.r, v.g, v.b, v.a)
		elseif ctype == "Vec3" then
			return sm_vec3_new(v.x, v.y, v.z)
		elseif ctype == "Quat" then
			return sm_quat_new(v.x, v.y, v.z, v.w)
		else
			return v
		end
	end

    local function recurse(tbl, newTable)
        for k, v in pairs(tbl) do
			sc.yield()

			local ctype = type(v)
            if ctype == "table" then
				if cache[v] then
					newTable[k] = cache[v]
				else
					if v == tbl then
						newTable[k] = newTable
					else
						cache[v] = {}
						newTable[k] = recurse(v, cache[v])
					end
				end
            else
				newTable[k] = clone(v, ctype)
			end
        end

        return newTable
    end

	if type(t) == "table" then
		cache[t] = {}
		return recurse(t, cache[t])
	end
	return clone(t, type(t))
end

local type = type
local sm_color_new = sm.color.new
local function sc_deepcopy(v)
	local tname = type(v)
	if tname == "table" then
		local r = {}

		for k, v in pairs(v) do
			r[sc_deepcopy(k)] = sc_deepcopy(v)
		end

		return r
	elseif tname == "Color" then
		return sm_color_new(v.r, v.g, v.b, v.a)
	else
		return v
	end
end
sc.deepcopy = sc_deepcopy

function sc.copy(v)
	if type(v) == "table" then
		local r = {}
		for k, v in pairs(v) do
			r[k] = v
		end

		return r
	else
		return v
	end
end

sc_copy = sc.copy

function sc.needSaveData()
	local v = sc.restrictions.saving
	if v == 0 then v = 1 end
	return sm.game.getCurrentTick() % v == 0
end

function sc.getApi(name)
	if _G[name] then
		return _G[name]
	elseif sm[name] then
		return sm[name]
	elseif a and a[name] then
		return a[name]
	elseif dlm and dlm[name] then
		return dlm[name]
	end
end

function sc.coroutineCheck()
	local c = sc.getApi("coroutine")
	if c and c.running() then
		error("this method cannot be called from a coroutine", 3)
	end
end

function sc.creativeCheck(self, isCreative)
	if isCreative and not sc.restrictions.acreative then
		self.shape:destroyShape()
	end
end

----------------------   STORAGE    ----------------------

sc.treesPainted = sm.storage.load("sc_treesPainted") or {}

---------------------- RESTRICTIONS ----------------------

local ll = "luaInLua"

function sc.getDefaultVM()
	if dlm then
		return "dlm"
	elseif _HENV then	
		return "hsandbox"
	elseif a then
		return "fullLuaEnv"
	elseif sm.advancedExecuter then --in development
		return "advancedExecuter"
	else
		return ll
	end
end

sc.defaultRestrictions = { --DEFAULT
	acreative = nil,
	adrop = true,
	disCompCheck = false,
	scriptMode = "safe",
	adminOnly = true,
	vm = sc.getDefaultVM(),
	allowChat = false,
	allowDist = false,
	optSpeed = false,
	rays = 0,
	skipFps = 20,
	rend = 15,
	cpu = (1 / 40) * 4, --max 4 ticks
	saving = 10,
	maxDisplays = 128,
	ibridge = true,
	disableCallLimit = false,
	lagDetector = 1,
	screenRate = 2
}

sc.forServerRestrictions = { --FOR SERVERS
	acreative = false,
	adrop = true,
	disCompCheck = false,
	scriptMode = "safe",
	adminOnly = true,
	vm = sc.getDefaultVM(),
	allowChat = false,
	allowDist = false,
	optSpeed = 5,
	rays = 32,
	skipFps = 20,
	rend = 5,
	cpu = (1 / 40) * 2, --two ticks
	saving = 80,
	maxDisplays = 64,
	ibridge = false,
	disableCallLimit = false,
	lagDetector = 2,
	screenRate = 4
}

sc.restrictions = nil
sc.restrictionsKey = "ScriptableComputer-Restrictions"

function sc.createRestrictions()
	sc.restrictions = sc.deepcopy(sc.defaultRestrictions)
	sc.restrictions.acreative = not sm.game.getLimitedInventory()
end

function sc.saveRestrictions()
	sm.storage.save(sc.restrictionsKey, sc.restrictions)
	sc.restrictionsUpdated = true
end

function sc.setRestrictions(restrictions)
	sc.restrictions = sc.advDeepcopy(restrictions)
	for key, value in pairs(sc.defaultRestrictions) do
		if sc.restrictions[key] == nil then
			sc.restrictions[key] = value
		end
	end
	if sc.restrictions.acreative == nil then
		sc.restrictions.acreative = not sm.game.getLimitedInventory()
	end
end

function sc.loadRestrictions()
	local data = sm.storage.load(sc.restrictionsKey)
	if data then
		sc.restrictions = data
		for key, value in pairs(sc.defaultRestrictions) do
			if sc.restrictions[key] == nil then
				sc.restrictions[key] = value
			end
		end
		if sc.restrictions.acreative == nil then
			sc.restrictions.acreative = not sm.game.getLimitedInventory()
		end

		if sc.restrictions.vm == "scrapVM" then
			sc.restrictions.vm = ll
		end
		if sc.restrictions.vm == ll and sc.getDefaultVM() ~= ll then
			sc.restrictions.vm = sc.getDefaultVM()
		end
	else
		sc.createRestrictions()
		sc.saveRestrictions()
	end
end


function sc.addLagScore(score)
	if sc.lastComputer and not sc.lastComputer.cdata.unsafe and type(sc.restrictions.lagDetector) == "number" then
		sc.lastComputer.lagScore = sc.lastComputer.lagScore + (score * sc.restrictions.lagDetector)
	end
end

function sc.init()
	if sc._INIT then return end
	sc.loadRestrictions()
	vnetwork.init()
	sc._INIT = true
end

---------------------- RESTRICTIONS END ----------------------

local type = type
local sm_color_new = sm.color.new
local tostring = tostring

function numberToColorpart(number)
    number = math.max(math.min(number, 1), 0)
    number = math.floor((number * 255) + 0.5)
    local hex = string.format("%x", number)
    if #hex < 2 then
        hex = "0" .. hex
    end
    return hex
end

--[[
local numberToColorpart = numberToColorpart
function sc.formatColor(data, isBlack, customAlpha)
	local customAlphaHex = "ff"
	if customAlpha then
		customAlphaHex = numberToColorpart(customAlpha)
	end

	if type(data) == "Color" then
		if customAlpha then
			return sm_color_new(tostring(data):sub(1, 6) .. customAlphaHex)
		else
			return data
		end
	elseif type(data) == "string" then
		return sm_color_new(data or (isBlack and ("000000" .. customAlphaHex) or ("ffffff"  .. customAlphaHex)))
	end
	return sm_color_new(isBlack and ("000000" .. customAlphaHex) or ("ffffff" .. customAlphaHex))
end

local formatColor = sc.formatColor
function sc.formatColorStr(data, isBlack, customAlpha)
	return tostring(formatColor(data, isBlack, customAlpha))
end
]]






local bit = bit or bit32
local band = bit.band
local rshift = bit.rshift
local function hexToRGB(color)
	return band(rshift(color, 16), 0xFF) / 255, band(rshift(color, 8), 0xFF) / 255, band(color, 0xFF) / 255
end

local black = "000000ff"
local white = "ffffffff"

local type = type
function sc.formatColor(data, default, advancedDefault)
	local t = type(data)
	if t == "Color" then
		return data
	elseif t == "string" then
		return sm_color_new(data)
	elseif t == "number" then
		return sm.color.new(hexToRGB(data))
	end

	if advancedDefault then
		return default
	else
		return sm_color_new(default and black or white)
	end
end

local formatColor, tostring = sc.formatColor, tostring
function sc.formatColorStr(data, default, advancedDefault)
	return tostring(formatColor(data, default, advancedDefault))
end

function sc.display.optimizeFont(chars, width, height)
	local optimized = {}

	for k, v in pairs(chars) do
		local pixels = {}

		for iy, w in ipairs(v) do
			for ix = 1, width do
				local z = w:sub(ix, ix)
				if z == "1" then
					table.insert(pixels, { ix-1, iy-1 })
				end
			end
		end

		optimized[k] = pixels
		if #k == 1 then
			optimized[k:byte()] = pixels
		end
	end

	return optimized
end

local sm_exists = sm.exists
function sc.checkComponent(self) --this method no longer needs to be called
	--[[
	if not sm_exists(self.shape or self.tool) then
		error("the " .. (self.componentType or "unknown") .. " component has been removed", 0)
	end
	]]
end

do
	local currentEffect = 1
	local effectsNames = {
		"ShapeRenderable",
	}

	for i = 2, 114 do
		table.insert(effectsNames, "ShapeRenderable" .. tostring(i))
	end

	function sc.getEffectName()
		local name = effectsNames[currentEffect]
		currentEffect = currentEffect + 1
		if currentEffect > #effectsNames then
			currentEffect = 1
		end
		return name
	end
end

do
	local currentEffect = 1
	local effectsNames = {
		"A",
		"B",
		"C",
		"D",
	}

	function sc.getSoundEffectName(realname)
		local name = effectsNames[currentEffect]
		currentEffect = currentEffect + 1
		if currentEffect > #effectsNames then
			currentEffect = 1
		end
		return realname .. name
	end
end

function sc.getComponents(self, name, settings)
	sc.coroutineCheck()

	settings = settings or {}

	local components = {}
	if settings.vcomponents then
		for lname, tbl in pairs(settings.vcomponents) do
			if lname == name then
				for i, data in ipairs(tbl) do
					data.type = lname
					table.insert(components, data)
				end
			end
		end
	end

	if not self.interactable then return components end

	----------------

	local connectType = sm.interactable.connectionType.composite
	local findMethod
	local componentDatas

	if name == "keyboard" then
		findMethod = self.interactable.getParents
		componentDatas = sc.keyboardDatas
	elseif name == "synthesizer" then
		findMethod = self.interactable.getChildren
		componentDatas = sc.synthesizerDatas
	elseif name == "holoprojector" then
		findMethod = self.interactable.getChildren
		componentDatas = sc.holoDatas
	elseif name == "camera" then
		findMethod = self.interactable.getParents
		componentDatas = sc.camerasDatas
	elseif name == "disk" then
		findMethod = self.interactable.getChildren
		componentDatas = sc.hardDiskDrivesDatas
	elseif name == "port" then
		findMethod = self.interactable.getChildren
		componentDatas = sc.networkPortsDatas
	elseif name == "radar" then
		findMethod = self.interactable.getChildren
		componentDatas = sc.radarsDatas
	elseif name == "motor" then
		findMethod = self.interactable.getChildren
		componentDatas = sc.motorsDatas
	elseif name == "display" then
		findMethod = self.interactable.getChildren
		componentDatas = sc.displaysDatas
	elseif name == "antenna" then
		findMethod = self.interactable.getChildren
		componentDatas = sc.antennasApis
	end

	local function addComponents(interactable, api)
		if self.componentCache[interactable.id] then
			table.insert(components, self.componentCache[interactable.id])
			return
		end

		local newapi = {}
		for key, value in pairs(api) do
			local api_type = api.type
			if type(value) == "function" then
				local checkTick
				newapi[key] = function (...)
					sc.coroutineCheck()

					local ctick = sm.game.getCurrentTick()
					if checkTick ~= ctick then
						checkTick = ctick

						if not sm_exists(interactable) then
							error("the \"" .. (api_type or "unknown") .. "\" component has been removed", 2)
						end

						if not sc.restrictions.disCompCheck then
							local find
							for _, children in ipairs(self.interactable:getChildren()) do
								if children == interactable then
									find = true
									break
								end
							end
							if not find then
								for _, parent in ipairs(self.interactable:getParents()) do
									if parent == interactable then
										find = true
										break
									end
								end
							end

							if not find then
								error("the \"" .. (api_type or "unknown") .. "\" component has been disconnected", 2)
							end
						end
					end

					if not api[key] then
						error("the \"" .. (api_type or "unknown") .. "\" component was turned off", 2)
					end

					local result = {pcall(api[key], ...)} --кастомные(пользовательские) компоненты на основе компа могут динамически изменять свой API
					if result[1] then
						return unpack(result, 2)
					else
						error(result[2], 2)
					end
				end
			else
				newapi[key] = sc.advDeepcopy(value)
			end
		end
		self.componentCache[interactable.id] = newapi
		table.insert(components, newapi)
	end

	local function reg(interactable)
		local data = interactable.publicData
		if data and
		data.sc_component and
		data.sc_component.api and data.sc_component.type == name then
			data.sc_component.api.type = name
			addComponents(interactable, data.sc_component.api)
		end
	end
	for k, v in pairs(self.interactable:getChildren(connectType)) do
		reg(v)
	end
	for k, v in pairs(self.interactable:getParents(connectType)) do
		reg(v)
	end

	if findMethod then
		for k, v in pairs(findMethod(self.interactable, connectType)) do
			local data = componentDatas[v:getId()]
			if data then
				data.type = name
				addComponents(v, data)
			end
		end
	end
	return components
end

if dlm and dlm.setupContentPath then
	print("SComputers dlm.setupContentPath: ", pcall(dlm.setupContentPath, "SComputers [Fork]", sm.uuid.new("3aeb81c2-71b9-45a1-9479-1f48f1e8ff21"), 2949350596))
end

-------------------------------------------------------

_G.internal_libs = {}
function sc.reg_internal_lib(name, tbl)
    _G.internal_libs[name] = tbl
end

sm.sc = sc --для интеграций
sm.sc_g = _G
function sc.customVersion(char)
	sc.version = sc.version:sub(1, #sc.version - 1) .. char
end

-------------------------------------------------------

dofile("$CONTENT_DATA/Scripts/font.lua")
dofile("$CONTENT_DATA/Scripts/basegraphic.lua")
dofile("$CONTENT_DATA/Scripts/warnings.lua")

-------------------------------------------------------

print("SComputers Configuration has been loaded. version " .. tostring(sc.version))