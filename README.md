# image

[![Build Status](https://drone.io/github.com/brendan-duncan/image/status.png)](https://drone.io/github.com/brendan-duncan/image/latest)

##Overview

A Dart library to encode and decode various image formats.

The library has no reliance on `dart:io`, so it can be used for both server and
web applications. The image library currently supports the following 
formats:

- PNG
- JPG
- TGA

Work in progress:
- WebP (decoding of lossless format)

##[Documentation](https://github.com/brendan-duncan/image/wiki)

##Samples

Load a jpeg, resize it, and save it as a png:

    import 'dart:io' as Io;
    import 'package:image/image.dart';
    void main() {
      // Read a jpeg image from file.
      Image image = readJpg(new Io.File('res/cat-eye04.jpg').readAsBytesSync());

      // Resize the image to a 120x? thumbnail (maintaining the aspect ratio).
      Image thumbnail = copyResize(image, 120);
    
      // Save the thumbnail as a PNG.
      new Io.File('out/thumbnail-cat-eye04.png')
            ..createSync(recursive: true)
            ..writeAsBytesSync(writePng(thumbnail));
    }


