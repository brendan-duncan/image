part of image_test;

void defineTgaTests() {
  group('tga', () {
    test('decode/encode', () {
      Io.File file = new Io.File('res/trees.tga');
      var bytes = file.readAsBytesSync();

      // Decode the image from file.
      var image = new TgaDecoder().decode(bytes);
      expect(image.width, equals(400));
      expect(image.height, equals(533));

      // Encode the image as a tga
      var tga = new TgaEncoder().encode(image);

      Io.File out = new Io.File('out/trees.tga');
      out.createSync(recursive: true);
      out.writeAsBytesSync(tga);

      // Decode the encoded image, make sure it's the same as the original.
      var image2 = new TgaDecoder().decode(tga);
      expect(image2.width, equals(400));
      expect(image2.height, equals(533));
    });
  });
}
