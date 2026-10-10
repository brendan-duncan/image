# Image File Formats

The Dart Image Library decodes and encodes many image file formats, all in pure Dart. Decoding produces
an [Image](image_data.md), and encoding turns an `Image` back into file bytes.

- [Supported formats](#supported-formats)
- [Decoding images](#decoding-images)
- [Encoding images](#encoding-images)
- [Format details and options](#format-details-and-options)
- [Decoder and Encoder classes](#decoder-and-encoder-classes)
- [Memory and performance](#memory-and-performance)

## Supported Formats

| Format | Extensions | Decode | Encode | Notes |
|---|---|---|---|---|
| [JPEG](#jpeg-decoding-encoding) | .jpg, .jpeg | Yes | Yes | Baseline and progressive decoding; scaled (thumbnail) decoding; baseline encoding |
| [PNG](#png-decoding-encoding) | .png | Yes | Yes | All bit depths, palette, 16-bit; animated APNG |
| [GIF](#gif-decoding-encoding) | .gif | Yes | Yes | Animated GIF |
| [WebP](#webp-decoding-encoding) | .webp | Yes | Yes | Lossless and lossy; animated WebP |
| [TIFF](#tiff-decoding-encoding) | .tif, .tiff | Yes | Yes | Multi-page; float and 16-bit decoding; uncompressed 8-bit encoding |
| [BMP](#bmp-decoding-encoding) | .bmp | Yes | Yes | |
| [TGA](#tga-decoding-encoding) | .tga | Yes | Yes | |
| [ICO](#ico-and-cur-decoding-encoding) | .ico | Yes | Yes | Multiple sizes in one file |
| [CUR](#ico-and-cur-decoding-encoding) | .cur | No | Yes | Windows cursors |
| [PVR](#pvr-decoding-encoding) | .pvr | Yes | Yes | PowerVR textures; PVRTC 4bpp encoding |
| [PSD](#photoshop-psd-decoding-only) | .psd | Yes | No | Flattened image, or the individual layers |
| [OpenEXR](#openexr-decoding-only) | .exr | Yes | No | High dynamic range (float) images |
| [PNM](#pnm-decoding-only) | .pnm, .pbm, .pgm, .ppm | Yes | No | PBM, PGM and PPM |

## Decoding Images

### Decoding a file of unknown format

```dart
Image? decodeImage(Uint8List data, {int? frame});
```

`decodeImage` finds the format by testing the data against each decoder in turn, then decodes it with the
first one that accepts it. It returns null if no decoder recognizes the data. Testing every decoder makes it
slower than calling a specific decoder, so use a format-specific function when you know the format.

If you know the file name, the extension picks the decoder. If there's no decoder for the extension,
`decodeNamedImage` falls back to `decodeImage`.

```dart
Image? decodeNamedImage(String path, Uint8List data, {int? frame});
```

On platforms with `dart:io`, you can decode straight from a file. `decodeImageFile` uses the extension
first, and if that decoder fails or the extension is unknown, it tries every decoder. On the web it returns
null.

```dart
Future<Image?> decodeImageFile(String path, {int? frame});
```

```dart
import 'dart:io';
import 'package:image/image.dart' as img;

Future<void> main() async {
  // From a file path (dart:io platforms only).
  final image = await img.decodeImageFile('photo.jpg');

  // From bytes you already have, such as a network response.
  final bytes = File('photo.png').readAsBytesSync();
  final image2 = img.decodePng(bytes); // Faster than img.decodeImage(bytes).
  print('${image?.width}x${image?.height}, ${image2?.width}x${image2?.height}');
}
```

### Animated and multi-frame files

For files with more than one frame (animated GIF, APNG and WebP, multi-page TIFF, ICO files holding several
sizes), the decoders decode **every frame** by default. The returned `Image` is the first frame, and the
others are in `image.frames`. Each frame of an animation is a full image the size of the canvas, so a long
animation can take a lot of memory. See [Animated Images](animation.md).

To decode only one frame, pass its index as `frame`. This saves the memory and time of decoding the other
frames:

```dart
// Only the first frame, e.g. to make a thumbnail of an animated GIF.
final first = img.decodeGif(bytes, frame: 0);
```

A frame decoded on its own is the frame as stored in the file. Formats that store animation frames as
partial updates (GIF, APNG, WebP) may give you a smaller rectangle that isn't composited onto the earlier
frames; see [Decoding one frame at a time](animation.md#decoding-one-frame-at-a-time).

### Errors

The decode functions return null when the data isn't in the expected format. Corrupt or unsupported files
may also throw an `ImageException`, for example when a PNG chunk fails its checksum or a JPEG is larger than
the decoder's [`maxPixels`](#jpeg-decoding-encoding) limit. Wrap decoding of untrusted files in a `try`
block.

## Encoding Images

Each format with an encoder has an `encodeXxx` function that returns the file bytes, and an
`encodeXxxFile` function that writes them to a file. You can also let the file extension choose the format:

```dart
Uint8List? encodeNamedImage(String path, Image image);

Future<bool> encodeImageFile(String path, Image image);
```

`encodeNamedImage` returns null if no encoder matches the extension. `encodeImageFile` and the
`encodeXxxFile` functions return false if the file couldn't be written, and always return false on
platforms without `dart:io` (the web). The extension-based functions use each encoder's default options;
call the format-specific function or encoder class to pass options.

```dart
final image = img.Image(width: 256, height: 256);
img.fill(image, color: img.ColorRgb8(255, 128, 0));

final png = img.encodePng(image); // Uint8List
await img.encodeImageFile('orange.webp', image); // Format from the extension.
await img.encodeJpgFile('orange.jpg', image, quality: 85);
```

If the image has more than one frame, the encoders for formats that support animation (GIF, PNG, WebP)
write all frames, and ICO writes each frame as a separate icon size. Pass `singleFrame: true` to write only
the image itself (the first frame). Other formats always write a single frame.

Encoders convert the image to what the format can store. For example, JPEG has no alpha channel, so
transparent pixels are blended over the image's `backgroundColor` (white if it has none), and most formats
store 8 bits per channel, so 16-bit and float images are converted to 8 bits. PNG can store 16-bit images
as they are. See [High Dynamic Range Images](hdr.md).

## Format Details and Options

Every function in this section is listed with its full signature. The functions that read or write files
need `dart:io`; on the web, the `decodeXxxFile` functions return null and the `encodeXxxFile` functions
return false.

### JPEG: decoding, encoding

```dart
Image? decodeJpg(Uint8List bytes, {int? maxPixels, int scale = 1});

Future<Image?> decodeJpgFile(String path, {int? maxPixels, int scale = 1});

Uint8List encodeJpg(Image image, {int quality = 100, JpegChroma chroma = JpegChroma.yuv444});

Future<bool> encodeJpgFile(String path, Image image,
    {int quality = 100, JpegChroma chroma = JpegChroma.yuv444});
```

Decoding options, also available on `JpegDecoder({int? maxPixels, int scale = 1})`:

| Option | Default | Description |
|---|---|---|
| `scale` | 1 | Decode the image scaled down by 1, 2, 4 or 8. The result is the JPEG's size divided by `scale`, rounded up. Scaled decoding skips most of the work and memory, so it's the fastest way to make a thumbnail. Other values throw an `ArgumentError`. |
| `maxPixels` | `JpegDecoder.defaultMaxPixels` | The largest width × height (of the full-size image) that will be decoded. Larger images throw an `ImageException` before any pixel memory is allocated. A value of 0 or less disables the limit. |

`JpegDecoder.defaultMaxPixels` is a static setting, 2<sup>28</sup> (16384 × 16384) by default. It's used by
every JPEG decoder created without `maxPixels`, including the ones `decodeImage` and `decodeImageFile` use.
It protects against small, malicious files that declare huge dimensions.

```dart
// A thumbnail at 1/8 of the size: much faster and smaller than a full decode.
final thumb = img.decodeJpg(bytes, scale: 8);

// Allow larger images for every JPEG decode in the app.
img.JpegDecoder.defaultMaxPixels = 1 << 30;
```

Other decoding behavior:

- JPEGs always decode to an RGB uint8 image (grayscale and CMYK JPEGs are converted).
- The EXIF orientation is applied while decoding: the pixels are rotated and flipped to be upright, and the
  `Orientation` tag is removed from `image.exif`. You don't need `bakeOrientation` for JPEGs decoded by this
  library. See [EXIF Data](exif.md).
- The EXIF data and ICC profile are kept, in `image.exif` and `image.iccProfile`.
- Baseline JPEGs are decoded a band of rows at a time, so the decoder doesn't hold the coefficients of the
  whole image. This takes much less memory than progressive JPEGs, which need all of their coefficients until
  the last scan.

Encoding options, also on `JpegEncoder({int quality = 100})` and its
`encode(image, chroma: ...)` method:

| Option | Default | Description |
|---|---|---|
| `quality` | 100 | 1 (smallest, worst) to 100 (largest, best). 75 to 90 is typical for photos. |
| `chroma` | `JpegChroma.yuv444` | `yuv444` keeps full color resolution. `yuv420` stores color at half the width and height, which makes files smaller with little visible difference in photos. |

The encoder writes baseline JPEGs. Alpha is blended over `image.backgroundColor`, or white if that's null.
The image's EXIF data and ICC profile are written to the file.

To read or replace the EXIF data of a JPEG file without decoding or re-encoding its pixels:

```dart
ExifData? decodeJpgExif(Uint8List jpeg);

Uint8List? injectJpgExif(Uint8List jpeg, ExifData exif);
```

See [EXIF Data](exif.md#reading-and-writing-exif-without-decoding-pixels).

### PNG: decoding, encoding

```dart
Image? decodePng(Uint8List bytes, {int? frame});

Future<Image?> decodePngFile(String path);

Uint8List encodePng(Image image,
    {bool singleFrame = false,
    int level = 6,
    PngFilter filter = PngFilter.paeth,
    PngCicpData? cicpData});

Future<bool> encodePngFile(String path, Image image,
    {bool singleFrame = false, int level = 6, PngFilter filter = PngFilter.paeth});
```

PNG files decode to an image in the file's own format: 1, 2, 4 and 8-bit images use the matching uint
format, 16-bit images are `Format.uint16`, and indexed images keep their palette. Interlaced PNGs and
animated PNGs (APNG) are supported. The decoder keeps the ICC profile in `image.iccProfile` and the
`tEXt` text chunks in `image.textData` (compressed `zTXt` and `iTXt` chunks aren't read). Other
metadata is available from [`PngDecoder.info`](#decoder-and-encoder-classes) (a `PngInfo`): `gamma`, `pixelDimensions` (pHYs),
`cicpData` (cICP), `bits`, `colorType`, and the APNG `frames` and `repeat` count.

Encoding options. `level`, `filter`, `cicpData` and `pixelDimensions` are also `PngEncoder` constructor
arguments, and `singleFrame` is an argument of its `encode` method:

| Option | Default | Description |
|---|---|---|
| `level` | 6 | zlib compression level, 0 (none, fastest) to 9 (smallest, slowest). |
| `filter` | `PngFilter.paeth` | The row filter applied before compression: `none`, `sub`, `up`, `average` or `paeth`. `paeth` usually compresses photos and gradients best; `none` can be better for palette images and flat graphics. |
| `singleFrame` | false | Write only the first frame of an animated image. Otherwise animated images are written as APNG. |
| `cicpData` | null | Not on `encodePngFile`. Writes a cICP chunk, marking the color space (for example Display P3 or BT.2020 PQ). See [`PngCicpData`](https://pub.dev/documentation/image/latest/image/PngCicpData-class.html). |
| `pixelDimensions` | null | `PngEncoder` only. Writes a pHYs chunk with the physical pixel size, e.g. `PngPhysicalPixelDimensions.dpi(300)`. |

The encoder writes the image's bit depth and channels: palette images as indexed PNGs, 1, 2 or 3 channels
as gray, gray + alpha or RGB, and 4 channels as RGBA. 16-bit images are written as 16-bit PNGs. Float,
32-bit and signed-integer images are converted to 8 bits. It also writes `image.iccProfile` (iCCP) and
`image.textData` (tEXt chunks). EXIF data is not written to PNG files, and isn't read from them.

```dart
final image = img.decodePng(bytes)!;

// Text metadata.
image.addTextData({'Author': 'Jane', 'Description': 'A test image'});

// 300 DPI, best compression, and a Display P3 color space tag.
final encoder = img.PngEncoder(
    level: 9,
    pixelDimensions: img.PngPhysicalPixelDimensions.dpi(300),
    cicpData: const img.PngCicpData(
        colorPrimaries: 12,
        transferCharacteristics: 13,
        matrixCoefficients: 0,
        videoFullRangeFlag: 1));
final png = encoder.encode(image);
```

### GIF: decoding, encoding

```dart
Image? decodeGif(Uint8List bytes, {int? frame});

Future<Image?> decodeGifFile(String path, {int? frame});

Uint8List encodeGif(Image image,
    {bool singleFrame = false,
    int repeat = 0,
    int samplingFactor = 10,
    DitherKernel dither = DitherKernel.floydSteinberg,
    bool ditherSerpentine = false, // Deprecated: use ditherScanOrder.
    DitherScanOrder? ditherScanOrder});

Future<bool> encodeGifFile(String path, Image image,
    {bool singleFrame = false,
    int repeat = 0,
    int samplingFactor = 10,
    DitherKernel dither = DitherKernel.floydSteinberg,
    bool ditherSerpentine = false,
    DitherScanOrder? ditherScanOrder});
```

GIFs decode to palette images: one channel of palette indices, with the GIF's color table as the palette.
Animated GIFs decode to full-canvas frames with the frame delays converted to milliseconds in
`frameDuration`, and the loop count in `loopCount`. Use `image.convert(numChannels: 4)` to get RGBA pixels.

GIF stores at most 256 colors per frame. When a frame isn't already a palette image, the encoder reduces
its colors with a quantizer, then dithers it (see [Color Quantization](color_quantization.md)). A palette
image is written with its own palette, which must have no more than 256 colors. A palette color with an
alpha of 0 is written as the transparent color.

The `GifEncoder` class has the full set of options:

| `GifEncoder` option | Default | Description |
|---|---|---|
| `quantizerType` | `QuantizerType.neural` | How colors are reduced: `neural` (NeuQuant, best quality), `octree` (faster), or `binary` (black and white). |
| `numColors` | 256 | The number of palette colors the `neural` and `octree` quantizers produce. |
| `samplingFactor` | 10 | NeuQuant sampling: 1 is the best quality and slowest, larger values are faster. If your frames have fewer than 256 colors anyway, a large value speeds things up. |
| `dither` | `DitherKernel.floydSteinberg` | The dither kernel: `none`, `floydSteinberg`, `falseFloydSteinberg`, `jarvisJudiceNinke`, `stucki`, `burkes`, `atkinson`, or the ordered `bayer2x2`, `bayer4x4`, `bayer8x8`. |
| `ditherScanOrder` | null (raster) | The pixel order of the error-diffusion kernels: `DitherScanOrder.raster`, `serpentine` or `zigzag`. |
| `ditherStrength` | 1.0 | Scales the Bayer kernels' dither offset. Ignored by the error-diffusion kernels. |
| `delay` | 80 | Frame delay in 1/100 seconds, used for frames added without a duration (including a single-frame image). |
| `repeat` | 0 | Loop count written to the file, 0 for forever. When encoding an animated `Image`, its `loopCount` is used instead. |
| `dispose` | 2 | The disposal method written for every frame: 0 none, 1 do not dispose, 2 restore to background, 3 restore to previous. |
| `ditherSerpentine` | false | Deprecated; use `ditherScanOrder: DitherScanOrder.serpentine`. |

`encodeGif` passes `samplingFactor`, `dither` and the scan order on to the encoder. Its `repeat` argument
currently isn't passed on and has no effect; for animations, set `image.loopCount`, or use `GifEncoder`.

```dart
// Fewer colors and ordered dithering: a smaller file with a retro look.
final gif = img.GifEncoder(
        numColors: 32,
        quantizerType: img.QuantizerType.octree,
        dither: img.DitherKernel.bayer4x4)
    .encode(image);
```

### WebP: decoding, encoding

```dart
Image? decodeWebP(Uint8List bytes, {int? frame});

Future<Image?> decodeWebPFile(String path, {int? frame});

Uint8List encodeWebP(Image image,
    {bool singleFrame = false,
    bool exact = true,
    bool lossless = true,
    int quality = 75,
    int method = 4,
    int alphaQuality = 100});

Future<bool> encodeWebPFile(String path, Image image,
    {bool singleFrame = false,
    bool exact = true,
    bool lossless = true,
    int quality = 75,
    int method = 4,
    int alphaQuality = 100});
```

The decoder reads lossless, lossy and animated WebP files, with their EXIF data and ICC profile. Animated
files decode to full-canvas frames with `frameDuration` and `loopCount` set.

The encoder writes lossless (VP8L) or lossy (VP8) WebP, plus animation, the ICC profile and EXIF data when
the image has them. The same options are on `WebPEncoder`:

| Option | Default | Description |
|---|---|---|
| `lossless` | true | Lossless reproduces the image exactly, typically 20-30% smaller than PNG. Pass `false` for lossy coding, which is several times smaller and is how WebP replaces JPEG. |
| `quality` | 75 | Lossy only. 0 to 100: how much detail may be discarded. The scale doesn't match JPEG's. Above about 90 the file grows steeply for little visible gain. |
| `method` | 4 | Lossy only. 0 to 6: encoding effort. 0-1 are about four times faster and 20% larger; 6 is about 5% smaller than 4 and takes twice as long. |
| `alphaQuality` | 100 | Lossy only. 0 to 100: how exactly the alpha channel is kept. Below 100 the alpha is reduced to fewer levels, which helps soft edges and gradient masks. |
| `exact` | true | Keep the color of fully transparent pixels. Setting it to false lets the encoder replace that invisible color, saving 15-20% on images with large transparent areas (`cwebp` does this unless given `-exact`). |
| `singleFrame` | false | Write only the first frame of an animated image. |

Encoding is lossless by default, so `quality`, `method` and `alphaQuality` do nothing until you pass
`lossless: false`. An image with more than one frame is written as an animation unless `singleFrame` is
true, and every frame has to fit inside the first frame's size.

```dart
// Photos and screenshots: lossy, like JPEG.
final webp = img.encodeWebP(image, lossless: false, quality: 75, method: 6);
```

### TIFF: decoding, encoding

```dart
Image? decodeTiff(Uint8List bytes, {int? frame});

Future<Image?> decodeTiffFile(String path, {int? frame});

Uint8List encodeTiff(Image image, {bool singleFrame = false});

Future<bool> encodeTiffFile(String path, Image image, {bool singleFrame = false});
```

The decoder reads a wide range of TIFF files, including bilevel, palette, 16 and 32-bit integer and 16, 32
and 64-bit float images, which decode to the matching [format](image_data.md#formats). Multi-page TIFFs
decode to one frame per page, with `frameType` set to `FrameType.page`. The TIFF tags are in `image.exif`.

The encoder writes a single uncompressed page (the first frame) with 8 bits per channel: 16-bit, float and
signed-integer images are converted to 8 bits first. The image's `exif.imageIfd` tags are copied into the
file.

### BMP: decoding, encoding

```dart
Image? decodeBmp(Uint8List bytes);

Future<Image?> decodeBmpFile(String path);

Uint8List encodeBmp(Image image);

Future<bool> encodeBmpFile(String path, Image image);
```

`BmpDecoder({bool forceRgba = false})` can decode to RGBA even when the file has no alpha. The encoder
picks the bit depth from the image's format and channels, from 1-bit palette images up to 32-bit RGBA.

### TGA: decoding, encoding

```dart
Image? decodeTga(Uint8List bytes, {int? frame});

Future<Image?> decodeTgaFile(String path);

Uint8List encodeTga(Image image);

Future<bool> encodeTgaFile(String path, Image image);
```

The encoder writes uncompressed 24-bit RGB, or 32-bit RGBA if the image has alpha.

### ICO and CUR: decoding, encoding

```dart
Image? decodeIco(Uint8List bytes, {int? frame});

Future<Image?> decodeIcoFile(String path, {int? frame});

Uint8List encodeIco(Image image, {bool singleFrame = false});

Future<bool> encodeIcoFile(String path, Image image, {bool singleFrame = false});

Uint8List encodeCur(Image image, {bool singleFrame = false});

Future<bool> encodeCurFile(String path, Image image, {bool singleFrame = false});
```

An ICO file holds the same icon at several sizes. `decodeIco` decodes them all as the frames of the
returned image (frames may have different sizes); pass `frame` to get one size, or use
`IcoDecoder().decodeImageLargest(bytes)` to get the biggest. Each frame of the image you encode is
written as one icon size, PNG compressed. Icons can be at most 256 × 256.

```dart
final source = img.decodePng(bytes)!;
// An .ico with 16, 32, 48 and 256 pixel icons.
final sizes = [16, 32, 48, 256]
    .map((s) => img.copyResize(source, width: s, height: s))
    .toList();
final ico = img.IcoEncoder().encodeImages(sizes);
```

CUR files are icons with a hot spot, the pixel that is the cursor's click point. `encodeCur` writes each
frame as a cursor image with its hot spot at 0, 0 (the top-left corner).

### PVR: decoding, encoding

```dart
Image? decodePvr(Uint8List bytes, {int? frame});

Future<Image?> decodePvrFile(String path, {int? frame});

Uint8List encodePvr(Image image, {bool singleFrame = false});

Future<bool> encodePvrFile(String path, Image image, {bool singleFrame = false});
```

PowerVR texture files. The decoder reads PVR v2 and v3 files and Apple's PVRTC files, with PVRTC and
uncompressed pixel formats. The encoder writes PVRTC 4 bits per pixel compressed textures, RGB or RGBA
depending on the image's channels; `PvrEncoder(format: ...)` takes a
[`PvrFormat`](https://pub.dev/documentation/image/latest/image/PvrFormat.html). PVRTC images must be
square, with a power-of-two size.

### Photoshop PSD: decoding only

```dart
Image? decodePsd(Uint8List bytes);

Future<Image?> decodePsdFile(String path);
```

`decodePsd` returns the flattened image: the composite stored in the file, or the layers blended together if
there is none. For the layers themselves, use `PsdDecoder().decodePsd(bytes)`, which returns a `PsdImage`
with a `layers` list. Each `PsdLayer` has a `name`, position (`left`, `top`), `opacity`, `blendMode` and its
pixels in `layerImage`.

```dart
final psd = img.PsdDecoder().decodePsd(bytes);
for (final layer in psd?.layers ?? <img.PsdLayer>[]) {
  print('${layer.name}: ${layer.width}x${layer.height} at ${layer.left},${layer.top}');
}
```

### OpenEXR: decoding only

```dart
Image? decodeExr(Uint8List bytes);

Future<Image?> decodeExrFile(String path);
```

EXR is a high dynamic range format. Images decode to `Format.float16`, `float32` or `uint32`, matching the
file's color channels; other channels, such as depth, are in `image.extraChannels`. For a multi-part file,
`ExrDecoder` decodes one part per frame index. See [High Dynamic Range Images](hdr.md).

### PNM: decoding only

```dart
Image? decodePnm(Uint8List bytes);

Future<Image?> decodePnmFile(String path);
```

Reads PBM (bitmap, ASCII `P1`), PGM (gray, ASCII `P2` and binary `P5`) and PPM (RGB, ASCII `P3` and binary
`P6`) files. Binary PBM (`P4`) isn't supported.

## Decoder and Encoder Classes

The top-level functions are shortcuts for the decoder and encoder classes. Use the classes directly to pass
options, to get more information about a file, or to decode frames one at a time.

### Decoders

Each decoder implements the [`Decoder`](https://pub.dev/documentation/image/latest/image/Decoder-class.html)
interface:

| Member | Description |
|---|---|
| `bool isValidFile(Uint8List bytes)` | A quick test of whether the data looks like this format. |
| `Image? decode(Uint8List bytes, {int? frame})` | Decode the file: all frames, or only `frame`. |
| `DecodeInfo? startDecode(Uint8List bytes)` | Read the file's header without decoding any pixels. Returns null if the data isn't valid. |
| `int numFrames()` | The number of frames, after `startDecode`. |
| `Image? decodeFrame(int frame)` | Decode one frame, after `startDecode`. |
| `ImageFormat format` | The format this decoder reads. |

`startDecode` returns a [`DecodeInfo`](https://pub.dev/documentation/image/latest/image/DecodeInfo-class.html)
with the `width`, `height`, `numFrames` and suggested `backgroundColor` of the image. It's a cheap way to
get an image's size:

```dart
final decoder = img.PngDecoder();
final info = decoder.startDecode(bytes);
if (info != null) {
  print('${info.width}x${info.height}, ${info.numFrames} frame(s)');
  // The PNG-specific information.
  final pngInfo = decoder.info;
  print('bits: ${pngInfo.bits}, gamma: ${pngInfo.gamma}, text: ${pngInfo.textData}');
  // Decode just the first frame.
  final frame0 = decoder.decodeFrame(0);
  print(frame0);
}
```

Each format has its own `DecodeInfo` class with format-specific data. Some decoders expose it as a
property after `startDecode` or `decode`:

| Decoder | Info |
|---|---|
| `JpegDecoder` | `info` (`JpegInfo`): `numComponents` |
| `PngDecoder` | `info` (`PngInfo`): `bits`, `colorType`, `gamma`, `iccpName`, `iccpData`, `textData`, `pixelDimensions`, `cicpData`, `frames`, `repeat` |
| `GifDecoder` | `info` (`GifInfo`): `globalColorMap`, `frames` (`GifImageDesc`: `x`, `y`, `width`, `height`, `duration` in 1/100 s, `disposal`) |
| `WebPDecoder` | `info` (`WebPInfo`): `format` (lossy, lossless or animated), `hasAlpha`, `hasAnimation`, `animLoopCount`, `frames` (`WebPFrame`) |
| `TiffDecoder` | `info` (`TiffInfo`): `images` (`TiffImage` per page, with `bitsPerSample`, `compression`, …) |
| `TgaDecoder` | `info` (`TgaInfo`) |
| `PsdDecoder` | `info` (`PsdImage`): `layers`, `imageResources` |
| `ExrDecoder` | `exrImage` (`ExrImage`): `parts`, `numParts` |

### Encoders

Each encoder implements [`Encoder`](https://pub.dev/documentation/image/latest/image/Encoder-class.html):

```dart
final encoder = img.PngEncoder();
// Encode the image to the PNG format.
final Uint8List fileBytes = encoder.encode(image);
// Can the encoder write all frames of an animated image?
final bool supportsAnimation = encoder.supportsAnimation;
```

`supportsAnimation` is true for `GifEncoder`, `PngEncoder`, `WebPEncoder` and `IcoEncoder`.
`GifEncoder` and `PngEncoder` can also encode an animation a frame at a time; see
[Animated Images](animation.md#encoding-frame-by-frame).

### Finding a decoder or encoder

```dart
// The decoder for the file name's extension, or null.
Decoder? findDecoderForNamedImage(String name);

// The encoder for the file name's extension, or null.
Encoder? findEncoderForNamedImage(String name);

// Test the data against each decoder, returning the first that accepts it. Much slower than using a
// specific decoder.
Decoder? findDecoderForData(List<int> data);

// The format of the data, or ImageFormat.invalid. Uses findDecoderForData.
ImageFormat findFormatForData(List<int> data);

// An encoder for the same format as the data, or null if it's unknown or can't be encoded.
Encoder? findEncoderForData(List<int> data);

// A decoder for an ImageFormat, or null.
Decoder? createDecoderForFormat(ImageFormat format);
```

`ImageFormat` has the values `bmp`, `cur`, `exr`, `gif`, `ico`, `jpg`, `png`, `pnm`, `psd`, `pvr`, `tga`,
`tiff`, `webp`, `custom` and `invalid`.

```dart
// Re-encode a file in its original format after editing it.
final decoder = img.findDecoderForData(bytes);
final image = decoder?.decode(bytes);
if (image != null) {
  img.grayscale(image);
  final encoder = img.findEncoderForData(bytes) ?? img.PngEncoder();
  final output = encoder.encode(image);
  print('${decoder!.format}: ${output.length} bytes');
}
```

## Memory and Performance

- **Use a specific decoder.** `decodeImage` and `findDecoderForData` test the data against each format.
  `decodeJpg`, `decodePng`, etc. go straight to the right decoder.
- **Decode JPEG thumbnails at a reduced scale.** `decodeJpg(bytes, scale: 8)` decodes at 1/8 of the size,
  much faster and with a fraction of the memory of decoding the full image and resizing it.
- **Decode one frame.** Passing `frame: 0` decodes only the first frame of an animation instead of every
  frame at full canvas size.
- **Get the size without decoding.** `decoder.startDecode(bytes)` reads only the header.
- **Baseline JPEGs and PNGs stream.** Baseline JPEGs are decoded a band of rows at a time, and PNG image
  data is decompressed as rows are read, so neither holds a second full copy of the image while decoding.
  Progressive JPEGs need all of their coefficients until the last scan. On `dart:io` platforms the PNG
  encoder also compresses as it goes, using the platform's zlib.
- **Limit JPEG size.** Use `maxPixels` or `JpegDecoder.defaultMaxPixels` to refuse images too large for
  your app.
- **Move work off the main thread.** [Commands](commands.md) can run decoding, processing and encoding in
  an isolate.
