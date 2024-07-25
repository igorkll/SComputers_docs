function onStart()
    print("start") --please note that the "print" function is disabled by default in SComputers. use the "Permission tool" to enable it
end

function onTick(dt)
    print("tick", dt)
end

function onStop()
    print("stop")
end

function onError(err) --handles errors. return true if you want to restart the computer
    pcall(print, err)
    --return true
end

-------------------------------------- 

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
end