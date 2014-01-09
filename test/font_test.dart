part of image_test;


void defineFontTests() {
  group('bitmapFont', () {
    test('fromZipFile', () {
      Io.File fp = new Io.File('res/test.zip');
      List<int> zip = fp.readAsBytesSync();

      BitmapFont font = new BitmapFont.fromZipFile(zip);

      fp = new Io.File('res/font.zip');
      zip = fp.readAsBytesSync();

      BitmapFont font2 = new BitmapFont.fromZipFile(zip);

      fp = new Io.File('res/trees.png');
      List<int> png = fp.readAsBytesSync();

      Image image = new PngDecoder().decode(png);

      font.drawString(image, 'Testing Font 1: Hello World', 10, 50);

      font2.drawString(image, 'Testing Font 2: Hello World', 10, 100);

      List<int> jpg = new JpegEncoder().encode(image);
      Io.File out = new Io.File('out/font.jpg');
      out.createSync(recursive: true);
      out.writeAsBytesSync(jpg);
    });
  });
}
