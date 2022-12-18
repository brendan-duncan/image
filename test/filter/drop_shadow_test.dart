import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../test_util.dart';

void DropShadowTest() {
  test('dropShadow', () {
    final i0 = Image(256, 256, numChannels: 4);
    drawStringCentered(i0, arial_48, 'Shadow', color: ColorRgb8(255));

    final id = dropShadow(i0, -5, 5, 3);

    final i1 = Image(256, 256);
    i1.clear(ColorRgb8(255, 255, 255));
    drawImage(i1, id);

    File('$tmpPath/out/filter/dropShadow.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(encodePng(i1));
  });
}
