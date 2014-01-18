part of image_test;

void defineWebPTests() {
  group('webp', () {
    test('getInfo', () {
      Io.File file = new Io.File('res/webp/1_webp_ll.webp');
      var bytes = file.readAsBytesSync();

      WebPFeatures features = new WebPDecoder().getInfo(bytes);
      print(features);
    });
  });
}
