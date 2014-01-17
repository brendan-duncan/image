part of image_test;

void defineJpegTests() {
  group('jpeg', () {
    test('decode/encode', () {
      var bytes = new Io.File('res/cat-eye04.jpg').readAsBytesSync();

      // Decode the image from file.
      var image = new JpegDecoder().decode(bytes);
      expect(image.width, equals(602));
      expect(image.height, equals(562));

      // Encode the image to Jpeg
      var jpg = new JpegEncoder().encode(image);

      // Decode the encoded jpg.
      var image2 = new JpegDecoder().decode(jpg);

      // We can't exactly do a byte-level comparison since Jpeg is lossy.
      expect(image2.width, equals(602));
      expect(image2.height, equals(562));
    });
  });
}
