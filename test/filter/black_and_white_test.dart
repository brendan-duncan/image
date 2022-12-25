import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../test_util.dart';

void blackAndWhiteTest() {
  test('blackAndWhite', () {
    final bytes = File('test/_data/png/buck_24.png').readAsBytesSync();
    final i0 = decodePng(bytes)!;
    blackAndWhite(i0);
    File('$testOutputPath/filter/blackAndWhite.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(encodePng(i0));
  });
}
