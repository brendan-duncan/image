part of image_test;

void definePngTests() {
  group('png', () {
    test('png_32', () {
      // Decode the image from file.
      List<int> bytes = new Io.File('res/png_32.png').readAsBytesSync();
      Image image = new PngDecoder().decode(bytes);
      expect(image.width, equals(64));
      expect(image.height, equals(64));
      expect(image.format, Image.RGBA);
    });

    test('png_24', () {
      // Decode the image from file.
      List<int> bytes = new Io.File('res/png_24.png').readAsBytesSync();
      Image image = new PngDecoder().decode(bytes);
      expect(image.width, equals(64));
      expect(image.height, equals(64));
      expect(image.format, Image.RGB);
    });

    /*test('png_8', () {
      // Decode the image from file.
      List<int> bytes = new Io.File('res/png_8.png').readAsBytesSync();
      Image image = new PngDecoder().decode(bytes);
      expect(image.width, equals(64));
      expect(image.height, equals(64));
      expect(image.format, Image.RGB);
    });

    test('png_32_int', () {
      // Decode the image from file.
      List<int> bytes = new Io.File('res/png_32_int.png').readAsBytesSync();
      Image image = new PngDecoder().decode(bytes);
      expect(image.width, equals(64));
      expect(image.height, equals(64));
      expect(image.format, Image.RGBA);
    });

    test('png_24_int', () {
      // Decode the image from file.
      List<int> bytes = new Io.File('res/png_24_int.png').readAsBytesSync();
      Image image = new PngDecoder().decode(bytes);
      expect(image.width, equals(64));
      expect(image.height, equals(64));
      expect(image.format, Image.RGB);
    });

    test('png_8_int', () {
      // Decode the image from file.
      List<int> bytes = new Io.File('res/png_8_int.png').readAsBytesSync();
      Image image = new PngDecoder().decode(bytes);
      expect(image.width, equals(64));
      expect(image.height, equals(64));
      expect(image.format, Image.RGB);
    });

    test('png_8_trans', () {
      // Decode the image from file.
      List<int> bytes = new Io.File('res/png_8_trans.png').readAsBytesSync();
      Image image = new PngDecoder().decode(bytes);
      expect(image.width, equals(64));
      expect(image.height, equals(64));
      expect(image.format, Image.RGBA);
    });

    test('png_8_trans_int', () {
      // Decode the image from file.
      List<int> bytes = new Io.File('res/png_8_trans_int.png').readAsBytesSync();
      Image image = new PngDecoder().decode(bytes);
      expect(image.width, equals(64));
      expect(image.height, equals(64));
      expect(image.format, Image.RGBA);
    });*/


    test('encode', () {
      Image image = new Image(64, 64);
      image.fill(getColor(100, 200, 255));

      // Encode the image to PNG
      List<int> png = new PngEncoder().encode(image);

      new Io.File('out/encode.png')
            .writeAsBytesSync(png);
    });

    test('decode', () {
      List<int> bytes = new Io.File('out/encode.png').readAsBytesSync();
      Image image = new PngDecoder().decode(bytes);

      expect(image.width, equals(64));
      expect(image.height, equals(64));
    });
  });
}
