base64lib = {}

function base64lib.encode(data)
    checkArg(1, data, "string")
    return base64.encode(data)
end

function base64lib.decode(data)
    checkArg(1, data, "string")
    return base64.decode(data)
end

sc.reg_internal_lib("base64", base64lib)