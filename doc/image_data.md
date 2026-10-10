# Image Data

The [Image](https://pub.dev/documentation/image/latest/image/Image-class.html) class stores a raster image: a
rectangle of pixels, plus metadata such as EXIF data, an ICC profile, text data, and animation frames. Images
are created directly, or [decoded](formats.md) from files such as JPEG or PNG.

An Image is made of a few cooperating classes:

| Class | Role |
|---|---|
| `Image` | The container: dimensions, pixel data, frames and metadata. |
| `ImageData` | The pixel storage (`image.data`), one subclass per [Format](#formats), such as `ImageDataUint8`. |
| `Palette` | Optional color table for indexed images (`image.palette`). |
| `Pixel` | A movable accessor (a "cursor") that reads and writes one pixel of an image. |
| `Color` | A standalone color value, such as `ColorRgb8(255, 0, 0)`. A `Pixel` is also a `Color`. |

Contents:

- [Creating images](#creating-images)
- [Image properties](#image-properties)
- [Formats](#formats)
- [Channels and channel order](#channels-and-channel-order)
- [Palettes](#palettes)
- [Colors](#colors)
- [Pixel access](#pixel-access)
- [Iterating over pixels](#iterating-over-pixels)
- [Converting images](#converting-images)
- [Raw bytes](#raw-bytes)
- [Frames](#frames)
- [Metadata](#metadata)

## Creating images

### Image()

```dart
// 8-bit RGB (the defaults: format uint8, 3 channels).
final rgb8 = Image(width: 256, height: 256);
// 8-bit RGBA.
final rgba8 = Image(width: 256, height: 256, numChannels: 4);
// 8-bit indexed image with an RGB palette.
final indexed = Image(width: 256, height: 256, withPalette: true);
// 8-bit indexed image with an RGBA palette.
final indexedRgba = Image(width: 256, height: 256, numChannels: 4, withPalette: true);
// 1-bit, 1-channel image.
final bitmap = Image(width: 256, height: 256, format: Format.uint1, numChannels: 1);
// 16-bit floating point RGBA image.
final hdr = Image(width: 256, height: 256, format: Format.float16, numChannels: 4);
```

New images are filled with zeros (black, and fully transparent if there is an alpha channel). Use
`image.clear(color)` to fill with a color.

| Parameter | Default | Meaning |
|---|---|---|
| `width`, `height` | required | Size in pixels. |
| `format` | `Format.uint8` | The data type of each channel. See [Formats](#formats). |
| `numChannels` | `3` | Channels per pixel (1-4). With a palette, the number of palette channels. |
| `withPalette` | `false` | Create a palette. Only used for formats that [support palettes](#palettes). |
| `paletteFormat` | `Format.uint8` | The format of the created palette's colors. |
| `palette` | `null` | Use this `Palette` instead of creating one. |
| `exif`, `iccp`, `textData` | `null` | Metadata to attach (the EXIF data is copied). |
| `loopCount`, `frameType`, `frameDuration`, `frameIndex` | `0`, `FrameType.sequence`, `0`, `0` | [Animation](animation.md) settings. |
| `backgroundColor` | `null` | Suggested background color of the canvas. |

### Image.fromBytes

`Image.fromBytes` creates an image from raw pixel data you already have, such as the bytes of a canvas,
a camera frame, or another library's bitmap. The bytes are copied into a new Image.

```dart
final image = Image.fromBytes(
    width: width,
    height: height,
    bytes: bgraBytes.buffer, // a ByteBuffer
    bytesOffset: bgraBytes.offsetInBytes, // where the pixels start in the buffer
    rowStride: sourceRowStride, // bytes per row in the source, including padding
    order: ChannelOrder.bgra); // channel order of the source
```

| Parameter | Default | Meaning |
|---|---|---|
| `bytes` | required | A `ByteBuffer`. For a `Uint8List`, pass `list.buffer` and `bytesOffset: list.offsetInBytes`. |
| `bytesOffset` | `0` | Byte offset into `bytes` where the pixel data starts. |
| `format` | `Format.uint8` | The data type of the source channels. |
| `numChannels` | from `order`, else `3` | Channels per pixel in the source. |
| `rowStride` | `width * numChannels * bytesPerChannel` | Bytes per row in the source. Set this when rows are padded or aligned. |
| `order` | RGB/RGBA | [Channel order](#channels-and-channel-order) of the source, such as `ChannelOrder.bgra`. The Image stores RGB(A), so the channels are rearranged. |

It also takes the palette, metadata and animation parameters of `Image()`.

### Copies

```dart
// A deep copy, including all frames and metadata.
final copy = Image.from(image);
// The same thing.
final copy2 = image.clone();
// Only the first frame.
final firstFrame = image.clone(noAnimation: true);
// Same size, format and metadata, but with zeroed pixels.
final blank = image.clone(noPixels: true);
// A blank image of a different size, with the format, palette and metadata of image.
final resizedBlank = Image.fromResized(image, width: 64, height: 64);
```

`Image.fromResized` doesn't scale the pixels; it creates empty storage for them. To scale an image use
[copyResize or resize](transform.md).

`Image.empty()` creates an Image with no pixel data (`isValid` is false). It's mainly useful as a placeholder.

## Image properties

| Property | Description |
|---|---|
| `width`, `height` | Size in pixels. |
| `format` | The [Format](#formats) of the channel values. |
| `formatType` | `FormatType.uint`, `FormatType.int` or `FormatType.float`. |
| `numChannels` | Channels per pixel (the palette's channels for indexed images). |
| `hasAlpha` | True for 2 and 4 channel images. |
| `hasPalette`, `palette`, `supportsPalette` | See [Palettes](#palettes). |
| `bitsPerChannel` | Bits per channel value, such as 8 for `uint8`. |
| `maxChannelValue` | Largest channel value: 255 for `uint8`, 1.0 for float formats (which can exceed it). For indexed images, the palette's maximum. |
| `maxIndexValue` | Largest palette index the format can store. |
| `isLdrFormat`, `isHdrFormat` | See [Formats](#formats). |
| `rowStride` | Bytes per row of pixel data. |
| `lengthInBytes` | Size of the pixel storage in bytes. |
| `buffer` | The `ByteBuffer` holding the pixels. |
| `isValid` | True if the image has pixel data and a non-zero size. |
| `frames`, `numFrames`, `hasAnimation` | See [Frames](#frames). |

`print(image)` shows a summary such as `Image(256, 256, uint8, 3)`.

## Formats

The [Format](https://pub.dev/documentation/image/latest/image/Format.html) enum is the data type of each
channel value.

| Format | Range | Storage | `isHdrFormat` |
|---|---|---|---|
| `uint1` | 0 - 1 | bit-packed | false |
| `uint2` | 0 - 3 | bit-packed | false |
| `uint4` | 0 - 15 | bit-packed | false |
| `uint8` | 0 - 255 | 1 byte | false |
| `uint16` | 0 - 65535 | 2 bytes | true |
| `uint32` | 0 - 4294967295 | 4 bytes | true |
| `int8` | -128 - 127 | 1 byte | true |
| `int16` | -32768 - 32767 | 2 bytes | true |
| `int32` | -2147483648 - 2147483647 | 4 bytes | true |
| `float16` | normally 0.0 - 1.0 | 2 bytes | true |
| `float32` | normally 0.0 - 1.0 | 4 bytes | true |
| `float64` | normally 0.0 - 1.0 | 8 bytes | true |

`isLdrFormat` is the opposite of `isHdrFormat`. Note that 16 and 32-bit integer formats count as "high dynamic
range" here; it means "more than 8 bits", not "floating point". Float images use 1.0 as their nominal maximum
but can store larger values; see [High Dynamic Range Images](hdr.md).

`FormatType` groups the formats into `uint`, `int` and `float`. The constant maps `formatToFormatType`,
`formatSize` (bytes per channel) and `formatMaxValue` are available if you need these values in code.

Decoders keep the image as close to the file's format as they can: a GIF decodes to an 8-bit indexed image,
a 16-bit PNG to `uint16`, a 1-bit BMP to `uint1`, and an EXR to a float format. Most of the library is fastest
with 8-bit RGB or RGBA images; see [Performance](performance.md).

### Bit-packed formats

`uint1`, `uint2` and `uint4` pack channel values into bytes. A 1-channel `uint1` image stores 8 pixels per byte;
a 4-channel `uint1` image stores 2 pixels per byte. Each row starts on a new byte, so the unused bits at the end
of a row are padding. `image.rowStride` gives the bytes per row for any format.

## Channels and channel order

| `numChannels` | Meaning |
|---|---|
| 1 | One value per pixel, stored in the red channel (also used for grayscale and palette indices). |
| 2 | Luminance (gray) and alpha. |
| 3 | Red, green, blue. |
| 4 | Red, green, blue, alpha. |

Notes:

- On a 2-channel image, `pixel.r`, `pixel.g` and `pixel.b` all return the gray value, and `pixel.a` is alpha.
- On a 1-channel image, the value is `pixel.r` (or `pixel[0]`); `pixel.g` and `pixel.b` read as 0 and
  `pixel.a` reads as the maximum value. Converting a 1-channel image to 3 or 4 channels with `convert` copies the
  value into red, green and blue.
- Reading a channel the pixel doesn't have returns 0 (or the maximum value for alpha); writing one is ignored.

Pixels are always stored in RGB or RGBA order. The [ChannelOrder](https://pub.dev/documentation/image/latest/image/ChannelOrder.html)
enum describes other orders used by external data:

| ChannelOrder | Channels |
|---|---|
| `rgba`, `bgra`, `abgr`, `argb` | 4 |
| `rgb`, `bgr` | 3 |
| `grayAlpha` | 2 |
| `red` | 1 |

`channelOrderLength[order]` gives the number of channels of an order. It's used in three places:

```dart
// Read BGRA data from an external source.
final image = Image.fromBytes(
    width: w, height: h, bytes: bgra.buffer, order: ChannelOrder.bgra);
// Get the pixels as BGRA bytes. This returns a copy when channels need to be
// rearranged or added; otherwise a view of the image data.
final out = image.getBytes(order: ChannelOrder.bgra);
// Rearrange the channels in place, without a copy. The image itself is still
// treated as RGBA afterwards, so only do this right before handing off the bytes.
image.remapChannels(ChannelOrder.bgra);
```

## Palettes

An indexed (palette) image stores one value per pixel: an index into its [Palette](https://pub.dev/documentation/image/latest/image/Palette-class.html).
GIF files, and many PNG, BMP and TIFF files, decode to indexed images.

```dart
final hasPalette = image.hasPalette; // True if the image has a palette.
final palette = image.palette; // The Palette, or null.
final supportsPalette = image.supportsPalette; // True for uint1, uint2, uint4, uint8 and uint16.
```

Only the unsigned integer formats `uint1` through `uint16` can have a palette. `Image(withPalette: true)` creates
a palette with 256 colors (65536 for `uint16`), with `numChannels` channels per color, in `paletteFormat`.
For indexed images, `image.numChannels` is the number of palette channels, not the 1 channel stored per pixel.

A palette can use any format and have 1-4 channels per color. The palette classes are `PaletteUint8`,
`PaletteUint16`, `PaletteUint32`, `PaletteInt8`, `PaletteInt16`, `PaletteInt32`, `PaletteFloat16`,
`PaletteFloat32` and `PaletteFloat64`, each created with `(numColors, numChannels)`.

```dart
final palette = PaletteUint8(16, 3); // 16 RGB colors.
palette.setRgb(0, 0, 0, 0); // color 0 is black
palette.setRgb(1, 255, 255, 255); // color 1 is white
final image = Image(width: 64, height: 64, format: Format.uint4, palette: palette);
image.setPixelIndex(10, 10, 1); // make pixel (10, 10) white

final numColors = palette.numColors; // 16
final numChannels = palette.numChannels; // 3
final format = palette.format; // Format.uint8
final red = palette.getRed(1); // 255 (also getGreen, getBlue, getAlpha)
final green = palette.get(1, 1); // channel 1 (green) of color 1
palette.set(1, 1, 128); // set channel 1 of color 1
palette.setRgba(2, 128, 42, 80, 255); // channels beyond numChannels are ignored
final bytes = palette.toUint8List(); // the raw palette data
```

Pixels of indexed images:

- `pixel.r`, `pixel.g`, `pixel.b` and `pixel.a` return the palette color of the pixel.
- `pixel.index` is the palette index. Setting `pixel.index` (or `pixel.r`) sets the index.
- `image.getPixelIndex(x, y)` and `image.setPixelIndex(x, y, i)` read and write indices directly.
- `image.setPixel(x, y, pixel)` copies the index when both images are indexed; otherwise it copies the color.

To convert an indexed image to RGB(A) use `convert`, and to reduce an RGB image to a palette use
[quantize](color_quantization.md) (which picks the best colors) or `convert(withPalette: true)` (which only works when the
image has at most as many colors as the palette holds). See [Converting images](#converting-images).

## Colors

[Color](https://pub.dev/documentation/image/latest/image/Color-class.html) is the base class of all color
values, and of `Pixel`. Functions that take a color, such as `fill` or `drawLine`, accept any Color and
convert it to the image's format.

| Class | Channel type |
|---|---|
| `ColorUint1`, `ColorUint2`, `ColorUint4` | bit-packed unsigned |
| `ColorUint8`, `ColorUint16`, `ColorUint32` | unsigned integer |
| `ColorInt8`, `ColorInt16`, `ColorInt32` | signed integer |
| `ColorFloat16`, `ColorFloat32`, `ColorFloat64` | floating point |
| `ColorRgb8`, `ColorRgba8` | shortcuts for 3 and 4 channel `ColorUint8` |
| `ConstColorRgb8`, `ConstColorRgba8`, `ConstColorRg8`, `ConstColorR8` | `const` 8-bit colors |

Each `Color*` class has the constructors `(numChannels)`, `.rgb(r, g, b)`, `.rgba(r, g, b, a)`, `.fromList(values)`
and `.from(other)`.

```dart
final red = ColorRgb8(255, 0, 0);
final translucentBlue = ColorRgba8(0, 0, 255, 128);
final hdrWhite = ColorFloat32.rgb(4.0, 4.0, 4.0);
final gray16 = ColorUint16.fromList([32768, 32768, 32768]);
// A color in the format and channel count of an image.
final c = image.getColor(255, 128, 0);
```

`ConstColor*` values can be used in `const` expressions, such as default parameters. They are read-only:
setting their channels has no effect.

```dart
const white = ConstColorRgb8(255, 255, 255);
```

Color members (these work on a `Pixel` too):

```dart
num r = c.r; // also g, b, a; all can be set
num rn = c.rNormalized; // r / maxChannelValue, in [0, 1]; also g, b, a, and can be set
num l = c.luminance; // brightness: 0.299 r + 0.587 g + 0.114 b
num ln = c.luminanceNormalized; // luminance in [0, 1]
num ch0 = c[0]; // channel by index
num v = c.getChannel(Channel.green); // channel by Channel enum
int n = c.length; // number of channels
num max = c.maxChannelValue; // 255 for 8-bit colors
Format f = c.format;
c.setRgb(10, 20, 30); // also setRgba, and set(otherColor)
final copy = c.clone();
final f32 = c.convert(format: Format.float32, numChannels: 4, alpha: 1.0);
bool same = c == ColorRgb8(10, 20, 30); // compares channel values
```

When `convert` adds an alpha channel, pass `alpha` explicitly; see the [note](#converting-images) below.

Normalized values make it easy to work across formats. Setting `rNormalized = 0.5` sets the red channel to 127 on
an 8-bit color and to 0.5 on a float color.

The [Channel](https://pub.dev/documentation/image/latest/image/Channel.html) enum names a color channel. It's
used by `getChannel`, by the `maskChannel` parameter of filters, and by `remapColors`:

| Channel | Value |
|---|---|
| `red`, `green`, `blue`, `alpha` | The color channel. |
| `luminance` | Not stored; the brightness computed from red, green and blue. |

Color utilities such as `rgbToHsl`, `hslToRgb`, `rgbToHsv`, `hsvToRgb`, `rgbToLab`, `labToRgb`, `cmykToRgb`,
`getLuminanceRgb`, `rgbaToUint32` and `uint32ToRed` are also exported; see the
[API reference](https://pub.dev/documentation/image/latest/image/image-library.html).

## Pixel access

### Reading pixels

```dart
final p = image.getPixel(x, y); // No bounds check: x and y must be inside the image.
final s = image.getPixelSafe(x, y); // Out of bounds returns Pixel.undefined, which reads 0.
final c = image.getPixelClamped(x, y); // Out of bounds coordinates are clamped to the edge.
// Sample between pixels; returns a Color.
final i = image.getPixelInterpolate(10.5, 20.25, interpolation: Interpolation.cubic);
```

`getPixelInterpolate` accepts an [Interpolation](https://pub.dev/documentation/image/latest/image/Interpolation.html):
`nearest`, `linear` (the default), `cubic`, or `average` (treated as `linear` here). `getPixelLinear` and
`getPixelCubic` call the two directly.

`image.isBoundsSafe(x, y)` tells you whether a coordinate is inside the image.

### Writing pixels

```dart
image.setPixelRgb(x, y, 255, 0, 0); // Set red, green, blue.
image.setPixelRgba(x, y, 255, 0, 0, 128); // Set red, green, blue, alpha.
image.setPixel(x, y, ColorRgb8(0, 255, 0)); // Set from any Color (or Pixel).
image.setPixelR(x, y, 7); // Set only the first channel (the index of indexed images).
image.clear(ColorRgb8(255, 255, 255)); // Set every pixel. With no color, sets all to 0.
```

Values are stored in the image's channel type, and channels the image doesn't have are ignored. `uint8` images
clamp values to 0-255, but other integer formats don't clamp (out-of-range values wrap around), so keep values
within the range of the format. Float formats store any value.

### The Pixel class

A [Pixel](https://pub.dev/documentation/image/latest/image/Pixel-class.html) reads and writes the image data at its
current position; it doesn't hold a copy of the color. Changing a channel changes the image.

```dart
final pixel = image.getPixel(0, 0);
pixel.r = 120; // Set the red channel.
pixel.g = 50;
pixel.b = 75;
pixel.a = 255; // Ignored if the image has no alpha channel.
pixel[1] = 60; // Set channel 1 (green).
pixel.setRgb(10, 20, 30);
pixel.rNormalized = 0.5; // 127 on an 8-bit image

print(pixel.length); // Number of channels.
for (final ch in pixel) {
  print(ch); // Each channel value.
}
print(pixel.maxChannelValue); // 255 for uint8.
print(pixel.x); // The x coordinate.
print(pixel.y); // The y coordinate.
print(pixel.xNormalized); // x / (width - 1), in [0, 1]
print(pixel.width); // Width of the image the pixel belongs to.
print(pixel.luminance); // Brightness of the pixel color.
print(pixel.index); // Palette index, or the red channel.

pixel.setPosition(5, 5); // Move the pixel to another coordinate.
pixel.setPositionNormalized(0.5, 0.5); // Move to the center.
```

Because a Pixel is a live view, keep a color with `image.getColor(p.r, p.g, p.b, p.a)` or a `ColorRgba8`
rather than holding on to the Pixel object.

### Reusing a Pixel

Each `getPixel` call allocates a new Pixel unless you pass one in to reuse. In loops this avoids creating
millions of short-lived objects:

```dart
final p = image.getPixel(0, 0);
for (var y = 0; y < image.height; ++y) {
  for (var x = 0; x < image.width; ++x) {
    image.getPixel(x, y, p); // Moves p instead of allocating a new Pixel.
    p.r = 255 - p.r;
  }
}
```

`getPixelSafe` and `getPixelClamped` accept a Pixel to reuse too. Iterating the image (below) reuses one Pixel
automatically.

## Iterating over pixels

An Image is an `Iterable<Pixel>`, so you can loop over all pixels of the first frame:

```dart
for (final pixel in image) {
  pixel
    ..r = pixel.x // Red follows the x coordinate.
    ..g = pixel.y // Green follows the y coordinate.
    ..a = pixel.maxChannelValue; // Make the pixel opaque.
}
```

The iterator moves one Pixel object along the image, so every element is the same object.
Don't store the elements (for example with `image.toList()`) expecting distinct pixels.

To visit a rectangle, use `getRange`, which returns an `Iterator<Pixel>`:

```dart
final range = image.getRange(x, y, width, height);
while (range.moveNext()) {
  final pixel = range.current;
  pixel.r = pixel.maxChannelValue - pixel.r; // Invert the red channel.
}
```

A Pixel is also an iterator, moving left to right and top to bottom:

```dart
// Make the last row transparent.
final pixel = image.getPixel(0, image.height - 1);
do {
  pixel.a = 0;
} while (pixel.moveNext());
```

For the other frames of an animation, iterate each image in `image.frames`.

## Converting images

`convert` returns a new image with a different format, number of channels, or palette. The original is unchanged,
and every frame is converted.

```dart
// Convert to uint8, keeping the number of channels.
final u8 = image.convert(format: Format.uint8);
// Convert to RGBA. A new alpha channel is set to maxChannelValue (opaque).
final rgba = image.convert(numChannels: 4);
// Convert to 8-bit RGBA, with a half-transparent alpha channel.
final u8rgba = image.convert(format: Format.uint8, numChannels: 4, alpha: 128);
// Convert an indexed image to RGB.
final rgb = indexedImage.convert(numChannels: 3);
// Convert to grayscale (1 channel).
final gray = image.convert(numChannels: 1);
// Convert to an indexed image. Only use this when the image has at most 256
// distinct colors (it throws otherwise); use quantize() for photos.
final indexed = image.convert(withPalette: true);
// Only convert the first frame.
final first = image.convert(numChannels: 4, noAnimation: true);
```

Notes:

- Values are scaled between formats: 8-bit 255 becomes 1.0 in a float format and 65535 in `uint16`.
  Converting a float (HDR) image to `uint8` clamps values above 1.0; use [hdrToLdr](hdr.md) to tone map instead.
- Converting to fewer channels uses the luminance for 1 channel and drops alpha where needed.
- If the format and channels already match, `convert` returns a copy.

You can convert a single color too:

```dart
final pixel = image.getPixel(0, 0);
final u8rgba = pixel.convert(format: Format.uint8, numChannels: 4, alpha: 255);
```

`Color.convert` currently sets an added alpha channel to 0 when `alpha` isn't given (unlike `Image.convert`),
so always pass `alpha` when converting a color to 4 channels.

## Raw bytes

```dart
ByteBuffer buffer = image.buffer; // The storage of the pixel data.
Uint8List bytes = image.toUint8List(); // A view of the pixel data, no copy.
Uint8List bgra = image.getBytes(order: ChannelOrder.bgra); // In a given channel order.
int stride = image.rowStride; // Bytes per row.
int size = image.lengthInBytes; // Bytes of storage.
```

- `toUint8List()` and `getBytes()` without an `order` return a view of the image's own memory: writing to it
  changes the image.
- `getBytes(order: ...)` returns a copy when the channels need to be rearranged, or added or removed (it converts
  the image first; `alpha` sets the value of an added alpha channel). It doesn't change the format, so a
  `uint16` image gives 2 bytes per channel; `convert(format: Format.uint8)` first if you need 8-bit bytes.
- The bytes are in the image's format: 8-bit images have one byte per channel, 16-bit images two bytes per
  channel (in the platform's byte order), and so on. Indexed images store indices, not colors, so convert them
  with `convert(numChannels: ...)` before reading color bytes.
- The storage can be larger than `height * rowStride`; for example, [resize](transform.md) works in place
  and keeps the original buffer. Use `Uint8List.sublistView(bytes, 0, image.height * image.rowStride)` when you
  need exactly the pixel rows.

To create an image from raw bytes, see [Image.fromBytes](#imagefrombytes).

## Frames

Formats such as GIF, PNG (APNG), WebP and TIFF can store several frames. Every Image has a `frames` list whose
first element is the image itself; the other frames are full-size images. See [Animated Images](animation.md).

```dart
final hasAnim = image.hasAnimation; // True if there is more than one frame.
final count = image.numFrames;
final loopCount = image.loopCount; // How many times to repeat; 0 means forever.
final type = image.frameType; // FrameType.animation, page, or sequence.
for (final frame in image.frames) {
  final index = frame.frameIndex; // Index in the frames list.
  final duration = frame.frameDuration; // Display time in milliseconds.
}
final frame2 = image.getFrame(1);
image.addFrame(Image(width: image.width, height: image.height));
```

## Metadata

```dart
// EXIF data. Reading `exif` creates an empty ExifData if there is none, so
// check hasExif first if you only want to look.
if (image.hasExif) {
  print(image.exif.imageIfd.orientation);
}
// Text key/value pairs, such as PNG tEXt chunks.
image.addTextData({'Author': 'Me'});
print(image.textData?['Author']);
// The ICC color profile, if the file had one.
final icc = image.iccProfile;
if (icc != null) {
  Uint8List profile = icc.decompressed();
}
// The suggested background color of an animation canvas.
final background = image.backgroundColor;
```

See [EXIF Data](exif.md) for working with EXIF.

Some formats store channels beyond RGBA, such as depth in EXR files. These are kept in `extraChannels`, a map of
named `ImageData`:

```dart
if (image.hasExtraChannel('Z')) {
  final depth = image.getExtraChannel('Z')!;
  print(depth.getPixel(0, 0).r);
}
image.setExtraChannel('mask', ImageDataUint8(image.width, image.height, 1));
image.setExtraChannel('mask', null); // remove it
```
