--ланная библиотека позваляет делать устройства в один блок, создавая виртуальные блокм

combinebox = {}

function combinebox.createBox(self)
    return combinebox.createRawBox(function ()
        return self.shape.worldPosition
    end, function ()
        return self.shape.worldRotation
    end, self.network, self.storage)
end

function combinebox.createRawBox(positionCallback, rotationCallback, network, storage)
    local box = {}
    box.network = network
    box.storage = storage

    box.blocks = {}
    box.positionCallback = positionCallback
    box.rotationCallback = rotationCallback

    if sm.isServerMode() then
        box.svCl = "server_"
    else
        box.svCl = "client_"
    end
    
    function box.add(id, cls)
        table.insert(box.blocks, {id = id, cls = cls, self = {
            
        }})
    end

    function box.tick()
        
    end

    return box
end