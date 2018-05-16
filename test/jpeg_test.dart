part of image_test;

void defineJpegTests() {
  Io.Directory dir = new Io.Directory('test/res/jpg');
  List files = dir.listSync(recursive: true);

  List<int> toRGB(int pixel) =>
      [getRed(pixel), getGreen(pixel), getBlue(pixel)];

  group('JPEG', () {
    for (var f in files) {
      if (f is! Io.File || !f.path.endsWith('.jpg')) {
        continue;
      }

      String name = f.path.split(new RegExp(r'(/|\\)')).last;
      test('$name', () {
        List<int> bytes = f.readAsBytesSync();
        expect(new JpegDecoder().isValidFile(bytes), equals(true));

        InputBuffer stream = new InputBuffer(bytes);
        Image image = new JpegDecoder().decodeImage(bytes);
        if (image == null) {
          throw new ImageException('Unable to decode JPEG Image: $name.');
        }

        List<int> tga = new TgaEncoder().encodeImage(image);
        new Io.File('out/jpg/${name}.tga')
              ..createSync(recursive: true)
              ..writeAsBytesSync(tga);

        List<int> outJpg = new JpegEncoder().encodeImage(image);
        new Io.File('out/jpg/${name}')
          ..createSync(recursive: true)
          ..writeAsBytesSync(outJpg);
      });
    }

    test('decode/encode', () {
      List<int> bytes = new Io.File('test/res/jpg/testimg.png').readAsBytesSync();
      Image png = new PngDecoder().decodeImage(bytes);
      expect(toRGB(png.getPixel(0, 0)), [48, 47, 45]);

      bytes = new Io.File('test/res/jpg/testimg.jpg').readAsBytesSync();

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
