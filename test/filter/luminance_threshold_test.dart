import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  group('Filter', () {
    test('luminanceThreshold', () {
      final bytes = File('test/_data/png/buck_24.png').readAsBytesSync();
      final i0 = decodePng(bytes)!;
      luminanceThreshold(i0);
      File('$testOutputPath/filter/luminanceThreshold.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0));
    });

    test('luminanceThreshold preserves image dimensions and numChannels', () {
      final src = horizontalGradient(32, 8);
      final out = luminanceThreshold(src.clone());
      expect(out.width, equals(src.width));
      expect(out.height, equals(src.height));
      expect(out.numChannels, equals(src.numChannels));
    });

    test('luminanceThreshold (binary) produces only black or white pixels', () {
      // With outputColor=false (default) each pixel becomes either 0 or
      // maxChannelValue (255 for uint8).
      final src = horizontalGradient(32, 8);
      // threshold=0.5 is the default but named explicitly for clarity.
      final out = luminanceThreshold(src.clone());
      for (final p in out) {
        expect(p.r == 0 || p.r == 255, isTrue,
            reason: 'r=${p.r} at ${p.x},${p.y} not 0 or 255');
        expect(p.g == 0 || p.g == 255, isTrue,
            reason: 'g=${p.g} at ${p.x},${p.y} is not 0 or 255');
        expect(p.b == 0 || p.b == 255, isTrue,
            reason: 'b=${p.b} at ${p.x},${p.y} is not 0 or 255');
      }
    });

    test('luminanceThreshold with threshold=0 → all white', () {
      // luminance >= 0 is always true, so every pixel becomes white.
      final src = horizontalGradient(32, 8);
      final out = luminanceThreshold(src.clone(), threshold: 0);
      expectSolidColor(out, ColorRgb8(255, 255, 255));
    });

    test('luminanceThreshold with threshold=1.1 → all black', () {
      // luminance < 1.1 is always true for [0,1] luminances → all black.
      final src = horizontalGradient(32, 8);
      final out = luminanceThreshold(src.clone(), threshold: 1.1);
      expectSolidColor(out, ColorRgb8(0, 0, 0));
    });

    test('luminanceThreshold output channels stay within [0, 255]', () {
      final src = horizontalGradient(32, 8);
      final out = luminanceThreshold(src.clone());
      for (final p in out) {
        expect(p.r, inInclusiveRange(0, 255));
        expect(p.g, inInclusiveRange(0, 255));
        expect(p.b, inInclusiveRange(0, 255));
      }
    });

    test('luminanceThreshold with all-zero mask leaves image unchanged', () {
      final src = horizontalGradient(32, 8);
      final result = luminanceThreshold(
        src.clone(),
        mask: solidImage(32, 8, ColorRgb8(0, 0, 0)),
      );
      testImageEquals(result, src);
    });
  });
}
