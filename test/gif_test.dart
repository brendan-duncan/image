import 'dart:io';

import 'package:image/image.dart';
import 'package:test/test.dart';

void main() {
  Directory dir = Directory('test/res/gif');
  var files = dir.listSync();

  group('Gif', () {
    for (var f in files) {
      if (f is! File || !f.path.endsWith('.gif')) {
        continue;
      }

      String name = f.path.split(RegExp(r'(/|\\)')).last;
      test('getInfo $name', () {
        var bytes = (f as File).readAsBytesSync();

        GifInfo data = GifDecoder().startDecode(bytes);
        if (data == null) {
          throw ImageException('Unable to parse Gif info: $name.');
        }
      });
    }

    for (var f in files) {
      if (f is! File || !f.path.endsWith('.gif')) {
        continue;
      }

      String name = f.path.split(RegExp(r'(/|\\)')).last;
      test('decodeImage $name', () {
        var bytes = (f as File).readAsBytesSync();
        Image image = GifDecoder().decodeImage(bytes);
        File('out/gif/$name.png')
          ..createSync(recursive: true)
          ..writeAsBytesSync(encodePng(image));
      });
    }

    for (var f in files) {
      if (f is! File || !f.path.endsWith('cars.gif')) {
        continue;
      }

      String name = f.path.split(RegExp(r'(/|\\)')).last;
      test('decodeAnimation $name', () {
        List<int> bytes = (f as File).readAsBytesSync();
        Animation anim = GifDecoder().decodeAnimation(bytes);
        expect(anim.length, equals(30));
        expect(anim.loopCount, equals(0));
      });
    }

    test('encodeAnimation', () {
      Animation anim = Animation();
      anim.loopCount = 10;

      for (var i = 0; i < 10; i++) {
        Image image = Image(480, 120);
        drawString(image, arial_48, 100, 60, i.toString());
        anim.addFrame(image);
      }

      List<int> gif = encodeGifAnimation(anim, samplingFactor: 480);

      File('out/gif/encodeAnimation.gif')
        ..createSync(recursive: true)
        ..writeAsBytesSync(gif);
    });

    test('encodeImage', () {
      List<int> bytes = File('test/res/jpg/jpeg444.jpg').readAsBytesSync();
      Image image = JpegDecoder().decodeImage(bytes);

      List<int> gif = GifEncoder().encodeImage(image);
      File('out/gif/jpeg444.gif')
        ..createSync(recursive: true)
        ..writeAsBytesSync(gif);
    });
  });
}
