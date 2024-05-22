local vdisplay = {}
local color_new = sm.color.new

local function localNeedPushStack(audience, dataTunnel, dt, skipAt)
    return dataTunnel.display_forceFlush or not ((dataTunnel.skipAtNotSight and audience <= 0) or (dataTunnel.skipAtLags and dt and dt >= (1 / (skipAt or 20))))
end

function vdisplay.create(callbacks, width, height)
    local dataTunnel = {}
    local audience = 1
    local libUpdate
    local obj = sm.canvas.createScriptableApi(width, height, dataTunnel, function ()
        libUpdate()
    end)
    local drawer = sm.canvas.createDrawer(width, height, function (x, y, color)
        callbacks.set(obj, x, y, color_new(color))
    end)
    callbacks.pushClick = sm.canvas.addTouch(obj, dataTunnel)

    function callbacks.updateAudience(_audience)
        checkArg(1, "number", _audience)
        audience = _audience
    end

    local oldUpdateTick
    function libUpdate()
        local ctick = sm.game.getCurrentTick()
        if ctick == oldUpdateTick then return end
        oldUpdateTick = ctick

        dataTunnel.scriptableApi_update()

        if dataTunnel.display_reset then
            drawer.drawerReset()
            dataTunnel.display_reset = nil
        end

        if dataTunnel.dataUpdated then
            drawer.pushDataTunnelParams(dataTunnel)
            dataTunnel.dataUpdated = nil
        end

        if dataTunnel.display_flush then
            if localNeedPushStack(audience, dataTunnel, sc.deltaTime, sc.restrictions.skipFps) then
                drawer.pushStack(dataTunnel.display_stack)
                drawer.flush()
                callbacks.flush(obj, not not dataTunnel.display_forceFlush)
            end
            
            dataTunnel.display_flush()
            dataTunnel.display_stack = nil
            dataTunnel.display_flush = nil
            dataTunnel.display_forceFlush = nil
        end
    end
    callbacks.update = libUpdate

    function obj.getAudience()
        return audience
    end

    drawer.flush(true)
    return obj
end

sc.reg_internal_lib("vdisplay", vdisplay)
return vdisplay