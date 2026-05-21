import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  group('Filter', () {
    test('bleachBypass', () {
      final bytes = File('test/_data/png/buck_24.png').readAsBytesSync();
      final i0 = decodePng(bytes)!;
      final original = i0.clone();
      bleachBypass(i0);
      File('$testOutputPath/filter/bleachBypass.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0));

      // The filter preserves the image dimensions and channel count.
      expect(i0.width, equals(original.width));
      expect(i0.height, equals(original.height));
      expect(i0.numChannels, equals(original.numChannels));
      // It mutates and returns the source image.
      expect(identical(bleachBypass(i0), i0), isTrue);
    });

    test('bleachBypass with amount 0 leaves the image unchanged', () {
      final src = horizontalGradient(32, 8);
      testImageEquals(bleachBypass(src.clone(), amount: 0), src);
    });

    test('bleachBypass keeps a uniform image uniform', () {
      // Every pixel is processed identically, so a solid input stays solid.
      final result = bleachBypass(solidImage(16, 16, ColorRgb8(180, 90, 60)));
      final first = result.getPixel(0, 0);
      final expected =
          ColorRgb8(first.r.toInt(), first.g.toInt(), first.b.toInt());
      expectSolidColor(result, expected);
    });
  });
}
