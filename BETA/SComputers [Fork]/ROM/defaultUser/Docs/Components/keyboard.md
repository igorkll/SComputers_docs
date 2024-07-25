---
sidebar_position: 3
title: keyboard
hide_title: true
sidebar-label: 'keyboard'
---

### keyboard api
* type - keyboard
* clear() - clear the input field
* read():string - get text from the input field
* write(string):bool - write text in the input field
* isEnter():boolean - returns true if the enter button was pressed in the gui (not on a real keyboard)
after polling, you need to call resetButtons
* isEsc():boolean - returns true if the escape button was pressed in the gui (not on a real keyboard)
after polling, you need to call resetButtons
* resetButtons(): - call the post after you have pulled the keyboard buttons to reset the flags