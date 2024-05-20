--plays a midi file from a disc
midi = require("midi")

synthesizers = getSynthesizers()
disk = getDisks()[1]

player = midi.create()
player:load(disk, "2.mid")
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