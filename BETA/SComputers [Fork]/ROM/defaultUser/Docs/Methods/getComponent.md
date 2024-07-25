---
sidebar_position: 26
title: getComponent
hide_title: true
sidebar-label: 'getComponent'
---

getComponent(string:name) - returns the API of one component of the specified type. if a component of this type is not connected, it generates an error.
if you do not need to issue an error, then use the method: getComponents("name")[1]