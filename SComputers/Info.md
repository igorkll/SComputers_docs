---
sidebar_position: 1
title: Info
hide_title: true
sidebar-label: 'Info'
---

<br></br>

![SComputers Image](/img/SComputers.jpg)

## steam link: [SComputers](https://steamcommunity.com/sharedfiles/filedetails/?id=2949350596)

### this documentation describes only the methods added by SComputers, see the official documentation for the basic methods added by Scriptable Computers: [Scriptable Computers Documentation](https://steamcommunity.com/sharedfiles/filedetails/?id=2831560152)

SComputers, this is a fork of the Scriptable Computers mod
this fork is compatible with the code of the original Scriptable Computers and with the SCI code
however, programs written for this mod will not work on the original Scriptable Computers

:::info note
in the original "ScriptableComputer" luaInLua worked terribly and contained a bunch of bugs,
in SComputers most of the luaInLua bugs were fixed
:::

:::info note
global lua changes, now the number of iterations is unlimited, but the execution time of one tick is limited, if the computer does not have time to execute the code in time, an error will pop up
you can configure how much the computer can "delay" the game-tick in the "Permission Tool" (by default: 4 ticks)
::::

### sm library in safe-mode
* sm.game.getCurrentTick / sm.game.getServerTick - added recently (because you still have os.time/os.clock)
* uuid - full, added by SComputers
* vec3 / util / quat / noise / color - full(with additional checks to avoid crashes)
* sm.json.parseJsonString / sm.json.writeJsonString - standard json implementation with additional checks

### small changes
* in safe-mode, additional checks have been added to some methods of the SM library (in order to avoid crashes) (previously, only json implementation switched to the built-in json mod library, there were still ways to call bugsplat, and this library has significant differences, so sm.json in safe-mode is now sm again.json but with additional checks)
* when using clientInvoke(available only in unsafe-mode), ENV will be saved, however, the code is loaded anew every time
* clientInvoke(str, ...) supports arguments
* exceptions "path .. underflow" cannot be retrieved. the extra ".." is simply ignored
* the combination of characters "\n" (two separate characters and not a new line) can be displayed in the gui as "¦n" this is due to the fact that mygui (which uses scrapmechanic) turns "\n" into a new line (at the same time, "¦n" works like normal "\n")
* now, when disabling a component/removing a component, it is guaranteed not to be work
* now the stepper motors do not create any force in the off state
* now the camera is able to see the units in a separate (by you exposed) color(by default, this color is bright white in all rendering modes)
* The camera's FOV is limited to 90 degrees
* The radar.getTargets method can now be used only once per tick on one radar (to avoid noise filtering) if you need to filter the noise then use multiple radars
* port.nextPacket can now be called even if there are no packets in the buffer without the risk of an error, the method will simply return nil if the packet is not in the buffer
* port.nextPacket now it returns 2 values, the first is the packet itself, and the second is the ID of the port from which the packet was sent
* fixed a bug that prevented radars from seeing static objects

### recommendations
* if the antenna on your device works only for receiving then you can put an NFC antenna, the antenna radius affects only the transmission

### this mod contains new components such as:
* sound synthesizer
* address led
* non-square displays
* holographic projector
* keyboard
* gps
* gpstag
* ibridge (Internet Bridge)


### lua implementations
* lua-in-lua   (most of the bugs have been fixed, but the debugging process of the program can be difficult)
* scrapVM      (very bad interpreter, support is over)
* dlm          (the best option at the moment)
* full lua env (dangerous)


### Permission Tool
* allow chat/alert/debug messages: false/true (creative tool only)
* Script Mode: Safe/Unsafe (creative tool only)
* LuaVM: luaInLua/dlm/fullLuaEnv

### Internal Libs
##### to get the internal libraries, use the require method(require not required for utf8 and coroutine)
* utf8(not full implementation)
* coroutine
* image
* base64
* gui
* json(custom implementation)
* image
* midi
* colors
* ramfs

