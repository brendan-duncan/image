import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../test_util.dart';

void bulgeDistortionTest() {
  test('bulgeDistortion', () {
    final bytes = File('test/_data/png/buck_24.png').readAsBytesSync();
    final i0 = decodePng(bytes)!;
    bulgeDistortion(i0, interpolation: Interpolation.cubic);
    File('$testOutputPath/filter/bulgeDistortion.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(encodePng(i0));
  });
}