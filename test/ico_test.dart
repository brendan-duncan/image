import 'dart:io';

import 'package:image/image.dart';
import 'package:image/src/formats/ico_encoder.dart';
import 'package:test/test.dart';

void main() {
  group('ICO', () {
    test('encode', () {
      Image image = Image(64, 64);
      image.fill(getColor(100, 200, 255));

      // Encode the image to ICO
      List<int> png = IcoEncoder().encodeImage(image);
      File('out/ico/encode.ico')
        ..createSync(recursive: true)
        ..writeAsBytesSync(png);

      Image image2 = Image(64, 64);
      image2.fill(getColor(100, 255, 200));

      List<int> png2 = IcoEncoder().encodeImages([image, image2]);
      File('out/ico/encode2.ico')
        ..createSync(recursive: true)
        ..writeAsBytesSync(png2);

      Image image3 = Image(32, 64);
      image3.fill(getColor(255, 100, 200));

      List<int> png3 = IcoEncoder().encodeImages([image, image2, image3]);
      File('out/ico/encode3.ico')
        ..createSync(recursive: true)
        ..writeAsBytesSync(png3);
    });
  });
}
