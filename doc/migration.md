# Migrating from Version 3

Version 4 of the library was a rewrite of the image model. Version 3 stored every image as 8-bit RGBA
packed into 32-bit integers; version 4 supports many pixel formats and channel counts, uses `Color` and
`Pixel` objects instead of integer colors, keeps animation frames inside the `Image`, and uses named
parameters for most functions. This page maps the version 3 API to its replacement.

```dart
import 'package:image/image.dart' as img;
```

- [Quick reference](#quick-reference)
- [Images](#images)
- [Pixels and colors](#pixels-and-colors)
- [Animations](#animations)
- [HDR images](#hdr-images)
- [Decoding and encoding](#decoding-and-encoding)
- [Drawing, filters and transforms](#drawing-filters-and-transforms)

## Quick reference

| Version 3 | Version 4 |
|---|---|
| `Image(w, h)` | `Image(width: w, height: h, numChannels: 4)` |
| `Image.rgb(w, h)` | `Image(width: w, height: h)` |
| `Image.fromBytes(w, h, bytes, format: Format.bgra)` | `Image.fromBytes(width: w, height: h, bytes: bytes.buffer, numChannels: 4, order: ChannelOrder.bgra)` |
| `image.channels == Channels.rgba` | `image.numChannels == 4` or `image.hasAlpha` |
| `image.getBytes(format: Format.rgba)` | `image.getBytes(order: ChannelOrder.rgba)` |
| `image.fill(color)` | `image.clear(color)` or `fill(image, color: color)` |
| `image.getPixel(x, y)` (an `int`) | `image.getPixel(x, y)` (a `Pixel`) |
| `image.setPixelRgba(x, y, r, g, b)` | `image.setPixelRgb(x, y, r, g, b)` or `image.setPixelRgba(x, y, r, g, b, a)` |
| `getRed(c)`, `getGreen(c)`, `getBlue(c)`, `getAlpha(c)` | `c.r`, `c.g`, `c.b`, `c.a` |
| `getColor(r, g, b)`, `Color.fromRgb(r, g, b)` | `ColorRgb8(r, g, b)` |
| `getColor(r, g, b, a)`, `Color.fromRgba(r, g, b, a)` | `ColorRgba8(r, g, b, a)` |
| `getLuminance(c)` | `c.luminance` or `getLuminance(c)` |
| `Animation` | `Image` with `frames` |
| `HdrImage` | `Image(format: Format.float16)` or `Format.float32` |
| `hdrToImage(hdr, exposure: e)` | `hdrToLdr(hdr, exposure: e)` |
| `ICCProfileData`, `ICCPCompression` | `IccProfile`, `IccProfileCompression` |
| `decoder.decodeImage(bytes)` | `decoder.decode(bytes)` |
| `decoder.decodeAnimation(bytes)` | `decoder.decode(bytes)` |
| `encoder.encodeImage(image)`, `encoder.encodeAnimation(anim)` | `encoder.encode(image)` |
| `decodeGifAnimation`, `decodePngAnimation`, `decodeWebPAnimation`, `decodeTiffAnimation` | `decodeGif`, `decodePng`, `decodeWebP`, `decodeTiff` |
| `encodeGifAnimation`, `encodePngAnimation` | `encodeGif`, `encodePng` |
| `decodeAnimation(bytes)` | `decodeImage(bytes)` |
| `decodeNamedImage(bytes, name)` | `decodeNamedImage(path, bytes)` |
| `encodeNamedImage(image, name)` | `encodeNamedImage(path, image)` |
| `getDecoderForNamedImage(name)` | `findDecoderForNamedImage(name)` |
| `readJpg`, `writeJpg`, `readPng`, `writePng`, `readTga`, `writeTga` | `decodeJpg`, `encodeJpg`, `decodePng`, `encodePng`, `decodeTga`, `encodeTga` |
| `decodeExr(bytes, exposure: e)` | `hdrToLdr(decodeExr(bytes)!, exposure: e)` |
| `drawImage(dst, src)`, `copyInto(dst, src)` | `compositeImage(dst, src)` |
| `drawString(image, font, x, y, text, color: c)` | `drawString(image, text, font: font, x: x, y: y, color: c)` |
| `drawStringCentered(image, font, text)` | `drawString(image, text, font: font)` (omit `x` and `y` to center) |
| `drawLine(image, x1, y1, x2, y2, c)` | `drawLine(image, x1: x1, y1: y1, x2: x2, y2: y2, color: c)` |
| `drawRect`, `fillRect(image, x1, y1, x2, y2, c)` | `drawRect`, `fillRect(image, x1: x1, y1: y1, x2: x2, y2: y2, color: c)` |
| `drawCircle`, `fillCircle(image, x, y, r, c)` | `drawCircle`, `fillCircle(image, x: x, y: y, radius: r, color: c)` |
| `copyCrop(src, x, y, w, h)` | `copyCrop(src, x: x, y: y, width: w, height: h)` |
| `copyRotate(src, angle)` | `copyRotate(src, angle: angle)` |
| `copyResizeCropSquare(src, size)` | `copyResizeCropSquare(src, size: size)` |
| `flip(src, Flip.horizontal)` | `flip(src, direction: FlipDirection.horizontal)` |
| `gaussianBlur(src, radius)` | `gaussianBlur(src, radius: radius)` |
| `brightness(src, n)` | `colorOffset(src, red: n, green: n, blue: n)` |
| `contrast(src, c)` | `contrast(src, contrast: c)` |
| `arial_14`, `arial_24`, `arial_48` | `arial14`, `arial24`, `arial48` |

Unchanged: `copyResize` (same `width`, `height` and `interpolation` parameters, with the same
`Interpolation` names: `nearest`, `linear`, `cubic` and `average`), `ImageException`, `BitmapFont`,
`readFontZip`, and the `encodeJpg(quality:)` and `encodePng(level:)` options.

## Images

In version 3 every image was 8-bit RGBA stored as a `Uint32List`, and `channels` only told encoders whether
to write the alpha. In version 4 an image has a [format](image_data.md#formats) (the data type of each
channel, such as `Format.uint8` or `Format.float32`) and a number of channels (1 to 4), and stores only
what it needs. A new `Image` is 8-bit RGB unless you ask for more:

```dart
// Version 3
final image = Image(320, 240); // RGBA

// Version 4
final image = img.Image(width: 320, height: 240, numChannels: 4);
```

`Format` changed meaning. In version 3 it was the channel order of raw bytes (`Format.rgba`,
`Format.bgra`, ...); that's now [ChannelOrder](https://pub.dev/documentation/image/latest/image/ChannelOrder.html),
used by `Image.fromBytes` and `getBytes`. `Format` is now the data type. `Image.fromBytes` takes a
`ByteBuffer` and named parameters:

```dart
// Version 3
final image = Image.fromBytes(w, h, bytes, format: Format.bgra);
final rgba = image.getBytes(format: Format.rgba);

// Version 4
final image = img.Image.fromBytes(width: w, height: h, bytes: bytes.buffer,
    numChannels: 4, order: img.ChannelOrder.bgra);
final rgba = image.getBytes(order: img.ChannelOrder.rgba);
```

`image.data` is no longer a `Uint32List` of pixels. Use `image.toUint8List()` for the raw bytes, or the
pixel functions below. See [Image Data](image_data.md) for the full model.

## Pixels and colors

Version 3 colors were `int`s packed as `0xAABBGGRR`, read with functions such as `getRed`. Version 4 uses
[Color](https://pub.dev/documentation/image/latest/image/Color-class.html) objects, such as `ColorRgb8` and
`ColorRgba8`, and `getPixel` returns a
[Pixel](https://pub.dev/documentation/image/latest/image/Pixel-class.html), which is a `Color` you can also
write to:

```dart
// Version 3
final c = image.getPixel(x, y);
final red = getRed(c);
image.setPixel(x, y, getColor(255, 0, 0));
drawLine(image, 0, 0, 10, 10, 0xff0000ff); // red, as 0xAABBGGRR

// Version 4
final p = image.getPixel(x, y);
final red = p.r;
p.r = 255; // writes to the image
image.setPixel(x, y, img.ColorRgb8(255, 0, 0));
img.drawLine(image, x1: 0, y1: 0, x2: 10, y2: 10, color: img.ColorRgb8(255, 0, 0));
```

Channel values are `num`s in the range of the image's format: 0-255 for 8-bit images, 0-65535 for 16-bit,
and usually 0-1 for float images. Use `rNormalized` and friends for 0-1 values in any format.

To loop over all pixels, iterate the image instead of indexing `image.data`:

```dart
for (final p in image) {
  p.r = 255 - p.r;
}
```

## Animations

The `Animation` class is gone. An animated file decodes to an `Image` holding all of its frames in
`image.frames`; the first frame is the image itself. Each frame is the full size of the animation (version
3 frames could be smaller, with `xOffset` and `yOffset`). Frame timing moved from `duration` to
`frameDuration`, still in milliseconds, and `loopCount` is on the image:

```dart
// Version 3
final anim = decodeGifAnimation(bytes)!;
for (final frame in anim) { ... }
final gif = encodeGifAnimation(anim);

// Version 4
final image = img.decodeGif(bytes)!;
for (final frame in image.frames) { ... }
final gif = img.encodeGif(image);
```

Decoding an animation decodes every frame. Pass `frame: 0` to decode only the first. See
[Animated Images](animation.md).

## HDR images

`HdrImage` is gone. A high dynamic range image is an ordinary `Image` with a float format, and
`decodeExr` returns one instead of tone mapping it to 8 bits. Convert it to 8 bits with `hdrToLdr`
(formerly `hdrToImage`); its `exposure` works differently from version 3's, so check the result. See
[High Dynamic Range Images](hdr.md).

```dart
// Version 3
final ldr = decodeExr(bytes, exposure: 1.0);

// Version 4
final hdr = img.decodeExr(bytes)!; // A float image
final ldr = img.hdrToLdr(hdr, exposure: 0);
```

## Decoding and encoding

- The format functions keep their names (`decodeJpg`, `encodePng`, ...). The `readXxx` and `writeXxx`
  aliases and the `xxxAnimation` variants are gone; the plain functions handle animations.
- Decode functions take a `Uint8List` instead of `List<int>`, and encode functions return a `Uint8List`.
- `Decoder.decodeImage` and `decodeAnimation` became `decode(bytes, {int? frame})`, and
  `Encoder.encodeImage` and `encodeAnimation` became `encode(image, {bool singleFrame = false})`.
- `decodeNamedImage` and `encodeNamedImage` take the file name first.
- New: `decodeImageFile` and `encodeImageFile`, and an `xxxFile` version of each format function, read and
  write files directly. See [Image Formats](formats.md).

## Drawing, filters and transforms

Most functions now use named parameters, take `Color` objects instead of `int` colors, and process every
frame of an animation. The image is still the first positional argument. Many also gained new options,
such as `mask`, `blend` and `linearBlend`. See [Drawing Functions](draw.md),
[Image Processing](filters.md) and [Transform Functions](transform.md) for the current signatures.

`drawImage` and `copyInto` were replaced by `compositeImage`, which takes the parameters of both (`dstX`,
`dstY`, `dstW`, `dstH`, `srcX`, `srcY`, `srcW`, `srcH` and `center`), with a `BlendMode` for `blend` instead
of a `bool` (`blend: false` becomes `blend: BlendMode.direct`):

```dart
// Version 3
drawImage(background, overlay, dstX: 10, dstY: 10);

// Version 4
img.compositeImage(background, overlay, dstX: 10, dstY: 10);
```
