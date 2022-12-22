import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../test_util.dart';

void remapColorsTest() {
  test('remapColors', () {
    final bytes = File('test/_data/png/buck_24.png').readAsBytesSync();
    final i0 = decodePng(bytes)!;
    remapColors(i0, red: Channel.green, green: Channel.luminance,
        blue: Channel.red);
    File('$testOutputPath/filter/remapColors.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(encodePng(i0));
  });
}
