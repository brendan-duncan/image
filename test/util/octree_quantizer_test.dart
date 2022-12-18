import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../test_util.dart';

void OctreeQuantizerTest() {
  group('OctreeQuantizer', () {
    final img = Image(256, 256);
    for (var p in img) {
      p.r = p.x;
      p.g = p.y;
    }

    final quantizer = OctreeQuantizer(img);

    final img2 = quantizer.getIndexImage(img);

    File('$tmpPath/out/util/octreeQuantizer_256.bmp')
      ..createSync(recursive: true)
      ..writeAsBytesSync(encodeBmp(img2));
  });
}
