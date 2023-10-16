local jsonlib = {}
local json = json
local jsonEncodeInputCheck = jsonEncodeInputCheck

function jsonlib.encode(tbl)
    jsonEncodeInputCheck(tbl, 0)
    return json.encode(tbl)
end

function jsonlib.decode(jsonstring)
    return json.decode(jsonstring)
end

sc.reg_internal_lib("json", jsonlib)