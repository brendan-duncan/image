import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  group('Filter', () {
    test('monochrome', () {
      final bytes = File('test/_data/png/buck_24.png').readAsBytesSync();
      final i0 = decodePng(bytes)!;
      monochrome(i0, color: ColorRgb8(100, 160, 64));
      File('$testOutputPath/filter/monochrome.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0));
    });

    test('monochrome with amount=0 leaves the image unchanged', () {
      // amount=0 is an early-return no-op.
      final src = quadrantImage(16, 16);
      testImageEquals(monochrome(src.clone(), amount: 0), src);
    });

    test('monochrome preserves image dimensions and numChannels', () {
      final src = horizontalGradient(32, 8);
      final out = monochrome(src.clone(), color: ColorRgb8(100, 160, 64));
      expect(out.width, equals(src.width));
      expect(out.height, equals(src.height));
      expect(out.numChannels, equals(src.numChannels));
    });

    test('monochrome output channels stay within [0, 255] for uint8', () {
      final src = horizontalGradient(32, 8);
      final out = monochrome(src.clone(), color: ColorRgb8(100, 160, 64));
      for (final p in out) {
        expect(p.r, inInclusiveRange(0, 255));
        expect(p.g, inInclusiveRange(0, 255));
        expect(p.b, inInclusiveRange(0, 255));
      }
    });

    test('monochrome of a uniform gray image produces a uniform output', () {
      // Per-pixel filter with no spatial coupling → uniform in, uniform out.
      final src = solidImage(16, 16, ColorRgb8(128, 128, 128));
      final out = monochrome(src.clone(), color: ColorRgb8(100, 160, 64));
      final first = out.getPixel(0, 0);
      for (final p in out) {
        expect(p.r, equals(first.r), reason: 'uniform r at ${p.x},${p.y}');
        expect(p.g, equals(first.g), reason: 'uniform g at ${p.x},${p.y}');
        expect(p.b, equals(first.b), reason: 'uniform b at ${p.x},${p.y}');
      }
    });

    test('monochrome with all-zero mask leaves the image unchanged', () {
      final src = horizontalGradient(32, 8);
      final result = monochrome(
        src.clone(),
        color: ColorRgb8(100, 160, 64),
        mask: solidImage(32, 8, ColorRgb8(0, 0, 0)),
      );
      testImageEquals(result, src);
    });
  });
}
