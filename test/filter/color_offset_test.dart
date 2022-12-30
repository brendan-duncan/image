import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  group('Filter', () {
    test('colorOffset', () {
      final bytes = File('test/_data/png/buck_24.png').readAsBytesSync();
      final i0 = decodePng(bytes)!;
      colorOffset(i0, red: 50, green: 10, blue: 30);
      File('$testOutputPath/filter/colorOffset.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0));
    });
  });
}
