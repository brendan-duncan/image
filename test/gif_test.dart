import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

void main() {
  Directory dir = Directory('test/res/gif');
  var files = dir.listSync();

  group('GIF', () {
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
        File('.dart_tool/out/gif/$name.png')
          ..createSync(recursive: true)
          ..writeAsBytesSync(encodePng(image));
      });
    }

    for (var f in files) {
      if (f is! File || !f.path.endsWith('cars.gif')) {
        continue;
      }

      Animation anim;
      String name = f.path.split(RegExp(r'(/|\\)')).last;
      test('decodeCars $name', () {
        List<int> bytes = (f as File).readAsBytesSync();
        anim = GifDecoder().decodeAnimation(bytes);
        expect(anim.length, equals(30));
        expect(anim.loopCount, equals(0));
      });

      test('encodeCars', () {
        var gif = encodeGifAnimation(anim);
        File('.dart_tool/out/gif/cars.gif')
          ..createSync(recursive: true)
          ..writeAsBytesSync(gif);
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

      List<int> gif = encodeGifAnimation(anim);
      File('.dart_tool/out/gif/encodeAnimation.gif')
        ..createSync(recursive: true)
        ..writeAsBytesSync(gif);

      Animation anim2 = GifDecoder().decodeAnimation(gif);
      expect(anim2.length, equals(10));
      expect(anim2.loopCount, equals(10));
    });

    test('encodeImage', () {
      List<int> bytes = File('test/res/jpg/jpeg444.jpg').readAsBytesSync();
      Image image = JpegDecoder().decodeImage(bytes);

      List<int> gif = GifEncoder().encodeImage(image);
      File('.dart_tool/out/gif/jpeg444.gif')
        ..createSync(recursive: true)
        ..writeAsBytesSync(gif);
    });
  });
}
