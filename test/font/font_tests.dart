import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

import '../_test_util.dart';

void main() {
  final image = decodeJpg(
    File('test/_data/jpg/big_buck_bunny.jpg').readAsBytesSync(),
  )!;

  group('Font', () {
    group('bitmapFont', () {
      test('zip/xml', () {
        final fontZip = File('test/_data/font/test.zip').readAsBytesSync();
        final font = readFontZip(fontZip);

        final img = copyResize(image, width: 400);
        drawString(
          img,
          'Testing Font 1: Hello World',
          font: font,
          x: 10,
          y: 50,
        );

        File('$testOutputPath/font/font_zip_xml.jpg')
          ..createSync(recursive: true)
          ..writeAsBytesSync(encodeJpg(img));
      });

      test('zip/text', () {
        final fontZip = File('test/_data/font/test_text.zip').readAsBytesSync();
        final font = readFontZip(fontZip);

        final img = copyResize(image, width: 400);
        drawString(
          img,
          'Testing Font 2: Hello World',
          font: font,
          x: 10,
          y: 50,
          color: ColorRgba8(255, 0, 0, 128),
        );

        File('$testOutputPath/font/font_zip_text.jpg')
          ..createSync(recursive: true)
          ..writeAsBytesSync(encodeJpg(img));
      });

      test('text fnt parses element and attribute names', () {
        const fnt = '''
info face="Mini" size=8 bold=0 italic=0 charset="" unicode=0 stretchH=100 smooth=1 antialias=1 padding=0,0,0,0 spacing=1,1 outline=0
common lineHeight=10 base=8 scaleW=1 scaleH=1 pages=1 packed=0
chars count=1
char id=65 x=0 y=0 width=1 height=1 xoffset=0 yoffset=0 xadvance=7 page=0 chnl=15
''';
        final font = readFont(fnt, Image(width: 1, height: 1, numChannels: 4));
        final char = font.characters[65]!;

        expect(font.face, 'Mini');
        expect(font.lineHeight, 10);
        expect(font.pages, 1);
        expect(char.width, 1);
        expect(char.height, 1);
        expect(char.xAdvance, 7);
      });

      test('arial_14', () {
        final img = copyResize(image, width: 400);
        drawString(
          img,
          'Testing Arial 14: Hello World',
          font: arial14,
          x: 10,
          y: 50,
          color: ColorRgba8(255, 0, 0, 128),
        );

        File('$testOutputPath/font/font_arial_14.jpg')
          ..createSync(recursive: true)
          ..writeAsBytesSync(encodeJpg(img));
      });

      test('arial_24', () {
        final img = copyResize(image, width: 400);
        drawString(
          img,
          'Testing Arial 24: Hello World',
          font: arial24,
          x: 10,
          y: 50,
          color: ColorRgba8(255, 0, 0, 128),
        );

        File('$testOutputPath/font/font_arial_24.jpg')
          ..createSync(recursive: true)
          ..writeAsBytesSync(encodeJpg(img));
      });

      test('arial_48', () {
        final img = copyResize(image, width: 400);
        drawString(
          img,
          'Testing Arial 48: Hello World',
          font: arial48,
          x: 10,
          y: 50,
          color: ColorRgba8(255, 0, 0, 128),
        );

        File('$testOutputPath/font/font_arial_48.jpg')
          ..createSync(recursive: true)
          ..writeAsBytesSync(encodeJpg(img));
      });

      test('drawStringCenteredY', () {
        final img = copyResize(image, width: 400);
        drawString(
          img,
          'Testing Arial 24: Hello World',
          font: arial24,
          y: 50,
          color: ColorRgba8(255, 0, 0, 128),
        );

        File('$testOutputPath/font/y_centered.jpg')
          ..createSync(recursive: true)
          ..writeAsBytesSync(encodeJpg(img));
      });

      test('drawStringCenteredY', () {
        final img = copyResize(image, width: 400);
        drawString(
          img,
          'Testing Arial 24: Hello World',
          font: arial24,
          x: 10,
          color: ColorRgba8(255, 0, 0, 128),
        );

        File('$testOutputPath/font/x_centered.jpg')
          ..createSync(recursive: true)
          ..writeAsBytesSync(encodeJpg(img));
      });

      test('drawStringCenteredXY', () {
        final img = copyResize(image, width: 400);
        drawString(
          img,
          'Testing Arial 24: Hello World',
          font: arial24,
          color: ColorRgba8(255, 0, 0, 128),
        );

        File('$testOutputPath/font/xy_centered.jpg')
          ..createSync(recursive: true)
          ..writeAsBytesSync(encodeJpg(img));
      });
    });
  });
}
