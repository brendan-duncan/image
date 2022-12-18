import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../test_util.dart';

void AdjustColorTest() {
  test('adjustColor', () {
    final bytes = File('test/data/png/buck_24.png').readAsBytesSync();
    final i0 = PngDecoder().decodeImage(bytes)!;
    adjustColor(i0, gamma: 2.2);
    File('$tmpPath/out/filter/adjustColor.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(encodePng(i0));
  });
}
