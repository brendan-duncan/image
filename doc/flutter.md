# Using the Library with Flutter

This library works in Flutter on every platform, because it's written in pure Dart. Flutter also has image
classes of its own, and the names overlap: this library's `Image` is a block of pixels in Dart memory, while
Flutter has an `Image` widget and a `dart:ui` `Image` that lives on the GPU. Import this library with a prefix to
keep them apart:

```dart
import 'dart:ui' as ui;
import 'package:image/image.dart' as img;
```

Contents:

- [When to use this library in Flutter](#when-to-use-this-library-in-flutter)
- [Getting image bytes](#getting-image-bytes)
- [Keep the UI responsive](#keep-the-ui-responsive)
- [Display an image](#display-an-image)
- [Convert a Flutter ui.Image to an Image](#convert-a-flutter-uiimage-to-an-image)
- [Camera frames](#camera-frames)
- [Memory tips](#memory-tips)

## When to use this library in Flutter

Flutter can already decode and display common formats using fast native code. Use this library when you need to
do something with the pixels: resize or crop before uploading, apply filters, draw, read or write EXIF, encode
to a file format, or handle formats Flutter can't, such as TIFF, TGA, PSD or EXR.

If you only need to show an image, Flutter's own `Image` widget (with `cacheWidth`/`cacheHeight` for smaller
decodes) is faster.

## Getting image bytes

All decoders take a `Uint8List` of the encoded file.

```dart
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;

// From an asset.
Future<img.Image?> decodeAsset(String path) async {
  final data = await rootBundle.load(path);
  final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  return img.decodeImage(bytes);
}

// From the network.
Future<img.Image?> decodeUrl(String url) async {
  final response = await http.get(Uri.parse(url));
  return img.decodeImage(response.bodyBytes);
}
```

If you know the format, use its decoder (`img.decodeJpg`, `img.decodePng`, ...) instead of `decodeImage`, which
has to identify the format first. For a JPEG that will be shown small, `img.decodeJpg(bytes, scale: 4)` decodes
it at a quarter of the size, much faster. See [Performance](performance.md).

## Keep the UI responsive

Decoding, processing and encoding a photo can take long enough to drop frames if done on the UI isolate. Move the
work to a background isolate:

```dart
import 'package:flutter/foundation.dart';

// compute() runs the function on a background isolate on mobile and desktop.
// On the web it runs on the main thread, since Flutter web has no isolates.
Future<Uint8List> makeThumbnail(Uint8List bytes) =>
    compute(_thumbnail, bytes);

Uint8List _thumbnail(Uint8List bytes) {
  final image = img.decodeImage(bytes)!;
  final thumb = img.copyResize(image, width: 300);
  return img.encodeJpg(thumb, quality: 85);
}
```

On mobile and desktop you can also use `Isolate.run` from `dart:isolate`, which accepts a closure; it isn't
available on the web.

The [Command API](commands.md) does the same thing for a pipeline of operations. `executeThread()`,
`getImageThread()` and `getBytesThread()` run the commands on a separate isolate on native platforms, and on the
main thread on the web:

```dart
Future<Uint8List?> makeThumbnailCmd(Uint8List bytes) => (img.Command()
      ..decodeImage(bytes)
      ..copyResize(width: 300)
      ..encodeJpg(quality: 85))
    .getBytesThread();
```

Passing data to an isolate copies it, while results come back without a copy (`Isolate.run`, and `compute` on
native platforms, return them with `Isolate.exit`). So send the
smallest input you can (usually the encoded bytes rather than a decoded `img.Image`), and do the whole
decode-process-encode job in one isolate call rather than one call per step.

## Display an image

### As raw pixels (fastest)

Convert to 8-bit RGBA and hand the pixels to Flutter. This skips encoding and decoding entirely:

```dart
Future<ui.Image> toUiImage(img.Image image) async {
  // Flutter wants 8-bit RGBA without a palette.
  if (image.format != img.Format.uint8 ||
      image.numChannels != 4 ||
      image.hasPalette) {
    image = image.convert(format: img.Format.uint8, numChannels: 4);
  }
  // Only the pixel rows, in case the buffer is larger than the image.
  final pixels =
      Uint8List.sublistView(image.toUint8List(), 0, image.height * image.rowStride);
  final buffer = await ui.ImmutableBuffer.fromUint8List(pixels);
  final descriptor = ui.ImageDescriptor.raw(buffer,
      width: image.width,
      height: image.height,
      pixelFormat: ui.PixelFormat.rgba8888);
  final codec = await descriptor.instantiateCodec();
  final frame = await codec.getNextFrame();
  codec.dispose();
  descriptor.dispose();
  buffer.dispose();
  return frame.image;
}
```

Show the result with `RawImage(image: uiImage)` or draw it on a `Canvas`, and call `uiImage.dispose()` when you
no longer need it. `ui.decodeImageFromPixels` is a callback-based alternative.

The `convert` call is needed when the image isn't already 8-bit RGBA, for example RGB JPEGs, indexed GIFs, and
16-bit PNGs. For a large image you can run the conversion in a background isolate along with the rest of your
processing.

### As encoded bytes (simplest)

Encode the image and use Flutter's `Image.memory` widget. This is convenient, but encoding (and Flutter's decoding)
costs extra time:

```dart
Widget buildPreview(img.Image image) =>
    Image.memory(img.encodePng(image, level: 1), gaplessPlayback: true);
```

A low PNG `level` makes encoding faster at the cost of a larger (in-memory) result.

## Convert a Flutter ui.Image to an Image

Read the pixels of a `ui.Image` (for example one you've drawn with a `Canvas`, or captured from a
`RepaintBoundary`) as unpremultiplied RGBA:

```dart
Future<img.Image?> fromUiImage(ui.Image uiImage) async {
  final data =
      await uiImage.toByteData(format: ui.ImageByteFormat.rawStraightRgba);
  if (data == null) {
    return null;
  }
  return img.Image.fromBytes(
      width: uiImage.width,
      height: uiImage.height,
      bytes: data.buffer,
      bytesOffset: data.offsetInBytes,
      numChannels: 4);
}
```

Use `rawStraightRgba` rather than `rawRgba`, which has premultiplied alpha.

You can use the same approach to decode with Flutter's native decoders and then process with this library:
`ui.instantiateImageCodec(bytes)`, then `codec.getNextFrame()`, then `fromUiImage(frame.image)`. Native decoding is
usually faster than this library's pure Dart decoders, but you lose metadata such as EXIF and the original format
details (everything becomes 8-bit RGBA).

## Camera frames

Raw frames from a camera plugin are already pixels, so create the image with `Image.fromBytes`, giving the row
stride and channel order. For example, a BGRA frame (as delivered by the
[camera](https://pub.dev/packages/camera) plugin on iOS):

```dart
img.Image fromBgraFrame(CameraImage frame) {
  final plane = frame.planes[0];
  return img.Image.fromBytes(
      width: frame.width,
      height: frame.height,
      bytes: plane.bytes.buffer,
      bytesOffset: plane.bytes.offsetInBytes,
      rowStride: plane.bytesPerRow,
      order: img.ChannelOrder.bgra);
}
```

YUV frames (the Android default) have to be converted to RGB first; the library doesn't read YUV.

## Memory tips

A decoded image takes `width * height * channels` bytes for 8-bit images: a 12 megapixel RGB photo is about 36 MB,
no matter how small the JPEG file was. On phones, this adds up quickly.

- Decode JPEGs at the size you need with `img.decodeJpg(bytes, scale: 2 | 4 | 8)`.
- For animations, decode one frame with `frame:` (for example `img.decodeGif(bytes, frame: 0)`) when you only need
  a still.
- Resize early, and drop references to the full-size image so it can be garbage collected.
- `img.resize` resizes in place where it can, avoiding a second full-size image; `copyResize` keeps the original.
- Don't keep the `img.Image`, its encoded bytes and a `ui.Image` of the same picture alive at the same time
  unless you need them. Dispose `ui.Image`s you create.
- `toUint8List()` is a view of the image's pixels, not a copy; `Image.fromBytes` always copies.

See [Performance](performance.md) for more.
