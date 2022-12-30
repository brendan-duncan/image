import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  group('Filter', () {
    test('adjustColor', () {
      final bytes = File('test/_data/png/buck_24.png').readAsBytesSync();
      final i0 = decodePng(bytes)!;
      adjustColor(i0, gamma: 2.2);
      File('$testOutputPath/filter/adjustColor.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0));
    });
  });
}
