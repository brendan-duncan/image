# High Dynamic Range Images

Ordinary (low dynamic range) images store each channel as an 8-bit integer from 0 to 255, where 255 is
full intensity. High dynamic range (HDR) images store more precision, and with floating-point formats
they can also store values brighter than full intensity (greater than 1.0) or below zero. Photos merged
from several exposures, renders, light probes and scientific data are often HDR.

The library supports HDR images through the image's [format](image_data.md#formats):

| Format | Range | Notes |
|---|---|---|
| `Format.float16`, `float32`, `float64` | Any value; 1.0 is full intensity | True HDR. Use for values outside 0-1. |
| `Format.uint16`, `uint32` | 0 to 65535 / 4294967295 | More precision, same 0-1 range when normalized. |
| `Format.int8`, `int16`, `int32` | Signed integers | |

`image.isHdrFormat` is true for all of these formats and `image.isLdrFormat` for the 1, 2, 4 and 8-bit
unsigned formats. Note that a 16-bit PNG counts as an HDR format here, even though its values can't go
above full intensity.

## Creating and editing HDR images

Create a float image by passing a `format`. Pixel values are set and read as numbers, so float channels
can hold any value:

```dart
final hdr = img.Image(width: 256, height: 256, format: img.Format.float32, numChannels: 3);
// A pixel 4 times brighter than full white.
hdr.setPixelRgb(10, 10, 4.0, 4.0, 4.0);
final p = hdr.getPixel(10, 10);
print('${p.r} ${p.rNormalized}'); // 4.0 4.0
```

For float formats the maximum channel value (`image.maxChannelValue`) is 1.0, so normalized values are the
values themselves. Drawing functions and most filters work with HDR images, though some, such as color
quantization and the encoders for 8-bit formats, convert to 8 bits first.

## Reading HDR files

| Format | HDR content |
|---|---|
| [OpenEXR](formats.md#openexr-decoding-only) (.exr) | `float16` (half), `float32` or `uint32`, matching the color channels in the file. |
| [TIFF](formats.md#tiff-decoding-encoding) (.tif) | 16 and 32-bit integer, and 16, 32 and 64-bit float images. |
| [PNG](formats.md#png-decoding-encoding) (.png) | 16-bit PNGs decode to `uint16`. |

```dart
final exr = await img.decodeExrFile('scene.exr');
if (exr != null) {
  print('${exr.format}, ${exr.numChannels} channels'); // e.g. Format.float16, 4 channels
}
```

### OpenEXR channels and parts

The R, G, B and A channels of an EXR file become the image's color channels. Any other channels, such as
depth (`Z`) or object IDs, are stored by name in `image.extraChannels`:

```dart
final exr = img.decodeExr(bytes)!;
final depth = exr.getExtraChannel('Z'); // An ImageData, or null.
if (depth != null) {
  print('depth at 0,0: ${depth.getPixel(0, 0).r}');
}
```

A multi-part EXR file holds several images. `decodeExr` returns the first part; use `ExrDecoder` to get the
others:

```dart
final decoder = img.ExrDecoder();
if (decoder.startDecode(bytes) != null) {
  for (var i = 0; i < decoder.numFrames(); ++i) {
    final part = decoder.decodeFrame(i);
    print('part $i: ${part?.width}x${part?.height}');
  }
}
```

## Writing HDR images

None of the encoders write floating-point images:

- **PNG** writes `uint16` images as 16-bit PNGs, keeping 16 bits of precision in the 0-1 range. Other HDR
  formats are converted to 8 bits.
- **TIFF** converts all HDR formats, including 16-bit, to 8 bits.
- **JPEG, WebP, GIF, BMP, TGA** and the others store 8 bits per channel.

Converting a float image to an integer format clamps values to the 0-1 range, so values brighter than
full intensity are lost. To keep the overall look of an HDR image, [tone map](#tone-mapping) it first. To
keep precision for values that are already in 0-1, convert to `uint16` and save as PNG:

```dart
// Keep 16 bits of precision (values above 1.0 are clamped).
final png16 = img.encodePng(hdr.convert(format: img.Format.uint16));
```

## Tone mapping

Tone mapping compresses the range of an HDR image to what a normal display or 8-bit file can show.

### hdrToLdr

```dart
Image hdrToLdr(Image hdr, {num? exposure})
```

Returns a new 8-bit image with the same number of channels. Without `exposure`, color values are clamped
to 0-1 and scaled to 0-255, with no other change. With `exposure`, a value in stops, the image is
brightened or darkened by that exposure, values above 1.0 roll off smoothly instead of clipping, and a
display gamma of 2.2 is applied, much like an EXR viewer. `exposure: 0` is a good starting point; raise it
to brighten the image, lower it to darken. Infinite and NaN values are treated as 0.

```dart
final ldr = img.hdrToLdr(exr, exposure: 0);
await img.encodePngFile('scene.png', ldr);
```

### reinhardTonemap

```dart
Image reinhardTonemap(Image hdr, {Image? mask, Channel maskChannel = Channel.luminance})
```

Applies Reinhard's global tone mapping operator to a float image, **in place**. It compresses bright
values toward 1.0 based on the average luminance of the image, preserving more detail in highlights than
clamping does. The result is still a float image, with linear values. Use `mask` to blend the effect, as
with other [filters](filters.md#masks).

```dart
img.reinhardTonemap(exr); // exr is now in the 0-1 range.
final ldr8 = img.hdrToLdr(exr); // Convert to 8 bits.
```

`reinhardTonemap` reads the raw channel values, so use it on float images rather than 16-bit integer
ones. Both functions work on a single frame, the image you pass. See also
[hdrToLdr](filters.md#hdrtoldr) and [reinhardTonemap](filters.md#reinhardtonemap) in Image Processing.

## Converting between formats

`Image.convert` changes an image's format, mapping the full range of one format onto the other: 0-255 in
`uint8` becomes 0.0-1.0 in `float32` and 0-65535 in `uint16`, and float values are clamped to 0-1 when
converting to integer formats. It returns a new image, including all frames.

```dart
// 8-bit to float, e.g. to do HDR math on an ordinary image.
final asFloat = image8.convert(format: img.Format.float32);
// Float to 8-bit, clamping (no tone mapping).
final as8 = asFloat.convert(format: img.Format.uint8);
```

See [Converting Images](image_data.md#converting-images).
