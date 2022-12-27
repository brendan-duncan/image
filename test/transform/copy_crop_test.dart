import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  group('Transform', () {
    test('copyCrop', () {
      final bytes = File('test/_data/png/buck_24.png').readAsBytesSync();
      final i0 = PngDecoder().decode(bytes)!;
      final i0_1 = copyCrop(i0, 50, 50, 100, 100);
      expect(i0_1.width, equals(100));
      expect(i0_1.height, equals(100));
      expect(i0_1.format, equals(i0.format));
      File('$testOutputPath/transform/copyCrop.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0_1));
    });

    test('copyCropCircle', () {
      final bytes = File('test/_data/png/buck_24.png').readAsBytesSync();
      final i0 = PngDecoder().decode(bytes)!.convert(numChannels: 4);
      final i0_1 = copyCropCircle(i0);
      expect(i0_1.width, equals(186));
      expect(i0_1.height, equals(186));
      expect(i0_1.format, equals(i0.format));
      File('$testOutputPath/transform/copyCropCircle.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0_1));
    });
  });
}
