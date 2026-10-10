import 'dart:typed_data';

import '../../exif/exif_data.dart';
import '../../image/image.dart';
import '../../util/image_exception.dart';
import 'jpeg_data.dart';

// Clamps a fixed point (x.8) color value v to [0, 255] as
// _clip[(v + _clipBias) >> 8]. The bias keeps the shifted value non-negative,
// so this is safe from dart2js's unsigned shifts.
const _clipBias = 256 << 8;
final _clip = Uint8List(768)
  ..setRange(256, 512, List<int>.generate(256, (i) => i))
  ..fillRange(512, 768, 255);

/// Converts the decoded component lines of [jpeg] to an RGB [Image], baking
/// in the EXIF orientation.
Image getImageFromJpeg(JpegData jpeg) {
  final orientation =
      jpeg.exif.imageIfd.hasOrientation ? jpeg.exif.imageIfd.orientation! : 0;

  final w = jpeg.scaledWidth;
  final h = jpeg.scaledHeight;
  final flipWidthHeight = orientation >= 5 && orientation <= 8;
  final width = flipWidthHeight ? h : w;
  final height = flipWidthHeight ? w : h;

  final image = Image(width: width, height: height)
    ..exif = ExifData.from(jpeg.exif)
    ..exif.imageIfd.orientation = null
    ..iccProfile = jpeg.iccProfile;

  final data = image.data!.toUint8List();
  final stride = image.data!.rowStride;
  final w1 = w - 1;
  final h1 = h - 1;

  // The byte offset of source pixel (x, y) in the oriented image is
  // start + x * xStep + y * yStep.
  int start;
  int xStep;
  int yStep;
  switch (orientation) {
    case 2: // flip horizontal
      start = w1 * 3;
      xStep = -3;
      yStep = stride;
      break;
    case 3: // rotate 180
      start = h1 * stride + w1 * 3;
      xStep = -3;
      yStep = -stride;
      break;
    case 4: // flip vertical
      start = h1 * stride;
      xStep = 3;
      yStep = -stride;
      break;
    case 5: // transpose
      start = 0;
      xStep = stride;
      yStep = 3;
      break;
    case 6: // rotate 90 clockwise
      start = h1 * 3;
      xStep = stride;
      yStep = -3;
      break;
    case 7: // transverse
      start = w1 * stride + h1 * 3;
      xStep = -stride;
      yStep = -3;
      break;
    case 8: // rotate 270 clockwise
      start = w1 * stride;
      xStep = -stride;
      yStep = 3;
      break;
    default:
      start = 0;
      xStep = 3;
      yStep = stride;
      break;
  }

  final components = jpeg.components;
  switch (components.length) {
    case 1:
      final c1 = components[0];
      final hShift1 = c1.hScaleShift;
      final vShift1 = c1.vScaleShift;
      var rowStart = start;
      for (var y = 0; y < h; y++, rowStart += yStep) {
        final line1 = c1.lines[y >> vShift1]!;
        var di = rowStart;
        for (var x = 0; x < w; x++, di += xStep) {
          final cy = line1[x >> hShift1];
          data[di] = cy;
          data[di + 1] = cy;
          data[di + 2] = cy;
        }
      }
      break;
    case 3:
      // JFIF indicates YCbCr; Adobe APP14 can specify the transform
      // (0 = none/RGB, 1 = YCbCr). Default to YCbCr.
      final colorTransform =
          jpeg.adobe == null || jpeg.adobe!.transformCode == 1;
      final c1 = components[0];
      final c2 = components[1];
      final c3 = components[2];
      final hShift1 = c1.hScaleShift;
      final vShift1 = c1.vScaleShift;
      final hShift2 = c2.hScaleShift;
      final vShift2 = c2.vScaleShift;
      final hShift3 = c3.hScaleShift;
      final vShift3 = c3.vScaleShift;
      final clip = _clip;
      var rowStart = start;
      for (var y = 0; y < h; y++, rowStart += yStep) {
        final line1 = c1.lines[y >> vShift1]!;
        final line2 = c2.lines[y >> vShift2]!;
        final line3 = c3.lines[y >> vShift3]!;
        var di = rowStart;
        if (colorTransform) {
          for (var x = 0; x < w; x++, di += xStep) {
            final cy = (line1[x >> hShift1] << 8) + _clipBias;
            final cb = line2[x >> hShift2] - 128;
            final cr = line3[x >> hShift3] - 128;
            data[di] = clip[(cy + 359 * cr) >> 8];
            data[di + 1] = clip[(cy - 88 * cb - 183 * cr) >> 8];
            data[di + 2] = clip[(cy + 454 * cb) >> 8];
          }
        } else {
          for (var x = 0; x < w; x++, di += xStep) {
            data[di] = line1[x >> hShift1];
            data[di + 1] = line2[x >> hShift2];
            data[di + 2] = line3[x >> hShift3];
          }
        }
      }
      break;
    case 4:
      if (jpeg.adobe == null) {
        throw ImageException('Unsupported color mode (4 components)');
      }
      // The default transform for four components is false; the Adobe
      // transform marker overrides it.
      final colorTransform = jpeg.adobe!.transformCode != 0;
      final c1 = components[0];
      final c2 = components[1];
      final c3 = components[2];
      final c4 = components[3];
      final hShift1 = c1.hScaleShift;
      final vShift1 = c1.vScaleShift;
      final hShift2 = c2.hScaleShift;
      final vShift2 = c2.vScaleShift;
      final hShift3 = c3.hScaleShift;
      final vShift3 = c3.vScaleShift;
      final hShift4 = c4.hScaleShift;
      final vShift4 = c4.vScaleShift;
      final clip = _clip;
      var rowStart = start;
      for (var y = 0; y < h; y++, rowStart += yStep) {
        final line1 = c1.lines[y >> vShift1]!;
        final line2 = c2.lines[y >> vShift2]!;
        final line3 = c3.lines[y >> vShift3]!;
        final line4 = c4.lines[y >> vShift4]!;
        var di = rowStart;
        for (var x = 0; x < w; x++, di += xStep) {
          int cc, cm, cy;
          final ck = line4[x >> hShift4];
          if (!colorTransform) {
            cc = line1[x >> hShift1];
            cm = line2[x >> hShift2];
            cy = line3[x >> hShift3];
          } else {
            final cyScaled = (line1[x >> hShift1] << 8) + _clipBias;
            final cb = line2[x >> hShift2] - 128;
            final cr = line3[x >> hShift3] - 128;
            cc = 255 - clip[(cyScaled + 359 * cr) >> 8];
            cm = 255 - clip[(cyScaled - 88 * cb - 183 * cr) >> 8];
            cy = 255 - clip[(cyScaled + 454 * cb) >> 8];
          }
          data[di] = (cc * ck) >> 8;
          data[di + 1] = (cm * ck) >> 8;
          data[di + 2] = (cy * ck) >> 8;
        }
      }
      break;
    default:
      throw ImageException('Unsupported color mode');
  }

  return image;
}
