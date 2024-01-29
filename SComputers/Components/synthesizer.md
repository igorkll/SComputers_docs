---
sidebar_position: 5
title: synthesizer
hide_title: true
sidebar-label: 'synthesizer'
---

### synthesizer api
* type - synthesizer
* clear() - remove all added sounds from the synthesizer RAM
* stop() - stop all playing sounds
* addBeep(device(0-9 default=0), pitch(0-1 default=0.5), volume(0-1 default=0.1), duration(ticks default=math.huge))
* flush() - make a sound

### synthesizer loop api
* getLoopsCount():number - returns the maximum number of cycles that you can run (4)
* getLoopsWhilelist():table - returns a table with the available cyclic effects to playing
* startLoop(number, loopname, params) - triggers a cyclic effect with the specified name, parameters, and number
* stopLoop(number) - stops the cycle with the specified number (from 1 to 4)
* stopLoops() - stops all cycles
* setLoopParams(table) - sets new parameters for the loop

### imitation of engine sound
```lua
synthesizer = getComponent("synthesizer")
synthesizer.stopLoops()
synthesizer.startLoop(1, "GasEngine - Level 3")

function callback_loop()
    if _endtick then
        synthesizer.stopLoops()
        return
    end

    synthesizer.setLoopParams(1, {
        rpm = 0.8,
        load = math.abs(math.sin(math.rad(getUptime())))
    })
end
```