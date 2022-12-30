import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  group('Filter', () {
    test('pixelate', () {
      final bytes = File('test/_data/png/buck_24.png').readAsBytesSync();
      final i0 = decodePng(bytes)!;
      final i1 = i0.clone();
      pixelate(i0, size: 10);
      File('$testOutputPath/filter/pixelate_upperLeft.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0));

      pixelate(i1, size: 10, mode: PixelateMode.average);
      File('$testOutputPath/filter/pixelate_average.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i1));
    });
  });
}
