import 'dart:io';

import 'package:image/image.dart';
import 'package:image/src/formats/cur_encoder.dart';
import 'package:test/test.dart';

void main() {
  group('CUR', () {
    test('encode', () {
      Image image = Image(64, 64);
      image.fill(getColor(100, 200, 255));

      // Encode the image to CUR
      List<int> png = CurEncoder().encodeImage(image);
      File('out/cur/encode.cur')
        ..createSync(recursive: true)
        ..writeAsBytesSync(png);

      Image image2 = Image(64, 64);
      image2.fill(getColor(100, 255, 200));

      List<int> png2 = CurEncoder(hotSpots: {1: Point(64, 64), 0: Point(64, 64)}).encodeImages([image, image2]);
      File('out/cur/encode2.cur')
        ..createSync(recursive: true)
        ..writeAsBytesSync(png2);

      Image image3 = Image(32, 64);
      image3.fill(getColor(255, 100, 200));

      List<int> png3 = CurEncoder().encodeImages([image, image2, image3]);
      File('out/cur/encode3.cur')
        ..createSync(recursive: true)
        ..writeAsBytesSync(png3);
    });
  });
}
