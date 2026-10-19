import 'dart:io';

import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

/// A small RGB image with varied colors, so filters have something to do.
Image _colorImage({int numChannels = 3}) {
  final image = Image(width: 24, height: 16, numChannels: numChannels);
  for (final p in image) {
    p
      ..r = (p.x * 255 / 23).round()
      ..g = (p.y * 255 / 15).round()
      ..b = ((p.x + p.y) * 7) % 256;
    if (numChannels == 4) {
      p.a = 255;
    }
  }
  return image;
}

/// A 10x8 solid center on a near-black, slightly noisy 20x20 background,
/// for trim tests. Only a fuzzy trim sees the background as uniform.
Image _trimImage() {
  final image = Image(width: 20, height: 20);
  for (final p in image) {
    final inside = p.x >= 5 && p.x < 15 && p.y >= 6 && p.y < 14;
    if (inside) {
      p.setRgb(200, 100, 50);
    } else {
      final v = (p.x + p.y) % 3;
      p.setRgb(v, v, v);
    }
  }
  return image;
}

class _ThrowStringCmd extends Command {
  _ThrowStringCmd() : super(null);

  @override
  Future<void> executeCommand() async {
    // Deliberately throw a non-Error, non-Exception object.
    // ignore: only_throw_errors
    throw 'command failed';
  }
}

