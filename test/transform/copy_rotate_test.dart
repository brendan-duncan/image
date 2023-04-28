import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  group('Transform', () {
    test('copyRotate', () {
      final img =
          decodePng(File('test/_data/png/buck_24.png').readAsBytesSync())!
            ..backgroundColor = ColorRgb8(255, 255, 255);
      for (var i = 0; i < 360; i += 45) {
        final i0 = copyRotate(img, angle: i);
        expect(i0.numChannels, equals(img.numChannels));
        File('$testOutputPath/transform/copyRotate_$i.png')
          ..createSync(recursive: true)
          ..writeAsBytesSync(encodePng(i0));
      }
    });
  });
}
