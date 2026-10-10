# Performance and Memory

This library is pure Dart: it runs everywhere Dart does, but it doesn't use native image codecs or the GPU.
Large photos take real time to decode and process and a lot of memory, especially on phones. This page collects
the techniques that make the biggest difference, based on how the library works.

- [Know what an image costs](#know-what-an-image-costs)
- [Decode only what you need](#decode-only-what-you-need)
- [Prefer 8-bit RGB and RGBA images](#prefer-8-bit-rgb-and-rgba-images)
- [Resize efficiently](#resize-efficiently)
- [Avoid unnecessary copies](#avoid-unnecessary-copies)
- [Access pixels efficiently](#access-pixels-efficiently)
- [Encode efficiently](#encode-efficiently)
- [Run heavy work off the main isolate](#run-heavy-work-off-the-main-isolate)
- [Measure in release mode](#measure-in-release-mode)
- [Benchmarks (for contributors)](#benchmarks-for-contributors)

## Know what an image costs

A decoded image takes `width * height * numChannels * bytesPerChannel` bytes, whatever the size of the file it
came from:

| Image | Memory |
|---|---|
| 12 MP (4000x3000) 8-bit RGB | about 36 MB |
| 12 MP 8-bit RGBA | about 48 MB |
| 12 MP 16-bit RGBA (`uint16`) | about 96 MB |
| 12 MP float32 RGBA | about 192 MB |
| 100-frame 500x500 RGBA animation | about 100 MB (every frame is a full image) |

Every copy (from a `copy...` function, `clone`, `convert`, or sending an image to an isolate) costs that much
again. On a phone, a few full-size copies of a photo can be the difference between working and being killed for
using too much memory.

## Decode only what you need

### Decode JPEGs at a reduced size

`decodeJpg` (and `decodeJpgFile` and `JpegDecoder`) can scale the image down by 2, 4 or 8 while decoding:

```dart
// A 4000x3000 photo decodes to 500x375.
final thumbnail = decodeJpg(bytes, scale: 8);
```

The result is the JPEG's size divided by `scale`, rounded up. The image never exists at full size, so this uses
much less memory than decoding and then resizing. At `scale: 8` the decoder also skips most of the work: in our
JIT benchmark on a synthetic 12 MP JPEG, `scale: 8` took about 70 ms against about 290 ms at full size. Scales 2
and 4 take only a little less time than a full decode, but still produce a much smaller image.

A good pattern for thumbnails is to decode at the largest scale that is still bigger than the size you need, then
finish with `copyResize`:

```dart
Image jpegThumbnail(Uint8List bytes, int targetWidth) {
  final info = JpegDecoder().startDecode(bytes); // reads the header only
  var scale = 1;
  if (info != null) {
    while (scale < 8 && info.width ~/ (scale * 2) >= targetWidth) {
      scale *= 2;
    }
  }
  final image = decodeJpg(bytes, scale: scale)!;
  return copyResize(image,
      width: targetWidth, interpolation: Interpolation.average);
}
```

### Baseline JPEGs use less memory than progressive ones

Baseline (non-progressive) JPEGs, the most common kind and the kind `encodeJpg` writes, are decoded a band of rows
at a time, so the decoder doesn't keep data for the whole image besides the output pixels. Progressive JPEGs need
the whole image's coefficients in memory until the last scan, so they use noticeably more memory to decode.
`scale: 8` reduces this too.

### Limit the size of images you accept

`decodeJpg(bytes, maxPixels: n)` throws an `ImageException` before allocating anything if the JPEG declares more
than `n` pixels. The default, `JpegDecoder.defaultMaxPixels`, is 2^28 (16384 x 16384). On a phone, a lower limit
protects you from images too big to handle:

```dart
JpegDecoder.defaultMaxPixels = 50000000; // also applies to decodeImage
```

### Decode a single animation frame

Decoding an animated GIF, PNG or WebP decodes every frame, each as a full-size image. If you only need one, ask
for it:

```dart
final first = decodeGif(bytes, frame: 0);
final firstAny = decodeImage(bytes, frame: 0);
```

### Use a specific decoder when you know the format

`decodeImage` doesn't know the format, so it asks each decoder in turn whether the data is valid
(JPEG, PNG, GIF, WebP, TIFF, PSD, EXR, BMP, PNM, TGA, ICO, then PVR) and uses the first that accepts it. That check
is cheap for JPEG, which is tried first, but adds work for formats later in the list. It also can't take decoder
options such as `scale`. When you know the format, call its decoder (`decodeJpg`, `decodePng`, ...) directly.
`decodeNamedImage` and `decodeImageFile` choose the decoder from the file extension, and only fall back to
detection if that fails.

To get the size of an image without decoding it, use a decoder's `startDecode`, which reads the header:

```dart
final info = PngDecoder().startDecode(bytes);
print('${info?.width} x ${info?.height}, ${info?.numFrames} frames');
```

## Prefer 8-bit RGB and RGBA images

The decoders, the JPEG, PNG, BMP, TGA and TIFF encoders, `copyResize` and `resize` (except nearest-neighbor
resizing, which is fast for most formats), and many filters (including `gaussianBlur`, `convolution`, `sobel`,
`edgeGlow`, `grayscale`, `gamma` and `adjustColor`) have fast paths that work directly on the bytes of `uint8`
images. Other formats (16-bit, float, bit-packed, and often indexed images) go through slower generic code that
reads and writes each pixel through a `Pixel` object. (`copyCrop`, `flip` and rotation by multiples of 90 degrees
copy bytes for any format whose pixels are a whole number of bytes.)

Most JPEG and PNG files decode to 8-bit RGB or RGBA already. If you have another kind, such as a 16-bit PNG or an
indexed GIF, and will run several operations on it, converting once can pay off:

```dart
if (image.format != Format.uint8 || image.hasPalette) {
  image = image.convert(
      format: Format.uint8, numChannels: image.hasAlpha ? 4 : 3);
}
```

Only do this when you don't need the extra precision, and note that converting costs a full pass and a copy.

## Resize efficiently

- `copyResize` returns a new image and keeps the original. If the image has an EXIF orientation (typical for
  phone photos), it applies the rotation while resizing, instead of first making a rotated full-size copy. Only
  call `bakeOrientation` yourself if you need the full-size image upright.
- `resize` resizes **in place** where it can (8-bit images without a palette), reusing the source image's
  memory instead of allocating a second image. Use it when you no longer need the original:

  ```dart
  image = resize(image, width: 1024); // Always use the returned image.
  ```

  The buffer keeps its original capacity, so `image.lengthInBytes` and `image.toUint8List()` can be larger than
  the resized pixels; see [Raw bytes](image_data.md#raw-bytes). If you only need a small copy and want to
  release the large buffer, use `copyResize` and drop the original instead.
- `Interpolation.nearest` (the default) is the fastest. `average` gives the best quality when shrinking a lot;
  `linear` and `cubic` are good for small changes in size.
- When the source is a JPEG, combine resizing with [decoding at a reduced size](#decode-jpegs-at-a-reduced-size).

## Avoid unnecessary copies

- Filters and drawing functions modify the image in place. Don't `clone()` before them unless you need the
  original.
- `convert` always returns a new image, even when nothing changes; check `format` and `numChannels` first.
- `toUint8List()`, `getBytes()` without an `order`, and `buffer` are views of the image's memory, not copies.
  `getBytes(order: ...)` copies only when the channels have to be rearranged.
- `Image.fromBytes` copies the bytes you give it.
- Decode one frame instead of a whole animation when you only need one.

## Access pixels efficiently

Per-pixel code in Dart is where most custom processing time goes.

- Iterate with `for (final p in image)` or reuse one `Pixel` with `image.getPixel(x, y, pixel)`. Calling
  `getPixel(x, y)` without a Pixel to reuse allocates a new object for every pixel.

  ```dart
  final p = image.getPixel(0, 0);
  for (var y = 0; y < image.height; ++y) {
    for (var x = 0; x < image.width; ++x) {
      image.getPixel(x, y, p);
      p.g = 0;
    }
  }
  ```

- For 8-bit images without a palette, working on the bytes directly is fastest. The channels of each pixel are
  stored together, row after row (`rowStride` bytes per row):

  ```dart
  void invertBytes(Image image) {
    final bytes = image.toUint8List();
    final channels = image.numChannels;
    final end = image.height * image.rowStride;
    for (var i = 0; i < end; i += channels) {
      bytes[i] = 255 - bytes[i]; // red
      if (channels >= 3) {
        bytes[i + 1] = 255 - bytes[i + 1]; // green
        bytes[i + 2] = 255 - bytes[i + 2]; // blue
      }
    }
  }
  ```

- Use the built-in filters where they fit; many have byte fast paths that are faster than a general per-pixel loop.

## Encode efficiently

- **PNG**: `encodePng(image, level: n)` takes a zlib level from 0 to 9 (default 6). Lower levels are faster and
  produce larger files. On native platforms (`dart:io`) the PNG encoder compresses rows as it goes using the
  platform's zlib, so it doesn't hold the whole uncompressed image data at once; on the web it collects the data
  and compresses it at the end. RGBA takes longer to encode than RGB, so drop an alpha channel you don't need.
- **JPEG**: `encodeJpg(image, quality: n)` defaults to `100`, which makes large files. Values from 75 to 90 are
  much smaller and usually look the same.
- **WebP**: `encodeWebP` is lossless by default. For photos use `lossless: false`; its `method` option (0-6)
  trades encoding time against size (see the [API docs](https://pub.dev/documentation/image/latest/image/encodeWebP.html)).
- **GIF**: GIF encoding quantizes colors, which is relatively slow. See
  [Color Quantization](color_quantization.md) for the options.

## Run heavy work off the main isolate

Decoding and processing a large image can take long enough to freeze a UI or stall a server's event loop. Run it on
another isolate:

```dart
import 'dart:isolate';

Future<Uint8List> processInBackground(Uint8List jpegBytes) =>
    Isolate.run(() {
      final image = decodeJpg(jpegBytes, scale: 2)!;
      final small = copyResize(image, width: 1024);
      grayscale(small);
      return encodeJpg(small, quality: 85);
    });
```

Or use the [Command API](commands.md), which does the same with `executeThread()`, `getImageThread()` or
`getBytesThread()`, and falls back to the main thread on the web:

```dart
Future<Uint8List?> processWithCommands(Uint8List jpegBytes) => (Command()
      ..decodeJpg(jpegBytes)
      ..copyResize(width: 1024)
      ..grayscale()
      ..encodeJpg(quality: 85))
    .getBytesThread();
```

Tips:

- Sending data **to** an isolate copies it; results come **back** without a copy. Send encoded bytes (small) rather
  than a decoded image (large), and do the whole job in one isolate call.
- Isolates run in parallel on multi-core devices, so a batch of images can be processed faster by spreading it
  over a few isolates. Each one needs memory for its own images, so keep the number small on phones.
- In Flutter, `compute` works on every platform (on the web it runs on the main thread); see [Flutter](flutter.md).
- `Isolate.run` isn't available on the web. Web apps can use web workers, or keep images small.

## Measure in release mode

Dart code runs much faster when compiled ahead of time than in a JIT debug session. Flutter debug builds are much
slower than profile and release builds, so measure image performance in profile or release mode. For command-line
tools, `dart compile exe` gives AOT performance.

## Benchmarks (for contributors)

The repository has benchmarks for decoding, encoding and processing:

```
dart run benchmark/benchmark.dart --list
dart run benchmark/benchmark.dart --filter=decode_jpeg,resize --size=2000x1500
```

Each benchmark runs in its own process and reports the minimum and median time and the peak memory. The default
image size is 12 MP (4000x3000), which is slow; `--size=2000x1500` is quicker. `--iterations=N` sets the number of
timed runs. For numbers closer to a Flutter release build, compile it first with
`dart compile exe benchmark/benchmark.dart -o build/benchmark.exe`.

For the web, run `benchmark/web_benchmark_test.dart` in a browser:

```
dart test -p chrome benchmark/web_benchmark_test.dart
dart test -p chrome -c dart2wasm benchmark/web_benchmark_test.dart
```
