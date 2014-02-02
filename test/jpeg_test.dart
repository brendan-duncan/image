part of image_test;

void defineJpegTests() {
  group('jpeg', () {
    test('decode/encode', () {
      List<int> bytes = new Io.File('res/cat-eye04.jpg').readAsBytesSync();

      // Decode the image from file.
      Image image = new JpegDecoder().decodeImage(bytes);
      expect(image.width, equals(602));
      expect(image.height, equals(562));

      // Encode the image to Jpeg
      List<int> jpg = new JpegEncoder().encode(image);

      // Decode the encoded jpg.
      Image image2 = new JpegDecoder().decodeImage(jpg);

      // We can't exactly do a byte-level comparison since Jpeg is lossy.
      expect(image2.width, equals(602));
      expect(image2.height, equals(562));
    });
  });
}
