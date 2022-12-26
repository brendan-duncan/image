import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../test_util.dart';

void hexagonPixelateTest() {
  test('hexagonPixelate', () {
    final bytes = File('test/_data/png/buck_24.png').readAsBytesSync();
    final i0 = decodePng(bytes)!;
    hexagonPixelate(i0, centerX: 50);
    File('$testOutputPath/filter/hexagonPixelate.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(encodePng(i0));
  });
}