void main() {
  group('Command parameters', () {
    // Skipped: contrast() with ContrastMode.scurve never builds its lookup
    // table (the scurve branch is nested inside the proportional branch in
    // lib/src/filter/contrast.dart), so the function itself fails.
    test('contrast mode', () async {
      final cmd = await (Command()
            ..image(_colorImage())
            ..contrast(contrast: 150, mode: ContrastMode.scurve))
          .getImage();
      final direct =
          contrast(_colorImage(), contrast: 150, mode: ContrastMode.scurve);
      testImageEquals(cmd!, direct);
    });

    test('pixelate amount', () async {
      final cmd = await (Command()
            ..image(_colorImage())
            ..pixelate(size: 4, amount: 0.5))
          .getImage();
      final direct = pixelate(_colorImage(), size: 4, amount: 0.5);
      testImageEquals(cmd!, direct);
    });

    test('quantize ditherStrength', () async {
      final cmd = await (Command()
            ..image(_colorImage())
            ..quantize(
                numberOfColors: 8,
                method: QuantizeMethod.octree,
                dither: DitherKernel.floydSteinberg,
                ditherStrength: 0.5))
          .getImage();
      final direct = quantize(_colorImage(),
          numberOfColors: 8,
          method: QuantizeMethod.octree,
          dither: DitherKernel.floydSteinberg,
          ditherStrength: 0.5);
      testImageEquals(cmd!, direct);
    });

    test('trim fuzzy', () async {
      final cmd = await (Command()
            ..image(_trimImage())
            ..trim(mode: TrimMode.topLeftColor, fuzzy: 0.05))
          .getImage();
      final direct = trim(_trimImage(), fuzzy: 0.05);
      expect(cmd!.width, equals(10));
      testImageEquals(cmd, direct);
    });

    test('trim padding', () async {
      final cmd = await (Command()
            ..image(_trimImage())
            ..trim(mode: TrimMode.topLeftColor, fuzzy: 0.05, padding: 2))
          .getImage();
      final direct = trim(_trimImage(), fuzzy: 0.05, padding: 2);
      expect(cmd!.width, equals(14));
      testImageEquals(cmd, direct);
    });

    final vertices = [Point(2, 2), Point(20, 4), Point(12, 14)];
    final polyColor = ColorRgb8(255, 0, 0);

    test('drawPolygon antialias', () async {
      final cmd = await (Command()
            ..image(_colorImage())
            ..drawPolygon(
                vertices: vertices, color: polyColor, antialias: true))
          .getImage();
      final direct = drawPolygon(_colorImage(),
          vertices: vertices, color: polyColor, antialias: true);
      testImageEquals(cmd!, direct);
    });

    test('drawPolygon thickness', () async {
      final cmd = await (Command()
            ..image(_colorImage())
            ..drawPolygon(vertices: vertices, color: polyColor, thickness: 3))
          .getImage();
      final direct = drawPolygon(_colorImage(),
          vertices: vertices, color: polyColor, thickness: 3);
      testImageEquals(cmd!, direct);
    });

    test('drawPixel filter', () async {
      final filter = ColorRgb8(128, 255, 64);
      final cmd = await (Command()
            ..image(_colorImage())
            ..drawPixel(5, 5, ColorRgb8(200, 200, 200), filter: filter))
          .getImage();
      final direct = drawPixel(_colorImage(), 5, 5, ColorRgb8(200, 200, 200),
          filter: filter);
      testImageEquals(cmd!, direct);
    });

    test('drawPixel alpha', () async {
      final cmd = await (Command()
            ..image(_colorImage())
            ..drawPixel(5, 5, ColorRgb8(200, 200, 200), alpha: 0.25))
          .getImage();
      final direct =
          drawPixel(_colorImage(), 5, 5, ColorRgb8(200, 200, 200), alpha: 0.25);
      testImageEquals(cmd!, direct);
    });

    test('fillRect alphaBlend', () async {
      final color = ColorRgba8(255, 0, 0, 100);
      final cmd = await (Command()
            ..image(_colorImage(numChannels: 4))
            ..fillRect(
                x1: 2, y1: 2, x2: 12, y2: 10, color: color, alphaBlend: false))
          .getImage();
      final direct = fillRect(_colorImage(numChannels: 4),
          x1: 2, y1: 2, x2: 12, y2: 10, color: color, alphaBlend: false);
      // Without alpha blending the color is written as-is.
      expect(cmd!.getPixel(5, 5).a, equals(100));
      testImageEquals(cmd, direct);
    });

    final jpgBytes = File('test/_data/jpg/buck_24.jpg').readAsBytesSync();

    test('decodeJpg scale', () async {
      final cmd = await (Command()..decodeJpg(jpgBytes, scale: 2)).getImage();
      final direct = decodeJpg(jpgBytes, scale: 2);
      final full = decodeJpg(jpgBytes);
      expect(cmd!.width, lessThan(full!.width));
      testImageEquals(cmd, direct!);
    });

    test('decodeJpg maxPixels', () async {
      final full = decodeJpg(jpgBytes)!;
      final limit = full.width * full.height - 1;
      // Both the function and the command reject the oversized image.
      expect(() => decodeJpg(jpgBytes, maxPixels: limit),
          throwsA(isA<ImageException>()));
      await expectLater(
          (Command()..decodeJpg(jpgBytes, maxPixels: limit)).getImage(),
          throwsA(isA<ImageException>()));
      final allowed = await (Command()
            ..decodeJpg(jpgBytes, maxPixels: full.width * full.height))
          .getImage();
      expect(allowed, isNotNull);
    });

    test('ditherImage default scan order matches the function', () async {
      final src = _colorImage();
      final quantizer = OctreeQuantizer(src, numberOfColors: 8);
      final cmd = await (Command()
            ..image(_colorImage())
            ..ditherImage(quantizer: quantizer))
          .getImage();
      final direct = ditherImage(_colorImage(), quantizer: quantizer);
      testImageEquals(cmd!, direct);

      // The deprecated serpentine flag is still honored.
      final cmdSerpentine = await (Command()
            ..image(_colorImage())
            ..ditherImage(quantizer: quantizer, serpentine: true))
          .getImage();
      final directSerpentine = ditherImage(_colorImage(),
          quantizer: quantizer, scanOrder: DitherScanOrder.serpentine);
      testImageEquals(cmdSerpentine!, directSerpentine);
    });

    test('executeThread rethrows non-Exception objects', () async {
      await expectLater(
          _ThrowStringCmd().executeThread(), throwsA(equals('command failed')));
    });
  });
}
