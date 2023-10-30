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

local function checkPassword(password)
    if not data.password then
        return true
    end
    return utils.md5bin(tostring(data.password)) == utils.md5bin(tostring(password))
end

---------------------------------------------------

if not data.uuid then
    data.uuid = tostring(sm.uuid.generateRandom())
    save()
end

---------------------------------------------------

function callback_loop()
    local packet, sender = port.nextPacket()
    if packet then
        local result = {pcall(sm.json.parseJsonString(packet))}
        if result[1] then
            local packetData = result[2]
            if checkPassword(packetData.password) then
                if packetData.command == "" then
                    
                end
            else
                port.sendTo(sender, "invalid password")
            end
        end
    end
end