if not better then return end

local baseCode = [[-------------------------------------- 

local function call(func, ...)
    if func then
        func(...)
    end
end

call(onStart)

function callback_loop() --a new entry point to the program
    if _endtick then
        call(onStop)
    else
        call(onTick, getDeltaTimeTps())
    end
end

function callback_error(err) --native SComputers error handler
    if onError and onError(err) then
        reboot()
    end
end]]

local allowedChars = {}
for i = 33, 126 do
    allowedChars[string.char(i)] = true
end

local function simpleFind(str, test)
    for i = 1, #str do
        local endf = i + (#test - 1)
        if str:sub(i, endf) == test then
            return i, endf
        end
    end
end

function ai_codeGen(prompt)
    local startpos = select(2, simpleFind(prompt, "--[[")) or 0
    local endpos = simpleFind(prompt, "]]") or (#prompt + 1)
    prompt = prompt:sub(startpos + 1, endpos - 1)
    while true do
        local firstChar = prompt:sub(1, 1)
        if firstChar == "\n" then
            prompt = prompt:sub(2, #prompt)
        else
            local lastChar = prompt:sub(#prompt, #prompt)
            if lastChar == "\n" then
                prompt = prompt:sub(1, #prompt - 1)
            else
                break
            end
        end
    end

    local async = better.openAI.textRequest(nil, nil,
        better.filesystem.readFile("$CONTENT_3aeb81c2-71b9-45a1-9479-1f48f1e8ff21/ROM/chatGPTprompt.txt"),
        prompt
    )

    return function ()
        local str = async()
        if str then
            local startpos = select(2, str:find("```lua")) or select(2, str:find("```")) or 0
            local endpos = str:find("```", startpos + 1) or (#str + 1)
            local code = str:sub(startpos + 1, endpos - 1)
            while true do
                if #code == 0 then
                    break
                end
                local firstChar = code:sub(1, 1)
                if not allowedChars[firstChar] then
                    code = code:sub(2, #code)
                else
                    local lastChar = code:sub(#code, #code)
                    if not allowedChars[lastChar] then
                        code = code:sub(1, #code - 1)
                    else
                        break
                    end
                end
            end
            local selfPrompt = "--ai code-gen prompt:\n--[[\n" .. prompt .. "\n]]\n\n"
            if #code > 0 and load_code(nil, code) then
                return selfPrompt .. code .. "\n\n" .. baseCode, true
            else
                return selfPrompt .. str, false
            end
        end
    end
end