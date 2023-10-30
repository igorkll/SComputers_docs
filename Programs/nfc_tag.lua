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

    return tostring(pass) == tostring(password)
end

local function only(admin, packetData, sender, func)
    if admin then
        if checkPassword(packetData.password, true) then
            func()
        else
            port.sendTo(sender, "0:invalid admin password")
        end
    else
        if checkPassword(packetData.password) or checkPassword(packetData.password, true) then
            func()
        else
            port.sendTo(sender, "0:invalid password")
        end
    end
end

---------------------------------------------------

if not data.uuid then
    data.adminPassword = utils.md5bin("0000")
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
                only(true, packetData, sender, function ()
                    data.unlock = true
                    save()
                    updateLock()
                    port.sendTo(sender, "1:tag unlocked")
                end)
            elseif packetData.command == "lock" then
                only(true, packetData, sender, function ()
                    data.unlock = false
                    save()
                    updateLock()
                    port.sendTo(sender, "1:tag locked")
                end)
            elseif packetData.command == "destroy" then
                only(true, packetData, sender, function ()
                    pcall(setCode, "THE TAG WAS DESTROYED")
                    pcall(setData, "")
                    pcall(setLock, true, true)
                    pcall(setInvisible, true, true)
                    port.sendTo(sender, "1:tag destroyed")
                    reboot()
                end)
            elseif packetData.command == "echo" then
                port.sendTo(sender, "1:" .. tostring(packetData.echo))
            elseif packetData.command == "uuid" then
                only(false, packetData, sender, function ()
                    port.sendTo(sender, "1:" .. tostring(data.uuid))
                end)
            elseif packetData.command == "set_password" then
                only(true, packetData, sender, function ()
                    data.password = tostring(packetData.pass)
                    save()
                    port.sendTo(sender, "1:password setted")
                end)
            elseif packetData.command == "set_admin_password" then
                only(true, packetData, sender, function ()
                    data.adminPassword = tostring(packetData.pass)
                    save()
                    port.sendTo(sender, "1:admin password setted")
                end)
            elseif packetData.command == "clear_password" then
                only(true, packetData, sender, function ()
                    data.password = nil
                    save()
                    port.sendTo(sender, "1:password cleared")
                end)
            elseif packetData.command == "clear_admin_password" then
                only(true, packetData, sender, function ()
                    data.adminPassword = nil
                    save()
                    port.sendTo(sender, "1:admin password cleared")
                end)
            else
                port.sendTo(sender, "0:unsupported command")
            end
        end
    end
end