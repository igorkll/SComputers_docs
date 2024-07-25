_g_examples = nil

function loadExample(self, widgetName, text)
    if widgetName == "exmpnum" then
        self.lastExampleStr = text
        return
    elseif widgetName == "exmpload" then
        if self.lastExampleStr then
            local example = _g_examples[self.lastExampleStr:gsub(" ", "_")] or _g_examples_num[tonumber(self.lastExampleStr) or false]
            if example then
                ScriptableComputer.cl_setText(self, example)
            else
                self:cl_internal_alertMessage("failed to load an example")
            end
        end
    end
end

function bindExamples(self)
    if not _g_examples then
        _g_examples = sm.json.open("$CONTENT_DATA/Scripts/examples/examples.json")
        _g_examples_num = {}
        local list = {}
        for k, v in pairs(_g_examples) do
            table.insert(list, k)
            _g_examples[k] = base64.decode(v)
        end
        table.sort(list)
        _g_examples_text = ""
        for i, name in ipairs(list) do
            _g_examples_text = _g_examples_text .. i .. ". " .. name:gsub("_", " ") .. "\n"
            _g_examples_num[i] = _g_examples[name]
        end
    end

    self.gui:setText("exmplist", _g_examples_text)
    self.gui:setButtonCallback("exmpload", "cl_onExample")
    self.gui:setTextChangedCallback("exmpnum", "cl_onExample")
end