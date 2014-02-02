part of image_test;


void defineFontTests() {
  group('bitmapFont', () {
    test('zip/xml', () {
      List<int> fontZip = new Io.File('res/font/test.zip').readAsBytesSync();
      BitmapFont font = readFontZip(fontZip);

      Image image = readPng(new Io.File('res/png/trees.png').readAsBytesSync());

      drawString(image, font, 10, 50, 'Testing Font 1: Hello World');

      new Io.File('out/font/font_zip_xml.jpg')
            ..createSync(recursive: true)
            ..writeAsBytesSync(writeJpg(image));
    });

    test('zip/text', () {
      List<int> fontZip = new Io.File('res/font/test_text.zip').readAsBytesSync();
      BitmapFont font = readFontZip(fontZip);

      Image image = readPng(new Io.File('res/png/trees.png').readAsBytesSync());

      drawString(image, font, 10, 50, 'Testing Font 2: Hello World',
          color: getColor(255, 0, 0, 128));

      new Io.File('out/font/font_zip_text.jpg')
            ..createSync(recursive: true)
            ..writeAsBytesSync(writeJpg(image));
    });

    test('arial_14', () {
      Image image = readPng(new Io.File('res/png/trees.png').readAsBytesSync());

      drawString(image, arial_14, 10, 50, 'Testing Arial 14: Hello World',
          color: getColor(255, 0, 0, 128));

      new Io.File('out/font/font_arial_14.jpg')
            ..createSync(recursive: true)
            ..writeAsBytesSync(writeJpg(image));
    });

    test('arial_24', () {
      Image image = readPng(new Io.File('res/png/trees.png').readAsBytesSync());

      drawString(image, arial_24, 10, 50, 'Testing Arial 24: Hello World',
          color: getColor(255, 0, 0, 128));

      new Io.File('out/font/font_arial_24.jpg')
            ..createSync(recursive: true)
            ..writeAsBytesSync(writeJpg(image));
    });

    test('arial_48', () {
      Image image = readPng(new Io.File('res/png/trees.png').readAsBytesSync());

      drawString(image, arial_48, 10, 50, 'Testing Arial 48: Hello World',
          color: getColor(255, 0, 0, 128));

      new Io.File('out/font/font_arial_48.jpg')
            ..createSync(recursive: true)
            ..writeAsBytesSync(writeJpg(image));
    });
  });
}
