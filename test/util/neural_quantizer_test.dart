import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../test_util.dart';

void NeuralQuantizerTest() {
  group('NeuralQuantizer', () {
    final img = Image(256, 256);
    for (var p in img) {
      p.r = p.x;
      p.g = p.y;
    }

    final q = NeuralQuantizer(img);
    var img2 = q.getIndexImage(img);
    File('$tmpPath/out/util/neuralQuantizer_256_10.bmp')
      ..createSync(recursive: true)
      ..writeAsBytesSync(encodeBmp(img2));

    final q_1 = NeuralQuantizer(img, samplingFactor: 1);
    img2 = q_1.getIndexImage(img);
    File('$tmpPath/out/util/neuralQuantizer_256_1.bmp')
      ..createSync(recursive: true)
      ..writeAsBytesSync(encodeBmp(img2));

    final q_100 = NeuralQuantizer(img, samplingFactor: 100);
    img2 = q_100.getIndexImage(img);
    File('$tmpPath/out/util/neuralQuantizer_256_100.bmp')
      ..createSync(recursive: true)
      ..writeAsBytesSync(encodeBmp(img2));
  });
}
