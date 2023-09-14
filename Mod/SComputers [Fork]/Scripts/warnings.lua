warnings = {}

if not dlm then
    table.insert(warnings, "#FF0000WARNING#FFFFFF the DLM is not installed, the mod will use the LUA virtual machine, which may cause the code to malfunction")
    table.insert(warnings, "it is recommended to install DLM(DLM LEGACY): https://steamcommunity.com/sharedfiles/filedetails/?id=2988924872")
end