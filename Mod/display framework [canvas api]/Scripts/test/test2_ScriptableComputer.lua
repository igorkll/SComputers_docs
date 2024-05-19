display = getDisplays()[1]
pos = (pos or 0) + 1
mul = (1 / display.getWidth()) * 5
display.clear("000000")
for ix = 0, display.getWidth() do
    for iy = 0, display.getHeight() do
        display.drawPixel(ix, iy, tostring(sm.color.new(sm.noise.perlinNoise2d((ix + pos) * mul, iy * mul, 0), 0, 0)))
    end
end
display.flush()