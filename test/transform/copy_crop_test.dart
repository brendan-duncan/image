import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  group('Transform', () {
    test('crop with radius', () async {
      final g1 = await decodeGifFile('test/_data/gif/homer.gif');
      final g2 = copyCrop(
        g1!,
        x: 0,
        y: 0,
        width: 500, // this is just the width of the original animation
        height: 375, // this is just the height of the original animation
        radius: 100,
      );
      await encodeGifFile('$testOutputPath/transform/copyCrop_radius.gif', g2);
      await encodePngFile('$testOutputPath/transform/copyCrop_radius.png', g2);
    });

    test('copyCrop', () {
      final bytes = File('test/_data/png/buck_24.png').readAsBytesSync();
      final i0 = PngDecoder().decode(bytes)!;

      final i0_1 = copyCrop(i0, x: 50, y: 50, width: 100, height: 100);
      expect(i0_1.width, equals(100));
      expect(i0_1.height, equals(100));
      expect(i0_1.format, equals(i0.format));
      File('$testOutputPath/transform/copyCrop.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0_1));

      final i1 = i0.convert(numChannels: 4);
      final i0_2 =
          copyCrop(i1, x: 50, y: 50, width: 100, height: 100, radius: 20);
      expect(i0_2.width, equals(100));
      expect(i0_2.height, equals(100));
      expect(i0_2.format, equals(i0.format));
      File('$testOutputPath/transform/copyCrop_rounded.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0_2));
    });
  });
}
