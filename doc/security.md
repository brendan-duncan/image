# Decoding Untrusted Images

Images uploaded by users or downloaded from the internet can be corrupt, or crafted to crash or exhaust
the program that decodes them. The decoders are written to fail safely on bad data, but a few habits make
decoding untrusted files much safer. This page is a checklist.

```dart
import 'package:image/image.dart' as img;
```

- [Handle errors and null results](#handle-errors-and-null-results)
- [Limit the image size](#limit-the-image-size)
- [Check the size before decoding](#check-the-size-before-decoding)
- [Decode only what you need](#decode-only-what-you-need)
- [Built-in protections](#built-in-protections)
- [Decode off the main isolate](#decode-off-the-main-isolate)

## Handle errors and null results

Decoders report bad data in two ways: they return null when the data isn't in the expected format, and
throw an [ImageException](https://pub.dev/documentation/image/latest/image/ImageException-class.html) when
it's corrupt or too large. Any other error raised while decoding, such as reading past the end of a
truncated file, is caught and rethrown as an `ImageException`, so that's the only exception you need to
catch. Handle both cases:

```dart
img.Image? decodeUpload(Uint8List bytes) {
  try {
    return img.decodeImage(bytes); // null if the format isn't recognized
  } on img.ImageException catch (e) {
    print('Rejected image: $e');
    return null;
  }
}
```

See [Errors](formats.md#errors) in Image Formats for which decode functions return null and which throw.

## Limit the image size

A file of a few hundred bytes can declare an image of billions of pixels. Every decoder has a `maxPixels`
limit on width × height, and throws an `ImageException` before allocating the pixels of a larger image. A
full decode of an animation, multi-page or multi-part file is limited to `maxPixels` across all of its
frames together. A value of 0 or less disables the limit.

The default is [`Decoder.defaultMaxPixels`](https://pub.dev/documentation/image/latest/image/Decoder/defaultMaxPixels.html),
2<sup>28</sup> (16384 × 16384), which allows a 1 GB RGBA image. That's often more than a server or phone
should accept, so set a limit that suits your app:

```dart
// Every decoder created without maxPixels, including the ones decodeImage uses.
img.Decoder.defaultMaxPixels = 40000000; // 40 megapixels

// Or one decoder.
final image = img.PngDecoder(maxPixels: 4096 * 4096).decode(bytes);
final photo = img.decodeJpg(bytes, maxPixels: 4096 * 4096);
```

Most decoders take `maxPixels` in their constructor. `GifDecoder` and `WebPDecoder` have a `maxPixels`
field instead: `img.GifDecoder()..maxPixels = n`. `decodeJpg` is the only decode function with a
`maxPixels` parameter.

## Check the size before decoding

You can also read just the header, check the dimensions, and only then decode. `startDecode` returns a
[DecodeInfo](https://pub.dev/documentation/image/latest/image/DecodeInfo-class.html) with the `width`,
`height` and `numFrames`, without decoding the pixels:

```dart
final decoder = img.findDecoderForData(bytes);
if (decoder == null) return null;
final info = decoder.startDecode(bytes);
if (info == null || info.width > 4096 || info.height > 4096) return null;
final image = decoder.decodeFrame(0);
```

Two exceptions:

- `ExrDecoder.startDecode` decodes the pixels too, so for EXR files rely on `maxPixels` instead.
- `PsdDecoder.startDecode` doesn't apply `maxPixels`; that check happens in `decodeFrame`.

## Decode only what you need

- **Animations**: decoding an animated GIF, PNG or WebP decodes every frame, each the full size of the
  image. If you only need a still image, pass `frame: 0` to `decodeImage`, `decodeGif`, `decodePng` or
  `decodeWebP`.
- **JPEG thumbnails**: `decodeJpg(bytes, scale: 2)` (or 4 or 8) decodes the image at a reduced size, which
  is faster and uses much less memory than decoding at full size and then resizing.
- **Known formats**: if you only accept certain formats, use those decoders rather than `decodeImage`, so
  other formats are rejected.

```dart
final still = img.decodeGif(bytes, frame: 0);
final preview = img.decodeJpg(bytes, scale: 4, maxPixels: 50000000);
```

## Built-in protections

Beyond `maxPixels`, the decoders guard against these malformed inputs:

- **Decompression bombs**: deflate-compressed TIFF and EXR data, ICC profiles (up to 16 MB), and the files
  in a bitmap font zip (up to 16 MB each) are only decompressed up to the size they should have.
- **Checksums**: zlib (Adler-32) checksums are verified for PNG, TIFF and EXR image data and ICC profiles.
- **JPEG scans**: each scan of a progressive JPEG is a pass over the whole image, so a JPEG with more than
  1000 scans throws an `ImageException` rather than taking a very long time to decode.
- **Looping IFDs**: in TIFF files and EXIF data, a chain of IFDs that loops back on itself is read once
  per IFD instead of forever. EXIF data is limited to 64 IFDs, and a TIFF file to 1024 pages.

## Decode off the main isolate

Even with limits, decoding a large image takes time. Run it on another isolate so it can't freeze your UI
or stall a server's event loop. Exceptions thrown on the other isolate are rethrown to the caller, so
handle them the same way:

```dart
import 'dart:isolate';

Future<img.Image?> decodeInBackground(Uint8List bytes) async {
  try {
    return await Isolate.run(() => img.decodeImage(bytes, frame: 0));
  } on img.ImageException {
    return null;
  }
}
```

With the [Command API](commands.md), `executeThread()`, `getImageThread()` and `getBytesThread()` run the
commands on another isolate (on the main thread on the web), and rethrow an exception thrown by the
commands. See [Run heavy work off the main isolate](performance.md#run-heavy-work-off-the-main-isolate)
for more.
