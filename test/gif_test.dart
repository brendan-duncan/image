import 'dart:io';
import 'package:image/image.dart';
import 'package:test/test.dart';

void main() {
  Directory dir = new Directory('test/res/gif');
  List files = dir.listSync();

  group('Gif/getInfo', () {
    for (var f in files) {
      if (f is! File || !f.path.endsWith('.gif')) {
        continue;
      }

      String name = f.path.split(new RegExp(r'(/|\\)')).last;
      test('$name', () {
        List<int> bytes = f.readAsBytesSync();

        GifInfo data = new GifDecoder().startDecode(bytes);
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
        List<int> bytes = f.readAsBytesSync();
        Image image = new GifDecoder().decodeImage(bytes);
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
        List<int> bytes = f.readAsBytesSync();
        Animation anim = new GifDecoder().decodeAnimation(bytes);
        expect(anim.length, equals(30));
        expect(anim.loopCount, equals(0));
      });
    }
  });

  group('Gif/encodeAnimation', () {
    Animation anim = new Animation();
    anim.loopCount = 10;
    for (var i = 0; i < 10; i++) {
      Image image = new Image(480, 120);
      drawString(image, arial_48, 100, 60, i.toString());
      anim.addFrame(image);
    }

    List<int> gif = encodeGifAnimation(anim);
    new File('out/gif/encodeAnimation.gif')
      ..createSync(recursive: true)
      ..writeAsBytesSync(gif);
  });

  group('Gif/encodeImage', () {
    List<int> bytes = new File('test/res/jpg/jpeg444.jpg').readAsBytesSync();
    Image image = new JpegDecoder().decodeImage(bytes);

    List<int> gif = new GifEncoder().encodeImage(image);
    new File('out/gif/jpeg444.gif')
          ..createSync(recursive: true)
          ..writeAsBytesSync(gif);
  });
}
