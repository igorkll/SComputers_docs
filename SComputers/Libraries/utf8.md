---
sidebar_position: 3
title: utf8
hide_title: true
sidebar-label: 'utf8'
---

not a complete utf8 implementation, does not require connection via require

### methods
* utf8.sub(str, i, j):str - cuts the string from i to j
* utf8.len(str):number - outputs the length of the string in characters
* utf8.code(str, i):str - works exactly the same as utf8.sub, but instead of i and j, only i which works both as i and as j (this method is more optimized than utf8.sub)