import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:image/image.dart';
import 'package:test/test.dart';

/// Directory test outputs (PNGs, etc.) are written to.
///
/// By default this is a unique system-temp directory, so repeated runs and CI
/// stay clean and never collide. To inspect outputs locally, set the
/// `IMAGE_TEST_OUTPUT` environment variable to a path before running the
/// tests -- no source edits required:
///
/// ```
/// IMAGE_TEST_OUTPUT=_out dart test            # bash / zsh
/// $env:IMAGE_TEST_OUTPUT='_out'; dart test    # PowerShell
/// ```
final testOutputPath = _resolveTestOutputPath();

String _resolveTestOutputPath() {
  final override = Platform.environment['IMAGE_TEST_OUTPUT'];
  if (override != null && override.trim().isNotEmpty) {
    final dir = Directory(override.trim())..createSync(recursive: true);
    return '${dir.absolute.path}/out';
  }
  return '${Directory.systemTemp.createTempSync('image_test_').path}/out';
}

int hashImage(Image image) {
  var hash = 0;
  var x = 0;
  var y = 0;

  final rgbaDouble = Float64List(4);
  final rgba8 = Uint8List.view(rgbaDouble.buffer);
  for (final p in image) {
    for (var ci = 0; ci < p.length; ++ci) {
      rgbaDouble[ci] = p[ci].toDouble();
    }
    hash = getCrc32(rgba8, hash);
    if (x != p.x || y != p.y) {
      throw ImageException('Invalid Pixel index');
    }
    x++;
    if (x == image.width) {
      x = 0;
      y++;
    }
  }

  return hash;
}

void testImageEquals(Image image, Image image2) {
  expect(image2.width, equals(image.width));
  expect(image2.height, equals(image.height));
  expect(image2.numChannels, equals(image.numChannels));
  expect(image2.hasPalette, equals(image.hasPalette));
  final c = image.iterator..moveNext();
  for (var p2 in image2) {
    final p1 = c.current;
    expect(
      p2,
      equals(p1),
      reason: 'At Pixel ${p2.x},${p2.y} / ${image.width} ${image.height}',
    );
    c.moveNext();
  }
}

Future<void> testImageConversions(Image image) async {
  for (final format in Format.values) {
    for (var nc = 1; nc <= 4; ++nc) {
      final ic = image.convert(
        format: format,
        numChannels: nc,
        withPalette: true,
      );
      expect(ic.width, equals(image.width));
      expect(ic.height, equals(image.height));
      expect(ic.format, equals(format));
      expect(ic.numChannels, equals(nc));
      /*if (nc < 4 &&
          (format == Format.uint1 || format == Format.uint2 ||
              format == Format.uint4 ||
              (format == Format.uint8 && nc == 1))) {
        expect(ic.palette, isNotNull);
      } else {
        expect(ic.palette, isNull);
      }*/

      // Exercise the reverse conversion and the PNG encoder, but keep it in
      // memory. This helper is called hundreds of times by the image/* tests;
      // writing a debug PNG per conversion previously dominated the run time
      // (and tripped the 30s per-test timeout) whenever testOutputPath pointed
      // at an antivirus- or file-sync-scanned volume such as a source tree.
      final oc = ic.convert(format: Format.uint8, numChannels: 4);
      expect(encodePng(oc), isNotEmpty);

      /*final op = image.getPixel(0, 0);
      for (final np in ic) {
        final nr = (np.rNormalized * 255).floor();
        final or = (op.rNormalized * 255).floor();
        expect(nr, equals(or));
        op.moveNext();
      }*/
    }
  }
}

// ---------------------------------------------------------------------------
// Synthetic image builders.
//
// These produce small images whose exact contents are known, so a test can
// assert what an operation *should* produce rather than just that it ran.
// ---------------------------------------------------------------------------

/// A [width]x[height] image with every pixel set to [color].
Image solidImage(int width, int height, Color color, {int numChannels = 3}) {
  final image = Image(width: width, height: height, numChannels: numChannels);
  for (final p in image) {
    if (numChannels >= 4) {
      p.setRgba(color.r, color.g, color.b, color.a);
    } else {
      p.setRgb(color.r, color.g, color.b);
    }
  }
  return image;
}

/// A horizontal grayscale ramp: column `x` has value `round(x/(w-1)*255)`,
/// black on the left, white on the right.
Image horizontalGradient(int width, int height) {
  final image = Image(width: width, height: height);
  for (final p in image) {
    final v = width <= 1 ? 0 : (p.x * 255 / (width - 1)).round();
    p.setRgb(v, v, v);
  }
  return image;
}

