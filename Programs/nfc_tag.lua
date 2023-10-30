local utils = require("utils")

local port = getComponents("port")[1]

local raw_data = getData()
local data = {}
if raw_data ~= "" then
    data = sm.json.parseJsonString(raw_data)
end

local function save()
    setData(sm.json.writeJsonString(data))
end

local function checkPassword(password, admin)
    local pass = data.password
    if admin then
        pass = data.adminPassword
    end

    if not pass then
        return true
    end

    return utils.md5bin(tostring(pass)) == utils.md5bin(tostring(password))
end

local function only(admin, packetData, sender, func)
    if admin then
        if checkPassword(packetData.password, true) then
            func()
        else
            port.sendTo(sender, "invalid admin password")
        end
    else
        if checkPassword(packetData.password) or checkPassword(packetData.password, true) then
            func()
        else
            port.sendTo(sender, "invalid password")
        end
    end
end

---------------------------------------------------

if not data.uuid then
    data.uuid = tostring(sm.uuid.generateRandom())
    save()
end

local function updateLock()
    pcall(setLock, not data.unlock)
    pcall(setInvisible, not data.unlock)
end

---------------------------------------------------

function callback_loop()
    local packet, sender = port.nextPacket()
    if packet then
        local result = {pcall(sm.json.parseJsonString(packet))}
        if result[1] then
            local packetData = result[2]
            if packetData.command == "unlock" then
                only(packetData, sender, function ()
                    data.unlock = true
                    save()
                    updateLock()
                end)
            elseif packetData.command == "lock" then
                only(packetData, sender, function ()
                    data.unlock = false
                    save()
                    updateLock()
                end)
            elseif packetData.command == "destroy" then
                only(packetData, sender, function ()
                    pcall(setCode, "")
                    pcall(setData, "")
                    pcall(setLock, true, true)
                    pcall(setInvisible, true, true)
                    reboot()
                end)
            end
        end
    end
end