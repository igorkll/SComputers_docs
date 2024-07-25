warnings = {}

if not better then
    table.insert(warnings, "#FF0000WARNING#FFFFFF: the BetterAPI is not installed, the mod will use the LUA virtual machine, which may cause the code to malfunction.\nit is recommended to install BetterAPI: https://steamcommunity.com/sharedfiles/filedetails/?id=3177944610")
end

pcall(dofile, "$CONTENT_e8298053-4412-48e8-aff1-4271d1b07584/Scripts/canvas.lua")
if not sm.canvas then
    table.insert(warnings, "#FF0000WARNING#FFFFFF: for some reason, you did not download the display framework automatically, the displays will not work until you manually download: https://steamcommunity.com/sharedfiles/filedetails/?id=3202981462")
end

function sc.warningsCheck()
    if _checked then return end
    _checked = true

    local origBlockUuid = sm.uuid.new("41d7c8b2-e2de-4c29-b842-5efd8af37ae6") --old screen pixel uuid
    if pcall(sm.shape.createPart, origBlockUuid, sm.vec3.new(0, 0, 10000)) then
        table.insert(warnings, "#FF0000CRITICAL ERROR#FFFFFF: SComputers conflicts with ScriptableComputer or another fork of ScriptableComputer!!!! URGENTLY REMOVE ALL OTHER COMPUTER MODS FROM YOUR WORLD, OTHERWISE SCOMPUTERS WILL NOT WORK")
        sc.shutdownFlag = true
    end
end