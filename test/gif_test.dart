part of image_test;

void defineGifTests() {
  Io.File script = new Io.File(Io.Platform.script.toFilePath());
  String path = script.parent.path + '/res/gif';

  Io.Directory dir = new Io.Directory(path);
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
    String path = script.parent.path;
    for (var f in files) {
      if (f is! Io.File || !f.path.endsWith('.gif')) {
        continue;
      }

      String name = f.path.split(new RegExp(r'(/|\\)')).last;
      test('$name', () {
        List<int> bytes = f.readAsBytesSync();
        Image image = new GifDecoder().decodeImage(bytes);
        new Io.File(path + '/out/gif/$name.png')
              ..createSync(recursive: true)
              ..writeAsBytesSync(encodePng(image));

      });
    }
  });

  group('Gif/encodeImage', () {
    String path = script.parent.path;
    List<int> bytes = new Io.File(path + '/res/jpg/jpeg444.jpg').readAsBytesSync();
    Image image = new JpegDecoder().decodeImage(bytes);

    List<int> gif = new GifEncoder().encodeImage(image);
    new Io.File(path + '/out/gif/jpeg444.gif')
          ..createSync(recursive: true)
          ..writeAsBytesSync(gif);
  });
}
