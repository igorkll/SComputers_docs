local utils = {}

utils.clamp = constrain
utils.map = map
utils.roundTo = round
utils.split = strSplit
utils.splitByMaxSize = splitByMaxSize
utils.deepcopy = sc.advDeepcopy
utils.md5 = function (str)
    if #str > (1024 * 1) then
        error("you cannot calculate md5-sum if the input string exceeds 1kb", 2)
    end
    return sm.lgc.md5(str)
end
utils.dist = mathDist

function utils.fromEuler(euler)
    return fromEuler(euler.x, euler.y, euler.z)
end
utils.toEuler = toEuler

function utils.splitByMaxSizeWithTool(tool, str, max)
    max = math.floor(max + 0.5)
    if max <= 0 then
        max = 1
    end

    local strs = {}
    while tool.len(str) > 0 do
        sc.yield()
        
        table.insert(strs, tool.sub(str, 1, max))
        str = tool.sub(str, tool.len(strs[#strs]) + 1, #str)
    end
    return strs
end

sc.reg_internal_lib("utils", utils)