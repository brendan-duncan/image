# Dart Image Library
[![Dart CI](https://github.com/brendan-duncan/image/actions/workflows/build.yaml/badge.svg?branch=main)](https://github.com/brendan-duncan/image/actions/workflows/build.yaml)
[![pub package](https://img.shields.io/pub/v/image.svg)](https://pub.dev/packages/image)

## Overview

The Dart Image Library loads, saves and manipulates images in a variety of image file
[formats](https://github.com/brendan-duncan/image/blob/main/doc/formats.md).

It's written in pure Dart with no native dependencies, so it works everywhere Dart does: command-line
apps, servers, [Flutter](https://github.com/brendan-duncan/image/blob/main/doc/flutter.md) on every
platform, and the web.

Features include:

- Decoding and encoding many [image formats](https://github.com/brendan-duncan/image/blob/main/doc/formats.md),
  including [animated](https://github.com/brendan-duncan/image/blob/main/doc/animation.md) GIF, PNG and WebP.
- [Resizing, cropping, rotating and flipping](https://github.com/brendan-duncan/image/blob/main/doc/transform.md).
- Dozens of [filters](https://github.com/brendan-duncan/image/blob/main/doc/filters.md) for color
  adjustment, blurring, and effects, plus [color quantization and dithering](https://github.com/brendan-duncan/image/blob/main/doc/color_quantization.md).
- [Drawing](https://github.com/brendan-duncan/image/blob/main/doc/draw.md) shapes, lines,
  [text](https://github.com/brendan-duncan/image/blob/main/doc/fonts.md) and other images.
- Direct [pixel access](https://github.com/brendan-duncan/image/blob/main/doc/image_data.md) in 1 to 32-bit
  integer and 16 to 64-bit floating point formats, with optional palettes.
- [EXIF](https://github.com/brendan-duncan/image/blob/main/doc/exif.md) metadata, ICC profiles and
  [HDR](https://github.com/brendan-duncan/image/blob/main/doc/hdr.md) images.
- A [Command API](https://github.com/brendan-duncan/image/blob/main/doc/commands.md) for running image
  processing in a separate isolate.

## [Documentation](https://github.com/brendan-duncan/image/blob/main/doc/README.md)

- [Tutorial](https://github.com/brendan-duncan/image/blob/main/doc/tutorial.md)
- [Using the library with Flutter](https://github.com/brendan-duncan/image/blob/main/doc/flutter.md)
- [Performance and memory](https://github.com/brendan-duncan/image/blob/main/doc/performance.md)
- [API reference](https://pub.dev/documentation/image/latest)

## [Supported Image Formats](https://github.com/brendan-duncan/image/blob/main/doc/formats.md)

**Read/Write**

- JPEG
- PNG / Animated PNG
- GIF / Animated GIF
- WebP / Animated WebP (lossless and lossy)
- BMP
- TIFF
- TGA
- ICO
- PVR

**Read Only**

- PSD
- EXR
- PNM (PBM, PGM, PPM)

**Write Only**

- CUR

## Getting started

```
dart pub add image
```

```dart
import 'package:image/image.dart' as img;
```

## Examples

Create an image, set pixel values, and save it as a PNG:

```dart
import 'dart:io';
import 'package:image/image.dart' as img;

Future<void> main() async {
  // Create a 256x256 8-bit (default) RGB (default) image.
  final image = img.Image(width: 256, height: 256);
  // Iterate over its pixels.
  for (final pixel in image) {
    pixel
      // Set the red channel to the x position, creating a gradient.
      ..r = pixel.x
      // Set the green channel to the y position.
      ..g = pixel.y;
  }
  // Encode the image to the PNG format.
  final png = img.encodePng(image);
  // Write the PNG data to a file.
  await File('image.png').writeAsBytes(png);
}
```

Load a JPEG, make a thumbnail, and save it:

```dart
import 'dart:io';
import 'package:image/image.dart' as img;

Future<void> main() async {
  final bytes = await File('photo.jpg').readAsBytes();
  // Decode the JPEG. This returns null, or throws an ImageException, if the
  // data isn't a valid JPEG.
  final image = img.decodeJpg(bytes);
  if (image == null) {
    return;
  }
  // Resize to 120 pixels wide, keeping the aspect ratio. The EXIF orientation
  // of the photo is applied.
  final thumbnail = img.copyResize(image, width: 120);
  // Encode as a JPEG and save it.
  await File('thumbnail.jpg').writeAsBytes(img.encodeJpg(thumbnail, quality: 85));
}
```

Do the same work in a separate isolate with the Command API, so it doesn't block the main isolate:

```dart
import 'package:image/image.dart' as img;

Future<void> main(List<String> args) async {
  final path = args.isNotEmpty ? args[0] : 'test.png';
  final cmd = img.Command()
    // Decode the image file at the given path.
    ..decodeImageFile(path)
    // Resize the image to a width of 64 pixels, keeping the aspect ratio.
    ..copyResize(width: 64)
    // Write the image to a PNG file (the format comes from the file extension).
    ..writeToFile('thumbnail.png');
  // On platforms that support isolates, execute the commands on a separate
  // isolate. Otherwise (on the web), they run on the main thread.
  await cmd.executeThread();
}
```

See the [tutorial](https://github.com/brendan-duncan/image/blob/main/doc/tutorial.md) for more.
