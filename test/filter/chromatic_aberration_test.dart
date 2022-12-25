import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../test_util.dart';

void chromaticAberrationTest() {
  test('chromaticAberration', () {
    final bytes = File('test/_data/png/buck_24.png').readAsBytesSync();
    final i0 = decodePng(bytes)!;
    chromaticAberration(i0);
    File('$testOutputPath/filter/chromaticAberration.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(encodePng(i0));
  });
}
