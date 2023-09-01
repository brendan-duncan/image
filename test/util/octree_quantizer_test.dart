import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  group('Util', () {
    test('octreeQuantizer', () {
      final img = Image(width: 256, height: 256);
      for (final p in img) {
        p
          ..r = p.x
          ..g = p.y;
      }

      final quantizer = OctreeQuantizer(img);

      final img2 = quantizer.getIndexImage(img);

      File('$testOutputPath/util/octreeQuantizer_256.bmp')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodeBmp(img2));
    });
  });
}
