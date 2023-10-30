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
    if not data.password 
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
            if not data.password or 
            if packetData.command == ""
        end
    end
end