import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  group('Transform', () {
    test('copyRotate', () {
      final img = decodePng(File('test/_data/png/buck_24.png')
          .readAsBytesSync())!;
      final i4 = img.convert(numChannels: 4);

      for (var i = 0; i < 360; i += 45) {
        final i0 = copyRotate(i4, angle: i);
        expect(i0.numChannels, equals(i4.numChannels));
        File('$testOutputPath/transform/copyRotate_$i.png')
          ..createSync(recursive: true)
          ..writeAsBytesSync(encodePng(i0));
      }
    });
  });
}
