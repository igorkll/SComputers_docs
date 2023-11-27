warnings = {}

if not dlm then
    table.insert(warnings, "#FF0000WARNING#FFFFFF: the DLM is not installed, the mod will use the LUA virtual machine, which may cause the code to malfunction")
    table.insert(warnings, "it is recommended to install DLM(DLM LEGACY): https://steamcommunity.com/sharedfiles/filedetails/?id=2988924872")
end

function sc.warningsCheck()
    if _checked then return end
    _checked = true

    local origBlockUuid = sm.uuid.new("41d7c8b2-e2de-4c29-b842-5efd8af37ae6")
    if pcall(sm.shape.createPart, origBlockUuid, sm.vec3.new(0, 0, 10000)) then
        table.insert(warnings, "#FF0000CRITICAL ERROR#FFFFFF: SComputers conflicts with ScriptableComputer or another fork of ScriptableComputer!!!! URGENTLY REMOVE ALL OTHER COMPUTER MODS FROM YOUR WORLD, OTHERWISE SCOMPUTERS WILL NOT WORK")
        sc.shutdownFlag = true
    end
end