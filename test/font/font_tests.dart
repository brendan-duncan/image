import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  final image =
      decodeJpg(File('test/_data/jpg/big_buck_bunny.jpg').readAsBytesSync())!;

  group('Font', () {
    group('bitmapFont', () {
      test('zip/xml', () {
        final fontZip = File('test/_data/font/test.zip').readAsBytesSync();
        final font = readFontZip(fontZip);

        final img = copyResize(image, width: 400);
        drawString(img, 'Testing Font 1: Hello World',
            font: font, x: 10, y: 50);

        File('$testOutputPath/font/font_zip_xml.jpg')
          ..createSync(recursive: true)
          ..writeAsBytesSync(encodeJpg(img));
      });

      test('zip/text', () {
        final fontZip = File('test/_data/font/test_text.zip').readAsBytesSync();
        final font = readFontZip(fontZip);

        final img = copyResize(image, width: 400);
        drawString(img, 'Testing Font 2: Hello World',
            font: font, x: 10, y: 50, color: ColorRgba8(255, 0, 0, 128));

        File('$testOutputPath/font/font_zip_text.jpg')
          ..createSync(recursive: true)
          ..writeAsBytesSync(encodeJpg(img));
      });

      test('arial_14', () {
        final img = copyResize(image, width: 400);
        drawString(img, 'Testing Arial 14: Hello World',
            font: arial14, x: 10, y: 50, color: ColorRgba8(255, 0, 0, 128));

        File('$testOutputPath/font/font_arial_14.jpg')
          ..createSync(recursive: true)
          ..writeAsBytesSync(encodeJpg(img));
      });

      test('arial_24', () {
        final img = copyResize(image, width: 400);
        drawString(img, 'Testing Arial 24: Hello World',
            font: arial24, x: 10, y: 50, color: ColorRgba8(255, 0, 0, 128));

        File('$testOutputPath/font/font_arial_24.jpg')
          ..createSync(recursive: true)
          ..writeAsBytesSync(encodeJpg(img));
      });

      test('arial_48', () {
        final img = copyResize(image, width: 400);
        drawString(img, 'Testing Arial 48: Hello World',
            font: arial48, x: 10, y: 50, color: ColorRgba8(255, 0, 0, 128));

        File('$testOutputPath/font/font_arial_48.jpg')
          ..createSync(recursive: true)
          ..writeAsBytesSync(encodeJpg(img));
      });

      test('drawStringCenteredY', () {
        final img = copyResize(image, width: 400);
        drawString(img, 'Testing Arial 24: Hello World',
            font: arial24, y: 50, color: ColorRgba8(255, 0, 0, 128));

        File('$testOutputPath/font/y_centered.jpg')
          ..createSync(recursive: true)
          ..writeAsBytesSync(encodeJpg(img));
      });

      test('drawStringCenteredY', () {
        final img = copyResize(image, width: 400);
        drawString(img, 'Testing Arial 24: Hello World',
            font: arial24, x: 10, color: ColorRgba8(255, 0, 0, 128));

        File('$testOutputPath/font/x_centered.jpg')
          ..createSync(recursive: true)
          ..writeAsBytesSync(encodeJpg(img));
      });

      test('drawStringCenteredXY', () {
        final img = copyResize(image, width: 400);
        drawString(img, 'Testing Arial 24: Hello World',
            font: arial24, color: ColorRgba8(255, 0, 0, 128));

        File('$testOutputPath/font/xy_centered.jpg')
          ..createSync(recursive: true)
          ..writeAsBytesSync(encodeJpg(img));
      });
    });
  });
}
