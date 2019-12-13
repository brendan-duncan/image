import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

void main() {
  Image image =
      readJpg(File('test/res/jpg/big_buck_bunny.jpg').readAsBytesSync());

  group('bitmapFont', () {
    test('zip/xml', () {
      List<int> fontZip = File('test/res/font/test.zip').readAsBytesSync();
      BitmapFont font = readFontZip(fontZip);

      var img = copyResize(image, width: 400);
      drawString(img, font, 10, 50, 'Testing Font 1: Hello World');

      File('.dart_tool/out/font/font_zip_xml.jpg')
        ..createSync(recursive: true)
        ..writeAsBytesSync(writeJpg(img));
    });

    test('zip/text', () {
      List<int> fontZip = File('test/res/font/test_text.zip').readAsBytesSync();
      BitmapFont font = readFontZip(fontZip);

      var img = copyResize(image, width: 400);
      drawString(img, font, 10, 50, 'Testing Font 2: Hello World',
          color: getColor(255, 0, 0, 128));

      File('.dart_tool/out/font/font_zip_text.jpg')
        ..createSync(recursive: true)
        ..writeAsBytesSync(writeJpg(img));
    });

    test('arial_14', () {
      var img = copyResize(image, width: 400);
      drawString(img, arial_14, 10, 50, 'Testing Arial 14: Hello World',
          color: getColor(255, 0, 0, 128));

      File('.dart_tool/out/font/font_arial_14.jpg')
        ..createSync(recursive: true)
        ..writeAsBytesSync(writeJpg(img));
    });

    test('arial_24', () {
      var img = copyResize(image, width: 400);
      drawString(img, arial_24, 10, 50, 'Testing Arial 24: Hello World',
          color: getColor(255, 0, 0, 128));

      File('.dart_tool/out/font/font_arial_24.jpg')
        ..createSync(recursive: true)
        ..writeAsBytesSync(writeJpg(img));
    });

    test('arial_48', () {
      var img = copyResize(image, width: 400);
      drawString(img, arial_48, 10, 50, 'Testing Arial 48: Hello World',
          color: getColor(255, 0, 0, 128));

      File('.dart_tool/out/font/font_arial_48.jpg')
        ..createSync(recursive: true)
        ..writeAsBytesSync(writeJpg(img));
    });

    test('drawStringCenteredY', () {
      var img = copyResize(image, width: 400);
      drawStringCentered(img, arial_24, 'Testing Arial 24: Hello World',
          y: 50, color: getColor(255, 0, 0, 128));

      File('.dart_tool/out/font/y_centered.jpg')
        ..createSync(recursive: true)
        ..writeAsBytesSync(writeJpg(img));
    });

    test('drawStringCenteredY', () {
      var img = copyResize(image, width: 400);
      drawStringCentered(img, arial_24, 'Testing Arial 24: Hello World',
          x: 10, color: getColor(255, 0, 0, 128));

      File('.dart_tool/out/font/x_centered.jpg')
        ..createSync(recursive: true)
        ..writeAsBytesSync(writeJpg(img));
    });

    test('drawStringCenteredXY', () {
      var img = copyResize(image, width: 400);
      drawStringCentered(img, arial_24, 'Testing Arial 24: Hello World',
          color: getColor(255, 0, 0, 128));

      File('.dart_tool/out/font/xy_centered.jpg')
        ..createSync(recursive: true)
        ..writeAsBytesSync(writeJpg(img));
    });
  });
}
