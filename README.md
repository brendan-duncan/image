# image

[![Build Status](https://drone.io/github.com/brendan-duncan/image/status.png)](https://drone.io/github.com/brendan-duncan/image/latest)

##Overview

A Dart library providing the ability to load, save and manipulate images in a variety of different file formats.

The library has no reliance on `dart:io`, so it can be used for both server and
web applications. 

**Supported Image Formats:**

Read/Write:

- PNG / Animated APNG
- JPEG
- Targa
- GIF / Animated GIF

Read Only:

- WebP / Animated WebP
- TIFF
- Photoshop PSD
- OpenEXR


##[Documentation](https://github.com/brendan-duncan/image/wiki)

##[API](http://www.dartdocs.org/documentation/image/1.1.22/index.html#image/image)

##[Examples](https://github.com/brendan-duncan/image/wiki/Examples)

##[Format Decoding Functions](https://github.com/brendan-duncan/image/wiki#format-decoding-functions)

##Samples

Load an image, resize it, and save it as a png:

    import 'dart:io' as Io;
    import 'package:image/image.dart';
    void main() {
      // Read an image from file (webp in this case).
      // decodeImage will identify the format of the image and use the appropriate
      // decoder.
      Image image = decodeImage(new Io.File('test.webp').readAsBytesSync());

      // Resize the image to a 120x? thumbnail (maintaining the aspect ratio).
      Image thumbnail = copyResize(image, 120);
    
      // Save the thumbnail as a PNG.
      new Io.File('thumbnail.png')
            ..writeAsBytesSync(encodePng(thumbnail));
    }

