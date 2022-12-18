import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../test_util.dart';

void DrawCircleTest() {
  test('drawCircle', () {
    final i0 = Image(256, 256);

    drawCircle(i0, 128, 128, 100, ColorRgba8(255));

    File('$tmpPath/out/draw/draw_circle_0.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(encodePng(i0));
  });
}
