import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  group('Filter', () {
    test('dotScreen preserves dimensions', () {
      final src = solidImage(32, 32, ColorRgb8(180, 180, 180));
      final result = dotScreen(src.clone());
      // The dot-screen stylization must not resize the image.
      expect(result.width, equals(32));
      expect(result.height, equals(32));
    });

    test('dotScreen returns the src image', () {
      final src = solidImage(16, 16, ColorRgb8(100, 100, 100));
      final result = dotScreen(src);
      expect(identical(result, src), isTrue);
    });

    test('dotScreen with amount 0 leaves image unchanged', () {
      // amount==0 means mx==0, so mix(p, pattern, 0)==p.
      final src = horizontalGradient(32, 32);
      final orig = src.clone();
      dotScreen(src, amount: 0);
      testImageEquals(src, orig);
    });

    test('dotScreen output values stay within channel range', () {
      // Channel values must remain within [0, maxChannelValue].
      final src = quadrantImage(32, 32);
      dotScreen(src);
      for (final p in src) {
        expect(p.r, greaterThanOrEqualTo(0));
        expect(p.r, lessThanOrEqualTo(p.maxChannelValue));
        expect(p.g, greaterThanOrEqualTo(0));
        expect(p.g, lessThanOrEqualTo(p.maxChannelValue));
        expect(p.b, greaterThanOrEqualTo(0));
        expect(p.b, lessThanOrEqualTo(p.maxChannelValue));
      }
    });

    test('dotScreen', () async {
      final bytes = File('test/_data/png/buck_24.png').readAsBytesSync();
      final img = decodePng(bytes)!;
      final i0 = img.clone();
      dotScreen(i0);
      File('$testOutputPath/filter/dotScreen.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0));

      expect(i0.width, equals(img.width));
      expect(i0.height, equals(img.height));
      // The screen is a gray pattern thresholded from the luminance, so the
      // result is gray and mostly pure black or white.
      var saturated = 0;
      for (final p in i0) {
        expect(p.g, equals(p.r), reason: 'g at ${p.x},${p.y}');
        expect(p.b, equals(p.r), reason: 'b at ${p.x},${p.y}');
        if (p.r == 0 || p.r == 255) {
          saturated++;
        }
      }
      expect(saturated, greaterThan(i0.width * i0.height * 0.6));
      // Dark source areas get less white than light ones.
      var darkSum = 0.0;
      var darkCount = 0;
      var lightSum = 0.0;
      var lightCount = 0;
      for (final p in i0) {
        final l = img.getPixel(p.x, p.y).luminance;
        if (l < 64) {
          darkSum += p.r;
          darkCount++;
        } else if (l > 192) {
          lightSum += p.r;
          lightCount++;
        }
      }
      expect(darkCount, greaterThan(0));
      expect(lightCount, greaterThan(0));
      expect(darkSum / darkCount + 100, lessThan(lightSum / lightCount));

      final mask = Command()
        ..createImage(width: img.width, height: img.height)
        ..fill(color: ColorRgb8(0, 0, 0))
        ..fillCircle(
          x: img.width ~/ 2,
          y: img.height ~/ 2,
          radius: 80,
          color: ColorRgb8(255, 255, 255),
        )
        ..gaussianBlur(radius: 20);

      final masked = (await (Command()
            ..image(img)
            ..copy()
            ..dotScreen(mask: mask)
            ..writeToFile('$testOutputPath/filter/dotScreen_mask.png'))
          .getImage())!;

      // The mask is white in a circle of radius 80 at the center, softened by
      // the blur, and black elsewhere: the center gets the full effect and
      // the area well outside the circle is untouched.
      final cx = img.width ~/ 2;
      final cy = img.height ~/ 2;
      var outside = 0;
      var center = 0;
      for (final p in masked) {
        final dx = p.x - cx;
        final dy = p.y - cy;
        final d2 = dx * dx + dy * dy;
        if (d2 > 110 * 110) {
          expect(p, equals(img.getPixel(p.x, p.y)),
              reason: 'outside mask at ${p.x},${p.y}');
          outside++;
        } else if (d2 < 50 * 50) {
          // The blurred mask is nearly, not exactly, 1 here.
          final full = i0.getPixel(p.x, p.y);
          for (var c = 0; c < 3; ++c) {
            expect(p[c], closeTo(full[c], 2),
                reason: 'inside mask at ${p.x},${p.y}');
          }
          center++;
        }
      }
      expect(outside, greaterThan(0));
      expect(center, greaterThan(0));
      expect(imagesAreEqual(masked, img), isFalse);
    });
  });
}
