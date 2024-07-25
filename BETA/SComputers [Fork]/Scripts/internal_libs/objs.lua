local objs = {}

objs.textbox = {
    drawer = function(self)
        local fontX = self.display.getFontWidth()
        local fontY = self.display.getFontHeight()
        local text = self.args[1]
        local color = self.args[2]
        local centerText = self.args[3]
        local centerLines = self.args[4]
        if self.args[5] then
            self.display.fillRect(self.x, self.y, self.sizeX, self.sizeY, self.args[5])
        end

        local lines = {}
        for _, line in ipairs(strSplit(utf8, text, "\n")) do
            for _, line in ipairs(splitByMaxSizeWithTool(utf8, line, self.sizeX / (fontX + 1))) do
                table.insert(lines, line)
            end
        end

        local index = 0
        for _, line in ipairs(lines) do
            local len = utf8.len(line)
            local px, py
            if centerText then
                px = (self.x + (self.sizeX / 2)) - ((len * (fontX + 1)) / 2)
            else
                px = self.x
            end
            if centerLines then
                py = (self.y + (self.sizeY / 2) + (index * (fontY + 1))) - ((#lines * (fontY + 1)) / 2)
            else
                py = self.y + (index * (fontY + 1))
            end
            if py >= self.y and py + fontY < self.y + self.sizeY and px >= self.x and px + fontX < self.x + self.sizeX then
                self.display.drawText(px, py, line, color)
            end
            index = index + 1
        end
    end
}

objs.panel = {
    drawer = function(self)
        self.display.fillRect(self.x, self.y, self.sizeX, self.sizeY, self.args[1] or 0xffffff)
    end
}

sc.reg_internal_lib("objs", objs)
return objs