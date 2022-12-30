import 'dart:io';
import 'dart:math';

import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  final r = Random();
  group('Draw', () {
    test('drawPixel.uint8', () {
      final i0 = Image(width: 256, height: 256);
      for (var i = 0; i < 10000; ++i) {
        final x = r.nextInt(i0.width - 1);
        final y = r.nextInt(i0.height - 1);
        drawPixel(i0, x, y, ColorRgb8(x, y, 0));
      }
      File('$testOutputPath/draw/drawPixel.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0));
    });
  });
}
