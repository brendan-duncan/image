import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../test_util.dart';

void fillTest() {
  test('fill', () {
    final i0 = Image(256, 256);
    fill(i0, ColorRgba8(120, 64, 85, 90));
    final p0 = i0.getPixel(50, 50);
    expect(p0, equals([120, 64, 85]));
    File('$tmpPath/out/draw/fill_0.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(encodePng(i0));
  });
}
