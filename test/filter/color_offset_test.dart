import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  group('Filter', () {
    test('colorOffset', () {
      final bytes = File('test/_data/png/buck_24.png').readAsBytesSync();
      final i0 = decodePng(bytes)!;
      colorOffset(i0, red: 50, green: 10, blue: 30);
      File('$testOutputPath/filter/colorOffset.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0));
    });

    test('colorOffset adds a constant to each channel', () {
      // Mid-range values are chosen so no channel clamps at 0 or 255.
      final result = colorOffset(solidImage(8, 8, ColorRgb8(100, 100, 100)),
          red: 50, green: 10, blue: 30);
      expectSolidColor(result, ColorRgb8(150, 110, 130));
    });

    test('colorOffset with zero offsets leaves the image unchanged', () {
      final src = quadrantImage(16, 16);
      testImageEquals(colorOffset(src.clone()), src);
    });
  });
}