/// A vertical grayscale ramp: row `y` has value `round(y/(h-1)*255)`,
/// black on top, white on the bottom.
Image verticalGradient(int width, int height) {
  final image = Image(width: width, height: height);
  for (final p in image) {
    final v = height <= 1 ? 0 : (p.y * 255 / (height - 1)).round();
    p.setRgb(v, v, v);
  }
  return image;
}

/// An image split into four solid quadrants. Useful for verifying flip,
/// rotate and other symmetry-preserving operations.
Image quadrantImage(
  int width,
  int height, {
  Color? topLeft,
  Color? topRight,
  Color? bottomLeft,
  Color? bottomRight,
}) {
  final tl = topLeft ?? ColorRgb8(255, 0, 0);
  final tr = topRight ?? ColorRgb8(0, 255, 0);
  final bl = bottomLeft ?? ColorRgb8(0, 0, 255);
  final br = bottomRight ?? ColorRgb8(255, 255, 0);
  final image = Image(width: width, height: height);
  final mx = width ~/ 2;
  final my = height ~/ 2;
  for (final p in image) {
    final c = p.y < my
        ? (p.x < mx ? tl : tr)
        : (p.x < mx ? bl : br);
    p.setRgb(c.r, c.g, c.b);
  }
  return image;
}

/// A checkerboard of [cell]-sized squares alternating between black and white.
Image checkerImage(int width, int height, {int cell = 8}) {
  final image = Image(width: width, height: height);
  for (final p in image) {
    final on = ((p.x ~/ cell) + (p.y ~/ cell)).isEven;
    final v = on ? 255 : 0;
    p.setRgb(v, v, v);
  }
  return image;
}

// ---------------------------------------------------------------------------
// Image statistics.
// ---------------------------------------------------------------------------

/// The mean of the r, g and b channels across every pixel of [image].
double imageMean(Image image) {
  var sum = 0.0;
  var count = 0;
  for (final p in image) {
    sum += p.r + p.g + p.b;
    count += 3;
  }
  return count == 0 ? 0.0 : sum / count;
}

/// The population variance of the r, g and b channels across every pixel.
///
/// This pools all three channels together, so it is 0 only for a uniform
/// *grayscale* image. Use it for relative comparisons -- e.g. blurring a
/// detailed image lowers its variance -- rather than as a uniformity test for
/// colored images.
double imageVariance(Image image) {
  final mean = imageMean(image);
  var sum = 0.0;
  var count = 0;
  for (final p in image) {
    for (final v in [p.r, p.g, p.b]) {
      final d = v - mean;
      sum += d * d;
      count++;
    }
  }
  return count == 0 ? 0.0 : sum / count;
}

// ---------------------------------------------------------------------------
// Assertions.
// ---------------------------------------------------------------------------

/// Expects every pixel of [image] to equal [color].
void expectSolidColor(Image image, Color color, {String? reason}) {
  for (final p in image) {
    final ok = p.r == color.r && p.g == color.g && p.b == color.b;
    expect(ok, isTrue,
        reason: reason ??
            'pixel ${p.x},${p.y} is ($p), expected '
                '(${color.r},${color.g},${color.b})');
  }
}

/// Returns true if [a] and [b] have identical dimensions and pixel values.
bool imagesAreEqual(Image a, Image b) {
  if (a.width != b.width || a.height != b.height) {
    return false;
  }
  final it = b.iterator..moveNext();
  for (final pa in a) {
    if (pa != it.current) {
      return false;
    }
    it.moveNext();
  }
  return true;
}

/// Expects [a] and [b] to have equal dimensions, with every channel value
/// within [tolerance] of the other. Use this for operations whose result is
/// approximately, but not bit-exactly, known.
void expectImagesClose(Image a, Image b, {num tolerance = 1}) {
  expect(b.width, equals(a.width), reason: 'width');
  expect(b.height, equals(a.height), reason: 'height');
  final it = b.iterator..moveNext();
  for (final pa in a) {
    final pb = it.current;
    final n = pa.length < pb.length ? pa.length : pb.length;
    for (var c = 0; c < n; ++c) {
      expect((pa[c] - pb[c]).abs() <= tolerance, isTrue,
          reason: 'channel $c at ${pa.x},${pa.y}: '
              '${pa[c]} vs ${pb[c]} (tolerance $tolerance)');
    }
    it.moveNext();
  }
}
