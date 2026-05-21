import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

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
