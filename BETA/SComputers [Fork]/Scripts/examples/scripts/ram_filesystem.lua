--example, this code allows you to allocate a small file system in a computer data string
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