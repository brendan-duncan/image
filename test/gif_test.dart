import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

void main() {
  Directory dir = Directory('test/res/gif');
  var files = dir.listSync();

  group('Gif/getInfo', () {
    for (var f in files) {
      if (f is! File || !f.path.endsWith('.gif')) {
        continue;
      }

      String name = f.path.split(new RegExp(r'(/|\\)')).last;
      test('$name', () {
        var bytes = (f as File).readAsBytesSync();

        GifInfo data = GifDecoder().startDecode(bytes);
        if (data == null) {
          throw new ImageException('Unable to parse Gif info: $name.');
        }
      });
    }
  });

  group('Gif/decodeImage', () {
    for (var f in files) {
      if (f is! File || !f.path.endsWith('.gif')) {
        continue;
      }

      String name = f.path.split(new RegExp(r'(/|\\)')).last;
      test('$name', () {
        var bytes = (f as File).readAsBytesSync();
        Image image = GifDecoder().decodeImage(bytes);
        new File('out/gif/$name.png')
          ..createSync(recursive: true)
          ..writeAsBytesSync(encodePng(image));
      });
    }
  });

  group('Gif/decodeAnimation', () {
    for (var f in files) {
      if (f is! File || !f.path.endsWith('cars.gif')) {
        continue;
      }

      String name = f.path.split(new RegExp(r'(/|\\)')).last;
      test('$name', () {
        List<int> bytes = (f as File).readAsBytesSync();
        Animation anim = GifDecoder().decodeAnimation(bytes);
        expect(anim.length, equals(30));
        expect(anim.loopCount, equals(0));
      });
    }
  });

  group('Gif/encodeAnimation', () {
    Animation anim = Animation();
    anim.loopCount = 10;
    for (var i = 0; i < 10; i++) {
      Image image = Image(480, 120);
      drawString(image, arial_48, 100, 60, i.toString());
      anim.addFrame(image);
    }

    List<int> gif = encodeGifAnimation(anim);
    new File('out/gif/encodeAnimation.gif')
      ..createSync(recursive: true)
      ..writeAsBytesSync(gif);
  });

  group('Gif/encodeImage', () {
    List<int> bytes = File('test/res/jpg/jpeg444.jpg').readAsBytesSync();
    Image image = JpegDecoder().decodeImage(bytes);

    List<int> gif = GifEncoder().encodeImage(image);
    new File('out/gif/jpeg444.gif')
      ..createSync(recursive: true)
      ..writeAsBytesSync(gif);
  });
}
