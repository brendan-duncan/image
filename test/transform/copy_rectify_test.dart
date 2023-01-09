import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  group('Transform', () {
    test('copyRectify', () {
      final img =
          decodeJpg(File('test/_data/jpg/oblique.jpg').readAsBytesSync())!;

      final i0 = copyRectify(img,
          topLeft: Point(16, 32),
          topRight: Point(79, 39),
          bottomLeft: Point(16, 151),
          bottomRight: Point(108, 141),
          interpolation: Interpolation.cubic);

      File('$testOutputPath/transform/copyRectify.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodePng(i0));
    });
  });
}
