import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  group('Draw', () {
    test('fillCircle', () {
      final i0 = Image(width: 256, height: 256);

      fillCircle(i0, 128, 128, 100, ColorRgba8(255, 255, 0, 128));

      File('$testOutputPath/draw/fill_circle.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0));
    });
  });
}
