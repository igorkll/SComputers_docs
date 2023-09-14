---
sidebar_position: 1
title: image
hide_title: true
sidebar-label: 'image'
---

![image demo](/img/image_demo.png)

### image library
#### allows you to use images in bmp and scimg
* image.new(number:resolutionX, number:resolutionY, smcolor:basecolor):img
* image.load(disk, path):img - loads the image from the disk, if the extensions are bmp, then parses using the decodeBmp method
otherwise parses as scimg(decode method)
* image.save(img, disk, path) - saves the image to disk in scimg format (regardless of the selected expansion)

* image.encode(img):string - converts an image to bytestring(in scimg format)
* image.decode(string):img - converts bytestring to an image, from scimg format
* image.decodeBmp(string):img - converts bytestring to an image, from bmp format

* image.draw(img, display, number:posX[default:0], number:posY[default:0], number:gamelight(0-1)[default:1]) - 
draw the image on the monitor, transparency is supported, but if the transparency is greater than 0, the pixel will not be transparent
* image.drawForTicks(img, display, number:tick[default:40], number:posX[default:0], number:posY[default:0], number:gamelight(0-1)[default:1]):function_drawer -
draws an image image for a certain number of ticks (40 by default)
will return a function that needs to be called until it returns true (further call does not make sense)
note that one generated function can only be used 1 time
* image.get(img, x, y):smcolor
* image.set(img, x, y, smcolor)
* image.getSize(img):sizeX:sizeY
* image.fromCamera(img, camera, methodName, ...) - gets a piece of the image from the camera according to its settings
send the camera, method name, and arguments for the method (to set basecolor)
* image.fromCameraAll(img, camera, methodName, ...) - gets all the images from the camera entirely