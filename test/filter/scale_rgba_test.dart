import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  group('Filter', () {
    test('scaleRgba', () {
      final bytes = File('test/_data/png/buck_24.png').readAsBytesSync();
      final i0 = decodePng(bytes)!;
      scaleRgba(i0, scale: ColorRgb8(128, 128, 128));
      File('$testOutputPath/filter/scaleRgba.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0));
    });

    test('scaleRgba preserves image dimensions and numChannels', () {
      final src = horizontalGradient(32, 8);
      final out = scaleRgba(src.clone(), scale: ColorRgb8(128, 128, 128));
      expect(out.width, equals(src.width));
      expect(out.height, equals(src.height));
      expect(out.numChannels, equals(src.numChannels));
    });

    test('scaleRgba with white scale (255,255,255) is a no-op', () {
      // scale normalized = 1.0 for each channel → multiply by 1 → unchanged.
      final src = quadrantImage(16, 16);
      testImageEquals(
          scaleRgba(src.clone(), scale: ColorRgb8(255, 255, 255)), src);
    });

    test('scaleRgba with black scale (0,0,0) produces a black image', () {
      // scale normalized = 0.0 → every channel * 0 = 0.
      final src = horizontalGradient(16, 8);
      expectSolidColor(scaleRgba(src.clone(), scale: ColorRgb8(0, 0, 0)),
          ColorRgb8(0, 0, 0));
    });

    test('scaleRgba with 50% scale halves channel values', () {
      // scale=128 → normalized ≈ 0.502; original=200 → result ≈ 100 (±2).
      final src = solidImage(8, 8, ColorRgb8(200, 200, 200));
      final out = scaleRgba(src.clone(), scale: ColorRgb8(128, 128, 128));
      final p = out.getPixel(0, 0);
      // 200 * (128/255) ≈ 100.4
      expect(p.r, closeTo(100, 2));
      expect(p.g, closeTo(100, 2));
      expect(p.b, closeTo(100, 2));
    });

    test('scaleRgba output channels stay within [0, 255] for uint8', () {
      final src = horizontalGradient(32, 8);
      final out = scaleRgba(src.clone(), scale: ColorRgb8(128, 200, 64));
      for (final p in out) {
        expect(p.r, inInclusiveRange(0, 255));
        expect(p.g, inInclusiveRange(0, 255));
        expect(p.b, inInclusiveRange(0, 255));
      }
    });

    test('scaleRgba with all-zero mask leaves the image unchanged', () {
      final src = horizontalGradient(32, 8);
      final result = scaleRgba(
        src.clone(),
        scale: ColorRgb8(128, 128, 128),
        mask: solidImage(32, 8, ColorRgb8(0, 0, 0)),
      );
      testImageEquals(result, src);
    });
  });
}
