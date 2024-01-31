local styles = {}

function styles:switch()
    local color1, color2, bg = self.fg, self.bg, self.bg
    if self.state then
        color1, color2, bg = self.bg_press, self.fg_press, self.bg_press
    end

    local sy = self.sizeY / 2
    local addX = sy - 1
    local py = (self.y + sy) - 1

    self.display.fillRect(self.x + addX, self.y, self.sizeX - (addX * 2), self.sizeY, bg)
    for i = 0, 1 - (self.sizeY % 2) do
        if self.state then
            self.display.fillCircle(self.x + addX, py + i, sy, color1)
            self.display.fillCircle(self.x + (self.sizeX - 1 - addX), py + i, sy, color2)
        else
            self.display.fillCircle(self.x + (self.sizeX - 1 - addX), py + i, sy, color2)
            self.display.fillCircle(self.x + addX, py + i, sy, color1)
        end
    end
end

sc.reg_internal_lib("styles", styles)
return styles