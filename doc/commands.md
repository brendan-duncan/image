# Commands and Async Execution

The [Command](https://pub.dev/documentation/image/latest/image/Command-class.html) API records a sequence of
image operations and runs them later, either on the current isolate or on a separate
[Isolate](https://dart.dev/language/isolates) so the work doesn't block your app.

```dart
import 'package:image/image.dart';

Future<void> main() async {
  final cmd = Command()
    ..decodeImageFile('photo.jpg')
    ..copyResize(width: 800)
    ..sepia(amount: 0.5)
    ..vignette()
    ..writeToFile('processed.png');
  // Nothing has run yet; the commands have only been recorded.

  await cmd.executeThread(); // Run everything on a separate isolate.
}
```

Contents:

- [Commands or direct functions?](#commands-or-direct-functions)
- [Building a command](#building-a-command)
- [Running a command](#running-a-command)
- [Running in an isolate](#running-in-an-isolate)
- [Getting results](#getting-results)
- [Combining images](#combining-images)
- [Custom operations](#custom-operations)
- [Running a command again](#running-a-command-again)
- [Available commands](#available-commands)

## Commands or direct functions?

Every command calls one of the library's ordinary functions; `..sepia()` runs `sepia(image)`. So you can always
write the same thing without commands:

```dart
final image = await decodeImageFile('photo.jpg');
if (image != null) {
  final resized = copyResize(image, width: 800);
  sepia(resized, amount: 0.5);
  vignette(resized);
  await encodeImageFile('processed.png', resized);
}
```

Use **commands** when:

- You want to run a whole pipeline (decode, process, encode, write) off the main isolate with one call,
  `executeThread()`, without writing isolate code yourself.
- You want to describe the work in one place and run it later, possibly more than once.

Use **direct functions** when:

- You need an option or function that has no command, such as `decodeJpg(scale:)`, `resize`, `findTrim`,
  `histogramEqualization`, `solarize`, or the `chroma` option of `encodeJpg`.
- You are already on a background isolate (for example inside `Isolate.run`), or the work is small.
- You want to inspect intermediate results or branch on them.

Both approaches produce the same images. To run direct calls in the background, wrap them in `Isolate.run`; see
[Performance](performance.md#run-heavy-work-off-the-main-isolate).

## Building a command

`Command()` creates an empty command. Each method call (`..decodePng(bytes)`, `..grayscale()`, ...) appends a
step whose input is the output of the step before it. Use Dart's cascade operator (`..`) to chain them.

```dart
final cmd = Command()
  ..decodePngFile('image.png') // Step 1: decode a file.
  ..vignette() // Step 2: uses the image from step 1.
  ..writeToFile('out.png'); // Step 3: uses the image from step 2.
```

A command chain usually starts with something that produces an image:

| Start with | Source |
|---|---|
| `image(Image)` | An Image you already have. |
| `createImage(width:, height:, ...)` | A new blank image (same parameters as `Image()`). |
| `decodeImage(bytes)`, `decodeNamedImage(path, bytes)` | Encoded bytes; the format is detected. |
| `decodeImageFile(path)` | A file (dart:io only); the format is detected. |
| `decodePng(bytes)`, `decodeJpgFile(path)`, ... | Bytes or a file of a known format. |

A chain can contain several images one after another; each decode or create step starts a new image:

```dart
await (Command()
      ..decodePngFile('image1.png')
      ..sepia()
      ..writeToFile('image1_out.png')
      ..decodeImageFile('image2.png')
      ..sketch()
      ..writeToFile('image2_out.png'))
    .execute();
```

## Running a command

| Method | Runs on | Returns |
|---|---|---|
| `execute()` | the current isolate | `Future<Command>` |
| `executeThread()` | a new isolate where supported | `Future<Command>` |
| `getImage()` | the current isolate | `Future<Image?>`: the final image |
| `getImageThread()` | a new isolate where supported | `Future<Image?>` |
| `getBytes()` | the current isolate | `Future<Uint8List?>`: the encoded bytes, if the chain ends with an encode step (optionally followed by `writeToFile`) |
| `getBytesThread()` | a new isolate where supported | `Future<Uint8List?>` |

`execute()` is `async` because some steps read or write files, but the image processing itself runs on the
current isolate and blocks it until it's done.

The `get*` methods run the command if it hasn't run yet, then return its result. Calling them on a command that
has already run just returns the result.

If a step throws (for example a decoder rejecting a corrupt file), the exception is thrown from `execute()`,
`executeThread()` or the `get*` method. If a decode step can't recognize the data it produces no image, later
steps do nothing, and `getImage()` returns null.

## Running in an isolate

`executeThread()`, `getImageThread()` and `getBytesThread()` run the command on a newly spawned isolate on
platforms that support `dart:io` isolates (the Dart VM, and Flutter on mobile and desktop):

- The command, including any `Image` given with `image()` and any byte data, is copied into the new isolate.
- The result image and bytes are sent back with `Isolate.exit`, which transfers them without another copy.
- Because the isolate works on a copy, an Image passed with `image()` is not modified.
- Exceptions thrown in the isolate are rethrown from the `*Thread` method.

On the web there are no isolates of this kind: the `*Thread` methods behave exactly like `execute()`,
`getImage()` and `getBytes()` and run on the main thread.

Spawning an isolate and copying the input costs a little time, so for very small images `execute()` can be
faster. The benefit is that your UI or server stays responsive while a large image is processed.

```dart
// Decode, resize and encode in the background, returning JPEG bytes.
Future<Uint8List?> makeThumbnail(Uint8List bytes) => (Command()
      ..decodeImage(bytes)
      ..copyResize(width: 200)
      ..encodeJpg(quality: 85))
    .getBytesThread();
```

### Images are modified in place by execute()

Most filters and drawing commands change their input image rather than copying it, just like the functions they
call. With `execute()` (or `executeThread()` on the web), an Image you pass with `image()` is changed:

```dart
final cmd = Command()
  ..image(original)
  ..invert();
await cmd.execute(); // `original` is now inverted.
```

Add `..copy()` before the first modifying step if you need to keep the original:

```dart
final cmd = Command()
  ..image(original)
  ..copy()
  ..invert();
final inverted = await cmd.getImage(); // `original` is unchanged.
```

## Getting results

After a command runs, its results are also available as properties:

```dart
final cmd = Command()
  ..decodeImage(bytes)
  ..grayscale()
  ..encodePng();
await cmd.execute();
final image = cmd.outputImage; // The final image.
final png = cmd.outputBytes; // The encoded PNG bytes.
```

`writeToFile(path)` writes the bytes from a preceding encode step if there is one; otherwise it encodes the image
in the format given by the file extension. On the web, where there is no file system, file steps do nothing:
file decodes produce no image and writes are skipped.

```dart
final cmd = Command()
  ..decodeImageFile('input.png')
  ..encodeJpg(quality: 80) // Encode with a specific quality...
  ..writeToFile('output.jpg'); // ...and write those bytes.
```

## Combining images

Some commands take another `Command` as an argument, such as `compositeImage`, the `mask` parameter of filters and
drawing commands, and `copyImageChannels(from:)`. That command is run first, and its output image is used.

```dart
final watermark = Command()
  ..decodePngFile('logo.png')
  ..copyResize(width: 100);

await (Command()
      ..decodeJpgFile('photo.jpg')
      ..compositeImage(watermark, dstX: 10, dstY: 10)
      ..writeToFile('watermarked.jpg'))
    .executeThread();
```

```dart
// Blur only where the mask image is bright.
final mask = Command()..decodePngFile('mask.png');
final blurred = Command()
  ..decodeJpgFile('photo.jpg')
  ..gaussianBlur(radius: 8, mask: mask, maskChannel: Channel.luminance);
```

## Custom operations

`filter` runs your own function on the image. The function receives each frame and returns either that frame
(after modifying it) or a new image to replace it. `forEachFrame` does the same thing; the name makes the intent
clearer for animations.

```dart
final image = await (Command()
      ..createImage(width: 256, height: 256)
      ..filter((image) {
        for (final pixel in image) {
          pixel
            ..r = pixel.x
            ..g = pixel.y;
        }
        return image;
      }))
    .getImage();
```

`addFrames(count, callback)` adds frames to the image; the callback is called with each new frame number and
returns the frame (or null to skip it).

When a command runs in an isolate, these functions run there too. They can be closures, but anything they
capture is copied to the isolate, so it must be something that can be sent between isolates (images, numbers,
strings and lists are fine; open files and sockets are not).

## Running a command again

A command runs its steps once. Calling `execute()` again returns the same results without redoing the work. If
you change something the command depends on, call `setDirty()` to make the next `execute()` run every step
again.

## Available commands

The commands have the same names and parameters as the functions documented in
[Image Processing](filters.md), [Transform Functions](transform.md), [Drawing Functions](draw.md) and
[Image Formats](formats.md), without the image argument. Where a function takes an `Image` (a source image or a
`mask`), the command takes a `Command` instead.

### Image commands

| Command | Description |
|---|---|
| `image(Image image)` | Use an existing image. |
| `createImage({required int width, required int height, Format format = Format.uint8, int numChannels = 3, bool withPalette = false, Format paletteFormat = Format.uint8, Palette? palette, ExifData? exif, IccProfile? iccp, Map<String, String>? textData})` | Create a new image. |
| `convert({int? numChannels, Format? format, num? alpha, bool withPalette = false})` | Convert the format or channels; see [Image Data](image_data.md#converting-images). |
| `copy()` | Continue with a copy of the image. |
| `addFrames(int count, AddFramesFunction callback)` | Add animation frames. `AddFramesFunction` is `Image? Function(int frameIndex)`. |
| `forEachFrame(FilterFunction callback)` | Run a function on each frame. `FilterFunction` is `Image Function(Image image)`. |
| `filter(FilterFunction filter)` | Run a function on the image (each frame). |

### Decoding and encoding commands

| Command | Description |
|---|---|
| `decodeImage(Uint8List data)` | Decode, detecting the format. |
| `decodeNamedImage(String path, Uint8List data)` | Decode, using the extension of `path` to pick the decoder. |
| `decodeImageFile(String path)` | Read and decode a file (dart:io only). |
| `writeToFile(String path)` | Write the encoded bytes, or encode by the file extension (dart:io only). |
| `decodeBmp(data)`, `decodeBmpFile(path)`, `encodeBmp()`, `encodeBmpFile(path)` | BMP. |
| `encodeCur()`, `encodeCurFile(path)` | CUR (encode only). |
| `decodeExr(data)`, `decodeExrFile(path)` | OpenEXR (decode only). |
| `decodeGif(data)`, `decodeGifFile(path)` | GIF. |
| `encodeGif({int samplingFactor = 10, DitherKernel dither = DitherKernel.floydSteinberg, DitherScanOrder? ditherScanOrder})`, `encodeGifFile(path, {...})` | GIF. The older `bool ditherSerpentine` is also accepted. |
| `decodeIco(data)`, `decodeIcoFile(path)`, `encodeIco()`, `encodeIcoFile(path)` | ICO. |
| `decodeJpg(data)`, `decodeJpgFile(path)` | JPEG, at full size. |
| `encodeJpg({int quality = 100})`, `encodeJpgFile(path, {int quality = 100})` | JPEG. |
| `decodePng(data)`, `decodePngFile(path)` | PNG. |
| `encodePng({int level = 6, PngFilter filter = PngFilter.paeth})`, `encodePngFile(path, {...})` | PNG. |
| `decodePsd(data)`, `decodePsdFile(path)` | Photoshop PSD (decode only). |
| `decodePvr(data)`, `decodePvrFile(path)`, `encodePvr()`, `encodePvrFile(path)` | PVR. |
| `decodeTga(data)`, `decodeTgaFile(path)`, `encodeTga()`, `encodeTgaFile(path)` | TGA. |
| `decodeTiff(data)`, `decodeTiffFile(path)`, `encodeTiff()`, `encodeTiffFile(path)` | TIFF. |
| `decodeWebP(data)`, `decodeWebPFile(path)`, `encodeWebP()`, `encodeWebPFile(path)` | WebP. The encode commands use the lossless defaults of `encodeWebP`. |

The format commands use the default options of the functions in [Image Formats](formats.md). For options the
commands don't have (JPEG `scale` and `chroma`, WebP lossy encoding, `singleFrame`, single-frame decoding with
`frame:`), call the functions directly or from a `filter` step.

### Drawing commands

See [Drawing Functions](draw.md).

| Command |
|---|
| `compositeImage(Command? src, {int? dstX, int? dstY, int? dstW, int? dstH, int? srcX, int? srcY, int? srcW, int? srcH, BlendMode blend = BlendMode.alpha, bool linearBlend = false, bool center = false, Command? mask, Channel maskChannel = Channel.luminance})` |
| `drawChar(String char, {required BitmapFont font, required int x, required int y, Color? color, BlendMode blend = BlendMode.alpha, Command? mask, Channel maskChannel = Channel.luminance})` |
| `drawCircle({required int x, required int y, required int radius, required Color color, bool antialias = false, BlendMode blend = BlendMode.alpha, Command? mask, Channel maskChannel = Channel.luminance})` |
| `drawLine({required int x1, required int y1, required int x2, required int y2, required Color color, bool antialias = false, num thickness = 1, BlendMode blend = BlendMode.alpha, Command? mask, Channel maskChannel = Channel.luminance})` |
| `drawPixel(int x, int y, Color color, {BlendMode blend = BlendMode.alpha, bool linearBlend = false, Command? mask, Channel maskChannel = Channel.luminance})` |
| `drawPolygon({required List<Point> vertices, required Color color, BlendMode blend = BlendMode.alpha, Command? mask, Channel maskChannel = Channel.luminance})` |
| `drawRect({required int x1, required int y1, required int x2, required int y2, required Color color, num radius = 0, num thickness = 1, BlendMode blend = BlendMode.alpha, Command? mask, Channel maskChannel = Channel.luminance})` |
| `drawString(String string, {required BitmapFont font, int? x, int? y, Color? color, bool wrap = false, bool rightJustify = false, BlendMode blend = BlendMode.alpha, Command? mask, Channel maskChannel = Channel.luminance})` |
| `fill({required Color color, Command? mask, Channel maskChannel = Channel.luminance})` |
| `fillCircle({required int x, required int y, required int radius, required Color color, bool antialias = false, BlendMode blend = BlendMode.alpha, Command? mask, Channel maskChannel = Channel.luminance})` |
| `fillFlood({required int x, required int y, required Color color, num threshold = 0.0, bool compareAlpha = false, Command? mask, Channel maskChannel = Channel.luminance})` |
| `fillPolygon({required List<Point> vertices, required Color color, BlendMode blend = BlendMode.alpha, Command? mask, Channel maskChannel = Channel.luminance})` |
| `fillRect({required int x1, required int y1, required int x2, required int y2, required Color color, num radius = 0, Command? mask, Channel maskChannel = Channel.luminance})` |

### Filter commands

See [Image Processing](filters.md). Every filter with a `mask` parameter also takes
`Channel maskChannel = Channel.luminance`; it's left out below for brevity.

| Command |
|---|
| `adjustColor({Color? blacks, Color? whites, Color? mids, num? contrast, num? saturation, num? brightness, num? gamma, num? exposure, num? hue, num amount = 1, Command? mask})` |
| `billboard({num grid = 10, num amount = 1, Command? mask})` |
| `bleachBypass({num amount = 1, Command? mask})` |
| `bulgeDistortion({int? centerX, int? centerY, num? radius, num scale = 0.5, Interpolation interpolation = Interpolation.nearest, Command? mask})` |
| `bumpToNormal({num strength = 2})` |
| `chromaticAberration({int shift = 5, Command? mask})` |
| `colorHalftone({num amount = 1, int? centerX, int? centerY, num angle = 180, num size = 5, Command? mask})` |
| `colorOffset({num red = 0, num green = 0, num blue = 0, num alpha = 0, Command? mask})` |
| `contrast({required num contrast, Command? mask})` |
| `convolution({required List<num> filter, num div = 1.0, num offset = 0, num amount = 1, Command? mask})` |
| `copyImageChannels({required Command? from, bool scaled = false, Channel? red, Channel? green, Channel? blue, Channel? alpha, Command? mask})` |
| `ditherImage({Quantizer? quantizer, DitherKernel kernel = DitherKernel.floydSteinberg, DitherScanOrder? scanOrder, double strength = 1.0})` (the older `bool serpentine` is also accepted) |
| `dotScreen({num angle = 180, num size = 5.75, int? centerX, int? centerY, num amount = 1, Command? mask})` |
| `dropShadow(int hShadow, int vShadow, int blur, {Color? shadowColor})` |
| `edgeGlow({num amount = 1, Command? mask})` |
| `emboss({num amount = 1, Command? mask})` |
| `gamma({required num gamma, Command? mask})` |
| `gaussianBlur({required int radius, Command? mask})` |
| `grayscale({num amount = 1, Command? mask})` |
| `hdrToLdr({num? exposure})` |
| `hexagonPixelate({int? centerX, int? centerY, int size = 5, num amount = 1, Command? mask})` |
| `invert({Command? mask})` |
| `luminanceThreshold({num threshold = 0.5, bool outputColor = false, num amount = 1, Command? mask})` |
| `monochrome({Color? color, num amount = 1, Command? mask})` |
| `noise(num sigma, {NoiseType type = NoiseType.gaussian, Random? random, Command? mask})` |
| `normalize({required num min, required num max, Command? mask})` |
| `pixelate({required int size, PixelateMode mode = PixelateMode.upperLeft, Command? mask})` |
| `quantize({int numberOfColors = 256, QuantizeMethod method = QuantizeMethod.neuralNet, DitherKernel dither = DitherKernel.none, DitherScanOrder? ditherScanOrder})` (the older `bool ditherSerpentine` is also accepted) |
| `reinhardTonemap({Command? mask})` |
| `remapColors({Channel red = Channel.red, Channel green = Channel.green, Channel blue = Channel.blue, Channel alpha = Channel.alpha})` |
| `scaleRgba({required Color scale, Command? mask})` |
| `separableConvolution({required SeparableKernel kernel, Command? mask})` |
| `sepia({num amount = 1, Command? mask})` |
| `sketch({num amount = 1, Command? mask})` |
| `smooth({required num weight, Command? mask})` |
| `sobel({num amount = 1, Command? mask})` |
| `stretchDistortion({int? centerX, int? centerY, Interpolation interpolation = Interpolation.nearest, Command? mask})` |
| `vignette({num start = 0.3, num end = 0.75, Color? color, num amount = 0.8, Command? mask})` |

Note that the `vignette` command's defaults (`end: 0.75`, `amount: 0.8`) differ from the `vignette` function's
(`end: 0.85`, `amount: 0.9`). Pass the values explicitly if you need identical results.

### Transform commands

See [Transform Functions](transform.md).

| Command |
|---|
| `bakeOrientation()` |
| `copyCrop({required int x, required int y, required int width, required int height, num radius = 0, bool antialias = true})` |
| `copyCropCircle({int? radius, int? centerX, int? centerY, bool antialias = true})` |
| `copyExpandCanvas({int? newWidth, int? newHeight, int? padding, ExpandCanvasPosition position = ExpandCanvasPosition.center, Color? backgroundColor, Image? toImage})` |
| `copyFlip({required FlipDirection direction})` |
| `copyRectify({required Point topLeft, required Point topRight, required Point bottomLeft, required Point bottomRight, Interpolation interpolation = Interpolation.nearest})` |
| `copyResize({int? width, int? height, bool? maintainAspect, Color? backgroundColor, Interpolation interpolation = Interpolation.nearest})` |
| `copyResizeCropSquare({required int size, num radius = 0, Interpolation interpolation = Interpolation.nearest, bool antialias = true})` |
| `copyRotate({required num angle, Interpolation interpolation = Interpolation.nearest})` |
| `flip({required FlipDirection direction})` |
| `trim({TrimMode mode = TrimMode.transparent, Trim sides = Trim.all})` |

The `trim` command defaults to `TrimMode.transparent`, while the `trim` function defaults to
`TrimMode.topLeftColor`.

### Functions without a command

These have no command method; call them directly, or from a `filter` step:
`resize`, `findTrim`, `flipVertical`, `flipHorizontal`, `flipHorizontalVertical`, `histogramEqualization`,
`histogramStretch`, `solarize`, and the format options listed above.

```dart
final cmd = Command()
  ..decodeImageFile('scan.png')
  ..filter((image) => histogramEqualization(image))
  ..writeToFile('scan_equalized.png');
```
