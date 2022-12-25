import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../test_util.dart';

void imageMaskTest() {
  test('maskAlpha', () {
    final bytes = File('test/_data/png/buck_24.png').readAsBytesSync();
    final i0 = decodePng(bytes)!.convert(numChannels: 4);

    final maskImage = Image(256, 256);
    fillCircle(maskImage, 128, 128, 128, ColorRgb8(255, 255, 255));

    imageMask(i0, maskImage, scaleMask: true);
    File('$testOutputPath/filter/imageMask.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(encodePng(i0));
  });
}
