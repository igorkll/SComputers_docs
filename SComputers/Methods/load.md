---
sidebar_position: 14
title: load
hide_title: true
sidebar-label: 'load'
---

load(chunk, chunkname, mode, env):func,err - it works like a loadstring from vanilla Scriptable Computers
, but the signature and behavior in case of an error like the standard load from new versions of lua
does not throw exceptions when loading an invalid piece of code
allows you to set the name of a piece of code
, however, mode is always perceived as "t" and does not allow loading bytecode, since it is not safe