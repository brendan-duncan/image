import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  group('Filter', () {
    test('contrast', () {
      final bytes = File('test/_data/png/buck_24.png').readAsBytesSync();
      final i0 = decodePng(bytes)!;
      contrast(i0, contrast: 150);
      File('$testOutputPath/filter/contrast.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0));
    });

    test('contrast=100 is a no-op', () {
      // The source short-circuits when contrast == 100.
      final src = quadrantImage(16, 16);
      testImageEquals(contrast(src.clone(), contrast: 100), src);
    });

    test('contrast preserves image dimensions and numChannels', () {
      final src = horizontalGradient(32, 8);
      final out = contrast(src.clone(), contrast: 150);
      expect(out.width, equals(src.width));
      expect(out.height, equals(src.height));
      expect(out.numChannels, equals(src.numChannels));
    });

    test('contrast output channels stay within [0, 255] for uint8', () {
      final src = horizontalGradient(32, 8);
      // Test both low and high contrast values.
      for (final c in [50, 100, 150, 200]) {
        final out = contrast(src.clone(), contrast: c);
        for (final p in out) {
          expect(p.r, inInclusiveRange(0, 255),
              reason: 'r out of range at ${p.x},${p.y} (contrast=$c)');
          expect(p.g, inInclusiveRange(0, 255),
              reason: 'g out of range at ${p.x},${p.y} (contrast=$c)');
          expect(p.b, inInclusiveRange(0, 255),
              reason: 'b out of range at ${p.x},${p.y} (contrast=$c)');
        }
      }
    });

    test('contrast>100 increases variance relative to original', () {
      // Higher contrast should push values away from center, increasing spread.
      final src = horizontalGradient(64, 8);
      final varBefore = imageVariance(src);
      final out = contrast(src.clone(), contrast: 200);
      final varAfter = imageVariance(out);
      expect(varAfter, greaterThanOrEqualTo(varBefore),
          reason: 'contrast>100 should increase or maintain variance');
    });

    test('contrast with all-zero mask leaves image unchanged', () {
      final src = horizontalGradient(32, 8);
      final result = contrast(
        src.clone(),
        contrast: 200,
        mask: solidImage(32, 8, ColorRgb8(0, 0, 0)),
      );
      testImageEquals(result, src);
    });
  });
}
