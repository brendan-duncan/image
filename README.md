# Dart Image Library (DIL)

[![Build Status](https://travis-ci.org/brendan-duncan/image.svg?branch=master)](https://travis-ci.org/brendan-duncan/image)

## NOTE
This is a work in progress major update for the Image library.

## Overview

A Dart library providing the ability to load, save and manipulate images in a variety of different file formats.

The library is written entirely in Dart and has no reliance on `dart:io`, so it can be used for both 
server and web applications.

### Performance Warning
Because this library is written entirely in Dart and is a not native executed library, its performance
will not be as fast as a native library.

### Supported Image Formats

**Read/Write**

- JPG
- PNG / Animated APNG
- GIF / Animated GIF
- BMP
- TIFF
- TGA
- PVRTC
- ICO

**Read Only**

- WebP / Animated WebP
- PSD
- EXR

**Write Only**

- CUR

## [Documentation](https://github.com/brendan-duncan/image/wiki)

## [API](https://pub.dev/documentation/image/latest/image/image-library.html)

## [Examples](https://github.com/brendan-duncan/image/wiki/Examples)

## [Format Decoding Functions](https://github.com/brendan-duncan/image/wiki#format-decoding-functions)

## Examples

Create an image, set pixel values, save it to a PNG.
```dart
import 'dart:io';
import 'package:image/image.dart' as DIL;
void main() async {
  final image = DIL.Image(256, 256);
  for (var pixel in image) {
    pixel.r = pixel.x;
    pixel.y = pixel.y;
  }
  final png = DIL.encodePng(image);
  await File('image.png').writeAsBytes(png);
}
```


Load an image asynchronously and resize it as a thumbnail. 
```dart
import 'package:image/image_io.dart' as DIL;

// Decode and resize an image asynchronously, saving it to a thumbnail file.
void main(List<String> args) async {
  final path = args.isNotEmpty ? args[0] : 'test.png';
  final image = await decodeImageFileAsync(path);
  final resized = await copyResizeAsync(image, width: 64);
  await File('thumbnail.png').writeAsBytes(DIL.encodePng(resized));
}
```
