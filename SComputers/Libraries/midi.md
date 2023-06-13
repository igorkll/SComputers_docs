---
sidebar_position: 6
title: midi
hide_title: true
sidebar-label: 'midi'
---

### midi library
* midi.create():player

### player object
* player:load(disk, path) - loads a midi file
* player:loadStr(midicontent) - loads a midi file from a string
* player:tick() - every tick should be called
* player:setSynthesizers(synthesizers) - installs a new synthesizer table (may contain virtual synthesizers for connecting custom equipment)
* player:start()
* player:stop()
* player:isPlaying():boolean - returns true if playback is currently in progress
* player:setDefaultInstrument(id:number) - install a standard musical instrument(default: 4)
* player:setVolume(number) - sets the playback volume by a number from 0 to 1, by default 0.1
* player:setNoteAlignment(mode:number) - sets the action to be performed with notes that are not included in the range (0 - skip, 1 - search for the nearest) (default: 1)
* player:setNoteShift(shift:number) - sets the shift of notes relative to midi (default -50)
* player:setSpeed(number) - sets the playback speed multiplier (default is 1)

### gui example
#### to use the example, import standard midi files to disk
```lua
midi = require("midi")

synthesizers = getSynthesizers()
disk = getDisks()[1]

player = midi.create()
player:load(disk, "1.mid")
player:setSynthesizers(synthesizers)
player:setSpeed(1)
player:setNoteShift(-50)
player:setNoteAlignment(1)
player:setVolume(0.1)
player:setDefaultInstrument(4)

player:start()
function callback_loop()
    if _endtick then
        player:stop()
    end
    player:tick()
end
```