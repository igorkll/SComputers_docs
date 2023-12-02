servicetool = class()
servicetool.instance = nil

function servicetool:client_onFixedUpdate()
    servicetool.instance = self

    if sm.sc_g then
        if not sm.sc_g.computersAllow then
            sm.sc_g.updateToolSettings = true
        end
        sm.sc_g.computersAllow = true
        if sm.sc_g.servicetool and sm.sc_g.servicetool.instance.gui then
            sm.sc_g.servicetool.instance.gui:close()
            sm.sc_g.servicetool.instance.gui = nil
        end
    end
end