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

      await (Command()
            ..image(img)
            ..copy()
            ..dotScreen(mask: mask)
            ..writeToFile('$testOutputPath/filter/dotScreen_mask.png'))
          .execute();
    });
  });
}
