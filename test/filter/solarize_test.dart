import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  group('Filter', () {
    test('solarize highlights', () {
      final bytes = File('test/_data/png/buck_24.png').readAsBytesSync();
      final i0 = decodePng(bytes)!;
      solarize(i0, threshold: 100);
      File('$testOutputPath/filter/solarize_highlights.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0));
    });

    test('solarize shadows', () {
      final bytes = File('test/_data/png/buck_24.png').readAsBytesSync();
      final i0 = decodePng(bytes)!;
      solarize(i0, threshold: 100, mode: SolarizeMode.shadows);
      File('$testOutputPath/filter/solarize_shadows.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0));
    });
  });
}
