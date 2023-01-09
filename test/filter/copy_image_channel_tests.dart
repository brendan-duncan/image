import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  group('Filter', () {
    test('copyImageChannels', () {
      final bytes = File('test/_data/png/buck_24.png').readAsBytesSync();
      final i0 = decodePng(bytes)!.convert(numChannels: 4);

      final maskImage = Image(width: 256, height: 256);
      fillCircle(maskImage,
          x: 128, y: 128, radius: 128, color: ColorRgb8(255, 255, 255));

      copyImageChannels(i0,
          from: maskImage, scaled: true, alpha: Channel.luminance);
      File('$testOutputPath/filter/copyImageChannels.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0));
    });
  });
}
