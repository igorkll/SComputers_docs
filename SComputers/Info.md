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
global lua changes, now the number of iterations is unlimited, but the execution time of one tick is limited, if the computer does not have time to execute the code in time, an error will pop up
you can configure how much the computer can "delay" the game-tick in the "Permission Tool" (by default: 2 ticks)
::::

### small changes
* in safe-mode, the implementation of sm.json has changed to the json library available via require. since the use of sm.json can cause problems as well as game crashes
* when using clientInvoke(available only in unsafe-mode), ENV will be saved, however, the code is loaded anew every time
* clientInvoke(str, ...) supports arguments
* get exceptions "path .. underflow" when using the filesystem has become impossible, instead superfluous ".." just ignore

### this mod contains new components such as:
* sound synthesizer
* address led
* non-square displays
* holographic projector
* keyboard


### lua implementations
* lua-in-lua   (there are bugs)
* scrapVM      (the best option - however, it also contains bugs)
* dlm          (the best option at the moment)
* full lua env (dangerous)


### Permission Tool
* Script Mode: Safe/Unsafe (creative tool only)
* LuaVM: luaInLua/scrapVM/fullLuaEnv
* allow chat/alert/debug messages: false/true (creative tool only)


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
before the computer crashes (but it will crash anyway if you delete the crash information from crashstate on callback_error function)
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

### tablet features
* The renderAtDistance screen function on the tablet will display the screen even if the tablet is not in your hand
* the tablet screen is displayed only to the one who holds it in his hand
* press R to edit the tablet settings
* press Q to turn the tablet on or off

### font features
* added small english letters
* added large Russian letters
* added small Russian letters

### raycast-camera features
* now methods can accept additional colors
* drawColor(display, noCollideColor, terrainColor)
* drawDepth(display, baseColor, noCollideColor)
* drawColorWithDepth(display, noCollideColor, terrainColor)

### motor features
* motor.getAvailableBatteries - the number of batteries available to the motor will be reduced, the creative motor will return math.huge
* motor.getCharge - returns the charge of the motor, if it reaches 0, the motor will try to take the battery and add 200-000 to the charge
* motor.getChargeAdditions - it will return how much the charge of the motor increases when it "eats" one battery(200-000)
the creative motor always has a math.huge charge, the
motor loses charge depending on the load, if the bearings are blocked, the engine will quickly drain all the batteries
* motor.getChargeDelta - it will return how much charge the motor loses in 1 tick (the creative motor has 0)
* motor.getBearingsCount:number - returns the number of bearings connected to the motor
* motor.isWorkAvailable:boolean -
returns true if the engine can start working at the moment (if there is a charge or something to replenish it with)
the creative engine method will always return true
* motor.maxStrength - will return the maximum power for this engine (creative 10-000, survival 1000)
* motor.maxVelocity - will return the maximum speed for this engine (creative 10-000, survival 500)

### disk features
* disk.clear() - clear the disk
* disk.getMaxSize():number - returns the maximum amount of data that can be written to disk in bytes

### display features
* display.reset() - resets all screen settings, list:
maxClicks, rotation, framecheck, skipAtNotSight, utf8support, renderAtDistance, skipAtLags
* display.forceFlush() - 
it works like a regular flush, but updates the picture with 100% probability,
ignoring setFrameCheck/setSkipAtNotSight/setSkipAtLags
* display.setUtf8Support/display.getUtf8Support -
default: false.
it is necessary to enable utf8 characters for output, however, it may cause performance degradation when rendering text.
* display.setSkipAtNotSight/display.getSkipAtNotSight -
default: false.
if set to true, the screen will not be updated for those people who do not look at it.
this should be set to true if skipping frames will not cause problems.
if the screen is updated rarely and every frame is important, then you should set false.
* display.setFrameCheck/display.getFrameCheck -
default: true.
if set to true, the display will compare the rendering table, and if they are the same, it will skip the rendering.
this can optimize a lot of software, but if you do not cause unnecessary renderings, it is better to turn off this option.
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
* you can import your generated image($CONTENT_DATA/USER/importer/disk.json), or a ready-made OS (scraps)


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