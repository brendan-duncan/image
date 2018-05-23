import 'dart:io' as Io;
import 'package:image/image.dart';
import 'package:test/test.dart';

void main() {
  Io.Directory dir = new Io.Directory('test/res/gif');
  List files = dir.listSync();

  group('Gif/getInfo', () {
    for (var f in files) {
      if (f is! Io.File || !f.path.endsWith('.gif')) {
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
      if (f is! Io.File || !f.path.endsWith('.gif')) {
        continue;
      }

      String name = f.path.split(new RegExp(r'(/|\\)')).last;
      test('$name', () {
        List<int> bytes = f.readAsBytesSync();
        Image image = new GifDecoder().decodeImage(bytes);
        new Io.File('out/gif/$name.png')
              ..createSync(recursive: true)
              ..writeAsBytesSync(encodePng(image));

      });
    }
  });

  group('Gif/encodeImage', () {
    List<int> bytes = new Io.File('test/res/jpg/jpeg444.jpg').readAsBytesSync();
    Image image = new JpegDecoder().decodeImage(bytes);

    List<int> gif = new GifEncoder().encodeImage(image);
    new Io.File('out/gif/jpeg444.gif')
          ..createSync(recursive: true)
          ..writeAsBytesSync(gif);
  });
}