### sandbox features
* if you declare the function "callback_error(str)" then it will be called in cases of an error in the computer
before the computer crashes (but it will crash anyway if you not delete the crash information from "crashstate" on callback_error function)
at the same time, it will be called before the crash and you will be able to "cancel" the crash
using the "getCurrentComputer" method and interacting with the crashstate table
if an exception occurs in this function, it can be caught only in the game logs/debug console
* if you declare the "callback_loop" function, it will be called on the next tick instead of calling the entire program
* there is a SCI api for compatibility (env.SCI =env)
* added the load method, which allows you to set the name of a piece of code and works as in a normal lua, but does not allow you to load bytecode
* the crashstate table has been added to the public api of the computer (getChildComputers and getParentComputers and getCurrentComputer)
there are two values hasException and exceptionMsg
you can write your values there
* the _endtick flag that is automatically raised if the computer's tick is the last one
* _VERSION contains uses VM name

### clientInvoke removed methods(the following functions will be unavailable in clientInvoke/clientInvokeTo)
* getComponents (and all aliases)
* reboot
* setCode / getCode
* setData / getData
* setLock / getLock
* setAlwaysOn / getAlwaysOn
* setInvisible / getInvisible
* getCurrentComputer / getChildComputers / getParentComputers
* clearregs / getreg / setreg
* ninput / input / out
* clientInvoke / clientInvokeTo
* setComponentApi / getComponentApi
* getMaxAvailableCpuTime / getDeltaTime / getUsedRam / getTotalRam / getUptime

### tablet features
* The renderAtDistance screen function on the tablet will display the screen even if the tablet is not in your hand
* the tablet screen is displayed only to the one who holds it in his hand
* press R to edit the tablet settings
* press Q to turn the tablet on or off

### font features
* added small english letters
* added large Russian letters
* added small Russian letters

### radar features
* radar.getTargets() - now returns the object type (character/body) by parameter number 6

### raycast-camera features
* camera.getSkyColor():smcolor - returns the color of the sky (even if the sky is not visible to the camera at the moment) this color is used in advanced rendering
* camera.rawRay(xAngle:number, yAngle:number, maxdist:number):table, nil - ray shoots from the camera and gives out a table {color = smcolor, distance = distance, fraction = distance/maxdist, uuid = uuid, type = character/shape/harvestable/lift/joint/terrain/asset/limiter}. maxdist is the maximum distance for raycast in meters. please note that the angle can be set from -45 to 45 degrees, it is transmitted in radians. limiter is the wall of the world. please note that not all types of objects have the "color" and "uuid" field. please note that getting the uuid of a block only works if it is no further than 4 meters (16 blocks) from the camera
* new rendering types
* camera.drawCustom(display, drawer(xPos:number, yPos:number, raydata:table):smcolor) - custom render, you must pass a function that will receive pixel pos and raydata as input (the same as rawRay outputs) and this function should return the color that you need to paint the pixel
* camera.drawAdvanced(display) - advanced rendering which is designed to give the most realistic picture possible at the moment
* now methods can accept additional colors
* camera.drawColorWithDepth(display, noCollideColor, terrainColor, unitsColor)
* camera.drawColor(display, noCollideColor, terrainColor, unitsColor)
* camera.drawDepth(display, baseColor, noCollideColor, unitsColor)

### antenna features
* the antenna now has its own API which you can view in the components section

### network-port features
* port.getUniqueId() - get a unique port ID
* port.sendTo(id, package:string) - transmits a packet to a specific port

### motor features
* motor.getAvailableBatteries() - the number of batteries available to the motor will be reduced, the creative motor will return math.huge
* motor.getCharge() - returns the charge of the motor, if it reaches 0, the motor will try to take the battery and add 200-000 to the charge
* motor.getChargeAdditions() - it will return how much the charge of the motor increases when it "eats" one battery(200-000)
the creative motor always has a math.huge charge, the
motor loses charge depending on the load, if the bearings are blocked, the engine will quickly drain all the batteries
* motor.getChargeDelta() - it will return how much charge the motor loses in 1 tick (the creative motor has 0)
* motor.getBearingsCount():number - returns the number of bearings connected to the motor
* motor.isWorkAvailable():boolean -
returns true if the engine can start working at the moment (if there is a charge or something to replenish it with)
the creative engine method will always return true
* motor.maxStrength() - will return the maximum power for this engine (creative/mini-creative 10-000, survival 1000, mini 75)
* motor.maxVelocity() - will return the maximum speed for this engine (creative/mini-creative 10-000, survival 500, mini 75)
* motor.setSoundType(type:number) - sets the engine sound type:
* 0 - off,
* 1 - standard sound,
* 2 - gas engine 3 sound.
* motor.getSoundType():number - returns the current type of motor sound

