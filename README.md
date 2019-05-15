# image

[![Build Status](https://travis-ci.org/brendan-duncan/image.svg?branch=master)](https://travis-ci.org/brendan-duncan/image)

## Overview

A Dart library providing the ability to load, save and manipulate images in a variety of different file formats.

The library has no reliance on `dart:io`, so it can be used for both server and
web applications. 

**Supported Image Formats:**

Read/Write:

- PNG / Animated APNG
- JPEG
- Targa
- GIF / Animated GIF
- PVR(PVRTC)

Read Only:

- WebP / Animated WebP
- TIFF
- Photoshop PSD
- OpenEXR


## [Documentation](https://github.com/brendan-duncan/image/wiki)

## [API](https://pub.dev/documentation/image/latest/image/image-library.html)

## [Examples](https://github.com/brendan-duncan/image/wiki/Examples)

## [Format Decoding Functions](https://github.com/brendan-duncan/image/wiki#format-decoding-functions)

## Samples

Load an image, resize it, and save it as a png:

    import 'dart:io';
    import 'package:image/image.dart';
    void main() {
      // Read an image from file (webp in this case).
      // decodeImage will identify the format of the image and use the appropriate
      // decoder.
      Image image = decodeImage(File('test.webp').readAsBytesSync());

      // Resize the image to a 120x? thumbnail (maintaining the aspect ratio).
      Image thumbnail = copyResize(image, width: 120);
    
      // Save the thumbnail as a PNG.
      File('thumbnail.png')..writeAsBytesSync(encodePng(thumbnail));
    }

