import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../test_util.dart';

void RemapColorsTest() {
  test('remapColors', () {
    final bytes = File('test/data/png/buck_24.png').readAsBytesSync();
    final i0 = PngDecoder().decodeImage(bytes)!;
    remapColors(i0, red: Channel.green, green: Channel.luminance,
        blue: Channel.red);
    File('$tmpPath/out/filter/remapColors.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(encodePng(i0));
  });
}