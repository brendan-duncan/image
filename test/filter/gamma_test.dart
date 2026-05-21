import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  group('Filter', () {
    test('gamma', () {
      final bytes = File('test/_data/png/buck_24.png').readAsBytesSync();
      final i0 = decodePng(bytes)!;
      gamma(i0, gamma: 2.2);
      File('$testOutputPath/filter/gamma.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0));
    });

    test('gamma=1 is a no-op', () {
      // pow(x, 1) == x for all x, so gamma=1 leaves the image unchanged.
      final src = quadrantImage(16, 16);
      testImageEquals(gamma(src.clone(), gamma: 1), src);
    });

    test('gamma preserves image dimensions and numChannels', () {
      final src = horizontalGradient(32, 8);
      final out = gamma(src.clone(), gamma: 2.2);
      expect(out.width, equals(src.width));
      expect(out.height, equals(src.height));
      expect(out.numChannels, equals(src.numChannels));
    });

    test('gamma output channels stay within [0, 255] for uint8', () {
      final src = horizontalGradient(32, 8);
      final out = gamma(src.clone(), gamma: 2.2);
      for (final p in out) {
        expect(p.r, inInclusiveRange(0, 255));
        expect(p.g, inInclusiveRange(0, 255));
        expect(p.b, inInclusiveRange(0, 255));
      }
    });

    test('gamma preserves pure black and pure white', () {
      // pow(0, gamma) == 0 and pow(1, gamma) == 1 for any positive gamma.
      final black = solidImage(4, 4, ColorRgb8(0, 0, 0));
      expectSolidColor(gamma(black, gamma: 2.2), ColorRgb8(0, 0, 0));

      final white = solidImage(4, 4, ColorRgb8(255, 255, 255));
      // pow(1.0, gamma) == 1.0, which rounds back to 255.
      expectSolidColor(gamma(white, gamma: 2.2), ColorRgb8(255, 255, 255));
    });

    test('gamma>1 darkens a mid-gray image', () {
      // pow(0.5, 2.2) < 0.5, so the mean should decrease.
      final src = solidImage(16, 16, ColorRgb8(128, 128, 128));
      final meanBefore = imageMean(src);
      final out = gamma(src.clone(), gamma: 2.2);
      expect(imageMean(out), lessThan(meanBefore));
    });

    test('gamma<1 brightens a mid-gray image', () {
      // pow(0.5, 0.5) > 0.5, so the mean should increase.
      final src = solidImage(16, 16, ColorRgb8(128, 128, 128));
      final meanBefore = imageMean(src);
      final out = gamma(src.clone(), gamma: 0.5);
      expect(imageMean(out), greaterThan(meanBefore));
    });

    test('gamma with all-zero mask leaves the image unchanged', () {
      final src = horizontalGradient(32, 8);
      final result = gamma(
        src.clone(),
        gamma: 2.2,
        mask: solidImage(32, 8, ColorRgb8(0, 0, 0)),
      );
      testImageEquals(result, src);
    });
  });
}
