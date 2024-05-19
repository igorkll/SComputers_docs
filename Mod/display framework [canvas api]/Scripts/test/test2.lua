dofile("$CONTENT_e8298053-4412-48e8-aff1-4271d1b07584/Scripts/canvas.lua")
test2 = class()

function test2:client_onCreate()
    self.display = sm.canvas.createClientScriptableCanvas(self.interactable, 64, 64, 2, sm.vec3.new(0, 1, 0))
    self.width = self.display.getWidth()
    self.height = self.display.getHeight()
    self.mul = (1 / self.width) * 5
end

function test2:client_onUpdate(dt)
    self.dt = dt
end

function test2:client_onFixedUpdate()
    self.pos = (self.pos or 0) + 1
    if self.display.getAudience() > 0 then
        self.display.clear()
        local pos = math.floor(self.pos)
        for ix = 0, self.width - 1 do
            for iy = 0, self.height - 1 do
                self.display.drawPixel(ix, iy, sm.color.new(sm.noise.perlinNoise2d((ix + pos) * self.mul, iy * self.mul, 0), 0, 0))
            end
        end
        self.display.flush()
    end
    self.display.update(self.dt)
end

function test2:client_onDestroy()
    self.display.destroy()
end