part of image_test;


void defineFontTests() {
  group('bitmapFont', () {
    test('fromZipFile', () {
      Io.File fp = new Io.File('res/font.zip');
      List<int> zip = fp.readAsBytesSync();

      BitmapFont font = new BitmapFont.fromZipFile(zip);
    });
  });
}
