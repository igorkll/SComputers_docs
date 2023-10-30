base64lib = {}

local maxDataLimit = 1024 * 16

function base64lib.encode(data)
    checkArg(1, data, "string")
    if #data > maxDataLimit then
        error("the maximum amount of data processed by the base64 library is 16 kilobytes", 2)
    end
    return base64.encode(data)
end

function base64lib.decode(data)
    checkArg(1, data, "string")
    if #data > maxDataLimit then
        error("the maximum amount of data processed by the base64 library is 16 kilobytes", 2)
    end
    return base64.decode(data)
end

sc.reg_internal_lib("base64", base64lib)
return base64lib