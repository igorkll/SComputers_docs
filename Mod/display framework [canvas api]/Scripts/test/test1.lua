dofile("$CONTENT_e8298053-4412-48e8-aff1-4271d1b07584/Scripts/canvas.lua")
test1 = class()

local function color(...)
    return sm.canvas.formatColorToNumber(sm.color.new(...))
end

function test1:client_onCreate()
    self.canvas = sm.canvas.createCanvas(self.interactable, 64, 64)
    self.canvas.setRenderDistance(5)
    self.rotation = 0
end

function test1:client_onFixedUpdate()
    --------------------------------------- motion

    self.canvas.setOffset(sm.vec3.new(0, 1.2 + (math.sin(math.rad(sm.game.getCurrentTick())) / 4), 0.4))
    self.canvas.setCanvasRotation(sm.quat.fromEuler(sm.vec3.new(0, math.rad(self.rotation), 0)))
    self.canvas.update()
    self.rotation = self.rotation + 16
    if not self.canvas.isRendering() then return end

    --------------------------------------- random fill

    local stack = {}
    for i = 1, 64 do
        local r = math.random(1, 3)
        local c = color(math.random() / 3, math.random() / 3, 0)
        if r == 1 then
            sm.canvas.pushData(stack, r, math.random(0, self.canvas.sizeX - 1), math.random(0, self.canvas.sizeY - 1), c)
        else
            sm.canvas.pushData(stack, r, math.random(0, self.canvas.sizeX - 1), math.random(0, self.canvas.sizeY - 1), math.random(0, 16), math.random(0, 16), c)
        end

        sm.canvas.pushData(stack, sm.canvas.draw.rect, 0, 0, self.canvas.sizeX, self.canvas.sizeY, color(1, 1, 1))
        sm.canvas.pushData(stack, sm.canvas.draw.set, 0, 0, color(0, 1, 0))
        sm.canvas.pushData(stack, sm.canvas.draw.set, self.canvas.sizeX - 1, 0, color(1, 0, 0))
        sm.canvas.pushData(stack, sm.canvas.draw.set, self.canvas.sizeX - 1, self.canvas.sizeY - 1, color(1, 1, 0))
        sm.canvas.pushData(stack, sm.canvas.draw.set, 0, self.canvas.sizeY - 1, color(0, 0, 1))
        sm.canvas.pushData(stack, sm.canvas.draw.set, 0, 1, color(0, 1, 1))
        sm.canvas.pushData(stack, sm.canvas.draw.set, 1, 0, color(0, 1, 1))
    end

    --------------------------------------- pushing

    self.canvas.pushStack(stack)
    self.canvas.flush()
end

function test1:client_onDestroy()
    self.canvas.destroy()
end