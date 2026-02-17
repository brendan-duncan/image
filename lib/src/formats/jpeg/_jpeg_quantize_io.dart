import 'dart:typed_data';

import '../../exif/exif_data.dart';
import '../../image/image.dart';
import '../../util/image_exception.dart';
import '_component_data.dart';
import 'jpeg_data.dart';

final _dctClip = _createDctClip();

const _dctClipOffset = 256;
const _dctClipLength = 768;

Uint8List _createDctClip() {
  final result = Uint8List(_dctClipLength);
  for (var i = 0; i < 256; ++i) {
    result[_dctClipOffset + i] = i;
  }
  for (var i = 256; i < 512; ++i) {
    result[_dctClipOffset + i] = 255;
  }
  return result;
}

// Quantize the coefficients and apply IDCT.
//
// A port of poppler's IDCT method which in turn is taken from:
// Christoph Loeffler, Adriaan Ligtenberg, George S. Moschytz,
// "Practical Fast 1-D DCT Algorithms with 11 Multiplications",
// IEEE Intl. Conf. on Acoustics, Speech & Signal Processing, 1989, 988-991.
void quantizeAndInverse(Int16List quantizationTable, Int32List coefBlock,
    Uint8List dataOut, Int32List dataIn) {
  final p = dataIn;

  // IDCT constants (20.12 fixed point format)
  const cos1 = 4017; // cos(pi/16)*4096
  const sin1 = 799; // sin(pi/16)*4096
  const cos3 = 3406; // cos(3*pi/16)*4096
  const sin3 = 2276; // sin(3*pi/16)*4096
  const cos6 = 1567; // cos(6*pi/16)*4096
  const sin6 = 3784; // sin(6*pi/16)*4096
  const sqrt2 = 5793; // sqrt(2)*4096
  const sqrt102 = 2896; // sqrt(2) / 2

  // de-quantize
  for (var i = 0; i < 64; i++) {
    p[i] = coefBlock[i] * quantizationTable[i];
  }

  // inverse DCT on rows
  var row = 0;
  for (var i = 0; i < 8; ++i, row += 8) {
    // check for all-zero AC coefficients
    if (p[1 + row] == 0 &&
        p[2 + row] == 0 &&
        p[3 + row] == 0 &&
        p[4 + row] == 0 &&
        p[5 + row] == 0 &&
        p[6 + row] == 0 &&
        p[7 + row] == 0) {
      final t = (sqrt2 * p[0 + row] + 512) >> 10;
      p[row + 0] = t;
      p[row + 1] = t;
      p[row + 2] = t;
      p[row + 3] = t;
      p[row + 4] = t;
      p[row + 5] = t;
      p[row + 6] = t;
      p[row + 7] = t;
      continue;
    }

    // stage 4
    var v0 = (sqrt2 * p[0 + row] + 128) >> 8;
    var v1 = (sqrt2 * p[4 + row] + 128) >> 8;
    var v2 = p[2 + row];
    var v3 = p[6 + row];
    var v4 = (sqrt102 * (p[1 + row] - p[7 + row]) + 128) >> 8;
    var v7 = (sqrt102 * (p[1 + row] + p[7 + row]) + 128) >> 8;
    var v5 = p[3 + row] << 4;
    var v6 = p[5 + row] << 4;

    // stage 3
    var t = (v0 - v1 + 1) >> 1;
    v0 = (v0 + v1 + 1) >> 1;
    v1 = t;
    t = (v2 * sin6 + v3 * cos6 + 128) >> 8;
    v2 = (v2 * cos6 - v3 * sin6 + 128) >> 8;
    v3 = t;
    t = (v4 - v6 + 1) >> 1;
    v4 = (v4 + v6 + 1) >> 1;
    v6 = t;
    t = (v7 + v5 + 1) >> 1;
    v5 = (v7 - v5 + 1) >> 1;
    v7 = t;

    // stage 2
    t = (v0 - v3 + 1) >> 1;
    v0 = (v0 + v3 + 1) >> 1;
    v3 = t;
    t = (v1 - v2 + 1) >> 1;
    v1 = (v1 + v2 + 1) >> 1;
    v2 = t;
    t = (v4 * sin3 + v7 * cos3 + 2048) >> 12;
    v4 = (v4 * cos3 - v7 * sin3 + 2048) >> 12;
    v7 = t;
    t = (v5 * sin1 + v6 * cos1 + 2048) >> 12;
    v5 = (v5 * cos1 - v6 * sin1 + 2048) >> 12;
    v6 = t;

    // stage 1
    p[0 + row] = v0 + v7;
    p[7 + row] = v0 - v7;
    p[1 + row] = v1 + v6;
    p[6 + row] = v1 - v6;
    p[2 + row] = v2 + v5;
    p[5 + row] = v2 - v5;
    p[3 + row] = v3 + v4;
    p[4 + row] = v3 - v4;
  }

  // inverse DCT on columns
  for (var i = 0; i < 8; ++i) {
    final col = i;
    final p0 = col;
    final p1 = 8 + col;
    final p2 = 16 + col;
    final p3 = 24 + col;
    final p4 = 32 + col;
    final p5 = 40 + col;
    final p6 = 48 + col;
    final p7 = 56 + col;

    // check for all-zero AC coefficients
    if (p[p1] == 0 &&
        p[p2] == 0 &&
        p[p3] == 0 &&
        p[p4] == 0 &&
        p[p5] == 0 &&
        p[p6] == 0 &&
        p[p7] == 0) {
      final t = (sqrt2 * dataIn[i] + 8192) >> 14;
      p[p0] = t;
      p[p1] = t;
      p[p2] = t;
      p[p3] = t;
      p[p4] = t;
      p[p5] = t;
      p[p6] = t;
      p[p7] = t;
      continue;
    }

    // stage 4
    var v0 = (sqrt2 * p[p0] + 2048) >> 12;
    var v1 = (sqrt2 * p[p4] + 2048) >> 12;
    var v2 = p[p2];
    var v3 = p[p6];
    var v4 = (sqrt102 * (p[p1] - p[p7]) + 2048) >> 12;
    var v7 = (sqrt102 * (p[p1] + p[p7]) + 2048) >> 12;
    var v5 = p[p3];
    var v6 = p[p5];

    // stage 3
    var t = (v0 - v1 + 1) >> 1;
    v0 = (v0 + v1 + 1) >> 1;
    v1 = t;
    t = (v2 * sin6 + v3 * cos6 + 2048) >> 12;
    v2 = (v2 * cos6 - v3 * sin6 + 2048) >> 12;
    v3 = t;
    t = (v4 - v6 + 1) >> 1;
    v4 = (v4 + v6 + 1) >> 1;
    v6 = t;
    t = (v7 + v5 + 1) >> 1;
    v5 = (v7 - v5 + 1) >> 1;
    v7 = t;

    // stage 2
    t = (v0 - v3 + 1) >> 1;
    v0 = (v0 + v3 + 1) >> 1;
    v3 = t;
    t = (v1 - v2 + 1) >> 1;
    v1 = (v1 + v2 + 1) >> 1;
    v2 = t;
    t = (v4 * sin3 + v7 * cos3 + 2048) >> 12;
    v4 = (v4 * cos3 - v7 * sin3 + 2048) >> 12;
    v7 = t;
    t = (v5 * sin1 + v6 * cos1 + 2048) >> 12;
    v5 = (v5 * cos1 - v6 * sin1 + 2048) >> 12;
    v6 = t;

    // stage 1
    p[p0] = v0 + v7;
    p[p7] = v0 - v7;
    p[p1] = v1 + v6;
    p[p6] = v1 - v6;
    p[p2] = v2 + v5;
    p[p5] = v2 - v5;
    p[p3] = v3 + v4;
    p[p4] = v3 - v4;
  }

  // convert to 8-bit integers
  for (var i = 0; i < 64; ++i) {
    final index = _dctClipOffset + 128 + ((p[i] + 8) >> 4);
    if (index < 0) {
      break;
    }
    dataOut[i] = _dctClip[index];
  }
}

