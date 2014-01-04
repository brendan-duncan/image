part of image_test;

void definePngTests() {
  group('png', () {
    List<int> bytes;
    Image image;
    List<int> png;
    Image image2;

    test('decode', () {
      Io.File file = new Io.File('res/trees.png');
      bytes = file.readAsBytesSync();

      // Decode the image from file.
      image = new PngDecoder().decode(bytes);
      expect(image.width, equals(400));
      expect(image.height, equals(533));
    });

    test('encode', () {
      png = new TgaEncoder().encode(image);
      Io.File file = new Io.File('out/trees.tga');
      file.createSync(recursive: true);
      file.writeAsBytesSync(png);

      // Encode the image to PNG
      png = new PngEncoder().encode(image);

      file = new Io.File('out/trees.png');
      file.createSync(recursive: true);
      file.writeAsBytesSync(png);
    });

    test('decode2', () {
      // Decode the encoded PNG
      image2 = new PngDecoder().decode(png);

      expect(image2.width, equals(400));
      expect(image2.height, equals(533));
    });
  });
}
