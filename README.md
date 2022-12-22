# Dart Image Library (DIL)
[![Dart CI](https://github.com/brendan-duncan/image/actions/workflows/build.yaml/badge.svg?branch=4.0)](https://github.com/brendan-duncan/image/actions/workflows/build.yaml)
[![pub package](https://img.shields.io/pub/v/image.svg)](https://pub.dev/packages/image)

## NOTE
This is a work in progress major update for the Image library.

## Overview

A Dart library providing the ability to load, save and manipulate images in a variety of different file formats.

The library is written entirely in Dart and has no reliance on `dart:io`, so it can be used for command-line, Flutter, 
and web applications.

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
    pixel..r = pixel.x
    ..g = pixel.y;
  }
  final png = DIL.encodePng(image);
  await File('image.png').writeAsBytes(png);
}
```

An ImageCommand API lets you perform these functions either synchronously or asynchronously.
```dart
import 'package:image/image_io.dart' as DIL;
void main() async {
  final cmd = DIL.ImageCommand()
      ..createImage(256, 256)
      ..filter((image) {
        for (var pixel in image) {
          pixel..r = pixel.x
          ..g = pixel.y;
        }
      })
      ..encodePngFile('image.png');
  await cmd.executeAsync();
}
```

To asynchronously load an image file, resize it, and save it as a thumbnail: 
```dart
import 'package:image/image_io.dart' as DIL;

void main(List<String> args) async {
  final path = args.isNotEmpty ? args[0] : 'test.png';
  final cmd = DIL.ImageCommand()
    // Decode the image file at the given path
    ..decodeImageFile(path)
    // Resize the image to a width of 64 pixels and a height that maintains the aspect ratio of the original. 
    ..copyResize(width: 64)
    // Write the image to a PNG file (determined by the suffix of the file path). 
    ..writeToFile('thumbnail.png');
  // On platforms that support Isolates, execute the image commands asynchronously on an isolate thread.
  // Otherwise, the commands will be executed synchronously.
  await cmd.executeAsync();
}
```
