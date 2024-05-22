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

        local index = 0
        for _, line in ipairs(splitByMaxSizeWithTool(utf8, text, self.sizeX / (fontX + 1))) do
            for _, line in ipairs(strSplit(utf8, line, "\n")) do
                local px, py
                if centerText then
                    px = (self.x + (self.sizeX / 2) / 2) - ((utf8.len(line) * (fontX + 1)) / 2)
                else
                    px = self.x
                end
                if centerLines then
                    py = self.y + (index * (fontY + 1))
                else
                    py = self.y + (index * (fontY + 1))
                end
                self.display.drawText(px, py, line, color)
                index = index + 1
            end
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