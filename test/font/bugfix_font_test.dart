import 'dart:io';

import 'package:image/image.dart';
import 'package:test/test.dart';

const _fnt = '''
info face="Test" size=8 bold=0 italic=0 charset="" unicode=1 stretchH=100 smooth=1 aa=1 padding=0,0,0,0 spacing=1,1 outline=0
common lineHeight=8 base=7 scaleW=16 scaleH=16 pages=1 packed=0 alphaChnl=0 redChnl=0 greenChnl=0 blueChnl=0
page id=0 file="x.png"
chars count=1
char id=65   x=0     y=0     width=4     height=6     xoffset=0     yoffset=1     xadvance=5     page=0  chnl=15
''';

void main() {
  group('BitmapFont bug fixes', () {
    test('fromFnt loads a .fnt with a page line', () {
      final page = Image(width: 16, height: 16, numChannels: 4)
        ..clear(ColorRgba8(255, 255, 255, 255));
      final font = readFont(_fnt, page);
      expect(font.face, equals('Test'));
      expect(font.characters[65], isNotNull);
      expect(font.characters[65]!.image.getPixel(0, 0).a, equals(255));
    });

    test('fromFnt rejects duplicate page ids', () {
      final page = Image(width: 16, height: 16, numChannels: 4);
      final dup = _fnt.replaceFirst('page id=0 file="x.png"\n',
          'page id=0 file="x.png"\npage id=0 file="y.png"\n');
      expect(() => readFont(dup, page), throwsA(isA<ImageException>()));
    });

    test('readFontZip still loads', () {
      final font =
          readFontZip(File('test/_data/font/test.zip').readAsBytesSync());
      expect(font.characters, isNotEmpty);
      final font2 =
          readFontZip(File('test/_data/font/test_text.zip').readAsBytesSync());
      expect(font2.characters, isNotEmpty);
    });
  });
}
