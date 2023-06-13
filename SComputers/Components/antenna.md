---
sidebar_position: 1
title: antenna
hide_title: true
sidebar-label: 'antenna'
---

### antenna - antenna api (a network port is still needed for data transmission)
* type - antenna
* getRadius():number - returns the radius in meters(1 meter - 4 blocks) how far the messages are sent
* getChannel():number - returns the antenna channel
* setChannel(number) - set the antenna channel
* setActive(state:boolean) - turns the antenna on or off
* isActive():state - returns true if the antenna is enabled, it is enabled initially