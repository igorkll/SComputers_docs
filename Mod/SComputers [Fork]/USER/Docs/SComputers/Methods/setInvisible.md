---
sidebar_position: 11
title: setInvisible
hide_title: true
sidebar-label: 'setInvisible'
---

setInvisible(state, permanent) / getInvisible():state,
permanent makes the computer invisible to other computers connected to it,
the invisible state can be protected from change by the second argument. getInvisible also returns 2 boolean
invisibility does not interfere with the operation of setComponentApi.
only getParentComputers and getChildComputers methods will not see the computer if this option is enabled