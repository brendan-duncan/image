import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  group('Filter', () {
    test('dropShadow', () {
      final i0 = Image(width: 256, height: 256, numChannels: 4);
      drawString(i0, 'Shadow', font: arial48, color: ColorRgb8(255, 0, 0));

      final id = dropShadow(i0, -5, 5, 3);

      final i1 = Image(width: 256, height: 256)
        ..clear(ColorRgb8(255, 255, 255));
      compositeImage(i1, id);

      File('$testOutputPath/filter/dropShadow.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i1));
    });

    test('dropShadow returns a new image (not the source)', () {
      final src = Image(width: 32, height: 32, numChannels: 4);
      final result = dropShadow(src, 4, 4, 2);
      // dropShadow always allocates a fresh destination image
      expect(identical(result, src), isFalse);
    });

    test('dropShadow output has 4 channels', () {
      final src = Image(width: 32, height: 32, numChannels: 4);
      final result = dropShadow(src, 4, 4, 2);
      // the internal image is always created with numChannels: 4
      expect(result.numChannels, equals(4));
    });

    test('dropShadow with positive offsets enlarges the canvas', () {
      final src = Image(width: 32, height: 32, numChannels: 4);
      // hShadow=4, vShadow=4, blur=2 → shadow extends beyond the source
      // boundary so the result must be wider and taller than the source.
      final result = dropShadow(src, 4, 4, 2);
      expect(result.width, greaterThan(src.width));
      expect(result.height, greaterThan(src.height));
    });

    test('dropShadow with blur=0 still returns a valid image', () {
      final src = Image(width: 16, height: 16, numChannels: 4);
      final result = dropShadow(src, 2, 2, 0);
      // Zero blur is allowed; clamped internally to 0.
      expect(result.width, greaterThanOrEqualTo(src.width));
      expect(result.height, greaterThanOrEqualTo(src.height));
    });
  });
}
