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