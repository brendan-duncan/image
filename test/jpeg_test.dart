import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

void main() {
  Directory dir = new Directory('test/res/jpg');
  List files = dir.listSync(recursive: true);

  List<int> toRGB(int pixel) =>
      [getRed(pixel), getGreen(pixel), getBlue(pixel)];

  group('JPEG', () {
    for (var f in files) {
      if (f is! File || !f.path.endsWith('.jpg')) {
        continue;
      }

      String name = f.path.split(new RegExp(r'(/|\\)')).last;
      test('$name', () {
        List<int> bytes = f.readAsBytesSync();
        expect(new JpegDecoder().isValidFile(bytes), equals(true));

        Image image = new JpegDecoder().decodeImage(bytes);
        if (image == null) {
          throw new ImageException('Unable to decode JPEG Image: $name.');
        }

        List<int> outJpg = new JpegEncoder().encodeImage(image);
        new File('out/jpg/${name}')
          ..createSync(recursive: true)
          ..writeAsBytesSync(outJpg);

        // Make sure we can read what we just wrote.
        Image image2 = new JpegDecoder().decodeImage(
            new File('out/jpg/${name}').readAsBytesSync());
        if (image2 == null) {
          throw new ImageException('Unable to re-decode JPEG Image: $name.');
        }
      });
    }

    test('decode/encode', () {
      List<int> bytes = new File('test/res/jpg/testimg.png').readAsBytesSync();
      Image png = new PngDecoder().decodeImage(bytes);
      expect(toRGB(png.getPixel(0, 0)), [48, 47, 45]);

      bytes = new File('test/res/jpg/testimg.jpg').readAsBytesSync();

      // Decode the image from file.
      Image image = new JpegDecoder().decodeImage(bytes);
      expect(image.width, equals(227));
      expect(image.height, equals(149));

      // Encode the image to Jpeg
      List<int> jpg = new JpegEncoder().encodeImage(image);

      // Decode the encoded jpg.
      Image image2 = new JpegDecoder().decodeImage(jpg);

      // We can't exactly do a byte-level comparison since Jpeg is lossy.
      expect(image2.width, equals(227));
      expect(image2.height, equals(149));
    });
  });
}
