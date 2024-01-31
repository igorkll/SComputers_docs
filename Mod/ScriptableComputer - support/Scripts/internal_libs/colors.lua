local colors = {num = {}, str = {}, sm = {}}
colors.names = {"Gray", "Yellow", "LimeGreen", "Green", "Cyan", "Blue", "Violet", "Magenta", "Red", "Orange"}

colors.num.Gray	      = {0xEEEEEE, 0x7F7F7F, 0x4A4A4A, 0x222222}
colors.num.Yellow     = {0xF5F071, 0xE2DB13, 0x817C00, 0x323000}
colors.num.LimeGreen  = {0xCBF66F, 0xA0EA00, 0x577D07, 0x375000}
colors.num.Green      = {0x68FF88, 0x19E753, 0x0E8031, 0x064023}
colors.num.Cyan       = {0x7EEDED, 0x2CE6E6, 0x118787, 0x0A4444}
colors.num.Blue       = {0x4C6FE3, 0x0A3EE2, 0x0F2E91, 0x0A1D5A}
colors.num.Violet     = {0xAE79F0, 0x7514ED, 0x500AA6, 0x35086C}
colors.num.Magenta    = {0xEE7BF0, 0xCF11D2, 0x720A74, 0x520653}
colors.num.Red        = {0xF06767, 0xD02525, 0x7C0000, 0x560202}
colors.num.Orange     = {0xEEAF5C, 0xDF7F00, 0x673B00, 0x472800}

colors.str.Gray	      = {"EEEEEE", "7F7F7F", "4A4A4A", "222222"}
colors.str.Yellow     = {"F5F071", "E2DB13", "817C00", "323000"}
colors.str.LimeGreen  = {"CBF66F", "A0EA00", "577D07", "375000"}
colors.str.Green	  = {"68FF88", "19E753", "0E8031", "064023"}
colors.str.Cyan       = {"7EEDED", "2CE6E6", "118787", "0A4444"}
colors.str.Blue       = {"4C6FE3", "0A3EE2", "0F2E91", "0A1D5A"}
colors.str.Violet     = {"AE79F0", "7514ED", "500AA6", "35086C"}
colors.str.Magenta    = {"EE7BF0", "CF11D2", "720A74", "520653"}
colors.str.Red        = {"F06767", "D02525", "7C0000", "560202"}
colors.str.Orange     = {"EEAF5C", "DF7F00", "673B00", "472800"}

for name, tbl in pairs(colors.str) do
    colors.sm[name] = {}
    for i, data in ipairs(tbl) do
        colors.sm[name][i] = sm.color.new(data)
    end
end

--------------------------------------

local constrain = constrain
function colors.hsvToRgb(h, s, v)
    h = constrain(h, 0, 1)
    s = constrain(s, 0, 1)
    v = constrain(v, 0, 1)

    local r, g, b

    local i = math.floor(h * 6)
    local f = h * 6 - i
    local p = v * (1 - s)
    local q = v * (1 - f * s)
    local t = v * (1 - (1 - f) * s)

    if i % 6 == 0 then
        r, g, b = v, t, p
    elseif i % 6 == 1 then
        r, g, b = q, v, p
    elseif i % 6 == 2 then
        r, g, b = p, v, t
    elseif i % 6 == 3 then
        r, g, b = p, q, v
    elseif i % 6 == 4 then
        r, g, b = t, p, v
    elseif i % 6 == 5 then
        r, g, b = v, p, q
    end

    return r, g, b
end

sc.reg_internal_lib("colors", colors)
return colors