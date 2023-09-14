---
sidebar_position: 2
title: getComponents
hide_title: true
sidebar-label: 'getComponents'
---

getComponents(string:name) - retrieves a table with components of the specified type
if such components are not connected or this type does not exist, an empty table will be returned.
this method is now the main one for getting
components. old methods such as getDisplays are now aliases on getComponents with an automatically transmitted type,
all new components such as terminal can be obtained only by this method.