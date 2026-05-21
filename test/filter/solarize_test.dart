import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  group('Filter', () {
    test('solarize highlights', () {
      final bytes = File('test/_data/png/buck_24.png').readAsBytesSync();
      final i0 = decodePng(bytes)!;
      solarize(i0, threshold: 100);
      File('$testOutputPath/filter/solarize_highlights.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0));
    });

    test('solarize shadows', () {
      final bytes = File('test/_data/png/buck_24.png').readAsBytesSync();
      final i0 = decodePng(bytes)!;
      solarize(i0, threshold: 100, mode: SolarizeMode.shadows);
      File('$testOutputPath/filter/solarize_shadows.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0));
    });

    test('solarize preserves image dimensions and numChannels', () {
      final src = horizontalGradient(32, 8);
      final out = solarize(src.clone(), threshold: 100);
      expect(out.width, equals(src.width));
      expect(out.height, equals(src.height));
      expect(out.numChannels, equals(src.numChannels));
    });

    test('solarize output channels stay within [0, 255] for uint8', () {
      final src = horizontalGradient(32, 8);
      for (final mode in [SolarizeMode.highlights, SolarizeMode.shadows]) {
        final out = solarize(src.clone(), threshold: 128, mode: mode);
        for (final p in out) {
          expect(p.r, inInclusiveRange(0, 255),
              reason: 'r out of range at ${p.x},${p.y} (mode=$mode)');
          expect(p.g, inInclusiveRange(0, 255),
              reason: 'g out of range at ${p.x},${p.y} (mode=$mode)');
          expect(p.b, inInclusiveRange(0, 255),
              reason: 'b out of range at ${p.x},${p.y} (mode=$mode)');
        }
      }
    });

    test(
        'solarize highlights: solid color below threshold '
        'is unchanged in value', () {
      // A solid gray below threshold (g <= thresholdRange) should NOT be
      // inverted by highlights mode. After the rescale step the values are
      // normalized to the min/max range — but a solid image stays solid.
      // Use a value well below a threshold of 200 (thresholdRange ~200).
      final src = solidImage(8, 8, ColorRgb8(50, 50, 50));
      final out = solarize(src.clone(), threshold: 200);
      // Every output pixel should still be equal to each other (uniform).
      final first = out.getPixel(0, 0);
      for (final p in out) {
        expect(p.r, equals(first.r),
            reason: 'uniform output expected at ${p.x},${p.y}');
        expect(p.g, equals(first.g),
            reason: 'uniform output expected at ${p.x},${p.y}');
        expect(p.b, equals(first.b),
            reason: 'uniform output expected at ${p.x},${p.y}');
      }
    });

    test(
        'solarize highlights: solid color above threshold inverts all channels',
        () {
      // With threshold=10, thresholdRange = round(255 * 10/255) = 10.
      // A solid white image (g=255 > 10) will be inverted to black (0,0,0),
      // then the rescale step finds min==max and returns early → stays 0,0,0.
      // Actually: after inversion the solid image has all values = 0.
      // minMax returns [0,0], mn==mx → rescale is skipped.
      final white = solidImage(8, 8, ColorRgb8(255, 255, 255));
      final out = solarize(white.clone(), threshold: 10);
      // All pixels inverted: 255-255=0; minMax=[0,0]; no rescale.
      expectSolidColor(out, ColorRgb8(0, 0, 0));
    });
  });
}
