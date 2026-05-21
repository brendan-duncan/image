import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  group('Filter', () {
    test('adjustColor', () {
      final bytes = File('test/_data/png/buck_24.png').readAsBytesSync();
      final i0 = decodePng(bytes)!;
      adjustColor(i0, gamma: 2.2);
      File('$testOutputPath/filter/adjustColor.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0));

      // adjustColor preserves image dimensions.
      expect(i0.width, equals(decodePng(bytes)!.width));
      expect(i0.height, equals(decodePng(bytes)!.height));
    });

    test('adjustColor with amount=0 leaves the image unchanged', () {
      final src = quadrantImage(16, 16);
      // amount=0 is documented to be a no-op.
      testImageEquals(adjustColor(src.clone(), amount: 0), src);
    });

    test('adjustColor preserves dimensions', () {
      final src = horizontalGradient(20, 10);
      final out = adjustColor(src.clone(), brightness: 1.5);
      expect(out.width, equals(src.width));
      expect(out.height, equals(src.height));
      expect(out.numChannels, equals(src.numChannels));
    });

    test('adjustColor output channels stay within [0, 255] for uint8', () {
      final src = horizontalGradient(32, 8);
      final out = adjustColor(src.clone(), gamma: 2.2, brightness: 1.5);
      for (final p in out) {
        // Channel values for uint8 images must be in [0, 255].
        expect(p.r, inInclusiveRange(0, 255));
        expect(p.g, inInclusiveRange(0, 255));
        expect(p.b, inInclusiveRange(0, 255));
      }
    });

    test('adjustColor brightness=0 produces a black image', () {
      final src = horizontalGradient(16, 8);
      final out = adjustColor(src.clone(), brightness: 0);
      // brightness=0 multiplies every channel by 0 → all black.
      expectSolidColor(out, ColorRgb8(0, 0, 0));
    });

    test('adjustColor contrast=1 (neutral) leaves the image unchanged', () {
      // In adjustColor, contrast is a [0,2] scalar where 1.0 is neutral.
      final src = quadrantImage(16, 16);
      testImageEquals(adjustColor(src.clone(), contrast: 1.0), src);
    });

    test('adjustColor saturation=0 produces a grayscale image', () {
      // saturation=0 should desaturate (push toward gray luma).
      final src = quadrantImage(16, 16);
      final out = adjustColor(src.clone(), saturation: 0);
      for (final p in out) {
        // After full desaturation every pixel should have equal r, g, b.
        expect(p.r, equals(p.g),
            reason: 'r==g at ${p.x},${p.y} after saturation=0');
        expect(p.g, equals(p.b),
            reason: 'g==b at ${p.x},${p.y} after saturation=0');
      }
    });
  });
}
