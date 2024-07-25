-- this code allows addons for scrap computers to work on SComputers. this does not violate the scrapcomputers license in any way as it does not borrow its code
if imitatingAPI then return end
local baseImitatingAPI = {}
sm.interactable.connectionType.compositeIO = 32768
sm.interactable.connectionType.networkingIO = 65536

---------------------------------------------------- envManager

baseImitatingAPI.envManager = {
    envHooks = {}
}

function baseImitatingAPI.envManager.createEnv(self)
    return {}
end

---------------------------------------------------- components

baseImitatingAPI.components = {}

local regComponents = {}

function baseImitatingAPI.components.ToComponent(cls, ctype, isComponent)
    if isComponent then
        regComponents[ctype] = {}
        cls.componentType = ctype

        local old_onCreate = cls.server_onCreate
        function cls:server_onCreate()
            if old_onCreate then
                old_onCreate(self)
            end
            if not self.interactable.publicData then
                self.interactable.publicData = {}
            end
            local api = self:sv_createData()
            self.interactable.publicData.sc_component = {
                type = ctype,
                api = api
            }
            table.insert(regComponents[ctype], {self = self, api = api})
        end

        local old_onDestroy = cls.server_onDestroy
        function cls:server_onDestroy()
            for i, v in ipairs(regComponents[ctype]) do
                if v.self == self then
                    table.remove(regComponents[ctype], i)
                    break
                end
            end

            if old_onDestroy then
                old_onDestroy(self)
            end
        end
    end
end

local privateData = "SC_PRIVATE_"
function baseImitatingAPI.components.getComponents(ctype, interactable, children, flags, private)
    local tbl = {}
    for i, v in ipairs(regComponents[ctype] or {}) do
        local function add()
            if not private then
                local newApi = {}
                for k, v in pairs(v.api) do
                    if k:sub(1, #privateData) ~= privateData then
                        newApi[k] = v
                    end
                end
                table.insert(tbl, newApi)
            else
                table.insert(tbl, v.api)
            end
        end
        if children then
            for _, child in ipairs(interactable:getChildren()) do
                if child.id == v.self.interactable.id and (not flags or child:hasOutputType(flags)) then
                    table.insert(tbl, v.api)
                    break
                end
            end
        else
            for _, parent in ipairs(interactable:getParents()) do
                if parent.id == v.self.interactable.id and (not flags or parent:hasOutputType(flags)) then
                    table.insert(tbl, v.api)
                    break
                end
            end
        end
    end
    return tbl
end

---------------------------------------------------- filters

baseImitatingAPI.filters = {
    dataType = mt_hook({__index = function(self, key)
        return key
    end})
}

----------------------------------------------------

local function emptyFunc()
    
end

function updateExternAPI()
    if type(sm.scrapcomputers) == "table" then
        if sm.scrapcomputers ~= baseImitatingAPI then
            if not sm.scrapcomputers.components then
                sm.scrapcomputers.components = {}
            end

            local _getComponents = sm.scrapcomputers.components.getComponents or emptyFunc
            function sm.scrapcomputers.components.getComponents(...)
                local tbl1 = baseImitatingAPI.components.getComponents(...) or {}
                local tbl2 = _getComponents(...) or {}
                for k, v in pairs(tbl2) do
                    tbl1[k] = v
                end
                return tbl1
            end

            local _ToComponent = sm.scrapcomputers.components.ToComponent or emptyFunc
            function sm.scrapcomputers.components.ToComponent(...)
                baseImitatingAPI.components.ToComponent(...)
                return _ToComponent(...)
            end
        end
    else
        sm.scrapcomputers = baseImitatingAPI
    end
    imitatingAPI = sm.scrapcomputers
end
updateExternAPI()