### disk features
* disk.clear() - clear the disk
* disk.getMaxSize():number - returns the maximum amount of data that can be written to disk in bytes

### display features
* display.reset() - resets all screen settings, list of resettable data:
maxClicks, rotation, framecheck, skipAtNotSight, utf8support, renderAtDistance, skipAtLags, clickData(click list), clicksAllowed
and resets the font
* display.isAllow():boolean - returns true if this display is enabled, returns false if displays with this resolution are disabled in the mod configuration
* display.getAudience():number - returns the number of people who are looking at the screen. can be used for optimization
* display.forceFlush() - 
it works like a regular flush, but updates the picture with 100% probability,
ignoring setSkipAtNotSight/setSkipAtLags
* display.setUtf8Support/display.getUtf8Support -
default: false.
it is necessary to enable utf8 characters for output, however, it may cause performance degradation when rendering text.
* display.setSkipAtNotSight/display.getSkipAtNotSight -
default: false.
if set to true, the screen will not be updated for those people who do not look at it.
this should be set to true if skipping frames will not cause problems.
if the screen is updated rarely and every frame is important, then you should set false.
* display.setSkipAtLags/display.getSkipAtLags
default: true.
should I skip the rendering if the fps is lower than the one set by the user,
you should turn it on if the picture is constantly updated and skipping one flush will not lead to problems
, or turn it off if each rendering is important
* display.setRotation/display.getRotation
by default: 0
sets the orientation of the screen, please note that the old content will not be redrawed
* display.getFontWidth - returns the width of the current font
* display.getFontHeight - returns the height of the current font
* display.setFont - sets a custom font
to set a standard font, pass nil
the font is a lua format table:
```lua
{
    chars = {
        ["a"] = {
            "1111",
            "...1",
            "1111",
            "1..1",
            "1111"
        },
        ["error"] = {
            "1111",
            "1111",
            "1111",
            "1111",
            "1111"
        }
    },
    width = 4,
    height = 5
}
```


### how to use the importer
* to generate an image, use the importer utility, it is located in $CONTENT_DATA/USER/importer
* to import an image, use the disk menu, to do this, press the E button on it
* to open this menu on a PC with a built-in disk, use the button in its gui
* when importing, old files are not erased, in order to erase them, click clear
* you can import your generated image($CONTENT_DATA/USER/importer/disk.json), or a ready-made OS (scrapOS)
* at the moment, importing/exporting a custom image only works when you are the host!
* the "import from importer" and "export to importer" buttons import and export the image to the importer file(disk.json) the buttons below are responsible for importing/exporting to the "$CONTENT_DATA/USER/userdisks" folder
* on "windows", it is usually located along the path: "C:\Program Files (x86)\Steam\steamapps\workshop\content\387990\2949350596\USER\importer"

:::info note
the print/alert/debug functions will not work by default, for them to work, you need to configure this in the creative Permission Tool
:::

:::info note
disk sizes are GREATLY reduced in order to avoid non-spawning buildings and saving bugs,
the game cannot save even megabytes of data
now small and embedded disks have a volume of 64kb
a larger 128kb.
creative hard drive has a volume of 16 MB, but does not save data after re-entry and when saving
:::

:::info note
after adding always on, it is incorrect to use "not input()" to track the shutdown,
use the check "if _endtick then" there is a _endtick flag raised, this means the last tick
::::

:::caution warning
exceptions in callback_error, clientInvoke, clientInvokeTo cannot be handled in any way other than viewing game logs/debug console
:::

This documentation was written by MR.Logic.