Image getImageFromJpeg(JpegData jpeg) {
  final orientation =
      jpeg.exif.imageIfd.hasOrientation ? jpeg.exif.imageIfd.orientation! : 0;

  final w = jpeg.width!;
  final h = jpeg.height!;
  final flipWidthHeight = orientation >= 5 && orientation <= 8;
  final width = flipWidthHeight ? h : w;
  final height = flipWidthHeight ? w : h;

  final image = Image(width: width, height: height)
    ..exif = ExifData.from(jpeg.exif)
    ..exif.imageIfd.orientation = null;

  ComponentData component1;
  ComponentData component2;
  ComponentData component3;
  ComponentData component4;
  Uint8List? component1Line;
  Uint8List? component2Line;
  Uint8List? component3Line;
  Uint8List? component4Line;
  var colorTransform = false;

  final h1 = h - 1;
  final w1 = w - 1;

  void Function(int x, int y, num r, num g, num b) setPixel;
  switch (orientation) {
    case 2:
      setPixel = (x, y, r, g, b) => image.setPixelRgb(w1 - x, y, r, g, b);
      break;
    case 3:
      setPixel = (x, y, r, g, b) => image.setPixelRgb(w1 - x, h1 - y, r, g, b);
      break;
    case 4:
      setPixel = (x, y, r, g, b) => image.setPixelRgb(x, h1 - y, r, g, b);
      break;
    case 5:
      setPixel = (x, y, r, g, b) => image.setPixelRgb(y, x, r, g, b);
      break;
    case 6:
      setPixel = (x, y, r, g, b) => image.setPixelRgb(h1 - y, x, r, g, b);
      break;
    case 7:
      setPixel = (x, y, r, g, b) => image.setPixelRgb(h1 - y, w1 - x, r, g, b);
      break;
    case 8:
      setPixel = (x, y, r, g, b) => image.setPixelRgb(y, w1 - x, r, g, b);
      break;
    default:
      setPixel = image.setPixelRgb;
      break;
  }

  switch (jpeg.components.length) {
    case 1:
      component1 = jpeg.components[0];
      final lines = component1.lines;
      final hShift1 = component1.hScaleShift;
      final vShift1 = component1.vScaleShift;
      for (var y = 0; y < h; y++) {
        final y1 = y >> vShift1;
        component1Line = lines[y1];
        for (var x = 0; x < w; x++) {
          final x1 = x >> hShift1;
          final cy = component1Line![x1];
          setPixel(x, y, cy, cy, cy);
        }
      }
      break;
    /*case 2:
        // PDF might compress two component data in custom color-space
        component1 = components[0];
        component2 = components[1];
        int hShift1 = component1.hScaleShift;
        int vShift1 = component1.vScaleShift;
        int hShift2 = component2.hScaleShift;
        int vShift2 = component2.vScaleShift;

        for (int y = 0; y < h; y++) {
          int y1 = y >> vShift1;
          int y2 = y >> vShift2;
          component1Line = component1.lines[y1];
          component2Line = component2.lines[y2];

          for (int x = 0; x < w; x++) {
            int x1 = x >> hShift1;
            int x2 = x >> hShift2;

            final cy = component1Line[x1];
            //data[offset++] = cy;

            cy = component2Line[x2];
            //data[offset++] = cy;
          }
        }
        break;*/
    case 3:
      // The default transform for three components is true
      // Determine if this is YCbCr or RGB based on markers
      // JFIF indicates YCbCr, Adobe APP14 can specify transform, default to
      // YCbCr
      colorTransform = true;
      if (jpeg.adobe != null) {
        // Adobe transform: 0=unknown, 1=YCbCr->RGB, 2=YCCK->CMYK
        colorTransform = jpeg.adobe!.transformCode == 1;
      }

      component1 = jpeg.components[0];
      component2 = jpeg.components[1];
      component3 = jpeg.components[2];

      final lines1 = component1.lines;
      final lines2 = component2.lines;
      final lines3 = component3.lines;

      final hShift1 = component1.hScaleShift;
      final vShift1 = component1.vScaleShift;
      final hShift2 = component2.hScaleShift;
      final vShift2 = component2.vScaleShift;
      final hShift3 = component3.hScaleShift;
      final vShift3 = component3.vScaleShift;

      for (var y = 0; y < h; y++) {
        final y1 = y >> vShift1;
        final y2 = y >> vShift2;
        final y3 = y >> vShift3;

        component1Line = lines1[y1]!;
        component2Line = lines2[y2]!;
        component3Line = lines3[y3]!;

        for (var x = 0; x < w; x++) {
          final x1 = x >> hShift1;
          final x2 = x >> hShift2;
          final x3 = x >> hShift3;

          var r = component1Line[x1];
          var g = component2Line[x2];
          var b = component3Line[x3];

          if (colorTransform) {
            final cy = r << 8;
            final cb = g - 128;
            final cr = b - 128;
            r = ((cy + (359 * cr)) >> 8).clamp(0, 255);
            g = ((cy - (88 * cb) - (183 * cr)) >> 8).clamp(0, 255);
            b = ((cy + 454 * cb) >> 8).clamp(0, 255);
          }

          setPixel(x, y, r, g, b);
        }
      }
      break;
    case 4:
      if (jpeg.adobe == null) {
        throw ImageException('Unsupported color mode (4 components)');
      }
      // The default transform for four components is false
      colorTransform = false;
      // The adobe transform marker overrides any previous setting
      if (jpeg.adobe!.transformCode != 0) {
        colorTransform = true;
      }

      component1 = jpeg.components[0];
      component2 = jpeg.components[1];
      component3 = jpeg.components[2];
      component4 = jpeg.components[3];

      final lines1 = component1.lines;
      final lines2 = component2.lines;
      final lines3 = component3.lines;
      final lines4 = component4.lines;

      final hShift1 = component1.hScaleShift;
      final vShift1 = component1.vScaleShift;
      final hShift2 = component2.hScaleShift;
      final vShift2 = component2.vScaleShift;
      final hShift3 = component3.hScaleShift;
      final vShift3 = component3.vScaleShift;
      final hShift4 = component4.hScaleShift;
      final vShift4 = component4.vScaleShift;

      for (var y = 0; y < h; y++) {
        final y1 = y >> vShift1;
        final y2 = y >> vShift2;
        final y3 = y >> vShift3;
        final y4 = y >> vShift4;
        component1Line = lines1[y1];
        component2Line = lines2[y2];
        component3Line = lines3[y3];
        component4Line = lines4[y4];
        for (var x = 0; x < w; x++) {
          final x1 = x >> hShift1;
          final x2 = x >> hShift2;
          final x3 = x >> hShift3;
          final x4 = x >> hShift4;
          int cc, cm, cy, ck;
          if (!colorTransform) {
            cc = component1Line![x1];
            cm = component2Line![x2];
            cy = component3Line![x3];
            ck = component4Line![x4];
          } else {
            cy = component1Line![x1];
            final cb = component2Line![x2];
            final cr = component3Line![x3];
            ck = component4Line![x4];

            final crShifted = cr - 128;
            final cbShifted = cb - 128;
            final cyScaled = cy << 8;
            cc = 255 - ((cyScaled + 359 * crShifted) >> 8).clamp(0, 255);
            cm = 255 -
                ((cyScaled - 88 * cbShifted - 183 * crShifted) >> 8)
                    .clamp(0, 255);
            cy = 255 - ((cyScaled + 454 * cbShifted) >> 8).clamp(0, 255);
          }
          final r = (cc * ck) >> 8;
          final g = (cm * ck) >> 8;
          final b = (cy * ck) >> 8;

          setPixel(x, y, r, g, b);
        }
      }
      break;
    default:
      throw ImageException('Unsupported color mode');
  }

  if (jpeg.iccProfile != null) {
    image.iccProfile = jpeg.iccProfile;
  }

  return image;
}
