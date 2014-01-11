part of image_test;


void defineFontTests() {
  group('bitmapFont', () {
    test('zip/xml', () {
      List<int> fontZip = new Io.File('res/test.zip').readAsBytesSync();
      BitmapFont font = readFontZip(fontZip);

      Image image = readPng(new Io.File('res/trees.png').readAsBytesSync());

      drawString(image, font, 10, 50, 'Testing Font 1: Hello World');

      new Io.File('out/font_zip_xml.jpg')
            ..createSync(recursive: true)
            ..writeAsBytesSync(writeJpg(image));
    });

    test('zip/text', () {
      List<int> fontZip = new Io.File('res/test_text.zip').readAsBytesSync();
      BitmapFont font = readFontZip(fontZip);

      Image image = readPng(new Io.File('res/trees.png').readAsBytesSync());

      drawString(image, font, 10, 50, 'Testing Font 2: Hello World',
          color: getColor(255, 0, 0, 128));

      new Io.File('out/font_zip_text.jpg')
            ..createSync(recursive: true)
            ..writeAsBytesSync(writeJpg(image));
    });
  });
}
