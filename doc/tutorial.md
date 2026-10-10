# Tutorial

This tutorial walks through the basics: adding the library, decoding an image, inspecting and processing it,
and encoding the result. It ends with recipes for common tasks.

- [Setup](#setup)
- [Decode an image](#decode-an-image)
- [Inspect an image](#inspect-an-image)
- [Process an image](#process-an-image)
- [Encode and save](#encode-and-save)
- [Work with pixels](#work-with-pixels)
- [Run work in the background](#run-work-in-the-background)
- [Use the library on the web](#use-the-library-on-the-web)
- [Recipes](#recipes)

## Setup

Add the package:

```
dart pub add image
```

(or `flutter pub add image` in a Flutter project), then import it:

```dart
import 'package:image/image.dart' as img;
```

The examples here use the `img` prefix. It's optional, but it avoids name clashes, such as with Flutter's own
`Image` widget and `dart:ui`'s `Image`.

The library is pure Dart, so it works anywhere Dart runs: command-line apps, servers, Flutter (mobile, desktop
and web), and the browser. Functions that read or write files need `dart:io`; on the web, work with bytes instead.

## Decode an image

Decoding turns encoded file bytes (JPEG, PNG, ...) into an [Image](image_data.md). The decode functions
return `null` when they can't decode the data, so check the result. Some can also throw, usually an
`ImageException`: `decodeJpg` throws for data that isn't a JPEG, and corrupt or truncated files can make any
decoder throw. Catch exceptions when decoding files you don't control.

```dart
import 'dart:io';
import 'package:image/image.dart' as img;

Future<void> main() async {
  // From a file (dart:io only). The format is chosen from the file extension,
  // falling back to detecting it from the data.
  final image = await img.decodeImageFile('photo.jpg');
  if (image == null) {
    print('Could not decode photo.jpg');
    return;
  }

  // From bytes, when you know the format: the fastest option.
  final bytes = await File('photo.jpg').readAsBytes();
  final jpg = img.decodeJpg(bytes);

  // From bytes of an unknown format: each decoder is tried in turn.
  final any = img.decodeImage(bytes);

  // From bytes, choosing the decoder by a file name.
  final named = img.decodeNamedImage('photo.jpg', bytes);
}
```

There is a decoder for each format: `decodeJpg`, `decodePng`, `decodeGif`, `decodeWebP`, `decodeBmp`,
`decodeTiff`, `decodeTga`, `decodeIco`, `decodePsd`, `decodeExr`, `decodePnm` and `decodePvr`, each with a
`...File` version that reads a path. See [Image Formats](formats.md) for the formats and their options.

Two options are worth knowing about early:

```dart
// Decode a JPEG at 1/2, 1/4 or 1/8 size: much faster for thumbnails.
final preview = img.decodeJpg(bytes, scale: 4);
// Decode only the first frame of an animated GIF, PNG or WebP.
final firstFrame = img.decodeGif(gifBytes, frame: 0);
```

## Inspect an image

```dart
print(image.width); // Width in pixels.
print(image.height); // Height in pixels.
print(image.numChannels); // 3 for RGB, 4 for RGBA.
print(image.hasAlpha); // True if there is an alpha channel.
print(image.format); // The channel data type, such as Format.uint8.
print(image.hasPalette); // True for indexed images, such as most GIFs.
print(image.numFrames); // More than 1 for animations.
if (image.hasExif) {
  print(image.exif.imageIfd.orientation); // Camera orientation, if any.
}
```

Most images decode to 8-bit RGB or RGBA, but not all: GIFs decode to indexed images, 16-bit PNGs to `uint16`,
and EXR files to floating point. If your code expects a particular layout, [convert](image_data.md#converting-images)
the image:

```dart
final rgba = image.convert(format: img.Format.uint8, numChannels: 4);
```

## Process an image

Functions come in two styles:

- **Copy functions**, whose names mostly start with `copy` (`copyResize`, `copyCrop`, `copyRotate`, ...), return a
  new image and leave the source unchanged. `trim` and `bakeOrientation` also return a new image.
- **In-place functions**, including all [filters](filters.md) (`grayscale`, `gaussianBlur`, `adjustColor`, ...),
  [drawing functions](draw.md) and `flip`, modify the image you pass and return that same image.

```dart
// Resize to 800 pixels wide, keeping the aspect ratio. Returns a new image.
final resized = img.copyResize(image,
    width: 800, interpolation: img.Interpolation.linear);

// Crop a 400x300 region. Returns a new image.
final cropped = img.copyCrop(resized, x: 100, y: 50, width: 400, height: 300);

// Rotate 90 degrees. Returns a new image.
final rotated = img.copyRotate(cropped, angle: 90);

// Filters modify the image in place, and return it so calls can be chained.
img.adjustColor(rotated, contrast: 1.2, saturation: 1.1);
img.gaussianBlur(rotated, radius: 2);

// Draw on it, also in place.
img.drawString(rotated, 'Hello', font: img.arial24, x: 10, y: 10,
    color: img.ColorRgb8(255, 255, 255));
img.fillRect(rotated,
    x1: 10, y1: 50, x2: 110, y2: 80, color: img.ColorRgba8(255, 0, 0, 128));
```

To keep the original when using an in-place function, work on a copy: `img.grayscale(image.clone())`.

Photos from phones often store their rotation in EXIF data rather than rotating the pixels. `copyResize` applies
that orientation automatically; for other operations call `img.bakeOrientation(image)` first. See
[Transform Functions](transform.md) and [EXIF Data](exif.md).

## Encode and save

Encoders turn an Image back into file bytes:

```dart
final jpg = img.encodeJpg(image, quality: 85); // Uint8List
final png = img.encodePng(image);
final webp = img.encodeWebP(image, lossless: false, quality: 75);
final gif = img.encodeGif(image);
// Choose the encoder from a file name.
final bytes = img.encodeNamedImage('out.png', image);
```

With `dart:io` you can write the bytes yourself, or let the library do it:

```dart
await File('out.jpg').writeAsBytes(img.encodeJpg(image, quality: 85));
// Or, encoding by the file extension:
await img.encodeImageFile('out.png', image);
// Or with a specific encoder and its options:
await img.encodeJpgFile('out.jpg', image, quality: 85);
```

`encodeImageFile` and the `encode...File` functions return `false` if the file couldn't be written, including
on the web where there is no file system.

## Work with pixels

You can read and write pixels directly. An Image is iterable, giving a [Pixel](image_data.md#pixel-access) for each
position:

```dart
final image = img.Image(width: 256, height: 256); // 8-bit RGB, all black.
for (final pixel in image) {
  pixel
    ..r = pixel.x // Red increases to the right.
    ..g = pixel.y; // Green increases downward.
}
image.setPixelRgb(10, 10, 255, 255, 255); // Set one pixel to white.
final p = image.getPixel(10, 10);
print('${p.r}, ${p.g}, ${p.b}');
```

See [Image Data](image_data.md) for formats, channels, palettes and colors.

## Run work in the background

Decoding, processing and encoding large images can take a noticeable time. In an app, run that work off the main
isolate so the UI stays responsive. The [Command API](commands.md) can run a whole pipeline on a separate isolate:

```dart
Future<void> makeThumbnail() async {
  await (img.Command()
        ..decodeImageFile('photo.jpg')
        ..copyResize(width: 120)
        ..gaussianBlur(radius: 1)
        ..writeToFile('thumbnail.png'))
      .executeThread(); // Runs on a separate isolate where supported.
}
```

Or wrap direct calls in `Isolate.run` (Dart VM and Flutter native, not the web):

```dart
import 'dart:isolate';
import 'dart:typed_data';

Future<Uint8List> thumbnailBytes(Uint8List jpegBytes) => Isolate.run(() {
      final image = img.decodeJpg(jpegBytes, scale: 4)!;
      final thumb = img.copyResize(image, width: 200);
      return img.encodeJpg(thumb, quality: 85);
    });
```

See [Performance](performance.md) for more ways to make processing faster and use less memory.

## Use the library on the web

In the browser there is no file system, so use the byte-based functions (`decodeImage`, `encodePng`, ...), and get
bytes from a network request, a file input, or a canvas. The `...File` functions return `null` or `false` there,
and `Command.executeThread` runs on the main thread.

The examples below use [package:web](https://pub.dev/packages/web) (`dart pub add web`).

### Read an image from a canvas

```dart
import 'dart:js_interop';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:web/web.dart' as web;

img.Image imageFromCanvas(web.HTMLCanvasElement canvas) {
  final w = canvas.width;
  final h = canvas.height;
  final ctx = canvas.getContext('2d') as web.CanvasRenderingContext2D;
  final data = ctx.getImageData(0, 0, w, h).data.toDart; // RGBA bytes
  return img.Image.fromBytes(
      width: w, height: h, bytes: data.buffer, numChannels: 4);
}
```

### Draw an image onto a canvas

```dart
void drawImageOnCanvas(web.HTMLCanvasElement canvas, img.Image image) {
  // Canvas ImageData is 8-bit RGBA.
  final rgba = image.convert(format: img.Format.uint8, numChannels: 4);
  final bytes = Uint8ClampedList.fromList(rgba.toUint8List());
  final imageData = web.ImageData(bytes.toJS, rgba.width, rgba.height.toJS);
  canvas
    ..width = rgba.width
    ..height = rgba.height;
  (canvas.getContext('2d') as web.CanvasRenderingContext2D)
      .putImageData(imageData, 0, 0);
}
```

### Load an image over the network

```dart
import 'package:http/http.dart' as http;

Future<img.Image?> loadImage(String url) async {
  final response = await http.get(Uri.parse(url));
  return img.decodeImage(response.bodyBytes);
}
```

This works on every platform, not only the web.

## Recipes

### Load a JPEG, resize it, and save a thumbnail

```dart
import 'dart:io';
import 'package:image/image.dart' as img;

Future<void> main() async {
  final bytes = await File('test.jpg').readAsBytes();
  // Decoding at a reduced scale is faster when the result will be small.
  final image = img.decodeJpg(bytes, scale: 2);
  if (image == null) {
    return;
  }
  // Resize to 120 pixels wide, keeping the aspect ratio.
  final thumbnail = img.copyResize(image,
      width: 120, interpolation: img.Interpolation.average);
  await img.encodeJpgFile('thumbnail-test.jpg', thumbnail, quality: 85);
}
```

### Create an image, draw some text, and save it as a PNG

```dart
import 'package:image/image.dart' as img;

Future<void> main() async {
  await (img.Command()
        // An 8-bit RGB image.
        ..createImage(width: 256, height: 256)
        // Fill it with blue.
        ..fill(color: img.ColorRgb8(0, 0, 255))
        // Draw text with the built-in 24pt Arial font.
        ..drawString('Hello World', font: img.arial24, x: 0, y: 0)
        // Draw a red line.
        ..drawLine(
            x1: 0,
            y1: 0,
            x2: 256,
            y2: 256,
            color: img.ColorRgb8(255, 0, 0),
            thickness: 3)
        // Blur the image.
        ..gaussianBlur(radius: 10)
        // Save it as a PNG.
        ..writeToFile('test.png'))
      .execute();
}
```

### Use the grayscale of an image as its alpha channel

```dart
import 'package:image/image.dart' as img;

img.Image grayscaleAlpha(img.Image image) {
  // Convert to RGBA if the image doesn't already have an alpha channel.
  final rgba = image.convert(numChannels: 4);
  // Copy the luminance (brightness) of each pixel into its alpha channel.
  return img.remapColors(rgba, alpha: img.Channel.luminance);
}
```

### Save the frames of a GIF animation as PNG files

```dart
import 'package:image/image.dart' as img;

Future<void> main() async {
  final anim = await img.decodeGifFile('animated.gif');
  if (anim == null) {
    return;
  }
  // frames holds every frame; a still image has a single frame, itself.
  for (final frame in anim.frames) {
    await img.encodePngFile('animated_${frame.frameIndex}.png', frame);
  }
}
```

See [Animated Images](animation.md) for more.

### Trim a directory of images using the trim of the first image

```dart
import 'dart:io';
import 'package:image/image.dart' as img;

Future<void> main(List<String> args) async {
  final path = args[0];
  List<int>? trimRect;
  for (final f in Directory(path).listSync()) {
    if (f is! File) {
      continue;
    }
    final image = img.decodeImage(await f.readAsBytes());
    if (image == null) {
      continue;
    }
    // findTrim returns [x, y, width, height].
    trimRect ??= img.findTrim(image, mode: img.TrimMode.transparent);
    final trimmed = img.copyCrop(image,
        x: trimRect[0], y: trimRect[1], width: trimRect[2], height: trimRect[3]);
    final name = f.uri.pathSegments.last;
    await img.encodeImageFile('$path/trimmed-$name', trimmed);
  }
}
```

### Split an image into tiles

```dart
import 'package:image/image.dart' as img;

List<img.Image> splitImage(img.Image image, int columns, int rows) {
  final tileWidth = (image.width / columns).round();
  final tileHeight = (image.height / rows).round();
  final tiles = <img.Image>[];
  for (var y = 0; y < image.height; y += tileHeight) {
    for (var x = 0; x < image.width; x += tileWidth) {
      tiles.add(
          img.copyCrop(image, x: x, y: y, width: tileWidth, height: tileHeight));
    }
  }
  return tiles;
}
```

`copyCrop` clips the region to the image, so tiles on the right and bottom edges can be smaller.
