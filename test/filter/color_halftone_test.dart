import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  group('Filter', () {
    test('colorHalftone', () {
      final bytes = File('test/_data/png/buck_24.png').readAsBytesSync();
      final i0 = decodePng(bytes)!;
      colorHalftone(i0);
      File('$testOutputPath/filter/colorHalftone.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0));
    });
  });
}
