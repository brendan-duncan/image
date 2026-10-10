import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  group('Filter', () {
    test('colorHalftone', () {
      final bytes = File('test/_data/png/buck_24.png').readAsBytesSync();
      final i0 = decodePng(bytes)!;
      final orig = i0.clone();
      colorHalftone(i0);
      File('$testOutputPath/filter/colorHalftone.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0));

      expect(i0.width, equals(orig.width));
      expect(i0.height, equals(orig.height));

      // Halftoning thresholds each ink into dots, so most channel values end
      // up fully on or off, unlike the continuous-tone source.
      int saturated(Image img) {
        var n = 0;
        for (final p in img) {
          for (final v in [p.r, p.g, p.b]) {
            if (v == 0 || v == 255) {
              n++;
            }
          }
        }
        return n;
      }

      final total = i0.width * i0.height * 3;
      expect(saturated(i0), greaterThan(total * 0.6));
      expect(saturated(orig), lessThan(total * 0.1));

      // The dots still follow the tone: dark source areas stay darker than
      // light ones.
      var darkSum = 0.0;
      var darkCount = 0;
      var lightSum = 0.0;
      var lightCount = 0;
      for (final p in i0) {
        final l = orig.getPixel(p.x, p.y).luminance;
        if (l < 64) {
          darkSum += p.luminance;
          darkCount++;
        } else if (l > 192) {
          lightSum += p.luminance;
          lightCount++;
        }
      }
      expect(darkCount, greaterThan(0));
      expect(lightCount, greaterThan(0));
      expect(darkSum / darkCount + 50, lessThan(lightSum / lightCount));
    });

    test('colorHalftone preserves dimensions', () {
      final src = solidImage(32, 32, ColorRgb8(200, 100, 50));
      final result = colorHalftone(src.clone());
      // The halftone stylization must not resize the image.
      expect(result.width, equals(32));
      expect(result.height, equals(32));
    });

    test('colorHalftone returns the src image', () {
      final src = solidImage(16, 16, ColorRgb8(100, 150, 200));
      final result = colorHalftone(src);
      expect(identical(result, src), isTrue);
    });

    test('colorHalftone with amount 0 leaves image unchanged', () {
      // amount==0 means mx==0, so mix(p, newColor, 0)==p.
      final src = horizontalGradient(32, 32);
      final orig = src.clone();
      colorHalftone(src, amount: 0);
      testImageEquals(src, orig);
    });

    test('colorHalftone output values stay within channel range', () {
      // Channel values must remain within [0, maxChannelValue].
      final src = quadrantImage(32, 32);
      colorHalftone(src);
      for (final p in src) {
        expect(p.r, greaterThanOrEqualTo(0));
        expect(p.r, lessThanOrEqualTo(p.maxChannelValue));
        expect(p.g, greaterThanOrEqualTo(0));
        expect(p.g, lessThanOrEqualTo(p.maxChannelValue));
        expect(p.b, greaterThanOrEqualTo(0));
        expect(p.b, lessThanOrEqualTo(p.maxChannelValue));
      }
    });
  });
}
