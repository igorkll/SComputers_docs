---
sidebar_position: 8
title: ramfs
hide_title: true
sidebar-label: 'ramfs'
---

## allows you to create a file system in RAM
### the maximum size of a file system of this type is not limited, however, the amount of data being written is limited by the amount of real RAM

#### methods
* ramfs.new(sizeinbytes:number):fsobj - creates a new file system with the specified size
* ramfs.load(fsdump:string) - accepts a file system dump

#### fsobj
* fsobj:dump():string - creates a dump of the filesystem
* fsobj:isChange():boolean - returns true if changes have been made to the file system
* fsobj.fs - contains the file system api (same as disks)


#### example, this code allows you to allocate a small file system in a computer data string
```lua
local ramfs = require("ramfs")

local currentComputerData = getData()
local fsobj
if currentComputerData == "" then
    fsobj = ramfs.create(1024 * 2)
else
    fsobj = ramfs.load(currentComputerData)
end

local disk = fsobj.fs

-----------------------------------

if not disk.hasFile("/test") then
    disk.createFile("/test")
    disk.writeFile("/test", "test data")
end

if not disk.hasFile("/test2") then
    disk.createFile("/test2")
    disk.writeFile("/test2", "test data 2")
end



print("files:")
for i, v in ipairs(disk.getFileList("/")) do
    print(v, ":", disk.readFile(v))
end

function callback_loop()
    if fsobj:isChange() then
        setData(fsobj:dump())
    end
end
```