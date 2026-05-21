import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  group('Transform', () {
    test('trim', () {
      final image = decodePng(
        File('test/_data/png/logo.png').readAsBytesSync(),
      )!;
      var trimmed = trim(image);
      File('$testOutputPath/transform/trim.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(trimmed));
      expect(trimmed.width, equals(465));
      expect(trimmed.height, equals(150));

      trimmed = trim(image, mode: TrimMode.transparent);
      File('$testOutputPath/transform/trim_transparent.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(trimmed));
      expect(trimmed.width, 465);
      expect(trimmed.height, equals(image.height));

      trimmed = trim(image, mode: TrimMode.bottomRightColor);
      File('$testOutputPath/transform/trim_bottomRightColor.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(trimmed));
      expect(trimmed.width, 465);
      expect(trimmed.height, 150);
    });

    // trim removes a uniform border: the result dimensions equal the
    // inner block that differs from the border colour.
    test('trim removes known solid border', () {
      // Build a 20x20 image filled with white, then paint a 10x10 red block
      // at (5,5).  Trimming by topLeftColor (white) should yield 10x10.
      final img = solidImage(20, 20, ColorRgb8(255, 255, 255));
      for (var y = 5; y < 15; y++) {
        for (var x = 5; x < 15; x++) {
          img.setPixelRgb(x, y, 255, 0, 0);
        }
      }
      final trimmed = trim(img);
      expect(trimmed.width, equals(10),
          reason: 'trimmed width should equal inner block width');
      expect(trimmed.height, equals(10),
          reason: 'trimmed height should equal inner block height');
    });

    // After trimming, the content of the result matches the inner block.
    test('trimmed image content matches inner block', () {
      final img = solidImage(20, 20, ColorRgb8(0, 0, 0));
      for (var y = 4; y < 14; y++) {
        for (var x = 3; x < 13; x++) {
          img.setPixelRgb(x, y, 0, 200, 100);
        }
      }
      final trimmed = trim(img);
      // Every pixel in the result should be the inner colour.
      expectSolidColor(trimmed, ColorRgb8(0, 200, 100));
    });

    // trim does not mutate the source image.
    test('trim does not mutate source', () {
      final src = solidImage(16, 16, ColorRgb8(255, 255, 255));
      for (var y = 4; y < 12; y++) {
        for (var x = 4; x < 12; x++) {
          src.setPixelRgb(x, y, 100, 100, 100);
        }
      }
      final orig = src.clone();
      trim(src);
      testImageEquals(src, orig);
    });

    // Trimming an image that is already uniform returns the full image.
    test('trim of uniform image returns original size', () {
      final src = solidImage(10, 10, ColorRgb8(128, 128, 128));
      final trimmed = trim(src);
      expect(trimmed.width, equals(10));
      expect(trimmed.height, equals(10));
    });

    // Trimming with bottomRightColor uses the bottom-right pixel as the border.
    test('trim bottomRightColor removes border matching bottom-right pixel',
        () {
      // Fill with green, paint a 6x6 blue block at (2,2).
      // Bottom-right pixel is green → green border is trimmed.
      final img = solidImage(12, 12, ColorRgb8(0, 255, 0));
      for (var y = 2; y < 8; y++) {
        for (var x = 2; x < 8; x++) {
          img.setPixelRgb(x, y, 0, 0, 255);
        }
      }
      final trimmed = trim(img, mode: TrimMode.bottomRightColor);
      expect(trimmed.width, equals(6));
      expect(trimmed.height, equals(6));
    });
  });
}
