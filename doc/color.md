# Color Spaces and Alpha

This page explains how the library interprets pixel values: which color space they're in, what happens to
color profiles, how blending can be done in linear light, and how alpha (transparency) is stored.

```dart
import 'package:image/image.dart' as img;
```

- [Pixel values are sRGB](#pixel-values-are-srgb)
- [Color profiles are carried, not applied](#color-profiles-are-carried-not-applied)
- [Blending in linear light](#blending-in-linear-light)
- [Alpha](#alpha)

## Pixel values are sRGB

The numbers in an 8-bit or 16-bit image are treated as sRGB-encoded values, which is what almost every
JPEG, PNG, GIF and WebP file holds. sRGB values aren't proportional to the amount of light: the encoding
spends more of its range on dark tones, where your eyes are more sensitive. A stored value of 128 (halfway)
is only about 22% of the light of 255.

Float (HDR) images are different. Files such as OpenEXR usually hold linear light, where 0.5 is half the
light of 1.0, and values can go above 1.0. See [High Dynamic Range Images](hdr.md) for how to tone map
them down to 8-bit sRGB.

## Color profiles are carried, not applied

The library doesn't do color management. It never converts pixels from one color space to another, so an
image in Display P3 or Adobe RGB keeps its numbers unchanged and will look wrong if you treat it as sRGB.
What it does is read the color space information from files and carry it along, so you can write it back
out or act on it yourself.

### ICC profiles

The JPEG, PNG and WebP decoders store an embedded ICC profile in
[`image.iccProfile`](https://pub.dev/documentation/image/latest/image/Image/iccProfile.html), an
[IccProfile](https://pub.dev/documentation/image/latest/image/IccProfile-class.html). Copies and transforms,
such as `clone` and `copyResize`, keep it. The JPEG, PNG and WebP encoders write it back out; the other
encoders drop it.

An `IccProfile` has a `name`, the profile `data`, and a `compression`
([IccProfileCompression](https://pub.dev/documentation/image/latest/image/IccProfileCompression.html)
`none` or `deflate`). A PNG stores its profile deflated, so use `decompressed()` to get the raw profile
bytes, or `compressed()` for the deflated bytes. Both convert the stored data in place and return it.
`decompressed()` throws an `ImageException` for invalid data, and stops at 16 MB.

```dart
final icc = image.iccProfile;
if (icc != null) {
  final Uint8List profile = icc.decompressed();
  // Pass the profile to a color management library, or inspect it.
}
```

To attach a profile, for example one you read from an `.icc` file, create an `IccProfile` from its bytes:

```dart
image.iccProfile = img.IccProfile(
    'Display P3', img.IccProfileCompression.none, File('DisplayP3.icc').readAsBytesSync());
await img.encodePngFile('p3.png', image);
```

To strip a profile, for example after converting the pixels to sRGB yourself, set `image.iccProfile = null`.

### PNG cICP

PNG files can mark their color space with a cICP chunk instead of an ICC profile, often for Display P3 or
HDR (BT.2020 PQ) images. The PNG decoder reads it into `PngDecoder.info.cicpData`, a
[PngCicpData](https://pub.dev/documentation/image/latest/image/PngCicpData-class.html) with the
`colorPrimaries`, `transferCharacteristics`, `matrixCoefficients` and `videoFullRangeFlag` values. It isn't
stored on the `Image`, so to keep it, read it from the decoder and pass it to the encoder:

```dart
final decoder = img.PngDecoder();
final image = decoder.decode(bytes)!;
final cicp = decoder.info.cicpData;
// ...
final png = img.encodePng(image, cicpData: cicp);
```

## Blending in linear light

Operations that average colors, such as resizing, blurring and antialiased drawing, normally average the
stored sRGB numbers. Because those numbers aren't proportional to light, the averages come out too dark:
averaging a black and a white pixel gives 128, which is only about 22% of the light, rather than the 50%
the eye expects. You can see it as thin bright lines and text that dim and thin out when an image is
shrunk, and soft edges that look darker than they should.

Functions that average colors take a `linearBlend` option. With `linearBlend: true`, the colors are converted
to linear light, blended, and converted back to sRGB:

```dart
final thumbnail = img.copyResize(image, width: 256,
    interpolation: img.Interpolation.average, linearBlend: true);
```

These functions, and their [Command](commands.md) equivalents, take `linearBlend`:

| Kind | Functions |
|---|---|
| Transforms | `copyResize`, `resize`, `copyResizeCropSquare`, `copyRotate`, `copyRectify` |
| Filters | `gaussianBlur`, `separableConvolution`, `smooth`, `pixelate`, `vignette`, `bulgeDistortion`, `stretchDistortion` |
| Drawing | `drawPixel`, `drawLine`, `drawRect`, `drawCircle`, `fillCircle`, `drawPolygon`, `fillPolygon`, `drawChar`, `drawString`, `compositeImage` |

How it works:

- Transforms and filters run on a float32 working copy of the image holding linear values, then write the
  result back in the image's own format. Drawing functions convert each blended pixel instead.
- Alpha is a coverage amount, not a color, so it isn't linearized.
- It has no effect with `Interpolation.nearest`, which picks pixels rather than blending them.
- The input is assumed to be sRGB. Don't use it on images that already hold linear values, such as most
  float images.

It costs time and, for transforms and filters, memory for the float32 copy. As a guide, `gaussianBlur` with
radius 5 on a 2000 x 1500 image went from 186 ms to 317 ms, and `copyResize` to a quarter size with
`Interpolation.average` from 9 ms to 70 ms. It's worth it for thumbnails of images with fine detail, such
as text, line art or star fields, and for blending soft edges; for most photos the difference is small.

If you work with pixel values directly, `srgbToLinear` and `linearToSrgb` convert one normalized (0-1)
channel value:

```dart
final p = image.getPixel(x, y);
final linearR = img.srgbToLinear(p.rNormalized); // 0.5 -> about 0.214
p.rNormalized = img.linearToSrgb(linearR * 0.5); // Half the light.
```

## Alpha

### Straight alpha

Images store straight (not premultiplied) alpha: a pixel's color channels hold its full color, whatever its
alpha. A fully transparent pixel still has a color, which is usually invisible but can come back if you
remove the alpha channel.

An image has an alpha channel if it has 2 channels (gray and alpha) or 4 (RGBA), or a palette with 2 or 4
channels. `image.hasAlpha` tells you which.

### Adding and removing alpha

`image.convert(numChannels: 4)` adds an alpha channel. The new alpha is opaque unless you pass `alpha`:

```dart
final rgba = image.convert(numChannels: 4); // Opaque.
final clear = image.convert(numChannels: 4, alpha: 0); // Fully transparent.
```

`Color.convert` is different: when it adds an alpha channel to a single color, the alpha defaults to 0
(transparent), so pass `alpha` explicitly, such as `color.convert(numChannels: 4, alpha: 255)`.

Converting to fewer channels, such as `image.convert(numChannels: 3)`, simply drops the alpha, so hidden
colors of transparent pixels show up. To get what the image looks like, flatten it onto a background
instead:

```dart
final flat = img.Image(width: image.width, height: image.height)
  ..clear(img.ColorRgb8(255, 255, 255));
img.compositeImage(flat, image);
```

The JPEG encoder does this for you: JPEG has no alpha, so it blends transparent pixels over
`image.backgroundColor`, or white if that's null.

### Which formats keep alpha

| Format | Alpha |
|---|---|
| PNG | Yes, gray + alpha or RGBA. |
| WebP | Yes, lossless or lossy. |
| TGA | Yes, written as 32-bit RGBA. |
| BMP | Yes, 8-bit RGBA images are written as 32-bit with an alpha mask. |
| ICO, CUR | Yes, each image is stored as a PNG. |
| TIFF | The 4th channel is written, but without the tag that marks it as alpha, so other programs may not treat it as transparency. |
| GIF | Only for palette images: the first palette color with an alpha of 0 is written as the transparent color, and partial transparency is lost. An RGBA image is quantized to an opaque palette, so its transparency is lost. |
| JPEG | No. Blended over the background color, as above. |

### Dark fringes on transparent edges

Because alpha is straight, resizing, blurring or rotating an image with transparent areas mixes in the
colors of the fully transparent pixels next to the visible ones. Those colors are often black (a new image
is filled with zeros), which leaves a dark fringe around the edges of the visible content. Premultiplied
alpha would avoid this, but the library doesn't premultiply.

To avoid fringes, make sure transparent pixels have a color close to their visible neighbors before you
resize or blur, for example by filling the image with the edge color (keeping alpha 0) before drawing the
content into it.
