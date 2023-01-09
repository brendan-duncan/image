import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  group('Draw', () {
    test('drawCircle', () {
      final i0 = Image(width: 256, height: 256);

      drawCircle(i0,
          x: 128, y: 128, radius: 50, color: ColorRgba8(255, 0, 0, 255));

      drawCircle(i0,
          x: 128,
          y: 128,
          radius: 100,
          antialias: true,
          color: ColorRgba8(0, 255, 0, 255));

      File('$testOutputPath/draw/drawCircle.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0));
    });
  });
}
