# Dart Image Library
[![Dart CI](https://github.com/brendan-duncan/image/actions/workflows/build.yaml/badge.svg?branch=4.0)](https://github.com/brendan-duncan/image/actions/workflows/build.yaml)
[![pub package](https://img.shields.io/pub/v/image.svg)](https://pub.dev/packages/image)

## Overview

The Dart Image Library provides the ability to load, save, and [manipulate](doc/filters.md) images
in a variety of [image file formats](doc/formats.md).

The library can be used with both dart:io and dart:html, for command-line, Flutter, and
web applications.

NOTE: 4.0 is a major revision from the previous verion of the library.

### [Supported Image Formats](doc/formats.md)

**Read/Write**

- JPG
- PNG / Animated APNG
- GIF / Animated GIF
- BMP
- TIFF
- TGA
- PVR
- ICO

**Read Only**

- WebP / Animated WebP
- PSD
- EXR

**Write Only**

- CUR

## [Documentation](doc/README.md)

## Examples

Create an image, set pixel values, save it to a PNG.
```dart
import 'dart:io';
import 'package:image/image.dart' as img;
void main() async {
  final image = img.Image(width: 256, height: 256);
  for (var pixel in image) {
    pixel..r = pixel.x
    ..g = pixel.y;
  }
  final png = img.encodePng(image);
  await File('image.png').writeAsBytes(png);
}
```

To asynchronously load an image file, resize it, and save it as a thumbnail: 
```dart
import 'package:image/image.dart' as img;

void main(List<String> args) async {
  final path = args.isNotEmpty ? args[0] : 'test.png';
  final cmd = img.Command()
    // Decode the image file at the given path
    ..decodeImageFile(path)
    // Resize the image to a width of 64 pixels and a height that maintains the aspect ratio of the original. 
    ..copyResize(width: 64)
    // Write the image to a PNG file (determined by the suffix of the file path). 
    ..writeToFile('thumbnail.png');
  // On platforms that support Isolates, execute the image commands asynchronously on an isolate thread.
  // Otherwise, the commands will be executed synchronously.
  await cmd.executeThread();
}
```
