local utils = {}

utils.clamp = constrain
utils.map = map
utils.roundTo = round
utils.split = function(tool, str, seps)
    return strSplit(tool, str, seps)
end
utils.splitByMaxSize = splitByMaxSize
utils.splitByMaxSizeWithTool = splitByMaxSizeWithTool
utils.deepcopy = sc.advDeepcopy
utils.md5 = function (str)
    sc.addLagScore(3)
    if #str > (1024 * 1) then
        error("you cannot calculate md5-sum if the input string exceeds 1kb", 2)
    end
    return md5.sumhexa(str)
end
utils.md5bin = function (str)
    sc.addLagScore(3)
    if #str > (1024 * 1) then
        error("you cannot calculate md5-sum if the input string exceeds 1kb", 2)
    end
    return md5.sum(str)
end
utils.dist = mathDist

function utils.fromEuler(euler)
    return fromEuler(euler.x, euler.y, euler.z)
end
utils.toEuler = toEuler

sc.reg_internal_lib("utils", utils)
return utils