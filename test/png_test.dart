part of image_test;

void definePngTests() {
  group('png', () {
    test('decode/encode', () {
      Io.File file = new Io.File('res/trees.png');
      var bytes = file.readAsBytesSync();

      // Decode the image from file.
      var image = new PngDecoder().decode(bytes);
      expect(image.width, equals(400));
      expect(image.height, equals(533));

      // Encode the image to PNG
      /*var png = new PngEncoder().encode(image);

      // Decode the encoded PNG
      var image2 = new PngDecoder().decode(png);

      expect(image2.width, equals(400));
      expect(image2.height, equals(533));*/
    });
  });
}
