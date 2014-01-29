part of image_test;

void defineWebPTests() {
  Io.File script = new Io.File(Io.Platform.script.toFilePath());
  String path = script.parent.path + '/res/webp';

  Io.Directory dir = new Io.Directory(path);
  List files = dir.listSync();

  group('WebP/getInfo', () {
    for (var f in files) {
      if (f is! Io.File || !f.path.endsWith('.webp')) {
        continue;
      }

      String name = f.path.split(new RegExp(r'(/|\\)')).last;
      test('$name', () {
        List<int> bytes = f.readAsBytesSync();

        WebPData data = new WebPDecoder().getInfo(bytes);
        if (data == null) {
          throw new ImageException('Unable to parse WebP info: $name.');
        }

        print('$name');
        print('    format: ${data.format}');
        print('    width: ${data.width}');
        print('    height: ${data.height}');
        print('    format: ${data.format}');
        print('    hasAlpha: ${data.hasAlpha}');
        print('    hasAnimation: ${data.hasAnimation}');
      });
    }
  });

  group('WebP/decodeImage', () {
    /*test('decode', () {
      Io.File file = new Io.File(path + '/1b.webp');
      List<int> bytes = file.readAsBytesSync();
      Image image = new WebPDecoder().decodeImage(bytes);
      List<int> png = new PngEncoder().encode(image);
      new Io.File('out/webp/decode.png')
      ..createSync(recursive: true)
        ..writeAsBytesSync(png);

      // Validate decoding.
      file = new Io.File(path + '/1b.png');
      bytes = file.readAsBytesSync();
      Image debugImage = new PngDecoder().decode(bytes);
      bool found = false;
      for (int y = 0; y < debugImage.height && !found; ++y) {
        for (int x = 0; x < debugImage.width; ++x) {
          int dc = debugImage.getPixel(x, y);
          int c = image.getPixel(x, y);
          expect(c, equals(dc));
        }
      }
    });*/

    for (var f in files) {
      if (f is! Io.File || !f.path.endsWith('.webp')) {
        continue;
      }

      String name = f.path.split(new RegExp(r'(/|\\)')).last;
      test('$name', () {
        List<int> bytes = f.readAsBytesSync();
        Image image = new WebPDecoder().decodeImage(bytes);
        if (image == null) {
          throw new ImageException('Unable to decode WebP Image: $name.');
        }

        List<int> png = new PngEncoder().encode(image);
        new Io.File('out/webp/${name}.png')
              ..createSync(recursive: true)
              ..writeAsBytesSync(png);
      });
    }
  });
}
