---
sidebar_position: 1
title: image
hide_title: true
sidebar-label: 'image'
---

![image demo](/img/image_demo.png)

### image library
#### allows you to use images in bmp, scimg, scimg8
#### scimg8 this is an 8 bit image, It takes up 4 times less space than usual. when saving scimg8, be sure to specify the extension so that the load method understands that you need to use the 8 decoder
* image.new(number:resolutionX, number:resolutionY, smcolor:basecolor):img
* image.load(disk, path):img - loads the image from the disk, if the extensions are bmp, then parses using the decodeBmp method
otherwise parses as scimg(decode method). if the extension is scimg8, the decode8 method will be used
* image.save(img, disk, path) - saves the image to disk in scimg format (regardless of the selected expansion)
* image.save8(img, disk, path) - saves the image to disk in scimg8 format (regardless of the selected expansion)

* image.encode(img):string - converts an image to bytestring(in scimg format)
* image.encode8(img):string - converts an image to bytestring(in scimg8 format)
* image.decode(string):img - converts bytestring to an image, from scimg format
* image.decode8(string):img - converts bytestring to an image, from scimg8 format
* image.decodeBmp(string):img - converts bytestring to an image, from bmp format

* image.draw(img, display, number:posX[default:0], number:posY[default:0]) - 
draw the image on the monitor, transparency is supported, but if the transparency is greater than 0, the pixel will not be transparent
* image.drawForTicks(img, display, number:tick[default:40], number:posX[default:0], number:posY[default:0]):function_drawer -
draws an image image for a certain number of ticks (40 by default)
will return a function that needs to be called until it returns true (further call does not make sense)
note that one generated function can only be used 1 time
* image.get(img, x, y):smcolor
* image.set(img, x, y, smcolor)
* image.getSize(img):sizeX:sizeY
* image.fromCamera(img, camera, methodName, ...) - gets a piece of the image from the camera according to its settings
send the camera, method name, and arguments for the method (to set basecolor)
* image.fromCameraAll(img, camera, methodName, ...) - gets all the images from the camera entirely