import 'dart:io';

import 'package:image/image.dart';
import 'package:test/test.dart';

import '../test_util.dart';

void fillTest() {
  test('fill', () async {
    final cmd = CreateImageCmd(256, 256)
        ..fill(ColorRgba8(120, 64, 85, 90))
        ..encodePng();

    final png = await cmd.getBytesAsync();
    expect(png, isNotNull);
    File('$testOutputPath/draw/fill.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(png!);

    final img = await cmd.getImageAsync();
    expect(img, isNotNull);
    expect(img?.width, equals(256));
    expect(img?.height, equals(256));
    expect(img?.getPixel(0, 0), equals([120, 64, 85]));
  });
}
