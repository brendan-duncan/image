import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  group('Draw', () {
    test('fillRect', () {
      final i0 = Image(width: 256, height: 256);

      fillRect(i0, 50, 50, 150, 150, ColorRgb8(255));
      fillRect(i0, 100, 100, 200, 200, ColorRgba8(0, 255, 0, 128));

      File('$testOutputPath/draw/fill_rect.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0));

      var p = i0.getPixel(51, 51);
      expect(p, equals([255, 0, 0]));
      p = i0.getPixel(101, 101);
      expect(p, equals([127, 128, 0]));
      p = i0.getPixel(195, 195);
      expect(p, equals([0, 128, 0]));
    });
  });
}
