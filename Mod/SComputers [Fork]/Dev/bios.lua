if bios_stop then
    if _endtick and bios_screen then
        pcall(bios_screen.clear, "000000")
        pcall(bios_screen.flush)
    end
    return
end
if not bios_start then
    bios_disk = getDisks()[1]
    bios_screen = getDisplays()[1]
    bios_bootfile = "/init.lua"

    systemDisk = bios_disk

    function bios_splash(str, isErr)
        --if isErr then
        --    print(str)
        --end

        if not bios_screen then
            --if isErr then
            --    error(str, 0)
            --end
            return
        end

        local function toParts(str, max)
            local strs = {}
            while #str > 0 do
                table.insert(strs, str:sub(1, max))
                str = str:sub(#strs[#strs] + 1)
            end
            return strs
        end

        local strs = toParts(str, math.floor(bios_screen.getWidth() / 5))
        bios_screen.clear("000000")
        for i, v in ipairs(strs) do
            bios_screen.drawText(0, (i - 1) * 7, v, "00FF00")
        end
        bios_screen.flush()
    end

    

    if not bios_disk then
        bios_splash("disk not found", true)
        bios_stop = true
        return
    elseif bios_disk.hasFile(bios_bootfile) then
        local ok, result = pcall(loadstring, bios_disk.readFile(bios_bootfile))
        if ok then
            bios_systemcode = result
        else
            bios_systemerror = result
        end

        if not bios_systemcode then
            bios_splash("failed to loading: " .. (bios_systemerror or "unknown"), true)
            bios_stop = true
            return
        end
    else
        bios_splash("init file not found", true)
        bios_stop = true
        return
    end

    bios_start = true
end

local ok, err = pcall(bios_systemcode, bios_disk)
if not ok then
    bios_splash("error in os: " .. (err or "unknown"), true)
    bios_stop = true
end