part of image_test;

void defineTgaTests() {
  group('tga', () {
    test('decode/encode', () {
      List<int> bytes = new Io.File('res/trees.tga').readAsBytesSync();

      // Decode the image from file.
      Image image = new TgaDecoder().decode(bytes);
      expect(image.width, equals(400));
      expect(image.height, equals(533));

      // Encode the image as a tga
      List<int> tga = new TgaEncoder().encode(image);

      Io.File out = new Io.File('out/trees.tga')
                          ..createSync(recursive: true)
                          ..writeAsBytesSync(tga);

      // Decode the encoded image, make sure it's the same as the original.
      Image image2 = new TgaDecoder().decode(tga);
      expect(image2.width, equals(400));
      expect(image2.height, equals(533));
    });
  });
}
