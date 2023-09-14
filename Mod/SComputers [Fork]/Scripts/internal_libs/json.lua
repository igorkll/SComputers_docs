local jsonlib = {}
local json = json

function jsonlib.encode(tbl)
    return json.encode(tbl)
end

function jsonlib.decode(jsonstring)
    return json.decode(jsonstring)
end

sc.reg_internal_lib("json", jsonlib)