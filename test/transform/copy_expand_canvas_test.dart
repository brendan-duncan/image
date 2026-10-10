import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

/// Expects [result] to be [width]x[height] with [src] copied exactly at
/// ([x0],[y0]) and every other pixel set to [background].
void _expectPlaced(Image result, Image src, int x0, int y0, Color background,
    {required int width, required int height}) {
  expect(result.width, equals(width), reason: 'width');
  expect(result.height, equals(height), reason: 'height');
  var wrong = 0;
  String? first;
  for (final p in result) {
    final sx = p.x - x0;
    final sy = p.y - y0;
    final inside = sx >= 0 && sy >= 0 && sx < src.width && sy < src.height;
    final Color e = inside ? src.getPixel(sx, sy) : background;
    if (p.r != e.r || p.g != e.g || p.b != e.b) {
      wrong++;
      first ??= '${p.x},${p.y} is $p, expected $e';
    }
  }
  expect(wrong, equals(0), reason: 'first mismatch: $first');
}

void main() {
  group('Transform', () {
    for (ExpandCanvasPosition position in ExpandCanvasPosition.values) {
      test('copyExpandCanvas - $position', () {
        final img = decodePng(
          File('test/_data/png/buck_24.png').readAsBytesSync(),
        )!;

        final expandedCanvas = copyExpandCanvas(
          img,
          newWidth: img.width * 2,
          newHeight: img.height * 2,
          position: position,
          backgroundColor: ColorRgb8(255, 255, 255),
        );

        File('$testOutputPath/transform/copyExpandCanvas_$position.png')
          ..createSync(recursive: true)
          ..writeAsBytesSync(encodePng(expandedCanvas));

        // The free space is img.width (height) on each axis, split 0, 1/2 or
        // all of it before the image depending on the position.
        final (fx, fy) = switch (position) {
          ExpandCanvasPosition.topLeft => (0, 0),
          ExpandCanvasPosition.topCenter => (1, 0),
          ExpandCanvasPosition.topRight => (2, 0),
          ExpandCanvasPosition.centerLeft => (0, 1),
          ExpandCanvasPosition.center => (1, 1),
          ExpandCanvasPosition.centerRight => (2, 1),
          ExpandCanvasPosition.bottomLeft => (0, 2),
          ExpandCanvasPosition.bottomCenter => (1, 2),
          ExpandCanvasPosition.bottomRight => (2, 2),
        };
        _expectPlaced(expandedCanvas, img, img.width * fx ~/ 2,
            img.height * fy ~/ 2, ColorRgb8(255, 255, 255),
            width: img.width * 2, height: img.height * 2);
      });
    }

    // Test with default parameters
    test('copyExpandCanvas - default parameters', () {
      final img = decodePng(
        File('test/_data/png/buck_24.png').readAsBytesSync(),
      )!;

      final expandedCanvas = copyExpandCanvas(
        img,
        newWidth: img.width * 2,
        newHeight: img.height * 2,
      );

      File('$testOutputPath/transform/copyExpandCanvas_default.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(expandedCanvas));

      // Centered by default; with no background color the opaque RGB canvas
      // stays black.
      _expectPlaced(expandedCanvas, img, img.width ~/ 2, img.height ~/ 2,
          ColorRgb8(0, 0, 0),
          width: img.width * 2, height: img.height * 2);
    });

    // Test with toImage parameter
    test('copyExpandCanvas - with toImage', () {
      final img = decodePng(
        File('test/_data/png/buck_24.png').readAsBytesSync(),
      )!;

      final toImage = Image(width: img.width * 2, height: img.height * 2);

      final expandedCanvas = copyExpandCanvas(
        img,
        newWidth: img.width * 2,
        newHeight: img.height * 2,
        toImage: toImage,
      );

      File('$testOutputPath/transform/copyExpandCanvas_toImage.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(expandedCanvas));

      // The result is drawn into toImage rather than a new image.
      expect(identical(expandedCanvas, toImage), isTrue);
      _expectPlaced(expandedCanvas, img, img.width ~/ 2, img.height ~/ 2,
          ColorRgb8(0, 0, 0),
          width: img.width * 2, height: img.height * 2);
    });

    // Test with only padding parameter
    test('copyExpandCanvas - with padding', () {
      final img = decodePng(
        File('test/_data/png/buck_24.png').readAsBytesSync(),
      )!;

      final expandedCanvas = copyExpandCanvas(img, padding: 50);

      File('$testOutputPath/transform/copyExpandCanvas_padding.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(expandedCanvas));

      // 50 pixels of black padding on every side.
      _expectPlaced(expandedCanvas, img, 50, 50, ColorRgb8(0, 0, 0),
          width: img.width + 100, height: img.height + 100);
    });

    // Test with both new dimensions and padding parameters
    test('copyExpandCanvas - with new dimensions and padding', () {
      final img = decodePng(
        File('test/_data/png/buck_24.png').readAsBytesSync(),
      )!;

      expect(
        () => copyExpandCanvas(
          img,
          newWidth: img.width * 2,
          newHeight: img.height * 2,
          padding: 50,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('copyExpandCanvas - alpha image', () {
      final img = decodePng(
        File('test/_data/png/alpha.png').readAsBytesSync(),
      )!;

      final expandedCanvas = copyExpandCanvas(
        img,
        newWidth: img.width * 2,
        newHeight: img.height * 2,
        backgroundColor: ColorRgb8(255, 255, 255),
      );
      File('$testOutputPath/transform/copyExpandCanvas_alpha.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(expandedCanvas));

      // The image is centered and alpha blended over the white background,
      // so transparent pixels show white and the whole canvas is opaque.
      expect(expandedCanvas.width, equals(img.width * 2));
      expect(expandedCanvas.height, equals(img.height * 2));
      final x0 = img.width ~/ 2;
      final y0 = img.height ~/ 2;
      var partial = 0;
      for (final p in expandedCanvas) {
        final sx = p.x - x0;
        final sy = p.y - y0;
        expect(p.a, equals(255), reason: 'alpha at ${p.x},${p.y}');
        if (sx < 0 || sy < 0 || sx >= img.width || sy >= img.height) {
          expect(p, equals([255, 255, 255, 255]),
              reason: 'background at ${p.x},${p.y}');
          continue;
        }
        final s = img.getPixel(sx, sy);
        final a = s.aNormalized;
        if (a > 0 && a < 1) {
          partial++;
        }
        for (var c = 0; c < 3; ++c) {
          expect(p[c], closeTo(s[c] * a + 255 * (1 - a), 1),
              reason: 'channel $c at ${p.x},${p.y}');
        }
      }
      // The test image does have partially transparent pixels to blend.
      expect(partial, greaterThan(0));
    });

    test('copyExpandCanvas preserves source RGBA and transparent padding', () {
      final src = Image(width: 4, height: 4, numChannels: 4)
        ..clear(ColorRgba8(255, 0, 0, 128));
      final result = copyExpandCanvas(src, padding: 2);
      expect(result.numChannels, equals(4));
      expect(result.getPixel(0, 0).a, equals(0));
      final p = result.getPixel(2, 2);
      expect([p.r, p.g, p.b, p.a], equals([255, 0, 0, 128]));
    });

    // EXIF metadata should survive a canvas expansion.
    test('copyExpandCanvas preserves EXIF metadata', () {
      final img = Image(width: 16, height: 16);
      img.exif.imageIfd.orientation = 6;

      final expanded = copyExpandCanvas(img, padding: 8);

      expect(expanded.hasExif, isTrue);
      expect(expanded.exif.imageIfd.orientation, equals(6));
    });

    // The expanded canvas is larger than the source.
    test('result dimensions are larger than the source', () {
      final src = solidImage(20, 20, ColorRgb8(100, 150, 200));
      final result = copyExpandCanvas(src,
          newWidth: 40, newHeight: 50, backgroundColor: ColorRgb8(0, 0, 0));
      expect(result.width, equals(40));
      expect(result.height, equals(50));
    });

    // Padding mode: result dimensions equal src + 2*padding on each axis.
    test('padding mode produces correct dimensions', () {
      final src = solidImage(10, 10, ColorRgb8(255, 0, 0));
      const pad = 5;
      final result = copyExpandCanvas(src,
          padding: pad, backgroundColor: ColorRgb8(0, 0, 0));
      expect(result.width, equals(10 + pad * 2));
      expect(result.height, equals(10 + pad * 2));
    });

    // Background color fills the border area when the source is placed at
    // topLeft — the pixels to the right and below are the background color.
    test('background color fills the border area', () {
      final src = solidImage(4, 4, ColorRgb8(255, 0, 0));
      final bg = ColorRgb8(0, 0, 255);
      final result = copyExpandCanvas(
        src,
        newWidth: 8,
        newHeight: 8,
        position: ExpandCanvasPosition.topLeft,
        backgroundColor: bg,
      );
      // Pixel just outside the source region should be the background color.
      final p = result.getPixel(7, 7);
      expect(p.r, equals(0));
      expect(p.g, equals(0));
      expect(p.b, equals(255));
    });

    // The original image content is reproduced at its placement offset.
    // With topLeft placement the source starts at (0,0) in the result.
    test('source content preserved at placement offset (topLeft)', () {
      final src = quadrantImage(8, 8);
      final result = copyExpandCanvas(
        src,
        newWidth: 16,
        newHeight: 16,
        position: ExpandCanvasPosition.topLeft,
        backgroundColor: ColorRgb8(128, 128, 128),
      );
      // Top-left pixel of source (red quadrant) must appear at (0,0).
      final p = result.getPixel(0, 0);
      expect(p.r, equals(255));
      expect(p.g, equals(0));
      expect(p.b, equals(0));
    });

    // copyExpandCanvas does not mutate the source image.
    test('copyExpandCanvas does not mutate source', () {
      final src = solidImage(8, 8, ColorRgb8(200, 100, 50));
      final orig = src.clone();
      copyExpandCanvas(src, padding: 4, backgroundColor: ColorRgb8(0, 0, 0));
      testImageEquals(src, orig);
    });
  });
}
