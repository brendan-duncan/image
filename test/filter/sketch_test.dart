import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../test_util.dart';

void sketchTest() {
  test('sketch', () {
    final bytes = File('test/_data/png/buck_24.png').readAsBytesSync();
    final i0 = decodePng(bytes)!;
    sketch(i0);
    File('$testOutputPath/filter/sketch.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(encodePng(i0));
  });
}