import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  group('Util', () {
    test('neuralQuantizer', () {
      final img = Image(width: 256, height: 256);
      for (final p in img) {
        p
          ..r = p.x
          ..g = p.y;
      }

      final q = NeuralQuantizer(img);
      var img2 = q.getIndexImage(img);
      File('$testOutputPath/util/neuralQuantizer_256_10.bmp')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodeBmp(img2));

      final q_1 = NeuralQuantizer(img, samplingFactor: 1);
      img2 = q_1.getIndexImage(img);
      File('$testOutputPath/util/neuralQuantizer_256_1.bmp')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodeBmp(img2));

      final q_100 = NeuralQuantizer(img, samplingFactor: 100);
      img2 = q_100.getIndexImage(img);
      File('$testOutputPath/util/neuralQuantizer_256_100.bmp')
        ..createSync(recursive: true)
        ..writeAsBytesSync(encodeBmp(img2));
    });
  });
}
