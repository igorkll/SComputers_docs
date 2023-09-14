local settings = {}
settings.path = "/data/settings.json"
settings.default = {
    mainProgrammPath = "/bin/desktop.lua",
    screenBrightness = "ff",
    onlyAFirstScreen = false,
    disableWorkingWithScreens = false,
    defaultSkipAtLags = true,
}

function settings.save()
    fs.write(settings.path, sm.json.writeJsonString(settings.current))
end

--------------------------------------

if fs.exists(settings.path) then
    settings.current = sm.json.parseJsonString(fs.read(settings.path))
else
    settings.current = utils.deepcopy(settings.default)
    settings.save()
end

return settings