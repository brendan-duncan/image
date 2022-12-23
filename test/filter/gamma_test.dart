import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../test_util.dart';

void gammaTest() {
  test('gamma', () {
    final bytes = File('test/_data/png/buck_24.png').readAsBytesSync();
    final i0 = decodePng(bytes)!;
    gamma(i0);
    File('$testOutputPath/filter/gamma.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(encodePng(i0));
  });
}